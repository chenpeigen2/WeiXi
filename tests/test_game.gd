extends "res://tests/test_case.gd"

const Game = preload("res://src/logic/game.gd")
const Board = preload("res://src/logic/board.gd")


func test_new_game_initial_state() -> void:
	var g := Game.new(1)
	assert_eq(g.board.ball_count(), 50, "开局5行")
	assert_eq(g.mode, Game.Mode.SHOOT, "默认射击模式")
	assert_eq(g.deadline_row, 11, "初始底线")
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


func test_cheat_add_rows_extends_board_and_deadline() -> void:
	var g := Game.new(1)
	g.add_rows(4) # 作弊2: 行数滑杆, 12+4=16 > 14 → 裁2行
	assert_eq(g.board.rows, Game.MAX_ROWS, "超过上限裁到 MAX_ROWS")
	assert_eq(g.deadline_row, 11 + 4 - 2, "底线=11+加行-裁剪")


func test_add_rows_beyond_max_trims_top() -> void:
	var g := Game.new(1)
	g.add_rows(10) # 12+10=22 > MAX_ROWS(14) → 裁8行
	assert_eq(g.board.rows, Game.MAX_ROWS, "超过上限裁到 MAX_ROWS")
	assert_eq(g.deadline_row, 11 + 10 - 8, "底线=11+加行-裁剪")


func test_trimmed_balls_vanish_and_rest_stay_anchored() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.deadline_row = 11
	g.board.set_ball(Vector2i(0, 0), 1) # 顶行, 将被永久移除
	g.board.set_ball(Vector2i(0, 9), 2) # 在裁剪线之下, 幸存并上移
	g.add_rows(10) # 12+10=22 > MAX_ROWS(14) → 裁8行
	assert_eq(g.board.ball_count(), 1, "顶行球永久消失")
	# 原(0,9) col=4 → 裁8行后 r=1, q=4+q_min(1)=4
	assert_eq(g.board.get_color(Vector2i(4, 1)), 2, "幸存球上移且列保持")


func test_attach_at_deadline_auto_extends() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(5, 0), 3)
	g.set_current_color(1)
	g.attach_ball(Vector2i(0, 11)) # 落点碰到底线, 12+3=15 > 14 → 裁1行
	assert_eq(g.board.rows, 14, "自动续3行后裁剪到上限")
	assert_eq(g.deadline_row, 13, "底线=11+3-1")





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
