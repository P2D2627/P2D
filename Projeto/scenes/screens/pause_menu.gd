class_name PauseMenu
extends CanvasLayer

## The pause screen, over the game darkened by Dim: Resume, Options and Main Menu, and the options
## screen, the same one as in the main menu. Its scene starts it hidden and runs it while the game
## is paused (process mode Always). It only says which button was pressed, through its signals; Main
## pauses and resumes the game and decides what each button does.

signal resume_requested
signal main_menu_requested

## Whether Back went down while the pause showed. Only then does letting it go close the pause: the
## release of a key pressed before the pause opened, like the Esc that opened it, does nothing.
var _back_went_down_here: bool = false

@onready var _panel: Control = %Panel
@onready var _resume_button: Button = %ResumeButton
@onready var _options_button: Button = %OptionsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _options_menu: OptionsMenu = %OptionsMenu


func _ready() -> void:
	_resume_button.pressed.connect(resume_requested.emit)
	_options_button.pressed.connect(_show_options)
	_main_menu_button.pressed.connect(main_menu_requested.emit)
	_options_menu.closed.connect(_on_options_closed)


## Back (B on the gamepad) closes the pause when it is let go, as the buttons do. Closed on the
## press, the game would come back on the frame B went down, and B is also Interact. Esc is Back
## too, but it is also Pause, and Main resumes on its press first. While the options screen shows,
## it takes Back's press itself, so that Back only goes back to the pause.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action(&"ui_cancel"):
		return
	if event.is_pressed():
		_back_went_down_here = true
	elif _back_went_down_here:
		_back_went_down_here = false
		resume_requested.emit()
		get_viewport().set_input_as_handled()


## Shows the pause screen on its own panel with Resume selected, also when it was left from the
## options.
func open() -> void:
	_back_went_down_here = false
	_options_menu.hide()
	_panel.show()
	show()
	_resume_button.grab_focus()


func _show_options() -> void:
	_panel.hide()
	_options_menu.open()


func _on_options_closed() -> void:
	_panel.show()
	_options_button.grab_focus()
