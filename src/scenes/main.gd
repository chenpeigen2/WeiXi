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
const Background = preload("res://src/ui/background.gd")
const FxLayer = preload("res://src/ui/fx_layer.gd")
const BallColorPopup = preload("res://src/ui/ball_color_popup.gd")
const DeadlineView = preload("res://src/ui/deadline_view.gd")
const MetaBar = preload("res://src/ui/meta_bar.gd")
const StickerAlbum = preload("res://src/ui/sticker_album.gd")
const StickerBook = preload("res://src/logic/sticker_book.gd")
const DailySeed = preload("res://src/logic/daily_seed.gd")

const INVALID_CELL := Vector2i(-999, -999)
const DRAG_THRESHOLD := 8.0

var game: RefCounted
var selected := INVALID_CELL

var board_view: Node2D
var deadline_view: Node2D
var shooter: Node2D
var picker: Node2D
var fx_layer: Node2D
var color_popup: Node2D
var score_panel: Control
var hint_label: Label
var meta_bar: Control
var album: Control
var sticker_book: RefCounted
var daily_mode := false

var _press := {} # {pos,dragging}
var _coach_step := 0
var _last_wish_completion := 0


func _ready() -> void:
	sticker_book = StickerBook.new()
	game = Game.new(randi())

	add_child(_make(Background, "Background"))
	board_view = _make(BoardView, "BoardView")
	board_view.game = game
	add_child(board_view)
	deadline_view = _make(DeadlineView, "DeadlineView")
	deadline_view.game = game
	add_child(deadline_view)
	shooter = _make(Shooter, "Shooter")
	shooter.game = game
	add_child(shooter)
	picker = _make(BallPicker, "ColorPicker")
	add_child(picker)
	fx_layer = _make(FxLayer, "FxLayer")
	add_child(fx_layer)
	color_popup = _make(BallColorPopup, "ColorPopup")
	add_child(color_popup)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	score_panel = _make(ScorePanel, "ScorePanel")
	hud.add_child(score_panel)
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "拖动瞄准 · 松手发射"
	hint_label.position = Vector2(Ui.HINT_X, Ui.HINT_Y)
	hint_label.size = Vector2(Ui.HINT_W, Ui.HINT_H)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_label.add_theme_color_override("font_color", Ui.ACCENT)
	hud.add_child(hint_label)

	meta_bar = MetaBar.new()
	meta_bar.name = "MetaBar"
	meta_bar.set_state(false, sticker_book.count())
	meta_bar.daily_pressed.connect(_on_daily)
	meta_bar.random_pressed.connect(_on_random)
	meta_bar.stickers_pressed.connect(_on_stickers)
	hud.add_child(meta_bar)

	album = StickerAlbum.new()
	album.name = "StickerAlbum"
	hud.add_child(album)

	refresh()


func _make(script: GDScript, node_name: String) -> Node:
	var node: Node = script.new()
	node.name = node_name
	return node


## 状态 → 组件 单向同步
func refresh() -> void:
	board_view.selected = selected
	board_view.queue_redraw()
	deadline_view.origin = board_view.cam_origin()
	deadline_view.queue_redraw()
	shooter.queue_redraw()
	picker.set_current(game.current_color)
	score_panel.set_score(game.scorer.score, game.scorer.combo, game.scorer.fever_charges)

	if game.wishes.completion_count != _last_wish_completion:
		var gained: int = game.wishes.completion_count - _last_wish_completion
		_last_wish_completion = game.wishes.completion_count
		var stickers := 0
		for k in range(maxi(0, gained)):
			if sticker_book.unlock_next() >= 0:
				stickers += 1
		meta_bar.set_state(daily_mode, sticker_book.count())
		if stickers > 0:
			fx_layer.spawn_text(
				Vector2(Ui.SCREEN_W * 0.5, 560.0),
				"愿望达成！贴纸 +%d" % stickers, 28, Ui.ACCENT
			)
		else:
			fx_layer.spawn_text(
				Vector2(Ui.SCREEN_W * 0.5, 560.0),
				"愿望达成！+%d" % game.wishes.last_reward, 28, Ui.ACCENT
			)
		if album.visible:
			album.queue_redraw()

	if color_popup.active:
		hint_label.text = "给这颗球选个颜色"
		hint_label.visible = true
	elif _coach_step < 3:
		hint_label.text = _coach_text()
		hint_label.visible = true
	elif game.should_hint_match3():
		hint_label.text = "点两个相邻球互换!"
		hint_label.visible = true
	elif game.wishes.active != null:
		hint_label.text = game.wishes.active.hud_text()
		hint_label.visible = true
	else:
		hint_label.visible = false

	_update_preview()


## 首轮三步提示：发射 → 互换 → 双击换色。玩家做过就进入下一步。
func _coach_text() -> String:
	match _coach_step:
		0:
			return "拖动瞄准 · 松手发射"
		1:
			return "点两个相邻球可以互换"
		2:
			return "双击任意球可以换色"
		_:
			return ""


