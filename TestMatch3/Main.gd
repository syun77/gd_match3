extends Node2D

# ----------------------------------------
# 外部参照.
# ----------------------------------------
const Point2 = preload("res://Point2.gd")
const Array2 = preload("res://Array2.gd")
const TileObj = preload("res://Tile.tscn")

# ----------------------------------------
# 定数.
# ----------------------------------------
const FIELD_WIDTH = 8
const FIELD_HEIGHT = 8

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var _field = Array2.new(FIELD_WIDTH, FIELD_HEIGHT)
var _font:BitmapFont
var _cursor = Point2.new()
var _select = Point2.new()

var _tiles = []

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
		_set_random()
		# 落下させる
		#_fall()
		
	if Input.is_action_just_pressed("ui_z"):
		if _cursor.equal(_select) == false:
			# 同じでなければ変更
			if _select.is_valid() and _select.is_close(_cursor):
				# 隣の位置なら値を交換する
				_field.swap(_select.x, _select.y, _cursor.x, _cursor.y)
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

func _set_random() -> void:
	for tile in _tiles:
		tile.queue_free()
	_tiles = []
	
	for idx in range(_field.width * _field.height):
		var v = randi()%7
		_field.set_idx(idx, v)
		if v == Array2.EMPTY:
			pass
			#continue
		var px = _field.to_x(idx)
		var py = _field.to_y(idx)
		var tile = _create_tile(v, px, py)
		_tiles.append(tile)
		#add_child(tile)

# 落下.
func _fall() -> void:
	_field.fall()

# 消去チェック.
func _check_erase() -> void:
	var erase_list = PoolIntArray()
	
	# 1: 検索済み.
	# 2: 消去する.
	var tmp = Array2.new(FIELD_WIDTH, FIELD_HEIGHT)
	
	for j in range(_field.height):
		for i in range(_field.width):
			var n = _field.getv(i, j)
			if n == Array2.EMPTY:
				# 空なので判定不要.
				continue
			
			tmp.fill(0)
			tmp.setv(i, j, 2) # 消せるかもしれない候補.
			
			for k in range(2):
				var cnt = 1
				
				# 上下を調べる.
				var tbl = [[0, -1], [0, 1]]
				if k == 1:
					# 左右を調べる.
					tbl = [[-1, 0], [1, 0]]
				
				for v in tbl:
					cnt = _check_erase_around(tmp, n, cnt, i, j, v[0], v[1])
				
				if cnt >= 3:
					# 消せる.
					var list = tmp.search(2)
					erase_list.append_array(list)
	
	# 重複インデックスを削除
	var list = PoolIntArray()
	for idx in erase_list:
		if list.has(idx) == false:
			list.append(idx)
	
	# 消去実行.
	for idx in list:
		var x = _field.to_x(idx)
		var y = _field.to_y(idx)
		var n = _field.getv(x, y)
		print("erase[%d]: (x, y) = (%d, %d)"%[n, x, y])
		_field.set_idx(idx, Array2.EMPTY)
		
func _check_erase_around(tmp:Array2, n:int, cnt:int, x:int, y:int, vx:int, vy:int) -> int:
	# 移動先を調べる.
	var x2 = x + vx
	var y2 = y + vy
	if tmp.getv(x2, y2) == 1:
		# 探索済み.
		return cnt
	
	var n2 = _field.getv(x2, y2)
	if n != n2:
		# 不一致なので消せない.
		tmp.setv(x2, y2, 1)
		return cnt
	
	# 消せるかもしれない.
	cnt += 1
	tmp.setv(x2, y2, 2)
	# 次を調べる.
	return _check_erase_around(tmp, n, cnt, x2, y2, vx, vy)

func _draw() -> void:
	
	_draw_cursor(_cursor.x, _cursor.y, Color.red, 512, 380)
	if _select.is_valid():
		_draw_cursor(_select.x, _select.y, Color.yellow, 512, 380)
	
	for j in range(_field.height):
		for i in range(_field.width):
			var n = _field.getv(i, j)
			_draw_tile(n, i, j, 512, 380)

func _draw_tile(n:int, x:int, y:int, x_ofs:float, y_ofs:float) -> void:
	var buf = "%d"%n
	draw_string(_font, Vector2(x_ofs + 32 + 20 * x, y_ofs + 32 + 20 * y), buf)	

func _draw_cursor(x:int, y:int, color:Color, x_ofs:float, y_ofs:float) -> void:
	var rect = Rect2(
		Vector2(x_ofs + 26 + 20 * x, y_ofs + 16 + 20 * y),
		Vector2(20, 20)
	)
	draw_rect(rect, color, false)
	
