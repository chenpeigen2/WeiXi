extends Node2D
## 双击棋盘球弹出的调色板：6 色横排 + 指向目标球的三角，点选即换，点外取消。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")

const SWATCH_R := 22.0
const DX := 52.0
const HIT_R := 26.0
const PANEL_W := 340.0
const PANEL_H := 76.0
const GAP_Y := 34.0 # 面板底与目标球的距离
const ARROW := 10.0

var active := false
var current_color := -1 # 目标球当前颜色，用于在调色板里标一下
var _center := Vector2.ZERO # 面板中心
var _above := true
var _hover := -1
var _anchor_x := 0.0

var _panel: StyleBoxFlat


static func swatch_pos(center: Vector2, i: int) -> Vector2:
	return center + Vector2((float(i) - 2.5) * DX, 0)


static func hit_at(center: Vector2, pos: Vector2) -> int:
	for i in range(6):
		if pos.distance_to(swatch_pos(center, i)) <= HIT_R:
			return i
	return -1


## 面板中心夹取到屏幕内（含面板半宽 170 与面板半高 38）
static func clamp_center(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, PANEL_W * 0.5 + 5.0, Ui.SCREEN_W - PANEL_W * 0.5 - 5.0),
		clampf(pos.y, 60.0, Ui.SCREEN_H - 60.0)
	)


func _ready() -> void:
	visible = false
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Color(1.0, 0.94, 0.94, 0.98)
	_panel.border_color = Ui.ROSE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(int(Ui.PANEL_RADIUS_LARGE))
	_panel.shadow_color = Color(0.12, 0.05, 0.09, 0.35)
	_panel.shadow_size = 12
	_panel.shadow_offset = Vector2(0, 6)


func open_at(screen_pos: Vector2) -> void:
	# 面板出现在球的上方，太靠顶则放到下方
	var c := Vector2(screen_pos.x, screen_pos.y - GAP_Y - PANEL_H / 2.0)
	_above = true
	if c.y - PANEL_H / 2.0 < 60.0:
		c.y = screen_pos.y + GAP_Y + PANEL_H / 2.0
		_above = false
	_center = clamp_center(c)
	# 三角尽量对齐目标球，但不允许跑出面板边缘。
	_anchor_x = clampf(
		screen_pos.x,
		_center.x - PANEL_W / 2.0 + 24.0,
		_center.x + PANEL_W / 2.0 - 24.0
	)
	_hover = -1
	active = true
	visible = true
	queue_redraw()


func close() -> void:
	active = false
	_hover = -1
	visible = false
	queue_redraw()


func hit(pos: Vector2) -> int:
	if not active:
		return -1
	return hit_at(_center, pos)


func set_hover(pos: Vector2) -> void:
	if not active:
		return
	var i := hit_at(_center, pos)
	if i != _hover:
		_hover = i
		queue_redraw()


func _draw() -> void:
	if not active:
		return

	var rect := Rect2(_center - Vector2(PANEL_W, PANEL_H) / 2.0, Vector2(PANEL_W, PANEL_H))
	draw_style_box(_panel, rect)
	draw_line(
		Vector2(rect.position.x + 28.0, rect.position.y + 1.0),
		Vector2(rect.end.x - 28.0, rect.position.y + 1.0),
		Color(1.0, 0.66, 0.76, 0.65), 1.0
	)
	var lace := Color(0.80, 0.73, 0.95, 0.55)
	var dx := rect.position.x + 28.0
	while dx < rect.end.x - 28.0:
		draw_circle(Vector2(dx, rect.position.y + 8.0), 2.0, lace)
		dx += 24.0

	# 指向目标球的三角：上方弹出时朝下，下方弹出时朝上。
	var half_h := PANEL_H / 2.0
	var base_y := _center.y + half_h
	var tip_y := base_y + ARROW
	if not _above:
		base_y = _center.y - half_h
		tip_y = base_y - ARROW
	var tri := PackedVector2Array([
		Vector2(_anchor_x, tip_y),
		Vector2(_anchor_x - 11.0, base_y),
		Vector2(_anchor_x + 11.0, base_y),
	])
	draw_colored_polygon(tri, _panel.bg_color)
	draw_line(Vector2(_anchor_x - 11.0, base_y), Vector2(_anchor_x, tip_y), Ui.PANEL_STROKE, 1.0, true)
	draw_line(Vector2(_anchor_x + 11.0, base_y), Vector2(_anchor_x, tip_y), Ui.PANEL_STROKE, 1.0, true)

	for i in range(6):
		var p := swatch_pos(_center, i)
		var r := SWATCH_R * (1.12 if i == current_color else 1.0)
		if i == current_color:
			var halo := Ui.ACCENT
			halo.a = 0.08
			draw_circle(p, r + 10.0, halo)
		elif i == _hover:
			draw_circle(p, r + 8.0, Color(1.0, 0.70, 0.80, 0.22))
		BallDraw.draw_ball(self, p, r, Ui.BALL_COLORS[i])
		if i == _hover:
			draw_arc(p, r + 3.0, 0, TAU, 36, Ui.HEART, 2.0, true)
		if i == current_color:
			draw_arc(p, r + 6.0, 0, TAU, 36, Ui.ACCENT, 2.0, true)
