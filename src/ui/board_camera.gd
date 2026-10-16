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


## 底线：触线即掉那一行(deadline_row)球的下沿，球碰线就掉
static func deadline_line_y(deadline_row: int, row_height: float, radius: float, origin_y: float) -> float:
	return origin_y + deadline_row * row_height + radius


## 区域标注框上沿：顶行球上沿(origin_y - 半径)再留 10px
const PANEL_TOP_PAD := 10.0


static func panel_top(origin_y: float, radius: float) -> float:
	return origin_y - radius - PANEL_TOP_PAD


## 区域标注框下边界：底线 + 12px 留白
const PANEL_BOTTOM_PAD := 12.0


static func panel_bottom(deadline_row: int, row_height: float, radius: float, origin_y: float) -> float:
	return deadline_line_y(deadline_row, row_height, radius, origin_y) + PANEL_BOTTOM_PAD
