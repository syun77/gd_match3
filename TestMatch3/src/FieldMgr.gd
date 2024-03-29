extends Node2D

# ========================================
# フィールド管理 (常駐).
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
const WIDTH  = 8 # フィールドの幅.
const HEIGHT = 8 # フィールドの高さ.
const OFS_X = 540 # フィールドの描画オフセット(X).
const OFS_Y = 128 # フィールドの描画オフセット(Y).

const ERASE_CNT = 3 # 3つ並んだら消去する.
const TILE_TYPE = 4 # 4種類出現する
const TILE_SIZE = 64 # タイル1つあたりのサイズ.

# 状態.
enum eState {
	HIDE,   # 非表示.
	ACTIVE, # アクティブ.
}

# ドラッグ状態.
enum eDrag {
	NONE,          # 何もしていない.
	JUST_PRESSED,  # クリック開始した.
	PRESSED,       # ドラッグ中.
	JUST_RELEASED, # クリック終了.
}

# 消去種別 (消去判定で使用する).
enum eEraseType {
	EMPTY  = 0, # 空.
	NOT    = 1, # 検索済み(消さない).
	REMOVE = 2, # 消去対象.
}

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var _state   = eState.HIDE # 状態.
var _field   = Array2.new(WIDTH, HEIGHT) # フィールド情報.
var _select  = Point2.new() # 選択カーソル.
var _dragpos = Point2.new() # ドラッグ開始位置.
var _cnt_chain = 0 # 連鎖数.
var _max_chain = 0 # 最大連鎖数.

# ----------------------------------------
# onready.
# ----------------------------------------
@onready var _layer = $Layer # タイル管理用キャンバスレイヤー.
@onready var _spr_cursor = $LayerUI/Cursor # カーソルスプライト.

# ----------------------------------------
# public functions.
# ----------------------------------------
	
# 初期化.
func initialize() -> void:
	# フィールド情報を初期化.
	_field.fill(Array2.EMPTY)
	
	# タイルをすべて消しておく.
	remove_all_tiles()
	
	# カーソルを無効化.
	_select.reset()
	if is_instance_valid(_spr_cursor):
		_spr_cursor.visible = false
	_dragpos.reset()
	
	# 初期状態は非表示.
	_state = eState.HIDE
	
	# 連鎖数を初期化.
	_cnt_chain = 0
	_max_chain = 0

# 表示開始.
func start() -> void:
	_state = eState.ACTIVE

# 手動更新関数.
func proc(delta: float) -> void:	
	if _state == eState.HIDE:
		return # 動作しない.
	
	# タイルの更新.
	var is_moving = false
	for tile in _layer.get_children():
		tile.proc(delta)
		if tile.is_moving():
			is_moving = true # 移動中のタイルが存在する.
		
	# 新しいタイル出現チェック
	var cnt_new_tile = 0
	for i in range(_field.width):
		# 1列あたりに HEIGHT のタイルで埋まるようにする.
		var list = _search_x_tiles(i)
		var d = _field.height - len(list)
		if d <= 0:
			continue
		
		var min_y := -1.0 # 最大の高さ (グリッド標系としては最小値) 
		for tile in list:
			var py = tile.get_grid_y()
			min_y = min(py, min_y)
		# 足りないぶんだけ生成する.
		for _k in range(d):
			var n = randi()%TILE_TYPE + 1
			_create_tile(n, i, int(min_y))
			min_y -= 1.0
		cnt_new_tile += d
			
	# 消去判定を行う.
	var cnt_erase = _update_erase()
	if cnt_erase > 0:
		# 消去SE再生.
		var level = min(_cnt_chain, 7) # 7を最大とする.
		var pitch = 1.0 - 6 * (1.0/12.0) + ((1.0/12.0)*(level - 1))
		Common.play_sound(pitch)
	
	if _check_chain(is_moving, cnt_new_tile, cnt_erase):
		# コンボ継続.
		pass
	elif _cnt_chain > 0:
		# コンボ終了.
		_cnt_chain = 0
	
	# カーソルの更新.
	_update_cursor()

