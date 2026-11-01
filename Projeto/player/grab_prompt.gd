class_name GrabPrompt
extends VBoxContainer

## A stand-in prompt for the grab, until its art comes: while a demon holds the man, it says what
## breaks him free and shows in a bar how near he is. A bar, not a count, so a second demon joining
## only lowers it. If the time runs out, it says he died and stays, with no bar, so a man who can't
## move never looks free until the room starts over. It only shows: it listens to GrabEscape, reads
## its progress and never changes the game. It goes as a child of the man's body, not of his
## drawing, so it stays put and readable while the drawing sinks.

const PRESS_TEXT: String = "Press Jump!"
const HOLD_TEXT: String = "Hold Jump!"
const DIED_TEXT: String = "You died"

@export var grab_escape: GrabEscape

@onready var _label: Label = %Label
@onready var _bar: ProgressBar = %Bar


## Hidden and still first, so a scene run without a GrabEscape only fails the assert.
func _ready() -> void:
	_on_grab_ended()
	assert(grab_escape != null, "GrabPrompt: assign the player's GrabEscape to Grab Escape.")
	grab_escape.grabbed.connect(_on_grabbed)
	grab_escape.broke_free.connect(_on_grab_ended)
	grab_escape.died.connect(_on_died)


func _process(_delta: float) -> void:
	_bar.value = grab_escape.get_escape_progress()


func _on_grabbed() -> void:
	_label.text = HOLD_TEXT if grab_escape.hold_to_escape else PRESS_TEXT
	_bar.value = 0.0
	_bar.show()
	show()
	set_process(true)


func _on_died() -> void:
	_label.text = DIED_TEXT
	_bar.hide()
	set_process(false)


func _on_grab_ended() -> void:
	hide()
	set_process(false)
