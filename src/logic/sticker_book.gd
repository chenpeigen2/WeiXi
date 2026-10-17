extends RefCounted
## 贴纸册：完成愿望解锁，本地持久化。纯数据，不依赖场景树。

const TOTAL := 12
const SAVE_PATH := "user://weixi_stickers.cfg"
const NAMES := [
	"草莓星", "薄荷兔", "柠檬心", "天空云",
	"薰衣草月", "蜜桃星", "彩虹", "小皇冠",
	"蝴蝶结", "泡泡", "四叶草", "猫猫",
]
const COLORS := [
	Color(1.00, 0.52, 0.62), Color(0.58, 0.92, 0.72),
	Color(1.00, 0.86, 0.48), Color(0.55, 0.78, 1.00),
	Color(0.80, 0.65, 1.00), Color(1.00, 0.68, 0.48),
	Color(0.80, 0.72, 1.00), Color(1.00, 0.78, 0.38),
	Color(1.00, 0.62, 0.78), Color(0.62, 0.84, 1.00),
	Color(0.62, 0.92, 0.66), Color(1.00, 0.78, 0.68),
]

var unlocked: Array[int] = []
var _path: String
var _persist := true


func _init(path := "") -> void:
	_path = SAVE_PATH if path.is_empty() else path
	# headless 测试不写用户目录；显式传 path 的测试仍会写临时文件。
	_persist = not path.is_empty() or DisplayServer.get_name() != "headless"
	if _persist:
		load_book()


func count() -> int:
	return unlocked.size()


func is_unlocked(index: int) -> bool:
	return unlocked.has(index)


## 解锁下一张；全收集返回 -1。
func unlock_next() -> int:
	for i in range(TOTAL):
		if not unlocked.has(i):
			unlocked.append(i)
			unlocked.sort()
			save()
			return i
	return -1


func save() -> void:
	if not _persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("stickers", "unlocked", unlocked)
	cfg.save(_path)


func load_book() -> void:
	unlocked.clear()
	var cfg := ConfigFile.new()
	if cfg.load(_path) != OK:
		return
	var saved = cfg.get_value("stickers", "unlocked", [])
	if saved is Array:
		for v in saved:
			var i := int(v)
			if i >= 0 and i < TOTAL and not unlocked.has(i):
				unlocked.append(i)
	unlocked.sort()
