# Checks the Input Map the game plays with, in the default controls profile: the whole game can be
# played with the keyboard alone or with a gamepad alone. Every play action has a key and a gamepad
# input; the default profile needs no mouse; the gamepad moves with the left stick and the D-pad,
# jumps with A, interacts with X, raises the crucifix with RT and pauses with Start; the keyboard
# raises the crucifix with Shift and interacts with E. Each play action has exactly the inputs of
# the tables below and no others, so a missing key fails, and so does a stray one, such as B, the
# menus' Back. The gamepad's inputs work on any gamepad plugged in, not only the first, and no dead
# zone reaches 1, which would keep a stick from ever counting. No key, button or stick direction
# serves two play actions, so one press never does two things. The menus move with the D-pad and
# the left stick. The D-pad walks, and holding Shift for the crucifix does not stop A from walking
# nor Space from reaching Jump (the raised crucifix then stops the jump itself, test_crucifix).
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_input_map.gd
extends "res://tests/support/player_test.gd"

## The device an Input Map event has when it stands for every gamepad, not one of them.
const ANY_DEVICE: int = -1
## The actions the player uses while playing. The debug actions are not here: they only exist in
## the debug build and have no gamepad input on purpose.
const PLAY_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down", &"jump", &"crucifix", &"interact",
	&"pause",
]
## The gamepad buttons of each play action, all of them and no others (ADR 0063). B stays out of
## every play action: it is the menus' Back, and is kept for the level 5 sword with Y and LT.
const GAMEPAD_BUTTONS: Dictionary[StringName, Array] = {
	&"move_left": [JOY_BUTTON_DPAD_LEFT],
	&"move_right": [JOY_BUTTON_DPAD_RIGHT],
	&"move_up": [JOY_BUTTON_DPAD_UP],
	&"move_down": [JOY_BUTTON_DPAD_DOWN],
	&"jump": [JOY_BUTTON_A],
	&"crucifix": [],
	&"interact": [JOY_BUTTON_X],
	&"pause": [JOY_BUTTON_START],
}
## The stick or trigger directions of each play action, all of them and no others: the axis and the
## sign of its value.
const GAMEPAD_AXES: Dictionary[StringName, Array] = {
	&"move_left": [Vector2i(JOY_AXIS_LEFT_X, -1)],
	&"move_right": [Vector2i(JOY_AXIS_LEFT_X, 1)],
	&"move_up": [Vector2i(JOY_AXIS_LEFT_Y, -1)],
	&"move_down": [Vector2i(JOY_AXIS_LEFT_Y, 1)],
	&"jump": [],
	&"crucifix": [Vector2i(JOY_AXIS_TRIGGER_RIGHT, 1)],
	&"interact": [],
	&"pause": [],
}
## The keys of each play action in the default profile, all of them and no others, by their place
## on the keyboard.
const DEFAULT_KEYS: Dictionary[StringName, Array] = {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"jump": [KEY_SPACE],
	&"crucifix": [KEY_SHIFT],
	&"interact": [KEY_E],
	&"pause": [KEY_ESCAPE],
}
## The menu actions and the D-pad button and stick direction each must have.
const MENU_BUTTONS: Dictionary[StringName, JoyButton] = {
	&"ui_left": JOY_BUTTON_DPAD_LEFT,
	&"ui_right": JOY_BUTTON_DPAD_RIGHT,
	&"ui_up": JOY_BUTTON_DPAD_UP,
	&"ui_down": JOY_BUTTON_DPAD_DOWN,
}
const MENU_AXES: Dictionary[StringName, Vector2i] = {
	&"ui_left": Vector2i(JOY_AXIS_LEFT_X, -1),
	&"ui_right": Vector2i(JOY_AXIS_LEFT_X, 1),
	&"ui_up": Vector2i(JOY_AXIS_LEFT_Y, -1),
	&"ui_down": Vector2i(JOY_AXIS_LEFT_Y, 1),
}


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_every_play_action_has_a_key_and_a_gamepad_input())
	results.append(_the_default_profile_needs_no_mouse())
	results.append(_the_gamepad_has_the_agreed_buttons_and_directions())
	results.append(_the_gamepad_inputs_work_on_any_gamepad())
	results.append(_the_keyboard_has_the_agreed_keys())
	results.append(_no_input_serves_two_play_actions())
	results.append(_the_menus_move_with_the_d_pad_and_the_left_stick())
	results.append(await _the_d_pad_walks_and_keys_still_work_with_shift_held())
	finish(results)


