extends RefCounted
## 棋盘：六边形错排网格上的球状态与消除规则。纯逻辑，不依赖场景树。

const HexGrid = preload("res://src/logic/hex_grid.gd")

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


## 新球吸附到 cell 后结算：相连同色 >=3 消除。
## 返回 {"popped": Array[Vector2i], "dropped": Array[Vector2i]}
func resolve_at(cell: Vector2i) -> Dictionary:
	var result: Dictionary = {"popped": [], "dropped": []}
	var cl := cluster(cell)
	if cl.size() >= 3:
		for c in cl:
			remove_ball(c)
		result["popped"] = cl
	return result
