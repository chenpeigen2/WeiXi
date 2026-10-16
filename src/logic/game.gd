extends RefCounted
## 游戏流程控制器：串联棋盘/计分/RNG，实现 玩法.md 的完整规则。纯逻辑。

const Board = preload("res://src/logic/board.gd")
const Scorer = preload("res://src/logic/scorer.gd")
const HexLayout = preload("res://src/logic/hex_layout.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")

enum Mode { SHOOT, MATCH3 }

const WIDTH := 10
const INITIAL_ROWS := 12
const MAX_ROWS := 17 # 超过即裁剪顶行（与相机可见容量一致，测试锁定）
const REFILL_ROWS := 5
const COLOR_COUNT := 6
const HINT_THRESHOLD := 10
const BALL_RADIUS := 17.0

var board: RefCounted
var scorer: RefCounted
var layout: RefCounted
var rng: RandomNumberGenerator
var mode := Mode.SHOOT
var current_color := 0
var next_color := 0
var deadline_row := INITIAL_ROWS - 1


func _init(p_seed := 0) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	layout = HexLayout.new(BALL_RADIUS)
	board = Board.new(WIDTH, INITIAL_ROWS)
	scorer = Scorer.new()
	board.refill_top(REFILL_ROWS, rng, COLOR_COUNT)
	current_color = _rand_color()
	next_color = _rand_color()


func _rand_color() -> int:
	return rng.randi_range(0, COLOR_COUNT - 1)


## 作弊1：自由换当前球颜色
func set_current_color(c: int) -> void:
	current_color = c


## 作弊2：行数滑杆，主动向下加 n 行空位（超出上限裁顶行）
func add_rows(n: int) -> void:
	board.extend_rows(n)
	deadline_row += n
	deadline_row -= board.trim_top_to(MAX_ROWS)


## 射击模式：球吸附到 cell 后的完整结算
func attach_ball(cell: Vector2i) -> Dictionary:
	board.set_ball(cell, current_color)
	var res: Dictionary = board.resolve_at(cell)
	_score_result(res)
	_after_board_change()
	current_color = next_color
	next_color = _rand_color()
	return res


## 三消模式：尝试互换两个相邻球
func try_swap(a: Vector2i, b: Vector2i) -> Dictionary:
	var res: Dictionary = board.swap(a, b)
	if res["matched"]:
		_score_result(res)
		_after_board_change()
	return res


func toggle_mode() -> void:
	mode = Mode.MATCH3 if mode == Mode.SHOOT else Mode.SHOOT


## 剩余球很少时提示可切三消（仅射击模式下提示）
func should_hint_match3() -> bool:
	return mode == Mode.SHOOT and board.ball_count() <= HINT_THRESHOLD


## 瞄准发射：求吸附格（表现层据此做动画，再调 attach_ball）
func aim_attach(from: Vector2, dir: Vector2) -> Vector2i:
	return Trajectory.find_attach_cell(board, layout, from, dir, WIDTH * layout.diameter)


func _score_result(res: Dictionary) -> void:
	if res["popped"].is_empty():
		scorer.register_miss()
	else:
		scorer.register_clear(res["popped"].size(), res["dropped"].size())


func _after_board_change() -> void:
	if board.is_empty():
		# 清空自动补球并切回射击模式（玩不死：永远有球可打）
		board.refill_top(REFILL_ROWS, rng, COLOR_COUNT)
		mode = Mode.SHOOT
	deadline_row += board.ensure_space(deadline_row)
	deadline_row -= board.trim_top_to(MAX_ROWS)
