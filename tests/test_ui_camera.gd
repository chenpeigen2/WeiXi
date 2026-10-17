extends "res://tests/test_case.gd"

const BoardCamera = preload("res://src/ui/board_camera.gd")
const Game = preload("res://src/logic/game.gd")
const Ui = preload("res://src/ui/theme.gd")

const RH := 57.1577 # sqrt(3) * 33（球半径33的行高）


func test_scale_always_one_no_shrink() -> void:
	assert_eq(BoardCamera.scale_for(12, RH, 66.0), 1.0, "12行不缩放")
	assert_eq(BoardCamera.scale_for(30, RH, 66.0), 1.0, "30行也不缩放, 球大小恒定")


func test_origin_top_aligned_when_fits() -> void:
	# 12行总高 12*57.1577+66 ≈ 752 < 870 → 顶对齐；x 补半个球：45 + 16.5 = 61.5
	assert_vec_near(BoardCamera.origin_for(12, RH, 66.0, 660.0), Vector2(61.5, 129))


func test_origin_slides_up_when_tall() -> void:
	# 20行总高 20*57.1577+66 ≈ 1209.2, 超出870的部分上滑
	var o := BoardCamera.origin_for(20, RH, 66.0, 660.0)
	assert_vec_near(o, Vector2(61.5, 129.0 - (20.0 * RH + 66.0 - 870.0)), "顶部溢出上滑")


func test_screen_board_roundtrip() -> void:
	var o := BoardCamera.origin_for(20, RH, 66.0, 660.0)
	var p := Vector2(123, 456)
	assert_vec_near(BoardCamera.to_screen(BoardCamera.to_board(p, 1.0, o), 1.0, o), p, "往返一致")


func test_max_rows_matches_camera_capacity() -> void:
	# 棋盘行数上限与相机可见容量必须一致：MAX_ROWS 装得下，+1 装不下
	var m: int = Game.MAX_ROWS
	assert_true(m * RH + 66.0 <= 870.0, "MAX_ROWS 行必须装得进可见区")
	assert_true((m + 1) * RH + 66.0 > 870.0, "MAX_ROWS+1 行必须装不下")


func test_ball_field_is_centered_inside_panel() -> void:
	# 独立真值：偶数行左沿到奇数行右沿是球区实际宽度，左右留白必须相等，
	# 且球区不能压出面板（面板 x = BOARD_MARGIN_X-8 .. SCREEN_W-(BOARD_MARGIN_X-8)）。
	var o := BoardCamera.origin_for(14, RH, 66.0, 660.0)
	var left: float = o.x - 33.0
	var right: float = o.x + 9.5 * 66.0 + 33.0
	var panel_left: float = Ui.BOARD_MARGIN_X - 8.0
	var panel_right: float = Ui.SCREEN_W - panel_left
	assert_true(abs(left - (Ui.SCREEN_W - right)) < 0.001,
		"球区左右留白相等, 实际 left=%.1f right=%.1f" % [left, right])
	assert_true(left >= panel_left - 0.001 and right <= panel_right + 0.001,
		"球区(%.1f..%.1f)必须在面板(%.1f..%.1f)内" % [left, right, panel_left, panel_right])
