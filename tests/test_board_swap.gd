extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")


func test_swap_horizontal_match_pops_and_drops() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(2, 0), 3) # 顶行锚点(无关色)
	b.set_ball(Vector2i(0, 1), 1)
	b.set_ball(Vector2i(1, 1), 1)
	b.set_ball(Vector2i(2, 1), 2) # 与下面的红球互换后 row1 三连红
	b.set_ball(Vector2i(2, 2), 1)
	var res: Dictionary = b.swap(Vector2i(2, 1), Vector2i(2, 2))
	assert_true(res["matched"], "互换产生消除")
	assert_eq(res["popped"].size(), 3, "三个红球消除")
	assert_eq(res["color_counts"].get(1, 0), 3, "互换结果带颜色统计")
	# 换到 (2,2) 的蓝球失去与顶行的连接, 悬空掉落
	assert_has(res["dropped"], Vector2i(2, 2))
	assert_eq(b.ball_count(), 1, "只剩顶行锚点")


func test_swap_diagonal_axis_match() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(2, 0), 1) # (2,0)-(1,1)-(0,2) 是 (1,-1) 轴线
	b.set_ball(Vector2i(0, 2), 1)
	b.set_ball(Vector2i(1, 1), 2) # 与 (1,2) 的红球互换后斜线三连
	b.set_ball(Vector2i(1, 2), 1)
	var res: Dictionary = b.swap(Vector2i(1, 1), Vector2i(1, 2))
	assert_true(res["matched"], "斜轴三连消除")
	assert_eq(res["popped"].size(), 3)


func test_swap_without_match_reverts() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 0), 3) # 锚点
	b.set_ball(Vector2i(0, 1), 1)
	b.set_ball(Vector2i(1, 1), 2)
	var res: Dictionary = b.swap(Vector2i(0, 1), Vector2i(1, 1))
	assert_false(res["matched"], "无连线则换回")
	assert_eq(b.get_color(Vector2i(0, 1)), 1, "红球回到原位")
	assert_eq(b.get_color(Vector2i(1, 1)), 2, "蓝球回到原位")


func test_swap_rejects_non_adjacent() -> void:
	var b := Board.new(10, 12)
	b.set_ball(Vector2i(0, 0), 1)
	b.set_ball(Vector2i(5, 5), 2)
	var res: Dictionary = b.swap(Vector2i(0, 0), Vector2i(5, 5))
	assert_false(res["matched"], "不相邻不能换")
	assert_eq(b.get_color(Vector2i(0, 0)), 1)
	assert_eq(b.get_color(Vector2i(5, 5)), 2)
