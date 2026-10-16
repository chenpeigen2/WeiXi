extends "res://tests/test_case.gd"

const BoardCamera = preload("res://src/ui/board_camera.gd")


func test_scale_is_one_when_board_fits() -> void:
	var rh := sqrt(3.0) * 18.0
	assert_eq(BoardCamera.scale_for(12, rh, 36.0), 1.0, "12行内不缩放")


func test_scale_shrinks_when_board_tall() -> void:
	var rh := sqrt(3.0) * 18.0
	var s: float = BoardCamera.scale_for(30, rh, 36.0)
	# 精确值 = 可用高 / (行数*行高 + 直径)
	assert_true(abs(s - 810.0 / (30.0 * rh + 36.0)) < 0.0001, "30行按比例缩小")


func test_screen_board_roundtrip() -> void:
	var s := 0.7
	var o := BoardCamera.origin_for(s, 360.0)
	var p := Vector2(123, 456)
	assert_vec_near(BoardCamera.to_screen(BoardCamera.to_board(p, s, o), s, o), p, "往返一致")


func test_origin_centers_board_horizontally() -> void:
	# 屏宽720, 板宽360*0.5=180 → x = (720-180)/2 = 270, 顶边距96
	assert_vec_near(BoardCamera.origin_for(0.5, 360.0), Vector2(270, 96))
