class_name SaveIndicator
extends CanvasLayer

## The word in the corner of the screen that says the game was saved. It only shows: it fades in,
## stays for Hold Time and fades out, also while the game is paused, and knows nothing of the save.

## Seconds it takes to fade in, and again to fade out.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_time: float = 0.25
## Seconds it stays on screen, so it reads even though saving is over at once.
@export_range(0.0, 10.0, 0.1, "suffix:s") var hold_time: float = 1.5

var _tween: Tween = null

@onready var _label: Label = %Label


func _ready() -> void:
	_label.modulate.a = 0.0


## Starts over if it was already showing.
func show_saved() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, ^"modulate:a", 1.0, fade_time)
	_tween.tween_interval(hold_time)
	_tween.tween_property(_label, ^"modulate:a", 0.0, fade_time)


## True while it can be seen, for the tests.
func is_showing() -> bool:
	return _label.modulate.a > 0.0
