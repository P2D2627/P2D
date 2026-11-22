class_name GameLastDevice
extends Node

## Whether the player last used the keyboard or a gamepad, as the autoload LastDevice, so the
## prompts show that device's keys. It listens to the window's window_input signal, which every
## event goes through before any node, paused or not, and even when a node's _input marks it handled
## or an open popup swallows it. Only what would work an action counts: a key, mouse button or pad
## button pressed on an action, or a stick or trigger pushed past that action's own dead zone.
## Echoes, releases, mouse motion, unbound keys and a stick resting under the dead zone change
## nothing, so a drifting stick never flips the prompts. Connecting a pad switches to it, so a
## player who plugs one in sees its buttons at once; disconnecting the pad used last goes back to
## the keyboard, and another pad going away changes nothing. No script names this autoload: they go
## to /root/LastDevice, so they compile before the autoloads exist.
## It also says which family the pad in use is, so the prompts draw its buttons as they are printed
## on it: the option Settings keeps (Gamepad buttons), or, on Automatic, the pad's own name. The
## buttons work the same either way: Godot numbers them by place, so a PlayStation pad's Cross and a
## Switch pad's B, at the bottom, have the index of an Xbox pad's A.

## The player moved on to device.
signal device_changed(device: Device)
## The player moved on to another pad, or plugged one in: its buttons may be drawn another way.
signal pad_changed

## NONE is only what device_of gives for an event that does not count; the device is never NONE.
enum Device { NONE = -1, KEYBOARD, PAD }
## How a pad's buttons are drawn: as on an Xbox pad, the layout most PC pads follow, or as on a
## PlayStation, Nintendo Switch or Steam Deck one.
enum PadFamily { XBOX, PLAYSTATION, NINTENDO, STEAM_DECK }

## What _pad holds with no pad used or connected.
const NO_PAD: int = -1
## The family each Gamepad buttons option picks; Automatic is not here, as it reads the pad's name.
const FAMILY_OF_OPTION: Dictionary[StringName, PadFamily] = {
	GameSettings.PAD_BUTTONS_XBOX: PadFamily.XBOX,
	GameSettings.PAD_BUTTONS_PLAYSTATION: PadFamily.PLAYSTATION,
	GameSettings.PAD_BUTTONS_NINTENDO: PadFamily.NINTENDO,
	GameSettings.PAD_BUTTONS_STEAM_DECK: PadFamily.STEAM_DECK,
}
## Words in a pad's name, in lower case, that tell its family, looked for in this order: "xbox"
## first, as an "Xbox Wireless Controller" would also match Sony's own name for a DualShock 4 with no
## mapping, "Wireless Controller". On Windows, Godot names a DualShock 4 "PS4 Controller", a
## DualSense "PS5 Controller" and a Switch Pro pad "Nintendo Switch Pro Controller".
const FAMILY_NAMES: Array[Array] = [
	[PadFamily.XBOX, ["xbox", "xinput"]],
	[PadFamily.STEAM_DECK, ["steam deck"]],
	[PadFamily.NINTENDO, ["nintendo", "switch", "joy-con", "joycon", "pro controller"]],
	[PadFamily.PLAYSTATION, ["ps3", "ps4", "ps5", "playstation", "dualshock", "dualsense", "sony",
			"wireless controller"]],
]
## Where the autoload Settings is, looked up when the family is asked for: it is loaded first.
const SETTINGS_PATH: NodePath = ^"/root/Settings"

var _device: Device = Device.KEYBOARD
## The pad used or connected last, by Godot's device index; NO_PAD with none.
var _pad: int = NO_PAD


func _ready() -> void:
	var pads: Array[int] = Input.get_connected_joypads()
	if not pads.is_empty():
		_pad = pads[0]
		_device = Device.PAD
	get_window().window_input.connect(_on_window_input)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


## The device the player used last: KEYBOARD or PAD.
func get_device() -> Device:
	return _device


func is_pad() -> bool:
	return _device == Device.PAD


## The family whose buttons the prompts draw: the one the Gamepad buttons option picks, or on
## Automatic the family of the pad in use, by its name; XBOX with no pad.
func get_pad_family() -> PadFamily:
	var settings: GameSettings = get_node_or_null(SETTINGS_PATH) as GameSettings
	var style: StringName = (settings.get_pad_buttons() if settings != null
			else GameSettings.PAD_BUTTONS_AUTO)
	if style in FAMILY_OF_OPTION:
		return FAMILY_OF_OPTION[style]
	return family_of_name(Input.get_joy_name(_pad)) if _pad != NO_PAD else PadFamily.XBOX


## The family a pad named pad_name is, by the first of FAMILY_NAMES with a word in the name; XBOX
## when none has, as most PC pads copy the Xbox layout.
static func family_of_name(pad_name: String) -> PadFamily:
	var lower: String = pad_name.to_lower()
	for entry: Array in FAMILY_NAMES:
		for word: String in entry[1]:
			if lower.contains(word):
				return entry[0]
	return PadFamily.XBOX


## The device event counts for, or NONE when it would work no action. The keyboard and the mouse
## count as one, the keyboard.
static func device_of(event: InputEvent) -> Device:
	var device: Device = _family_of(event)
	if device == Device.NONE:
		return Device.NONE
	# is_action_pressed skips echoes and releases, and weighs a stick against the action's dead zone.
	for action: StringName in InputMap.get_actions():
		if event.is_action_pressed(action):
			return device
	return Device.NONE


## The device an event comes from, whether or not it works an action: KEYBOARD for keys and mouse
## buttons, PAD for a pad's buttons and axes, NONE for the rest.
static func _family_of(event: InputEvent) -> Device:
	if event is InputEventKey or event is InputEventMouseButton:
		return Device.KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.PAD
	return Device.NONE


func _on_window_input(event: InputEvent) -> void:
	# An event from the device in use, and on a pad from the pad in use, can change nothing, so it
	# skips the look through every action: a resting stick sends one every frame.
	var family: Device = _family_of(event)
	if family == _device and (family == Device.KEYBOARD or event.device == _pad):
		return
	var device: Device = device_of(event)
	if device == Device.NONE:
		return
	if device == Device.PAD:
		_set_pad(event.device)
	_set_device(device)


func _on_joy_connection_changed(pad: int, connected: bool) -> void:
	if connected:
		_set_pad(pad)
		_set_device(Device.PAD)
	elif pad == _pad:
		_pad = NO_PAD
		_set_device(Device.KEYBOARD)


func _set_pad(pad: int) -> void:
	if pad == _pad:
		return
	_pad = pad
	pad_changed.emit()


func _set_device(device: Device) -> void:
	if device == _device:
		return
	_device = device
	device_changed.emit(device)
