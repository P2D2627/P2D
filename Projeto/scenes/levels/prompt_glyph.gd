class_name PromptGlyph
extends PanelContainer

## One action's prompt, drawn the same way in the tutorial's band at the bottom of the screen and in
## the world, over Velvet: on the keyboard, the action's first key or mouse button, as the controls
## screen names it, in a key of our own; once a pad is the device used last (the autoload
## LastDevice), the pad's button, stick or trigger for the action: its picture from Pad Icons, tinted
## in the interface's bone colour, or, for a binding with no picture, its name in the key. It follows
## the profile picked in the options, which are only reached through the pause, so it reads the Input
## Map again when the game comes back from it. It only shows: it never reads a press.

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
const LAST_DEVICE_PATH: NodePath = ^"/root/LastDevice"

## The action whose key it shows, such as &"jump".
@export var action: StringName = &"":
	set(value):
		action = value
		if is_node_ready():
			refresh()

## The pictures of the pad's buttons, sticks and triggers, by the name PAD_BUTTONS or PAD_AXES gives
## them, white to be tinted. Swapping these swaps the art; a name missing here shows as text.
@export var pad_icons: Dictionary[String, Texture2D] = {}

## Whether it shows the pad's button now, rather than the key.
var _shows_pad: bool = false
## No frame, for a picture, which has its own; the key's frame is the theme's PromptKey.
var _no_box: StyleBoxEmpty = StyleBoxEmpty.new()

@onready var _label: Label = %Label
@onready var _icon: TextureRect = %Icon
@onready var _last_device: GameLastDevice = get_node_or_null(LAST_DEVICE_PATH) as GameLastDevice


func _ready() -> void:
	# The picture takes the key's name colour from the theme, so the colour lives in one place.
	_icon.self_modulate = _label.get_theme_color(&"font_color")
	if _last_device != null:
		_last_device.device_changed.connect(_on_device_changed)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED and is_node_ready():
		refresh()


## The text it shows now: the key's or the pad button's name, or NO_KEY_TEXT.
func get_text() -> String:
	return _label.text


func shows_pad() -> bool:
	return _shows_pad


## Whether it shows a picture now, rather than a name in a key.
func shows_icon() -> bool:
	return _icon.visible


## Reads the action's key again from the Input Map: the pad's button when a pad is the device used
## last and the action has one, and the key otherwise.
func refresh() -> void:
	if action.is_empty():
		return
	assert(InputMap.has_action(action), "PromptGlyph: Action %s is not in the Input Map." % action)
	var pad: String = pad_text(action) if _last_device != null and _last_device.is_pad() else ""
	_shows_pad = not pad.is_empty()
	_label.text = pad if _shows_pad else key_text(action)
	var picture: Texture2D = pad_icons.get(pad) if _shows_pad else null
	_icon.texture = picture
	_icon.visible = picture != null
	_label.visible = picture == null
	if picture == null:
		remove_theme_stylebox_override(&"panel")
	else:
		add_theme_stylebox_override(&"panel", _no_box)
	reset_size()


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


func _on_device_changed(_device: GameLastDevice.Device) -> void:
	refresh()
