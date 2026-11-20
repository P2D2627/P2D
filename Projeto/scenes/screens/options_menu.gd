class_name OptionsMenu
extends VBoxContainer

## The options screen, the same in the main menu and in the pause, titled Settings as the button that
## opens it. A row of tabs (Audio, Display, Controls, Accessibility) shows one page at a time, so the
## player never sees every option at once: Audio a volume slider for each audio bus; Display full
## screen, V-Sync and the frame rate limit; Controls the controls (ControlsMenu); Accessibility the
## screen shake, the vibration, the constant vibration, Hold To Escape and Show Hidden. It opens on
## Audio with its tab selected; left and right on the tabs scroll through them, round from the last
## to the first, and the page follows at once; down or Enter go into the page, and up from its first
## row goes back to the tabs. The selection, a row, a tab or a button, has a light band behind it,
## drawn by the screen itself, that glides with it, in place of the menu's crosses, and the line
## under the pages (Description) says what the selected option does. The mouse over a tab does not
## select it, so a pointer on its way to the page leaves the page alone; a click does.
## Reset and Back sit apart, under everything, with Back's keys beside it. The grids' titles all take
## the widest one's width, so the pages' sliders and switches sit in the same column. Each switch
## says On or Off in the value's column, so its state reads at a glance. Each change of the Vibration
## slider plays a hit's pulse on the controller in use, so the player feels the strength they pick; a
## drag with the mouse plays it once, as it ends. It shows what the autoload Settings holds and hands
## every change straight to it; Settings applies and saves. Back, Esc or B close the screen from any
## tab and say so with closed, and the menu it is in shows its own panel again.

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
## The width of a volume slider, in px: the longest title, a slider and a value fit the menu's half
## of a 1920 px screen.
const SLIDER_WIDTH: float = 400.0
## The theme's look for the rows' text: smaller than the menu's, so every row fits a 1080 px screen.
const ROW_TEXT: StringName = &"OptionsLabel"
## What the frame rate list shows for no cap.
const NO_CAP_TEXT: String = "No limit"
## What a switch's value says. Both read the same: a dimmer Off would read as disabled.
const ON_TEXT: String = "On"
const OFF_TEXT: String = "Off"
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
## How many lines the description keeps room for, so the screen never moves as the text changes.
const DESCRIPTION_LINES: int = 2
## The theme's looks for a tab and for the selected one.
const TAB: StringName = &"OptionsTab"
const SELECTED_TAB: StringName = &"OptionsTabSelected"
## The theme type whose panel style is the band behind the selection.
const HIGHLIGHT: StringName = &"OptionsRowHighlight"
## What each volume does, by bus; a bus missing here shows no line.
const BUS_DESCRIPTIONS: Dictionary[StringName, String] = {
	&"Master": "The volume of the whole game.",
	&"Music": "The volume of the music.",
	&"SFX": "The volume of the game's sound effects.",
	&"Ambience": "The volume of each place's background sound.",
	&"UI": "The volume of the menus' sounds.",
}
const FULLSCREEN_DESCRIPTION: String = "Plays on the whole screen; off, in a window."
const VSYNC_DESCRIPTION: String = "Draws each frame in step with the screen, so the picture never tears."
const FPS_CAP_DESCRIPTION: String = "The most frames drawn each second. The game keeps its pace."
const SCREEN_SHAKE_DESCRIPTION: String = "How strong the screen shake is. 0 % turns it off."
const VIBRATION_DESCRIPTION: String = "How strong the controller's vibration is. 0 % turns it off."
const CONSTANT_VIBRATION_DESCRIPTION: String = ("The controller also vibrates while a state lasts, "
		+ "such as a grab or the crucifix held up.")
const HOLD_TO_ESCAPE_DESCRIPTION: String = ("Hold Jump to break free of a grab, instead of pressing "
		+ "it again and again.")
const SHOW_HIDDEN_DESCRIPTION: String = "Demons and spikes show even out of sight."

@export_group("Row highlight")
## How fast the band behind the selected row glides to a new row: higher is quicker.
@export_range(1.0, 60.0, 0.5) var highlight_sharpness: float = 18.0
## How far the band reaches past its row, each way, across (x) and up and down (y), in px.
@export var highlight_margin: Vector2 = Vector2(18.0, 4.0)

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
## Each switch's value text, which says On or Off.
var _switch_texts: Dictionary[CheckButton, Label] = {}
## What each control does, shown on the description line while it is selected.
var _descriptions: Dictionary[Control, String] = {}
## Each tab and the page it shows, in the tabs' order.
var _pages: Dictionary[Button, Control] = {}
## Each page's first control, where the focus goes into the page.
var _first_controls: Dictionary[Control, Control] = {}
## Each page's last control, over Reset and Back.
var _last_controls: Dictionary[Control, Control] = {}
## The tab whose page shows.
var _selected_tab: Button
## The control whose row the band is on; null while it is hidden.
var _highlighted: Control
## Where the band is drawn now, in global coordinates; empty while it is hidden.
var _highlight_rect: Rect2 = Rect2()
## True from the band's appearing to its first frame, which puts it in place without gliding.
var _snap_highlight: bool = false

