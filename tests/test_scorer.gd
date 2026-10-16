extends "res://tests/test_case.gd"

const Scorer = preload("res://src/logic/scorer.gd")


func test_first_clear_base_score() -> void:
	var s := Scorer.new()
	# 消除3球 x 10分 x 连击1
	assert_eq(s.register_clear(3, 0), 30, "首次消除")
	assert_eq(s.score, 30)


func test_dropped_balls_double_value() -> void:
	var s := Scorer.new()
	# 消除3球 + 掉落2球: (3*10 + 2*20) * 1 = 70
	assert_eq(s.register_clear(3, 2), 70, "掉落加倍")


func test_combo_multiplier_grows() -> void:
	var s := Scorer.new()
	s.register_clear(3, 0) # 连击升到2
	# 第二次: (3*10 + 1*20) * 2 = 100
	assert_eq(s.register_clear(3, 1), 100, "连击x2")


func test_miss_resets_combo() -> void:
	var s := Scorer.new()
	s.register_clear(3, 0)
	s.register_miss()
	assert_eq(s.combo, 1, "连击清零")
	assert_eq(s.register_clear(3, 0), 30, "重新从x1算起")
