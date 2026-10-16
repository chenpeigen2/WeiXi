extends RefCounted
## 球的统一绘制。两档画法：
##  - 大球（r >= 26）：投影 + 暗边 + 球形提亮 + 高光点（糖果玻璃质感）
##  - 小球（r < 26）：纯色实心 + 硬描边 + 单个高光点（清晰不糊）

const SMALL_R := 26.0


static func draw_ball(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	if r < SMALL_R:
		_draw_crisp(ci, pos, r, color)
	else:
		_draw_candy(ci, pos, r, color)


static func _draw_crisp(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	# 纯色实心 + 深色硬描边 + 实心高光点，不用半透明叠层
	ci.draw_circle(pos, r, color.darkened(0.28))
	ci.draw_circle(pos, r - 1.5, color)
	ci.draw_circle(pos + Vector2(-r * 0.28, -r * 0.32), r * 0.22, color.lightened(0.55))
	ci.draw_circle(pos + Vector2(-r * 0.28, -r * 0.32), r * 0.12, Color.WHITE)


static func _draw_candy(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
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
