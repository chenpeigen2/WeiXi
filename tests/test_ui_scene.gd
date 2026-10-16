extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func _instantiate_main() -> Node:
	var ps: PackedScene = load("res://src/scenes/main.tscn")
	assert_true(ps != null, "场景可加载")
	var node: Node = ps.instantiate()
	tree_root.add_child(node)
	return node


func test_main_scene_components_exist() -> void:
	var node := _instantiate_main()
	for p in ["Background", "BoardView", "Shooter", "ColorPicker", "FxLayer", "HUD/ScorePanel", "HUD/HintLabel", "HUD/RowSlider"]:
		assert_true(node.get_node_or_null(p) != null, "存在组件 %s" % p)
	node.free()


func test_score_panel_updates_after_scoring() -> void:
	var node := _instantiate_main()
	node.game.board = Board.new(10, 12)
	node.game.board.set_ball(Vector2i(5, 0), 3)
	node.game.board.set_ball(Vector2i(0, 0), 1)
	node.game.board.set_ball(Vector2i(1, 0), 1)
	node.game.set_current_color(1)
	node.game.attach_ball(Vector2i(0, 1))
	node.refresh()
	var panel = node.get_node("HUD/ScorePanel")
	assert_true("30" in panel.text, "分数面板显示30, 实际: %s" % panel.text)
	node.free()
