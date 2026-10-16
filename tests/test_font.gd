extends "res://tests/test_case.gd"


func test_kawaii_font_configured_and_supports_cjk() -> void:
	# 独立真值: project.godot 的 gui/theme/custom_font 指向的字体必须可加载且含常用汉字
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK, "project.godot 可解析")
	var font_path: String = cfg.get_value("gui", "theme/custom_font", "")
	assert_true(font_path.begins_with("res://"), "已配置全局字体, 实际: %s" % font_path)
	var font := FontFile.new()
	var err := font.load_dynamic_font(font_path)
	assert_eq(err, OK, "字体可加载: %s" % font_path)
	if err != OK:
		return
	# 游戏界面用到的汉字都必须有字形（避免豆腐块）
	for ch in ["分", "数", "连", "击", "掉", "落", "点", "给", "这", "颗", "球", "选", "个", "颜", "色", "相", "邻", "互", "换"]:
		assert_true(font.has_char(ch.unicode_at(0)), "有字形: %s" % ch)
