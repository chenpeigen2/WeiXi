extends SceneTree
## 图标生成器：tools/make_icon.gd
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/make_icon.gd
## 画一张 512x512 糖果泡泡风图标: 深夜蓝圆角渐变底 + 三色泡泡堆 + 底部发射球。

const S := 512


func _init() -> void:
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# 圆角矩形底 + 垂直渐变 + 四角压暗
	var top := Color(0.17, 0.19, 0.32)
	var bottom := Color(0.09, 0.10, 0.20)
	var radius := 110.0
	for y in range(S):
		var t := float(y) / (S - 1)
		var row := top.lerp(bottom, t)
		for x in range(S):
			var a := _rounded_rect_alpha(x, y, radius)
			if a > 0.0:
				var c := row
				var d: float = min(min(x, S - 1 - x), min(y, S - 1 - y)) / 90.0
				c = c.darkened(0.22 * (1.0 - clamp(d, 0.0, 1.0)))
				c.a = a
				img.set_pixel(x, y, c)

	# 三色泡泡堆（顶排两颗 + 下排一颗）+ 发射小球
	_draw_ball(img, Vector2(180, 195), 78, Color(0.96, 0.30, 0.35))
	_draw_ball(img, Vector2(332, 195), 78, Color(0.98, 0.80, 0.22))
	_draw_ball(img, Vector2(256, 315), 78, Color(0.30, 0.58, 0.98))
	_draw_ball(img, Vector2(256, 428), 40, Color(0.36, 0.85, 0.45))

	img.save_png("res://icon.png")
	print("icon.png 已生成")
	quit(0)


func _rounded_rect_alpha(x: int, y: int, r: float) -> float:
	# 距离场: 内部 alpha=1, 圆角外 0, 边缘平滑 2px
	var half := S / 2.0
	var dx: float = abs(x - half) - (half - r)
	var dy: float = abs(y - half) - (half - r)
	var dxm: float = max(dx, 0.0)
	var dym: float = max(dy, 0.0)
	var dist: float = sqrt(dxm * dxm + dym * dym) + float(min(max(dx, dy), 0.0)) - r
	return clamp(0.5 - dist, 0.0, 1.0)


func _draw_ball(img: Image, pos: Vector2, r: float, color: Color) -> void:
	# 投影 + 外圈暗边 + 主体 + 提亮 + 高光点（与游戏内球的画法一致）
	_stamp(img, pos + Vector2(0, r * 0.14), r * 0.98, Color(0, 0, 0, 0.28))
	_stamp(img, pos, r, color.darkened(0.22))
	_stamp(img, pos, r * 0.92, color)
	_stamp(img, pos + Vector2(-r * 0.10, -r * 0.12), r * 0.62, color.lightened(0.28))
	_stamp(img, pos + Vector2(r * 0.06, r * 0.08), r * 0.38, color.lightened(0.08))
	_stamp(img, pos + Vector2(-r * 0.30, -r * 0.34), r * 0.15, Color(1, 1, 1, 0.85))


func _stamp(img: Image, pos: Vector2, r: float, color: Color) -> void:
	var r2 := r * r
	for y in range(int(pos.y - r - 1), int(pos.y + r + 2)):
		if y < 0 or y >= S:
			continue
		for x in range(int(pos.x - r - 1), int(pos.x + r + 2)):
			if x < 0 or x >= S:
				continue
			var dx: float = x + 0.5 - pos.x
			var dy: float = y + 0.5 - pos.y
			var d2: float = dx * dx + dy * dy
			if d2 <= r2:
				var a: float = clamp(r - sqrt(d2), 0.0, 1.0) # 边缘1px抗锯齿
				var dst := img.get_pixel(x, y)
				img.set_pixel(x, y, dst.blend(Color(color.r, color.g, color.b, color.a * a)))