func _every_play_action_has_a_key_and_a_gamepad_input() -> bool:
	var missing: PackedStringArray = []
	for action: StringName in PLAY_ACTIONS:
		var keys: int = 0
		var gamepad: int = 0
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys += 1
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				gamepad += 1
		if keys == 0 or gamepad == 0:
			missing.append("%s (%d keys, %d gamepad)" % [action, keys, gamepad])
	return report(missing.is_empty(),
			"Every play action has a key and a gamepad input; missing in %s" % [missing])


func _the_default_profile_needs_no_mouse() -> bool:
	var with_mouse: PackedStringArray = []
	for action: StringName in PLAY_ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventMouseButton:
				with_mouse.append(action)
	return report(with_mouse.is_empty(),
			"The default profile needs no mouse; mouse buttons on %s" % [with_mouse])


func _the_gamepad_has_the_agreed_buttons_and_directions() -> bool:
	var wrong: PackedStringArray = []
	for action: StringName in PLAY_ACTIONS:
		if _sorted(_buttons_of(action)) != _sorted(GAMEPAD_BUTTONS[action]):
			wrong.append("%s buttons %s, expected %s" % [action, _buttons_of(action),
					GAMEPAD_BUTTONS[action]])
		if _sorted(_axes_of(action)) != _sorted(GAMEPAD_AXES[action]):
			wrong.append("%s axes %s, expected %s" % [action, _axes_of(action),
					GAMEPAD_AXES[action]])
	return report(wrong.is_empty(), "The gamepad bindings; wrong: %s" % [wrong])


func _the_gamepad_inputs_work_on_any_gamepad() -> bool:
	var wrong: PackedStringArray = []
	for action: StringName in PLAY_ACTIONS:
		var deadzone: float = InputMap.action_get_deadzone(action)
		if deadzone >= 1.0:
			wrong.append("%s dead zone %.2f" % [action, deadzone])
		for event: InputEvent in InputMap.action_get_events(action):
			var gamepad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
			if gamepad and event.device != ANY_DEVICE:
				wrong.append("%s only on gamepad %d" % [action, event.device])
	return report(wrong.is_empty(),
			"The gamepad inputs work on any gamepad, with a dead zone under 1; wrong: %s" % [wrong])


func _the_keyboard_has_the_agreed_keys() -> bool:
	var wrong: PackedStringArray = []
	for action: StringName in PLAY_ACTIONS:
		if _sorted(_keys_of(action)) != _sorted(DEFAULT_KEYS[action]):
			wrong.append("%s has %s, expected %s" % [action, _key_names(_keys_of(action)),
					_key_names(DEFAULT_KEYS[action])])
	return report(wrong.is_empty(), "The default keys; wrong: %s" % [wrong])


func _no_input_serves_two_play_actions() -> bool:
	var owners: Dictionary[String, StringName] = {}
	var shared: PackedStringArray = []
	for action: StringName in PLAY_ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			var input: String = _input_name(event)
			if input.is_empty():
				continue
			if owners.has(input) and owners[input] != action:
				shared.append("%s on %s and %s" % [input, owners[input], action])
			owners[input] = action
	return report(shared.is_empty() and not owners.is_empty(),
			"No input serves two play actions (%d inputs); shared: %s" % [owners.size(), shared])


func _the_menus_move_with_the_d_pad_and_the_left_stick() -> bool:
	var missing: PackedStringArray = []
	for action: StringName in MENU_BUTTONS:
		if not _buttons_of(action).has(int(MENU_BUTTONS[action])):
			missing.append("%s D-pad" % action)
		if not _axes_of(action).has(MENU_AXES[action]):
			missing.append("%s stick" % action)
	return report(missing.is_empty(),
			"The menus move with the D-pad and the left stick; missing: %s" % [missing])


