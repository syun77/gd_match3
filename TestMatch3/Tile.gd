extends Area2D

# ========================================
# タイルオブジェクト.
# ========================================

# ----------------------------------------
# クラス名.
# ----------------------------------------
class_name TileObj

# ----------------------------------------
# 外部参照.
# ----------------------------------------
const Array2 = preload("res://Array2.gd")

# ----------------------------------------
# 定数.
# ----------------------------------------
# 重力加速度.
const GRAVITY_Y = 0.5

# タイマー.
const TIMER_VANISH = 0.5 # 消滅時間.
const TIMER_SWAP = 0.1 # 交換.

enum eTile {
	NONE = 0 # 無効なタイルID
}

enum eState {
	HIDE, # 非表示.
	FALLING, # 落下中.
	STANDBY, # 待機中.
	VANISH, # 消滅演出中.
	SWAP, # 交換アニメーション中.
}

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
# タイルID
var _id:int = 0

# 状態.
var _timer:float = 0
var _state = eState.HIDE

# 現在のグリッド座標.
var _grid_x:float = 0
var _grid_y:float = 0
# 交換先のグリッド座標.
var _swap_x:float = 0
var _swap_y:float = 0

# 落下速度.
var _velocity_y:float = 0

# ----------------------------------------
# onready.
# ----------------------------------------
onready var _spr = $Sprite
onready var _label = $Label

# ----------------------------------------
# メンバ関数.
# ----------------------------------------
# タイルIDを設定.
func set_id(var id):
	_id = id
	
	# IDに対応する画像を設定する
	var tbl = [
		"tile_red.png", # ID=0は無効だけれども念のため設定.
		"tile_red.png",
		"tile_yellow.png",
		"tile_green.png",
		"tile_magenta.png",
		"tile_blue.png",
		"tile_orange.png",
		"tile_sliver.png",
		"tile_gold.png"
	]
	
	_spr.texture = load("res://assets/tiles/%s"%tbl[_id])

# タイルIDを取得する.
func get_id() -> int:
	return _id

# 現在の座標(グリッド座標)を取得する.
func get_grid_x() -> float:
	return _grid_x
func get_grid_y() -> float:
	return _grid_y

# 開始処理.
func _ready() -> void:
	set_id(eTile.NONE)
	visible = false

# 出現開始.
func appear(id:int, px:float, py:float) -> void:
	# IDを設定.
	set_id(id)
	
	_grid_x = px
	_grid_y = py
	
	_state = eState.FALLING
	visible = true
	
	# グリッド座標系をワールド座標系に変換.
	position = FieldMgr.to_world(_grid_x, _grid_y)

# 入れ替え開始.
func start_swap(next_x:float, next_y:float) -> void:
	if _state != eState.STANDBY:
		printerr("eState.STANDBY(%d) 以外では呼び出せません state:%d"%[eState.STANDBY, _state])
		return
	
	_swap_x = next_x
	_swap_y = next_y
	
	_state = eState.SWAP
	_timer = TIMER_SWAP

# 入れ替え終了.
func end_swap() -> void:
	_grid_x = _swap_x
	_grid_y = _swap_y
	_state = eState.STANDBY

# 落下チェック.
func _check_fall() -> bool:
	if FieldMgr.check_hit_bottom(self):
		return false
	return true

# 下のタイルと衝突しているかどうか
# @param tile 判定する下のタイル 
func check_hit_bottom(tile:TileObj) -> bool:
	
	var obj_id = tile.get_instance_id()
	#var number = tile.get_id()
	var tile_x = tile.get_grid_x()
	var tile_y = tile.get_grid_y()
	
	# ユニークIDを比較.
	if get_instance_id() == obj_id:
		return false # 自分自身は除外.
	
	if _grid_x != tile_x:
		return false # 別のX座標のブロック
	
	if _grid_y > tile_y:
		return false # 対象のタイルがそもそも上にあるので判定不要.
		
	var bottom = _grid_y + 0.5 # 上のブロックの底
	var upper = tile_y - 0.5 # 下のブロックのトップ
	if bottom < upper:
		return false # 重なっていない.
	
	# 更新タイミングの関係でめり込んでいたら押し返す.
	_grid_y -= (bottom - upper)
	
	return true

# グリッドにフィットするように調整する.
func fit_grid() -> void:
	_grid_x = int(_grid_x)
	_grid_y = int(_grid_y)

# 非表示状態かどうか.
func is_hide() -> bool:
	return _state == eState.HIDE

# 消去や移動判定可能な状態かどうか.
func is_standby() -> bool:
	return _state == eState.STANDBY

# 指定の位置にタイルが存在するかどうか.
func is_same_pos(i:int, j:int) -> bool:
	if i == int(_grid_x) and j == int(_grid_y):
		return true	
	return false

# 消滅処理開始.
func start_vanish() -> void:
	_state = eState.VANISH
	_timer = TIMER_VANISH

func _to_world() -> Vector2:
	if _state == eState.SWAP:
		# 交換中は特殊処理.
		var rate = 1.0 - _timer / TIMER_SWAP
		var px = _grid_x + (_swap_x - _grid_x) * rate
		var py = _grid_y + (_swap_y - _grid_y) * rate
		return FieldMgr.to_world(px, py)
	
	return FieldMgr.to_world(_grid_x, _grid_y)

# 手動更新関数.
func proc(delta: float) -> void:
	if _id == eTile.NONE:
		visible = false
		return
	
	# タイル座標系をワールド座標系に変換.
	position = _to_world()
	
	_label.text = "%d"%_id
	
	match _state:
		eState.HIDE: # 非表示.
			visible = false
		eState.FALLING: # 落下中.
			_label.text = "F"
			# 重力を加算.
			_velocity_y += GRAVITY_Y	 * delta
			# 速度を位置に加算.
			_grid_y += _velocity_y
			if _check_fall() == false:
				# 移動完了.
				fit_grid()
				_velocity_y = 0
				_state = eState.STANDBY
		eState.STANDBY:
			if _check_fall():
				_state = eState.FALLING
		eState.VANISH:
			_timer -= delta
			visible = true
			if fmod(_timer, 0.1) < 0.05:
				visible = false
			if _timer < 0:
				# 消滅する.
				queue_free()
		eState.SWAP:
			_timer -= delta
			if _timer < 0:
				# 交換終了.
				end_swap()
	
	#_label.text += " X:%3.2f Y:%3.2f"%[_grid_x, _grid_y]
