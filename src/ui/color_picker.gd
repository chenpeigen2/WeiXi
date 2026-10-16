extends Node2D
## 作弊1·颜色选择条：玻璃底条 + 6 色糖果球，当前色金环高亮。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")

var current := 0

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
	_panel.set_corner_radius_all(30)


func set_current(c: int) -> void:
	current = c
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(pos_of(0) - Vector2(28, 26), Vector2(Ui.PICKER_DX * 5 + 56, 52))
	draw_style_box(_panel, rect)
	for i in range(Ui.BALL_COLORS.size()):
		var p := pos_of(i)
		var r := Ui.PICKER_R * (1.15 if i == current else 1.0)
		BallDraw.draw_ball(self, p, r, Ui.BALL_COLORS[i])
		if i == current:
			draw_arc(p, r + 4, 0, TAU, 40, Ui.ACCENT, 2.5, true)
