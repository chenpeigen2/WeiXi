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
	var bounce_points := PackedVector2Array()
	for i in range(MAX_STEPS):
		pos += vel
		# 侧墙反弹：六边形球区物理范围是 [-R, W*D]。
		# 球心左边界是 0（球左沿 -R），右边界是 W*D-R（球右沿 W*D）。
		# 旧代码左右都用 R，导致左墙提前一个半径反弹。
		var left_bound := 0.0
		var right_bound: float = board_pixel_width - layout.radius
		if pos.x < left_bound:
			bounce_points.append(Vector2(left_bound, pos.y))
			pos.x = 2.0 * left_bound - pos.x
			vel.x = -vel.x
			bounces += 1
		elif pos.x > right_bound:
			bounce_points.append(Vector2(right_bound, pos.y))
			pos.x = 2.0 * right_bound - pos.x
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
		var hit_ball := Vector2i(-999, -999)
		var hit_dist := INF
		for c in candidates:
			if not board.has_ball(c):
				continue
			var d: float = layout.cell_to_pixel(c).distance_to(pos)
			if d < layout.diameter * 0.85 and d < hit_dist:
				hit_dist = d
				hit_ball = c
		if hit_ball.x != -999:
			cell = _nearest_empty_neighbor(board, layout, hit_ball, pos)
			break
	if max_points > 0:
		points.append(pos)
	return {"cell": cell, "points": points, "bounces": bounces, "bounce_points": bounce_points}


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
