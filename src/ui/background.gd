extends Node2D
## 背景：纵向渐变 + 顶部微光晕。

const Ui = preload("res://src/ui/theme.gd")

const BANDS := 32


func _draw() -> void:
	for i in range(BANDS):
		var t := float(i) / BANDS
		var col := Ui.BG_TOP.lerp(Ui.BG_BOTTOM, t)
		draw_rect(Rect2(0, t * Ui.SCREEN_H, Ui.SCREEN_W, Ui.SCREEN_H / BANDS + 1), col)
	# 顶部微光
	var glow := Ui.ACCENT
	glow.a = 0.03
	draw_circle(Vector2(Ui.SCREEN_W * 0.5, -90), 390, glow)
