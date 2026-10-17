extends "res://tests/test_case.gd"


func test_web_export_preset_configured() -> void:
	# 独立真值: 网页版 = export_presets.cfg 存在 platform=Web 的预设, 导出到 export/web/
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK, "export_presets.cfg 可解析")
	var found := false
	for section in cfg.get_sections():
		if section.ends_with(".options") or section.ends_with(".credentials"):
			continue
		if str(cfg.get_value(section, "platform", "")) == "Web":
			found = true
			var path: String = cfg.get_value(section, "export_path", "")
			assert_true(path.begins_with("export/web/"), "导出到 export/web/, 实际: %s" % path)
	assert_true(found, "存在 platform=Web 的导出预设")


func test_web_page_centers_canvas() -> void:
	# 独立真值: 网页必须把画布居中显示且整体可见(不裁切/不顶角)
	var html := FileAccess.get_file_as_string("res://export/web/index.html")
	assert_true(not html.is_empty(), "导出产物 index.html 存在")
	assert_true("justify-content: center" in html or "justify-content:center" in html, "水平居中")
	assert_true("align-items: center" in html or "align-items:center" in html, "垂直居中")
	assert_true("max-height: 100vh" in html or "max-height:100vh" in html, "整体等比适配不裁切")


func test_game_content_scales_to_fit_any_window() -> void:
	# 独立真值: 750x1275 内容必须完整显示在任意窗口里 → stretch=canvas_items + aspect=keep
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK, "project.godot 可解析")
	assert_eq(cfg.get_value("display", "window/stretch/mode", ""), "canvas_items", "内容等比缩放")
	assert_eq(cfg.get_value("display", "window/stretch/aspect", ""), "keep", "完整显示不裁切")
