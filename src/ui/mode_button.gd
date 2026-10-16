extends Button
## 模式切换按钮：金边胶囊样式，低球数时红光闪烁提示。

const Ui = preload("res://src/ui/theme.gd")

var _hint := false
var _t := 0.0


func _ready() -> void:
	position = Vector2(262, 10)
	size = Vector2(124, 40)
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Ui.TEXT_MAIN)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.07)
	normal.border_color = Ui.ACCENT
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(20)
	add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(1, 1, 1, 0.15)
	add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Ui.ACCENT.darkened(0.45)
	add_theme_stylebox_override("pressed", pressed)

	text = "三消模式"


func set_shoot_mode(is_shoot: bool) -> void:
	text = "三消模式" if is_shoot else "射击模式"


func set_hint(h: bool) -> void:
	_hint = h


func _process(delta: float) -> void:
	if _hint:
		_t += delta * 5.0
		modulate = Color.WHITE.lerp(Color(1, 0.45, 0.45), 0.5 + 0.5 * sin(_t))
	else:
		modulate = Color.WHITE
