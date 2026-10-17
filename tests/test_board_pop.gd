extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_cluster_floods_same_color() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 0), 1)
	b.set_ball(Vector2i(1, 0), 1)
	b.set_ball(Vector2i(2, 0), 2) # 不同色, 不入选
	var c := b.cluster(Vector2i(0, 0))
	assert_eq(c.size(), 2, "只有两个相连红球")
	assert_has(c, Vector2i(0, 0))
	assert_has(c, Vector2i(1, 0))


func test_resolve_pops_cluster_of_three() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 0), 1)
	b.set_ball(Vector2i(1, 0), 1)
	b.set_ball(Vector2i(0, 1), 1) # 新吸附的球, 与两个红球相邻
	var res: Dictionary = b.resolve_at(Vector2i(0, 1))
	assert_eq(res["popped"].size(), 3, "三球全消")
	assert_eq(res["color_counts"].get(1, 0), 3, "结果带颜色统计")
	assert_false(b.has_ball(Vector2i(0, 0)))
	assert_false(b.has_ball(Vector2i(1, 0)))
	assert_false(b.has_ball(Vector2i(0, 1)))


func test_resolve_keeps_cluster_of_two() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 0), 1)
	b.set_ball(Vector2i(0, 1), 1) # 只有两个相连
	var res: Dictionary = b.resolve_at(Vector2i(0, 1))
	assert_eq(res["popped"].size(), 0, "不足3个不消除")
	assert_true(b.has_ball(Vector2i(0, 0)))
	assert_true(b.has_ball(Vector2i(0, 1)))
