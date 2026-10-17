extends RefCounted
## 计分、连击与星星能量。具体数值见 玩法.md 第二节。

const STAR_MAX := 100
const FEVER_SHOTS := 3

var score := 0
var combo := 1
var star := 0
var fever_shots := 0


## 一次有消除的结算：返回本次得分。
## Fever 倍率由调用方显式传入：只有 Fever 射击享受 x2；
## 互换/换色不消耗 Fever，也不翻倍。
func register_clear(popped: int, dropped: int, fever := false) -> int:
	var mult := 2 if fever else 1
	var gained := (popped * 10 + dropped * 20) * combo * mult
	score += gained
	combo += 1
	if not fever:
		add_star(mini(20, popped * 4) + dropped * 4)
	return gained


## 一次无消除的结算：连击清零。Fever 的消耗由 Game 按“发射”统一处理。
func register_miss() -> void:
	combo = 1


## 积累星星；满 100 进入 Fever（3 次消除，得分 x2）。
## Fever 期间不再积累，避免无限续杯。
func add_star(amount: int, allow_in_fever := false) -> void:
	if amount <= 0:
		return
	if fever_shots > 0 and not allow_in_fever:
		return
	star += amount
	if star >= STAR_MAX:
		star = 0
		fever_shots = FEVER_SHOTS


func is_fever() -> bool:
	return fever_shots > 0
