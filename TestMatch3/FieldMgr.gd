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
const WIDTH = 8
const HEIGHT = 8
const OFS_X = 32
const OFS_Y = 32

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var _field = Array2.new(WIDTH, HEIGHT)
var _tiles = []

onready var _layer = $Layer

# ----------------------------------------
# メンバ関数.
# ----------------------------------------
func _process(_delta: float) -> void:
	
	# いったん初期化.
	_field.fill(Array2.EMPTY)
	
	# フィールド情報を更新.
	for tile in _tiles:
		if tile.is_standby() == false:
			continue
		var px = tile.get_now_x()
		var py = tile.get_now_y()
		var num = tile.get_id()
		_field.setv(int(px), int(py), num)

func getv(i:int, j:int) -> int:
	return _field.getv(i, j)
	
func check_hit_bottom(tile:TileObj) -> bool:
	if tile.get_now_y() >= HEIGHT - 1:
		return true
	
	for t in _tiles:
		if tile.check_hit_bottom(t):
			return true
	
	return false

func _create_tile(id:int, x:int, y:int) -> void:
	var tile = TileObj.instance()
	_layer.add_child(tile)
	_tiles.append(tile)
	tile.appear(id, x, y)

func set_random() -> void:
	for tile in _tiles:
		tile.queue_free()
	_tiles = []
	
	for idx in range(_field.width * _field.height):
		var v = randi()%7
		_field.set_idx(idx, v)
		if v == Array2.EMPTY:
			continue
		var px = _field.to_x(idx)
		var py = _field.to_y(idx)
		_create_tile(v, px, py)

func swap(x1:int, y1:int, x2:int, y2:int) -> void:
	_field.swap(x1, y1, x2, y2)

func fall() -> void:
	_field.fall()

func check_erase() -> void:
	var erase_list = PoolIntArray()
	
	# 1: 検索済み.
	# 2: 消去する.
	var tmp = Array2.new(WIDTH, HEIGHT)
	
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

