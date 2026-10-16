extends RefCounted
## 游戏流程控制器：串联棋盘/计分/RNG，实现 玩法.md 的完整规则。纯逻辑。

const Board = preload("res://src/logic/board.gd")
const Scorer = preload("res://src/logic/scorer.gd")
const HexLayout = preload("res://src/logic/hex_layout.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")

const WIDTH := 10
const MAX_ROWS := 14 # 固定容量（与相机可见容量一致，测试锁定）
const REFILL_ROWS := 5
const COLOR_COUNT := 6
const HINT_THRESHOLD := 10
const BALL_RADIUS := 33.0

var board: RefCounted
var scorer: RefCounted
var layout: RefCounted
var rng: RandomNumberGenerator
var current_color := 0
var next_color := 0
var deadline_row := MAX_ROWS - 1 # 固定底线


func _init(p_seed := 0) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	layout = HexLayout.new(BALL_RADIUS)
	board = Board.new(WIDTH, MAX_ROWS)
	scorer = Scorer.new()
	board.refill_top(REFILL_ROWS, rng, COLOR_COUNT)
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
	var res: Dictionary = {"popped": [], "dropped": [], "overflow": []}
	if not board.has_ball(cell):
		return res
	board.cells[cell] = color
	res = board.resolve_at(cell)
	if not res["popped"].is_empty():
		scorer.register_clear(res["popped"].size(), res["dropped"].size())
	_after_board_change(res, false)
	return res



## 发射：球吸附到 cell 后的完整结算。
## 宽限一发: 触线的球先留着，之后再发射才会触发最低行掉落。
func attach_ball(cell: Vector2i) -> Dictionary:
	var at_line_before: bool = board.lowest_occupied_row() >= deadline_row
	board.set_ball(cell, current_color)
	var res: Dictionary = board.resolve_at(cell)
	_score_result(res)
	_after_board_change(res, at_line_before)
	current_color = next_color
	next_color = _rand_color()
	return res


## 三消模式：尝试互换两个相邻球
func try_swap(a: Vector2i, b: Vector2i) -> Dictionary:
	var res: Dictionary = board.swap(a, b)
	if res["matched"]:
		_score_result(res)
		_after_board_change(res, false)
	return res


## 剩余球很少时提示可切三消（仅射击模式下提示）
func should_hint_match3() -> bool:
	return board.ball_count() <= HINT_THRESHOLD


## 瞄准发射：求吸附格（表现层据此做动画，再调 attach_ball）
func aim_attach(from: Vector2, dir: Vector2) -> Vector2i:
	return Trajectory.find_attach_cell(board, layout, from, dir, WIDTH * layout.diameter)


func _score_result(res: Dictionary) -> void:
	if res["popped"].is_empty():
		scorer.register_miss()
	else:
		scorer.register_clear(res["popped"].size(), res["dropped"].size())


## trigger_overflow: 仅"发球前球堆已在触线状态"的那次发射触发掉落（宽限一发）
func _after_board_change(res: Dictionary, trigger_overflow: bool) -> void:
	if board.is_empty():
		# 清空自动补球（玩不死：永远有球可打）
		board.refill_top(REFILL_ROWS, rng, COLOR_COUNT)
	if trigger_overflow:
		res["overflow"] = board.drop_overflow(deadline_row)
	else:
		res["overflow"] = []
