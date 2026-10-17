extends RefCounted
## 愿望池：同时只有一条，完成立刻换下一条；不会失败，不会有惩罚。

const Wish = preload("res://src/logic/wish.gd")
const KINDS := ["clear", "color", "big_clear", "combo", "drop_row", "bank", "recolor"]

var active: RefCounted
var completion_count := 0
var last_reward := 0
var rng: RandomNumberGenerator
var _last_kind := ""


func _init(p_rng: RandomNumberGenerator) -> void:
	rng = p_rng
	active = _make_wish()


func _make_wish() -> RefCounted:
	var kind: String = KINDS[rng.randi_range(0, KINDS.size() - 1)]
	if kind == _last_kind:
		kind = KINDS[(KINDS.find(kind) + 1) % KINDS.size()]
	_last_kind = kind
	match kind:
		"clear":
			return Wish.new("clear", 15)
		"color":
			return Wish.new("color", 12, rng.randi_range(0, 5))
		"big_clear":
			return Wish.new("big_clear", 6)
		"combo":
			return Wish.new("combo", 4)
		"drop_row":
			return Wish.new("drop_row", 1)
		"bank":
			return Wish.new("bank", 1)
		_:
			return Wish.new("recolor", 1)


## 返回 {} 表示未完成；完成时返回 {completed, reward, wish}。
func notify(event: String, data: Dictionary) -> Dictionary:
	if active == null:
		return {}
	if not active.apply(event, data):
		return {}
	var done: RefCounted = active
	completion_count += 1
	last_reward = int(done.reward_star)
	active = _make_wish()
	return {"completed": true, "reward": last_reward, "wish": done}
