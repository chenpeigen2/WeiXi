extends RefCounted
## 测试基类：收集断言失败，由 tests/run_tests.gd 统一驱动。

var failures: Array[String] = []
var assert_count := 0


func assert_eq(actual: Variant, expected: Variant, msg := "") -> void:
	assert_count += 1
	if actual != expected:
		failures.append("assert_eq 失败: 期望 %s, 实际 %s. %s" % [str(expected), str(actual), msg])


func assert_ne(actual: Variant, expected: Variant, msg := "") -> void:
	assert_count += 1
	if actual == expected:
		failures.append("assert_ne 失败: 不应等于 %s. %s" % [str(expected), msg])


func assert_true(cond: Variant, msg := "") -> void:
	assert_count += 1
	if not cond:
		failures.append("assert_true 失败. %s" % msg)


func assert_false(cond: Variant, msg := "") -> void:
	assert_count += 1
	if cond:
		failures.append("assert_false 失败. %s" % msg)


func assert_has(arr: Array, item: Variant, msg := "") -> void:
	assert_count += 1
	if not arr.has(item):
		failures.append("assert_has 失败: %s 不在 %s 中. %s" % [str(item), str(arr), msg])


func assert_vec_near(actual: Vector2, expected: Vector2, msg := "") -> void:
	assert_count += 1
	if actual.distance_to(expected) > 0.001:
		failures.append("assert_vec_near 失败: 期望 %s, 实际 %s. %s" % [str(expected), str(actual), msg])
