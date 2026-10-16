extends "res://tests/test_case.gd"

const Ui = preload("res://src/ui/theme.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")
const Game = preload("res://src/logic/game.gd")


func test_top_row_balls_do_not_intrude_hud() -> void:
	# 独立真值: HUD(分数/提示)占屏幕顶部 ~84px, 顶行球不得压进该区
	var ball_top: float = Ui.BOARD_TOP - Game.BALL_RADIUS
	assert_true(ball_top >= 90.0, "顶行球上沿(%.0f)必须在HUD区(0..84)之下" % ball_top)


func test_score_text_and_combo_pill_do_not_overlap() -> void:
	# 独立真值: 分数文字预留到 x=270, 连击胶囊从 276 开始, 中间有缝
	assert_true(Ui.COMBO_PILL_X >= Ui.SCORE_TEXT_MAX_X + 4.0,
		"分数(最远%.0f)与连击胶囊(%.0f)不重叠" % [Ui.SCORE_TEXT_MAX_X, Ui.COMBO_PILL_X])


func test_deadline_line_touches_bottom_of_drop_row() -> void:
	# 独立真值: 触线即掉 = deadline 行(r=13)球的下沿(y = 13*行高 + 半径)
	# 线之下到发射器之间就是"区域标注框"的下边界
	var line_y: float = BoardCamera.deadline_line_y(13, 57.1577, 33.0, 129.0)
	assert_true(abs(line_y - 905.05) < 0.1, "底线在触线行球的下沿, 实际 %.2f" % line_y)
	assert_true(line_y < 1038.0 - 33.0 - 40.0, "底线与发射器之间留出空间")


func test_panel_bottom_hugs_deadline() -> void:
	# 区域标注框的下边界 = 底线 + 12px 留白, 不得拖出大片空白
	var panel_bottom: float = BoardCamera.panel_bottom(13, 57.1577, 33.0, 129.0)
	assert_true(abs(panel_bottom - 917.05) < 0.1, "框底贴着底线, 实际 %.2f" % panel_bottom)
