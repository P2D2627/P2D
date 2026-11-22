# Checks the autoload LastDevice, which says whether the player last used the keyboard or a gamepad,
# so the prompts show that device's keys. Only what would work an action counts: a key, mouse
# button or pad button pressed on an action, or a stick or trigger pushed past that action's dead
# zone; echoes, releases, mouse motion, unbound keys and a stick resting under the dead zone change
# nothing. It hears every event, also while paused and when a node marks it handled. Connecting a
# pad switches to it; disconnecting the pad used last goes back to the keyboard, and another pad
# going away changes nothing. A pad left on in the background moves nothing in the game.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_last_device.gd
extends "res://tests/support/base_test.gd"

const IGNORE_UNFOCUSED_PADS: String = "input_devices/joypads/ignore_joypad_on_unfocused_application"
## A key no action has, on the keyboard of every profile.
const UNBOUND_KEY: Key = KEY_F20
## Pads the cases connect and press on; headless runs have none, so the cases only fake them.
const PAD: int = 3
const OTHER_PAD: int = 5
## How far past or short of an action's dead zone the stick is pushed.
const DEAD_ZONE_STEP: float = 0.05


## A node that marks every event as handled in its _input, as a menu might.
class Swallower extends Node:
	func _input(_event: InputEvent) -> void:
		get_viewport().set_input_as_handled()


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_the_autoload_starts_on_the_keyboard())
	results.append(_presses_on_an_action_count())
	results.append(_what_works_no_action_does_not_count())
	results.append(_a_stick_counts_from_the_action_s_dead_zone())
	results.append(await _the_device_touched_last_wins())
	results.append(await _it_hears_events_while_paused_and_handled())
	results.append(await _connecting_a_pad_switches_and_disconnecting_it_goes_back())
	results.append(await _the_pad_used_last_is_the_one_whose_going_counts())
	results.append(_the_project_ignores_pads_while_unfocused())
	results.append(_a_pad_s_family_comes_from_its_name_or_the_option())
	results.append(_every_part_of_every_family_has_its_picture())
	quit(1 if results.has(false) else 0)


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Pads are told apart by their names: "xbox" first, as an Xbox Wireless Controller also has Sony's
## own name for a DualShock 4 in it; an unknown name is Xbox. With no pad, on Automatic, the family
## is Xbox; the Gamepad buttons option overrides it. Jump's button, the bottom one, is named Cross on
## a PlayStation pad, B on a Switch pad, where the letters go the other way, and A on the others.
func _a_pad_s_family_comes_from_its_name_or_the_option() -> bool:
	var expected: Dictionary[String, GameLastDevice.PadFamily] = {
		"PS4 Controller": GameLastDevice.PadFamily.PLAYSTATION,
		"PS5 Controller": GameLastDevice.PadFamily.PLAYSTATION,
		"Wireless Controller": GameLastDevice.PadFamily.PLAYSTATION,
		"Xbox Wireless Controller": GameLastDevice.PadFamily.XBOX,
		"XInput Controller": GameLastDevice.PadFamily.XBOX,
		"Nintendo Switch Pro Controller": GameLastDevice.PadFamily.NINTENDO,
		"Steam Deck": GameLastDevice.PadFamily.STEAM_DECK,
		"Generic USB Joystick": GameLastDevice.PadFamily.XBOX,
		"": GameLastDevice.PadFamily.XBOX,
	}
	var wrong: Array[String] = []
	for pad_name: String in expected:
		var family: GameLastDevice.PadFamily = GameLastDevice.family_of_name(pad_name)
		if family != expected[pad_name]:
			wrong.append("%s as %s" % [pad_name, GameLastDevice.PadFamily.find_key(family)])
	var last: GameLastDevice = _last_device()
	var settings: GameSettings = root.get_node(^"Settings") as GameSettings
	var auto: GameLastDevice.PadFamily = last.get_pad_family()
	settings.set_pad_buttons(GameSettings.PAD_BUTTONS_NINTENDO)
	var forced: GameLastDevice.PadFamily = last.get_pad_family()
	settings.set_pad_buttons(GameSettings.PAD_BUTTONS_AUTO)
	var jump: Array[String] = []
	for family: GameLastDevice.PadFamily in GameLastDevice.PadFamily.values():
		jump.append(PromptGlyph.pad_text(&"jump", family))
	return _report(wrong.is_empty() and auto == GameLastDevice.PadFamily.XBOX
			and forced == GameLastDevice.PadFamily.NINTENDO and jump == ["A", "Cross", "B", "A"],
			("Pad names read wrong %s; with no pad on Automatic %s, on Nintendo Switch %s; Jump named %s "
			+ "on Xbox, PlayStation, Switch and Steam Deck pads (expected [A, Cross, B, A])")
			% [wrong, GameLastDevice.PadFamily.find_key(auto),
			GameLastDevice.PadFamily.find_key(forced), jump])


