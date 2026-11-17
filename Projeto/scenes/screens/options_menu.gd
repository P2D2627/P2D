class_name OptionsMenu
extends VBoxContainer

## The options screen, the same in the main menu and in the pause: a volume slider for each audio
## bus, full screen, V-Sync, the frame rate limit, the screen shake, the vibration, the constant
## vibration, Hold To Escape, Controls, Reset and Back. The four before Controls have a grid of their
## own, under the frame rate, for the accessibility options, with their sliders in line with the
## volumes'. Each change of the
## Vibration slider plays a hit's pulse on the controller in use, so the player feels the strength
## they pick; a drag with the mouse plays it once, as it ends. Controls swaps this screen for the
## controls screen, and its Back swaps them again. It shows what the autoload Settings holds and hands
## every change straight to it; Settings applies and saves. Back, Esc or B close the screen and say so
## with closed, and the menu it is in shows its own panel again.

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
const SCREEN_SHAKE_TITLE: String = "Screen shake"
## How much one press of the left or right arrow moves the screen shake.
const SCREEN_SHAKE_STEP: float = 0.1
const VIBRATION_TITLE: String = "Vibration"
## How much one press of the left or right arrow moves the vibration.
const VIBRATION_STEP: float = 0.1
const CONSTANT_VIBRATION_TITLE: String = "Constant vibration"
const HOLD_TO_ESCAPE_TITLE: String = "Hold to escape"
const SHOW_HIDDEN_TITLE: String = "Show hidden dangers"
## The game's pulses: the Vibration slider plays a hit's, the blow the player feels most often.
const RUMBLE_STATS: RumbleStats = preload("res://scenes/others/feedback/rumble_stats.tres")

var _sliders: Dictionary[StringName, HSlider] = {}
var _volume_texts: Dictionary[StringName, Label] = {}
var _screen_shake_slider: HSlider
var _screen_shake_text: Label
var _vibration_slider: HSlider
var _vibration_text: Label
var _constant_vibration_check: CheckButton
var _hold_to_escape_check: CheckButton
var _show_hidden_check: CheckButton
## Plays the Vibration slider's sample, also in the pause.
var _sample_rumble: ControllerRumble
## True while the mouse drags the Vibration slider: the sample waits for the drag to end.
var _dragging_vibration: bool = false
## The titles of the volumes and of the accessibility options, so they can take the same width.
var _titles: Array[Label] = []

@onready var _settings: GameSettings = get_node(SETTINGS_PATH) as GameSettings
@onready var _volumes: GridContainer = %Volumes
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_check: CheckButton = %VSyncCheck
@onready var _fps_cap_option: OptionButton = %FpsCapOption
@onready var _accessibility: GridContainer = %Accessibility
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
	_add_screen_shake_row()
	_add_vibration_row()
	_add_constant_vibration_row()
	_add_hold_to_escape_row()
	_add_show_hidden_row()
	_line_up_titles()
	_sample_rumble = ControllerRumble.new()
	_sample_rumble.process_mode = Node.PROCESS_MODE_ALWAYS
	_sample_rumble.keeps_last_controller = true
	add_child(_sample_rumble)
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
	var slider: HSlider = _new_slider(VOLUME_STEP)
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	var volume_text: Label = Label.new()
	_volumes.add_child(title)
	_volumes.add_child(slider)
	_volumes.add_child(volume_text)
	_sliders[bus] = slider
	_volume_texts[bus] = volume_text
	_titles.append(title)


## The screen shake's row: its name, its slider and its strength in %.
func _add_screen_shake_row() -> void:
	_screen_shake_slider = _new_slider(SCREEN_SHAKE_STEP)
	_screen_shake_slider.value_changed.connect(_on_screen_shake_changed)
	_screen_shake_text = Label.new()
	_add_accessibility_row(SCREEN_SHAKE_TITLE, _screen_shake_slider, _screen_shake_text)


## The vibration's row, under the screen shake's: its name, its slider and its strength in %.
func _add_vibration_row() -> void:
	_vibration_slider = _new_slider(VIBRATION_STEP)
	_vibration_slider.value_changed.connect(_on_vibration_changed)
	_vibration_slider.drag_started.connect(_on_vibration_drag_started)
	_vibration_slider.drag_ended.connect(_on_vibration_drag_ended)
	_vibration_slider.visibility_changed.connect(_on_vibration_visibility_changed)
	_vibration_text = Label.new()
	_add_accessibility_row(VIBRATION_TITLE, _vibration_slider, _vibration_text)


## The constant vibration's row, under the vibration's: its name and a switch, with nothing in the
## value's column.
func _add_constant_vibration_row() -> void:
	_constant_vibration_check = CheckButton.new()
	_constant_vibration_check.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_constant_vibration_check.toggled.connect(_settings.set_constant_vibration)
	_add_accessibility_row(CONSTANT_VIBRATION_TITLE, _constant_vibration_check, Label.new())


