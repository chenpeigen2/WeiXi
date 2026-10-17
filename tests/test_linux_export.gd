extends "res://tests/test_case.gd"


func test_linux_export_preset_configured() -> void:
	# 独立真值: Linux 版 = export_presets.cfg 存在 Linux/X11 预设, 导出到 export/linux/
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK, "export_presets.cfg 可解析")
	var found := false
	for section in cfg.get_sections():
		if section.ends_with(".options") or section.ends_with(".credentials"):
			continue
		if str(cfg.get_value(section, "platform", "")) == "Linux/X11":
			found = true
			var path: String = cfg.get_value(section, "export_path", "")
			assert_true(path.begins_with("export/linux/"), "导出到 export/linux/, 实际: %s" % path)
	assert_true(found, "存在 platform=Linux/X11 的导出预设")
