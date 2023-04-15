extends Node2D

# ========================================
# メイン.
# ========================================

# ----------------------------------------
# 外部参照.
# ----------------------------------------
const Point2 = preload("res://src/common/Point2.gd")
const Array2 = preload("res://src/common/Array2.gd")
const TileObj = preload("res://src/Tile.tscn")

# ----------------------------------------
# 定数.
# ----------------------------------------

# ----------------------------------------
# onready.
# ----------------------------------------
@onready var _label = $UILayer/Label
@onready var _sound = $AudioStreamPlayer

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var _font:FontFile

# ----------------------------------------
# メンバ関数.
# ----------------------------------------
func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1152*2, 648*2))
	
	# セットアップ.
	Common.setup(_sound)
	
	# デバッグ描画用のフォント.
	_font = Control.new().get_theme_font("font")
	
	# フィールドを初期化.
	FieldMgr.initialize()
	FieldMgr.start()

# 更新.
func _process(delta: float) -> void:
	
	# 入力の更新.
	_update_input()
	
	# フィールドの更新.
	FieldMgr.proc(delta)
	
	# UIの更新.
	_update_ui(delta)
	
	# デバッグ描画.
	queue_redraw()

# 入力の更新.
func _update_input() -> void:
	
	# Rキー.
	if Input.is_action_just_pressed("ui_r"):
		# ゲームをリセットする.
		FieldMgr.initialize()
		FieldMgr.start()

## UIの更新.
func _update_ui(delta:float) -> void:
	var chain = FieldMgr.get_chain()
	var max_chain = FieldMgr.get_max_chain()
	_label.text = "CHAIN: %d/%d"%[chain, max_chain]

# デバッグ描画.
func _draw() -> void:
	
	# フィールドの状態を描画.
	for j in range(FieldMgr.HEIGHT):
		for i in range(FieldMgr.WIDTH):
			var n = FieldMgr.getv(i, j)
			var color = Color.WHITE
			if n == Array2.EMPTY:
				color = Color.GRAY
			_draw_tile(n, i, j, 64, 380, color)
	
	# タイル情報の描画.
	#var idx = 0
	#var y = 32	
	#for tile in FieldMgr.get_all_tiles():
	#	var buf = "[%d] n:%d (x, y) : (%1.0f, %1.0f)"%[idx, tile.get_id(), tile.get_grid_x(), tile.get_grid_y()]
	#	draw_string(_font, Vector2(800, y), buf)
	#	idx += 1
	#	y += 20

# タイルのデバッグ描画.
func _draw_tile(n:int, x:int, y:int, x_ofs:float, y_ofs:float, color:Color) -> void:
	var buf = "%d"%n
	draw_string(_font, Vector2(x_ofs + 32 + 20 * x, y_ofs + 32 + 20 * y), buf, 0, -1, 16, color)	

# カーソルのデバッグ描画.
func _draw_cursor(x:int, y:int, color:Color, x_ofs:float, y_ofs:float) -> void:
	var rect = Rect2(
		Vector2(x_ofs + 26 + 20 * x, y_ofs + 16 + 20 * y),
		Vector2(20, 20)
	)
	draw_rect(rect, color, false)
