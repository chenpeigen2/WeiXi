extends Node2D
## 编排层：装配 UI 组件、转发输入、同步游戏状态。规则全在 src/logic，绘制全在 src/ui。

const Game = preload("res://src/logic/game.gd")
const Ui = preload("res://src/ui/theme.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")
const BoardView = preload("res://src/ui/board_view.gd")
const Shooter = preload("res://src/ui/shooter.gd")
const BallPicker = preload("res://src/ui/color_picker.gd")
const ScorePanel = preload("res://src/ui/score_panel.gd")
const ModeButton = preload("res://src/ui/mode_button.gd")
const RowSlider = preload("res://src/ui/row_slider.gd")
const Background = preload("res://src/ui/background.gd")

const INVALID_CELL := Vector2i(-999, -999)

var game: RefCounted
var selected := INVALID_CELL

var board_view: Node2D
var shooter: Node2D
var picker: Node2D
var score_panel: Control
var mode_button: Button
var row_slider: Control


func _ready() -> void:
	game = Game.new(randi())

	add_child(_make(Background, "Background"))
	board_view = _make(BoardView, "BoardView")
	board_view.game = game
	add_child(board_view)
	shooter = _make(Shooter, "Shooter")
	shooter.game = game
	add_child(shooter)
	picker = _make(BallPicker, "ColorPicker")
	add_child(picker)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	score_panel = _make(ScorePanel, "ScorePanel")
	hud.add_child(score_panel)
	mode_button = _make(ModeButton, "ModeButton")
	mode_button.pressed.connect(_on_mode_pressed)
	hud.add_child(mode_button)
	row_slider = _make(RowSlider, "RowSlider")
	row_slider.rows_added.connect(_on_rows_added)
	hud.add_child(row_slider)

	refresh()


func _make(script: GDScript, node_name: String) -> Node:
	var node: Node = script.new()
	node.name = node_name
	return node


## 状态 → 组件 单向同步
func refresh() -> void:
	board_view.selected = selected
	board_view.queue_redraw()
	shooter.queue_redraw()
	picker.set_current(game.current_color)
	score_panel.set_score(game.scorer.score, game.scorer.combo)
	mode_button.set_shoot_mode(game.mode == Game.Mode.SHOOT)
	mode_button.set_hint(game.should_hint_match3())


# ---------- 输入路由 ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		shooter.set_aim(event.position - Ui.SHOOTER_POS)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(event.position)


func _on_click(pos: Vector2) -> void:
	# 作弊1：颜色选择条优先命中
	var i := BallPicker.hit(pos)
	if i >= 0:
		game.set_current_color(i)
		refresh()
		return
	if game.mode == Game.Mode.SHOOT:
		_fire()
	else:
		_swap_at(pos)


func _fire() -> void:
	if shooter.is_flying():
		return
	var s := _cam_scale()
	var o := _cam_origin(s)
	var cell: Vector2i = game.aim_attach(BoardCamera.to_board(Ui.SHOOTER_POS, s, o), shooter.aim_dir)
	if cell == INVALID_CELL:
		return
	var to_screen := BoardCamera.to_screen(game.layout.cell_to_pixel(cell), s, o)
	shooter.start_flight(Ui.SHOOTER_POS, to_screen, game.current_color, func() -> void:
		game.attach_ball(cell)
		selected = INVALID_CELL
		refresh()
	)


func _swap_at(pos: Vector2) -> void:
	var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, _cam_scale(), _cam_origin(_cam_scale())))
	if not game.board.has_ball(c):
		selected = INVALID_CELL
	elif selected == INVALID_CELL:
		selected = c
	elif c == selected:
		selected = INVALID_CELL
	else:
		game.try_swap(selected, c)
		selected = INVALID_CELL
	refresh()


# ---------- HUD 回调 ----------

func _on_mode_pressed() -> void:
	game.toggle_mode()
	selected = INVALID_CELL
	refresh()


func _on_rows_added(n: int) -> void:
	game.add_rows(n)
	refresh()


# ---------- 相机 ----------

func _cam_scale() -> float:
	return BoardCamera.scale_for(game.board.rows, game.layout.row_height, game.layout.diameter)


func _cam_origin(s: float) -> Vector2:
	return BoardCamera.origin_for(s, game.board.width * game.layout.diameter)
