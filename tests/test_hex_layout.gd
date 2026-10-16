extends "res://tests/test_case.gd"

const HexLayout = preload("res://src/logic/hex_layout.gd")


func test_cell_to_pixel_origin() -> void:
	var l := HexLayout.new(10.0)
	assert_vec_near(l.cell_to_pixel(Vector2i(0, 0)), Vector2(0, 0), "原点格")


func test_odd_row_indented_half_cell() -> void:
	var l := HexLayout.new(10.0)
	# 第1行第0列: x 偏移半个直径 = R, y = sqrt(3)*R
	assert_vec_near(l.cell_to_pixel(Vector2i(0, 1)), Vector2(10.0, sqrt(3.0) * 10.0), "奇数行缩进")


func test_even_row_2_shifted_left() -> void:
	var l := HexLayout.new(10.0)
	# 第2行第0列对应 q=-1: x = 0, y = 2*sqrt(3)*R
	assert_vec_near(l.cell_to_pixel(Vector2i(-1, 2)), Vector2(0, 2.0 * sqrt(3.0) * 10.0))


func test_round_trip_pixel_cell() -> void:
	var l := HexLayout.new(10.0)
	for c in [Vector2i(0, 0), Vector2i(3, 4), Vector2i(-1, 3), Vector2i(9, 0), Vector2i(0, 7), Vector2i(-2, 5)]:
		assert_eq(l.pixel_to_cell(l.cell_to_pixel(c)), c, "往返一致 %s" % str(c))
