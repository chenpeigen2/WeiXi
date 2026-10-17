extends "res://tests/test_case.gd"


func test_windows_export_preset_configured() -> void:
	# 独立真值: Windows 可执行版 = export_presets.cfg 存在 Windows Desktop 预设, 导出到 export/windows/
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK, "export_presets.cfg 可解析")
	var found := false
	for section in cfg.get_sections():
		if section.ends_with(".options") or section.ends_with(".credentials"):
			continue
		if str(cfg.get_value(section, "platform", "")) == "Windows Desktop":
			found = true
			var path: String = cfg.get_value(section, "export_path", "")
			assert_true(path.begins_with("export/windows/"), "导出到 export/windows/, 实际: %s" % path)
	assert_true(found, "存在 platform=Windows Desktop 的导出预设")


func test_windows_installer_script_exists() -> void:
	# 独立真值: 可安装 = NSIS 安装脚本存在且包含卸载器与快捷方式
	var nsi := FileAccess.get_file_as_string("res://tools/installer.nsi")
	assert_true(not nsi.is_empty(), "tools/installer.nsi 存在")
	assert_true("WriteUninstaller" in nsi, "带卸载器")
	assert_true("CreateShortCut" in nsi, "建快捷方式")
	assert_true("weixi.exe" in nsi, "打包游戏可执行文件")
