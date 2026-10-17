extends RefCounted
## 设计规范：全局配色与布局尺寸的唯一来源。所有 UI 组件从这里取值。

# ---- 背景 / 面板 ----
const BG_TOP := Color(0.13, 0.14, 0.22) # 深夜蓝(顶)
const BG_BOTTOM := Color(0.07, 0.08, 0.13) # 深夜蓝(底)
const PANEL := Color(1, 1, 1, 0.08) # 玻璃面板
const PANEL_STROKE := Color(1, 1, 1, 0.16) # 玻璃描边
const PANEL_RADIUS := 20.0 # HUD 等小面板
const PANEL_RADIUS_LARGE := 30.0 # 棋盘 / 调色条 / 弹出层

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
const ACCENT := Color(1.0, 0.78, 0.30) # 金色：当前球 / 选中态 / 连击
const DEADLINE := Color(1.0, 0.62, 0.42, 0.80) # 珊瑚色掉球线，不是死亡红线
const DEADLINE_ARMED := Color(1.0, 0.52, 0.34, 0.98) # 触线宽限期的警示色
const SELECTION := Color(1, 1, 1, 0.95)
const COMBO_IDLE_BG := Color(1, 1, 1, 0.08)
const COMBO_IDLE_TEXT := Color(0.72, 0.76, 0.88)

# ---- 布局（750x1275，球半径33） ----
const SCREEN_W := 750.0
const SCREEN_H := 1275.0
const BOARD_TOP := 129.0 # 顶行球圆心: HUD底(~84) + 球半径33 + 留白12
const BOARD_AREA_H := 870.0 # 棋盘可见高度，超出上滑隐藏并裁剪
const BOARD_MARGIN_X := 36.0
const SHOOTER_POS := Vector2(375, 1038)
const PICKER_CENTER := Vector2(375, 1164)
const PICKER_DX := 93.0
const PICKER_R := 24.0
const PICKER_HIT_R := 33.0

# ---- HUD 分区（分数文字 / 连击胶囊 不得重叠） ----
const SCORE_TEXT_MAX_X := 270.0 # 分数文字最远到面板内 x=270
const COMBO_PILL_X := 280.0 # 连击胶囊从 x=280 起
const COMBO_PILL_Y := 13.0
const COMBO_PILL_W := 138.0
const COMBO_PILL_H := 38.0
const SCORE_PANEL_W := 440.0
const SCORE_PANEL_H := 64.0
