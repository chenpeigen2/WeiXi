extends Node2D
## 棋盘视图：玻璃面板背板 + 全部球（顶部滑出隐藏）+ 三消选中环。
## 掉球线由独立的 DeadlineView 绘制，闪烁时不必重绘整盘球。

const Ui = preload("res://src/ui/theme.gd")
const BallDraw = preload("res://src/ui/ball_draw.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")
const HexGrid = preload("res://src/logic/hex_grid.gd")
const BoardPanel = preload("res://src/ui/board_panel.gd")

const INVALID_CELL := Vector2i(-999, -999)

var game: RefCounted
var selected := INVALID_CELL
var hover_cell := INVALID_CELL
var hidden_cells := {} # 互换动画期间被覆盖层接管、暂停绘制的格子
var _landings: Array[Dictionary] = []
var _anim_t := 0.0
var _shake: Dictionary = {}

var _panel_mat: Panel
var _panel_glow: Control


func _ready() -> void:
	var mat := StyleBoxFlat.new()
	mat.bg_color = Color(0.80, 0.73, 0.95, 0.30)
	mat.set_corner_radius_all(38)
	mat.shadow_color = Color(0.36, 0.22, 0.30, 0.18)
	mat.shadow_size = 20
	mat.shadow_offset = Vector2(0, 8)
	_panel_mat = Panel.new()
	_panel_mat.name = "PanelMat"
	_panel_mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_mat.show_behind_parent = true
	_panel_mat.add_theme_stylebox_override("panel", mat)
	add_child(_panel_mat)
	_panel_glow = BoardPanel.new()
	_panel_glow.name = "PanelGlow"
	add_child(_panel_glow)


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
	var panel_rect := Rect2(
		Ui.BOARD_PANEL_X,
		panel_top_y,
		Ui.BOARD_PANEL_W,
		panel_bottom_y - panel_top_y
	)
	if _panel_mat != null:
		var mat_rect := panel_rect.grow(8.0)
		_panel_mat.position = mat_rect.position
		_panel_mat.size = mat_rect.size
	if _panel_glow != null:
		_panel_glow.set_panel(panel_rect)
	_bow(Vector2(panel_rect.get_center().x, panel_top_y + 1.0), 10.0)

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
	_heart(Vector2(panel_rect.position.x + 4.0, panel_top_y - 4.0), 5.0, Ui.ROSE, 0.8)
	_heart(Vector2(panel_rect.end.x - 4.0, panel_top_y - 4.0), 5.0, Ui.ROSE, 0.8)
	_heart(Vector2(panel_rect.position.x + 4.0, panel_bottom_y + 4.0), 4.5, Ui.ROSE, 0.6)
	_heart(Vector2(panel_rect.end.x - 4.0, panel_bottom_y + 4.0), 4.5, Ui.ROSE, 0.6)
	# 空棋盘上的奶油暗纹：大爱心 + 小星星，填一点可爱但不抢球。
	_heart(Vector2(Ui.SCREEN_W * 0.5, panel_bottom_y - 130.0), 30.0, Ui.ROSE, 0.055)
	for star_pos in [Vector2(120, panel_top_y + 390), Vector2(628, panel_top_y + 470), Vector2(548, panel_top_y + 170)]:
		_star(star_pos, 7.0, Color(0.80, 0.73, 0.95, 0.16))

	# 球（滑出顶部的行隐藏不画）
	var r: float = layout.radius
	for cell in game.board.cells:
		if hidden_cells.has(cell) or _is_landing(cell):
			continue
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(cell), 1.0, origin)
		if pos.y < Ui.BOARD_TOP - r:
			continue
		BallDraw.draw_ball(self, pos, r * 0.95, Ui.BALL_COLORS[game.board.get_color(cell)])

	for landing in _landings:
		_draw_landing(landing)

	# 悬停柔光（呼吸）
	if hover_cell != INVALID_CELL and hover_cell != selected and game.board.has_ball(hover_cell):
		var hp: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(hover_cell), 1.0, origin)
		var ha: float = 0.48 + 0.18 * (0.5 + 0.5 * sin(_anim_t * 5.0))
		draw_arc(hp, r * (1.06 + 0.02 * sin(_anim_t * 5.0)), 0, TAU, 36, Color(1.0, 0.96, 0.93, ha), 2.2, true)

	# 三消选中环 + 相邻目标小星星 + 虚线换位连接
	if selected != INVALID_CELL and game.board.has_ball(selected):
		var pos: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(selected), 1.0, origin)
		var pulse: float = 1.0 + 0.022 * sin(_anim_t * 6.0)
		var glow := Ui.ACCENT
		glow.a = 0.14 + 0.06 * (0.5 + 0.5 * sin(_anim_t * 6.0))
		draw_arc(pos, r * 1.16 * pulse, 0, TAU, 40, glow, 7.0, true)
		draw_arc(pos, r * 1.05 * pulse, 0, TAU, 40, Ui.SELECTION, 3.5, true)
		# 糖霜圆点沿着选中环慢慢转
		for pi in range(10):
			var ang: float = TAU * float(pi) / 10.0 + _anim_t * 0.35
			var dp: Vector2 = pos + Vector2(cos(ang), sin(ang)) * r * 1.10
			var da: float = 0.42 + 0.20 * (0.5 + 0.5 * sin(_anim_t * 4.0 + float(pi)))
			draw_circle(dp, 1.9, Color(1.0, 0.92, 0.96, da))
		_bunny(pos + Vector2(0, -r * 1.22 + 2.0 * sin(_anim_t * 4.0)), 7.6, Color(1.0, 0.96, 0.92), 1.0)
		var idx := 0
		for n in HexGrid.neighbors(selected):
			if not game.board.has_ball(n):
				continue
			var np: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(n), 1.0, origin)
			var tw: float = 0.40 + 0.24 * (0.5 + 0.5 * sin(_anim_t * 4.0 + float(idx) * 0.8))
			_heart(np + Vector2(r * 0.52, -r * 0.86), 3.5, Ui.ROSE, tw)
			idx += 1
		if hover_cell != INVALID_CELL and HexGrid.neighbors(selected).has(hover_cell):
			var hp2: Vector2 = BoardCamera.to_screen(layout.cell_to_pixel(hover_cell), 1.0, origin)
			draw_dashed_line(pos, hp2, Color(1.0, 0.55, 0.68, 0.70), 2.0, 8.0)
			draw_arc(hp2, r * 1.12, 0, TAU, 40, Ui.ACCENT, 2.5, true)


