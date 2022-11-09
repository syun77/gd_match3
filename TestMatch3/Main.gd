extends Node2D

# ========================================
# フィールド管理 (常駐).
# ========================================

# ----------------------------------------
# 外部参照.
# ----------------------------------------
const Point2 = preload("res://Point2.gd")
const Array2 = preload("res://Array2.gd")
const TileObj = preload("res://Tile.tscn")

# ----------------------------------------
# 定数.
# ----------------------------------------


# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var _font:BitmapFont
var _cursor = Point2.new()
var _select = Point2.new()


# ----------------------------------------
# メンバ関数.
# ----------------------------------------
func _ready() -> void:
	_font = Control.new().get_font("font")
	# 選択位置をリセットする.
	_select.reset()
	
	# フィールドを初期化.
	FieldMgr.initialize()

# 更新.
func _process(delta: float) -> void:
	
	# 入力の更新.
	_update_input()
	
	# フィールドの更新.
	FieldMgr.proc(delta)
	
	# デバッグ描画.
	update()

# 入力の更新.
func _update_input() -> void:
	# カーソルの移動.
	if Input.is_action_just_pressed("ui_left"):
		_cursor.x -= 1
	if Input.is_action_just_pressed("ui_right"):
		_cursor.x += 1
	if Input.is_action_just_pressed("ui_up"):
		_cursor.y -= 1
	if Input.is_action_just_pressed("ui_down"):
		_cursor.y += 1
	_cursor.x = clamp(_cursor.x, 0, 7)
	_cursor.y = clamp(_cursor.y, 0, 7)
	
	if Input.is_action_just_pressed("ui_r"):
		FieldMgr.initialize()
		FieldMgr.start()
		FieldMgr.set_random()
		
	if Input.is_action_just_pressed("ui_z"):
		if _cursor.equal(_select) == false:
			# 同じでなければ変更
			if _select.is_valid() and _select.is_close(_cursor):
				# 隣の位置なら値を交換する
				FieldMgr.swap(_select.x, _select.y, _cursor.x, _cursor.y)
				# 選択位置をリセットする
				_select.reset()
			else:
				# 選択位置をカーソルに合わせる.
				_select.copy(_cursor)


# デバッグ描画.
func _draw() -> void:
	
	# カーソルの描画.
	_draw_cursor(_cursor.x, _cursor.y, Color.red, 640, 380)
	if _select.is_valid():
		_draw_cursor(_select.x, _select.y, Color.yellow, 640, 380)
	
	# フィールドの状態を描画.
	for j in range(FieldMgr.HEIGHT):
		for i in range(FieldMgr.WIDTH):
			var n = FieldMgr.getv(i, j)
			var color = Color.white
			if n == Array2.EMPTY:
				color = Color.gray
			_draw_tile(n, i, j, 640, 380, color)
	
	# タイル情報の描画.
	#var idx = 0
	#var y = 32	
	#for tile in FieldMgr.get_all_tiles():
	#	var buf = "[%d] n:%d (x, y) : (%1.0f, %1.0f)"%[idx, tile.get_id(), tile.get_now_x(), tile.get_now_y()]
	#	draw_string(_font, Vector2(800, y), buf)
	#	idx += 1
	#	y += 20

# タイルのデバッグ描画.
func _draw_tile(n:int, x:int, y:int, x_ofs:float, y_ofs:float, color:Color) -> void:
	var buf = "%d"%n
	draw_string(_font, Vector2(x_ofs + 32 + 20 * x, y_ofs + 32 + 20 * y), buf, color)	

# カーソルのデバッグ描画.
func _draw_cursor(x:int, y:int, color:Color, x_ofs:float, y_ofs:float) -> void:
	var rect = Rect2(
		Vector2(x_ofs + 26 + 20 * x, y_ofs + 16 + 20 * y),
		Vector2(20, 20)
	)
	draw_rect(rect, color, false)

	
