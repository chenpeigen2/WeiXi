extends Node2D
## 棋盘视图：玻璃面板背板 + 全部球（顶部滑出隐藏）+ 三消选中环。
## 掉球线由独立的 DeadlineView 绘制，闪烁时不必重绘整盘球。

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
	_panel.border_color = Ui.MINT
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(int(Ui.PANEL_RADIUS_LARGE))
	_panel.shadow_color = Color(0, 0, 0, 0.22)
	_panel.shadow_size = 16
	_panel.shadow_offset = Vector2(0, 6)


func cam_origin() -> Vector2:
	return BoardCamera.origin_for(game.board.rows, game.layout.row_height, game.layout.diameter, game.board.width * game.layout.diameter)


func _draw() -> void:
	if game == null:
		return
	var layout = game.layout
	var origin := cam_origin()

	# 背板：区域标注框，紧贴球区（上沿顶行球留白，下沿贴底线）
	var panel_top_y: float = BoardCamera.panel_top(origin.y, layout.radius)
	var panel_bottom_y: float = BoardCamera.panel_bottom(game.deadline_row, layout.row_height, layout.radius, origin.y)
	draw_style_box(_panel, Rect2(
		Ui.BOARD_PANEL_X,
		panel_top_y,
		Ui.BOARD_PANEL_W,
		panel_bottom_y - panel_top_y
	))

	# 顶部高光 + 奶油花边：小圆点沿着上下边缘，像糖霜。
	draw_line(
		Vector2(Ui.BOARD_PANEL_X + 26.0, panel_top_y + 1.0),
		Vector2(Ui.BOARD_PANEL_X + Ui.BOARD_PANEL_W - 26.0, panel_top_y + 1.0),
		Color(0.62, 0.88, 0.74, 0.65), 1.0
	)
	var lace := Color(0.80, 0.73, 0.95, 0.55)
	var dot_x := Ui.BOARD_PANEL_X + 30.0
	while dot_x < Ui.BOARD_PANEL_X + Ui.BOARD_PANEL_W - 30.0:
		draw_circle(Vector2(dot_x, panel_top_y + 9.0), 2.2, lace)
		draw_circle(Vector2(dot_x, panel_bottom_y - 9.0), 2.2, lace)
		dot_x += 26.0
	_heart(Vector2(Ui.BOARD_PANEL_X + 20.0, panel_top_y + 20.0), 5.0, Ui.ROSE, 0.75)
	_heart(Vector2(Ui.BOARD_PANEL_X + Ui.BOARD_PANEL_W - 20.0, panel_top_y + 20.0), 5.0, Ui.ROSE, 0.75)
	# 很淡的波点糖霜，藏在球后面
	var dot := Color(0.80, 0.73, 0.95, 0.10)
	for gy in range(3):
		for gx in range(5):
			draw_circle(Vector2(
				Ui.BOARD_PANEL_X + 64.0 + gx * 142.0,
				panel_top_y + 96.0 + gy * 250.0
			), 3.2, dot)

	# 空棋盘上的奶油暗纹：大爱心 + 小星星，填一点可爱但不抢球。
	_heart(Vector2(Ui.SCREEN_W * 0.5, panel_bottom_y - 130.0), 30.0, Ui.ROSE, 0.055)
	for star_pos in [Vector2(120, panel_top_y + 390), Vector2(628, panel_top_y + 470), Vector2(548, panel_top_y + 170)]:
		_star(star_pos, 7.0, Color(0.80, 0.73, 0.95, 0.16))

	# 球（滑出顶部的行隐藏不画）
	var r: float = layout.radius
	for cell in game.board.cells:
		if hidden_cells.has(cell):
			continue
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(cell), 1.0, origin)
		if pos.y < Ui.BOARD_TOP - r:
			continue
		BallDraw.draw_ball(self, pos, r * 0.95, Ui.BALL_COLORS[game.board.get_color(cell)])

	# 三消选中环：外层柔光 + 内层实线
	if selected != INVALID_CELL and game.board.has_ball(selected):
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(selected), 1.0, origin)
		var glow := Ui.ACCENT
		glow.a = 0.18
		draw_arc(pos, r * 1.16, 0, TAU, 40, glow, 7.0, true)
		draw_arc(pos, r * 1.05, 0, TAU, 40, Ui.SELECTION, 3.5, true)


## 小爱心：棋盘边角的糖霜装饰。
func _heart(p: Vector2, s: float, c: Color, a: float) -> void:
	var col := Color(c.r, c.g, c.b, a)
	draw_circle(p + Vector2(-s * 0.38, -s * 0.18), s * 0.48, col)
	draw_circle(p + Vector2(s * 0.38, -s * 0.18), s * 0.48, col)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.82, -s * 0.05), p + Vector2(s * 0.82, -s * 0.05), p + Vector2(0, s * 0.85),
	]), col)


func _star(p: Vector2, s: float, c: Color) -> void:
	var q: float = s * 0.22
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -s), p + Vector2(q, -q), p + Vector2(s, 0), p + Vector2(q, q),
		p + Vector2(0, s), p + Vector2(-q, q), p + Vector2(-s, 0), p + Vector2(-q, -q),
	]), c)
