# ===========================
# 整数値のベクトル.
# ===========================

# ----------------------------------------
# 定数.
# ----------------------------------------
const INVALID = -1 # 負の値を無効とする.

# ----------------------------------------
# メンバ変数.
# ----------------------------------------
var x:int = 0
var y:int = 0

# ----------------------------------------
# メンバ関数.
# ----------------------------------------
# コンストラクタ.
func _init(_x:int=0, _y:int=0) -> void:
	set_xy(_x, _y)
	
# xyを設定.
func set_xy(_x:int, _y:int) -> void:
	x = _x
	y = _y

# コピー
func copy(src) -> void:
	set_xy(src.x, src.y)

# リセット.
func reset() -> void:
	# 無効な値にする.
	set_xy(INVALID, INVALID)

# 値が同じかどうか.
func equal(src) -> bool:
	return x == src.x and y == src.y

# 値が有効かどうか.
func is_valid() -> bool:
	return x !=INVALID and y != INVALID

# 近くかどうか.
func is_close(src) -> bool:
	var d = abs(x - src.x)
	d += abs(y - src.y)
	return d == 1
