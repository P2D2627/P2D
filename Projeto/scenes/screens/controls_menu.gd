class_name ControlsMenu
extends VBoxContainer

## The controls screen, opened from the options: the profile list, a row for each action with its
## keys and mouse buttons, Reset and Back. The fixed profiles only show their bindings. In the
## custom one, pressing an action's button waits for the next key or mouse button and remaps the
## action to it; Esc, or B on the gamepad, stops waiting and changes nothing. The gamepad's buttons
## are the same in every profile. The screen shows what the autoload Settings holds and hands every
## change to it; Settings applies and saves. Back, Esc or B close the screen and say so with closed.

signal closed

## Where the autoload Settings is in the tree, looked up once the screen is ready, as the options
## screen does: a script that names an autoload only compiles once the autoload exists.
const SETTINGS_PATH: NodePath = ^"/root/Settings"
## What an action's button shows while it waits for a key.
const WAITING_TEXT: String = "Press a key or mouse button... (Esc to cancel)"
## The width of an action's button, in px, so the rows do not jump as the texts change.
const BINDING_WIDTH: float = 640.0

var _binding_buttons: Dictionary[StringName, Button] = {}
## The action waiting for a key; empty while none is.
var _waiting_action: StringName = &""

@onready var _settings: GameSettings = get_node(SETTINGS_PATH) as GameSettings
@onready var _profile_option: OptionButton = %ProfileOption
@onready var _bindings: GridContainer = %Bindings
@onready var _reset_button: Button = %ControlsResetButton
@onready var _back_button: Button = %ControlsBackButton


## The profile list has the profiles in the order of InputProfiles.PROFILES, so an item's index is
## its profile's place there.
func _ready() -> void:
	for profile: StringName in InputProfiles.PROFILES:
		_profile_option.add_item(InputProfiles.PROFILES[profile])
	for action: StringName in InputProfiles.ACTIONS:
		_add_binding_row(action)
	_profile_option.item_selected.connect(_on_profile_selected)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(_close)


## While an action waits, the next key or mouse button press is its new binding, and nothing else
## gets it: not the focused button, nor the pause. Esc and B stop waiting; a reserved key, or a
## gamepad button other than B, is taken and ignored.
func _input(event: InputEvent) -> void:
	if _waiting_action == &"" or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if event.is_action(&"ui_cancel"):
		_stop_waiting()
		return
	var binding: String = InputProfiles.binding_from_event(event)
	if binding.is_empty():
		return
	_settings.set_custom_binding(_waiting_action, binding)
	_stop_waiting()


## Esc or B closes the screen while it shows, and the event stops here, as on the options screen.
func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


## Shows the screen with what Settings holds, and the profile list selected.
func open() -> void:
	_stop_waiting()
	show()
	_profile_option.grab_focus()


func is_waiting_for_a_key() -> bool:
	return _waiting_action != &""


func _close() -> void:
	_stop_waiting()
	hide()
	closed.emit()


## A row of the bindings grid: the action's name and the button with its bindings.
func _add_binding_row(action: StringName) -> void:
	var title: Label = Label.new()
	title.text = InputProfiles.ACTIONS[action]
	var button: Button = Button.new()
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
		button.text = WAITING_TEXT if action == _waiting_action else _bindings_text(action)
	_reset_button.disabled = not custom


func _bindings_text(action: StringName) -> String:
	var titles: PackedStringArray = []
	for binding: String in _settings.get_bindings(action):
		titles.append(InputProfiles.binding_title(binding))
	return ", ".join(titles)


func _start_waiting(action: StringName) -> void:
	_waiting_action = action
	_show_settings()


func _stop_waiting() -> void:
	_waiting_action = &""
	_show_settings()


func _on_profile_selected(index: int) -> void:
	_settings.set_input_profile(InputProfiles.PROFILES.keys()[index])
	_show_settings()


func _on_reset_pressed() -> void:
	_settings.reset_custom_bindings()
	_show_settings()
