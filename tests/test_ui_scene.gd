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
	for p in ["Background", "BoardView", "DeadlineView", "Shooter", "ColorPicker", "FxLayer", "ColorPopup", "HUD/ScorePanel", "HUD/HintLabel"]:
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


func test_first_run_coach_starts_with_fire_hint() -> void:
	var node := _instantiate_main()
	assert_true(node.hint_label.visible, "首次进入显示操作提示")
	assert_true("发射" in node.hint_label.text, "第一条提示教发射, 实际: %s" % node.hint_label.text)
	node.free()


func test_deadline_warning_arms_when_lowest_row_reaches_line() -> void:
	var node := _instantiate_main()
	assert_false(node.deadline_view.armed(), "开局未触线")
	node.game.board.set_ball(Vector2i(0, node.game.deadline_row), 1)
	assert_true(node.deadline_view.armed(), "最低行触线后进入宽限期警示")
	node.free()


func test_meta_bar_and_sticker_album_exist_and_open() -> void:
	var node := _instantiate_main()
	assert_true(node.get_node_or_null("HUD/MetaBar") != null, "底部入口存在")
	assert_true(node.get_node_or_null("HUD/StickerAlbum") != null, "贴纸册存在")
	assert_false(node.album.visible, "默认关闭")
	node._on_stickers()
	assert_true(node.album.visible, "点击贴纸入口打开")
	node.album.close()
	assert_false(node.album.visible, "可关闭")
	node.free()


func test_daily_and_random_reset_game() -> void:
	var node := _instantiate_main()
	var old = node.game
	node._on_daily()
	assert_true(node.daily_mode, "每日模式")
	assert_ne(node.game, old, "重新开局")
	assert_eq(node.game.scorer.score, 0, "分数归零")
	assert_eq(node.meta_bar.daily, true, "每日入口高亮")
	assert_eq(node.game.rng.seed, preload("res://src/logic/daily_seed.gd").today_seed(), "每日种子一致")
	node._on_random()
	assert_false(node.daily_mode, "随机模式")
	assert_eq(node.meta_bar.daily, false)
	node.free()


func test_wish_completion_unlocks_stickers() -> void:
	var node := _instantiate_main()
	var before: int = node.sticker_book.count()
	node.game.wishes.completion_count += 3
	node.refresh()
	assert_eq(node.sticker_book.count(), mini(before + 3, 12), "完成多条愿望解锁多张贴纸")
	assert_eq(node.meta_bar.sticker_count, node.sticker_book.count(), "底部计数同步")
	node.free()


func test_sticker_album_ignores_flight_and_swap() -> void:
	var node := _instantiate_main()
	node.shooter._flight = {"dummy": true}
	node._on_stickers()
	assert_false(node.album.visible, "飞行中不打开相册")
	node.shooter._flight = {}
	node._on_stickers()
	assert_true(node.album.visible, "空闲时可打开")
	node.album.close()
	node.free()


func test_landing_animation_queues_and_expires() -> void:
	var node := _instantiate_main()
	node.game.board = Board.new(10, 12)
	node.game.board.set_ball(Vector2i(0, 0), 1)
	node.board_view.play_landing(Vector2i(0, 0), Vector2.UP)
	assert_eq(node.board_view._landings.size(), 1, "落球动画入队")
	node.board_view._process(0.15)
	assert_eq(node.board_view._landings.size(), 1, "未到时长仍保留")
	node.board_view._process(0.5)
	assert_eq(node.board_view._landings.size(), 0, "结束后清理")
	node.free()


func test_match3_swap_keeps_board_until_animation_end() -> void:
	var node := _instantiate_main()
	node.game.board = Board.new(10, 14)
	node.game.board.set_ball(Vector2i(2, 0), 3) # 锚点
	node.game.board.set_ball(Vector2i(0, 1), 1)
	node.game.board.set_ball(Vector2i(1, 1), 1)
	node.game.board.set_ball(Vector2i(2, 1), 2)
	node.game.board.set_ball(Vector2i(2, 2), 1)
	node._animated_swap(Vector2i(2, 1), Vector2i(2, 2))
	assert_true(node.fx_layer.is_swapping(), "互换动画开始")
	assert_true(node.game.board.has_ball(Vector2i(2, 1)), "动画期间保留 before 棋盘")
	assert_eq(node.game.board.get_color(Vector2i(2, 1)), 2, "动画期间不提前移除球")
	assert_true(node.board_view.hidden_cells.has(Vector2i(2, 1)), "两个互换球隐藏交给特效层")
	node.fx_layer._process(0.40)
	assert_false(node.fx_layer.is_swapping(), "动画结束")
	assert_false(node.game.board.has_ball(Vector2i(2, 1)), "落位后才消除")
	assert_eq(node.board_view.hidden_cells.size(), 0, "隐藏格清理")
	node.free()


func test_board_hover_cell() -> void:
	var node := _instantiate_main()
	node.game.board = Board.new(10, 14)
	node.game.board.set_ball(Vector2i(0, 0), 1)
	node.board_view.set_hover(Vector2i(0, 0))
	assert_eq(node.board_view.hover_cell, Vector2i(0, 0), "悬停格记录")
	node.board_view.set_hover(Vector2i(-999, -999))
	assert_eq(node.board_view.hover_cell, Vector2i(-999, -999), "悬停清除")
	node.free()


func test_board_shake_returns_to_rest() -> void:
	var node := _instantiate_main()
	node.board_view.play_shake(4.0)
	assert_true(node.board_view.is_shaking(), "震屏开始")
	node.board_view._process(0.30)
	assert_true(node.board_view._shake.is_empty(), "震屏结束")
	assert_eq(node.board_view.position, Vector2.ZERO, "回到原位")
	node.free()


func test_sticker_chip_pulse_on_unlock() -> void:
	var node := _instantiate_main()
	node.meta_bar.set_state(false, 2)
	assert_true(node.meta_bar._sticker_pulse > 0.0, "贴纸数量增加时入口发光")
	node.meta_bar._process(0.60)
	assert_true(node.meta_bar._sticker_pulse <= 0.0, "脉冲结束")
	node.free()
