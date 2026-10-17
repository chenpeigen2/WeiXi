extends "res://tests/test_case.gd"

const Board = preload("res://src/logic/board.gd")
const HexLayout = preload("res://src/logic/hex_layout.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")

const R := 10.0
const W_PX := 10 * 2 * R


func test_trace_straight_up_path_and_cell() -> void:
	var b := Board.new(10, 12)
	var l := HexLayout.new(R)
	var res: Dictionary = Trajectory.trace_path(b, l, Vector2(100, 500), Vector2(0, -1), W_PX)
	assert_eq(res["cell"], Vector2i(5, 0), "落点与 find_attach_cell 一致")
	var pts: PackedVector2Array = res["points"]
	assert_true(pts.size() >= 3, "有路径点")
	var last_y := 9999.0
	for p in pts:
		assert_eq(p.x, 100.0, "直线弹道x不变")
		assert_true(p.y < last_y, "y严格递减")
		last_y = p.y


func test_trace_wall_bounce_has_turning_point() -> void:
	var b := Board.new(10, 12)
	var l := HexLayout.new(R)
	var res: Dictionary = Trajectory.trace_path(b, l, Vector2(R, 500), Vector2(-0.5, -1), W_PX)
	assert_eq(res["cell"].y, 0, "弹墙后仍到顶")
	var pts: PackedVector2Array = res["points"]
	var min_x := 9999.0
	for p in pts:
		if p.x < min_x:
			min_x = p.x
	# 反弹后横坐标仍被夹在墙边 [R, R+步进] ≈ [10, 11.2]
	assert_true(min_x < R + 2.0, "先贴到左墙, min_x=%f" % min_x)
	assert_true(pts[pts.size() - 1].x > min_x + 5.0, "反弹后向右")
	assert_true(min_x < R - 2.0, "左侧球心边界应为 0，而不是 R；实际 min_x=%.2f" % min_x)
	assert_true(int(res["bounces"]) >= 1, "记录反弹次数")
	var bps: PackedVector2Array = res["bounce_points"]
	assert_true(bps.size() >= 1, "记录反弹点")
	assert_true(bps[0].x < 1.0, "左反弹点应贴在球区左边界 x=0")
