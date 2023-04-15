extends Node

var _sound:AudioStreamPlayer

## セットアップ.
func setup(sound:AudioStreamPlayer) -> void:
	_sound = sound

## SEの再生.
func play_sound(pitch:float = 1.0) -> void:
	_sound.pitch_scale = pitch
	_sound.play()
