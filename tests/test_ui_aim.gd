extends "res://tests/test_case.gd"

const Shooter = preload("res://src/ui/shooter.gd")


func test_aim_clamped_upward() -> void:
	var d: Vector2 = Shooter.clamp_aim(Vector2(1, 1))
	assert_true(d.y <= -0.14, "向下瞄准被抬起到水平以上, y=%f" % d.y)
	assert_true(abs(d.length() - 1.0) < 0.001, "保持单位向量")


func test_aim_straight_up_unchanged() -> void:
	assert_vec_near(Shooter.clamp_aim(Vector2(0, -1)), Vector2(0, -1))


func test_aim_zero_falls_back_up() -> void:
	assert_vec_near(Shooter.clamp_aim(Vector2.ZERO), Vector2.UP)
