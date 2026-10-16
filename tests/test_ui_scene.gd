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
	for p in ["Background", "BoardView", "Shooter", "ColorPicker", "FxLayer", "ColorPopup", "HUD/ScorePanel", "HUD/HintLabel"]:
		assert_true(node.get_node_or_null(p) != null, "存在组件 %s" % p)
	assert_true(node.get_node_or_null("HUD/RowSlider") == null, "不再有主动掉落滑杆")
	node.free()


func test_double_click_marks_target_ball() -> void:
	var node := _instantiate_main()
	# 确定性棋盘: 换成2时不会触发消除
	node.game.board = Board.new(10, node.game.board.rows)
	node.game.board.set_ball(Vector2i(0, 0), 3)
	node.game.board.set_ball(Vector2i(1, 0), 0)
	node.game.board.set_ball(Vector2i(0, 1), 1)
	var pos: Vector2 = node.board_view.cam_origin() # cell(0,0) 的屏幕位置
	node._try_cycle_board_ball(pos)
	assert_true(node.color_popup.active, "调色板打开")
	assert_eq(node.board_view.selected, Vector2i(0, 0), "目标球被框选")
	assert_true(node.hint_label.visible, "有操作提示")
	# 点选第2个颜色 → 球变成该色
	var swatch: Vector2 = node.color_popup.swatch_pos(node.color_popup._center, 2)
	node._apply_popup_tap(swatch)
	assert_eq(node.game.board.get_color(Vector2i(0, 0)), 2, "换成选中色")
	assert_false(node.color_popup.active, "调色板关闭")
	assert_eq(node.board_view.selected, node.INVALID_CELL, "框选解除")
	node.free()


func test_popup_tap_outside_cancels_and_unmarks() -> void:
	var node := _instantiate_main()
	var pos: Vector2 = node.board_view.cam_origin()
	node._try_cycle_board_ball(pos)
	node._apply_popup_tap(Vector2(10, 700)) # 点空白取消
	assert_false(node.color_popup.active, "调色板关闭")
	assert_eq(node.board_view.selected, node.INVALID_CELL, "框选解除")
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
