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
