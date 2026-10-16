extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")
const HexLayout = preload("res://src/logic/hex_layout.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")

const R := 10.0
const W_PX := 10 * 2 * R # 10列 x 直径


func test_straight_up_to_empty_ceiling() -> void:
	var b := Board.new(10, 12)
	var l := HexLayout.new(R)
	# 从 (100,500) 正上方发射, 空盘 → 吸附到顶行最近的格子 (col=5)
	var cell := Trajectory.find_attach_cell(b, l, Vector2(100, 500), Vector2(0, -1), W_PX)
	assert_eq(cell, Vector2i(5, 0), "顶行第5列")


func test_attach_below_blocking_ball() -> void:
	var b := Board.new(10, 12)
	var l := HexLayout.new(R)
	b.set_ball(Vector2i(5, 0), 1) # 挡路球在 (100, 0)
	var cell := Trajectory.find_attach_cell(b, l, Vector2(100, 500), Vector2(0, -1), W_PX)
	assert_eq(cell, Vector2i(5, 1), "贴到挡路球正下方的空位")


func test_wall_bounce_still_lands_valid() -> void:
	var b := Board.new(10, 12)
	var l := HexLayout.new(R)
	# 紧贴左墙向左上发射, 必经反弹, 最终也要落在合法空格
	var cell := Trajectory.find_attach_cell(b, l, Vector2(R, 500), Vector2(-0.5, -1), W_PX)
	assert_true(b.is_valid_cell(cell), "合法格 %s" % str(cell))
	assert_false(b.has_ball(cell), "落在空格")
	assert_eq(cell.y, 0, "弹到顶行")
