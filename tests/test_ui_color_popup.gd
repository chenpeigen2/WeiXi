extends "res://tests/test_case.gd"

const BallColorPopup = preload("res://src/ui/ball_color_popup.gd")


func test_swatch_hit() -> void:
	var c := Vector2(375, 600)
	for i in range(6):
		assert_eq(BallColorPopup.hit_at(c, BallColorPopup.swatch_pos(c, i)), i, "命中第%d个" % i)


func test_miss() -> void:
	var c := Vector2(375, 600)
	assert_eq(BallColorPopup.hit_at(c, Vector2(375, 800)), -1, "远处不命中")
	assert_eq(BallColorPopup.hit_at(c, c + Vector2(0, 60)), -1, "调色板下方不命中")


func test_clamp_center_keeps_popup_on_screen() -> void:
	var clamped: Vector2 = BallColorPopup.clamp_center(Vector2(10, 10))
	assert_true(clamped.x >= 150.0 and clamped.y >= 60.0, "左上被夹回屏幕")
	clamped = BallColorPopup.clamp_center(Vector2(740, 1260))
	assert_true(clamped.x <= 600.0 and clamped.y <= 1215.0, "右下被夹回屏幕")
	assert_vec_near(BallColorPopup.clamp_center(Vector2(375, 800)), Vector2(375, 800), "中间不动")
