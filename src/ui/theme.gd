extends RefCounted
## 设计规范：全局配色与布局尺寸的唯一来源。所有 UI 组件从这里取值。

# ---- 背景 / 面板 ----
const BG_TOP := Color(0.13, 0.14, 0.22) # 深夜蓝(顶)
const BG_BOTTOM := Color(0.07, 0.08, 0.13) # 深夜蓝(底)
const PANEL := Color(1, 1, 1, 0.06) # 玻璃面板
const PANEL_STROKE := Color(1, 1, 1, 0.10)

# ---- 球色（糖果色系） ----
const BALL_COLORS: Array[Color] = [
	Color(0.96, 0.30, 0.35), # 红
	Color(0.98, 0.80, 0.22), # 黄
	Color(0.30, 0.58, 0.98), # 蓝
	Color(0.36, 0.85, 0.45), # 绿
	Color(0.72, 0.45, 0.95), # 紫
	Color(0.98, 0.55, 0.25), # 橙
]

# ---- 文字 / 强调 ----
const TEXT_MAIN := Color(0.93, 0.94, 0.98)
const TEXT_DIM := Color(0.60, 0.63, 0.72)
const ACCENT := Color(1.0, 0.78, 0.30) # 金色
const DEADLINE := Color(0.95, 0.40, 0.40, 0.75)
const SELECTION := Color(1, 1, 1, 0.95)

# ---- 布局（500x850 桌面手机比例，球半径22） ----
const SCREEN_W := 500.0
const SCREEN_H := 850.0
const BOARD_TOP := 64.0 # 棋盘顶部（给分数条让位）
const BOARD_AREA_H := 580.0 # 棋盘可见高度，超出上滑隐藏并裁剪
const BOARD_MARGIN_X := 24.0
const SHOOTER_POS := Vector2(250, 692)
const PICKER_CENTER := Vector2(250, 776)
const PICKER_DX := 62.0
const PICKER_R := 16.0
const PICKER_HIT_R := 22.0
