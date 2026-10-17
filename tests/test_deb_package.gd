extends "res://tests/test_case.gd"


func test_deb_build_script_exists() -> void:
	# 独立真值: deb 包 = 构建脚本存在, 用 dpkg-deb 打包, 含标准 control 字段
	var sh := FileAccess.get_file_as_string("res://tools/build_deb.sh")
	assert_true(not sh.is_empty(), "tools/build_deb.sh 存在")
	assert_true("dpkg-deb --build" in sh or "dpkg-deb -b" in sh, "用 dpkg-deb 打包")
	for field in ["Package:", "Version:", "Architecture:", "Maintainer:", "Description:"]:
		assert_true(field in sh, "control 字段 %s" % field)
	assert_true("weixi.desktop" in sh, "带桌面快捷方式")
