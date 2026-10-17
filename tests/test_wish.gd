extends "res://tests/test_case.gd"

const Wish = preload("res://src/logic/wish.gd")
const WishSystem = preload("res://src/logic/wish_system.gd")


func test_color_wish_accumulates_only_that_color() -> void:
	var w := Wish.new("color", 12, 3)
	assert_false(w.apply("clear", {"count": 8, "colors": {3: 5, 1: 3}, "combo": 2}), "还没满")
	assert_eq(w.progress, 5, "只累计薄荷色")
	assert_false(w.apply("clear", {"count": 3, "colors": {3: 3}, "combo": 3}))
	assert_true(w.apply("clear", {"count": 4, "colors": {3: 4}, "combo": 4}), "12 颗完成")
	assert_eq(w.progress, 12)
	assert_true(w.hud_text().begins_with("愿望 薄荷"))


func test_big_clear_is_single_shot() -> void:
	var w := Wish.new("big_clear", 6)
	assert_false(w.apply("clear", {"count": 5}))
	assert_true(w.apply("clear", {"count": 6}), "一次 6 颗完成")
	assert_eq(w.progress, 6)


func test_combo_wish_uses_best_combo() -> void:
	var w := Wish.new("combo", 4)
	assert_false(w.apply("clear", {"count": 3, "combo": 2}))
	assert_false(w.apply("clear", {"count": 3, "combo": 3}))
	assert_true(w.apply("clear", {"count": 3, "combo": 4}), "连击 4 完成")
	assert_eq(w.progress, 4)


func test_one_shot_wishes() -> void:
	for kind in ["drop_row", "bank", "recolor"]:
		var w := Wish.new(kind, 1)
		assert_false(w.apply("clear", {"count": 99, "combo": 99}), "别的事件不推进 %s" % kind)
		assert_true(w.apply(kind, {}), "%s 完成" % kind)


func test_wish_system_rotates_on_completion() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sys := WishSystem.new(rng)
	assert_true(sys.active != null, "开局有愿望")
	var first: RefCounted = sys.active
	var done := false
	for i in range(8):
		var r: Dictionary = sys.notify("clear", {
			"count": 99,
			"colors": {0: 99, 1: 99, 2: 99, 3: 99, 4: 99, 5: 99},
			"combo": 99,
		})
		if r.is_empty():
			r = sys.notify("drop_row", {})
		if r.is_empty():
			r = sys.notify("bank", {})
		if r.is_empty():
			r = sys.notify("recolor", {})
		if not r.is_empty():
			done = true
			assert_true(sys.completion_count >= 1, "计数增加")
			assert_eq(sys.last_reward, 25, "奖励星星")
			break
	assert_true(done, "任意愿望都能被对应事件完成")
	assert_ne(sys.active, first, "完成后换新愿望")
