extends RefCounted
## 球的统一绘制。两档画法：
##  - 大球（r >= 26）：投影 + 暗边 + 球形提亮 + 高光点（糖果玻璃质感）
##  - 小球（r < 26）：纯色实心 + 硬描边 + 单个高光点（清晰不糊）
## alpha 用于掉落/淡出特效，默认 1.0。

const SMALL_R := 26.0


static func draw_ball(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float = 1.0) -> void:
	if alpha <= 0.001:
		return
	if r < SMALL_R:
		_draw_crisp(ci, pos, r, color, alpha)
	else:
		_draw_candy(ci, pos, r, color, alpha)


static func _draw_crisp(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float) -> void:
	# 纯色实心 + 深色硬描边 + 实心高光点，不用半透明叠层
	var edge := color.darkened(0.28)
	edge.a *= alpha
	var body := color
	body.a *= alpha
	var light := color.lightened(0.55)
	light.a *= alpha
	var dot := Color.WHITE
	dot.a *= alpha
	ci.draw_circle(pos, r, edge)
	ci.draw_circle(pos, r - 1.5, body)
	ci.draw_circle(pos + Vector2(-r * 0.28, -r * 0.32), r * 0.22, light)
	ci.draw_circle(pos + Vector2(-r * 0.28, -r * 0.32), r * 0.12, dot)


static func _draw_candy(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float) -> void:
	# 投影
	ci.draw_circle(pos + Vector2(0, r * 0.14), r * 0.98, Color(0, 0, 0, 0.28 * alpha))
	# 外圈暗边
	var edge := color.darkened(0.22)
	edge.a *= alpha
	ci.draw_circle(pos, r, edge)
	# 主体
	var body := color
	body.a *= alpha
	ci.draw_circle(pos, r * 0.92, body)
	# 球形提亮（偏左上）
	var light := color.lightened(0.28)
	light.a *= alpha
	ci.draw_circle(pos + Vector2(-r * 0.10, -r * 0.12), r * 0.62, light)
	# 核心回压主色（避免发灰）
	var core := color.lightened(0.08)
	core.a *= alpha
	ci.draw_circle(pos + Vector2(r * 0.06, r * 0.08), r * 0.38, core)
	# 高光点
	ci.draw_circle(pos + Vector2(-r * 0.30, -r * 0.34), r * 0.15, Color(1, 1, 1, 0.85 * alpha))
