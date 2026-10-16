extends "res://tests/test_case.gd"

const BoardCamera = preload("res://src/ui/board_camera.gd")

const RH := 31.1769 # sqrt(3) * 18


func test_scale_always_one_no_shrink() -> void:
	assert_eq(BoardCamera.scale_for(12, RH, 36.0), 1.0, "12行不缩放")
	assert_eq(BoardCamera.scale_for(30, RH, 36.0), 1.0, "30行也不缩放, 球大小恒定")


func test_origin_top_aligned_when_fits() -> void:
	# 12行总高 12*31.1769+36 ≈ 410 < 810 → 顶对齐, x 居中 (720-600)/2=60
	assert_vec_near(BoardCamera.origin_for(12, RH, 36.0, 600.0), Vector2(60, 96))


func test_origin_slides_up_when_tall() -> void:
	# 30行总高 30*31.1769+36 ≈ 971.3, 超出810的部分上滑隐藏
	var o := BoardCamera.origin_for(30, RH, 36.0, 600.0)
	assert_vec_near(o, Vector2(60, 96.0 - (30.0 * RH + 36.0 - 810.0)), "顶部溢出上滑")


func test_screen_board_roundtrip() -> void:
	var o := BoardCamera.origin_for(30, RH, 36.0, 600.0)
	var p := Vector2(123, 456)
	assert_vec_near(BoardCamera.to_screen(BoardCamera.to_board(p, 1.0, o), 1.0, o), p, "往返一致")
