extends Area2D

class_name TileObj

const Array2 = preload("res://Array2.gd")
const TILE_SIZE = 32

# 重力加速度.
const GRAVITY_Y = 0.1

# 消滅時間.
const TIMER_VANISH = 1.0

enum eTile {
	NONE = 0 # 無効なタイルID
}

enum eState {
	HIDE, # 非表示.
	FALLING, # 落下中.
	STANDBY, # 待機中.
	VANISH, # 消滅演出中.
}

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

onready var _rect = $ColorRect
onready var _label = $Label

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

func appear(id:int, px:float, py:float) -> void:
	# IDを設定.
	set_id(id)
	
	_now_x = px
	_now_y = py
	
	_state = eState.FALLING
	visible = true

# 落下チェック.
func _check_fall() -> bool:
	if FieldMgr.check_hit_bottom(self) == false:
		return false
	return true	

func check_hit_bottom(tile:TileObj) -> bool:
	if _now_x != tile._now_x:
		return false
	
	var bottom = _now_x + TILE_SIZE/2.0
	var upper = tile._now_x - TILE_SIZE/2.0
	if bottom <= upper:
		return false
	return true

func to_world(x:float, y:float) -> Vector2:
	# タイル座標系をワールド座標に変換する.
	var px = FieldMgr.OFS_X + TILE_SIZE * x
	var py = FieldMgr.OFS_Y + TILE_SIZE * y
	return Vector2(px, py)

func fit_grid() -> void:
	_now_x = int(_now_x / TILE_SIZE) * TILE_SIZE
	_now_y = int(_now_y / TILE_SIZE) * TILE_SIZE

func is_hide() -> bool:
	return _state == eState.HIDE

func start_vanish() -> void:
	_state = eState.VANISH
	_timer = TIMER_VANISH

func _ready() -> void:
	set_id(eTile.NONE)
	visible = false

func _process(delta: float) -> void:
	if _id == eTile.NONE:
		visible = false
		return
	
	# タイル座標系をワールド座標系に変換.
	position = to_world(_now_x, _now_y)
	
	_label.text = "%d"%_id
	
	match _state:
		eState.HIDE: # 非表示.
			visible = false
		eState.FALLING: # 落下中.

			_velocity_y += GRAVITY_Y	
			_now_y += _velocity_y
			if FieldMgr.check_hit_bottom(self):
				# 移動完了.
				fit_grid()
				_state = eState.STANDBY
		eState.STANDBY:
			pass
		eState.VANISH:
			_timer -= delta
			visible = true
			if fmod(_timer, 0.2) < 0.1:
				visible = false
			if _timer < 0:
				_state = eState.HIDE
