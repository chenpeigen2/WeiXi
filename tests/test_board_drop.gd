extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_drop_overflow_removes_rows_at_deadline() -> void:
	var b := Board.new(10, 14)
	b.set_ball(Vector2i(0, 10), 1)
	b.set_ball(Vector2i(0, 13), 2)
	b.set_ball(Vector2i(1, 13), 3)
	var dropped := b.drop_overflow(13)
	assert_eq(dropped.size(), 2, "底线行的两个球掉落")
	assert_has(dropped, Vector2i(0, 13))
	assert_has(dropped, Vector2i(1, 13))
	assert_true(b.has_ball(Vector2i(0, 10)), "上面的球保留")


func test_drop_overflow_repeats_until_below_deadline() -> void:
	var b := Board.new(10, 14)
	b.set_ball(Vector2i(0, 12), 1)
	b.set_ball(Vector2i(0, 13), 2)
	var dropped := b.drop_overflow(12)
	assert_eq(dropped.size(), 2, "两行都越过底线, 全部掉落")
	assert_eq(b.lowest_occupied_row(), -1, "清空")


func test_drop_overflow_noop_when_safe() -> void:
	var b := Board.new(10, 14)
	b.set_ball(Vector2i(0, 5), 1)
	assert_eq(b.drop_overflow(13).size(), 0, "安全区不掉落")


func test_drop_lowest_rows_manual() -> void:
	var b := Board.new(10, 14)
	b.set_ball(Vector2i(0, 3), 1)
	b.set_ball(Vector2i(0, 7), 2)
	b.set_ball(Vector2i(1, 9), 3)
	var dropped := b.drop_lowest_rows(2)
	assert_eq(dropped.size(), 2, "最低两个占用行的球掉落")
	assert_true(b.has_ball(Vector2i(0, 3)), "第3行保留")
	assert_eq(b.lowest_occupied_row(), 3)


func test_drop_lowest_rows_more_than_occupied() -> void:
	var b := Board.new(10, 14)
	b.set_ball(Vector2i(0, 5), 1)
	assert_eq(b.drop_lowest_rows(5).size(), 1, "只有1行可掉")
	assert_true(b.is_empty())