## Every button, stick way and trigger PromptGlyph names has its picture in Kenney's pack, on every
## family, but a PlayStation pad's PS button, which the pack does not draw.
func _every_part_of_every_family_has_its_picture() -> bool:
	var parts: Array[String] = []
	parts.append_array(PromptGlyph.BUTTON_PARTS.values())
	for ways: Array in PromptGlyph.AXIS_PARTS.values():
		for way: String in ways:
			if way not in parts:
				parts.append(way)
	var missing: Array[String] = []
	for family: GameLastDevice.PadFamily in GameLastDevice.PadFamily.values():
		for part: String in parts:
			var looks: Array = PromptGlyph._looks_of(part, family)
			var path: String = (PromptGlyph.ICON_PATH % [PromptGlyph.FAMILY_FOLDERS[family], looks[1]]
					if not looks.is_empty() and not (looks[1] as String).is_empty() else "")
			if path.is_empty() or not ResourceLoader.exists(path):
				missing.append("%s %s" % [GameLastDevice.PadFamily.find_key(family), part])
	return _report(missing == ["PLAYSTATION guide"],
			"Parts without a picture %s (expected only [PLAYSTATION guide])" % [missing])


func _last_device() -> GameLastDevice:
	return root.get_node_or_null(^"LastDevice") as GameLastDevice


func _the_autoload_starts_on_the_keyboard() -> bool:
	var last: GameLastDevice = _last_device()
	var device: int = last.get_device() if last != null else GameLastDevice.Device.NONE
	return _report(last != null and device == GameLastDevice.Device.KEYBOARD,
			"Autoload LastDevice there %s, starting on %s (no pad connected)"
			% [last != null, GameLastDevice.Device.find_key(device)])


func _presses_on_an_action_count() -> bool:
	var click: InputEventMouseButton = _mouse_button(MOUSE_BUTTON_LEFT)
	var bound_click: InputEventMouseButton = _mouse_button(MOUSE_BUTTON_LEFT)
	InputMap.action_add_event(&"interact", bound_click)
	var found: Array = [
		GameLastDevice.device_of(_key(KEY_SPACE)),
		GameLastDevice.device_of(_pad_button(JOY_BUTTON_A)),
		GameLastDevice.device_of(click),
	]
	InputMap.action_erase_event(&"interact", bound_click)
	var expected: Array = [GameLastDevice.Device.KEYBOARD, GameLastDevice.Device.PAD,
			GameLastDevice.Device.KEYBOARD]
	return _report(found == expected,
			"Space, pad A and a click bound to Interact count as %s (expected %s)"
			% [_names(found), _names(expected)])


func _what_works_no_action_does_not_count() -> bool:
	var found: Array = [
		GameLastDevice.device_of(_key(KEY_SPACE, true, true)),
		GameLastDevice.device_of(_key(KEY_SPACE, false)),
		GameLastDevice.device_of(_key(UNBOUND_KEY)),
		GameLastDevice.device_of(_pad_button(JOY_BUTTON_A, false)),
		GameLastDevice.device_of(_mouse_button(MOUSE_BUTTON_LEFT)),
		GameLastDevice.device_of(InputEventMouseMotion.new()),
		GameLastDevice.device_of(_touch()),
	]
	var none: int = GameLastDevice.Device.NONE
	return _report(found == [none, none, none, none, none, none, none],
			"Echo, release, F20, pad release, unbound click, mouse motion, touch: %s (expected all NONE)"
			% [_names(found)])


