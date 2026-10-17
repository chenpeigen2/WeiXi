extends Node2D
## 掉球线：珊瑚色的“掉落线”，不是死亡线。
## 独立节点负责闪烁与触线提示，避免为了闪线每帧重绘整盘球。

const Ui = preload("res://src/ui/theme.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")
const UiFont = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

var game: RefCounted
var origin := Vector2.ZERO

var _pulse := 0.0
var _pill: StyleBoxFlat


func _ready() -> void:
	_pill = StyleBoxFlat.new()
	_pill.set_corner_radius_all(15)
	_pill.set_border_width_all(1)


## 触线宽限期：最低占用行已到达底线，再打一发就会掉一行。
func armed() -> bool:
	return game != null and game.board.lowest_occupied_row() >= game.deadline_row


func _process(delta: float) -> void:
	if armed():
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var layout = game.layout
	var line_y: float = BoardCamera.deadline_line_y(
		game.deadline_row, layout.row_height, layout.radius, origin.y
	)
	var x0 := Ui.BOARD_MARGIN_X
	var x1 := Ui.SCREEN_W - Ui.BOARD_MARGIN_X
	var is_armed := armed()
	var base: Color = Ui.DEADLINE
	var pulse := 0.0
	if is_armed:
		base = Ui.DEADLINE_ARMED
		pulse = 0.5 + 0.5 * sin(_pulse * 6.0)

	var glow_a: float = 0.10
	var mid_a: float = 0.25
	var line_a: float = base.a
	if is_armed:
		glow_a = 0.12 + 0.12 * pulse
		mid_a = 0.30 + 0.22 * pulse
		line_a = base.a * (0.72 + 0.28 * pulse)

	# 三层发光：宽光晕 / 中光 / 虚线，全部用珊瑚色。
	draw_line(Vector2(x0, line_y), Vector2(x1, line_y), Color(base.r, base.g, base.b, glow_a), 8.0)
	draw_line(Vector2(x0, line_y), Vector2(x1, line_y), Color(base.r, base.g, base.b, mid_a), 4.0)
	draw_dashed_line(
		Vector2(x0, line_y), Vector2(x1, line_y),
		Color(base.r, base.g, base.b, line_a), 2.0, 12.0
	)

	# 线名：常驻在右端，明确它不是 Game Over 线。
	draw_string(
		UiFont, Vector2(x1 - 100.0, line_y + 19.0), "掉球线",
		HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 13,
		Color(base.r, base.g, base.b, 0.85)
	)

	if is_armed:
		_draw_warning(line_y, base, pulse)


## 触线提示放在线下方、发射器上方，避免盖住已经触线的球。
func _draw_warning(line_y: float, base: Color, pulse: float) -> void:
	var rect := Rect2(Ui.SCREEN_W * 0.5 - 125.0, line_y + 14.0, 250.0, 30.0)
	_pill.bg_color = Color(0.08, 0.08, 0.14, 0.94)
	_pill.border_color = Color(base.r, base.g, base.b, 0.55 + 0.35 * pulse)
	draw_style_box(_pill, rect)
	draw_string(
		UiFont, Vector2(rect.position.x, rect.position.y + 21.0),
		"再打一发，这一行会掉",
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15,
		Color(base.r, base.g, base.b, 0.88 + 0.12 * pulse)
	)
