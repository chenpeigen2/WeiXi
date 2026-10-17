extends Control
## 贴纸册：12 张手绘矢量贴纸，完成愿望逐张解锁。

const Ui = preload("res://src/ui/theme.gd")
const UiFont = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")
const StickerBook = preload("res://src/logic/sticker_book.gd")

const PANEL := Rect2(75, 300, 600, 600)
const CLOSE := Rect2(632, 314, 34, 34)
const COLS := 4
const CELL := Vector2(135, 130)
const GRID_START := Vector2(105, 392)

var _book: RefCounted
var _panel: StyleBoxFlat


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(Ui.SCREEN_W, Ui.SCREEN_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Color(0.14, 0.10, 0.20, 0.98)
	_panel.border_color = Color(1.0, 0.78, 0.88, 0.30)
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(30)
	_panel.shadow_color = Color(0, 0, 0, 0.45)
	_panel.shadow_size = 24


func open(book: RefCounted) -> void:
	_book = book
	visible = true
	queue_redraw()


func close() -> void:
	visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if CLOSE.has_point(p) or not PANEL.has_point(p):
			close()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Ui.SCREEN_W, Ui.SCREEN_H), Color(0.04, 0.025, 0.07, 0.74))
	draw_style_box(_panel, PANEL)
	var total := StickerBook.TOTAL
	var owned: int = _book.count() if _book != null else 0
	draw_string(
		UiFont, Vector2(105, 342), "贴纸册 %d/%d" % [owned, total],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Ui.TEXT_MAIN
	)
	draw_string(
		UiFont, Vector2(105, 369), "完成愿望，解锁一张小贴纸",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Ui.TEXT_DIM
	)
	# 关闭按钮
	draw_circle(Vector2(649, 331), 17, Color(1, 0.86, 0.93, 0.10))
	draw_string(
		UiFont, Vector2(638, 339), "×",
		HORIZONTAL_ALIGNMENT_CENTER, 22, 22, Ui.TEXT_MAIN
	)

	for i in range(total):
		var col := i % COLS
		var row: int = int(i / COLS)
		var origin := GRID_START + Vector2(col * CELL.x, row * CELL.y)
		var center := origin + Vector2(67, 48)
		var unlocked: bool = _book != null and _book.is_unlocked(i)
		_draw_sticker(i, center, unlocked)
		var name: String = StickerBook.NAMES[i] if unlocked else "？？？"
		draw_string(
			UiFont, origin + Vector2(0, 108), name,
			HORIZONTAL_ALIGNMENT_CENTER, CELL.x, 12,
			Ui.TEXT_MAIN if unlocked else Ui.TEXT_DIM
		)

	draw_string(
		UiFont, Vector2(105, 870), "第 %d 张 / 共 %d 张" % [owned, total],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Ui.TEXT_DIM
	)


func _draw_sticker(index: int, c: Vector2, unlocked: bool) -> void:
	var base: Color = StickerBook.COLORS[index] if unlocked else Color(0.20, 0.15, 0.25)
	if unlocked:
		draw_circle(c, 43, Color(base.r, base.g, base.b, 0.22))
		draw_circle(c, 38, base)
		draw_arc(c, 43, 0, TAU, 48, Color(1, 1, 1, 0.32), 2.0, true)
		draw_circle(c + Vector2(-12, -14), 8, Color(1, 1, 1, 0.22))
		_symbol(index, c, 24, Color(0.24, 0.12, 0.23, 0.88))
	else:
		draw_circle(c, 40, base)
		draw_arc(c, 43, 0, TAU, 48, Color(1, 1, 1, 0.08), 2.0, true)
		draw_string(
			UiFont, c + Vector2(-12, 10), "?",
			HORIZONTAL_ALIGNMENT_CENTER, 24, 28, Color(1, 1, 1, 0.28)
		)


