extends Node2D
## 发射器：底座 + 弹道预测点流 + 落点幽灵球 + 当前/下一球 + 飞球动画。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const FlightPath = preload("res://src/ui/flight_path.gd")
const Game = preload("res://src/logic/game.gd")

const FLY_SPEED := 2700.0 # 像素/秒
const FLY_MIN := 0.08
const FLY_MAX := 0.45

var game: RefCounted
var aim_dir := Vector2.UP

var _flight: Dictionary = {} # {path,total,d,speed,pos,color,cb}
var _preview_points := PackedVector2Array()
var _preview_target := Vector2.ZERO
var _preview_color := 0


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


func set_preview(points: PackedVector2Array, target: Vector2, color: int) -> void:
	_preview_points = points
	_preview_target = target
	_preview_color = color
	queue_redraw()


func is_flying() -> bool:
	return not _flight.is_empty()


## 沿真实弹道折线飞行（与预览点流完全一致，含弹墙拐弯）
func start_flight(path: PackedVector2Array, color: int, on_finished: Callable) -> void:
	if path.is_empty():
		return
	var total := FlightPath.length(path)
	var duration: float = clamp(total / FLY_SPEED, FLY_MIN, FLY_MAX)
	_flight = {"path": path, "total": total, "d": 0.0, "speed": total / duration, "pos": path[0], "color": color, "cb": on_finished}


func _process(delta: float) -> void:
	if _flight.is_empty():
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

	# 底座：整圈细环 + 上半金色弧
	draw_arc(p, r * 1.5, 0, TAU, 48, Color(1, 1, 1, 0.12), 4.0, true)
	draw_arc(p, r * 1.5, PI, TAU, 24, Ui.ACCENT.darkened(0.15), 4.0, true)

	# 弹道预测：点流 + 落点幽灵球
	if game.mode == Game.Mode.SHOOT and _flight.is_empty():
		for pt in _preview_points:
			draw_circle(pt, 5.0, Color(1, 1, 1, 0.35))
		if not _preview_points.is_empty():
			var ghost := Ui.BALL_COLORS[_preview_color]
			ghost.a = 0.30
			draw_circle(_preview_target, r * 0.95, ghost)
			draw_arc(_preview_target, r, 0, TAU, 40, Color(1, 1, 1, 0.55), 2.5, true)

	# 当前球
	BallDraw.draw_ball(self, p, r, Ui.BALL_COLORS[game.current_color])

	# 飞行球
	if not _flight.is_empty():
		BallDraw.draw_ball(self, _flight["pos"], r, Ui.BALL_COLORS[_flight["color"]])

	# 下一球预告（右侧小球 + 引导环）
	var next_pos := p + Vector2(r * 2.9, r * 0.7)
	draw_arc(next_pos, r * 0.73, 0, TAU, 32, Color(1, 1, 1, 0.15), 2.0, true)
	BallDraw.draw_ball(self, next_pos, r * 0.53, Ui.BALL_COLORS[game.next_color])
