extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_is_empty() -> void:
	var b := Board.new(10, 12)
	assert_true(b.is_empty(), "新盘为空")
	b.set_ball(Vector2i(0, 0), 1)
	assert_false(b.is_empty())


func test_refill_top_fills_exactly_n_rows() -> void:
	var b := Board.new(10, 12)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	b.refill_top(5, rng, 6)
	assert_eq(b.ball_count(), 50, "5行x10列全满")
	for r in range(5):
		var q0: int = -((r - (r & 1)) >> 1)
		for col in range(10):
			var cell := Vector2i(q0 + col, r)
			assert_true(b.has_ball(cell), "第%d行第%d列有球" % [r, col])
			var color := b.get_color(cell)
			assert_true(color >= 0 and color < 6, "颜色在0..5之间: %d" % color)
	assert_false(b.has_ball(Vector2i(0, 5)), "第6行仍为空")