func _the_d_pad_walks_and_keys_still_work_with_shift_held() -> bool:
	Input.parse_input_event(_button_event(JOY_BUTTON_DPAD_LEFT, true))
	await process_frame
	var left: float = Input.get_axis(&"move_left", &"move_right")
	Input.parse_input_event(_button_event(JOY_BUTTON_DPAD_LEFT, false))
	Input.parse_input_event(_button_event(JOY_BUTTON_DPAD_RIGHT, true))
	await process_frame
	var right: float = Input.get_axis(&"move_left", &"move_right")
	Input.parse_input_event(_button_event(JOY_BUTTON_DPAD_RIGHT, false))
	await process_frame
	var still: float = Input.get_axis(&"move_left", &"move_right")
	# Shift goes down first and stays down, as when the crucifix is held; A and Space then come
	# with Shift among their modifiers, as the keyboard sends them.
	Input.parse_input_event(_key_event_with_shift(KEY_SHIFT, true))
	await process_frame
	var raised: bool = Input.is_action_pressed(&"crucifix")
	Input.parse_input_event(_key_event_with_shift(KEY_A, true))
	Input.parse_input_event(_key_event_with_shift(KEY_SPACE, true))
	await process_frame
	var walking: bool = is_equal_approx(Input.get_axis(&"move_left", &"move_right"), -1.0)
	var jumping: bool = Input.is_action_pressed(&"jump")
	Input.parse_input_event(_key_event_with_shift(KEY_A, false))
	Input.parse_input_event(_key_event_with_shift(KEY_SPACE, false))
	Input.parse_input_event(_key_event_with_shift(KEY_SHIFT, false))
	await process_frame
	var all_up: bool = (not Input.is_action_pressed(&"jump")
			and not Input.is_action_pressed(&"crucifix")
			and is_zero_approx(Input.get_axis(&"move_left", &"move_right")))
	return report(is_equal_approx(left, -1.0) and is_equal_approx(right, 1.0)
			and is_zero_approx(still) and raised and walking and jumping and all_up,
			("The D-pad walks (left %.1f, right %.1f, let go %.1f); Shift raises %s, with it held "
			+ "A walks %s and Space reaches Jump %s, all let go %s")
			% [left, right, still, raised, walking, jumping, all_up])


## The action's gamepad buttons, as numbers, untyped so it compares with the expected lists.
func _buttons_of(action: StringName) -> Array:
	var buttons: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			buttons.append(int((event as InputEventJoypadButton).button_index))
	return buttons


## The action's stick and trigger directions: the axis and the sign of its value.
func _axes_of(action: StringName) -> Array:
	var axes: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion: InputEventJoypadMotion = event
			axes.append(Vector2i(motion.axis, signi(roundi(motion.axis_value))))
	return axes


## The action's keys, by their place on the keyboard, as numbers.
func _keys_of(action: StringName) -> Array:
	var keys: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event
			keys.append(int(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode))
	return keys


func _key_names(keys: Array) -> PackedStringArray:
	var names: PackedStringArray = []
	for key: int in keys:
		names.append(OS.get_keycode_string(key as Key))
	return names


## A sorted copy, so two lists with the same items compare equal whatever their order.
func _sorted(values: Array) -> Array:
	var copy: Array = values.duplicate()
	copy.sort()
	return copy


## A name for the physical input an event stands for, the same for two events of the same key,
## button or stick direction; empty for other events.
func _input_name(event: InputEvent) -> String:
	if event is InputEventKey:
		var key: InputEventKey = event
		return "key %s" % OS.get_keycode_string(
				key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	if event is InputEventMouseButton:
		return "mouse %d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		return "button %d" % (event as InputEventJoypadButton).button_index
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event
		return "axis %d %+d" % [motion.axis, signi(roundi(motion.axis_value))]
	return ""


func _button_event(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


## A key event with Shift held, as the keyboard sends every key while Shift is down; Shift itself
## comes with Shift among its modifiers when it goes down.
func _key_event_with_shift(key: Key, pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.shift_pressed = pressed or key != KEY_SHIFT
	return event
