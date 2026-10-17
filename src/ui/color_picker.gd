extends Node2D
## 作弊1·颜色选择条：玻璃底条 + 6 色糖果球，当前色金环高亮。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const UiFont = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

var current := 0
var hover := -1

var _panel: StyleBoxFlat


static func pos_of(i: int) -> Vector2:
	return Vector2(Ui.PICKER_CENTER.x + (float(i) - 2.5) * Ui.PICKER_DX, Ui.PICKER_CENTER.y)


static func hit(pos: Vector2) -> int:
	for i in range(Ui.BALL_COLORS.size()):
		if pos.distance_to(pos_of(i)) <= Ui.PICKER_HIT_R:
			return i
	return -1


func _ready() -> void:
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.PANEL_STROKE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(int(Ui.PANEL_RADIUS_LARGE))


func set_current(c: int) -> void:
	current = c
	queue_redraw()


func set_hover(pos: Vector2) -> void:
	var i := hit(pos)
	if i != hover:
		hover = i
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(pos_of(0) - Vector2(50, 45), Vector2(Ui.PICKER_DX * 5 + 99, 90))
	draw_style_box(_panel, rect)

	# “换色”标题：让这条 6 色球不再像装饰。
	draw_string(
		UiFont, Vector2(pos_of(0).x - 14.0, Ui.PICKER_CENTER.y - 62.0),
		"换色", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Ui.TEXT_DIM
	)

	for i in range(Ui.BALL_COLORS.size()):
		var p := pos_of(i)
		var r := Ui.PICKER_R
		if i == current:
			r *= 1.15
		elif i == hover:
			r *= 1.08
		BallDraw.draw_ball(self, p, r, Ui.BALL_COLORS[i])
		if i == hover and i != current:
			draw_arc(p, r + 5.0, 0, TAU, 36, Color(1, 1, 1, 0.75), 2.0, true)
		if i == current:
			draw_arc(p, r + 7.0, 0, TAU, 40, Ui.ACCENT, 4.0, true)
