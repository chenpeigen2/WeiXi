extends SceneTree
## headless 测试运行器：
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_tests.gd
## 自动发现并运行 tests/ 下所有 test_*.gd 中以 test_ 开头的方法。

var _done := false


# 场景树未初始化完时 root 不在树内, add_child 不触发 _ready。
# 因此测试推迟到第一帧 _process 执行。
func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	return true


func _run_all() -> void:
	var total := 0
	var failed_tests := 0
	var failed_files := 0

	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	if dir:
		for f in dir.get_files():
			if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
				files.append("res://tests/" + f)
	files.sort()

	for path in files:
		var script: GDScript = load(path)
		# 注意: 解析失败的脚本 load() 不返回 null, 而是返回损坏的资源, 需用 can_instantiate() 判活
		if script == null or not script.can_instantiate():
			failed_files += 1
			printerr("无法加载测试文件: ", path)
			continue
		for m in script.get_script_method_list():
			var method_name: String = m["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var inst: RefCounted = script.new()
			inst.tree_root = root
			inst.call(method_name)
			# GDScript 运行时错误会中断测试函数但不进 failures, 用断言数兜底识别
			if inst.assert_count == 0:
				inst.failures.append("断言数为0, 疑似运行时错误中断(见上方 SCRIPT ERROR)")
			for failure in inst.failures:
				printerr("[%s::%s] %s" % [path.get_file(), method_name, failure])
			if not inst.failures.is_empty():
				failed_tests += 1

	print("---")
	print("共 %d 个测试, 失败 %d 个, 无法加载文件 %d 个" % [total, failed_tests, failed_files])
	if failed_tests > 0 or failed_files > 0:
		quit(1)
	else:
		quit(0)
