extends RefCounted
## 六边形网格基础（轴坐标 axial coordinates）。
## 格子用 Vector2i(q, r) 表示，r=0 为顶行，向下递增。
## 视觉上是 odd-r 错排：奇数行相对偶数行缩进半格。

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), # E
	Vector2i(-1, 0), # W
	Vector2i(0, 1), # SE
	Vector2i(0, -1), # NW
	Vector2i(1, -1), # NE
	Vector2i(-1, 1), # SW
]

## 连线判定的三个轴向（直线 = 沿轴向正负两个方向延伸）
const LINE_DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, -1),
]


static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		out.append(cell + d)
	return out


## odd-r 错排换算：第 r 行 col=0 列对应的 q 值（col = q - q_min(r)）
static func q_min(r: int) -> int:
	return -((r - (r & 1)) >> 1)
