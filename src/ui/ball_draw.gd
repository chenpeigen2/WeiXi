extends RefCounted
## 球的统一绘制：投影 + 暗边 + 主体 + 球形提亮 + 高光点，糖果玻璃质感。

static func draw_ball(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	# 投影
	ci.draw_circle(pos + Vector2(0, r * 0.14), r * 0.98, Color(0, 0, 0, 0.28))
	# 外圈暗边
	ci.draw_circle(pos, r, color.darkened(0.22))
	# 主体
	ci.draw_circle(pos, r * 0.92, color)
	# 球形提亮（偏左上）
	ci.draw_circle(pos + Vector2(-r * 0.10, -r * 0.12), r * 0.62, color.lightened(0.28))
	# 核心回压主色（避免发灰）
	ci.draw_circle(pos + Vector2(r * 0.06, r * 0.08), r * 0.38, color.lightened(0.08))
	# 高光点
	ci.draw_circle(pos + Vector2(-r * 0.30, -r * 0.34), r * 0.15, Color(1, 1, 1, 0.85))
