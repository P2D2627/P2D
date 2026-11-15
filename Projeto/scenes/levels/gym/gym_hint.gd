@tool
class_name GymHint
extends Node2D

## A sign at the back of a station in the gym (ADR 0036) that says what to try there, in
## Portuguese, for the group. Its Label wraps the text to a fixed width and sits on an opaque panel,
## so it reads the same on any background; test_gym_hint.gd checks the text against the panel for
## the 4.5:1 contrast of WCAG AA. With no text the sign hides, so an unfilled one shows as missing.
## It shows its text in the editor too, to place it.

## Shows the text; its font, colours and panel are set in gym_hint.tscn.
@export var label: Label:
	set(value):
		label = value
		_show_text()
## What to try at this station. The first line is the station's name.
@export_multiline var text: String = "":
	set(value):
		text = value
		_show_text()


func _ready() -> void:
	if not Engine.is_editor_hint():
		assert(label != null, "GymHint: assign a Label to Label.")
	_show_text()


func _show_text() -> void:
	if label == null:
		return
	label.text = text
	visible = not text.is_empty()
