class_name ControlsMenu
extends VBoxContainer

## The options screen's Controls tab: the profile list, a row for each action with its keys and
## mouse buttons, and the custom profile's Reset. The fixed profiles only show their bindings. In the
## custom one, pressing an action's button waits for the next key or mouse button and remaps the
## action to it, and says so with rebound; a key it cannot take (one reserved, as the debug overlay's
## F3, or one with no name) is refused, and so is a gamepad button other than B, as the gamepad's
## buttons are the same in every profile: the button says so, the wait goes on, and input_refused
## tells. Esc, or B on the gamepad, stops waiting and changes nothing, goes no further, and says so
## with wait_cancelled. The tab shows what the autoload Settings holds and hands every change to it;
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
## refused, with its name on the button, and so is a gamepad button other than B. The stick and the
## triggers, the gamepad's axes, are taken and ignored for now, as is the wheel: an axis sends
## events all along its way, so refusing it once per push would need each axis's state kept.
func _input(event: InputEvent) -> void:
	if _waiting_action == &"" or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if event.is_action(&"ui_cancel"):
		_stop_waiting()
		wait_cancelled.emit()
		return
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


func _start_waiting(action: StringName) -> void:
	_waiting_action = action
	_refused_text = ""
	_show_settings()


func _stop_waiting() -> void:
	_waiting_action = &""
	_refused_text = ""
	_show_settings()


## The waiting action's button says text, why what was pressed cannot be used, and the wait goes on.
func _refuse(text: String) -> void:
	_refused_text = text
	_show_settings()
	input_refused.emit()


## The key's name, or Unnamed Key for a key that has none.
func _key_name(key: InputEventKey) -> String:
	var keycode: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var key_name: String = OS.get_keycode_string(keycode)
	return key_name if not key_name.is_empty() else UNNAMED_KEY


func _on_profile_selected(index: int) -> void:
	_settings.set_input_profile(InputProfiles.PROFILES.keys()[index])
	_show_settings()


func _on_reset_pressed() -> void:
	_settings.reset_custom_bindings()
	_show_settings()
