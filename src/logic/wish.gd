extends RefCounted
## 一条无失败的愿望：只累计、不惩罚。完成由 WishSystem 负责换下一条。

const COLOR_NAMES := ["草莓", "柠檬", "天空", "薄荷", "薰衣草", "蜜桃"]

var kind: String
var target: int
var color: int
var progress := 0
var reward_star := 25


func _init(p_kind: String, p_target: int, p_color := -1, p_reward := 25) -> void:
	kind = p_kind
	target = p_target
	color = p_color
	reward_star = p_reward


## 应用一个游戏事件；返回是否刚好完成。
func apply(event: String, data: Dictionary) -> bool:
	if is_done():
		return false
	match kind:
		"clear":
			if event == "clear":
				progress += int(data.get("count", 0))
		"color":
			if event == "clear":
				var counts: Dictionary = data.get("colors", {})
				progress += int(counts.get(color, 0))
		"big_clear":
			if event == "clear" and int(data.get("count", 0)) >= target:
				progress = target
		"combo":
			if event == "clear":
				progress = maxi(progress, int(data.get("combo", 1)))
		"drop_row":
			if event == "drop_row":
				progress += 1
		"bank":
			if event == "bank":
				progress += 1
		"recolor":
			if event == "recolor":
				progress += 1
	progress = mini(progress, target)
	return is_done()


func is_done() -> bool:
	return progress >= target


## HUD 中间那一条愿望文字；尽量短，避免和分数/连击挤。
func hud_text() -> String:
	match kind:
		"clear":
			return "愿望 消球 %d/%d" % [progress, target]
		"color":
			return "愿望 %s %d/%d" % [COLOR_NAMES[color], progress, target]
		"big_clear":
			return "愿望 一次消 %d 颗" % target
		"combo":
			return "愿望 连击 %d/%d" % [progress, target]
		"drop_row":
			return "愿望 掉 1 行"
		"bank":
			return "愿望 反弹命中"
		"recolor":
			return "愿望 双击换色"
	return ""
