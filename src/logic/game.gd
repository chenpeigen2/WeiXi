extends RefCounted
## 游戏流程控制器：串联棋盘/计分/RNG，实现 玩法.md 的完整规则。纯逻辑。

const Board = preload("res://src/logic/board.gd")
const Scorer = preload("res://src/logic/scorer.gd")
const HexLayout = preload("res://src/logic/hex_layout.gd")
const HexGrid = preload("res://src/logic/hex_grid.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")
const WishSystem = preload("res://src/logic/wish_system.gd")

const WIDTH := 10
const MAX_ROWS := 14 # 固定容量（与相机可见容量一致，测试锁定）
const REFILL_ROWS := 5
const COLOR_COUNT := 6
const HINT_THRESHOLD := 10
const BALL_RADIUS := 33.0

var board: RefCounted
var scorer: RefCounted
var wishes: RefCounted
var layout: RefCounted
var rng: RandomNumberGenerator
var current_color := 0
var next_color := 0
var star_shot := false # 下一发是否为星星炸弹
var deadline_row := MAX_ROWS - 1 # 固定底线


func _init(p_seed := 0) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	layout = HexLayout.new(BALL_RADIUS)
	board = Board.new(WIDTH, MAX_ROWS)
	scorer = Scorer.new()
	board.refill_top(REFILL_ROWS, rng, COLOR_COUNT)
	wishes = WishSystem.new(rng)
	current_color = _rand_color()
	next_color = _rand_color()


func _rand_color() -> int:
	return rng.randi_range(0, COLOR_COUNT - 1)


## 作弊1：自由换当前球颜色
func set_current_color(c: int) -> void:
	current_color = c


## 作弊1快捷手势：双击棋盘上已射出的球，弹出调色板换成任意颜色，
## 若形成 >=3 相连同色立即消除计分
func set_ball_color(cell: Vector2i, color: int) -> Dictionary:
	var res: Dictionary = {"popped": [], "dropped": [], "overflow": [], "gain": 0, "color_counts": {}}
	if not board.has_ball(cell):
		return res
	board.cells[cell] = color
	res = board.resolve_at(cell)
	if not res["popped"].is_empty():
		_prepare_clear(res)
		res["gain"] = scorer.register_clear(res["popped"].size(), res["dropped"].size(), false)
		_notify_clear(res)
	else:
		res["gain"] = 0
	_after_board_change(res, false)
	_notify_wish("recolor", {})
	return res



## 发射：球吸附到 cell 后的完整结算。
## 宽限一发: 触线的球先留着；之后再发射时，逾期的最低行先掉出腾位置，
## 新球不陪葬，掉行后失去支撑的悬空球跟着掉。
func attach_ball(cell: Vector2i, color := -1, bounces := 0) -> Dictionary:
	var ball_color := current_color if color < 0 else color
	var fever_shot: bool = scorer.fever_shots > 0
	var bomb := star_shot
	star_shot = false
	var overflow: Array[Vector2i] = []
	if board.lowest_occupied_row() >= deadline_row:
		overflow = board.drop_overflow(deadline_row)
		overflow.append_array(_drop_floating())
	board.set_ball(cell, ball_color)
	var res: Dictionary
	if bomb:
		res = _star_burst(cell)
	else:
		res = board.resolve_at(cell)
		_prepare_clear(res)
	res["cell"] = cell
	_score_result(res, fever_shot)

	# 反弹奖励：不改变落球规则，只给技巧发糖。
	if bounces > 0:
		var bank_gain := bounces * 10
		scorer.score += bank_gain
		scorer.add_star(bounces * 8)
		res["bank"] = bounces
		res["bank_gain"] = bank_gain
		res["gain"] = int(res.get("gain", 0)) + bank_gain
		_notify_wish("bank", {"bounces": bounces})

	# 掉行不是惩罚，是星尘。
	if not overflow.is_empty():
		var overflow_star := 15 + overflow.size() * 4
		scorer.add_star(overflow_star)
		res["overflow_star"] = overflow_star
		_notify_wish("drop_row", {"count": overflow.size()})

	_after_board_change(res, false)
	res["overflow"] = overflow
	current_color = next_color
	next_color = _rand_color()
	# “3 发”按发射严格消耗，空枪也算。
	if fever_shot:
		scorer.fever_shots -= 1
	return res


