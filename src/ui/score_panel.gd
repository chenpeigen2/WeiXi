extends Control
## 计分面板：玻璃底 + 分数 + 连击倍率。

const Ui = preload("res://src/ui/theme.gd")

var text := ""

var _score_label: Label
var _combo_label: Label
var _panel: StyleBoxFlat


func _ready() -> void:
	position = Vector2(24, 18)
	size = Vector2(420, 63)
	custom_minimum_size = size

	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.PANEL_STROKE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(12)

	_score_label = Label.new()
	_score_label.position = Vector2(21, 13)
	_score_label.add_theme_font_size_override("font_size", 30)
	_score_label.add_theme_color_override("font_color", Ui.TEXT_MAIN)
	add_child(_score_label)

	_combo_label = Label.new()
	_combo_label.position = Vector2(255, 17)
	_combo_label.add_theme_font_size_override("font_size", 25)
	_combo_label.add_theme_color_override("font_color", Ui.ACCENT)
	add_child(_combo_label)


func set_score(score: int, combo: int) -> void:
	text = "分数 %d" % score
	_score_label.text = text
	_combo_label.text = "连击 x%d" % combo


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
