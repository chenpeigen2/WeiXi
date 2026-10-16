extends Node2D
## 双击棋盘球弹出的调色板：6 色横排 + 指向球的小三角，点选即换，点外取消。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")

const SWATCH_R := 18.0
const DX := 46.0
const HIT_R := 24.0
const PANEL_W := 290.0
const PANEL_H := 64.0
const GAP_Y := 34.0 # 面板底与目标球的距离

var active := false
var _center := Vector2.ZERO # 面板中心

var _panel: StyleBoxFlat


static func swatch_pos(center: Vector2, i: int) -> Vector2:
	return center + Vector2((float(i) - 2.5) * DX, 0)


static func hit_at(center: Vector2, pos: Vector2) -> int:
	for i in range(6):
		if pos.distance_to(swatch_pos(center, i)) <= HIT_R:
			return i
	return -1


## 面板中心夹取到屏幕内（含面板半宽145与球间距）
static func clamp_center(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, 150.0, 600.0),
		clamp(pos.y, 60.0, 1215.0)
	)


func _ready() -> void:
	visible = false
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Color(0.10, 0.11, 0.17, 0.96)
	_panel.border_color = Ui.PANEL_STROKE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(32)


func open_at(screen_pos: Vector2) -> void:
	# 面板出现在球的上方，太靠顶则放到下方
	var c := Vector2(screen_pos.x, screen_pos.y - GAP_Y - PANEL_H / 2.0)
	if c.y - PANEL_H / 2.0 < 60.0:
		c.y = screen_pos.y + GAP_Y + PANEL_H / 2.0
	_center = clamp_center(c)
	active = true
	visible = true
	queue_redraw()


func close() -> void:
	active = false
	visible = false
	queue_redraw()


func hit(pos: Vector2) -> int:
	if not active:
		return -1
	return hit_at(_center, pos)


func _draw() -> void:
	if not active:
		return
	draw_style_box(_panel, Rect2(_center - Vector2(PANEL_W, PANEL_H) / 2.0, Vector2(PANEL_W, PANEL_H)))
	for i in range(6):
		BallDraw.draw_ball(self, swatch_pos(_center, i), SWATCH_R, Ui.BALL_COLORS[i])
