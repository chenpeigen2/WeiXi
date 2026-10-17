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


func test_star_meter_fills_and_enters_fever() -> void:
	var s := Scorer.new()
	s.add_star(60)
	assert_eq(s.star, 60)
	s.add_star(40)
	assert_eq(s.star, 0, "满 100 清空")
	assert_eq(s.fever_shots, 3, "进入 3 发 Fever")
	assert_true(s.is_fever())


func test_fever_multiplier_is_explicit_and_does_not_tick_in_scorer() -> void:
	var s := Scorer.new()
	s.add_star(100)
	assert_eq(s.register_clear(3, 0, true), 60, "Fever 射击 x2")
	assert_eq(s.fever_shots, 3, "Scorer 不负责扣发数")
	assert_eq(s.register_clear(3, 0, false), 60, "非射击结算不翻倍，连击2")
	assert_eq(s.fever_shots, 3)


func test_wish_reward_can_fill_during_fever() -> void:
	var s := Scorer.new()
	s.add_star(100)
	s.add_star(25, true)
	assert_eq(s.star, 25, "愿望奖励在 Fever 期间仍可积累")
	s.add_star(75, true)
	assert_eq(s.star, 0)
	assert_eq(s.fever_shots, 3, "满 100 刷新 3 发 Fever")
