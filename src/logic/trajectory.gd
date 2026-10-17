extends RefCounted
## 弹道：从发射点沿方向步进，处理侧墙反弹与碰撞，求最终吸附格。纯逻辑。

const HexGrid = preload("res://src/logic/hex_grid.gd")

const MAX_STEPS := 20000


## 返回吸附格。from/dir 为像素坐标与方向，board_pixel_width 为盘面像素宽。
static func find_attach_cell(board, layout, from: Vector2, dir: Vector2, board_pixel_width: float) -> Vector2i:
	return _simulate(board, layout, from, dir, board_pixel_width, 0)["cell"]


## 弹道预览：返回 {"cell": 吸附格, "points": 路径采样点(最多 max_points 个 + 终点)}
static func trace_path(board, layout, from: Vector2, dir: Vector2, board_pixel_width: float, max_points := 40) -> Dictionary:
	return _simulate(board, layout, from, dir, board_pixel_width, max_points)


static func _simulate(board, layout, from: Vector2, dir: Vector2, board_pixel_width: float, max_points: int) -> Dictionary:
	var points := PackedVector2Array()
	var pos := from
	var vel: Vector2 = dir.normalized() * (layout.radius * 0.25)
	var cell := Vector2i(-999, -999)
	var bounces := 0
	for i in range(MAX_STEPS):
		pos += vel
		# 侧墙反弹（球心活动范围 [R, 宽-R]）
		if pos.x < layout.radius:
			pos.x = 2.0 * layout.radius - pos.x
			vel.x = -vel.x
			bounces += 1
		elif pos.x > board_pixel_width - layout.radius:
			pos.x = 2.0 * (board_pixel_width - layout.radius) - pos.x
			vel.x = -vel.x
			bounces += 1
		# 路径采样
		if max_points > 0 and i % 5 == 0 and points.size() < max_points:
			points.append(pos)
		# 碰顶：吸附到顶行最近空格
		if pos.y <= 0.0:
			cell = _nearest_empty_in_row(board, layout, pos, 0)
			break
		# 碰球：吸附到该球最近的空邻格
		var near: Vector2i = layout.pixel_to_cell(pos)
		var candidates: Array[Vector2i] = [near]
		candidates.append_array(HexGrid.neighbors(near))
		var hit := false
		for c in candidates:
			if board.has_ball(c) and layout.cell_to_pixel(c).distance_to(pos) < layout.diameter * 0.85:
				cell = _nearest_empty_neighbor(board, layout, c, pos)
				hit = true
				break
		if hit:
			break
	if max_points > 0:
		points.append(pos)
	return {"cell": cell, "points": points, "bounces": bounces}


static func _nearest_empty_in_row(board, layout, pos: Vector2, r: int) -> Vector2i:
	var best := Vector2i(-999, -999)
	var best_dist := INF
	var q0: int = HexGrid.q_min(r)
	for col in range(board.width):
		var cell := Vector2i(q0 + col, r)
		if board.has_ball(cell):
			continue
		var d: float = layout.cell_to_pixel(cell).distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = cell
	return best


static func _nearest_empty_neighbor(board, layout, around: Vector2i, pos: Vector2) -> Vector2i:
	# 第一圈，找不到再扩到第二圈（被围死的极端情况）
	for ring in [1, 2]:
		var best := Vector2i(-999, -999)
		var best_dist := INF
		var frontier: Array[Vector2i] = [around]
		for i in range(ring):
			var next: Array[Vector2i] = []
			for c in frontier:
				for n in HexGrid.neighbors(c):
					next.append(n)
			frontier = next
		for c in frontier:
			if not board.is_valid_cell(c) or board.has_ball(c):
				continue
			var d: float = layout.cell_to_pixel(c).distance_to(pos)
			if d < best_dist:
				best_dist = d
				best = c
		if best != Vector2i(-999, -999):
			return best
	return Vector2i(-999, -999)
