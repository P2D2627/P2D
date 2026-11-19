class_name ControlsMenu
extends VBoxContainer

## The options screen's Controls tab: the profile list, a row for each action with its keys and
## mouse buttons, and the custom profile's Reset. The fixed profiles only show their bindings. In the
## custom one, pressing an action's button waits for the next key or mouse button and remaps the
## action to it, and says so with rebound. A modifier (Shift, Ctrl, Alt) binds only as it is let go,
## with nothing pressed meanwhile and the game still in focus: held, it may start a shortcut, as Alt
## starts Alt+Tab. A key it cannot take (one reserved, as the debug overlay's F3, or one with no
## name) is refused, and so is the rest of the gamepad but B, a push at a time, as the gamepad is
## the same in every profile: the button says so, the wait goes on, and input_refused tells. Esc,
## or B on the gamepad, stops waiting and changes nothing, goes no further, and says so with
## wait_cancelled. The tab shows what the autoload Settings holds and hands every change to it;
## Settings applies and saves. The options screen opens and closes it, gives it the focus and closes
## itself on Esc or B.

## A key or mouse button was taken as action's new binding.
signal rebound(action: StringName)
## The player stopped the wait for a key with Esc or B.
signal wait_cancelled
## A key or a gamepad button pressed while waiting cannot be a binding; the wait goes on.
signal input_refused

