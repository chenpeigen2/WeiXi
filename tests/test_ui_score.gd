extends "res://tests/test_case.gd"

const ScorePanel = preload("res://src/ui/score_panel.gd")


func test_score_formatting_keeps_panel_readable() -> void:
	assert_eq(ScorePanel.format_score(30), "30")
	assert_eq(ScorePanel.format_score(1234), "1,234")
	assert_eq(ScorePanel.format_score(123456), "12.3万")
	assert_eq(ScorePanel.format_score(123456789), "1.2亿")