# ---------- 输入路由（点按/拖拽/长按） ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_cursor(event.position)
		if color_popup.active:
			color_popup.set_hover(event.position)
		else:
			picker.set_hover(event.position)
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
		hint_label.modulate = Color.WHITE.lerp(Color(1.0, 0.86, 0.92), 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0))


## 桌面 hover：可点元素显示手型光标，减少“这里能不能点”的猜测。
func _update_cursor(pos: Vector2) -> void:
	if shooter.is_flying() or fx_layer.is_swapping():
		board_view.set_hover(INVALID_CELL)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	var hand := false
	if color_popup.active:
		board_view.set_hover(INVALID_CELL)
		hand = color_popup.hit(pos) >= 0
	elif BallPicker.hit(pos) >= 0:
		board_view.set_hover(INVALID_CELL)
		hand = true
	else:
		var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, 1.0, _cam_origin()))
		hand = game.board.has_ball(c)
		board_view.set_hover(c if hand else INVALID_CELL)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hand else Input.CURSOR_ARROW)


## 作弊1：双击棋盘上已射出的球 → 弹出调色板选任意颜色
var _popup_cell := INVALID_CELL


func _try_cycle_board_ball(pos: Vector2) -> void:
	if shooter.is_flying() or fx_layer.is_swapping():
		return
	var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, 1.0, _cam_origin()))
	if not game.board.has_ball(c):
		return
	selected = c # 框选目标球，明确正在改哪颗
	_popup_cell = c
	color_popup.current_color = game.board.get_color(c)
	color_popup.open_at(pos)
	refresh()


func _apply_popup_tap(pos: Vector2) -> void:
	var i: int = color_popup.hit(pos)
	color_popup.close()
	if i < 0:
		selected = INVALID_CELL
		_popup_cell = INVALID_CELL
		refresh()
		return # 点外取消
	var before: Dictionary = game.board.cells.duplicate()
	var res: Dictionary = game.set_ball_color(_popup_cell, i)
	selected = INVALID_CELL
	_popup_cell = INVALID_CELL
	if _coach_step < 3:
		_coach_step = 3
	if not res["popped"].is_empty():
		_spawn_effects(res, before)
	refresh()


func _on_daily() -> void:
	_start_new_game(DailySeed.today_seed(), true)


func _on_random() -> void:
	_start_new_game(randi(), false)


func _on_stickers() -> void:
	# 飞行/互换中不打开相册，避免盖住正在结算的球
	if shooter.is_flying() or fx_layer.is_swapping():
		return
	if color_popup.active:
		color_popup.close()
		selected = INVALID_CELL
		_popup_cell = INVALID_CELL
		refresh()
	album.open(sticker_book)


func _start_new_game(seed: int, is_daily: bool) -> void:
	daily_mode = is_daily
	game = Game.new(seed)
	board_view.game = game
	deadline_view.game = game
	shooter.game = game
	selected = INVALID_CELL
	_popup_cell = INVALID_CELL
	_press = {}
	_coach_step = 3
	_last_wish_completion = 0
	color_popup.close()
	picker.set_current(game.current_color)
	shooter.aim_dir = Vector2.UP
	shooter._flight = {}
	shooter.set_preview(PackedVector2Array(), Vector2.ZERO, game.current_color)
	board_view.clear_landings()
	board_view.set_hover(INVALID_CELL)
	board_view.hidden_cells = {}
	fx_layer.clear()
	meta_bar.set_state(daily_mode, sticker_book.count())
	refresh()


func _on_release(pos: Vector2) -> void:
	if _press.is_empty():
		return
	var p := _press
	_press = {}
	if color_popup.active:
		_apply_popup_tap(pos)
		return
	if p["dragging"]:
		shooter.set_aim(pos - Ui.SHOOTER_POS)
		_update_preview()
		_fire()
		return
	_on_tap(pos)


func _on_tap(pos: Vector2) -> void:
	# 调色板打开时优先：选色或点外取消
	if color_popup.active:
		_apply_popup_tap(pos)
		return
	# 飞行/互换期间锁输入，避免“飞的是旧色、落的是新色”
	if shooter.is_flying() or fx_layer.is_swapping():
		return
	# 作弊1：颜色选择条优先命中
	var i := BallPicker.hit(pos)
	if i >= 0:
		game.set_current_color(i)
		refresh()
		return
	var c: Vector2i = game.layout.pixel_to_cell(BoardCamera.to_board(pos, 1.0, _cam_origin()))
	if game.board.has_ball(c):
		_swap_select(c)
	else:
		_fire()


# ---------- 发射 ----------

func _fire() -> void:
	if shooter.is_flying() or fx_layer.is_swapping():
		return
	var tr := _trace_screen()
	if tr["cell"] == INVALID_CELL:
		return
	var cell: Vector2i = tr["cell"]
	selected = INVALID_CELL
	board_view.set_hover(INVALID_CELL)
	var before: Dictionary = game.board.cells.duplicate()
	var shot_color: int = game.current_color
	var bounces: int = int(tr.get("bounces", 0))
	shooter.start_flight(tr["path"], shot_color, func() -> void:
		var res: Dictionary = game.attach_ball(cell, shot_color, bounces)
		if game.board.has_ball(cell):
			var impact := Vector2.UP
			var path: PackedVector2Array = tr["path"]
			if path.size() >= 2:
				impact = (path[path.size() - 1] - path[path.size() - 2]).normalized()
			board_view.play_landing(cell, impact)
		_spawn_effects(res, before)
		refresh()
	)
	if _coach_step == 0:
		_coach_step = 1
		refresh()


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
		if not fx_layer.is_swapping():
			refresh()
		return
	refresh()


