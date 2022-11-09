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
const WIDTH  = 8 # フィールドの幅.
const HEIGHT = 8 # フィールドの高さ.
const OFS_X = 32 # フィールドの描画オフセット(X).
const OFS_Y = 32 # フィールドの描画オフセット(Y).

const ERASE_CNT = 3 # 3つ並んだら消去する.

# 消去種別 (消去判定で使用する).
enum eEraseType {
	EMPTY  = 0 # 空.
	NOT    = 1 # 検索済み(消さない).
	REMOVE = 2 # 消去対象.
}

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var _field  = Array2.new(WIDTH, HEIGHT)

# ----------------------------------------
# onready.
# ----------------------------------------
onready var _layer = $Layer # タイル管理用キャンバスレイヤー.

# ----------------------------------------
# メンバ関数.
# ----------------------------------------
# 初期化.
func initialize() -> void:
	# フィールド情報を初期化.
	_field.fill(Array2.EMPTY)
	
	# タイルをすべて消しておく.
	remove_all()

# 生成したタイルをすべて破棄する.
func remove_all() -> void:
	for tile in _layer.get_children():
		tile.queue_free()	

# 更新.
func _process(_delta: float) -> void:	
	
	# 消去判定を行う.
	_update_erase()

# 更新 > 消去処理
func _update_erase() -> void:
	# いったん初期化.
	_field.fill(Array2.EMPTY)
	
	# フィールド情報を更新.
	for tile in _layer.get_children():
		if tile.is_standby() == false:
			continue
		var px = tile.get_now_x()
		var py = tile.get_now_y()
		var num = tile.get_id()
		_field.setv(int(px), int(py), num)
	
	# 消去リストを取得する.
	var erase_list = check_erase()
	
	# 消去実行.
	for idx in erase_list:
		var x = _field.to_x(idx)
		var y = _field.to_y(idx)
		var n = _field.getv(x, y)
		#print("erase[%d]: (x, y) = (%d, %d)"%[n, x, y])
		_field.set_idx(idx, Array2.EMPTY)

		# 消滅開始.		
		var tile = search_tile(x, y)
		tile.start_vanish()	

# タイル情報を取得する.
func getv(i:int, j:int) -> int:
	return _field.getv(i, j)

# 下のタイルとの衝突チェックする.
func check_hit_bottom(tile:TileObj) -> bool:
	if tile.get_now_y() >= HEIGHT - 1:
		return true
	
	for t in _layer.get_children():
		if tile.check_hit_bottom(t):
			return true
	
	return false

# 指定の位置にあるタイルを探す.
func search_tile(i:int, j:int) -> TileObj:
	for tile in _layer.get_children():
		if tile.is_standby() == false:
			continue
		
		if tile.is_same_pos(i, j) == true:
			# 座標が一致.
			return tile
	
	# 見つからなかった.
	return null

# タイルの生成.
func _create_tile(id:int, x:int, y:int) -> void:
	var tile = TileObj.instance()
	_layer.add_child(tile)
	tile.appear(id, x, y)

# ランダムでタイルを生成する.
func set_random() -> void:
	# いったんタイルを全削除しておく.
	remove_all()
	
	for idx in range(_field.width * _field.height):
		var v = randi()%4
		_field.set_idx(idx, v)
		if v == Array2.EMPTY:
			continue
		var px = _field.to_x(idx)
		var py = _field.to_y(idx)
		_create_tile(v, px, py)
	
	# いったん消しておきます.
	_field.fill(Array2.EMPTY)

# タイルを交換する.
func swap(x1:int, y1:int, x2:int, y2:int) -> void:
	_field.swap(x1, y1, x2, y2)

# 落下を実行する.
func fall() -> void:
	_field.fall()

# 消去チェックする.
# @return 消去するインデックスのリスト.
func check_erase() -> PoolIntArray:
	var erase_list = PoolIntArray()
	
	var tmp = Array2.new(WIDTH, HEIGHT)
	
	for j in range(_field.height):
		for i in range(_field.width):
			var n = _field.getv(i, j)
			if n == Array2.EMPTY:
				# 空なので判定不要.
				continue
			
			for k in range(2):
				# 初期化.
				tmp.fill(eEraseType.EMPTY)
				tmp.setv(i, j, eEraseType.REMOVE) # 消せるかもしれない候補.
				var cnt = 1
				
				# 上下を調べる.
				var tbl = [[0, -1], [0, 1]]
				if k == 1:
					# 左右を調べる.
					tbl = [[-1, 0], [1, 0]]
				
				for v in tbl:
					cnt = _check_erase_recursive(tmp, n, cnt, i, j, v[0], v[1])
				
				if cnt >= ERASE_CNT:
					# ERASE_CNT以上連続していれば消せる.
					var list = tmp.search(eEraseType.REMOVE)
					erase_list.append_array(list)
	
	# 重複インデックスを削除
	var list = PoolIntArray()
	for idx in erase_list:
		if list.has(idx) == false:
			list.append(idx)
	
	return list

# 消去チェック (再帰処理用).
func _check_erase_recursive(tmp:Array2, n:int, cnt:int, x:int, y:int, vx:int, vy:int) -> int:
	# 移動先を調べる.
	var x2 = x + vx
	var y2 = y + vy
	if tmp.getv(x2, y2) == eEraseType.NOT:
		# 探索済み.
		return cnt
	
	var n2 = _field.getv(x2, y2)
	if n != n2:
		# 不一致なので消せない.
		tmp.setv(x2, y2, eEraseType.NOT)
		return cnt
	
	# 消せるかもしれない.
	cnt += 1
	tmp.setv(x2, y2, eEraseType.REMOVE)
	# 次を調べる.
	return _check_erase_recursive(tmp, n, cnt, x2, y2, vx, vy)

