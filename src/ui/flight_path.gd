extends RefCounted
## 飞球路径：折线长度与按距离采样。纯数学。


static func length(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


## 沿折线走 dist 距离后的位置；负距离取起点，超程取终点
static func sample(path: PackedVector2Array, dist: float) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	if dist <= 0.0:
		return path[0]
	var acc := 0.0
	for i in range(1, path.size()):
		var seg: float = path[i - 1].distance_to(path[i])
		if acc + seg >= dist:
			var t := (dist - acc) / seg if seg > 0.0 else 0.0
			return path[i - 1].lerp(path[i], t)
		acc += seg
	return path[path.size() - 1]