func set_hover(cell: Vector2i) -> void:
	if hover_cell != cell:
		hover_cell = cell
		queue_redraw()


func clear_landings() -> void:
	_landings.clear()
	queue_redraw()


func play_landing(cell: Vector2i, impact_dir: Vector2) -> void:
	if game == null or not game.board.has_ball(cell):
		return
	_landings.append({
		"cell": cell,
		"dir": impact_dir.normalized() if impact_dir != Vector2.ZERO else Vector2.UP,
		"t": 0.0,
		"color": game.board.get_color(cell),
	})
	queue_redraw()


func play_shake(amount: float) -> void:
	_shake = {"t": 0.0, "dur": 0.24, "amp": amount}


func is_shaking() -> bool:
	return not _shake.is_empty()


func clear_motion() -> void:
	_shake = {}
	position = Vector2.ZERO


func _process(delta: float) -> void:
	if selected != INVALID_CELL or hover_cell != INVALID_CELL:
		_anim_t += delta
		queue_redraw()
	if not _shake.is_empty():
		_shake["t"] += delta
		var sk: float = clampf(float(_shake["t"]) / float(_shake["dur"]), 0.0, 1.0)
		var fall: float = 1.0 - sk
		position = Vector2(
			sin(float(_shake["t"]) * 72.0) * float(_shake["amp"]) * fall,
			cos(float(_shake["t"]) * 53.0) * float(_shake["amp"]) * 0.55 * fall
		)
		if sk >= 1.0:
			_shake = {}
			position = Vector2.ZERO
	if _landings.is_empty():
		return
	var keep: Array[Dictionary] = []
	for l in _landings:
		l["t"] += delta / 0.38
		var cell: Vector2i = l["cell"]
		if l["t"] >= 1.0:
			continue
		if game == null or not game.board.has_ball(cell) or game.board.get_color(cell) != int(l["color"]):
			continue
		keep.append(l)
	_landings = keep
	queue_redraw()


func _is_landing(cell: Vector2i) -> bool:
	for l in _landings:
		if l["cell"] == cell:
			return true
	return false


