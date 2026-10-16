extends "res://tests/test_case.gd"

const HexGrid = preload("res://src/logic/hex_grid.gd")


func test_neighbors_returns_six_axial_cells() -> void:
	# 轴坐标六邻接是标准定义: E/W/SE/NW/NE/SW
	var n := HexGrid.neighbors(Vector2i(2, 3))
	assert_eq(n.size(), 6, "六个邻居")
	assert_has(n, Vector2i(3, 3), "E")
	assert_has(n, Vector2i(1, 3), "W")
	assert_has(n, Vector2i(2, 4), "SE")
	assert_has(n, Vector2i(2, 2), "NW")
	assert_has(n, Vector2i(3, 2), "NE")
	assert_has(n, Vector2i(1, 4), "SW")


func test_q_min_for_odd_r_offset_rows() -> void:
	# odd-r 错排: col = q - q_min(r), 每两行 q 起点左移一格
	assert_eq(HexGrid.q_min(0), 0, "第0行")
	assert_eq(HexGrid.q_min(1), 0, "第1行")
	assert_eq(HexGrid.q_min(2), -1, "第2行")
	assert_eq(HexGrid.q_min(3), -1, "第3行")
	assert_eq(HexGrid.q_min(4), -2, "第4行")
