extends Node2D
## 特效层：爆裂环 + 掉落球 + 三消互换滑动动画（含无效回弹）。

const BallDraw = preload("res://src/ui/ball_draw.gd")
const NumericFont = preload("res://fonts/Fredoka-Variable.ttf")

const POP_DUR := 0.30
const DROP_DUR := 0.50
const DROP_GRAVITY := 4500.0
const SPARK_GRAVITY := 900.0

var _effects: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _swap: Dictionary = {} # {a,b,color_a,color_b,r,revert,dur,t,cb}


func spawn_pop(pos: Vector2, r: float, color: Color) -> void:
	_effects.append({"kind": "pop", "pos": pos, "r": r, "color": color, "t": 0.0})
	spawn_burst(pos, color, 3, 0.75, 0.30)
	queue_redraw()


## 星星/爱心粒子爆点；count 建议 3~12，避免大量消除时粒子过密。
func spawn_burst(pos: Vector2, color: Color, count := 6, power := 1.0, heart_chance := 0.25) -> void:
	for i in range(count):
		var ang := randf() * TAU
		var speed := randf_range(80.0, 260.0) * power
		var kind := "heart" if randf() < heart_chance else "star"
		_sparks.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * speed + Vector2(0, -55.0),
			"t": 0.0,
			"life": randf_range(0.34, 0.60),
			"color": color,
			"size": randf_range(3.0, 5.6),
			"kind": kind,
		})
	queue_redraw()


## 有效互换落位：两颗球颜色混合的星心爆点。
func spawn_swap_burst(a: Vector2, b: Vector2, color_a: Color, color_b: Color) -> void:
	var mid := (a + b) * 0.5
	for i in range(10):
		var ang := randf() * TAU
		var speed := randf_range(100.0, 280.0)
		_sparks.append({
			"pos": mid,
			"vel": Vector2(cos(ang), sin(ang)) * speed + Vector2(0, -40.0),
			"t": 0.0,
			"life": randf_range(0.36, 0.62),
			"color": color_a if i % 2 == 0 else color_b,
			"size": randf_range(3.6, 6.2),
			"kind": "star" if i % 4 != 0 else "heart",
		})
	for i in range(2):
		_sparks.append({
			"pos": mid + Vector2(-8.0 + 16.0 * i, -4.0),
			"vel": Vector2(-28.0 + 56.0 * i, -110.0),
			"t": 0.0,
			"life": 0.62,
			"color": Color(1.0, 0.62, 0.75),
			"size": 5.2,
			"kind": "heart",
		})
	queue_redraw()


## 无效互换：一团低饱和小烟雾，不抢戏。
func spawn_invalid_puff(pos: Vector2) -> void:
	for i in range(6):
		var ang := randf() * TAU
		var speed := randf_range(45.0, 110.0)
		_sparks.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * speed + Vector2(0, -30.0),
			"t": 0.0,
			"life": randf_range(0.28, 0.45),
			"color": Color(0.86, 0.64, 0.72),
			"size": randf_range(2.4, 4.2),
			"kind": "dot",
		})
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
	label.pivot_offset = Vector2(150, 18)
	label.scale = Vector2(0.68, 0.68)
	add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 48.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tw.tween_property(label, "scale", Vector2(1.12, 1.12), 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(label, "scale", Vector2.ONE, 0.14).set_delay(0.16).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(label.queue_free)


## 消除后的 +分浮字：上浮淡出，给玩家“这一发有回报”的即时反馈。
func spawn_score_text(pos: Vector2, amount: int, color := Color(1.0, 0.60, 0.74)) -> void:
	if amount <= 0:
		return
	spawn_text(pos, "+%d" % amount, 24, color, NumericFont)


func clear() -> void:
	_effects.clear()
	_sparks.clear()
	_swap = {}
	for child in get_children():
		child.queue_free()
	queue_redraw()


func effect_count() -> int:
	return _effects.size()


# ---------- 三消互换动画 ----------

## 互换两球在进度 k(0..1) 时的基础位置。
## 有效互换带一点 over-shoot（先冲过目标再回弹），无效互换来回摆动。
static func swap_positions(a: Vector2, b: Vector2, k: float, revert: bool) -> Array[Vector2]:
	var t: float
	if revert:
		t = sin(PI * k)
	else:
		var kk: float = k - 1.0
		t = 1.0 + 2.70158 * kk * kk * kk + 1.70158 * kk * kk
	return [a.lerp(b, t), b.lerp(a, t)]


## 视觉层：交换时两球绕开彼此走一点弧线，并配合挤压回弹。
static func swap_visuals(a: Vector2, b: Vector2, k: float, revert: bool, r: float) -> Dictionary:
	var base: Array = swap_positions(a, b, k, revert)
	var delta := b - a
	if delta.length() < 0.001:
		delta = Vector2.RIGHT
	var dir := delta.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var arc := 0.0
	var along := 1.0
	var across := 1.0
	if revert:
		var wob: float = sin(3.0 * PI * k) * (1.0 - k)
		arc = wob * r * 0.24
		along = 1.0 + 0.05 * wob
		across = 1.0 - 0.035 * wob
	else:
		var swell: float = sin(PI * k)
		arc = swell * r * 1.05
		along = 1.0 + 0.18 * swell
		across = 1.0 - 0.08 * swell
	# 按交换方向做轴向挤压/拉伸，但不旋转球体，保持高光方向稳定。
	var dx: float = absf(dir.x)
	var dy: float = absf(dir.y)
	var sx: float = across + (along - across) * dx
	var sy: float = across + (along - across) * dy
	return {
		"a": base[0] + perp * arc,
		"b": base[1] - perp * arc,
		"scale": 1.0 + (along - 1.0) * 0.55,
		"sx": sx,
		"sy": sy,
	}


func _draw_swap_ball(pos: Vector2, r: float, color: Color, sx: float, sy: float, alpha: float) -> void:
	if alpha <= 0.001:
		return
	draw_set_transform(pos, 0.0, Vector2(sx, sy))
	BallDraw.draw_ball(self, Vector2.ZERO, r, color, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _star_shape(p: Vector2, s: float, c: Color) -> void:
	var q: float = s * 0.24
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -s), p + Vector2(q, -q), p + Vector2(s, 0), p + Vector2(q, q),
		p + Vector2(0, s), p + Vector2(-q, q), p + Vector2(-s, 0), p + Vector2(-q, -q),
	]), c)


