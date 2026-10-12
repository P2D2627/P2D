class_name MainMenu
extends CanvasLayer

## The first screen. The main panel has the game's name, Play, Options and Quit; Play opens the
## level panel, with a button for each level and Back, and Options opens the options screen. The
## menu only says what was chosen, through its signals, and the scene it is in decides what that
## does. Each panel opens with its first button selected, so the arrow keys and Enter work without
## the mouse; Esc on the level panel goes back, and coming back selects the button the player left
## from.

signal level_chosen(index: int)
signal quit_requested

@onready var _title: Label = %Title
@onready var _main_panel: Control = %MainPanel
@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _level_panel: Control = %LevelPanel
@onready var _level_buttons: Container = %LevelButtons
@onready var _back_button: Button = %BackButton
@onready var _options_menu: OptionsMenu = %OptionsMenu


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name") as String
	_play_button.pressed.connect(_show_level_panel)
	_options_button.pressed.connect(_show_options)
	_quit_button.pressed.connect(quit_requested.emit)
	_back_button.pressed.connect(_show_main_panel.bind(_play_button))
	_options_menu.closed.connect(_show_main_panel.bind(_options_button))
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


## Shows the menu again, on the main panel with Play selected.
func open() -> void:
	show()
	_show_main_panel(_play_button)


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
