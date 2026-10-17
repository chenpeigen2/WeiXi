extends "res://tests/test_case.gd"

const DailySeed = preload("res://src/logic/daily_seed.gd")


func test_same_date_same_seed() -> void:
	assert_eq(DailySeed.for_date(2026, 10, 17), DailySeed.for_date(2026, 10, 17))


func test_different_date_different_seed() -> void:
	assert_ne(DailySeed.for_date(2026, 10, 17), DailySeed.for_date(2026, 10, 18))


func test_today_seed_is_stable_within_day() -> void:
	assert_eq(DailySeed.today_seed(), DailySeed.today_seed())
