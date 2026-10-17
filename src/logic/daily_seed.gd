extends RefCounted
## 每日挑战种子：同一天同一盘，跨天自动换盘。

static func for_date(year: int, month: int, day: int) -> int:
	return hash("weixi-daily-%04d-%02d-%02d" % [year, month, day])


static func today_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return for_date(int(d["year"]), int(d["month"]), int(d["day"]))