@onready var _settings: GameSettings = get_node(SETTINGS_PATH) as GameSettings
@onready var _volumes: GridContainer = %Volumes
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _fullscreen_text: Label = %FullscreenValue
@onready var _vsync_check: CheckButton = %VSyncCheck
@onready var _vsync_text: Label = %VSyncValue
@onready var _fps_cap_option: OptionButton = %FpsCapOption
@onready var _display: GridContainer = %Display
@onready var _accessibility: GridContainer = %Accessibility
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton
@onready var _tabs: Container = %Tabs
@onready var _audio_tab: Button = %AudioTab
@onready var _display_tab: Button = %DisplayTab
@onready var _controls_tab: Button = %ControlsTab
@onready var _accessibility_tab: Button = %AccessibilityTab
@onready var _pages_box: Control = %Pages
@onready var _audio_page: Control = %AudioPage
@onready var _display_page: Control = %DisplayPage
@onready var _accessibility_page: Control = %AccessibilityPage
@onready var _controls_menu: ControlsMenu = %ControlsMenu
@onready var _description: Label = %Description


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
	_say_on_or_off(_fullscreen_check, _fullscreen_text)
	_say_on_or_off(_vsync_check, _vsync_text)
	# As wide as a slider, so the display grid's On and Off line up with the other grids' values.
	_fps_cap_option.custom_minimum_size.x = SLIDER_WIDTH
	# The display grid's rows are in the scene: its titles are the first of each row.
	for index: int in range(0, _display.get_child_count(), _display.columns):
		_titles.append(_display.get_child(index) as Label)
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
	_descriptions[_fullscreen_check] = FULLSCREEN_DESCRIPTION
	_descriptions[_vsync_check] = VSYNC_DESCRIPTION
	_descriptions[_fps_cap_option] = FPS_CAP_DESCRIPTION
	_pages = {_audio_tab: _audio_page, _display_tab: _display_page, _controls_tab: _controls_menu,
			_accessibility_tab: _accessibility_page}
	_first_controls = {_audio_page: _sliders[GameSettings.BUSES[0]],
			_display_page: _fullscreen_check, _controls_menu: _controls_menu.first_control(),
			_accessibility_page: _screen_shake_slider}
	_last_controls = {_audio_page: _sliders[GameSettings.BUSES[-1]], _display_page: _fps_cap_option,
			_controls_menu: _controls_menu.last_control(), _accessibility_page: _show_hidden_check}
	for tab: Button in _pages:
		tab.focus_entered.connect(_select_tab.bind(tab))
		tab.pressed.connect(_enter_page)
	_link_the_tabs()
	_description.custom_minimum_size.y = _description_room()
	_size_the_pages()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


## The band behind the selected row follows it, also as the layout moves.
func _process(delta: float) -> void:
	if _highlighted == null:
		return
	if not is_instance_valid(_highlighted) or not _highlighted.is_visible_in_tree():
		_hide_highlight()
		return
	var target: Rect2 = _row_rect(_highlighted).grow_individual(highlight_margin.x,
			highlight_margin.y, highlight_margin.x, highlight_margin.y)
	var weight: float = 1.0 if _snap_highlight else 1.0 - exp(-highlight_sharpness * delta)
	_snap_highlight = false
	_highlight_rect = Rect2(_highlight_rect.position.lerp(target.position, weight),
			_highlight_rect.size.lerp(target.size, weight))
	queue_redraw()


## The band, drawn by the screen itself: a container draws before its children, so the band sits
## behind the rows' text. Its look is the theme's OptionsRowHighlight panel.
func _draw() -> void:
	if _highlighted == null:
		return
	draw_style_box(get_theme_stylebox(&"panel", HIGHLIGHT), get_global_transform().affine_inverse()
			* _highlight_rect)


## Esc or B close the screen from any tab while it shows, and the event stops here: in the pause,
## that Esc goes back to the pause instead of resuming the game. An action waiting for a key in the
## Controls tab takes its own Esc first.
func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


