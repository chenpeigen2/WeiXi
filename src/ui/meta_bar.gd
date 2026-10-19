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
var _hover_glow: StyleBoxFlat
var _hover := -1
var _last_count := 0
var _sticker_pulse := 0.0
var _pulse_glow: StyleBoxFlat


func _ready() -> void:
	position = Vector2(0, 1204)
	size = Vector2(Ui.SCREEN_W, 71)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_idle = _box(Ui.PANEL, Ui.MINT)
	_active = _box(Ui.ACCENT, Ui.ROSE)
	_sticker_bg = _box(Ui.PANEL, Ui.LAVENDER)
	_hover_glow = StyleBoxFlat.new()
	_hover_glow.bg_color = Color(0, 0, 0, 0)
	_hover_glow.border_color = Color(1.0, 0.68, 0.80, 0.55)
	_hover_glow.set_border_width_all(2)
	_hover_glow.set_corner_radius_all(18)

	_pulse_glow = StyleBoxFlat.new()
	_pulse_glow.bg_color = Color(0, 0, 0, 0)
	_pulse_glow.border_color = Color(1.0, 0.62, 0.76, 0.55)
	_pulse_glow.set_border_width_all(2)
	_pulse_glow.set_corner_radius_all(18)


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
	if count > _last_count:
		_sticker_pulse = 0.55
	_last_count = count
	queue_redraw()


func _process(delta: float) -> void:
	if _sticker_pulse > 0.0:
		_sticker_pulse = maxf(0.0, _sticker_pulse - delta)
		queue_redraw()


func _draw() -> void:
	_draw_chip(DAILY_RECT, "每日挑战", daily, _hover == 0)
	_draw_chip(RANDOM_RECT, "随机", not daily, _hover == 1)
	if _hover == 2:
		draw_style_box(_hover_glow, STICKER_RECT.grow(2.0))
	if _sticker_pulse > 0.0:
		var pk: float = _sticker_pulse / 0.55
		_pulse_glow.border_color = Color(1.0, 0.62, 0.76, 0.55 * pk)
		draw_style_box(_pulse_glow, STICKER_RECT.grow(2.0 + 3.0 * (1.0 - pk)))
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
	if _sticker_pulse > 0.0:
		var pk: float = _sticker_pulse / 0.55
		for i in range(4):
			var ang: float = TAU * float(i) / 4.0 + (1.0 - pk) * 2.0
			var sp: Vector2 = star + Vector2(cos(ang), sin(ang)) * (12.0 + 10.0 * (1.0 - pk))
			_star(sp, 3.4 * pk, Color(1.0, 0.76, 0.86, 0.85 * pk))


func _draw_chip(rect: Rect2, text: String, active: bool, hover: bool) -> void:
	if hover and not active:
		draw_style_box(_hover_glow, rect.grow(2.0))
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		if _hover != -1:
			_hover = -1
			queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := -1
		var p: Vector2 = event.position
		if DAILY_RECT.has_point(p):
			h = 0
		elif RANDOM_RECT.has_point(p):
			h = 1
		elif STICKER_RECT.has_point(p):
			h = 2
		if h != _hover:
			_hover = h
			queue_redraw()
		return
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
