extends RefCounted
## 球的统一绘制：底色 + 高光 + 底部暗边 + 细描边，营造糖果质感。

static func draw_ball(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	# 底色
	ci.draw_circle(pos, r, color)
	# 底部暗弧（厚度感）
	var dark := color.darkened(0.30)
	ci.draw_arc(pos, r * 0.88, PI * 0.15, PI * 0.85, 24, dark, r * 0.22, true)
	# 左上高光
	var hl := color.lightened(0.5)
	hl.a = 0.9
	ci.draw_circle(pos + Vector2(-r * 0.30, -r * 0.34), r * 0.38, hl)
	# 细描边
	ci.draw_arc(pos, r * 0.98, 0, TAU, 48, Color(0, 0, 0, 0.20), 1.5, true)
