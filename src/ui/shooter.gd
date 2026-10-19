extends Node2D
## 发射器：底座 + 弹道预测点流 + 落点幽灵球 + 当前/下一球 + 飞球动画。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const FlightPath = preload("res://src/ui/flight_path.gd")
const UiFont = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

const FLY_SPEED := 2700.0 # 像素/秒
const FLY_MIN := 0.08
const FLY_MAX := 0.45

var game: RefCounted
var aim_dir := Vector2.UP

var _flight: Dictionary = {} # {path,total,d,speed,pos,color,cb}
var _preview_points := PackedVector2Array()
var _preview_target := Vector2.ZERO
var _preview_color := 0
var _preview_bounces := PackedVector2Array()
var _t := 0.0
var _launch := 1.0


## 瞄准方向限制在水平线以上，并保持单位向量
static func clamp_aim(dir: Vector2) -> Vector2:
	var d := dir.normalized()
	if d == Vector2.ZERO:
		return Vector2.UP
	if d.y > -0.15:
		d = Vector2(d.x, -0.15).normalized()
	return d


func set_aim(dir: Vector2) -> void:
	aim_dir = clamp_aim(dir)
	queue_redraw()


func set_preview(points: PackedVector2Array, target: Vector2, color: int, bounces := PackedVector2Array()) -> void:
	_preview_points = points
	_preview_target = target
	_preview_color = color
	_preview_bounces = bounces
	queue_redraw()


func _star_marker(p: Vector2, s: float, c: Color) -> void:
	var q: float = s * 0.22
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -s), p + Vector2(q, -q), p + Vector2(s, 0), p + Vector2(q, q),
		p + Vector2(0, s), p + Vector2(-q, q), p + Vector2(-s, 0), p + Vector2(-q, -q),
	]), c)


func is_flying() -> bool:
	return not _flight.is_empty()


## 沿真实弹道折线飞行（与预览点流完全一致，含弹墙拐弯）
func start_flight(path: PackedVector2Array, color: int, on_finished: Callable) -> void:
	if path.is_empty():
		return
	var total := FlightPath.length(path)
	var duration: float = clamp(total / FLY_SPEED, FLY_MIN, FLY_MAX)
	_launch = 0.0
	_flight = {"path": path, "total": total, "d": 0.0, "speed": total / duration, "pos": path[0], "color": color, "cb": on_finished}


