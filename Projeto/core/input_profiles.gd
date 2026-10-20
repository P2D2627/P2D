class_name InputProfiles
extends RefCounted

## The keyboard and mouse controls the player can choose from: the default one, which is the Input
## Map in project.godot, the arrows one, made here, and a custom one the player remaps, which starts
## as a copy of the default. Only the keyboard and the mouse change between profiles; the gamepad
## stays as project.godot has it. The settings file keeps a profile by its id and a binding as
## readable text, "key:<key name>" or "mouse:<button name>", such as "key:Q" or "mouse:left", never
## as a number or a whole InputEvent. Settings keeps which profile is on and the custom one's
## bindings, and puts them in the Input Map; this file only knows the profiles and how to read and
## write a binding.

const KEYBOARD_AND_MOUSE: StringName = &"keyboard_and_mouse"
const ARROWS_AND_QWEASD: StringName = &"arrows_and_qweasd"
const CUSTOM: StringName = &"custom"
const DEFAULT_PROFILE: StringName = KEYBOARD_AND_MOUSE
## The profiles, by id, in the order the controls screen lists them, with the name it shows.
const PROFILES: Dictionary[StringName, String] = {
	KEYBOARD_AND_MOUSE: "Keyboard and mouse",
	ARROWS_AND_QWEASD: "Arrows and QWEASD",
	CUSTOM: "Custom",
}
## The actions the profiles set, in the order the controls screen shows them, with the name it
## shows. Pause, the debug overlay and the menus' own actions stay as project.godot has them.
const ACTIONS: Dictionary[StringName, String] = {
	&"move_left": "Move left",
	&"move_right": "Move right",
	&"move_up": "Move up",
	&"move_down": "Move down",
	&"jump": "Jump",
	&"crucifix": "Crucifix",
	&"interact": "Interact",
}
## Keys that can never be remapped to an action: Esc pauses and goes back in the menus, and F3 shows
## the debug overlay.
const RESERVED_KEYS: Array[Key] = [KEY_ESCAPE, KEY_F3]
## The mouse buttons that can be remapped to an action, with the name a binding keeps; the controls
## screen shows "<Name> mouse button". The wheel's steps are not buttons a player holds.
const MOUSE_BUTTONS: Dictionary[MouseButton, String] = {
	MOUSE_BUTTON_LEFT: "left",
	MOUSE_BUTTON_RIGHT: "right",
	MOUSE_BUTTON_MIDDLE: "middle",
	MOUSE_BUTTON_XBUTTON1: "back",
	MOUSE_BUTTON_XBUTTON2: "forward",
}

const _KEY_PREFIX: String = "key:"
const _MOUSE_PREFIX: String = "mouse:"


## The bindings of a profile, by action. The arrows one is made here; any other id gives the
## default one, read from project.godot. The custom profile has no bindings of its own here:
## Settings keeps them, and starts them as a copy of the default.
static func preset(profile: StringName) -> Dictionary[StringName, PackedStringArray]:
	if profile == ARROWS_AND_QWEASD:
		# W, E, A, S and D are left free for the upgrades.
		return {
			&"move_left": PackedStringArray([key(KEY_LEFT)]),
			&"move_right": PackedStringArray([key(KEY_RIGHT)]),
			&"move_up": PackedStringArray([key(KEY_UP)]),
			&"move_down": PackedStringArray([key(KEY_DOWN)]),
			&"jump": PackedStringArray([key(KEY_SPACE)]),
			&"crucifix": PackedStringArray([key(KEY_Q)]),
			&"interact": PackedStringArray([key(KEY_CTRL)]),
		}
	return _project_bindings()


static func key(physical_keycode: Key) -> String:
	return _KEY_PREFIX + OS.get_keycode_string(physical_keycode)


static func mouse(button: MouseButton) -> String:
	return _MOUSE_PREFIX + MOUSE_BUTTONS.get(button, "")


## The binding an event would make: a key by where it is on the keyboard, or a mouse button. Empty
## for anything else, and for a reserved key or a mouse button not on offer.
static func binding_from_event(event: InputEvent) -> String:
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null:
		var keycode: Key = key_event.physical_keycode
		if keycode == KEY_NONE:
			keycode = key_event.keycode
		# Only a key whose name reads back as the same key makes a binding.
		var binding: String = key(keycode)
		var read_back: InputEventKey = event_from_binding(binding) as InputEventKey
		return binding if read_back != null and read_back.physical_keycode == keycode else ""
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and MOUSE_BUTTONS.has(mouse_event.button_index):
		return mouse(mouse_event.button_index)
	return ""


## The Input Map event of a binding; null if the text is not a binding on offer.
static func event_from_binding(binding: String) -> InputEvent:
	if binding.begins_with(_KEY_PREFIX):
		var keycode: Key = OS.find_keycode_from_string(binding.trim_prefix(_KEY_PREFIX))
		if (keycode == KEY_NONE or (keycode & KEY_MODIFIER_MASK) != 0
				or keycode in RESERVED_KEYS):
			return null
		var key_event: InputEventKey = InputEventKey.new()
		key_event.physical_keycode = keycode
		return key_event
	if binding.begins_with(_MOUSE_PREFIX):
		var button_name: String = binding.trim_prefix(_MOUSE_PREFIX)
		if button_name.is_empty() or button_name not in MOUSE_BUTTONS.values():
			return null
		var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTONS.find_key(button_name)
		return mouse_event
	return null


static func is_valid(binding: String) -> bool:
	return event_from_binding(binding) != null


## What the controls screen shows for a binding: the key as printed on this keyboard, or the mouse
## button's name. Without a window (the tests), the keyboard cannot be asked, and a key shows as on
## a US keyboard.
static func binding_title(binding: String) -> String:
	var event: InputEvent = event_from_binding(binding)
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null:
		var printed: Key = KEY_NONE
		if DisplayServer.get_name() != "headless":
			printed = DisplayServer.keyboard_get_keycode_from_physical(key_event.physical_keycode)
		return OS.get_keycode_string(printed if printed != KEY_NONE else key_event.physical_keycode)
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null:
		return "%s mouse button" % MOUSE_BUTTONS[mouse_event.button_index].capitalize()
	return "?"


## True for the events a profile sets, which it takes out of the Input Map before putting its own
## in: keys and mouse buttons. The gamepad's are left alone.
static func is_profile_event(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton


## The default profile: the keys and mouse buttons each action has in project.godot, as the project
## saved them, whatever the Input Map holds now. This is the only place the default comes from, so
## a key added in Project Settings > Input Map is a key of the default profile.
static func _project_bindings() -> Dictionary[StringName, PackedStringArray]:
	var bindings: Dictionary[StringName, PackedStringArray] = {}
	for action: StringName in ACTIONS:
		var found: PackedStringArray = []
		var setting: Variant = ProjectSettings.get_setting("input/%s" % action, {})
		var events: Array = []
		if setting is Dictionary:
			events = (setting as Dictionary).get("events", [])
		for event: Variant in events:
			var binding: String = binding_from_event(event as InputEvent)
			if not binding.is_empty() and binding not in found:
				found.append(binding)
		bindings[action] = found
	return bindings
