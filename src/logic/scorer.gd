extends RefCounted
## 计分与连击。具体数值见 玩法.md 第二节。

var score := 0
var combo := 1


## 一次有消除的结算：返回本次得分。
## 得分 = (消除数*10 + 掉落数*20) * 当前连击倍率，之后连击+1。
func register_clear(popped: int, dropped: int) -> int:
	var gained := (popped * 10 + dropped * 20) * combo
	score += gained
	combo += 1
	return gained


## 一次无消除的结算：连击清零。
func register_miss() -> void:
	combo = 1
