extends Button
## 模式切换按钮：射击/三消互切，低球数时红光闪烁提示。

var _hint := false
var _t := 0.0


func _ready() -> void:
	position = Vector2(513, 18)
	size = Vector2(183, 63)
	add_theme_font_size_override("font_size", 26)
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
