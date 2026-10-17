extends ColorRect
## 棋盘背板：奶油→薄荷/薰衣草渐变 + 玫瑰内描边 + 淡紫波点。
## 全部在 shader 里按分辨率绘制，4K/8K 都不会糊。

const SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform vec2 panel_size = vec2(694.0, 831.0);
uniform float corner_radius = 30.0;
uniform vec4 cream : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform vec4 mint : source_color = vec4(0.72, 0.93, 0.82, 1.0);
uniform vec4 lavender : source_color = vec4(0.86, 0.80, 0.97, 1.0);
uniform vec4 rose : source_color = vec4(1.0, 0.66, 0.76, 1.0);

float sd_round_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - (half_size - vec2(r));
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 px = UV * panel_size;
	vec2 center = panel_size * 0.5;
	float d = sd_round_box(px - center, center, corner_radius);
	float aa = max(fwidth(d), 0.0001);
	float mask = 1.0 - smoothstep(-aa, aa, d);
	// 奶油底 + 顶部薄荷、底部薰衣草的柔和渐变
	vec3 col = cream.rgb;
	float top = smoothstep(0.0, 0.62, 1.0 - UV.y);
	float bottom = smoothstep(0.08, 0.82, UV.y);
	col = mix(col, mint.rgb, top * 0.42);
	col = mix(col, lavender.rgb, bottom * 0.44);

	// 右上角一点玫瑰光
	float glow = exp(-length((UV - vec2(0.82, 0.16)) * vec2(1.25, 1.0)) * 3.2);
	col += rose.rgb * glow * 0.075;

	// 淡紫波点：像糖霜，密度低、存在感轻
	vec2 gp = mod(px, vec2(46.0, 46.0)) - vec2(23.0);
	float dot = 1.0 - smoothstep(2.0, 3.6, length(gp));
	col = mix(col, lavender.rgb, dot * 0.18);

	// 内层玫瑰描边
	float inner = abs(d + 7.0) - 1.0;
	float line = 1.0 - smoothstep(0.0, 1.5, inner);
	col = mix(col, rose.rgb, line * 0.38);

	// 外层薄荷描边
	float edge = 1.0 - smoothstep(0.0, 2.0, abs(d + 1.0));
	col = mix(col, mint.rgb, edge * 0.80);

	// 顶部奶油高光
	col += vec3(1.0, 0.96, 0.92) * smoothstep(0.86, 1.0, 1.0 - UV.y) * 0.045;

	COLOR = vec4(col, mask);
}
"""

var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	color = Color.WHITE
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	material = _mat


func set_panel(rect: Rect2) -> void:
	if position != rect.position:
		position = rect.position
	if size != rect.size:
		size = rect.size
	if _mat != null:
		_mat.set_shader_parameter("panel_size", rect.size)
	queue_redraw()
