class_name GrabPrompt
extends VBoxContainer

## A stand-in prompt for the grab, until its art comes: while a demon holds the man, it shows Jump's
## key (a PromptGlyph, which follows the device used last, as the tutorial's band does) and says what
## breaks him free, pressing or holding as the Hold To Escape option says on each frame drawn, so a
## change made in the pause shows as the game goes on, and shows in a bar how near he is. The words
## never name the action: the key does (#284). A bar, not a count, so a second demon joining only
## lowers it. If the time runs out, the key and the bar go and it says he fell, and stays, so a man
## who can't move never looks free until the room starts over. It only shows: it listens to
## GrabEscape, reads its progress and never changes the game. It goes as a child of the man's body,
## not of his drawing, so it stays put and readable while the drawing sinks. Its z_index (10) puts it
## over the rock, which the man stands behind, so it always shows.

const PRESS_TEXT: String = "Break free!"
const HOLD_TEXT: String = "Hold to break free"
## The death's words: the demons count deaths as falls ("Three falls on the way to me").
const DIED_TEXT: String = "Another fall."

@export var grab_escape: GrabEscape

@onready var _glyph: PromptGlyph = %Glyph
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
	_show_what_frees_him()
	_bar.value = grab_escape.get_escape_progress()


func _on_grabbed() -> void:
	_show_what_frees_him()
	_bar.value = 0.0
	_bar.show()
	_glyph.show()
	show()
	set_process(true)


func _on_died() -> void:
	_label.text = DIED_TEXT
	_glyph.hide()
	_bar.hide()
	set_process(false)


func _on_grab_ended() -> void:
	hide()
	set_process(false)


## The label only takes a new text when the option changed, so it is not laid out again each frame.
func _show_what_frees_him() -> void:
	var text: String = HOLD_TEXT if grab_escape.is_hold_to_escape() else PRESS_TEXT
	if _label.text != text:
		_label.text = text
