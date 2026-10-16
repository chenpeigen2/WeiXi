extends Control
## 作弊2·加行滑杆：竖向拖动 1~5 行，松手生效并自动复位。

const Ui = preload("res://src/ui/theme.gd")

signal rows_added(n: int)

var slider: VSlider


func _ready() -> void:
	position = Vector2(640, 195)
	size = Vector2(66, 450)

	var label := Label.new()
	label.text = "加行"
	label.position = Vector2(6, -42)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Ui.TEXT_DIM)
	add_child(label)

	slider = VSlider.new()
	slider.min_value = 1
	slider.max_value = 5
	slider.step = 1
	slider.value = 1
	slider.size = Vector2(48, 450)
	slider.drag_ended.connect(_on_drag_ended)
	add_child(slider)


func _on_drag_ended(_value_changed: bool) -> void:
	rows_added.emit(int(slider.value))
	slider.value = 1 # 自动复位