## Where the autoload Settings is in the tree, looked up once the screen is ready, as the options
## screen does: a script that names an autoload only compiles once the autoload exists.
const SETTINGS_PATH: NodePath = ^"/root/Settings"
## What an action's button shows while it waits for a key.
const WAITING_TEXT: String = "Press a key or mouse button (Esc or B cancels)"
## What the button shows after a key it cannot take, with the key's name, as short as the waiting
## text, so it fits the button.
const REFUSED_TEXT: String = "%s can't be used: press another key"
## The name shown for a refused key that has none.
const UNNAMED_KEY: String = "That key"
## What the button shows after a gamepad button other than B, with the way out, short enough to fit
## the button.
const GAMEPAD_REFUSED_TEXT: String = "Gamepad stays fixed: press a key (B cancels)"
## The keys that only bind as they are let go, with nothing pressed meanwhile.
const MODIFIERS: Array[Key] = [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
## The width of an action's button, in px, so the rows do not jump as the texts change.
const BINDING_WIDTH: float = 640.0
## The theme's looks for an action's name and its button: the size of the other tabs' rows.
const ROW_TEXT: StringName = &"OptionsLabel"
const BINDING: StringName = &"OptionsBinding"

var _binding_buttons: Dictionary[StringName, Button] = {}
## The action waiting for a key; empty while none is.
var _waiting_action: StringName = &""
## What the waiting action's button says after a refused key; empty until one is.
var _refused_text: String = ""
## The gamepad axes past the half of their way during the wait, by device (x) and axis (y), so a push
## is refused once, as it gets there, and not at each event of its way.
var _pushed_axes: Dictionary[Vector2i, bool] = {}
## The modifier held down during the wait, which binds as it is let go; KEY_NONE while none is.
var _held_modifier: Key = KEY_NONE

@onready var _settings: GameSettings = get_node(SETTINGS_PATH) as GameSettings
@onready var _profile_option: OptionButton = %ProfileOption
@onready var _bindings: GridContainer = %Bindings
@onready var _reset_button: Button = %ControlsResetButton


## The profile list has the profiles in the order of InputProfiles.PROFILES, so an item's index is
## its profile's place there.
func _ready() -> void:
	for profile: StringName in InputProfiles.PROFILES:
		_profile_option.add_item(InputProfiles.PROFILES[profile])
	for action: StringName in InputProfiles.ACTIONS:
		_add_binding_row(action)
	_profile_option.item_selected.connect(_on_profile_selected)
	_reset_button.pressed.connect(_on_reset_pressed)


## While an action waits, the next key or mouse button press is its new binding, and nothing else
## gets it: not the focused button, nor the pause. Esc and B stop waiting; a key it cannot take is
## refused, with its name on the button, and so is the rest of the gamepad, a push at a time: a
## button other than B, or an axis (the stick, a trigger) once per push, however many events the push
## sends on its way. The wheel is taken and ignored. A modifier is held until it is let go, and any
## other press drops it.
func _input(event: InputEvent) -> void:
	if _waiting_action == &"":
		return
	var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
	if motion != null:
		get_viewport().set_input_as_handled()
		_on_axis_moved(motion)
		return
	var key: InputEventKey = event as InputEventKey
	if (key != null and not key.pressed and _held_modifier != KEY_NONE
			and _keycode_of(key) == _held_modifier):
		get_viewport().set_input_as_handled()
		_held_modifier = KEY_NONE
		_answer(key)
		return
	if not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	_held_modifier = KEY_NONE
	if event.is_action(&"ui_cancel"):
		_stop_waiting()
		wait_cancelled.emit()
		return
	if key != null and _keycode_of(key) in MODIFIERS:
		_held_modifier = _keycode_of(key)
		return
	_answer(event)


## Losing the focus, as with Alt+Tab, drops a held modifier: it was the start of a shortcut to
## another window, not a binding.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held_modifier = KEY_NONE


## Shows the tab with what Settings holds; the options screen gives the focus.
func open() -> void:
	_stop_waiting()
	show()


## Hides the tab, and an action waiting for a key stops waiting.
func close() -> void:
	_stop_waiting()
	hide()


func is_waiting_for_a_key() -> bool:
	return _waiting_action != &""


## The control the focus goes to as the tab is entered: the profile list.
func first_control() -> Control:
	return _profile_option


## The tab's last control, over the options screen's Reset and Back.
func last_control() -> Control:
	return _reset_button


## A row of the bindings grid: the action's name and the button with its bindings.
func _add_binding_row(action: StringName) -> void:
	var title: Label = Label.new()
	title.theme_type_variation = ROW_TEXT
	title.text = InputProfiles.ACTIONS[action]
	var button: Button = Button.new()
	button.theme_type_variation = BINDING
	button.name = "%sButton" % String(action).to_pascal_case()
	button.custom_minimum_size.x = BINDING_WIDTH
	button.pressed.connect(_start_waiting.bind(action))
	_bindings.add_child(title)
	_bindings.add_child(button)
	_binding_buttons[action] = button


## Sets every control to what Settings holds. The actions' buttons only press in the custom profile,
## and so does Reset, which resets that profile.
func _show_settings() -> void:
	var profile: StringName = _settings.get_input_profile()
	_profile_option.select(InputProfiles.PROFILES.keys().find(profile))
	var custom: bool = profile == InputProfiles.CUSTOM
	for action: StringName in InputProfiles.ACTIONS:
		var button: Button = _binding_buttons[action]
		button.disabled = not custom
		if action != _waiting_action:
			button.text = _bindings_text(action)
		else:
			button.text = _refused_text if not _refused_text.is_empty() else WAITING_TEXT
	_reset_button.disabled = not custom


func _bindings_text(action: StringName) -> String:
	var titles: PackedStringArray = []
	for binding: String in _settings.get_bindings(action):
		titles.append(InputProfiles.binding_title(binding))
	return ", ".join(titles)


## An axis let go while no action waited was never seen, so the pushed axes start afresh.
func _start_waiting(action: StringName) -> void:
	_waiting_action = action
	_refused_text = ""
	_pushed_axes.clear()
	_held_modifier = KEY_NONE
	_show_settings()


func _stop_waiting() -> void:
	_waiting_action = &""
	_refused_text = ""
	_held_modifier = KEY_NONE
	_show_settings()


## Binds what event pressed, or let go for a modifier, to the waiting action, or refuses it.
func _answer(event: InputEvent) -> void:
	var binding: String = InputProfiles.binding_from_event(event)
	if binding.is_empty():
		if event is InputEventKey:
			_refuse(REFUSED_TEXT % _key_name(event as InputEventKey))
		elif event is InputEventJoypadButton:
			_refuse(GAMEPAD_REFUSED_TEXT)
		return
	var action: StringName = _waiting_action
	_settings.set_custom_binding(action, binding)
	_stop_waiting()
	rebound.emit(action)


## The waiting action's button says text, why what was pressed cannot be used, and the wait goes on.
func _refuse(text: String) -> void:
	_refused_text = text
	_show_settings()
	input_refused.emit()


## An axis is refused as it gets past the half of its way, where Godot counts it as pressed, and not
## again until it has come back under it.
func _on_axis_moved(motion: InputEventJoypadMotion) -> void:
	var axis: Vector2i = Vector2i(motion.device, motion.axis)
	if not motion.is_pressed():
		_pushed_axes.erase(axis)
	elif not _pushed_axes.has(axis):
		_pushed_axes[axis] = true
		_refuse(GAMEPAD_REFUSED_TEXT)


## The key's name, or Unnamed Key for a key that has none.
func _key_name(key: InputEventKey) -> String:
	var key_name: String = OS.get_keycode_string(_keycode_of(key))
	return key_name if not key_name.is_empty() else UNNAMED_KEY


## The key by its place on the keyboard, as bindings keep it, or by its code if it has no place.
func _keycode_of(key: InputEventKey) -> Key:
	return key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode


func _on_profile_selected(index: int) -> void:
	_settings.set_input_profile(InputProfiles.PROFILES.keys()[index])
	_show_settings()


func _on_reset_pressed() -> void:
	_settings.reset_custom_bindings()
	_show_settings()