func _process(delta: float) -> void:
	_t += delta
	_launch = minf(1.0, _launch + delta / 0.32)
	if _flight.is_empty():
		queue_redraw()
		return
	_flight["d"] += _flight["speed"] * delta
	if _flight["d"] >= _flight["total"]:
		var cb: Callable = _flight["cb"]
		_flight = {}
		cb.call()
	else:
		_flight["pos"] = FlightPath.sample(_flight["path"], _flight["d"])
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var p := Ui.SHOOTER_POS
	var r: float = game.layout.radius

	# 底座星能环：白环打底，粉色弧显示当前星星进度；满环进入 Fever。
	draw_arc(p, r * 1.5, 0, TAU, 64, Color(0.50, 0.38, 0.54, 0.30), 4.0, true)
	var star_ratio: float = float(game.scorer.star) / 100.0
	if game.scorer.fever_charges > 0:
		var halo := Ui.ACCENT
		halo.a = 0.10
		draw_arc(p, r * 1.75, 0, TAU, 64, halo, 8.0, true)
		draw_arc(p, r * 1.5, 0, TAU, 64, Ui.ACCENT, 4.0, true)
	elif star_ratio > 0.0:
		draw_arc(p, r * 1.5, -PI / 2.0, -PI / 2.0 + TAU * star_ratio, 64, Ui.ACCENT, 4.0, true)
	# 星能环顶端的小星星：既是装饰，也是“这是一条能量环”的提示。
	_star_marker(p + Vector2(0, -r * 1.5 + 1.5 * sin(_t * 3.0)), 5.0 + 0.5 * sin(_t * 3.0), Ui.ACCENT)

	# 弹道预测：带颜色光晕的点流 + 高可读的落点幽灵球
	if _flight.is_empty():
		var n: int = _preview_points.size()
		for i in range(n):
			var pt: Vector2 = _preview_points[i]
			var t: float = float(i) / maxf(1.0, float(n - 1))
			var wave: float = 0.5 + 0.5 * sin(_t * 6.0 - float(i) * 0.55)
			var halo := Ui.BALL_COLORS[_preview_color]
			halo.a = 0.20 * (1.0 - t) * (0.8 + 0.2 * wave)
			draw_circle(pt, 6.4 + 1.5 * wave, halo)
			var dot := Ui.INK
			dot.a = lerpf(0.58, 0.18, t) * (0.8 + 0.2 * wave)
			draw_circle(pt, 3.4 + 0.7 * wave, dot)
		for bp in _preview_bounces:
			var bounce := Ui.BALL_COLORS[_preview_color]
			bounce.a = 0.10
			draw_circle(bp, r * 0.92, bounce)
			var bounce_ring := Ui.BALL_COLORS[_preview_color]
			bounce_ring.a = 0.35
			draw_arc(bp, r * (0.99 + 0.025 * sin(_t * 5.0)), 0, TAU, 32, bounce_ring, 1.5, true)
		if not _preview_points.is_empty():
			# alpha 0.30 的橙球叠在深蓝上会发褐；提高填充并加同色描边。
			var gs: float = 1.0 + 0.02 * sin(_t * 4.0)
			var ghost := Ui.BALL_COLORS[_preview_color]
			ghost.a = 0.55
			draw_circle(_preview_target, r * 0.95 * gs, ghost)
			var ring := Ui.BALL_COLORS[_preview_color]
			ring.a = 0.95
			draw_arc(_preview_target, r * gs, 0, TAU, 40, ring, 2.5, true)
			draw_arc(_preview_target, r * 0.52 * gs, 0, TAU, 32, Color(1.0, 0.96, 0.93, 0.75), 1.5, true)
			draw_circle(_preview_target, 3.0 * gs, Color(1.0, 0.96, 0.93, 0.90))

	# 当前球；5+ 后下一发是星星炸弹，用光晕 + 星徽提示
	if game.star_shot:
		var shot_glow := Ui.ACCENT
		shot_glow.a = 0.16
		draw_circle(p, r * 1.16, shot_glow)
	var idle_s: float = 1.0 + (0.018 * sin(_t * 3.1) if _flight.is_empty() else 0.0)
	draw_set_transform(p, 0.0, Vector2(idle_s, idle_s))
	BallDraw.draw_ball(self, Vector2.ZERO, r, Ui.BALL_COLORS[game.current_color], 1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if game.star_shot:
		_star_marker(p + Vector2(r * 0.72, -r * 0.72), 9.0, Color(1.0, 0.97, 0.94, 0.98))
	# 发射后的一圈后坐涟漪
	if _launch < 1.0:
		var k: float = _launch
		draw_arc(p, r * (1.22 + 0.85 * k), 0, TAU, 48, Color(1.0, 0.88, 0.94, 0.38 * (1.0 - k)), 2.6, true)

	# 飞行球 + 一点点拖尾，让碰撞前的速度感更明显
	if not _flight.is_empty():
		for k in [1, 2, 3]:
			var d: float = _flight["d"] - k * 13.0
			if d > 0.0:
				var tp := FlightPath.sample(_flight["path"], d)
				var trail := Ui.BALL_COLORS[_flight["color"]]
				trail.a = 0.16 / float(k)
				draw_circle(tp, r * (0.82 - k * 0.07), trail)
		BallDraw.draw_ball(self, _flight["pos"], r, Ui.BALL_COLORS[_flight["color"]], 1.0, true)

	# 下一球预告（右侧小球 + 引导环 + 标签）
	var next_pos := p + Vector2(r * 2.9, r * 0.7 + 1.2 * sin(_t * 3.2 + 1.0))
	draw_arc(next_pos, r * (0.73 + 0.015 * sin(_t * 4.0)), 0, TAU, 32, Color(0.50, 0.38, 0.54, 0.38), 2.0, true)
	BallDraw.draw_ball(self, next_pos, r * 0.53, Ui.BALL_COLORS[game.next_color], 1.0, true)
	draw_string(
		UiFont, Vector2(next_pos.x - 28.0, next_pos.y + 40.0), "下一颗",
		HORIZONTAL_ALIGNMENT_CENTER, 56.0, 13, Ui.TEXT_DIM
	)