## Shows the screen with what Settings holds, on Audio with its tab selected. The pages are measured
## again, as what they show may have grown since the screen was last open.
func open() -> void:
	_show_settings()
	_select_tab(_audio_tab)
	_size_the_pages()
	show()
	_audio_tab.grab_focus()


## Where the band is drawn now, in global coordinates; empty while it is hidden.
func highlight_rect() -> Rect2:
	return _highlight_rect if _highlighted != null else Rect2()


func _close() -> void:
	_controls_menu.close()
	_hide_highlight()
	hide()
	closed.emit()


## Shows tab's page, and only it, marks tab as the selected one, and points the way down from the
## tabs into the page and the way up from its first row back to tab.
func _select_tab(tab: Button) -> void:
	_selected_tab = tab
	for other: Button in _pages:
		var page: Control = _pages[other]
		other.theme_type_variation = SELECTED_TAB if other == tab else TAB
		if other == tab:
			if page == _controls_menu:
				_controls_menu.open()
			else:
				page.show()
		elif page == _controls_menu:
			_controls_menu.close()
		else:
			page.hide()
	var first: Control = _first_controls[_pages[tab]]
	var last: Control = _last_controls[_pages[tab]]
	for other: Button in _pages:
		other.focus_neighbor_bottom = other.get_path_to(first)
	first.focus_neighbor_top = first.get_path_to(tab)
	last.focus_neighbor_bottom = last.get_path_to(_reset_button)
	_reset_button.focus_neighbor_top = _reset_button.get_path_to(last)
	_back_button.focus_neighbor_top = _back_button.get_path_to(last)
	_description.text = ""


## Enter or A on a tab goes into its page, onto its first control.
func _enter_page() -> void:
	_first_controls[_pages[_selected_tab]].grab_focus()


## Left and right on a tab go to the tab beside it, and round from the last to the first. Each way is
## set: where none is, Godot picks the nearest control that way, and from Controls that is the
## profile list under the tabs.
func _link_the_tabs() -> void:
	var count: int = _tabs.get_child_count()
	for index: int in count:
		var tab: Control = _tabs.get_child(index) as Control
		tab.focus_neighbor_left = tab.get_path_to(_tabs.get_child((index - 1 + count) % count))
		tab.focus_neighbor_right = tab.get_path_to(_tabs.get_child((index + 1) % count))


## The pages take the tallest one's height, so the screen never moves as the tabs change.
func _size_the_pages() -> void:
	var tallest: float = 0.0
	for tab: Button in _pages:
		tallest = maxf(tallest, _pages[tab].get_combined_minimum_size().y)
	_pages_box.custom_minimum_size.y = tallest


## The height of Description Lines lines of the description, so the screen never moves as it changes:
## the lines, the theme's spacing between wrapped lines and the label's own margins.
func _description_room() -> float:
	return (_description.get_line_height() * DESCRIPTION_LINES
			+ _description.get_theme_constant(&"line_spacing") * (DESCRIPTION_LINES - 1)
			+ _description.get_theme_stylebox(&"normal").get_minimum_size().y)


## The selected control's description, and the band behind it, the screen's one mark of the
## selection (the menu's crosses stay out of it). The band appears in place and glides after.
func _on_focus_changed(control: Control) -> void:
	if not is_ancestor_of(control):
		return
	_description.text = _descriptions.get(control, "")
	if _highlighted == null:
		_snap_highlight = true
	_highlighted = control


func _hide_highlight() -> void:
	_highlighted = null
	_highlight_rect = Rect2()
	queue_redraw()


## The rect the band covers for control, in global coordinates: a grid's whole row, the Controls
## tab's profile row, or the control alone, as a tab, Reset or Back.
func _row_rect(control: Control) -> Rect2:
	var row_box: Control = control.get_parent() as Control
	if row_box is HBoxContainer and _pages_box.is_ancestor_of(control):
		return row_box.get_global_rect()
	if not row_box is GridContainer:
		return control.get_global_rect()
	var grid: GridContainer = row_box as GridContainer
	var first: int = control.get_index() - control.get_index() % grid.columns
	var top: float = INF
	var bottom: float = -INF
	for cell: int in range(first, mini(first + grid.columns, grid.get_child_count())):
		var cell_rect: Rect2 = (grid.get_child(cell) as Control).get_global_rect()
		top = minf(top, cell_rect.position.y)
		bottom = maxf(bottom, cell_rect.end.y)
	return Rect2(grid.global_position.x, top, grid.size.x, bottom - top)


