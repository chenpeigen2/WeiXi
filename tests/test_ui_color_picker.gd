extends "res://tests/test_case.gd"

const BallPicker = preload("res://src/ui/color_picker.gd")


func test_hit_each_swatch() -> void:
	for i in range(6):
		assert_eq(BallPicker.hit(BallPicker.pos_of(i)), i, "命中第%d个色块" % i)


func test_miss_returns_minus_one() -> void:
	assert_eq(BallPicker.hit(Vector2(240, 400)), -1, "空白处不命中")
	assert_eq(BallPicker.hit(Vector2(0, 0)), -1, "角落不命中")
