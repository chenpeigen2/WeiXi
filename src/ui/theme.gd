extends RefCounted
## 设计规范：全局配色与布局尺寸的唯一来源。所有 UI 组件从这里取值。

# ---- 背景 / 面板 ----
const BG_TOP := Color(0.78, 0.93, 0.85) # 开心果马卡龙(顶)
const BG_BOTTOM := Color(0.85, 0.81, 0.95) # 薰衣草马卡龙(底)
const PANEL := Color(1.0, 0.98, 0.94, 0.96) # 奶油面板
const PANEL_STROKE := Color(0.64, 0.87, 0.76, 0.65) # 薄荷描边
const PANEL_SOFT := Color(1.0, 0.96, 0.91, 0.95) # 更浅奶油
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
const TEXT_MAIN := Color(0.30, 0.17, 0.23) # 可可文字
const TEXT_DIM := Color(0.48, 0.36, 0.46) # 玫瑰灰
const ACCENT := Color(0.92, 0.38, 0.55) # 覆盆子粉：当前球 / 选中态 / 连击
const HEART := Color(0.95, 0.46, 0.60) # 爱心
const BUNNY := Color(1.0, 0.80, 0.84) # 小兔脸
const BUNNY_EAR := Color(1.0, 0.91, 0.92) # 兔耳内侧
const MINT := Color(0.62, 0.88, 0.74) # 薄荷马卡龙
const LAVENDER := Color(0.80, 0.73, 0.95) # 薰衣草马卡龙
const LEMON := Color(1.0, 0.90, 0.62) # 柠檬马卡龙
const ROSE := Color(1.0, 0.66, 0.76) # 玫瑰马卡龙
const PEACH := Color(1.0, 0.78, 0.66) # 蜜桃马卡龙
const SKY := Color(0.68, 0.84, 1.0) # 天空马卡龙
const DEADLINE := Color(0.92, 0.32, 0.38, 0.82) # 珊瑚粉掉球线
const DEADLINE_ARMED := Color(0.92, 0.20, 0.28, 0.98) # 触线宽限期的警示色
const SELECTION := Color(0.92, 0.38, 0.55, 0.95)
const COMBO_IDLE_BG := Color(0.80, 0.73, 0.95, 0.45)
const COMBO_IDLE_TEXT := Color(0.45, 0.34, 0.52)
const FACE_INK := Color(0.30, 0.16, 0.23, 0.86) # 表情墨色
const BLUSH := Color(1.0, 0.45, 0.58, 0.34) # 腮红
const STAR := Color(0.76, 0.54, 0.66) # 背景小星星（浅底上的玫瑰）
const INK := Color(0.34, 0.18, 0.26, 0.72) # 奶油底上的描点/线

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
