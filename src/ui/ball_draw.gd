extends RefCounted
## 球的统一绘制。两档画法，全部是 _draw 矢量，不依赖任何图片：
##  - 大球（r >= 28）：投影 + 暗边 + 球形提亮 + 高光点（糖果玻璃质感）
##  - 小球（r < 28）：20 层同心圆径向渐变 + 柔光 + 底边反射光（等价 VectorDrawable 的矢量球）
## alpha 用于掉落/淡出特效，默认 1.0。

const SMALL_R := 28.0


static func draw_ball(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float = 1.0) -> void:
	if alpha <= 0.001:
		return
	if r < SMALL_R:
		_draw_crisp(ci, pos, r, color, alpha)
	else:
		_draw_candy(ci, pos, r, color, alpha)


## Compatibility 渲染器不支持 2D MSAA，必须让圆自己开抗锯齿。
static func _circle(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	ci.draw_circle(pos, r, color, true, -1.0, true)


## 真正的逐顶点径向渐变：一个三角扇，中心色 -> 边缘色。
## 128 段在 8K 下弦高 < 0.15px；不是贴图，也不会出现单多边形的 0° 接缝。
static func _gradient_disc(ci: CanvasItem, pos: Vector2, r: float, core: Color, edge: Color, segments := 128) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	points.append(pos)
	colors.append(core)
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		points.append(pos + Vector2(cos(a), sin(a)) * r)
		colors.append(edge)
	for i in range(segments):
		indices.append(0)
		indices.append(1 + i)
		indices.append(1 + ((i + 1) % segments))
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, colors)


static func _draw_crisp(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float) -> void:
	# 逐顶点三角扇径向渐变：没有接缝，2K/4K/8K 放大都不会出现色带。
	# 这不是贴图，等价于 VectorDrawable 的渐变填充 + 路径裁剪。
	var core := color.lightened(0.14)
	core.a *= alpha
	var edge := color.darkened(0.32)
	edge.a *= alpha
	# 先铺一个抗锯齿的深色圆，再把渐变盘盖上去，形成干净的 1.2px 深色外圈。
	# 外缘由 draw_circle(antialiased=true) 负责，不会有 arc 细线在低分辨率下发虚/发点。
	# 抗锯齿边缘色圆 + 同色边的三角扇渐变：外缘由 draw_circle 抗锯齿，
	# 渐变盘的硬边被同色圆完全盖住，不会出现点状锯齿。
	_circle(ci, pos, r, edge)
	_gradient_disc(ci, pos, r - 1.2, core, edge, 1024)

	# 左上柔光（两层渐变） + 白色高光点
	var gloss := color.lightened(0.42)
	var gloss_pos := pos + Vector2(-r * 0.26, -r * 0.30)
	gloss.a = 0.14 * alpha
	_circle(ci, gloss_pos, r * 0.48, gloss)
	gloss.a = 0.24 * alpha
	_circle(ci, gloss_pos, r * 0.30, gloss)
	_circle(
		ci, pos + Vector2(-r * 0.30, -r * 0.34), r * 0.13,
		Color(1, 1, 1, 0.95 * alpha)
	)

	# 底部反射光：小球的“玻璃感”来源
	var rim := color.lightened(0.50)
	rim.a = 0.35 * alpha
	ci.draw_arc(pos, r * 0.84, PI * 0.18, PI * 0.82, 24, rim, 1.3, true)


static func _draw_candy(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float) -> void:
	# 投影
	_circle(ci, pos + Vector2(0, r * 0.14), r * 0.98, Color(0, 0, 0, 0.28 * alpha))
	# 外圈暗边
	var edge := color.darkened(0.22)
	edge.a *= alpha
	_circle(ci, pos, r, edge)
	# 主体
	var body := color
	body.a *= alpha
	_circle(ci, pos, r * 0.92, body)
	# 球形提亮（偏左上）
	var light := color.lightened(0.28)
	light.a *= alpha
	_circle(ci, pos + Vector2(-r * 0.10, -r * 0.12), r * 0.62, light)
	# 核心回压主色（避免发灰）
	var core := color.lightened(0.08)
	core.a *= alpha
	_circle(ci, pos + Vector2(r * 0.06, r * 0.08), r * 0.38, core)
	# 底部反射光：让球更像玻璃糖果，而不是平面圆
	var rim := color.lightened(0.45)
	rim.a = 0.30 * alpha
	ci.draw_arc(pos, r * 0.86, PI * 0.18, PI * 0.82, 28, rim, 1.5, true)
	# 高光点
	_circle(ci, pos + Vector2(-r * 0.30, -r * 0.34), r * 0.15, Color(1, 1, 1, 0.85 * alpha))
