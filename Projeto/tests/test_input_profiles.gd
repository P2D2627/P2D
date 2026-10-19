# Checks the controls profiles in Settings and the Input Map. The default profile is the Input Map in
# project.godot, read from the project settings, so the two never differ. Arrows and QWEASD moves
# with the arrows only, jumps with Space, raises the crucifix with Q, interacts with Ctrl and leaves
# W, E, A, S and D free. Every profile keeps the gamepad's buttons. The custom profile starts as a
# copy of the default one; remapping an action leaves it that one binding, and a binding another
# action had swaps over, so no action is left without one. Reserved keys (Esc, F3, F4), bindings
# not on offer, and remapping outside the custom profile change nothing. The file keeps the profile
# by its id and each binding as readable text, and both read back the same; a profile or bindings
# in the file that are not on offer give the defaults. Every key and mouse button on offer reads
# back from its name as itself. Reset brings the custom profile back to the default one, and the
# options' own Reset leaves the controls alone. The tests use a settings node of their own, with a
# file of their own, and never touch the player's file. Setting a binding that is not on offer
# prints an ERROR, which is expected.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_input_profiles.gd
extends "res://tests/support/player_test.gd"

const SETTINGS_SCRIPT: GDScript = preload("res://core/settings.gd")
const TEST_PATH: String = "user://test_input_profiles.cfg"
## Keys whose names are checked to read back as the same key: letters, arrows, modifiers, function
## keys, the keypad and punctuation.
const KEYS_TO_READ_BACK: Array[Key] = [
	KEY_A, KEY_Q, KEY_LEFT, KEY_UP, KEY_SPACE, KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_TAB, KEY_ENTER,
	KEY_F5, KEY_KP_ENTER, KEY_KP_5, KEY_SEMICOLON, KEY_BRACKETLEFT, KEY_1,
]


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(await _the_default_profile_is_project_godots_input_map())
	results.append(await _arrows_and_qweasd_moves_with_the_arrows_and_raises_with_q())
	results.append(await _every_profile_keeps_the_gamepad())
	results.append(await _custom_starts_as_the_default_and_remaps_one_action())
	results.append(await _a_binding_another_action_had_swaps_over())
	results.append(await _reserved_keys_and_remaps_outside_custom_change_nothing())
	results.append(await _the_file_keeps_ids_and_readable_bindings_that_read_back())
	results.append(await _wrong_values_in_the_file_give_the_defaults())
	results.append(_every_key_and_mouse_button_reads_back_from_its_name())
	results.append(await _reset_brings_custom_back_and_the_options_reset_leaves_it())
	await _back_to_the_default_controls()
	_delete_test_file()
	finish(results)


## The Input Map's keys and mouse buttons, with the default profile on, are those project.godot
## saved for each action, read from the project settings here, not written out again.
func _the_default_profile_is_project_godots_input_map() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var profile: StringName = settings.get_input_profile()
	var wrong: PackedStringArray = []
	var bindings_found: int = 0
	for action: StringName in InputProfiles.ACTIONS:
		var saved: PackedStringArray = []
		var setting: Dictionary = ProjectSettings.get_setting("input/%s" % action, {})
		for event: InputEvent in setting.get("events", []):
			var binding: String = InputProfiles.binding_from_event(event)
			if not binding.is_empty():
				saved.append(binding)
		bindings_found += saved.size()
		if _sorted(saved) != _sorted(_map_bindings(action)):
			wrong.append("%s %s" % [action, _map_bindings(action)])
	settings.queue_free()
	return report(profile == InputProfiles.KEYBOARD_AND_MOUSE and bindings_found > 0
			and wrong.is_empty(),
			"The default profile: %s, %d bindings in project.godot, Input Map differs in %s"
			% [profile, bindings_found, wrong])


func _arrows_and_qweasd_moves_with_the_arrows_and_raises_with_q() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_input_profile(InputProfiles.ARROWS_AND_QWEASD)
	var wrong: PackedStringArray = _differences({
		&"move_left": [KEY_LEFT], &"move_right": [KEY_RIGHT],
		&"move_up": [KEY_UP], &"move_down": [KEY_DOWN],
		&"jump": [KEY_SPACE], &"crucifix": [KEY_Q], &"interact": [KEY_CTRL],
	})
	var taken: PackedStringArray = []
	for key: Key in [KEY_W, KEY_E, KEY_A, KEY_S, KEY_D]:
		for action: StringName in InputProfiles.ACTIONS:
			if InputProfiles.key(key) in _map_bindings(action):
				taken.append("%s on %s" % [OS.get_keycode_string(key), action])
	settings.queue_free()
	return report(wrong.is_empty() and taken.is_empty(),
			"Arrows and QWEASD: Input Map differs in %s; W, E, A, S and D taken: %s"
			% [wrong, taken])


