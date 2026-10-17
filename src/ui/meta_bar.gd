extends Control
## 底部入口：每日挑战 / 随机一局 / 贴纸册。

signal daily_pressed
signal random_pressed
signal stickers_pressed

const Ui = preload("res://src/ui/theme.gd")
const UiFont = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

const DAILY_RECT := Rect2(28, 8, 150, 32)
const RANDOM_RECT := Rect2(190, 8, 108, 32)
const STICKER_RECT := Rect2(532, 8, 190, 32)

var daily := false
var sticker_count := 0

var _idle: StyleBoxFlat
var _active: StyleBoxFlat
var _sticker_bg: StyleBoxFlat


func _ready() -> void:
	position = Vector2(0, 1204)
	size = Vector2(Ui.SCREEN_W, 71)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_idle = _box(Ui.PANEL, Ui.MINT)
	_active = _box(Ui.ACCENT, Ui.ROSE)
	_sticker_bg = _box(Ui.PANEL, Ui.LAVENDER)


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(16)
	return box


func set_state(is_daily: bool, count: int) -> void:
	daily = is_daily
	sticker_count = count
	queue_redraw()


func _draw() -> void:
	_draw_chip(DAILY_RECT, "每日挑战", daily)
	_draw_chip(RANDOM_RECT, "随机", not daily)
	draw_style_box(_sticker_bg, STICKER_RECT)
	_heart(Vector2(STICKER_RECT.position.x + 14, STICKER_RECT.position.y + 16), 4.2, Ui.ROSE, 0.9)
	var text := "贴纸册 %d/%d" % [sticker_count, 12]
	draw_string(
		UiFont, Vector2(STICKER_RECT.position.x + 26, STICKER_RECT.position.y + 21),
		text, HORIZONTAL_ALIGNMENT_LEFT, STICKER_RECT.size.x - 38, 14, Ui.TEXT_MAIN
	)
	# 小星星标记
	var star := STICKER_RECT.position + Vector2(STICKER_RECT.size.x - 20, 16)
	_star(star, 5.0, Ui.ROSE)


func _draw_chip(rect: Rect2, text: String, active: bool) -> void:
	draw_style_box(_active if active else _idle, rect)
	var color := Color(0.30, 0.10, 0.18) if active else Ui.TEXT_DIM
	_heart(Vector2(rect.position.x + 13.0, rect.position.y + 16.0), 4.0,
		Color(0.55, 0.18, 0.28) if active else Ui.ROSE, 0.9)
	draw_string(
		UiFont, Vector2(rect.position.x + 8.0, rect.position.y + 21),
		text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 14, color
	)


func _star(p: Vector2, s: float, c: Color) -> void:
	var q: float = s * 0.22
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -s), p + Vector2(q, -q), p + Vector2(s, 0), p + Vector2(q, q),
		p + Vector2(0, s), p + Vector2(-q, q), p + Vector2(-s, 0), p + Vector2(-q, -q),
	]), c)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if DAILY_RECT.has_point(p):
			daily_pressed.emit()
			accept_event()
		elif RANDOM_RECT.has_point(p):
			random_pressed.emit()
			accept_event()
		elif STICKER_RECT.has_point(p):
			stickers_pressed.emit()
			accept_event()


func _heart(p: Vector2, s: float, c: Color, a: float) -> void:
	var col := Color(c.r, c.g, c.b, a)
	draw_circle(p + Vector2(-s * 0.38, -s * 0.18), s * 0.48, col)
	draw_circle(p + Vector2(s * 0.38, -s * 0.18), s * 0.48, col)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.82, -s * 0.05), p + Vector2(s * 0.82, -s * 0.05), p + Vector2(0, s * 0.85),
	]), col)
