class_name MainMenu
extends CanvasLayer

## The first screen, over the MenuBackdrop (the character in the light), with the crosses marking
## the selected option. The main panel has Continue while there is a save to come back to, New Game
## (PlayButton), Settings (OptionsButton) and Quit; the first of them is always the biggest. The
## game's name is kept in Title, hidden. New Game starts the level at once when there is only one,
## and otherwise opens the level panel, with a button for each level and Back; Settings opens the
## options screen. The
## menu only says what was chosen, through its signals, and the scene it is in decides what that
## does. Each panel opens with its first button selected, so the arrow keys and Enter work without
## the mouse; Esc on the level panel goes back, and coming back selects the button the player left
## from. The panels sit on the right third of the screen, across from the character, centred from
## top to bottom.

signal level_chosen(index: int)
signal continue_requested
## The player agreed to replace the save with the new game of the level at index.
signal new_game_confirmed(index: int)
signal quit_requested

## The theme's look for the main panel's first option, the biggest, and for the others.
const FIRST_OPTION: StringName = &"MenuFirstOption"
const OPTION: StringName = &"MenuOption"

## The level the replace-save question is about.
var _asked_level: int = 0

@onready var _title: Label = %Title
@onready var _main_panel: Control = %MainPanel
@onready var _continue_button: Button = %ContinueButton
@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _level_panel: Control = %LevelPanel
@onready var _level_buttons: Container = %LevelButtons
@onready var _back_button: Button = %BackButton
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _backdrop: MenuBackdrop = $MenuBackdrop
@onready var _replace_save_dialog: ConfirmationDialog = %ReplaceSaveDialog
@onready var _crosses: MenuCrosses = $Crosses
@onready var _blur: ColorRect = $Blur


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name") as String
	_continue_button.pressed.connect(continue_requested.emit)
	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_show_options)
	_quit_button.pressed.connect(quit_requested.emit)
	_back_button.pressed.connect(_show_main_panel.bind(_play_button))
	_options_menu.closed.connect(_show_main_panel.bind(_options_button))
	_replace_save_dialog.confirmed.connect(_on_replace_save_confirmed)
	_replace_save_dialog.canceled.connect(_on_replace_save_canceled)
	_replace_save_dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replace_save_dialog.visibility_changed.connect(_on_replace_save_visibility_changed)
	_size_options()
	_show_main_panel(_play_button)


## Esc goes back only while the level panel shows: the menu is a node that stays in the tree while
## it is hidden, and its input callbacks run then too. The options screen handles its own Esc.
func _unhandled_input(event: InputEvent) -> void:
	if _level_panel.is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		_show_main_panel(_play_button)
		get_viewport().set_input_as_handled()


## Adds a button to the level panel for each title, in order. Pressing one sends its index with
## level_chosen.
func add_levels(titles: PackedStringArray) -> void:
	for index: int in titles.size():
		var button: Button = Button.new()
		button.text = titles[index]
		button.theme_type_variation = OPTION
		button.pressed.connect(level_chosen.emit.bind(index))
		_level_buttons.add_child(button)


## Asks before the new game of the level at index replaces the save, with No selected, so a press
## too many keeps the save.
func ask_to_replace_save(index: int) -> void:
	_asked_level = index
	_replace_save_dialog.popup_centered()
	_replace_save_dialog.get_cancel_button().grab_focus()


## Shows or hides Continue. Selected when it shows, as what most players want next.
func set_can_continue(can_continue: bool) -> void:
	_continue_button.visible = can_continue
	_size_options()
	if _main_panel.is_visible_in_tree():
		_first_button().grab_focus()


## Shows the menu again, on the main panel with its first button selected.
func open() -> void:
	show()
	_show_main_panel(_first_button())


## While the question shows, what lies behind its box is blurred, and the menu's crosses, by the
## level button, hide: the question has its own.
func _on_replace_save_visibility_changed() -> void:
	var showing: bool = _replace_save_dialog.visible
	_crosses.visible = not showing
	_blur.visible = showing
	if showing:
		_blur.position = Vector2(_replace_save_dialog.position)
		_blur.size = Vector2(_replace_save_dialog.size)


func _on_replace_save_confirmed() -> void:
	new_game_confirmed.emit(_asked_level)


## Back to the button the question came from: the level's on the level panel, or New Game when it
## started the only level at once.
func _on_replace_save_canceled() -> void:
	if _level_panel.visible:
		(_level_buttons.get_child(_asked_level) as Control).grab_focus()
	else:
		_play_button.grab_focus()


## With a single level there is nothing to choose: New Game starts it, as the list would.
func _on_play_pressed() -> void:
	if _level_buttons.get_child_count() == 1:
		level_chosen.emit(0)
	else:
		_show_level_panel()


func _first_button() -> Button:
	return _continue_button if _continue_button.visible else _play_button


## The first option shown is the biggest; the others are all the same size.
func _size_options() -> void:
	var first: Button = _first_button()
	for button: Button in [_continue_button, _play_button, _options_button, _quit_button]:
		button.theme_type_variation = FIRST_OPTION if button == first else OPTION


## The main panel alone, with the given button selected, and the character in front again. The
## options screen hides itself when it closes.
func _show_main_panel(selected: Button) -> void:
	_level_panel.hide()
	_backdrop.recede(false)
	_main_panel.show()
	selected.grab_focus()


## With no levels, Back gets the focus, so the keyboard still has a button to press.
func _show_level_panel() -> void:
	_main_panel.hide()
	_level_panel.show()
	if _level_buttons.get_child_count() > 0:
		(_level_buttons.get_child(0) as Control).grab_focus()
	else:
		_back_button.grab_focus()


## The character steps back while the options show, so the two do not fight for the eye.
func _show_options() -> void:
	_main_panel.hide()
	_backdrop.recede(true)
	_options_menu.open()
