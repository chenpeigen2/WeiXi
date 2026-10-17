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
	assert_eq(s.fever_charges, 3, "进入 3 次 Fever")
	assert_true(s.is_fever())


func test_fever_doubles_three_clears_then_ends() -> void:
	var s := Scorer.new()
	s.add_star(100)
	assert_eq(s.register_clear(3, 0), 60, "第一次 Fever x2")
	assert_eq(s.fever_charges, 2)
	assert_eq(s.register_clear(3, 0), 120, "连击2 x Fever2")
	assert_eq(s.fever_charges, 1)
	assert_eq(s.register_clear(3, 0), 180, "连击3 x Fever2")
	assert_eq(s.fever_charges, 0)
	var after := s.register_clear(3, 0)
	assert_eq(after, 120, "Fever 结束回到 x1，连击4")


func test_miss_does_not_consume_fever() -> void:
	var s := Scorer.new()
	s.add_star(100)
	s.register_miss()
	assert_eq(s.fever_charges, 3, "miss 不消耗 Fever")


func test_wish_reward_can_fill_during_fever() -> void:
	var s := Scorer.new()
	s.add_star(100)
	s.add_star(25, true)
	assert_eq(s.star, 25, "愿望奖励在 Fever 期间仍可积累")
	s.add_star(75, true)
	assert_eq(s.star, 0)
	assert_eq(s.fever_charges, 3, "满 100 刷新 3 次 Fever")
