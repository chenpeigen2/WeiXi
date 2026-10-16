extends Control
## 作弊2·加行滑杆：竖向拖动 1~5 行，松手生效并自动复位。金色滑块。

const Ui = preload("res://src/ui/theme.gd")

signal rows_added(n: int)

var slider: VSlider


func _ready() -> void:
	position = Vector2(356, 110)
	size = Vector2(40, 260)

	var label := Label.new()
	label.text = "加行"
	label.position = Vector2(2, -24)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Ui.TEXT_DIM)
	add_child(label)

	slider = VSlider.new()
	slider.min_value = 1
	slider.max_value = 5
	slider.step = 1
	slider.value = 1
	slider.size = Vector2(30, 260)

	var bar := StyleBoxFlat.new()
	bar.bg_color = Color(1, 1, 1, 0.10)
	bar.set_corner_radius_all(6)
	slider.add_theme_stylebox_override("slider", bar)

	var grab := StyleBoxFlat.new()
	grab.bg_color = Ui.ACCENT
	grab.set_corner_radius_all(7)
	slider.add_theme_stylebox_override("grabber_area", grab)
	slider.add_theme_stylebox_override("grabber_area_highlight", grab)

	slider.drag_ended.connect(_on_drag_ended)
	add_child(slider)


func _on_drag_ended(_value_changed: bool) -> void:
	rows_added.emit(int(slider.value))
	slider.value = 1 # 自动复位
