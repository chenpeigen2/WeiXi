extends Node2D
## 消除特效层：爆裂环（放大淡出）+ 掉落球（重力加速下坠淡出）。

const POP_DUR := 0.30
const DROP_DUR := 0.50
const DROP_GRAVITY := 4200.0

var _effects: Array[Dictionary] = []


func spawn_pop(pos: Vector2, r: float, color: Color) -> void:
	_effects.append({"kind": "pop", "pos": pos, "r": r, "color": color, "t": 0.0})
	queue_redraw()


func spawn_drop(pos: Vector2, r: float, color: Color) -> void:
	_effects.append({"kind": "drop", "pos": pos, "vel": Vector2(0, 60), "r": r, "color": color, "t": 0.0})
	queue_redraw()


func effect_count() -> int:
	return _effects.size()


func _process(delta: float) -> void:
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
			c.a = 1.0 - k * k
			draw_circle(e["pos"], e["r"] * 0.95, c)
