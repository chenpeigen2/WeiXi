extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_trim_top_shifts_up_preserving_columns() -> void:
	var b := Board.new(10, 15)
	b.set_ball(Vector2i(0, 0), 1) # 顶行，将被永久移除
	b.set_ball(Vector2i(0, 3), 2) # col = 0 - q_min(3) = 1
	b.set_ball(Vector2i(0, 4), 3) # col = 0 - q_min(4) = 2
	assert_eq(b.trim_top_to(12), 3, "裁掉3行")
	assert_eq(b.rows, 12)
	assert_eq(b.ball_count(), 2, "顶行球永久消失")
	# 列保持：原(0,3)col=1 → r=0,q=1；原(0,4)col=2 → r=1,q=2+q_min(1)=2
	assert_eq(b.get_color(Vector2i(1, 0)), 2)
	assert_eq(b.get_color(Vector2i(2, 1)), 3)


func test_trim_noop_when_fits() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 0), 1)
	assert_eq(b.trim_top_to(12), 0, "装得下不裁")
	assert_eq(b.rows, 12)
	assert_true(b.has_ball(Vector2i(0, 0)))