## 三消模式：尝试互换两个相邻球
func try_swap(a: Vector2i, b: Vector2i) -> Dictionary:
	var res: Dictionary = board.swap(a, b)
	if res["matched"]:
		_prepare_clear(res)
		_score_result(res, false)
		_after_board_change(res, false)
	return res


## 剩余球很少时提示可切三消（仅射击模式下提示）
func should_hint_match3() -> bool:
	return board.ball_count() <= HINT_THRESHOLD


## 瞄准发射：求吸附格（表现层据此做动画，再调 attach_ball）
func aim_attach(from: Vector2, dir: Vector2) -> Vector2i:
	return Trajectory.find_attach_cell(board, layout, from, dir, WIDTH * layout.diameter)


func _score_result(res: Dictionary, fever := false) -> void:
	if res["popped"].is_empty():
		scorer.register_miss()
		res["gain"] = 0
	else:
		res["gain"] = scorer.register_clear(res["popped"].size(), res["dropped"].size(), fever)
		_notify_clear(res)


func _notify_clear(res: Dictionary) -> void:
	_notify_wish("clear", {
		"count": res["popped"].size(),
		"colors": res.get("color_counts", {}),
		"combo": scorer.combo,
	})


## 5+：下一发变成星星炸弹；7+：立刻彩虹洗色。
## 星星炸弹本身不再连锁触发，避免一发自爆刷屏。
func _prepare_clear(res: Dictionary) -> void:
	if res["popped"].is_empty():
		return
	if res["popped"].size() >= 7:
		_rainbow_wash(res)
	if res["popped"].size() >= 5:
		star_shot = true
		res["star_armed"] = true


## 彩虹洗色：清掉棋盘上剩余的所有“主色”球。
func _rainbow_wash(res: Dictionary) -> void:
	var counts: Dictionary = res.get("color_counts", {})
	if counts.is_empty():
		return
	var color := -1
	var best := 0
	for c in counts:
		var n := int(counts[c])
		if n > best:
			best = n
			color = int(c)
	if color < 0:
		return
	var washed: Array[Vector2i] = []
	for c in board.cells.keys():
		if board.cells[c] == color:
			washed.append(c)
	if washed.is_empty():
		return
	for c in washed:
		board.remove_ball(c)
	var popped: Array = res["popped"]
	popped.append_array(washed)
	res["popped"] = popped
	counts[color] = int(counts.get(color, 0)) + washed.size()
	res["color_counts"] = counts
	var fl: Array[Vector2i] = board.floating()
	for c in fl:
		board.remove_ball(c)
	var dropped: Array = res["dropped"]
	dropped.append_array(fl)
	res["dropped"] = dropped
	res["rainbow"] = true


## 星星炸弹：清掉落点周围一圈（含落点）。
func _star_burst(cell: Vector2i) -> Dictionary:
	var cells: Array[Vector2i] = [cell]
	cells.append_array(HexGrid.neighbors(cell))
	var popped: Array[Vector2i] = []
	var counts := {}
	for c in cells:
		if not board.has_ball(c):
			continue
		var col: int = board.get_color(c)
		counts[col] = counts.get(col, 0) + 1
		board.remove_ball(c)
		popped.append(c)
	var fl: Array[Vector2i] = board.floating()
	for c in fl:
		board.remove_ball(c)
	return {
		"popped": popped,
		"dropped": fl,
		"color_counts": counts,
		"star_burst": true,
	}


func _notify_wish(event: String, data: Dictionary) -> void:
	if wishes == null:
		return
	var done: Dictionary = wishes.notify(event, data)
	if done.is_empty():
		return
	# 愿望奖励是特殊糖：Fever 期间也能攒，避免奖励被吞。
	scorer.add_star(int(done.get("reward", 0)), true)


## 掉行后失去与顶行连接的球（物理一致性）
func _drop_floating() -> Array[Vector2i]:
	var fl: Array[Vector2i] = board.floating()
	for c in fl:
		board.remove_ball(c)
	return fl


func _after_board_change(res: Dictionary, _trigger_overflow: bool) -> void:
	if board.is_empty():
		# 清空自动补球（玩不死：永远有球可打）
		board.refill_top(REFILL_ROWS, rng, COLOR_COUNT)
	if not res.has("overflow"):
		res["overflow"] = []
