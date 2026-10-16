extends Node2D
## 表现层：只负责渲染与输入转发，全部规则在 src/logic/game.gd（已测）。

const Game = preload("res://src/logic/game.gd")

const COLORS: Array[Color] = [
	Color(0.90, 0.20, 0.25), # 红
	Color(0.95, 0.85, 0.20), # 黄
	Color(0.25, 0.50, 0.95), # 蓝
	Color(0.30, 0.80, 0.35), # 绿
	Color(0.65, 0.35, 0.85), # 紫
	Color(0.95, 0.55, 0.20), # 橙
]

const BOARD_AREA_H := 560.0 # 盘面可见高度（超出则整体缩放）
const BOARD_TOP := 30.0
const SHOOTER_POS := Vector2(240, 690)
const PICKER_Y := 750.0
const PICKER_X0 := 90.0
const PICKER_DX := 60.0
const FLY_TIME := 0.15
const INVALID_CELL := Vector2i(-999, -999)

var game: RefCounted
var aim_dir := Vector2.UP
var flying: Dictionary = {} # {from,to,pos,t,cell}
var selected := INVALID_CELL # 三消模式首个选中的格子
var hint_flash := 0.0

var score_label: Label
var mode_button: Button
var row_slider: VSlider


func _ready() -> void:
	game = Game.new(randi())
	_build_hud()
	queue_redraw()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(10, 8)
	score_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(score_label)

	mode_button = Button.new()
	mode_button.name = "ModeButton"
	mode_button.position = Vector2(350, 8)
	mode_button.pressed.connect(_on_mode_pressed)
	layer.add_child(mode_button)

	row_slider = VSlider.new()
	row_slider.name = "RowSlider"
	row_slider.min_value = 1
	row_slider.max_value = 5
	row_slider.step = 1
	row_slider.value = 1
	row_slider.position = Vector2(438, 100)
	row_slider.size = Vector2(32, 300)
	row_slider.drag_ended.connect(_on_rows_added)
	layer.add_child(row_slider)

	_update_hud()


# ---------- 坐标换算（盘面随高度整体缩放，保证全场可见） ----------

func _board_scale() -> float:
	var h: float = game.board.rows * game.layout.row_height + game.layout.diameter
	return min(1.0, BOARD_AREA_H / h)


func _board_origin() -> Vector2:
	var s := _board_scale()
	return Vector2(240.0 - 180.0 * s, BOARD_TOP)


func _to_screen(board_pos: Vector2) -> Vector2:
	return _board_origin() + board_pos * _board_scale()


func _to_board(screen_pos: Vector2) -> Vector2:
	return (screen_pos - _board_origin()) / _board_scale()


# ---------- 输入 ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_aim(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(event.position)


func _update_aim(mouse_pos: Vector2) -> void:
	var d: Vector2 = mouse_pos - SHOOTER_POS
	if d.length() < 1.0:
		return
	aim_dir = d.normalized()
	if aim_dir.y > -0.15: # 只允许向上发射
		aim_dir = Vector2(aim_dir.x, -0.15).normalized()
	queue_redraw()


func _on_click(pos: Vector2) -> void:
	# 作弊1：颜色选择条命中检测
	for i in range(COLORS.size()):
		if pos.distance_to(_picker_pos(i)) <= 20.0:
			game.set_current_color(i)
			_refresh()
			return
	if game.mode == Game.Mode.SHOOT:
		_on_shoot_click()
	else:
		_on_match3_click(pos)


func _on_shoot_click() -> void:
	if not flying.is_empty():
		return
	var cell: Vector2i = game.aim_attach(_to_board(SHOOTER_POS), aim_dir)
	if cell == INVALID_CELL:
		return
	flying = {
		"from": SHOOTER_POS,
		"to": _to_screen(game.layout.cell_to_pixel(cell)),
		"pos": SHOOTER_POS,
		"t": 0.0,
		"cell": cell,
	}


func _on_match3_click(pos: Vector2) -> void:
	var c: Vector2i = game.layout.pixel_to_cell(_to_board(pos))
	if not game.board.has_ball(c):
		selected = INVALID_CELL
	elif selected == INVALID_CELL:
		selected = c
	elif c == selected:
		selected = INVALID_CELL
	else:
		game.try_swap(selected, c)
		selected = INVALID_CELL
		_update_hud()
	queue_redraw()


# ---------- HUD 回调 ----------

func _on_mode_pressed() -> void:
	game.toggle_mode()
	selected = INVALID_CELL
	_refresh()


func _on_rows_added(_value_changed: bool) -> void:
	game.add_rows(int(row_slider.value))
	row_slider.value = 1
	_refresh()


func _update_hud() -> void:
	score_label.text = "分数: %d   连击: x%d" % [game.scorer.score, game.scorer.combo]
	mode_button.text = "切三消" if game.mode == Game.Mode.SHOOT else "切射击"


func _refresh() -> void:
	_update_hud()
	queue_redraw()


func _picker_pos(i: int) -> Vector2:
	return Vector2(PICKER_X0 + i * PICKER_DX, PICKER_Y)


# ---------- 帧更新 ----------

func _process(delta: float) -> void:
	# 低球数时三消按钮闪烁提示
	if game.should_hint_match3():
		hint_flash += delta * 5.0
		mode_button.modulate = Color.WHITE.lerp(Color(1, 0.4, 0.4), 0.5 + 0.5 * sin(hint_flash))
	else:
		mode_button.modulate = Color.WHITE

	if flying.is_empty():
		return
	flying["t"] += delta / FLY_TIME
	if flying["t"] >= 1.0:
		var cell: Vector2i = flying["cell"]
		flying = {}
		game.attach_ball(cell)
		_update_hud()
	else:
		flying["pos"] = flying["from"].lerp(flying["to"], flying["t"])
	queue_redraw()


# ---------- 绘制 ----------

func _draw() -> void:
	var s := _board_scale()
	var r: float = game.layout.radius * s

	# 棋盘上的球
	for cell in game.board.cells:
		draw_circle(_to_screen(game.layout.cell_to_pixel(cell)), r * 0.95, COLORS[game.board.get_color(cell)])

	# 三消选中高亮
	if selected != INVALID_CELL and game.board.has_ball(selected):
		draw_arc(_to_screen(game.layout.cell_to_pixel(selected)), r, 0, TAU, 32, Color.WHITE, 3.0)

	# 底线（不是死亡线，只是续行提示）
	var line_y := _to_screen(Vector2(0, (game.deadline_row + 1) * game.layout.row_height)).y
	draw_line(Vector2(20, line_y), Vector2(460, line_y), Color(1, 1, 1, 0.25), 2.0)

	# 瞄准虚线
	if game.mode == Game.Mode.SHOOT and flying.is_empty():
		draw_dashed_line(SHOOTER_POS, SHOOTER_POS + aim_dir * 120.0, Color(1, 1, 1, 0.5), 2.0, 8.0)

	# 发射器：当前球 + 下一球预告
	draw_circle(SHOOTER_POS, game.layout.radius, COLORS[game.current_color])
	draw_circle(SHOOTER_POS + Vector2(52, 12), game.layout.radius * 0.6, COLORS[game.next_color])

	# 飞行中的球
	if not flying.is_empty():
		draw_circle(flying["pos"], game.layout.radius, COLORS[game.current_color])

	# 作弊1：颜色选择条
	for i in range(COLORS.size()):
		var p := _picker_pos(i)
		draw_circle(p, 16.0, COLORS[i])
		if i == game.current_color:
			draw_arc(p, 21.0, 0, TAU, 32, Color.WHITE, 3.0)