## The gamepad's events of every action are the same in all three profiles.
func _every_profile_keeps_the_gamepad() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var before: Dictionary = _gamepad_events()
	var same: Array[bool] = []
	for profile: StringName in [InputProfiles.ARROWS_AND_QWEASD, InputProfiles.CUSTOM,
			InputProfiles.KEYBOARD_AND_MOUSE]:
		settings.set_input_profile(profile)
		same.append(_gamepad_events() == before)
	settings.queue_free()
	return report(not same.has(false) and not before.is_empty(),
			"The gamepad in every profile: the same %s" % [same])


func _custom_starts_as_the_default_and_remaps_one_action() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var defaults: Dictionary[StringName, PackedStringArray] = {}
	for action: StringName in InputProfiles.ACTIONS:
		defaults[action] = settings.get_bindings(action)
	settings.set_input_profile(InputProfiles.CUSTOM)
	var starts_as_default: bool = true
	for action: StringName in InputProfiles.ACTIONS:
		starts_as_default = starts_as_default and settings.get_bindings(action) == defaults[action]
	settings.set_custom_binding(&"move_left", InputProfiles.key(KEY_J))
	var wrong: PackedStringArray = _differences({&"move_left": [KEY_J], &"jump": [KEY_SPACE]})
	settings.queue_free()
	return report(starts_as_default and wrong.is_empty(),
			"Custom: starts as the default %s; after Move left to J, Input Map differs in %s"
			% [starts_as_default, wrong])


## Jump to E, which Interact had alone: Interact takes Space, Jump's old key. Move left to D, which
## Move right shared with the right arrow: Move right keeps the right arrow only.
func _a_binding_another_action_had_swaps_over() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_input_profile(InputProfiles.CUSTOM)
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_E))
	settings.set_custom_binding(&"move_left", InputProfiles.key(KEY_D))
	var wrong: PackedStringArray = _differences({
		&"jump": [KEY_E], &"interact": [KEY_SPACE],
		&"move_left": [KEY_D], &"move_right": [KEY_RIGHT],
	})
	settings.queue_free()
	return report(wrong.is_empty(), "Swaps: Input Map differs in %s" % [wrong])


func _reserved_keys_and_remaps_outside_custom_change_nothing() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_J))
	var outside_custom: PackedStringArray = _differences({&"jump": [KEY_SPACE]})
	settings.set_input_profile(InputProfiles.CUSTOM)
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_ESCAPE))
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_F3))
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_F4))
	settings.set_custom_binding(&"jump", "mouse:wheel")
	settings.set_custom_binding(&"jump", "rubbish")
	var not_on_offer: PackedStringArray = _differences({&"jump": [KEY_SPACE]})
	var esc_event: InputEventKey = InputEventKey.new()
	esc_event.physical_keycode = KEY_ESCAPE
	var esc_as_binding: String = InputProfiles.binding_from_event(esc_event)
	settings.queue_free()
	return report(outside_custom.is_empty() and not_on_offer.is_empty()
			and esc_as_binding.is_empty(),
			"Nothing changes: outside custom differs in %s, not on offer differs in %s, Esc as a binding '%s'"
			% [outside_custom, not_on_offer, esc_as_binding])


## The file holds the profile's id and the bindings as text, such as "key:J" and "mouse:right", and
## a new settings node reads them back the same.
func _the_file_keeps_ids_and_readable_bindings_that_read_back() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_input_profile(InputProfiles.CUSTOM)
	settings.set_custom_binding(&"crucifix", InputProfiles.mouse(MOUSE_BUTTON_RIGHT))
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_J))
	settings.queue_free()
	var file: ConfigFile = ConfigFile.new()
	file.load(TEST_PATH)
	var in_file: Array = [file.get_value("input", "profile"),
			file.get_value("input_custom", "crucifix"), file.get_value("input_custom", "jump")]
	var expected_in_file: Array = ["custom", PackedStringArray(["mouse:right"]),
			PackedStringArray(["key:J"])]
	await _back_to_the_default_controls()
	var again: GameSettings = await _new_settings()
	var profile: StringName = again.get_input_profile()
	var wrong: PackedStringArray = _differences({
		&"crucifix": [MOUSE_BUTTON_RIGHT], &"jump": [KEY_J],
	})
	again.queue_free()
	return report(in_file == expected_in_file and profile == InputProfiles.CUSTOM
			and wrong.is_empty(),
			"The file: holds %s; read back, profile %s, Input Map differs in %s"
			% [in_file, profile, wrong])


func _wrong_values_in_the_file_give_the_defaults() -> bool:
	var outcomes: PackedStringArray = []
	var all_right: bool = true
	for profile_value: Variant in [99, "no_such_profile", 1.5]:
		_delete_test_file()
		var file: ConfigFile = ConfigFile.new()
		file.set_value("input", "profile", profile_value)
		file.set_value("input_custom", "jump", PackedStringArray(["rubbish", "key:Escape"]))
		file.set_value("input_custom", "crucifix", "not a list")
		file.save(TEST_PATH)
		var settings: GameSettings = await _new_settings()
		var profile: StringName = settings.get_input_profile()
		var default_crucifix: PackedStringArray = settings.get_bindings(&"crucifix")
		settings.set_input_profile(InputProfiles.CUSTOM)
		var custom_is_default: bool = settings.get_bindings(&"crucifix") == default_crucifix \
				and settings.get_bindings(&"jump") == PackedStringArray([InputProfiles.key(KEY_SPACE)])
		settings.queue_free()
		var right: bool = profile == InputProfiles.DEFAULT_PROFILE and custom_is_default
		all_right = all_right and right
		outcomes.append("%s gives %s, custom the default %s" % [profile_value, profile,
				custom_is_default])
	return report(all_right, "Wrong values in the file: %s" % ", ".join(outcomes))


