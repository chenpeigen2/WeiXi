extends Node2D
## 编排层：装配 UI 组件、转发输入、同步游戏状态。规则全在 src/logic，绘制全在 src/ui。

const Game = preload("res://src/logic/game.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")
const Ui = preload("res://src/ui/theme.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")
const BoardView = preload("res://src/ui/board_view.gd")
const Shooter = preload("res://src/ui/shooter.gd")
const BallPicker = preload("res://src/ui/color_picker.gd")
const ScorePanel = preload("res://src/ui/score_panel.gd")
const ModeButton = preload("res://src/ui/mode_button.gd")
const RowSlider = preload("res://src/ui/row_slider.gd")
const Background = preload("res://src/ui/background.gd")
const FxLayer = preload("res://src/ui/fx_layer.gd")

const INVALID_CELL := Vector2i(-999, -999)

var game: RefCounted
var selected := INVALID_CELL

var board_view: Node2D
var shooter: Node2D
var picker: Node2D
var fx_layer: Node2D
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
	fx_layer = _make(FxLayer, "FxLayer")
	add_child(fx_layer)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	score_panel = _make(ScorePanel, "ScorePanel")
	hud.add_child(score_panel)
	mode_button = _make(ModeButton, "ModeButton")
	mode_button.pressed.connect(_on_mode_pressed)
	hud.add_child(mode_button)
	row_slider = _make(RowSlider, "RowSlider")
	row_slider.rows_dropped.connect(_on_rows_dropped)
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
	_update_preview()


# ---------- 输入路由 ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		shooter.set_aim(event.position - Ui.SHOOTER_POS)
		_update_preview()
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
	var tr := _trace_screen()
	if tr["cell"] == INVALID_CELL:
		return
	var cell: Vector2i = tr["cell"]
	var before: Dictionary = game.board.cells.duplicate()
	shooter.start_flight(tr["path"], game.current_color, func() -> void:
		var res: Dictionary = game.attach_ball(cell)
		_spawn_effects(res, before)
		selected = INVALID_CELL
		refresh()
	)


func _swap_at(pos: Vector2) -> void:
	var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, 1.0, _cam_origin()))
	if not game.board.has_ball(c):
		selected = INVALID_CELL
	elif selected == INVALID_CELL:
		selected = c
	elif c == selected:
		selected = INVALID_CELL
	else:
		var before: Dictionary = game.board.cells.duplicate()
		var res: Dictionary = game.try_swap(selected, c)
		if res["matched"]:
			_spawn_effects(res, before)
		selected = INVALID_CELL
	refresh()


func _spawn_effects(res: Dictionary, before: Dictionary) -> void:
	var o := _cam_origin()
	for c in res["popped"]:
		var pos := BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
		fx_layer.spawn_pop(pos, game.layout.radius, Ui.BALL_COLORS[before.get(c, 0)])
	for c in res["dropped"]:
		var pos := BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
		fx_layer.spawn_drop(pos, game.layout.radius, Ui.BALL_COLORS[before.get(c, 0)])
	_spawn_drop_effects(res.get("overflow", []), before)


func _spawn_drop_effects(cells: Array, before: Dictionary) -> void:
	var o := _cam_origin()
	for c in cells:
		var pos := BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
		fx_layer.spawn_drop(pos, game.layout.radius, Ui.BALL_COLORS[before.get(c, 0)])


# ---------- 弹道（预览与飞行共用同一条折线） ----------

func _trace_screen() -> Dictionary:
	var o := _cam_origin()
	var trace: Dictionary = Trajectory.trace_path(game.board, game.layout, BoardCamera.to_board(Ui.SHOOTER_POS, 1.0, o), shooter.aim_dir, game.board.width * game.layout.diameter)
	var pts := PackedVector2Array()
	pts.append(Ui.SHOOTER_POS)
	for p in trace["points"]:
		pts.append(BoardCamera.to_screen(p, 1.0, o))
	var target := Vector2.ZERO
	if trace["cell"] != INVALID_CELL:
		target = BoardCamera.to_screen(game.layout.cell_to_pixel(trace["cell"]), 1.0, o)
		pts.append(target)
	return {"cell": trace["cell"], "path": pts, "target": target}


func _update_preview() -> void:
	if game.mode != Game.Mode.SHOOT or shooter.is_flying():
		shooter.set_preview(PackedVector2Array(), Vector2.ZERO, 0)
		return
	var tr := _trace_screen()
	if tr["cell"] == INVALID_CELL:
		shooter.set_preview(PackedVector2Array(), Vector2.ZERO, 0)
		return
	var pts: PackedVector2Array = tr["path"]
	pts.remove_at(0) # 预览点流不含发射器中心
	shooter.set_preview(pts, tr["target"], game.current_color)


# ---------- HUD 回调 ----------

func _on_mode_pressed() -> void:
	game.toggle_mode()
	selected = INVALID_CELL
	refresh()


func _on_rows_dropped(n: int) -> void:
	var before: Dictionary = game.board.cells.duplicate()
	var dropped: Array = game.drop_bottom_rows(n)
	_spawn_drop_effects(dropped, before)
	refresh()


# ---------- 相机（球大小恒定，超高上滑） ----------

func _cam_origin() -> Vector2:
	return board_view.cam_origin()
