extends Node2D
## 编排层：装配 UI 组件、转发输入、同步游戏状态。规则全在 src/logic，绘制全在 src/ui。
## 融合操作（无模式）：点球=三消互换，点空位/拖拽=发射，长按当前球=循环换色。

const Game = preload("res://src/logic/game.gd")
const Trajectory = preload("res://src/logic/trajectory.gd")
const HexGrid = preload("res://src/logic/hex_grid.gd")
const Ui = preload("res://src/ui/theme.gd")
const BoardCamera = preload("res://src/ui/board_camera.gd")
const BoardView = preload("res://src/ui/board_view.gd")
const Shooter = preload("res://src/ui/shooter.gd")
const BallPicker = preload("res://src/ui/color_picker.gd")
const ScorePanel = preload("res://src/ui/score_panel.gd")
const RowSlider = preload("res://src/ui/row_slider.gd")
const Background = preload("res://src/ui/background.gd")
const FxLayer = preload("res://src/ui/fx_layer.gd")

const INVALID_CELL := Vector2i(-999, -999)
const DRAG_THRESHOLD := 8.0

var game: RefCounted
var selected := INVALID_CELL

var board_view: Node2D
var shooter: Node2D
var picker: Node2D
var fx_layer: Node2D
var score_panel: Control
var hint_label: Label
var row_slider: Control

var _press := {} # {pos,dragging}


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
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "点两个相邻球互换!"
	hint_label.position = Vector2(505, 30)
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_label.add_theme_color_override("font_color", Ui.ACCENT)
	hud.add_child(hint_label)
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
	hint_label.visible = game.should_hint_match3()
	_update_preview()


# ---------- 输入路由（点按/拖拽/长按） ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		shooter.set_aim(event.position - Ui.SHOOTER_POS)
		_update_preview()
		if not _press.is_empty() and event.position.distance_to(_press["pos"]) > DRAG_THRESHOLD:
			_press["dragging"] = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				_try_cycle_board_ball(event.position)
			else:
				_press = {"pos": event.position, "dragging": false}
		else:
			_on_release(event.position)


func _process(_delta: float) -> void:
	# 提示闪烁
	if hint_label.visible:
		hint_label.modulate = Color.WHITE.lerp(Color(1, 0.6, 0.4), 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0))


## 作弊1：双击棋盘上已射出的球 → 该球颜色循环+1（凑三连即消）
func _try_cycle_board_ball(pos: Vector2) -> void:
	if fx_layer.is_swapping():
		return
	var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, 1.0, _cam_origin()))
	if not game.board.has_ball(c):
		return
	var before: Dictionary = game.board.cells.duplicate()
	var res: Dictionary = game.cycle_ball_color(c)
	selected = INVALID_CELL
	if not res["popped"].is_empty():
		_spawn_effects(res, before)
	refresh()


func _on_release(pos: Vector2) -> void:
	if _press.is_empty():
		return
	var p := _press
	_press = {}
	if p["dragging"]:
		shooter.set_aim(pos - Ui.SHOOTER_POS)
		_update_preview()
		_fire()
		return
	_on_tap(pos)


func _on_tap(pos: Vector2) -> void:
	# 作弊1：颜色选择条优先命中
	var i := BallPicker.hit(pos)
	if i >= 0:
		game.set_current_color(i)
		refresh()
		return
	if fx_layer.is_swapping():
		return
	var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, 1.0, _cam_origin()))
	if game.board.has_ball(c):
		_swap_select(c)
	else:
		_fire()


# ---------- 发射 ----------

func _fire() -> void:
	if shooter.is_flying():
		return
	var tr := _trace_screen()
	if tr["cell"] == INVALID_CELL:
		return
	var cell: Vector2i = tr["cell"]
	selected = INVALID_CELL
	var before: Dictionary = game.board.cells.duplicate()
	shooter.start_flight(tr["path"], game.current_color, func() -> void:
		var res: Dictionary = game.attach_ball(cell)
		_spawn_effects(res, before)
		refresh()
	)


# ---------- 三消互换 ----------

func _swap_select(c: Vector2i) -> void:
	if selected == INVALID_CELL:
		selected = c
	elif c == selected:
		selected = INVALID_CELL
	elif not _is_neighbor(selected, c):
		selected = c # 点非相邻球 = 改选
	else:
		_animated_swap(selected, c)
	refresh()


func _is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	return HexGrid.neighbors(a).has(b)


func _animated_swap(a: Vector2i, c: Vector2i) -> void:
	selected = INVALID_CELL
	var o := _cam_origin()
	var before: Dictionary = game.board.cells.duplicate()
	var res: Dictionary = game.try_swap(a, c)
	var pos_a := BoardCamera.to_screen(game.layout.cell_to_pixel(a), 1.0, o)
	var pos_b := BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
	var color_a: Color = Ui.BALL_COLORS[before[a]]
	var color_b: Color = Ui.BALL_COLORS[before[c]]
	var r: float = game.layout.radius * 0.95
	board_view.hidden_cells = {a: true, c: true}
	if res["matched"]:
		fx_layer.play_swap(pos_a, pos_b, color_a, color_b, r, false, 0.16, func() -> void:
			board_view.hidden_cells = {}
			_spawn_effects(res, before)
			refresh()
		)
	else:
		fx_layer.play_swap(pos_a, pos_b, color_a, color_b, r, true, 0.28, func() -> void:
			board_view.hidden_cells = {}
			refresh()
		)


# ---------- 特效 ----------

func _spawn_effects(res: Dictionary, before: Dictionary) -> void:
	var o := _cam_origin()
	for c in res["popped"]:
		var pos := BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
		fx_layer.spawn_pop(pos, game.layout.radius, Ui.BALL_COLORS[before.get(c, 0)])
	_spawn_drop_effects(res["dropped"], before)
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
	if shooter.is_flying():
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

func _on_rows_dropped(n: int) -> void:
	var before: Dictionary = game.board.cells.duplicate()
	var dropped: Array = game.drop_bottom_rows(n)
	_spawn_drop_effects(dropped, before)
	refresh()


# ---------- 相机（球大小恒定，超高上滑） ----------

func _cam_origin() -> Vector2:
	return board_view.cam_origin()
