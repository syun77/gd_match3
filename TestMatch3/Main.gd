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
	
func _create_tile(id:int, x:int, y:int) -> TileObj:
	var tile = TileObj.instance()
	add_child(tile)
	tile.appear(id, x, y)
	return tile

# 更新.
func _process(_delta: float) -> void:
	
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
		# ランダムにブロックを配置する
		FieldMgr.set_random()
		# 落下させる
		#_fall()
		
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

	if Input.is_action_just_pressed("ui_x"):
		# 消去チェック.
		_check_erase()
		_fall()
	
	update()

# 落下.
func _fall() -> void:
	FieldMgr.fall()

# 消去チェック.
func _check_erase() -> void:
	FieldMgr.check_erase()

func _draw() -> void:
	
	_draw_cursor(_cursor.x, _cursor.y, Color.red, 512, 380)
	if _select.is_valid():
		_draw_cursor(_select.x, _select.y, Color.yellow, 512, 380)
	
	for j in range(FieldMgr.HEIGHT):
		for i in range(FieldMgr.WIDTH):
			var n = FieldMgr.getv(i, j)
			var color = Color.white
			if n == Array2.EMPTY:
				color = Color.gray
			_draw_tile(n, i, j, 512, 380, color)

func _draw_tile(n:int, x:int, y:int, x_ofs:float, y_ofs:float, color:Color) -> void:
	var buf = "%d"%n
	draw_string(_font, Vector2(x_ofs + 32 + 20 * x, y_ofs + 32 + 20 * y), buf, color)	

func _draw_cursor(x:int, y:int, color:Color, x_ofs:float, y_ofs:float) -> void:
	var rect = Rect2(
		Vector2(x_ofs + 26 + 20 * x, y_ofs + 16 + 20 * y),
		Vector2(20, 20)
	)
	draw_rect(rect, color, false)

	
