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
const GRAVITY_Y = 0.005

# 消滅時間.
const TIMER_VANISH = 0.5

enum eTile {
	NONE = 0 # 無効なタイルID
}

enum eState {
	HIDE, # 非表示.
	FALLING, # 落下中.
	STANDBY, # 待機中.
	VANISH, # 消滅演出中.
}

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
# タイルID
var _id:int = 0

# 状態.
var _timer:float = 0
var _state = eState.HIDE

# 現在の座標.
var _now_x:float = 0
var _now_y:float = 0

# 落下速度.
var _velocity_y:float = 0

# ----------------------------------------
# onready.
# ----------------------------------------
onready var _rect = $ColorRect
onready var _label = $Label

# ----------------------------------------
# メンバ関数.
# ----------------------------------------
func set_id(var id):
	_id = id
	var tbl = [
		Color.white,
		Color.red,
		Color.green,
		Color.aqua,
		Color.magenta,
		Color.yellow,
		Color.white
	]
	
	_rect.color = tbl[id]
	
func get_id() -> int:
	return _id

func get_now_x() -> float:
	return _now_x
func get_now_y() -> float:
	return _now_y

func appear(id:int, px:float, py:float) -> void:
	# IDを設定.
	set_id(id)
	
	_now_x = px
	_now_y = py
	
	_state = eState.FALLING
	visible = true
	
	# タイル座標系をワールド座標系に変換.
	position = FieldMgr.to_world(_now_x, _now_y)

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
	var tile_x = tile.get_now_x()
	var tile_y = tile.get_now_y()
	
	# ユニークIDを比較.
	if get_instance_id() == obj_id:
		return false # 自分自身は除外.
	
	if _now_x != tile_x:
		return false # 別のX座標のブロック
	
	if _now_y > tile_y:
		return false # 対象のタイルがそもそも上にあるので判定不要.
		
	var bottom = _now_y + 0.5 # 上のブロックの底
	var upper = tile_y - 0.5 # 下のブロックのトップ
	if bottom < upper:
		return false # 重なっていない.
	
	# 更新タイミングの関係でめり込んでいたら押し返す.
	_now_y -= (bottom - upper)
	
	return true

func fit_grid() -> void:
	_now_x = int(_now_x)
	_now_y = int(_now_y)

func is_hide() -> bool:
	return _state == eState.HIDE
func is_standby() -> bool:
	return _state == eState.STANDBY

func is_same_pos(i:int, j:int) -> bool:
	if i == int(_now_x) and j == int(_now_y):
		return true	
	return false
	
func start_vanish() -> void:
	_state = eState.VANISH
	_timer = TIMER_VANISH

func _ready() -> void:
	set_id(eTile.NONE)
	visible = false

# 手動更新関数.
func proc(delta: float) -> void:
	if _id == eTile.NONE:
		visible = false
		return
	
	# タイル座標系をワールド座標系に変換.
	position = FieldMgr.to_world(_now_x, _now_y)
	
	_label.text = "%d"%_id
	
	match _state:
		eState.HIDE: # 非表示.
			visible = false
		eState.FALLING: # 落下中.
			_label.text = "F"
			_velocity_y += GRAVITY_Y	
			_now_y += _velocity_y
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
	
	#_label.text += " X:%3.2f Y:%3.2f"%[_now_x, _now_y]
