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

## The player moved on to device.
signal device_changed(device: Device)

## NONE is only what device_of gives for an event that does not count; the device is never NONE.
enum Device { NONE = -1, KEYBOARD, PAD }

## What _pad holds with no pad used or connected.
const NO_PAD: int = -1

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
		_pad = event.device
	_set_device(device)


func _on_joy_connection_changed(pad: int, connected: bool) -> void:
	if connected:
		_pad = pad
		_set_device(Device.PAD)
	elif pad == _pad:
		_pad = NO_PAD
		_set_device(Device.KEYBOARD)


func _set_device(device: Device) -> void:
	if device == _device:
		return
	_device = device
	device_changed.emit(device)
