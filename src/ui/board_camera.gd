extends RefCounted
## 棋盘相机：球大小恒定（永不缩放），盘面超高时整体上滑、顶部隐藏，
## 安全线始终钉在视野底部。

const Ui = preload("res://src/ui/theme.gd")


static func scale_for(_rows: int, _row_height: float, _diameter: float) -> float:
	return 1.0 # 不缩放，超高改上滑


## 盘面像素坐标原点的屏幕位置：装得下则顶对齐，装不下则上滑超出部分
static func origin_for(rows: int, row_height: float, diameter: float, board_px_w: float) -> Vector2:
	var total_h: float = rows * row_height + diameter
	var y: float = Ui.BOARD_TOP - max(0.0, total_h - Ui.BOARD_AREA_H)
	return Vector2((Ui.SCREEN_W - board_px_w) * 0.5, y)


static func to_screen(board_pos: Vector2, scale: float, origin: Vector2) -> Vector2:
	return origin + board_pos * scale


static func to_board(screen_pos: Vector2, scale: float, origin: Vector2) -> Vector2:
	return (screen_pos - origin) / scale