## コンボチェック.
func _check_chain(is_moving:bool, cnt_new_tile:int, cnt_erase:int) -> bool:
	if is_moving:
		# 移動中のタイルが存在する
		return true # 継続.
	if cnt_new_tile > 0:
		# 新しいタイルが存在する
		return true # 継続.
	if cnt_erase > 0:
		# 消去タイルが存在する.
		return true # 継続.
	
	return false # コンボ終了.

## 連鎖中かどうか.
func is_chain() -> bool:
	return _cnt_chain > 0
## 連鎖数を取得する.
func get_chain() -> int:
	return _cnt_chain
## 最連鎖数を取得する.
func get_max_chain() -> int:
	return _max_chain

# ----------------------------------------
# private functions.
# ----------------------------------------
# コンストラクタ
func _init() -> void:
	initialize()
	
## 更新 > 消去処理
## @return 消去タイルの数.
func _update_erase() -> int:
	# いったん初期化.
	_field.fill(Array2.EMPTY)
	
	# フィールド情報を更新.
	for tile in _layer.get_children():
		if tile.is_standby() == false:
			continue
		var px = tile.get_grid_x()
		var py = tile.get_grid_y()
		var num = tile.get_id()
		_field.setv(int(px), int(py), num)
	
	# 消去リストを取得する.
	var erase_list = check_erase()
	
	if erase_list.size() > 0:
		# 1つでも消せればコンボ加算.
		_cnt_chain += 1
		if _cnt_chain > _max_chain:
			_max_chain = _cnt_chain
	
	# 消去実行.
	for idx in erase_list:
		var p = _field.idx_to_pos(idx)
		#var n = _field.getv(x, y)
		#print("erase[%d]: (x, y) = (%d, %d)"%[n, x, y])
		_field.set_idx(idx, Array2.EMPTY)

		# 消滅開始.		
		var tile = search_tile(p)
		tile.start_vanish()	
	
	return erase_list.size()

# 更新 > カーソル.
func _update_cursor() -> void:
	
	if _select.is_valid():
		if search_tile(_select) == null:
			# 選択しているタイルが消えたらリセット.
			_select.reset()
			_dragpos.reset()
	
	# ドラッグ状態.
	var drag = _get_click()
	# マウス座標を取得.
	var pos = get_global_mouse_position()
	# グリッド座標系に変換.
	var target = world_to_grid(pos)
	
	match drag:
		eDrag.JUST_PRESSED:
			if _can_swap(_select, target):
				# 交換してみる.
				_do_swap(_select, target)
			else:
				# 選択し直す.
				_select = target
		eDrag.PRESSED:
			if _can_swap(_select, target):
				# 交換してみる.
				_do_swap(_select, target)
		eDrag.JUST_RELEASED:
			pass
	
	_spr_cursor.visible = false
	if _select.is_valid():
		_spr_cursor.visible = true
		_spr_cursor.position = to_world(_select.x, _select.y)

# 交換できるかどうか.
func _can_swap(sel:Point2, tgt:Point2) -> bool:
	if sel.is_valid() == false:
		return false # カーソルで選択していない.
	if sel.is_close(tgt) == false:
		return false # 交換先が隣のタイルでない
	
	var t1 = search_tile(sel)
	var t2 = search_tile(tgt)
	if t1 == null or t2 == null:
		return false # タイルが取得できない.
	
	# search_tile() できるタイルは eState.standby のみだけれど念のため.
	if t1.is_standby() == false or t2.is_standby() == false:
		return false
	
	# 交換可能.
	return true

# 交換を実行する.
func _do_swap(sel:Point2, tgt:Point2) -> void:
	var t1 = search_tile(sel)
	var t2 = search_tile(tgt)
	t1.start_swap(tgt.x, tgt.y)
	t2.start_swap(sel.x, sel.y)

# クリック状態を取得する.
func _get_click():
	if Input.is_action_just_pressed("ui_click"):
		return eDrag.JUST_PRESSED # クリックした瞬間.
	if Input.is_action_pressed("ui_click"):
		return eDrag.PRESSED # クリック中(ドラッグ中)
	if Input.is_action_just_released("ui_click"):
		return eDrag.JUST_RELEASED # クリックを離した.
	
	# 何もしていない.
	return eDrag.NONE

