# Checks which keys the game's balloon lets through while it shows. The game's own keys stay with
# it, so the man does not jump or interact under the lines: Jump (Space) and Interact (E) reach
# nothing behind it. Pause (Esc) and the debug keys go through, so the game can be paused, and the
# debug overlay shown, in the middle of a talk: Esc, F3 and F4 reach a node behind it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_balloon_input.gd
extends "res://tests/support/player_test.gd"

const BALLOON_SCENE: PackedScene = preload("res://scenes/screens/dialogue_balloon.tscn")
const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
## Frames to wait for the first line.
const LINE_FRAMES: int = 60
const THROUGH: Array[StringName] = [&"pause", &"toggle_debug_overlay", &"debug_damage"]
const BLOCKED: Array[StringName] = [&"jump", &"interact"]


func _initialize() -> void:
	await process_frame
	var behind: ActionCounter = ActionCounter.new()
	root.add_child(behind)
	var balloon: DialogueBalloon = BALLOON_SCENE.instantiate()
	balloon.next_action = &"jump"
	balloon.skip_action = &"jump"
	root.add_child(balloon)
	balloon.start(LUST, "asmodeus_offer")
	await wait_until(func() -> bool: return balloon.dialogue_line != null, LINE_FRAMES)
	for action: StringName in THROUGH + BLOCKED:
		await _tap(action)
	var through: bool = true
	for action: StringName in THROUGH:
		through = through and behind.presses.get(action, 0) == 1
	var blocked: bool = true
	for action: StringName in BLOCKED:
		blocked = blocked and behind.presses.get(action, 0) == 0
	var heard: String = str(behind.presses)
	balloon.queue_free()
	behind.queue_free()
	await wait_frames(2)
	finish([report(through and blocked,
			"Behind the balloon: %s; Esc, F3 and F4 go through %s, Jump and Interact stay %s"
			% [heard, through, blocked])])


## A press and a release of the first key of action, as the keyboard sends them.
func _tap(action: StringName) -> void:
	var key: InputEventKey = InputMap.action_get_events(action)[0] as InputEventKey
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = key.physical_keycode
		event.keycode = key.keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		await wait_frames(2)


## Counts the presses of each action that reach it unhandled.
class ActionCounter extends Node:
	var presses: Dictionary[StringName, int] = {}

	func _unhandled_input(event: InputEvent) -> void:
		for action: StringName in THROUGH + BLOCKED:
			if event.is_action_pressed(action):
				presses[action] = presses.get(action, 0) + 1