func _is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	return HexGrid.neighbors(a).has(b)


func _animated_swap(a: Vector2i, c: Vector2i) -> void:
	selected = INVALID_CELL
	var o := _cam_origin()
	var before: Dictionary = game.board.cells.duplicate()
	var res: Dictionary = game.try_swap(a, c)
	var after: Dictionary = game.board.cells.duplicate()
	if _coach_step < 2:
		_coach_step = 2
	var pos_a := BoardCamera.to_screen(game.layout.cell_to_pixel(a), 1.0, o)
	var pos_b := BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
	var color_a: Color = Ui.BALL_COLORS[before[a]]
	var color_b: Color = Ui.BALL_COLORS[before[c]]
	var r: float = game.layout.radius * 0.95
	board_view.selected = INVALID_CELL
	board_view.set_hover(INVALID_CELL)
	board_view.hidden_cells = {a: true, c: true}
	if res["matched"]:
		# 互换期间先保留完整 before 棋盘，等两球落位后再移除消除球，避免提前出现空洞。
		game.board.cells = before.duplicate()
		board_view.queue_redraw()
		fx_layer.play_swap(pos_a, pos_b, color_a, color_b, r, false, 0.32, func() -> void:
			game.board.cells = after
			board_view.hidden_cells = {}
			fx_layer.spawn_swap_burst(pos_a, pos_b, color_a, color_b)
			_spawn_effects(res, before)
			refresh()
		)
	else:
		board_view.queue_redraw()
		fx_layer.play_swap(pos_a, pos_b, color_a, color_b, r, true, 0.32, func() -> void:
			board_view.hidden_cells = {}
			fx_layer.spawn_invalid_puff((pos_a + pos_b) * 0.5)
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

	# +分浮字：本发有消除才出现。
	var gain: int = int(res.get("gain", 0))
	if gain > 0 and not res["popped"].is_empty():
		var center := Vector2.ZERO
		for c in res["popped"]:
			center += BoardCamera.to_screen(game.layout.cell_to_pixel(c), 1.0, o)
		center /= float(res["popped"].size())
		fx_layer.spawn_score_text(center, gain)
		var n: int = res["popped"].size()
		if n >= 4:
			var msg := "漂亮！" if n == 4 else ("太棒了！" if n == 5 else "好厉害！")
			var fs := 24 if n == 4 else (26 if n == 5 else 28)
			fx_layer.spawn_text(center - Vector2(0, 54), msg, fs, Ui.ACCENT)
			fx_layer.spawn_burst(center - Vector2(0, 54), Ui.ROSE, 3, 0.45, 1.0)
		if n >= 5:
			board_view.play_shake(1.8 + minf(1.4, float(n - 5) * 0.35))

	if res.get("star_burst", false):
		fx_layer.spawn_text(Vector2(Ui.SCREEN_W * 0.5, 540.0), "星星泡泡！", 28, Ui.ACCENT)
	elif res.get("rainbow", false):
		fx_layer.spawn_text(Vector2(Ui.SCREEN_W * 0.5, 540.0), "彩虹洗色！", 28, Ui.ACCENT)
	elif res.get("star_armed", false):
		fx_layer.spawn_text(Vector2(Ui.SCREEN_W * 0.5, 600.0), "星星球准备！", 24, Ui.ACCENT)

	# 反弹 / 掉行的可见回调；分数已经算进 res["gain"] / scorer。
	var bank_gain: int = int(res.get("bank_gain", 0))
	if bank_gain > 0:
		var bank_cell: Vector2i = res.get("cell", INVALID_CELL)
		if bank_cell != INVALID_CELL:
			var at := BoardCamera.to_screen(game.layout.cell_to_pixel(bank_cell), 1.0, o)
			fx_layer.spawn_text(at - Vector2(0, 52), "BANK!", 26, Ui.ACCENT)
	var overflow_star: int = int(res.get("overflow_star", 0))
	if overflow_star > 0:
		fx_layer.spawn_text(
			Vector2(Ui.SCREEN_W * 0.5, 952.0),
			"星尘 +%d" % overflow_star, 20, Ui.ACCENT
		)


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
	var bounce_pts := PackedVector2Array()
	for bp in trace.get("bounce_points", []):
		bounce_pts.append(BoardCamera.to_screen(bp, 1.0, o))
	return {
		"cell": trace["cell"], "path": pts, "target": target,
		"bounces": trace.get("bounces", 0), "bounce_points": bounce_pts,
	}


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
	shooter.set_preview(pts, tr["target"], game.current_color, tr["bounce_points"])


# ---------- HUD 回调 ----------


# ---------- 相机（球大小恒定，超高上滑） ----------

func _cam_origin() -> Vector2:
	return board_view.cam_origin()
