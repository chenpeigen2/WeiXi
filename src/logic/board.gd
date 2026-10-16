extends RefCounted
## 棋盘：六边形错排网格上的球状态与消除规则。纯逻辑，不依赖场景树。

const HexGrid = preload("res://src/logic/hex_grid.gd")

## 触底自动续行的单次幅度
const EXTEND_CHUNK := 3

var width: int
var rows: int
var cells: Dictionary = {} # Vector2i -> int(颜色)


func _init(p_width := 10, p_rows := 12) -> void:
	width = p_width
	rows = p_rows


func is_valid_cell(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= rows:
		return false
	var q0: int = HexGrid.q_min(cell.y)
	return cell.x >= q0 and cell.x < q0 + width


func set_ball(cell: Vector2i, color: int) -> void:
	cells[cell] = color


func has_ball(cell: Vector2i) -> bool:
	return cells.has(cell)


func get_color(cell: Vector2i) -> int:
	return cells.get(cell, -1)


func remove_ball(cell: Vector2i) -> void:
	cells.erase(cell)


func ball_count() -> int:
	return cells.size()


func is_empty() -> bool:
	return cells.is_empty()


## 在顶部 n_rows 行随机补球（清空后自动续局）
func refill_top(n_rows: int, rng: RandomNumberGenerator, color_count := 6) -> void:
	for r in range(n_rows):
		var q0: int = HexGrid.q_min(r)
		for col in range(width):
			cells[Vector2i(q0 + col, r)] = rng.randi_range(0, color_count - 1)


## 底部增加 n 行空位（永不超线：底线随盘面向下推移）
func extend_rows(n: int) -> void:
	rows += n


func lowest_occupied_row() -> int:
	var lowest := -1
	for c in cells:
		if c.y > lowest:
			lowest = c.y
	return lowest


## 保证最低球不碰到 deadline_row：不足就按 EXTEND_CHUNK 续行，返回续的行数
func ensure_space(deadline_row: int) -> int:
	var added := 0
	while lowest_occupied_row() >= deadline_row + added:
		added += EXTEND_CHUNK
	rows += added
	return added


## 从 start 出发的相连同色球（含自身）
func cluster(start: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not has_ball(start):
		return out
	var color: int = cells[start]
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		out.append(c)
		for n in HexGrid.neighbors(c):
			if not seen.has(n) and cells.get(n, -1) == color:
				seen[n] = true
				stack.append(n)
	return out


## 穿过 cell 沿 dir 轴向的同色连线（含自身）
func line_through(cell: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var color: int = cells.get(cell, -1)
	if color == -1:
		return out
	out.append(cell)
	for s in [1, -1]:
		var c: Vector2i = cell + dir * s
		while cells.get(c, -1) == color:
			out.append(c)
			c += dir * s
	return out


## 三消模式：互换两个相邻球。若互换后穿过两球的任一三轴连线 >=3 则消除，
## 并结算悬空掉落；否则自动换回。
## 返回 {"matched": bool, "popped": Array[Vector2i], "dropped": Array[Vector2i]}
func swap(a: Vector2i, b: Vector2i) -> Dictionary:
	var result: Dictionary = {"matched": false, "popped": [], "dropped": []}
	if not has_ball(a) or not has_ball(b):
		return result
	if not HexGrid.neighbors(a).has(b):
		return result
	var tmp: int = cells[a]
	cells[a] = cells[b]
	cells[b] = tmp
	var matched := {}
	for cell in [a, b]:
		for d in HexGrid.LINE_DIRS:
			var line := line_through(cell, d)
			if line.size() >= 3:
				for c in line:
					matched[c] = true
	if matched.is_empty():
		tmp = cells[a]
		cells[a] = cells[b]
		cells[b] = tmp
		return result
	result["matched"] = true
	var popped: Array[Vector2i] = []
	for c in matched.keys():
		remove_ball(c)
		popped.append(c)
	result["popped"] = popped
	var fl := floating()
	for c in fl:
		remove_ball(c)
	result["dropped"] = fl
	return result


## 与顶行(r=0)失去连接的所有球
func floating() -> Array[Vector2i]:
	var seen := {}
	var stack: Array[Vector2i] = []
	for c in cells:
		if c.y == 0:
			seen[c] = true
			stack.append(c)
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for n in HexGrid.neighbors(c):
			if cells.has(n) and not seen.has(n):
				seen[n] = true
				stack.append(n)
	var out: Array[Vector2i] = []
	for c in cells:
		if not seen.has(c):
			out.append(c)
	return out


## 新球吸附到 cell 后结算：相连同色 >=3 消除，失去支撑的悬空球掉落。
## 返回 {"popped": Array[Vector2i], "dropped": Array[Vector2i]}
func resolve_at(cell: Vector2i) -> Dictionary:
	var result: Dictionary = {"popped": [], "dropped": []}
	var cl := cluster(cell)
	if cl.size() >= 3:
		for c in cl:
			remove_ball(c)
		result["popped"] = cl
		var fl := floating()
		for c in fl:
			remove_ball(c)
		result["dropped"] = fl
	return result