func _a_stick_counts_from_the_action_s_dead_zone() -> bool:
	var dead_zone: float = InputMap.action_get_deadzone(&"move_left")
	var past: int = GameLastDevice.device_of(
			_pad_axis(JOY_AXIS_LEFT_X, -(dead_zone + DEAD_ZONE_STEP)))
	var short: int = GameLastDevice.device_of(
			_pad_axis(JOY_AXIS_LEFT_X, -(dead_zone - DEAD_ZONE_STEP)))
	var trigger: int = GameLastDevice.device_of(_pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	return _report(past == GameLastDevice.Device.PAD and short == GameLastDevice.Device.NONE
			and trigger == GameLastDevice.Device.PAD,
			"Left stick past Move Left's dead zone %.2f: %s; short of it: %s; RT: %s"
			% [dead_zone, _names([past]), _names([short]), _names([trigger])])


## Through Input, as the game gets them: the pad, then the keyboard, then the keyboard again.
func _the_device_touched_last_wins() -> bool:
	var last: GameLastDevice = _last_device()
	await _press(_key(KEY_SPACE))
	var changes: Array[int] = []
	var count_change: Callable = func(device: GameLastDevice.Device) -> void: changes.append(device)
	last.device_changed.connect(count_change)
	await _press(_pad_button(JOY_BUTTON_A))
	var after_pad: int = last.get_device()
	await _press(_key(KEY_SPACE))
	var after_key: int = last.get_device()
	await _press(_key(KEY_SPACE))
	last.device_changed.disconnect(count_change)
	var expected: Array[int] = [GameLastDevice.Device.PAD, GameLastDevice.Device.KEYBOARD]
	return _report(after_pad == GameLastDevice.Device.PAD
			and after_key == GameLastDevice.Device.KEYBOARD and changes == expected,
			"Pad A, then Space, then Space: %s, %s; signal with %s (expected %s)"
			% [_names([after_pad]), _names([after_key]), _names(changes), _names(expected)])


## With the game paused and a node taking every event in its _input, a pad press still counts.
func _it_hears_events_while_paused_and_handled() -> bool:
	var last: GameLastDevice = _last_device()
	await _press(_key(KEY_SPACE))
	var swallower: Swallower = Swallower.new()
	swallower.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(swallower)
	paused = true
	await _press(_pad_button(JOY_BUTTON_A))
	var device: int = last.get_device()
	paused = false
	swallower.queue_free()
	await process_frame
	return _report(device == GameLastDevice.Device.PAD,
			"Pad A while paused and handled by a node's _input: %s (expected PAD)" % _names([device]))


func _connecting_a_pad_switches_and_disconnecting_it_goes_back() -> bool:
	var last: GameLastDevice = _last_device()
	await _press(_key(KEY_SPACE))
	Input.joy_connection_changed.emit(PAD, true)
	var connected: int = last.get_device()
	Input.joy_connection_changed.emit(PAD, false)
	var disconnected: int = last.get_device()
	return _report(connected == GameLastDevice.Device.PAD
			and disconnected == GameLastDevice.Device.KEYBOARD,
			"Pad connected: %s; disconnected: %s" % [_names([connected]), _names([disconnected])])


## Two pads: the one pressed last is the one whose going sends the prompts back to the keyboard.
func _the_pad_used_last_is_the_one_whose_going_counts() -> bool:
	var last: GameLastDevice = _last_device()
	await _press(_key(KEY_SPACE))
	Input.joy_connection_changed.emit(PAD, true)
	Input.joy_connection_changed.emit(OTHER_PAD, true)
	await _press(_pad_button(JOY_BUTTON_A, true, PAD))
	Input.joy_connection_changed.emit(OTHER_PAD, false)
	var other_gone: int = last.get_device()
	Input.joy_connection_changed.emit(PAD, false)
	var used_gone: int = last.get_device()
	return _report(other_gone == GameLastDevice.Device.PAD
			and used_gone == GameLastDevice.Device.KEYBOARD,
			"Pad %d used, pad %d unplugged: %s; pad %d unplugged: %s (expected PAD, KEYBOARD)"
			% [PAD, OTHER_PAD, _names([other_gone]), PAD, _names([used_gone])])


## Only the project's setting: no pad can be made to send events to an unfocused window here.
func _the_project_ignores_pads_while_unfocused() -> bool:
	var ignored: bool = ProjectSettings.get_setting(IGNORE_UNFOCUSED_PADS, false)
	return _report(ignored, "%s on: %s" % [IGNORE_UNFOCUSED_PADS, ignored])


## Sends a press and its release through Input, and waits until both reached the window.
func _press(event: InputEvent) -> void:
	Input.parse_input_event(event)
	var release: InputEvent = event.duplicate()
	release.set(&"pressed", false)
	Input.parse_input_event(release)
	await process_frame
	await process_frame


static func _names(devices: Array) -> Array[String]:
	var names: Array[String] = []
	for device: int in devices:
		names.append(str(GameLastDevice.Device.find_key(device)))
	return names


static func _key(keycode: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	return event


static func _mouse_button(index: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = true
	return event


static func _pad_button(index: JoyButton, pressed: bool = true, pad: int = 0) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	event.device = pad
	return event


static func _pad_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


static func _touch() -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.pressed = true
	return event