## A row of the volumes grid: the bus's name, its slider and its volume in %.
func _add_volume_row(bus: StringName) -> void:
	var title: Label = _new_row_text()
	title.text = BUS_TITLES.get(bus, String(bus))
	var slider: HSlider = _new_slider(VOLUME_STEP)
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	var volume_text: Label = _new_row_text()
	_volumes.add_child(title)
	_volumes.add_child(slider)
	_volumes.add_child(volume_text)
	_sliders[bus] = slider
	_volume_texts[bus] = volume_text
	_titles.append(title)
	_descriptions[slider] = BUS_DESCRIPTIONS.get(bus, "")


## The screen shake's row: its name, its slider and its strength in %.
func _add_screen_shake_row() -> void:
	_screen_shake_slider = _new_slider(SCREEN_SHAKE_STEP)
	_screen_shake_slider.value_changed.connect(_on_screen_shake_changed)
	_screen_shake_text = _new_row_text()
	_add_accessibility_row(SCREEN_SHAKE_TITLE, SCREEN_SHAKE_DESCRIPTION, _screen_shake_slider,
			_screen_shake_text)


## The vibration's row, under the screen shake's: its name, its slider and its strength in %.
func _add_vibration_row() -> void:
	_vibration_slider = _new_slider(VIBRATION_STEP)
	_vibration_slider.value_changed.connect(_on_vibration_changed)
	_vibration_slider.drag_started.connect(_on_vibration_drag_started)
	_vibration_slider.drag_ended.connect(_on_vibration_drag_ended)
	_vibration_slider.visibility_changed.connect(_on_vibration_visibility_changed)
	_vibration_text = _new_row_text()
	_add_accessibility_row(VIBRATION_TITLE, VIBRATION_DESCRIPTION, _vibration_slider, _vibration_text)


## The constant vibration's row, under the vibration's: its name, a switch and On or Off.
func _add_constant_vibration_row() -> void:
	_constant_vibration_check = _new_switch()
	_constant_vibration_check.toggled.connect(_settings.set_constant_vibration)
	_add_switch_row(CONSTANT_VIBRATION_TITLE, CONSTANT_VIBRATION_DESCRIPTION,
			_constant_vibration_check)


## Hold To Escape's row: its name, a switch and On or Off.
func _add_hold_to_escape_row() -> void:
	_hold_to_escape_check = _new_switch()
	_hold_to_escape_check.toggled.connect(_settings.set_hold_to_escape)
	_add_switch_row(HOLD_TO_ESCAPE_TITLE, HOLD_TO_ESCAPE_DESCRIPTION, _hold_to_escape_check)


## Show Hidden's row, the grid's last: its name, a switch and On or Off.
func _add_show_hidden_row() -> void:
	_show_hidden_check = _new_switch()
	_show_hidden_check.toggled.connect(_settings.set_show_hidden)
	_add_switch_row(SHOW_HIDDEN_TITLE, SHOW_HIDDEN_DESCRIPTION, _show_hidden_check)


func _new_switch() -> CheckButton:
	var switch: CheckButton = CheckButton.new()
	switch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return switch


## A switch's row of the accessibility grid, with its value text saying On or Off.
func _add_switch_row(title_text: String, description: String, switch: CheckButton) -> void:
	var value_text: Label = _new_row_text()
	_add_accessibility_row(title_text, description, switch, value_text)
	_say_on_or_off(switch, value_text)


## From now on, value_text says whether switch is on, as the player switches it.
func _say_on_or_off(switch: CheckButton, value_text: Label) -> void:
	_switch_texts[switch] = value_text
	switch.toggled.connect(_show_switch.bind(switch).unbind(1))


func _show_switch(switch: CheckButton) -> void:
	var value_text: Label = _switch_texts[switch]
	value_text.text = ON_TEXT if switch.button_pressed else OFF_TEXT


## A row of the accessibility grid: a title with title_text, then control and value_text; while
## control is selected, the page's line shows description.
func _add_accessibility_row(title_text: String, description: String, control: Control,
		value_text: Label) -> void:
	var title: Label = _new_row_text()
	title.text = title_text
	_accessibility.add_child(title)
	_accessibility.add_child(control)
	_accessibility.add_child(value_text)
	_titles.append(title)
	_descriptions[control] = description


## A label in a row's look.
func _new_row_text() -> Label:
	var text: Label = Label.new()
	text.theme_type_variation = ROW_TEXT
	return text


## Each grid sizes its own columns, so the titles all take the widest one's width, and the sliders
## and switches of the volumes, the display and the accessibility options line up.
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
	for switch: CheckButton in _switch_texts:
		_show_switch(switch)


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
