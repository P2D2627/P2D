class_name KeyPrompt
extends Node2D

## One key drawn on the level's background, next to the obstacle that teaches its action: a stand-in
## until the art comes (S3.31), which swaps the Label for the key's picture. It shows the first key
## or mouse button the Input Map has for Action, as the controls screen names it, so it follows the
## profile picked in the options; while a gamepad is connected, it shows the pad's button or stick
## for Action instead, and it switches as soon as one is connected or disconnected. The options are
## only reached through the pause, so it reads the key again when the game comes back from it. It
## only shows: it never reads a press.

## Shown while the action has no key or mouse button.
const NO_KEY_TEXT: String = "?"
## The pad's buttons by Godot's index, as on an Xbox pad, the layout most PC pads follow.
const PAD_BUTTONS: Dictionary[int, String] = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad ↑", JOY_BUTTON_DPAD_DOWN: "D-pad ↓",
	JOY_BUTTON_DPAD_LEFT: "D-pad ←", JOY_BUTTON_DPAD_RIGHT: "D-pad →",
}
## The pad's sticks and triggers by Godot's axis, each way: [the name, then less than 0, more than 0].
const PAD_AXES: Dictionary[int, Array] = {
	JOY_AXIS_LEFT_X: ["LS ←", "LS →"], JOY_AXIS_LEFT_Y: ["LS ↑", "LS ↓"],
	JOY_AXIS_RIGHT_X: ["RS ←", "RS →"], JOY_AXIS_RIGHT_Y: ["RS ↑", "RS ↓"],
	JOY_AXIS_TRIGGER_LEFT: ["LT", "LT"], JOY_AXIS_TRIGGER_RIGHT: ["RT", "RT"],
}

## The action whose key it shows, such as &"jump".
@export var action: StringName = &""
## Which side of the key sits on the node: centred, or, for two keys side by side, the left one
## by its right edge and the right one by its left edge, so each grows away from the other and
## a longer name, as a pad's, never covers its neighbour.
@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

## Whether a gamepad is connected, so the pad's button shows.
var _pad_connected: bool = false

@onready var _label: Label = %Label


func _ready() -> void:
	assert(InputMap.has_action(action), "KeyPrompt: Action %s is not in the Input Map." % action)
	_pad_connected = not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED and is_node_ready():
		refresh()


## The text it shows now: the key's or the pad button's name, or NO_KEY_TEXT.
func get_text() -> String:
	return _label.text


## Reads the action's key again from the Input Map, and places the label on the node as Alignment
## says. With a
## gamepad connected, the pad's button, when the action has one.
func refresh() -> void:
	var pad: String = pad_text(action) if _pad_connected else ""
	_label.text = pad if not pad.is_empty() else key_text(action)
	_label.reset_size()
	var x: float = -_label.size.x / 2.0
	if alignment == HORIZONTAL_ALIGNMENT_LEFT:
		x = 0.0
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = -_label.size.x
	_label.position = Vector2(x, -_label.size.y / 2.0)


## The name of the first key or mouse button the Input Map has for action, as the controls screen
## shows it; NO_KEY_TEXT with none.
static func key_text(for_action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(for_action):
		var binding: String = InputProfiles.binding_from_event(event)
		if not binding.is_empty():
			return InputProfiles.binding_title(binding)
	return NO_KEY_TEXT


## The name of the first pad button, stick or trigger the Input Map has for action; empty with none.
static func pad_text(for_action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(for_action):
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if button != null:
			return PAD_BUTTONS.get(button.button_index, "Button %d" % button.button_index)
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if motion != null:
			var names: Array = PAD_AXES.get(motion.axis, ["Axis %d" % motion.axis] as Array)
			return names[0] if motion.axis_value < 0.0 or names.size() < 2 else names[1]
	return ""


## Any pad still connected keeps the pad's buttons: one of two going away changes nothing.
func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	_pad_connected = connected or not Input.get_connected_joypads().is_empty()
	refresh()
