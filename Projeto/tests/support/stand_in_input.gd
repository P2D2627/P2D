# A PlayerInput a test drives by hand: it never reads the keyboard, the mouse or the gamepad, only
# what the test sets. The tests reach it through player_test.gd, as StandInInput, and put it on a
# player with put_a_stand_in().
extends PlayerInput

## What a press frame holds before the first press.
const NO_PRESS: int = -1

var run_direction: float = 0.0
var hold_jump: bool = false
## Whether Crucifix is held. Setting it from false to true is a press: Crucifix counts as just
## pressed for the whole of that physics frame, as on the keyboard.
var crucifix_held: bool = false:
	set(value):
		if value and not crucifix_held:
			_crucifix_press_frame = Engine.get_physics_frames()
		crucifix_held = value

## The physics frame of the last press of Jump.
var _jump_press_frame: int = NO_PRESS
## The physics frame of the last press of Crucifix.
var _crucifix_press_frame: int = NO_PRESS


## Jump counts as just pressed for the whole of the current physics frame, as on the keyboard,
## however many times the player asks in it.
func press_jump() -> void:
	_jump_press_frame = Engine.get_physics_frames()


func get_run_direction() -> float:
	return run_direction


func is_jump_just_pressed() -> bool:
	return Engine.get_physics_frames() == _jump_press_frame


func is_jump_held() -> bool:
	return hold_jump


func is_crucifix_just_pressed() -> bool:
	return Engine.get_physics_frames() == _crucifix_press_frame


func is_crucifix_held() -> bool:
	return crucifix_held
