extends Node2D
## 棋盘视图：玻璃面板背板 + 全部球 + 三消选中环 + 安全虚线。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")

const INVALID_CELL := Vector2i(-999, -999)

var game: RefCounted
var selected := INVALID_CELL

var _panel: StyleBoxFlat


func _ready() -> void:
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.PANEL_STROKE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(20)


func _draw() -> void:
	if game == null:
		return
	var layout = game.layout
	var s := BoardCamera.scale_for(game.board.rows, layout.row_height, layout.diameter)
	var origin := BoardCamera.origin_for(s, game.board.width * layout.diameter)

	# 背板
	draw_style_box(_panel, Rect2(
		Ui.BOARD_MARGIN_X - 8,
		Ui.BOARD_TOP - 10,
		Ui.SCREEN_W - (Ui.BOARD_MARGIN_X - 8) * 2,
		Ui.BOARD_AREA_H + 20
	))

	# 球
	var r: float = layout.radius * s
	for cell in game.board.cells:
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(cell), s, origin)
		BallDraw.draw_ball(self, pos, r * 0.95, Ui.BALL_COLORS[game.board.get_color(cell)])

	# 三消选中环
	if selected != INVALID_CELL and game.board.has_ball(selected):
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(selected), s, origin)
		draw_arc(pos, r * 1.05, 0, TAU, 40, Ui.SELECTION, 2.5, true)

	# 安全虚线（非死亡线，触底自动续行）
	var line_y: float = BoardCamera.to_screen(Vector2(0, (game.deadline_row + 1) * layout.row_height), s, origin).y
	draw_dashed_line(
		Vector2(Ui.BOARD_MARGIN_X, line_y),
		Vector2(Ui.SCREEN_W - Ui.BOARD_MARGIN_X, line_y),
		Ui.DEADLINE, 2.0, 10.0
	)
