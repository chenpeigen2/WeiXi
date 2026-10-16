extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_floating_finds_balls_detached_from_top() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(5, 0), 1) # 顶行, 锚定
	b.set_ball(Vector2i(5, 1), 2) # 挂在锚定球下
	b.set_ball(Vector2i(8, 8), 3) # 孤立的球
	b.set_ball(Vector2i(8, 9), 3) # 与孤立球相连, 同样悬空
	var fl := b.floating()
	assert_eq(fl.size(), 2, "两个孤立球悬空")
	assert_has(fl, Vector2i(8, 8))
	assert_has(fl, Vector2i(8, 9))


func test_resolve_drops_floating_after_pop() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(5, 0), 1)
	b.set_ball(Vector2i(6, 0), 1)
	b.set_ball(Vector2i(5, 2), 2) # 只靠 (5,1) 吊着
	b.set_ball(Vector2i(5, 1), 1) # 吸附后三个红球相连
	var res: Dictionary = b.resolve_at(Vector2i(5, 1))
	assert_eq(res["popped"].size(), 3, "三个红球消除")
	assert_eq(res["dropped"].size(), 1, "失去支撑的绿球掉落")
	assert_has(res["dropped"], Vector2i(5, 2))
	assert_false(b.has_ball(Vector2i(5, 2)))
