extends Node2D
## 背景：静态 shader 渐变 + 平滑暗角 + 缓缓上浮的氛围气泡。
## 渐变/暗角只画一次，气泡每帧只重绘本层；不再用四角大圆与 32 条色带。

const Ui = preload("res://src/ui/theme.gd")

const SHADER_CODE := """
shader_type canvas_item;

uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;
uniform vec4 glow_color : source_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, uv.y));

	// 径向暗角：smoothstep 代替四个硬边圆，避免花瓣状接缝。
	float d = distance(uv, vec2(0.5, 0.44));
	float vig = smoothstep(0.28, 0.90, d);
	col = mix(col, vec3(0.055, 0.030, 0.085), vig * 0.62);

	// 顶部微光：柔和椭圆，不是 390px 的圆。
	float glow = 1.0 - smoothstep(0.0, 0.62, distance(uv, vec2(0.5, -0.06)));
	col += glow_color.rgb * glow * 0.09;

	// 球堆后面一层很淡的粉色奶油光
	float pile = 1.0 - smoothstep(0.0, 0.40, distance(uv, vec2(0.5, 0.25)));
	col += glow_color.rgb * pile * 0.03;

	// 1LSB 抖动打散 8bit 渐变色带。
	float n = hash(uv * vec2(750.0, 1275.0)) - 0.5;
	col += n / 255.0;

	COLOR = vec4(col, 1.0);
}
"""

var _bubbles: Array[Dictionary] = []
var _stars: Array[Dictionary] = []


func _ready() -> void:
	_build_static_layer()

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
	for i in range(12):
		_stars.append({
			"x": rng.randf_range(36, Ui.SCREEN_W - 36),
			"y": rng.randf_range(96, Ui.SCREEN_H - 120),
			"s": rng.randf_range(2.5, 6.0),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.6, 1.4),
		})


## 静态渐变层：一个带 shader 的 ColorRect，只创建一次，不参与每帧重绘。
func _build_static_layer() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("top_color", Ui.BG_TOP)
	mat.set_shader_parameter("bottom_color", Ui.BG_BOTTOM)
	mat.set_shader_parameter("glow_color", Ui.ACCENT)

	var rect := ColorRect.new()
	rect.name = "Gradient"
	rect.position = Vector2.ZERO
	rect.size = Vector2(Ui.SCREEN_W, Ui.SCREEN_H)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Ui.BG_BOTTOM # shader 编译失败时的兜底底色，避免白屏
	rect.material = mat
	rect.z_index = -1
	rect.show_behind_parent = true
	add_child(rect)


func _process(delta: float) -> void:
	for b in _bubbles:
		b["y"] -= b["speed"] * delta
		if b["y"] < -30:
			b["y"] = Ui.SCREEN_H + 30
	queue_redraw()


func _draw() -> void:
	for b in _bubbles:
		draw_circle(Vector2(b["x"], b["y"]), b["r"], Color(1, 1, 1, b["a"]))
	var t := Time.get_ticks_msec() / 1000.0
	for st in _stars:
		var a: float = 0.10 + 0.12 * (0.5 + 0.5 * sin(t * st["speed"] + st["phase"]))
		_star(Vector2(st["x"], st["y"]), st["s"], Color(Ui.STAR.r, Ui.STAR.g, Ui.STAR.b, a))


## 四角小星星：两个交叉的细长菱形，矢量绘制。
func _star(p: Vector2, s: float, c: Color) -> void:
	var q: float = s * 0.22
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -s), p + Vector2(q, -q), p + Vector2(s, 0), p + Vector2(q, q),
		p + Vector2(0, s), p + Vector2(-q, q), p + Vector2(-s, 0), p + Vector2(-q, -q),
	]), c)
