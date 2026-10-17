extends RefCounted
## 设计规范：全局配色与布局尺寸的唯一来源。所有 UI 组件从这里取值。

# ---- 背景 / 面板 ----
const BG_TOP := Color(0.20, 0.15, 0.30) # 薰衣草夜空(顶)
const BG_BOTTOM := Color(0.10, 0.075, 0.16) # 深梅子(底)
const PANEL := Color(1.0, 0.84, 0.92, 0.08) # 草莓奶昔玻璃
const PANEL_STROKE := Color(1.0, 0.84, 0.92, 0.16) # 粉色玻璃描边
const PANEL_RADIUS := 20.0 # HUD 等小面板
const PANEL_RADIUS_LARGE := 30.0 # 棋盘 / 调色条 / 弹出层

# ---- 球色（糖果色系） ----
const BALL_COLORS: Array[Color] = [
	Color(1.00, 0.52, 0.62), # 草莓粉
	Color(1.00, 0.86, 0.48), # 柠檬奶油
	Color(0.55, 0.78, 1.00), # 天空蓝
	Color(0.58, 0.92, 0.72), # 薄荷绿
	Color(0.80, 0.65, 1.00), # 薰衣草紫
	Color(1.00, 0.68, 0.48), # 蜜桃橙
]

# ---- 文字 / 强调 ----
const TEXT_MAIN := Color(1.0, 0.96, 0.98) # 奶油白
const TEXT_DIM := Color(0.72, 0.66, 0.80) # 薰衣草灰
const ACCENT := Color(1.0, 0.60, 0.74) # 草莓粉：当前球 / 选中态 / 连击
const DEADLINE := Color(1.0, 0.58, 0.52, 0.82) # 珊瑚粉掉球线
const DEADLINE_ARMED := Color(1.0, 0.46, 0.44, 0.98) # 触线宽限期的警示色
const SELECTION := Color(1.0, 0.94, 0.97, 0.95)
const COMBO_IDLE_BG := Color(1.0, 0.86, 0.93, 0.08)
const COMBO_IDLE_TEXT := Color(0.78, 0.72, 0.86)
const FACE_INK := Color(0.24, 0.12, 0.23, 0.86) # 表情墨色
const BLUSH := Color(1.0, 0.45, 0.58, 0.34) # 腮红
const STAR := Color(1.0, 0.82, 0.90) # 背景小星星

# ---- 布局（750x1275，球半径33） ----
const SCREEN_W := 750.0
const SCREEN_H := 1275.0
const BOARD_TOP := 129.0 # 顶行球圆心: HUD底(~84) + 球半径33 + 留白12
const BOARD_AREA_H := 870.0 # 棋盘可见高度，超出上滑隐藏并裁剪
const BOARD_MARGIN_X := 36.0
const BOARD_PANEL_X := 28.0 # 棋盘面板左沿 = BOARD_MARGIN_X - 8
const BOARD_PANEL_W := 694.0 # 750 - 28*2，HUD 与棋盘共用
const SHOOTER_POS := Vector2(375, 1038)
const PICKER_CENTER := Vector2(375, 1164)
const PICKER_DX := 93.0
const PICKER_R := 24.0
const PICKER_HIT_R := 33.0

# ---- HUD 分区（分数文字 / 连击胶囊 不得重叠） ----
const SCORE_TEXT_MAX_X := 210.0 # 分数文字最远到面板内 x=210（给中间提示留位）
const COMBO_PILL_X := 532.0 # 连击胶囊从 x=532 起（整条 HUD 的右侧）
const COMBO_PILL_Y := 13.0
const COMBO_PILL_W := 138.0
const COMBO_PILL_H := 38.0
const SCORE_PANEL_X := 28.0 # 与棋盘面板左沿对齐
const SCORE_PANEL_Y := 12.0
const SCORE_PANEL_W := 694.0 # 与棋盘面板同宽
const SCORE_PANEL_H := 64.0
const HINT_X := 245.0 # 提示居中在分数与连击之间
const HINT_Y := 27.0
const HINT_W := 260.0
const HINT_H := 34.0
