extends Control
## 计分面板：玻璃底 + 大分数 + 金色连击胶囊。

const Ui = preload("res://src/ui/theme.gd")

var text := ""

var _score_label: Label
var _combo_label: Label
var _panel: StyleBoxFlat
var _pill: StyleBoxFlat


func _ready() -> void:
	position = Vector2(14, 10)
	size = Vector2(240, 40)
	custom_minimum_size = size

	_panel = StyleBoxFlat.new()
	_panel.bg_color = Ui.PANEL
	_panel.border_color = Ui.PANEL_STROKE
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(10)

	_pill = StyleBoxFlat.new()
	_pill.bg_color = Ui.ACCENT
	_pill.set_corner_radius_all(12)

	_score_label = Label.new()
	_score_label.position = Vector2(12, 8)
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.add_theme_color_override("font_color", Ui.TEXT_MAIN)
	add_child(_score_label)

	_combo_label = Label.new()
	_combo_label.position = Vector2(160, 11)
	_combo_label.add_theme_font_size_override("font_size", 15)
	_combo_label.add_theme_color_override("font_color", Color(0.12, 0.10, 0.05))
	add_child(_combo_label)


func set_score(score: int, combo: int) -> void:
	text = "分数 %d" % score
	_score_label.text = text
	_combo_label.text = "连击 x%d" % combo
	queue_redraw()


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	draw_style_box(_pill, Rect2(Vector2(150, 8), Vector2(82, 25)))
