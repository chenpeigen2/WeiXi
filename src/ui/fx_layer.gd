extends Node2D
## 特效层：爆裂环 + 掉落球 + 三消互换滑动动画（含无效回弹）。

const BallDraw = preload("res://src/ui/ball_draw.gd")
const NumericFont = preload("res://fonts/Fredoka-Variable.ttf")

const POP_DUR := 0.30
const DROP_DUR := 0.50
const DROP_GRAVITY := 4500.0

var _effects: Array[Dictionary] = []
var _swap: Dictionary = {} # {a,b,color_a,color_b,r,revert,dur,t,cb}


func spawn_pop(pos: Vector2, r: float, color: Color) -> void:
	_effects.append({"kind": "pop", "pos": pos, "r": r, "color": color, "t": 0.0})
	queue_redraw()


func spawn_drop(pos: Vector2, r: float, color: Color) -> void:
	_effects.append({"kind": "drop", "pos": pos, "vel": Vector2(0, 60), "r": r, "color": color, "t": 0.0})
	queue_redraw()


## 通用浮字：+分 / BANK / 星尘 / 愿望达成 都复用它。
func spawn_text(pos: Vector2, text: String, size := 24, color := Color(1.0, 0.60, 0.74), font: Font = null) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(300, 36)
	label.position = pos - Vector2(150, 20)
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.10, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 48.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)


## 消除后的 +分浮字：上浮淡出，给玩家“这一发有回报”的即时反馈。
func spawn_score_text(pos: Vector2, amount: int, color := Color(1.0, 0.60, 0.74)) -> void:
	if amount <= 0:
		return
	spawn_text(pos, "+%d" % amount, 24, color, NumericFont)


func clear() -> void:
	_effects.clear()
	_swap = {}
	for child in get_children():
		child.queue_free()
	queue_redraw()


func effect_count() -> int:
	return _effects.size()


# ---------- 三消互换动画 ----------

## 互换两球在进度 k(0..1) 时的位置对。
## revert=true 表示无效互换：前半程滑向对方，后半程滑回原位（回弹）。
static func swap_positions(a: Vector2, b: Vector2, k: float, revert: bool) -> Array[Vector2]:
	var t: float
	if revert:
		t = k * 2.0 if k < 0.5 else (1.0 - k) * 2.0
	else:
		t = k
	# smoothstep 缓动
	t = t * t * (3.0 - 2.0 * t)
	return [a.lerp(b, t), b.lerp(a, t)]


func play_swap(a: Vector2, b: Vector2, color_a: Color, color_b: Color, r: float, revert: bool, dur: float, on_done: Callable) -> void:
	_swap = {"a": a, "b": b, "color_a": color_a, "color_b": color_b, "r": r, "revert": revert, "dur": dur, "t": 0.0, "cb": on_done}
	queue_redraw()


func is_swapping() -> bool:
	return not _swap.is_empty()


func _process(delta: float) -> void:
	if not _swap.is_empty():
		_swap["t"] += delta
		if _swap["t"] >= _swap["dur"]:
			var cb: Callable = _swap["cb"]
			_swap = {}
			cb.call()
		queue_redraw()
	if _effects.is_empty():
		return
	var keep: Array[Dictionary] = []
	for e in _effects:
		e["t"] += delta
		var dur: float = POP_DUR if e["kind"] == "pop" else DROP_DUR
		if e["t"] < dur:
			if e["kind"] == "drop":
				e["vel"].y += DROP_GRAVITY * delta
				e["pos"] += e["vel"] * delta
			keep.append(e)
	_effects = keep
	queue_redraw()


func _draw() -> void:
	if not _swap.is_empty():
		var k: float = clamp(_swap["t"] / _swap["dur"], 0.0, 1.0)
		var pos: Array[Vector2] = swap_positions(_swap["a"], _swap["b"], k, _swap["revert"])
		BallDraw.draw_ball(self, pos[0], _swap["r"], _swap["color_a"])
		BallDraw.draw_ball(self, pos[1], _swap["r"], _swap["color_b"])
	for e in _effects:
		var dur: float = POP_DUR if e["kind"] == "pop" else DROP_DUR
		var k: float = clamp(e["t"] / dur, 0.0, 1.0)
		var c: Color = e["color"]
		if e["kind"] == "pop":
			c.a = 0.85 * (1.0 - k)
			draw_arc(e["pos"], e["r"] * (1.0 + k * 1.1), 0, TAU, 32, c, max(1.0, 5.0 * (1.0 - k)), true)
			c.a = 0.45 * (1.0 - k)
			draw_circle(e["pos"], e["r"] * (1.0 - k) * 0.9, c)
		else:
			BallDraw.draw_ball(self, e["pos"], e["r"] * 0.95, e["color"], 1.0 - k * k)