# タイル情報を取得する.
func getv(i:int, j:int) -> int:
	return _field.getv(i, j)

# グリッド座標系をワールド座標系に変換する.
func to_world(x:float, y:float) -> Vector2:
	# タイル座標系をワールド座標に変換する.
	var px = OFS_X + TILE_SIZE * x
	var py = OFS_Y + TILE_SIZE * y
	return Vector2(px, py)

# ワールド座標をグリッド座標系に変換する.
func world_to_grid(world:Vector2) -> Point2:
	var p = Point2.new()
	var half = TILE_SIZE / 2.0 # 中央揃えなので.
	var i = int((world.x - OFS_X + half) / TILE_SIZE)
	var j = int((world.y - OFS_Y + half) / TILE_SIZE)
	if i < 0 or WIDTH <= i:
		i = -1
	if j < 0 or HEIGHT <= j:
		j = -1
	if i == -1 or j == -1:
		# 無効な値なのでリセット.
		p.reset()
		return p
	
	p.set_xy(i, j)
	return p
	
# 下のタイルとの衝突チェックする.
func check_hit_bottom(tile:TileObj) -> bool:
	if tile.get_grid_y() >= HEIGHT - 1:
		return true # Y座標の最大なので常に衝突.

	# タイルとの衝突チェック.	
	for t in _layer.get_children():
		if tile.check_hit_bottom(t):
			return true
	
	# どのタイルとも衝突していない.
	return false

# 指定の位置にあるタイルを探す.
func search_tile(p:Point2) -> TileObj:
	for tile in _layer.get_children():
		if tile.is_standby() == false:
			continue
		
		if tile.is_same_pos(p.x, p.y) == true:
			# 座標が一致.
			return tile
	
	# 見つからなかった.
	return null

# 指定のX座標に存在するタイルをすべて取得する.
func _search_x_tiles(x:int):
	var ret = []
	for tile in _layer.get_children():
		if int(tile.get_grid_x()) == x:
			ret.append(tile) # X座標が一致した.
	
	return ret

# すべてのタイルを取得する.
func get_all_tiles():
	return _layer.get_children()

# タイルの生成.
func _create_tile(id:int, x:int, y:int) -> void:
	var tile = TileObj.instantiate()
	# CanvasLayerに登録する.
	_layer.add_child(tile)
	# 出現開始.
	tile.appear(id, x, y)

# 生成したタイルをすべて破棄する.
func remove_all_tiles() -> void:
	if is_instance_valid(_layer) == false:
		return # _layerが無効なので何もしない.
		
	for tile in _layer.get_children():
		tile.queue_free()

# ランダムでタイルを生成する.
func set_random() -> void:
	# いったんタイルを全削除しておく.
	remove_all_tiles()
	
	for idx in range(_field.width * _field.height):
		var v = randi()%TILE_TYPE + 1
		_field.set_idx(idx, v)
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
func check_erase() -> PackedInt32Array:
	var erase_list = PackedInt32Array()
	
	# 消去判定用の2次元配列.
	var tmp = Array2.new(WIDTH, HEIGHT)
	
	for j in range(_field.height):
		for i in range(_field.width):
			# 開始タイルを決める.
			var n = _field.getv(i, j)
			if n == Array2.EMPTY:
				continue	 # 空なので判定不要.
			
			# 上下と左右を分けて判定する.
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
				
				#  消去判定の再帰処理呼び出し.
				for v in tbl:
					cnt = _check_erase_recursive(tmp, n, cnt, i, j, v[0], v[1])
				
				if cnt >= ERASE_CNT:
					# ERASE_CNT以上連続していれば消せる.
					var list = tmp.search(eEraseType.REMOVE)
					erase_list.append_array(list)
	
	# 重複インデックスを削除
	var list = PackedInt32Array()
	for idx in erase_list:
		if list.has(idx) == false:
			list.append(idx) # 未登録のもののみ追加.
	
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

