extends RefCounted
## 计分、连击与星星能量。具体数值见 玩法.md 第二节。

const STAR_MAX := 100
const FEVER_CHARGES := 3

var score := 0
var combo := 1
var star := 0
var fever_charges := 0


## 一次有消除的结算：返回本次得分。
## Fever 持续 3 次消除，任何操作造成的消除都享受 x2 并消耗一层。
func register_clear(popped: int, dropped: int) -> int:
	var fever_active := fever_charges > 0
	var mult := 2 if fever_active else 1
	var gained := (popped * 10 + dropped * 20) * combo * mult
	score += gained
	combo += 1
	if fever_active:
		fever_charges -= 1
	else:
		add_star(mini(20, popped * 4) + dropped * 4)
	return gained


## 一次无消除的结算：连击清零；空枪不消耗 Fever。
func register_miss() -> void:
	combo = 1


## 积累星星；满 100 进入 Fever（3 次消除，得分 x2）。
## Fever 期间不再积累，避免无限续杯。
func add_star(amount: int, allow_in_fever := false) -> void:
	if amount <= 0:
		return
	if fever_charges > 0 and not allow_in_fever:
		return
	star += amount
	if star >= STAR_MAX:
		star = 0
		fever_charges = FEVER_CHARGES


func is_fever() -> bool:
	return fever_charges > 0