## 落球：沿撞击方向挤压回弹 + 接触涟漪 + 奶油尘 + 小爱心。
func _draw_landing(l: Dictionary) -> void:
	var t: float = l["t"]
	var cell: Vector2i = l["cell"]
	var pos: Vector2 = BoardCamera.to_screen(game.layout.cell_to_pixel(cell), 1.0, cam_origin())
	var r: float = game.layout.radius
	var dir: Vector2 = l["dir"]
	var color: Color = Ui.BALL_COLORS[int(l["color"])]
	var w: float = exp(-8.0 * t) * cos(14.0 * t)
	var sx: float = 1.0 + 0.20 * w * absf(dir.y) - 0.12 * w * absf(dir.x)
	var sy: float = 1.0 - 0.24 * w * absf(dir.y) + 0.12 * w * absf(dir.x)
	var lift: float = -3.0 * sin(PI * t) * (1.0 - t)
	var fade: float = 1.0 - t

	# 接触涟漪
	var ring := Ui.ROSE
	ring.a = 0.42 * fade
	draw_arc(pos + Vector2(0, r * 0.82), r * (0.45 + 0.6 * t), 0, TAU, 40, ring, 3.0, true)
	# 奶油尘
	for i in range(7):
		var ang: float = PI * 0.12 + PI * 0.76 * float(i) / 6.0
		var dp := pos + Vector2(cos(ang), sin(ang)) * r * (0.88 + 0.55 * t)
		var dust := Color(1.0, 0.93, 0.88, 0.38 * fade)
		draw_circle(dp, 3.2 * fade, dust)

	# 球体挤压回弹
	draw_set_transform(pos + Vector2(0, lift), 0.0, Vector2(maxf(0.72, sx), maxf(0.72, sy)))
	BallDraw.draw_ball(self, Vector2.ZERO, r * 0.95, color, 1.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 两颗小爱心 + 两颗小星星从接触点冒出来
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		_heart(
			pos + Vector2(side * r * 0.45, r * 0.62 - 24.0 * t),
			4.0, Ui.ROSE, 0.65 * fade
		)
		_star(
			pos + Vector2(side * r * 0.82, -r * 0.15 - 26.0 * t),
			3.4 * (0.7 + 0.3 * fade), Color(1.0, 0.90, 0.66, 0.72 * fade)
		)


## 小兔头：选中球顶部的糖霜标记。
func _bunny(p: Vector2, s: float, c: Color, a: float) -> void:
	var col := Color(c.r, c.g, c.b, a)
	var inner := Color(1.0, 0.80, 0.87, a)
	var ink := Color(0.32, 0.18, 0.25, a)
	# 奶油贴纸底 + 玫瑰描边，让兔兔从浅色背板上跳出来
	draw_circle(p, s * 1.18, Color(1.0, 0.98, 0.94, 0.92 * a))
	draw_arc(p, s * 1.18, 0, TAU, 28, Color(0.92, 0.38, 0.55, 0.38 * a), 1.6, true)
	draw_circle(p + Vector2(-s * 0.34, -s * 0.78), s * 0.23, col)
	draw_circle(p + Vector2(s * 0.34, -s * 0.78), s * 0.23, col)
	draw_circle(p + Vector2(-s * 0.34, -s * 0.78), s * 0.11, inner)
	draw_circle(p + Vector2(s * 0.34, -s * 0.78), s * 0.11, inner)
	draw_circle(p, s * 0.53, col)
	draw_circle(p + Vector2(-s * 0.19, -s * 0.02), maxf(0.8, s * 0.07), ink)
	draw_circle(p + Vector2(s * 0.19, -s * 0.02), maxf(0.8, s * 0.07), ink)
	draw_arc(p + Vector2(0, s * 0.10), s * 0.14, 0.15, PI - 0.15, 8, ink, 0.9, true)
	var blush := Color(1.0, 0.58, 0.70, a * 0.50)
	draw_circle(p + Vector2(-s * 0.40, s * 0.08), s * 0.09, blush)
	draw_circle(p + Vector2(s * 0.40, s * 0.08), s * 0.09, blush)
	# 左耳小蝴蝶结
	var rose := Color(0.92, 0.38, 0.55, a)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.86, -s * 0.70),
		p + Vector2(-s * 0.48, -s * 0.58),
		p + Vector2(-s * 0.80, -s * 0.38),
	]), rose)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.38, -s * 0.72),
		p + Vector2(-s * 0.52, -s * 0.48),
		p + Vector2(-s * 0.28, -s * 0.42),
	]), rose)
	draw_circle(p + Vector2(-s * 0.53, -s * 0.56), s * 0.10, Color(1.0, 0.93, 0.88, a))


## 小爱心：棋盘边角的糖霜装饰。
func _heart(p: Vector2, s: float, c: Color, a: float) -> void:
	var col := Color(c.r, c.g, c.b, a)
	draw_circle(p + Vector2(-s * 0.38, -s * 0.18), s * 0.48, col)
	draw_circle(p + Vector2(s * 0.38, -s * 0.18), s * 0.48, col)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.82, -s * 0.05), p + Vector2(s * 0.82, -s * 0.05), p + Vector2(0, s * 0.85),
	]), col)


func _bow(p: Vector2, s: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		p, p + Vector2(-s, -s * 0.62), p + Vector2(-s, s * 0.62),
	]), Ui.MINT)
	draw_colored_polygon(PackedVector2Array([
		p, p + Vector2(s, -s * 0.62), p + Vector2(s, s * 0.62),
	]), Ui.ROSE)
	draw_circle(p, s * 0.27, Ui.PANEL)
	draw_circle(p - Vector2(s * 0.7, 0), s * 0.22, Ui.PANEL_SOFT)
	draw_circle(p + Vector2(s * 0.7, 0), s * 0.22, Ui.PANEL_SOFT)


func _star(p: Vector2, s: float, c: Color) -> void:
	var q: float = s * 0.22
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -s), p + Vector2(q, -q), p + Vector2(s, 0), p + Vector2(q, q),
		p + Vector2(0, s), p + Vector2(-q, q), p + Vector2(-s, 0), p + Vector2(-q, -q),
	]), c)
