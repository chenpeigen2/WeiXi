extends Control
## 计分面板：小标签 + 大数字 + 分状态的连击胶囊。
## 连击 ×1 用中性胶囊，×2 起才变金色，避免开局最抢眼的是“没有连击”。

const Ui = preload("res://src/ui/theme.gd")

var text := ""

var _label_label: Label
var _value_label: Label
var _combo_label: Label
var _panel: StyleBoxFlat
var _pill: StyleBoxFlat
var _pill_rect := Rect2(Ui.COMBO_PILL_X, Ui.COMBO_PILL_Y, Ui.COMBO_PILL_W, Ui.COMBO_PILL_H)


func _ready() -> void:
	position = Vector2(24, 12)
	size = Vector2(Ui.SCORE_PANEL_W, Ui.SCORE_PANEL_H)
	custom_minimum_size = size

	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.PANEL_STROKE
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
	_label_label.position = Vector2(20, 4)
	_label_label.add_theme_font_size_override("font_size", 14)
	_label_label.add_theme_color_override("font_color", Ui.TEXT_DIM)
	add_child(_label_label)

	_value_label = Label.new()
	_value_label.name = "ScoreValue"
	_value_label.position = Vector2(20, 20)
	_value_label.size = Vector2(Ui.SCORE_TEXT_MAX_X - 20.0, 40)
	var value_font := ThemeDB.fallback_font
	if value_font != null:
		_value_label.add_theme_font_override("font", value_font)
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


func set_score(score: int, combo: int) -> void:
	var value := format_score(score)
	text = "分数 %s" % value
	if _value_label != null:
		_value_label.text = value
	if _combo_label != null:
		var active := combo > 1
		_combo_label.text = "连击 ×%d" % combo
		_combo_label.add_theme_color_override(
			"font_color",
			Color(0.12, 0.10, 0.05) if active else Ui.COMBO_IDLE_TEXT
		)
		_pill.bg_color = Ui.ACCENT if active else Ui.COMBO_IDLE_BG
		var min_w: float = _combo_label.get_minimum_size().x + 30.0
		var max_w: float = Ui.SCORE_PANEL_W - Ui.COMBO_PILL_X - 16.0
		var w: float = clampf(maxf(Ui.COMBO_PILL_W, min_w), Ui.COMBO_PILL_W, max_w)
		_pill_rect = Rect2(Ui.COMBO_PILL_X, Ui.COMBO_PILL_Y, w, Ui.COMBO_PILL_H)
		_combo_label.size = Vector2(w - 30.0, Ui.COMBO_PILL_H)
	queue_redraw()


## 分数格式化：小分数用千分位，大分数压成 1.2万 / 1.2亿，避免撑爆面板。
static func format_score(score: int) -> String:
	var s: int = maxi(0, score)
	if s >= 100000000:
		return "%.1f亿" % (float(s) / 100000000.0)
	if s >= 100000:
		return "%.1f万" % (float(s) / 10000.0)
	return _group(s)


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
	draw_style_box(_pill, _pill_rect)
