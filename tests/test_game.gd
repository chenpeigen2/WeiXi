extends "res://tests/test_case.gd"

const Game = preload("res://src/logic/game.gd")
const Board = preload("res://src/logic/board.gd")


func test_new_game_initial_state() -> void:
	var g := Game.new(1)
	assert_eq(g.board.ball_count(), 50, "开局5行")
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


func test_attach_without_pop_is_miss() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(5, 0), 3)
	g.set_current_color(1)
	var res: Dictionary = g.attach_ball(Vector2i(8, 8))
	assert_eq(res["popped"].size(), 0)
	assert_eq(g.scorer.score, 0, "无消除不得分")
	assert_eq(g.scorer.combo, 1, "连击保持1")


func test_deadline_gives_one_more_shot_grace() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	g.board.set_ball(Vector2i(5, 0), 3) # 锚点
	g.set_current_color(1)
	var res1: Dictionary = g.attach_ball(Vector2i(0, 13)) # 第一个球触线
	assert_eq(res1["overflow"].size(), 0, "触线球暂留, 宽限一发")
	assert_true(g.board.has_ball(Vector2i(0, 13)), "球留在场上")
	g.set_current_color(2)
	var res2: Dictionary = g.attach_ball(Vector2i(8, 11)) # 再打一个
	assert_has(res2["overflow"], Vector2i(0, 13), "再打一个之后最低行才掉落")
	assert_false(g.board.has_ball(Vector2i(0, 13)), "掉落行清空")
	assert_true(g.board.has_ball(Vector2i(8, 11)), "新打的球不受影响")
	assert_eq(g.board.rows, Game.MAX_ROWS, "棋盘容量不变")





func test_swap_clear_all_refills() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(0, 1), 1)
	g.board.set_ball(Vector2i(1, 1), 1)
	g.board.set_ball(Vector2i(2, 1), 2)
	g.board.set_ball(Vector2i(2, 2), 1)
	var res: Dictionary = g.try_swap(Vector2i(2, 1), Vector2i(2, 2))
	assert_true(res["matched"])
	# 3红消除 + (2,2)蓝悬空掉落 → 全场清空 → 自动补5行
	assert_eq(g.board.ball_count(), 50, "清空自动补5行")
	assert_true(g.scorer.score > 0, "三消也计分")


func test_failed_swap_keeps_score() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, 12)
	g.board.set_ball(Vector2i(0, 0), 3)
	g.board.set_ball(Vector2i(0, 1), 1)
	g.board.set_ball(Vector2i(1, 1), 2)
	var res: Dictionary = g.try_swap(Vector2i(0, 1), Vector2i(1, 1))
	assert_false(res["matched"])
	assert_eq(g.scorer.score, 0)


func test_hint_match3_when_few_balls() -> void:
	var g := Game.new(1)
	assert_false(g.should_hint_match3(), "50球不提示")
	g.board = Board.new(10, 12)
	for i in range(8):
		g.board.set_ball(Vector2i(i, 0), i % 6)
	assert_true(g.should_hint_match3(), "8球提示")


func test_set_board_ball_color() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	g.board.set_ball(Vector2i(5, 0), 3)
	g.set_ball_color(Vector2i(5, 0), 0)
	assert_eq(g.board.get_color(Vector2i(5, 0)), 0, "改成指定的颜色")
	g.set_ball_color(Vector2i(5, 0), 5)
	assert_eq(g.board.get_color(Vector2i(5, 0)), 5, "任意颜色")
	var res: Dictionary = g.set_ball_color(Vector2i(9, 9), 2)
	assert_eq(res["popped"].size(), 0, "空格安全")


func test_set_board_ball_color_triggers_match_and_scores() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	g.board.set_ball(Vector2i(0, 0), 1)
	g.board.set_ball(Vector2i(1, 0), 1)
	g.board.set_ball(Vector2i(0, 1), 4) # 改成1即三连红
	var res: Dictionary = g.set_ball_color(Vector2i(0, 1), 1)
	assert_eq(res["popped"].size(), 3, "换色形成三连即消")
	assert_eq(g.scorer.score, 30, "计分")


func test_trigger_shot_survives_while_overdue_row_drops() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	g.board.set_ball(Vector2i(5, 0), 3) # 锚点
	g.board.set_ball(Vector2i(0, 13), 1) # 逾期行(触线)
	g.set_current_color(2)
	var res: Dictionary = g.attach_ball(Vector2i(5, 13)) # 触发的这一发也落线行
	assert_has(res["overflow"], Vector2i(0, 13), "逾期行掉落")
	assert_false(g.board.has_ball(Vector2i(0, 13)), "旧球清掉")
	assert_true(g.board.has_ball(Vector2i(5, 13)), "这一发不陪葬, 落在腾出的行")


func test_overflow_drop_takes_unsupported_balls() -> void:
	var g := Game.new(1)
	g.board = Board.new(10, Game.MAX_ROWS)
	# 顶部链: (q,13) q=0..5 与 (0,r) r=0..12, 全色1
	for q in range(6):
		g.board.set_ball(Vector2i(q, 13), 1)
	for r in range(13):
		g.board.set_ball(Vector2i(0, r), 1)
	# 只靠 (5,13)/(6,13) 吊着的球
	g.board.set_ball(Vector2i(6, 12), 2)
	g.board.set_ball(Vector2i(6, 13), 1)
	g.set_current_color(2)
	var res: Dictionary = g.attach_ball(Vector2i(1, 12)) # 发球前最低行13存在→触发
	assert_has(res["overflow"], Vector2i(0, 13), "逾期行掉落")
	assert_has(res["overflow"], Vector2i(6, 12), "失去支撑的球跟着掉")
	assert_true(g.board.has_ball(Vector2i(1, 12)), "新球仍在")
