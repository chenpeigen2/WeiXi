extends "res://tests/test_case.gd"


func test_main_scene_loads_and_ready() -> void:
	var ps: PackedScene = load("res://src/scenes/main.tscn")
	assert_true(ps != null, "场景可加载")
	if ps == null:
		return
	var node := ps.instantiate()
	tree_root.add_child(node) # 触发 _ready, 暴露脚本错误
	assert_true(node.get_node_or_null("HUD") != null, "HUD层存在")
	assert_true(node.get_node_or_null("HUD/ScoreLabel") != null, "分数标签存在")
	assert_true(node.get_node_or_null("HUD/ModeButton") != null, "模式按钮存在")
	assert_true(node.get_node_or_null("HUD/RowSlider") != null, "行数滑杆存在")
	assert_eq(node.game.board.ball_count(), 50, "开局50球")
	tree_root.remove_child(node)
	node.queue_free()
