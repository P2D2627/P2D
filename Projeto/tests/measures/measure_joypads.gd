# Lists the gamepads the engine sees and tries each one's motors, to check a gamepad and its driver
# before playing with it: each pad's index, name, GUID, the driver's details and whether the engine
# knows its button layout; then the weak motor, the strong motor and both, each at full strength for
# Rumble Time with a pause between, so whoever holds the pad can tell which they felt. Then, for
# Echo Time, it prints each play action pressed and each gamepad button pressed, or stick or trigger
# pushed past Axis Print, with the engine's name for it, so whoever holds the pad can check that
# every button reaches the action the README's table gives it. It checks nothing else: the exit
# code is 1 only if no gamepad is connected. A run with --headless does not read gamepads, so this
# one opens a window while it runs; the echo needs that window focused.
# Run from the repository root:
# godot --path Projeto --script res://tests/measures/measure_joypads.gd
extends "res://tests/support/base_test.gd"

## Frames to wait before asking, so the engine has found the pads plugged in at the start.
const SETTLE_FRAMES: int = 30
## How long each try rumbles, in s.
const RUMBLE_TIME: float = 1.5
## The quiet between two tries, in s.
const PAUSE_TIME: float = 1.0
## Each try's strength, from 0 to 1: the weak motor (x) and the strong one (y).
const TRIES: Array[Vector2] = [Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)]
const TRY_NAMES: Array[String] = ["weak motor", "strong motor", "both motors"]
## How long the echo listens, in s.
const ECHO_TIME: float = 20.0
## The actions the echo prints: the play actions and the menus' Confirm and Back.
const ECHO_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down", &"jump", &"crucifix", &"interact",
	&"pause", &"ui_accept", &"ui_cancel",
]
## How far a stick or trigger must go, from 0 to 1, for the echo to print it.
const AXIS_PRINT: float = 0.5


func _initialize() -> void:
	for frame: int in SETTLE_FRAMES:
		await process_frame
	var pads: Array[int] = Input.get_connected_joypads()
	print("Gamepads connected: %d" % pads.size())
	if pads.is_empty():
		quit(1)
		return
	for device: int in pads:
		print("  %d: %s | GUID %s | known layout: %s | %s" % [device, Input.get_joy_name(device),
				Input.get_joy_guid(device), Input.is_joy_known(device), Input.get_joy_info(device)])
	var wait: Timer = Timer.new()
	wait.one_shot = true
	root.add_child(wait)
	for index: int in TRIES.size():
		for device: int in pads:
			Input.start_joy_vibration(device, TRIES[index].x, TRIES[index].y, RUMBLE_TIME)
			print("Rumble %s for %.1f s on %d: the engine holds %s" % [TRY_NAMES[index], RUMBLE_TIME,
					device, Input.get_joy_vibration_strength(device)])
		wait.start(RUMBLE_TIME + PAUSE_TIME)
		await wait.timeout
	wait.queue_free()
	await _echo()
	quit(0)


func _echo() -> void:
	print("Echo for %.0f s: press each button, and push each stick and trigger" % ECHO_TIME)
	var buttons_down: Dictionary[Vector2i, bool] = {}
	var axes_out: Dictionary[Vector3i, bool] = {}
	var end_msec: int = Time.get_ticks_msec() + roundi(ECHO_TIME * 1000.0)
	while Time.get_ticks_msec() < end_msec:
		await process_frame
		for action: StringName in ECHO_ACTIONS:
			if Input.is_action_just_pressed(action):
				print("  action %s" % action)
		for device: int in Input.get_connected_joypads():
			for index: int in JOY_BUTTON_SDL_MAX:
				var button: JoyButton = index as JoyButton
				var down: bool = Input.is_joy_button_pressed(device, button)
				if down and not buttons_down.get(Vector2i(device, index), false):
					var event: InputEventJoypadButton = InputEventJoypadButton.new()
					event.button_index = button
					print("  %d: %s" % [device, event.as_text()])
				buttons_down[Vector2i(device, index)] = down
			for index: int in JOY_AXIS_SDL_MAX:
				var axis: JoyAxis = index as JoyAxis
				var value: float = Input.get_joy_axis(device, axis)
				for direction: int in [-1, 1]:
					var out: bool = value * direction >= AXIS_PRINT
					if out and not axes_out.get(Vector3i(device, index, direction), false):
						var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
						motion.axis = axis
						motion.axis_value = float(direction)
						print("  %d: %s" % [device, motion.as_text()])
					axes_out[Vector3i(device, index, direction)] = out
