extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_extend_rows_grows_board() -> void:
	var b := Board.new(10, 12)
	b.extend_rows(3)
	assert_eq(b.rows, 15, "加3行")


func test_lowest_occupied_row() -> void:
	var b := Board.new(10, 12)
	assert_eq(b.lowest_occupied_row(), -1, "空盘")
	b.set_ball(Vector2i(0, 4), 1)
	b.set_ball(Vector2i(0, 7), 1)
	assert_eq(b.lowest_occupied_row(), 7, "最低占用行")


func test_ensure_space_extends_when_ball_reaches_deadline() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 11), 1) # 底线在第11行, 球碰到了
	assert_eq(b.ensure_space(11), 3, "自动续3行")
	assert_eq(b.rows, 15)


func test_ensure_space_extends_until_clear_of_deadline() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 14), 1) # 越过底线很深
	assert_eq(b.ensure_space(11), 6, "续6行才脱险")
	assert_eq(b.rows, 18)


func test_ensure_space_noop_when_above_deadline() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 5), 1)
	assert_eq(b.ensure_space(11), 0, "安全区不续行")
	assert_eq(b.rows, 12)
