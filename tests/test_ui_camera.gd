extends "res://tests/test_case.gd"

const BoardCamera = preload("res://src/ui/board_camera.gd")
const Game = preload("res://src/logic/game.gd")

const RH := 57.1577 # sqrt(3) * 33（球半径33的行高）


func test_scale_always_one_no_shrink() -> void:
	assert_eq(BoardCamera.scale_for(12, RH, 66.0), 1.0, "12行不缩放")
	assert_eq(BoardCamera.scale_for(30, RH, 66.0), 1.0, "30行也不缩放, 球大小恒定")


func test_origin_top_aligned_when_fits() -> void:
	# 12行总高 12*57.1577+66 ≈ 752 < 870 → 顶对齐, x 居中 (750-660)/2=45
	assert_vec_near(BoardCamera.origin_for(12, RH, 66.0, 660.0), Vector2(45, 96))


func test_origin_slides_up_when_tall() -> void:
	# 20行总高 20*57.1577+66 ≈ 1209.2, 超出870的部分上滑
	var o := BoardCamera.origin_for(20, RH, 66.0, 660.0)
	assert_vec_near(o, Vector2(45, 96.0 - (20.0 * RH + 66.0 - 870.0)), "顶部溢出上滑")


func test_screen_board_roundtrip() -> void:
	var o := BoardCamera.origin_for(20, RH, 66.0, 660.0)
	var p := Vector2(123, 456)
	assert_vec_near(BoardCamera.to_screen(BoardCamera.to_board(p, 1.0, o), 1.0, o), p, "往返一致")


func test_max_rows_matches_camera_capacity() -> void:
	# 棋盘行数上限与相机可见容量必须一致：MAX_ROWS 装得下，+1 装不下
	var m: int = Game.MAX_ROWS
	assert_true(m * RH + 66.0 <= 870.0, "MAX_ROWS 行必须装得进可见区")
	assert_true((m + 1) * RH + 66.0 > 870.0, "MAX_ROWS+1 行必须装不下")
