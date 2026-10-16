extends Node2D
## 发射器：底座 + 瞄准虚线 + 当前球/下一球预告 + 飞球动画。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const Game = preload("res://src/logic/game.gd")

const FLY_TIME := 0.16

var game: RefCounted
var aim_dir := Vector2.UP

var _flight: Dictionary = {} # {from,to,pos,t,color,cb}


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


func is_flying() -> bool:
	return not _flight.is_empty()


func start_flight(from_pos: Vector2, to_pos: Vector2, color: int, on_finished: Callable) -> void:
	_flight = {"from": from_pos, "to": to_pos, "pos": from_pos, "t": 0.0, "color": color, "cb": on_finished}


func _process(delta: float) -> void:
	if _flight.is_empty():
		return
	_flight["t"] += delta / FLY_TIME
	if _flight["t"] >= 1.0:
		var cb: Callable = _flight["cb"]
		_flight = {}
		cb.call()
	else:
		_flight["pos"] = _flight["from"].lerp(_flight["to"], _flight["t"])
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var p := Ui.SHOOTER_POS

	# 底座：整圈细环 + 上半金色弧
	draw_arc(p, 45, 0, TAU, 48, Color(1, 1, 1, 0.12), 4.0, true)
	draw_arc(p, 45, PI, TAU, 24, Ui.ACCENT.darkened(0.15), 4.0, true)

	# 瞄准虚线
	if game.mode == Game.Mode.SHOOT and _flight.is_empty():
		draw_dashed_line(p + aim_dir * 54.0, p + aim_dir * 225.0, Color(1, 1, 1, 0.35), 3.5, 14.0)

	# 当前球
	BallDraw.draw_ball(self, p, game.layout.radius, Ui.BALL_COLORS[game.current_color])

	# 飞行球
	if not _flight.is_empty():
		BallDraw.draw_ball(self, _flight["pos"], game.layout.radius, Ui.BALL_COLORS[_flight["color"]])

	# 下一球预告（右侧小球 + 引导环）
	var next_pos := p + Vector2(87, 21)
	draw_arc(next_pos, 22, 0, TAU, 32, Color(1, 1, 1, 0.15), 2.0, true)
	BallDraw.draw_ball(self, next_pos, 16.0, Ui.BALL_COLORS[game.next_color])
