extends "res://tests/test_case.gd"

const FxLayer = preload("res://src/ui/fx_layer.gd")


func test_effects_expire_after_duration() -> void:
	var fx: Node2D = FxLayer.new()
	fx.spawn_pop(Vector2(100, 100), 20.0, Color.RED)
	fx.spawn_drop(Vector2(200, 200), 20.0, Color.BLUE)
	assert_eq(fx.effect_count(), 2, "两个特效存活")
	fx._process(0.6) # 超过最长寿命
	assert_eq(fx.effect_count(), 0, "超时全部消散")
	fx.free()


func test_drop_effect_falls_down() -> void:
	var fx: Node2D = FxLayer.new()
	fx.spawn_drop(Vector2(200, 200), 20.0, Color.BLUE)
	fx._process(0.1)
	var y_after: float = fx._effects[0]["pos"].y
	assert_true(y_after > 200.0, "掉落特效向下运动")
	fx.free()
