class_name MainMenu
extends CanvasLayer

## The first screen. The main panel has the game's name, Continue while there is a save to come
## back to, Play, Options and Quit; Play opens the level panel, with a button for each level and
## Back, and Options opens the options screen. The
## menu only says what was chosen, through its signals, and the scene it is in decides what that
## does. Each panel opens with its first button selected, so the arrow keys and Enter work without
## the mouse; Esc on the level panel goes back, and coming back selects the button the player left
## from.

signal level_chosen(index: int)
signal continue_requested
## The player agreed to replace the save with the new game of the level at index.
signal new_game_confirmed(index: int)
signal quit_requested

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
@onready var _replace_save_dialog: ConfirmationDialog = %ReplaceSaveDialog


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name") as String
	_continue_button.pressed.connect(continue_requested.emit)
	_play_button.pressed.connect(_show_level_panel)
	_options_button.pressed.connect(_show_options)
	_quit_button.pressed.connect(quit_requested.emit)
	_back_button.pressed.connect(_show_main_panel.bind(_play_button))
	_options_menu.closed.connect(_show_main_panel.bind(_options_button))
	_replace_save_dialog.confirmed.connect(_on_replace_save_confirmed)
	_replace_save_dialog.canceled.connect(_on_replace_save_canceled)
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
	if _main_panel.is_visible_in_tree():
		_first_button().grab_focus()


## Shows the menu again, on the main panel with its first button selected.
func open() -> void:
	show()
	_show_main_panel(_first_button())


func _on_replace_save_confirmed() -> void:
	new_game_confirmed.emit(_asked_level)


func _on_replace_save_canceled() -> void:
	(_level_buttons.get_child(_asked_level) as Control).grab_focus()


func _first_button() -> Button:
	return _continue_button if _continue_button.visible else _play_button


## The main panel alone, with the given button selected. The options screen hides itself when it
## closes.
func _show_main_panel(selected: Button) -> void:
	_level_panel.hide()
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


func _show_options() -> void:
	_main_panel.hide()
	_options_menu.open()
