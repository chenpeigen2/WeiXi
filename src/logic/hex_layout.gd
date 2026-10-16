extends RefCounted
## 几何布局：格子 <-> 像素坐标换算（圆球紧密排列，奇数行缩进半格）。
## 纯数学，不依赖场景树。

const HexGrid = preload("res://src/logic/hex_grid.gd")

var radius: float # 球半径
var diameter: float
var row_height: float # sqrt(3) * R


func _init(p_radius: float) -> void:
	radius = p_radius
	diameter = p_radius * 2.0
	row_height = sqrt(3.0) * p_radius


func cell_to_pixel(cell: Vector2i) -> Vector2:
	var col: int = cell.x - HexGrid.q_min(cell.y)
	var x: float = (float(col) + 0.5 * float(cell.y & 1)) * diameter
	var y: float = float(cell.y) * row_height
	return Vector2(x, y)


func pixel_to_cell(p: Vector2) -> Vector2i:
	var r := int(round(p.y / row_height))
	var col := int(round(p.x / diameter - 0.5 * float(r & 1)))
	return Vector2i(HexGrid.q_min(r) + col, r)
