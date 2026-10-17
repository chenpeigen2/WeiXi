extends "res://tests/test_case.gd"


func test_vector_balls_use_antialiased_primitives() -> void:
	# Compatibility 不支持 2D MSAA，球体边缘必须由 draw_circle(..., antialiased=true) 自己抗锯齿。
	var src := FileAccess.get_file_as_string("res://src/ui/ball_draw.gd")
	assert_true(not src.is_empty(), "ball_draw.gd 可读")
	assert_true(
		"ci.draw_circle(pos, r, color, true, -1.0, true)" in src,
		"球体圆使用 antialiased=true"
	)


func test_hidpi_and_fractional_scaling_enabled() -> void:
	# 独立真值: 矢量 UI 要真正高清，必须允许 HiDPI，并用非整数缩放铺满窗口
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK, "project.godot 可解析")
	assert_true(bool(cfg.get_value("display", "window/dpi/allow_hidpi", true)), "允许 HiDPI（默认 true）")
	assert_eq(
		str(cfg.get_value("display", "window/stretch/scale_mode", "fractional")),
		"fractional",
		"小数缩放（默认 fractional），避免整数缩放的锯齿/黑边"
	)
