extends Control
## 计分面板：小标签 + 大数字 + 分状态的连击胶囊。
## 连击 ×1 用中性胶囊，×2 起才变金色，避免开局最抢眼的是“没有连击”。

const Ui = preload("res://src/ui/theme.gd")
const NumericFont = preload("res://fonts/Fredoka-Variable.ttf")

var text := ""

var _label_label: Label
var _value_label: Label
var _combo_label: Label
var _panel: StyleBoxFlat
var _pill: StyleBoxFlat
var _pill_rect := Rect2(Ui.COMBO_PILL_X, Ui.COMBO_PILL_Y, Ui.COMBO_PILL_W, Ui.COMBO_PILL_H)
var _last_combo := 1
var _last_fever := 0


func _ready() -> void:
	position = Vector2(Ui.SCORE_PANEL_X, Ui.SCORE_PANEL_Y)
	size = Vector2(Ui.SCORE_PANEL_W, Ui.SCORE_PANEL_H)
	custom_minimum_size = size

	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.MINT
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(int(Ui.PANEL_RADIUS))
	_panel.shadow_color = Color(0, 0, 0, 0.22)
	_panel.shadow_size = 10
	_panel.shadow_offset = Vector2(0, 4)

	_pill = StyleBoxFlat.new()
	_pill.bg_color = Ui.COMBO_IDLE_BG
	_pill.set_corner_radius_all(int(Ui.COMBO_PILL_H * 0.5))

	_label_label = Label.new()
	_label_label.name = "ScoreLabel"
	_label_label.text = "分数"
	_label_label.position = Vector2(64, 4)
	_label_label.add_theme_font_size_override("font_size", 14)
	_label_label.add_theme_color_override("font_color", Ui.TEXT_DIM)
	add_child(_label_label)

	_value_label = Label.new()
	_value_label.name = "ScoreValue"
	_value_label.position = Vector2(64, 20)
	_value_label.size = Vector2(Ui.SCORE_TEXT_MAX_X - 64.0, 40)
	_value_label.add_theme_font_override("font", NumericFont)
	_value_label.add_theme_font_size_override("font_size", 34)
	_value_label.add_theme_color_override("font_color", Ui.TEXT_MAIN)
	add_child(_value_label)

	_combo_label = Label.new()
	_combo_label.name = "ComboLabel"
	_combo_label.position = Vector2(Ui.COMBO_PILL_X + 15, Ui.COMBO_PILL_Y)
	_combo_label.size = Vector2(Ui.COMBO_PILL_W - 30, Ui.COMBO_PILL_H)
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 22)
	_combo_label.add_theme_color_override("font_color", Ui.COMBO_IDLE_TEXT)
	add_child(_combo_label)


func set_score(score: int, combo: int, fever := 0) -> void:
	var value := format_score(score)
	text = "分数 %s" % value
	if _value_label != null:
		_value_label.text = value
		var fs := 34
		if value.length() > 9:
			fs = 24
		elif value.length() > 6:
			fs = 28
		_value_label.add_theme_font_size_override("font_size", fs)
	if _combo_label != null:
		var fever_on := fever > 0
		var active := combo > 1 or fever_on
		_combo_label.text = "FEVER ×2" if fever_on else "连击 ×%d" % combo
		_combo_label.add_theme_color_override(
			"font_color",
			Color(0.16, 0.06, 0.10) if active else Ui.COMBO_IDLE_TEXT
		)
		_pill.bg_color = Ui.ACCENT if active else Ui.COMBO_IDLE_BG
		var min_w: float = _combo_label.get_minimum_size().x + 30.0
		var max_w: float = Ui.SCORE_PANEL_W - Ui.COMBO_PILL_X - 16.0
		var w: float = clampf(maxf(Ui.COMBO_PILL_W, min_w), Ui.COMBO_PILL_W, max_w)
		_pill_rect = Rect2(Ui.COMBO_PILL_X, Ui.COMBO_PILL_Y, w, Ui.COMBO_PILL_H)
		_combo_label.size = Vector2(w - 30.0, Ui.COMBO_PILL_H)
		if combo > _last_combo or fever > _last_fever:
			_pop_combo()
		_last_combo = combo
		_last_fever = fever
	queue_redraw()


## 连击升高时让胶囊里的字弹一下，给“连上了”一个手感。
func _pop_combo() -> void:
	if _combo_label == null:
		return
	_combo_label.pivot_offset = _combo_label.size * 0.5
	_combo_label.scale = Vector2(1.14, 1.14)
	var tw := create_tween()
	tw.tween_property(_combo_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 分数格式：千分位，配合 Fredoka 圆润数字；超长时由字号收缩，不再塞“万/亿”方块。
static func format_score(score: int) -> String:
	return _group(maxi(0, score))


static func _group(n: int) -> String:
	var raw := str(n)
	var out := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = raw[i] + out
		count += 1
	return out


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	draw_line(Vector2(20.0, 0.5), Vector2(size.x - 20.0, 0.5), Color(0.62, 0.88, 0.74, 0.65), 1.0)
	draw_style_box(_pill, _pill_rect)
	_draw_bunny()


## HUD 左侧的小兔兔：计分伙伴，同时也是“这是分数区”的可爱标记。
func _draw_bunny() -> void:
	var c := Vector2(42.0, 39.0)
	# 长耳朵
	for sx in [-1.0, 1.0]:
		var ear_x: float = c.x + sx * 8.0
		var tip := Vector2(ear_x - sx * 2.0, 10.0)
		draw_line(Vector2(ear_x, 28.0), tip, Ui.BUNNY, 8.0)
		draw_circle(Vector2(ear_x, 28.0), 4.0, Ui.BUNNY)
		draw_circle(tip, 4.0, Ui.BUNNY)
		draw_line(Vector2(ear_x, 27.0), tip + Vector2(0, 1.0), Ui.BUNNY_EAR, 3.2)
		draw_circle(tip + Vector2(0, 1.0), 1.6, Ui.BUNNY_EAR)
	# 头
	draw_circle(c, 15.0, Ui.BUNNY)
	draw_arc(c, 15.0, 0, TAU, 36, Ui.HEART, 1.4, true)
	# 眼睛/腮红/嘴
	var ink := Ui.FACE_INK
	draw_circle(c + Vector2(-5.0, 1.5), 1.6, ink)
	draw_circle(c + Vector2(5.0, 1.5), 1.6, ink)
	draw_circle(c + Vector2(-9.0, 6.0), 2.4, Ui.BLUSH)
	draw_circle(c + Vector2(9.0, 6.0), 2.4, Ui.BLUSH)
	draw_arc(c + Vector2(0, 4.0), 4.2, PI * 0.2, PI * 0.8, 16, ink, 1.2, true)
	# 薄荷蝴蝶结
	var bow := c + Vector2(12.0, -10.0)
	draw_colored_polygon(PackedVector2Array([
		bow, bow + Vector2(-8, -4), bow + Vector2(-8, 5),
	]), Ui.MINT)
	draw_colored_polygon(PackedVector2Array([
		bow, bow + Vector2(8, -4), bow + Vector2(8, 5),
	]), Ui.MINT)
	draw_circle(bow, 2.1, Ui.PANEL_SOFT)
