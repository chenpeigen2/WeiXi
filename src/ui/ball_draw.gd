extends RefCounted
const Ui = preload("res://src/ui/theme.gd")

## 统一糖果球绘制：全部是 _draw 矢量，不依赖任何图片。
## 结构：柔和投影 + 薄边 + 1024 段离轴径向渐变 + 左上高光 + 底部反光。
## 离轴光照让球有明确的受光面/背光面，4K/8K 下也不会退化成平面圆。

const SEGMENTS := 1024


static func draw_ball(ci: CanvasItem, pos: Vector2, r: float, color: Color, alpha: float = 1.0, face: bool = false) -> void:
	if alpha <= 0.001:
		return

	# 柔和投影：球体落在面板上的接触阴影
	_circle(ci, pos + Vector2(0, r * 0.14), r * 1.02, Color(0, 0, 0, 0.22 * alpha))

	# 球体主渐变：受光点偏左上，边缘压暗
	var edge := color.darkened(0.30)
	edge.a *= alpha
	var core := color.lightened(0.32)
	core.a *= alpha
	_circle(ci, pos, r, edge)
	_gradient_disc(
		ci, pos, r - 1.0,
		pos + Vector2(-r * 0.20, -r * 0.24),
		core, edge, SEGMENTS
	)

	# 左上柔光（两层）
	var gloss := color.lightened(0.52)
	var gloss_pos := pos + Vector2(-r * 0.22, -r * 0.26)
	gloss.a = 0.16 * alpha
	_circle(ci, gloss_pos, r * 0.46, gloss)
	gloss.a = 0.26 * alpha
	_circle(ci, gloss_pos, r * 0.28, gloss)

	# 硬高光点
	_circle(
		ci, pos + Vector2(-r * 0.30, -r * 0.34), r * 0.12,
		Color(1, 1, 1, 0.95 * alpha)
	)

	# 底部反光弧：玻璃糖果的“透光边”
	var rim := color.lightened(0.55)
	rim.a = 0.28 * alpha
	ci.draw_arc(pos, r * 0.82, PI * 0.18, PI * 0.82, 48, rim, maxf(1.0, r * 0.045), true)

	if face:
		_face(ci, pos, r, alpha)


## 当前球 / 下一颗的小表情：眼睛 + 高光 + 微笑 + 腮红。
static func _face(ci: CanvasItem, pos: Vector2, r: float, alpha: float) -> void:
	var ink := Ui.FACE_INK
	ink.a *= alpha
	var blush := Ui.BLUSH
	blush.a *= alpha
	var eye_r: float = maxf(1.3, r * 0.055)
	var eye_y := pos.y + r * 0.02
	var lx := pos.x - r * 0.22
	var rx := pos.x + r * 0.22
	_circle(ci, Vector2(lx, eye_y), eye_r, ink)
	_circle(ci, Vector2(rx, eye_y), eye_r, ink)
	var spark: float = maxf(0.55, eye_r * 0.34)
	_circle(ci, Vector2(lx + eye_r * 0.32, eye_y - eye_r * 0.34), spark, Color(1, 1, 1, 0.92 * alpha))
	_circle(ci, Vector2(rx + eye_r * 0.32, eye_y - eye_r * 0.34), spark, Color(1, 1, 1, 0.92 * alpha))
	ci.draw_arc(
		pos + Vector2(0, r * 0.10), r * 0.22,
		PI * 0.20, PI * 0.80, 24, ink, maxf(1.2, r * 0.045), true
	)
	_circle(ci, pos + Vector2(-r * 0.37, r * 0.16), r * 0.11, blush)
	_circle(ci, pos + Vector2(r * 0.37, r * 0.16), r * 0.11, blush)


## Compatibility 不支持 2D MSAA，圆必须自己开抗锯齿。
static func _circle(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	ci.draw_circle(pos, r, color, true, -1.0, true)


## 1024 段三角扇，逐顶点颜色从受光点插值到圆周。
## 三角扇的边界点都在圆周上，不会出现单多边形中心点造成的 0° 接缝。
static func _gradient_disc(
	ci: CanvasItem,
	center: Vector2,
	radius: float,
	light_pos: Vector2,
	core: Color,
	edge: Color,
	segments: int
) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	points.append(light_pos)
	colors.append(core)
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(a), sin(a)) * radius)
		colors.append(edge)
	for i in range(segments):
		indices.append(0)
		indices.append(1 + i)
		indices.append(1 + ((i + 1) % segments))
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, colors)
