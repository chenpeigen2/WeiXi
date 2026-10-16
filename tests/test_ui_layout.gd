extends "res://tests/test_case.gd"

const Ui = preload("res://src/ui/theme.gd")
const Game = preload("res://src/logic/game.gd")


func test_top_row_balls_do_not_intrude_hud() -> void:
	# 独立真值: HUD(分数/提示)占屏幕顶部 ~84px, 顶行球不得压进该区
	var ball_top: float = Ui.BOARD_TOP - Game.BALL_RADIUS
	assert_true(ball_top >= 90.0, "顶行球上沿(%.0f)必须在HUD区(0..84)之下" % ball_top)


func test_score_text_and_combo_pill_do_not_overlap() -> void:
	# 独立真值: 分数文字预留到 x=270, 连击胶囊从 276 开始, 中间有缝
	assert_true(Ui.COMBO_PILL_X >= Ui.SCORE_TEXT_MAX_X + 4.0,
		"分数(最远%.0f)与连击胶囊(%.0f)不重叠" % [Ui.SCORE_TEXT_MAX_X, Ui.COMBO_PILL_X])
