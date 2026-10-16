extends Node2D
## 背景：纵向渐变 + 缓缓上浮的氛围气泡 + 四角压暗 + 顶部微光。

const Ui = preload("res://src/ui/theme.gd")

const BANDS := 32

var _bubbles: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 # 固定种子，布局稳定
	for i in range(14):
		_bubbles.append({
			"x": rng.randf_range(20, Ui.SCREEN_W - 20),
			"y": rng.randf_range(0, Ui.SCREEN_H),
			"r": rng.randf_range(6, 26),
			"speed": rng.randf_range(8, 22),
			"a": rng.randf_range(0.03, 0.07),
		})


func _process(delta: float) -> void:
	for b in _bubbles:
		b["y"] -= b["speed"] * delta
		if b["y"] < -30:
			b["y"] = Ui.SCREEN_H + 30
	queue_redraw()


func _draw() -> void:
	# 渐变
	for i in range(BANDS):
		var t := float(i) / BANDS
		var col := Ui.BG_TOP.lerp(Ui.BG_BOTTOM, t)
		draw_rect(Rect2(0, t * Ui.SCREEN_H, Ui.SCREEN_W, Ui.SCREEN_H / BANDS + 1), col)
	# 氛围气泡
	for b in _bubbles:
		draw_circle(Vector2(b["x"], b["y"]), b["r"], Color(1, 1, 1, b["a"]))
	# 四角压暗
	var vignette := Color(0, 0, 0, 0.16)
	for corner in [Vector2.ZERO, Vector2(Ui.SCREEN_W, 0), Vector2(0, Ui.SCREEN_H), Vector2(Ui.SCREEN_W, Ui.SCREEN_H)]:
		draw_circle(corner, 200, vignette)
	# 顶部微光
	var glow := Ui.ACCENT
	glow.a = 0.035
	draw_circle(Vector2(Ui.SCREEN_W * 0.5, -70), 260, glow)