## Each key in KEYS_TO_READ_BACK and each mouse button on offer makes a binding whose name reads back
## as itself, both ways: from an event to a binding and from the binding to an event.
func _every_key_and_mouse_button_reads_back_from_its_name() -> bool:
	var wrong: PackedStringArray = []
	for key: Key in KEYS_TO_READ_BACK:
		var key_event: InputEventKey = InputEventKey.new()
		key_event.physical_keycode = key
		var binding: String = InputProfiles.binding_from_event(key_event)
		var back: InputEventKey = InputProfiles.event_from_binding(binding) as InputEventKey
		if back == null or back.physical_keycode != key:
			wrong.append("%s as '%s'" % [OS.get_keycode_string(key), binding])
	for button: MouseButton in InputProfiles.MOUSE_BUTTONS:
		var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
		mouse_event.button_index = button
		var binding: String = InputProfiles.binding_from_event(mouse_event)
		var back: InputEventMouseButton = InputProfiles.event_from_binding(binding) \
				as InputEventMouseButton
		if back == null or back.button_index != button:
			wrong.append("mouse button %d as '%s'" % [button, binding])
	return report(wrong.is_empty(),
			"Names that read back: %d keys and %d mouse buttons, wrong: %s"
			% [KEYS_TO_READ_BACK.size(), InputProfiles.MOUSE_BUTTONS.size(), wrong])


func _reset_brings_custom_back_and_the_options_reset_leaves_it() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_input_profile(InputProfiles.CUSTOM)
	settings.set_custom_binding(&"jump", InputProfiles.key(KEY_J))
	settings.reset_to_defaults()
	var kept: PackedStringArray = _differences({&"jump": [KEY_J]})
	var profile_kept: bool = settings.get_input_profile() == InputProfiles.CUSTOM
	settings.reset_custom_bindings()
	var back: PackedStringArray = _differences({&"jump": [KEY_SPACE]})
	settings.queue_free()
	return report(kept.is_empty() and profile_kept and back.is_empty(),
			"Resets: the options' Reset keeps custom %s and its bindings (differs in %s); Reset custom brings back the default (differs in %s)"
			% [profile_kept, kept, back])


## For each action, its keys and mouse buttons in the Input Map against those expected, a key as a
## Key and a mouse button as a MouseButton; the actions that differ, with what the Input Map has.
func _differences(expected: Dictionary) -> PackedStringArray:
	var wrong: PackedStringArray = []
	for action: StringName in expected:
		var wanted: PackedStringArray = []
		for code: int in expected[action]:
			# No key's code is a mouse button's: the lowest, Space, is 32.
			wanted.append(InputProfiles.mouse(code as MouseButton)
					if code in InputProfiles.MOUSE_BUTTONS else InputProfiles.key(code as Key))
		if _sorted(wanted) != _sorted(_map_bindings(action)):
			wrong.append("%s %s" % [action, _map_bindings(action)])
	return wrong


## The keys and mouse buttons the Input Map has for action, as bindings.
func _map_bindings(action: StringName) -> PackedStringArray:
	var found: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if InputProfiles.is_profile_event(event):
			found.append(InputProfiles.binding_from_event(event))
	return found


func _sorted(bindings: PackedStringArray) -> PackedStringArray:
	var copy: PackedStringArray = bindings.duplicate()
	copy.sort()
	return copy


## The gamepad's events of every action the profiles set, as text, by action.
func _gamepad_events() -> Dictionary:
	var events: Dictionary = {}
	for action: StringName in InputProfiles.ACTIONS:
		var texts: PackedStringArray = []
		for event: InputEvent in InputMap.action_get_events(action):
			if not InputProfiles.is_profile_event(event):
				texts.append(event.as_text())
		events[action] = texts
	return events


func _new_settings() -> GameSettings:
	var settings: GameSettings = SETTINGS_SCRIPT.new() as GameSettings
	settings.path = TEST_PATH
	root.add_child(settings)
	await process_frame
	return settings


## Puts the default profile back in the Input Map, with a settings node that keeps to memory, so
## the next case, and the autoload, start from it.
func _back_to_the_default_controls() -> void:
	var settings: GameSettings = SETTINGS_SCRIPT.new() as GameSettings
	settings.path = ""
	root.add_child(settings)
	await process_frame
	settings.set_input_profile(InputProfiles.DEFAULT_PROFILE)
	settings.queue_free()
	await process_frame


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
