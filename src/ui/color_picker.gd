extends Node2D
## 作弊1·颜色选择条：玻璃底条 + 6 色糖果球，当前色金环高亮。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const UiFont = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

var current := 0
var hover := -1

const COLOR_NAMES := ["草莓", "柠檬", "天空", "薄荷", "薰衣草", "蜜桃"]

var _panel: StyleBoxFlat
var _t := 0.0


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
	_panel.border_color = Ui.LAVENDER
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(int(Ui.PANEL_RADIUS_LARGE))
	_panel.shadow_color = Color(0.12, 0.05, 0.09, 0.28)
	_panel.shadow_size = 14
	_panel.shadow_offset = Vector2(0, 6)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


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
	draw_line(
		Vector2(rect.position.x + 30.0, rect.position.y + 1.0),
		Vector2(rect.end.x - 30.0, rect.position.y + 1.0),
		Color(0.80, 0.73, 0.95, 0.65), 1.0
	)
	var lace := Color(1.0, 0.66, 0.76, 0.55)
	var dx := rect.position.x + 30.0
	while dx < rect.end.x - 30.0:
		draw_circle(Vector2(dx, rect.position.y + 9.0), 2.0, lace)
		draw_circle(Vector2(dx, rect.end.y - 9.0), 2.0, lace)
		dx += 24.0
	_heart(Vector2(rect.position.x + 18.0, rect.position.y + 20.0), 4.2, Ui.ROSE, 0.8)

	# “换色”标题：让这条 6 色球不再像装饰。
	_heart(Vector2(pos_of(0).x - 30.0, Ui.PICKER_CENTER.y - 65.0), 4.0, Ui.ROSE, 0.9)
	var title := "换色" if hover < 0 else "换色 · %s" % COLOR_NAMES[hover]
	draw_string(
		UiFont, Vector2(pos_of(0).x - 14.0, Ui.PICKER_CENTER.y - 62.0),
		title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Ui.TEXT_DIM if hover < 0 else Ui.ACCENT
	)

	for i in range(Ui.BALL_COLORS.size()):
		var p := pos_of(i)
		var r := Ui.PICKER_R
		if i == current:
			r *= 1.12 + 0.025 * sin(_t * 5.0)
		elif i == hover:
			r *= 1.06 + 0.02 * sin(_t * 6.0)
		if i == current:
			var halo := Ui.ACCENT
			halo.a = 0.05 + 0.02 * (0.5 + 0.5 * sin(_t * 5.0))
			draw_circle(p, r + 16.0, halo)
			halo.a = 0.10
			draw_circle(p, r + 10.0, halo)
		elif i == hover:
			draw_circle(p, r + 12.0, Color(1.0, 0.70, 0.80, 0.20))
		BallDraw.draw_ball(self, p, r, Ui.BALL_COLORS[i])
		if i == hover and i != current:
			draw_arc(p, r + 5.0, 0, TAU, 36, Ui.HEART, 2.0, true)
		if i == current:
			draw_arc(p, r + 7.0, 0, TAU, 40, Ui.ACCENT, 4.0, true)
			_heart(p + Vector2(0, -r - 13.0 + 2.0 * sin(_t * 4.0)), 3.6, Ui.HEART, 0.85)


## 小爱心：奶油条上的糖霜。
func _heart(p: Vector2, s: float, c: Color, a: float) -> void:
	var col := Color(c.r, c.g, c.b, a)
	draw_circle(p + Vector2(-s * 0.38, -s * 0.18), s * 0.48, col)
	draw_circle(p + Vector2(s * 0.38, -s * 0.18), s * 0.48, col)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.82, -s * 0.05), p + Vector2(s * 0.82, -s * 0.05), p + Vector2(0, s * 0.85),
	]), col)