func _heart_shape(p: Vector2, s: float, c: Color) -> void:
	draw_circle(p + Vector2(-s * 0.30, -s * 0.08), s * 0.36, c)
	draw_circle(p + Vector2(s * 0.30, -s * 0.08), s * 0.36, c)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.60, -s * 0.04),
		p + Vector2(s * 0.60, -s * 0.04),
		p + Vector2(0, s * 0.68),
	]), c)


func _sparkle(p: Vector2, s: float, c: Color) -> void:
	_star_shape(p, s, c)
	draw_circle(p, s * 0.16, Color(1, 1, 1, c.a * 0.8))

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
	if not _sparks.is_empty():
		var keep_sparks: Array[Dictionary] = []
		for sp in _sparks:
			sp["t"] += delta
			if sp["t"] < sp["life"]:
				sp["vel"].y += SPARK_GRAVITY * delta
				sp["pos"] += sp["vel"] * delta
				keep_sparks.append(sp)
		_sparks = keep_sparks
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
		var vis: Dictionary = swap_visuals(_swap["a"], _swap["b"], k, _swap["revert"], _swap["r"])
		for j in [1, 2, 3]:
			var vk: float = k - 0.06 * float(j)
			if vk <= 0.0:
				continue
			var trail: Dictionary = swap_visuals(_swap["a"], _swap["b"], vk, _swap["revert"], _swap["r"])
			_draw_swap_ball(trail["a"], _swap["r"] * 0.94, _swap["color_a"], float(trail["sx"]) * 0.94, float(trail["sy"]) * 0.94, 0.13 / float(j))
			_draw_swap_ball(trail["b"], _swap["r"] * 0.94, _swap["color_b"], float(trail["sx"]) * 0.94, float(trail["sy"]) * 0.94, 0.13 / float(j))
		_draw_swap_ball(vis["a"], _swap["r"], _swap["color_a"], float(vis["sx"]), float(vis["sy"]), 1.0)
		_draw_swap_ball(vis["b"], _swap["r"], _swap["color_b"], float(vis["sx"]), float(vis["sy"]), 1.0)
		var mid: Vector2 = (_swap["a"] + _swap["b"]) * 0.5
		if _swap["revert"]:
			var no_a: float = 0.28 * sin(PI * k)
			draw_arc(mid, _swap["r"] * 0.62, 0, TAU, 28, Color(0.85, 0.55, 0.65, no_a), 2.4, true)
		else:
			var spark_a: float = 0.75 * sin(PI * k)
			if spark_a > 0.01:
				draw_arc(mid, _swap["r"] * 0.62, 0, TAU, 32, Color(1.0, 0.80, 0.88, spark_a * 0.45), 2.2, true)
				_sparkle(mid, _swap["r"] * 0.78 * (0.65 + 0.35 * spark_a), Color(1, 0.96, 0.90, spark_a))
	for e in _effects:
		var dur: float = POP_DUR if e["kind"] == "pop" else DROP_DUR
		var k: float = clamp(e["t"] / dur, 0.0, 1.0)
		var c: Color = e["color"]
		if e["kind"] == "pop":
			c.a = 0.85 * (1.0 - k)
			draw_arc(e["pos"], e["r"] * (1.0 + k * 1.1), 0, TAU, 32, c, max(1.0, 5.0 * (1.0 - k)), true)
			var inner := Color(c.r, c.g, c.b, 0.50 * (1.0 - k))
			draw_arc(e["pos"], e["r"] * (0.65 + 0.55 * k), 0, TAU, 28, inner, 2.2, true)
			if k < 0.35:
				draw_circle(e["pos"], e["r"] * (0.52 + 0.5 * k), Color(1, 1, 1, 0.24 * (1.0 - k / 0.35)))
			c.a = 0.45 * (1.0 - k)
			draw_circle(e["pos"], e["r"] * (1.0 - k) * 0.9, c)
		else:
			BallDraw.draw_ball(self, e["pos"], e["r"] * 0.95, e["color"], 1.0 - k * k)
	for sp in _sparks:
		var sk: float = sp["t"] / sp["life"]
		var sc: Color = sp["color"]
		sc.a *= (1.0 - sk)
		var ss: float = sp["size"] * (1.0 - 0.25 * sk)
		if sp["kind"] == "heart":
			_heart_shape(sp["pos"], ss, sc)
		elif sp["kind"] == "star":
			_star_shape(sp["pos"], ss, sc)
		else:
			draw_circle(sp["pos"], ss * 0.8, sc)
