extends "res://tests/test_case.gd"


func test_project_icon_exists_and_is_valid_image() -> void:
	# 独立真值: project.godot 的 application/config/icon 指向的文件必须可解码成 512x512 图
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK, "project.godot 可解析")
	var icon_path: String = cfg.get_value("application", "config/icon", "")
	assert_true(icon_path.begins_with("res://"), "已配置图标路径, 实际: %s" % icon_path)
	var img := Image.load_from_file(icon_path)
	assert_true(img != null, "图标可解码: %s" % icon_path)
	if img == null:
		return
	assert_eq(img.get_width(), 512, "512宽")
	assert_eq(img.get_height(), 512, "512高")
	# 不能是空白图: 采样若干点应有颜色变化
	var seen := {}
	for p in [Vector2i(256, 256), Vector2i(128, 128), Vector2i(384, 384), Vector2i(64, 256), Vector2i(256, 64)]:
		seen[img.get_pixelv(p)] = true
	assert_true(seen.size() >= 2, "图标有画面内容(至少2种颜色)")
