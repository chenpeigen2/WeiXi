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


static func _draw_crisp(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float) -> void:
	# 多层同心圆做径向渐变：没有接缝，放大到任意尺寸都平滑。
	# 这不是贴图，等价于 VectorDrawable 的渐变填充 + 路径裁剪。
	var core := color.lightened(0.14)
	core.a *= alpha
	var edge := color.darkened(0.32)
	edge.a *= alpha
	var rings := 20
	for i in range(rings):
		var t := float(i) / float(rings - 1) # 0=边缘, 1=球心
		var rr: float = r * (1.0 - t * 0.94)
		_circle(ci, pos, rr, edge.lerp(core, t))
	# 1px 深色外圈：让小球边缘“收住”，在深色面板上更锐利
	var outline := color.darkened(0.55)
	outline.a *= alpha
	ci.draw_arc(pos, r - 0.6, 0, TAU, 40, outline, 1.2, true)

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
