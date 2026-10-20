class_name PlayerInput
extends Node

## What the player is told to do on each physics frame: where to run, what Jump does and what
## Crucifix does. This one reads the keyboard, the mouse and the gamepad through the Input Map, and
## it is the only place that reads them for the player. An AI, a cutscene or a test drives the
## player by putting a node that extends this one in the player's input.


## -1 to run left, 1 to run right, 0 to stand.
func get_run_direction() -> float:
	return signf(Input.get_axis(&"move_left", &"move_right"))


## True on the physics frame Jump is pressed.
func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"jump")


## True while Jump is held.
func is_jump_held() -> bool:
	return Input.is_action_pressed(&"jump")


## True on the physics frame Crucifix is pressed: only a press raises the crucifix.
func is_crucifix_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"crucifix")


## True while Crucifix is held: the crucifix stays up only while it is.
func is_crucifix_held() -> bool:
	return Input.is_action_pressed(&"crucifix")