## Hold To Escape's row: its name and a switch, with nothing in the value's column.
func _add_hold_to_escape_row() -> void:
	_hold_to_escape_check = CheckButton.new()
	_hold_to_escape_check.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_hold_to_escape_check.toggled.connect(_settings.set_hold_to_escape)
	_add_accessibility_row(HOLD_TO_ESCAPE_TITLE, _hold_to_escape_check, Label.new())


## Show Hidden's row, the grid's last: its name and a switch, with nothing in the value's column.
func _add_show_hidden_row() -> void:
	_show_hidden_check = CheckButton.new()
	_show_hidden_check.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_show_hidden_check.toggled.connect(_settings.set_show_hidden)
	_add_accessibility_row(SHOW_HIDDEN_TITLE, _show_hidden_check, Label.new())


## A row of the accessibility grid: a title with title_text, then control and value_text.
func _add_accessibility_row(title_text: String, control: Control, value_text: Label) -> void:
	var title: Label = Label.new()
	title.text = title_text
	_accessibility.add_child(title)
	_accessibility.add_child(control)
	_accessibility.add_child(value_text)
	_titles.append(title)


## Each grid sizes its own columns, so the titles all take the widest one's width, and the sliders of
## the volumes and of the accessibility options line up.
func _line_up_titles() -> void:
	var widest: float = 0.0
	for title: Label in _titles:
		widest = maxf(widest, title.get_minimum_size().x)
	for title: Label in _titles:
		title.custom_minimum_size.x = widest


## A slider from 0 to 1, as wide as the others.
func _new_slider(step: float) -> HSlider:
	var slider: HSlider = HSlider.new()
	slider.max_value = 1.0
	slider.step = step
	slider.custom_minimum_size.x = SLIDER_WIDTH
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return slider


## Sets every control to what Settings holds, without the controls handing it back as a change.
func _show_settings() -> void:
	for bus: StringName in GameSettings.BUSES:
		_sliders[bus].set_value_no_signal(_settings.get_volume(bus))
		_show_volume(bus)
	_fullscreen_check.set_pressed_no_signal(_settings.is_fullscreen())
	_vsync_check.set_pressed_no_signal(_settings.is_vsync_on())
	_fps_cap_option.select(GameSettings.FPS_CAPS.find(_settings.get_fps_cap()))
	_screen_shake_slider.set_value_no_signal(_settings.get_screen_shake())
	_show_screen_shake()
	_vibration_slider.set_value_no_signal(_settings.get_vibration())
	_show_vibration()
	_constant_vibration_check.set_pressed_no_signal(_settings.is_constant_vibration_on())
	_hold_to_escape_check.set_pressed_no_signal(_settings.is_hold_to_escape_on())
	_show_hidden_check.set_pressed_no_signal(_settings.is_show_hidden_on())


func _show_volume(bus: StringName) -> void:
	_volume_texts[bus].text = _percent_text(_settings.get_volume(bus))


func _show_screen_shake() -> void:
	_screen_shake_text.text = _percent_text(_settings.get_screen_shake())


func _show_vibration() -> void:
	_vibration_text.text = _percent_text(_settings.get_vibration())


## A value from 0 to 1 as a whole percentage, such as "30 %".
func _percent_text(value: float) -> String:
	return "%d %%" % roundi(value * 100.0)


func _on_volume_changed(volume: float, bus: StringName) -> void:
	_settings.set_volume(bus, volume)
	_show_volume(bus)


func _on_screen_shake_changed(strength: float) -> void:
	_settings.set_screen_shake(strength)
	_show_screen_shake()


## Hands the strength to Settings, shows it and, unless the mouse is still dragging, plays a hit's
## pulse at it on the controller in use: a press of a direction on the controller plays it at once.
func _on_vibration_changed(strength: float) -> void:
	_settings.set_vibration(strength)
	_show_vibration()
	if not _dragging_vibration:
		_sample_rumble.play(RUMBLE_STATS.hit)


func _on_vibration_drag_started() -> void:
	_dragging_vibration = true


## A drag plays the sample once, as it ends, at the strength it ended on.
func _on_vibration_drag_ended(_value_changed: bool) -> void:
	_dragging_vibration = false
	_sample_rumble.play(RUMBLE_STATS.hit)


## Hidden mid-drag, as when the screen closes, the slider drops the drag without ending it, so the
## drag is over here too, and the next change plays the sample.
func _on_vibration_visibility_changed() -> void:
	_dragging_vibration = false


func _on_fps_cap_selected(index: int) -> void:
	_settings.set_fps_cap(GameSettings.FPS_CAPS[index])


func _on_reset_pressed() -> void:
	_settings.reset_to_defaults()
	_show_settings()
