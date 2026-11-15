class_name OptionsMenu
extends VBoxContainer

## The options screen, the same in the main menu and in the pause: a volume slider for each audio
## bus, full screen, V-Sync, the frame rate limit, Controls, Reset and Back. Controls swaps this
## screen for the controls screen, and its Back swaps them again. It shows what the autoload
## Settings holds and hands every change straight to it; Settings applies and saves. Back, Esc or B
## close the screen and say so with closed, and the menu it is in shows its own panel again.

signal closed

## Where the autoload Settings is in the tree. The screen looks it up there once it is ready instead
## of naming it in the code: a script that names an autoload only compiles once the autoload exists,
## and a test, or any script that compiles before the autoloads, would break every menu with it.
const SETTINGS_PATH: NodePath = ^"/root/Settings"
## The name shown for each bus; a bus missing here shows its own name.
const BUS_TITLES: Dictionary[StringName, String] = {
	&"Master": "Master",
	&"Music": "Music",
	&"SFX": "Effects",
	&"Ambience": "Ambience",
	&"UI": "Interface",
}
## How much one press of the left or right arrow moves a volume.
const VOLUME_STEP: float = 0.05
## The width of a volume slider, in px.
const SLIDER_WIDTH: float = 480.0
## What the frame rate list shows for no cap.
const NO_CAP_TEXT: String = "No limit"

var _sliders: Dictionary[StringName, HSlider] = {}
var _volume_texts: Dictionary[StringName, Label] = {}

@onready var _settings: GameSettings = get_node(SETTINGS_PATH) as GameSettings
@onready var _volumes: GridContainer = %Volumes
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_check: CheckButton = %VSyncCheck
@onready var _fps_cap_option: OptionButton = %FpsCapOption
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton
@onready var _general: Control = %General
@onready var _controls_button: Button = %ControlsButton
@onready var _controls_menu: ControlsMenu = %ControlsMenu


func _ready() -> void:
	for bus: StringName in GameSettings.BUSES:
		_add_volume_row(bus)
	for fps_cap: int in GameSettings.FPS_CAPS:
		_fps_cap_option.add_item(
				NO_CAP_TEXT if fps_cap == GameSettings.NO_FPS_CAP else "%d FPS" % fps_cap)
	_fullscreen_check.toggled.connect(_settings.set_fullscreen)
	_vsync_check.toggled.connect(_settings.set_vsync)
	_fps_cap_option.item_selected.connect(_on_fps_cap_selected)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(_close)
	_controls_button.pressed.connect(_show_controls)
	_controls_menu.closed.connect(_on_controls_closed)


## Esc or B closes the screen while it shows, and the event stops here: in the pause, that Esc goes
## back to the pause instead of resuming the game. While the controls screen shows, it handles its
## own Esc, going back to this one.
func _unhandled_input(event: InputEvent) -> void:
	if _general.is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


## Shows the screen with what Settings holds, and the first volume selected.
func open() -> void:
	_show_settings()
	_controls_menu.hide()
	_general.show()
	show()
	_sliders[GameSettings.BUSES[0]].grab_focus()


func _close() -> void:
	hide()
	closed.emit()


func _show_controls() -> void:
	_general.hide()
	_controls_menu.open()


func _on_controls_closed() -> void:
	_general.show()
	_controls_button.grab_focus()


## A row of the volumes grid: the bus's name, its slider and its volume in %.
func _add_volume_row(bus: StringName) -> void:
	var title: Label = Label.new()
	title.text = BUS_TITLES.get(bus, String(bus))
	var slider: HSlider = HSlider.new()
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.custom_minimum_size.x = SLIDER_WIDTH
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	var volume_text: Label = Label.new()
	_volumes.add_child(title)
	_volumes.add_child(slider)
	_volumes.add_child(volume_text)
	_sliders[bus] = slider
	_volume_texts[bus] = volume_text


## Sets every control to what Settings holds, without the controls handing it back as a change.
func _show_settings() -> void:
	for bus: StringName in GameSettings.BUSES:
		_sliders[bus].set_value_no_signal(_settings.get_volume(bus))
		_show_volume(bus)
	_fullscreen_check.set_pressed_no_signal(_settings.is_fullscreen())
	_vsync_check.set_pressed_no_signal(_settings.is_vsync_on())
	_fps_cap_option.select(GameSettings.FPS_CAPS.find(_settings.get_fps_cap()))


func _show_volume(bus: StringName) -> void:
	_volume_texts[bus].text = "%d %%" % roundi(_settings.get_volume(bus) * 100.0)


func _on_volume_changed(volume: float, bus: StringName) -> void:
	_settings.set_volume(bus, volume)
	_show_volume(bus)


func _on_fps_cap_selected(index: int) -> void:
	_settings.set_fps_cap(GameSettings.FPS_CAPS[index])


func _on_reset_pressed() -> void:
	_settings.reset_to_defaults()
	_show_settings()
