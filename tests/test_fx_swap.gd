extends "res://tests/test_case.gd"

const FxLayer = preload("res://src/ui/fx_layer.gd")

const A := Vector2(100, 100)
const B := Vector2(200, 200)


func test_swap_positions_non_revert() -> void:
	# 有效互换：A→B, B→A
	var at0: Array = FxLayer.swap_positions(A, B, 0.0, false)
	assert_vec_near(at0[0], A, "起点A")
	assert_vec_near(at0[1], B, "起点B")
	var at1: Array = FxLayer.swap_positions(A, B, 1.0, false)
	assert_vec_near(at1[0], B, "A滑到B")
	assert_vec_near(at1[1], A, "B滑到A")


func test_swap_positions_revert_goes_and_returns() -> void:
	# 无效互换：中点交换，终点归位
	var mid: Array = FxLayer.swap_positions(A, B, 0.5, true)
	assert_vec_near(mid[0], B, "中点A到B")
	assert_vec_near(mid[1], A, "中点B到A")
	var at1: Array = FxLayer.swap_positions(A, B, 1.0, true)
	assert_vec_near(at1[0], A, "终点A回原位")
	assert_vec_near(at1[1], B, "终点B回原位")


var _cb_called := false
func _on_cb() -> void:
	_cb_called = true


func test_play_swap_lifecycle() -> void:
	var fx: Node2D = FxLayer.new()
	_cb_called = false
	fx.play_swap(A, B, Color.RED, Color.BLUE, 20.0, false, 0.15, Callable(self, "_on_cb"))
	assert_true(fx.is_swapping(), "动画进行中")
	fx._process(0.20)
	assert_false(fx.is_swapping(), "动画已结束")
	assert_true(_cb_called, "结束回调触发")
	fx.free()


func test_swap_visuals_arc_scale_and_endpoints() -> void:
	var v0: Dictionary = FxLayer.swap_visuals(A, B, 0.0, false, 20.0)
	assert_vec_near(v0["a"], A, "视觉起点A")
	assert_vec_near(v0["b"], B, "视觉起点B")
	var v1: Dictionary = FxLayer.swap_visuals(A, B, 1.0, false, 20.0)
	assert_vec_near(v1["a"], B, "视觉终点A")
	assert_vec_near(v1["b"], A, "视觉终点B")
	assert_true(absf(float(v1["scale"]) - 1.0) < 0.001, "终点恢复原尺寸")

	var vm: Dictionary = FxLayer.swap_visuals(A, B, 0.5, false, 20.0)
	assert_true(float(vm["scale"]) > 1.0, "中点有挤压回弹")
	var perp := (B - A).normalized().orthogonal()
	var offset: float = absf((vm["a"] - (A + B) * 0.5).dot(perp))
	assert_true(offset > 4.0, "两球沿弧线绕开彼此")

	var vr: Dictionary = FxLayer.swap_visuals(A, B, 1.0, true, 20.0)
	assert_vec_near(vr["a"], A, "无效互换回原位")
	assert_vec_near(vr["b"], B, "无效互换回原位")

	# 水平互换：沿 x 拉伸、y 收窄，高光不旋转
	var vh: Dictionary = FxLayer.swap_visuals(Vector2(100, 100), Vector2(200, 100), 0.5, false, 20.0)
	assert_true(float(vh["sx"]) > float(vh["sy"]), "水平互换沿 x 拉伸")
