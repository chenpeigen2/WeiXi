extends "res://tests/test_case.gd"

const Game = preload("res://src/logic/game.gd")
const Board = preload("res://src/logic/board.gd")


func test_new_game_initial_state() -> void:
	var g := Game.new(1)
	assert_eq(g.board.ball_count(), 50, "开局5行")
	assert_eq(g.mode, Game.Mode.SHOOT, "默认射击模式")
	assert_eq(g.deadline_row, Game.MAX_ROWS - 1, "底线固定在最底可见行")
	assert_eq(g.board.rows, Game.MAX_ROWS, "棋盘容量固定")
	assert_eq(g.scorer.score, 0)
	assert_true(g.current_color >= 0 and g.current_color < 6)
	assert_true(g.next_color >= 0 and g.next_color < 6)


func test_cheat_set_color_and_attach_pop_scores() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(5, 0), 3) # 锚点, 防止清空触发补球
	g.board.set_ball(Vector2i(0, 0), 1)
	g.board.set_ball(Vector2i(1, 0), 1)
	g.set_current_color(1) # 作弊1: 自由换色
	var old_next: int = g.next_color
	var res: Dictionary = g.attach_ball(Vector2i(0, 1))
	assert_eq(res["popped"].size(), 3, "三消")
	assert_eq(g.scorer.score, 30, "(3*10+0)*1")
	assert_eq(g.current_color, old_next, "当前球轮转")
	assert_eq(g.mode, Game.Mode.SHOOT)


func test_attach_without_pop_is_miss() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(5, 0), 3)
	g.set_current_color(1)
	var res: Dictionary = g.attach_ball(Vector2i(8, 8))
	assert_eq(res["popped"].size(), 0)
	assert_eq(g.scorer.score, 0, "无消除不得分")
	assert_eq(g.scorer.combo, 1, "连击保持1")


func test_cheat_drop_bottom_rows() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	g.board.set_ball(Vector2i(0, 5), 1)
	g.board.set_ball(Vector2i(0, 8), 2)
	g.board.set_ball(Vector2i(1, 8), 3)
	var dropped: Array = g.drop_bottom_rows(1) # 作弊2: 掉落滑杆
	assert_eq(dropped.size(), 2, "最低占用行的2个球掉落")
	assert_true(g.board.has_ball(Vector2i(0, 5)), "上面的球保留")
	assert_eq(g.board.lowest_occupied_row(), 5)
	assert_eq(g.deadline_row, Game.MAX_ROWS - 1, "底线不动")


func test_attach_at_deadline_overflows_and_drops() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	g.board.set_ball(Vector2i(5, 0), 3)
	g.set_current_color(1)
	var res: Dictionary = g.attach_ball(Vector2i(0, 13)) # 落点到达底线
	assert_has(res["overflow"], Vector2i(0, 13), "刚落的球随最低行一起掉出")
	assert_false(g.board.has_ball(Vector2i(0, 13)), "掉落后不再存在")
	assert_eq(g.board.rows, Game.MAX_ROWS, "棋盘容量不变")
	assert_eq(g.deadline_row, Game.MAX_ROWS - 1, "底线不动")
	assert_eq(g.board.lowest_occupied_row(), 0, "只剩顶行锚点")





func test_swap_clear_all_refills_and_returns_shoot_mode() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(0, 1), 1)
	g.board.set_ball(Vector2i(1, 1), 1)
	g.board.set_ball(Vector2i(2, 1), 2)
	g.board.set_ball(Vector2i(2, 2), 1)
	g.toggle_mode()
	assert_eq(g.mode, Game.Mode.MATCH3)
	var res: Dictionary = g.try_swap(Vector2i(2, 1), Vector2i(2, 2))
	assert_true(res["matched"])
	# 3红消除 + (2,2)蓝悬空掉落 → 全场清空 → 自动补5行 + 切回射击
	assert_eq(g.board.ball_count(), 50, "清空自动补5行")
	assert_eq(g.mode, Game.Mode.SHOOT, "切回射击模式")
	assert_true(g.scorer.score > 0, "三消也计分")


func test_failed_swap_keeps_score_and_mode() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(0, 0), 3)
	g.board.set_ball(Vector2i(0, 1), 1)
	g.board.set_ball(Vector2i(1, 1), 2)
	g.toggle_mode()
	var res: Dictionary = g.try_swap(Vector2i(0, 1), Vector2i(1, 1))
	assert_false(res["matched"])
	assert_eq(g.scorer.score, 0)
	assert_eq(g.mode, Game.Mode.MATCH3)


func test_hint_match3_when_few_balls() -> void:
	var g := Game.new(1)
	assert_false(g.should_hint_match3(), "50球不提示")
	g.board = Board.new(10, 12)
	for i in range(8):
		g.board.set_ball(Vector2i(i, 0), i % 6)
	assert_true(g.should_hint_match3(), "8球提示")
	g.toggle_mode()
	assert_false(g.should_hint_match3(), "三消模式下不提示")
