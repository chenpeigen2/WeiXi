extends "res://tests/test_case.gd"


func test_msaa_2d_enabled_for_crisp_shapes() -> void:
	# 独立真值: 糖果球是矢量圆形, 边缘发糊需要 MSAA 2D 抗锯齿（0=关 2=2x 4=4x）
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK, "project.godot 可解析")
	var msaa: int = cfg.get_value("rendering", "anti_aliasing/quality/msaa_2d", 0)
	assert_true(msaa >= 2, "MSAA 2D 至少 2x, 实际: %d" % msaa)