func _symbol(kind: int, c: Vector2, r: float, col: Color) -> void:
	match kind:
		0:
			_star5(c, r * 1.1, col)
		1:
			_bunny(c, r, col)
		2:
			_heart(c, r, col)
		3:
			_cloud(c, r, col)
		4:
			draw_arc(c + Vector2(r * 0.10, 0), r * 0.70, PI * 0.35, PI * 1.65, 32, col, r * 0.55, true)
		5:
			_star5(c, r * 1.1, col)
		6:
			var arcs := [Color(1, 0.55, 0.62), Color(1, 0.86, 0.48), Color(0.55, 0.78, 1.0)]
			for k in range(3):
				draw_arc(c + Vector2(0, r * 0.35), r * (0.85 - k * 0.20), PI, TAU, 32, arcs[k], 4.0, true)
		7:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r, r * 0.6), c + Vector2(-r * 0.8, -r * 0.65),
				c + Vector2(-r * 0.25, -r * 0.1), c + Vector2(0, -r * 0.85),
				c + Vector2(r * 0.25, -r * 0.1), c + Vector2(r * 0.8, -r * 0.65),
				c + Vector2(r, r * 0.6),
			]), col)
		8:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.9, -r * 0.55), c + Vector2(-r * 0.1, 0), c + Vector2(-r * 0.9, r * 0.55),
			]), col)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(r * 0.9, -r * 0.55), c + Vector2(r * 0.1, 0), c + Vector2(r * 0.9, r * 0.55),
			]), col)
			draw_circle(c, r * 0.24, Color(1, 1, 1, 0.55))
		9:
			draw_circle(c, r * 0.75, col)
			draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.18, Color(1, 1, 1, 0.55))
		10:
			for k in range(4):
				var a := TAU * float(k) / 4.0
				draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.34, col)
		11:
			draw_circle(c + Vector2(0, r * 0.15), r * 0.68, col)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.62, -r * 0.25), c + Vector2(-r * 0.42, -r * 0.95), c + Vector2(-r * 0.05, -r * 0.48),
			]), col)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(r * 0.62, -r * 0.25), c + Vector2(r * 0.42, -r * 0.95), c + Vector2(r * 0.05, -r * 0.48),
			]), col)
			draw_circle(c + Vector2(-r * 0.24, r * 0.08), r * 0.07, Color(1, 1, 1, 0.85))
			draw_circle(c + Vector2(r * 0.24, r * 0.08), r * 0.07, Color(1, 1, 1, 0.85))

func _star5(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in range(10):
		var a := -PI / 2.0 + float(k) * PI / 5.0
		var rad := r if k % 2 == 0 else r * 0.42
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, col)


func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.38, -r * 0.18), r * 0.48, col)
	draw_circle(c + Vector2(r * 0.38, -r * 0.18), r * 0.48, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.82, -r * 0.05), c + Vector2(r * 0.82, -r * 0.05), c + Vector2(0, r * 0.85),
	]), col)


func _bunny(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.34, -r * 0.68), r * 0.22, col)
	draw_circle(c + Vector2(-r * 0.34, -r * 0.95), r * 0.14, col)
	draw_circle(c + Vector2(r * 0.34, -r * 0.68), r * 0.22, col)
	draw_circle(c + Vector2(r * 0.34, -r * 0.95), r * 0.14, col)
	draw_circle(c + Vector2(0, r * 0.15), r * 0.62, col)
	draw_circle(c + Vector2(-r * 0.20, r * 0.08), r * 0.055, Color(1, 1, 1, 0.8))
	draw_circle(c + Vector2(r * 0.20, r * 0.08), r * 0.055, Color(1, 1, 1, 0.8))


func _cloud(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.38, r * 0.08), r * 0.38, col)
	draw_circle(c + Vector2(0, -r * 0.12), r * 0.48, col)
	draw_circle(c + Vector2(r * 0.40, r * 0.10), r * 0.34, col)
	draw_rect(Rect2(c + Vector2(-r * 0.62, r * 0.08), Vector2(r * 1.25, r * 0.38)), col)
