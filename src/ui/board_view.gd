extends Node2D
## 棋盘视图：玻璃面板背板 + 全部球（顶部滑出隐藏）+ 三消选中环 + 发光安全线。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")

const INVALID_CELL := Vector2i(-999, -999)

var game: RefCounted
var selected := INVALID_CELL
var hidden_cells := {} # 互换动画期间被覆盖层接管、暂停绘制的格子

var _panel: StyleBoxFlat


func _ready() -> void:
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.PANEL_STROKE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(30)


func cam_origin() -> Vector2:
	return BoardCamera.origin_for(game.board.rows, game.layout.row_height, game.layout.diameter, game.board.width * game.layout.diameter)


func _draw() -> void:
	if game == null:
		return
	var layout = game.layout
	var origin := cam_origin()

	# 背板：区域标注框，紧贴球区（上沿顶行球留白，下沿贴底线）
	var panel_bottom_y: float = BoardCamera.panel_bottom(game.deadline_row, layout.row_height, layout.radius, origin.y)
	draw_style_box(_panel, Rect2(
		Ui.BOARD_MARGIN_X - 8,
		Ui.BOARD_TOP - 10,
		Ui.SCREEN_W - (Ui.BOARD_MARGIN_X - 8) * 2,
		panel_bottom_y - (Ui.BOARD_TOP - 10)
	))

	# 球（滑出顶部的行隐藏不画）
	var r: float = layout.radius
	for cell in game.board.cells:
		if hidden_cells.has(cell):
			continue
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(cell), 1.0, origin)
		if pos.y < Ui.BOARD_TOP - r:
			continue
		BallDraw.draw_ball(self, pos, r * 0.95, Ui.BALL_COLORS[game.board.get_color(cell)])

	# 三消选中环
	if selected != INVALID_CELL and game.board.has_ball(selected):
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(selected), 1.0, origin)
		draw_arc(pos, r * 1.05, 0, TAU, 40, Ui.SELECTION, 3.5, true)

	# 发光安全线（非死亡线，触线即掉）
	var line_y: float = BoardCamera.deadline_line_y(game.deadline_row, layout.row_height, layout.radius, origin.y)
	var x0 := Ui.BOARD_MARGIN_X
	var x1 := Ui.SCREEN_W - Ui.BOARD_MARGIN_X
	var glow := Ui.DEADLINE
	glow.a = 0.10
	draw_line(Vector2(x0, line_y), Vector2(x1, line_y), glow, 8.0)
	glow.a = 0.25
	draw_line(Vector2(x0, line_y), Vector2(x1, line_y), glow, 4.0)
	draw_dashed_line(Vector2(x0, line_y), Vector2(x1, line_y), Ui.DEADLINE, 2.0, 12.0)
