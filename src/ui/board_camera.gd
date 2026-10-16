extends RefCounted
## 棋盘相机：盘面随续行整体缩放，保证全场可见。纯数学。

const Ui = preload("res://src/ui/theme.gd")


static func scale_for(rows: int, row_height: float, diameter: float) -> float:
	var h: float = rows * row_height + diameter
	return min(1.0, Ui.BOARD_AREA_H / h)


## 盘面像素坐标原点的屏幕位置（水平居中）
static func origin_for(scale: float, board_px_w: float) -> Vector2:
	return Vector2((Ui.SCREEN_W - board_px_w * scale) * 0.5, Ui.BOARD_TOP)


static func to_screen(board_pos: Vector2, scale: float, origin: Vector2) -> Vector2:
	return origin + board_pos * scale


static func to_board(screen_pos: Vector2, scale: float, origin: Vector2) -> Vector2:
	return (screen_pos - origin) / scale
