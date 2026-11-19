class_name KeyPrompt
extends Node2D

## One key drawn in the world: next to the obstacle that teaches its action, when the tutorial has no
## band at the bottom of the screen, or over Velvet while the man is near her. It holds a
## PromptGlyph, the band's drawing, so it shows the first key the Input Map has for Action, or the
## pad's button once a pad is the device used last, and reads the key again after the pause. A
## stand-in until the art comes (S3.31). It only shows: it never reads a press.

## Shown while the action has no key or mouse button.
const NO_KEY_TEXT: String = PromptGlyph.NO_KEY_TEXT

## The action whose key it shows, such as &"jump".
@export var action: StringName = &""
## Which side of the key sits on the node: centred, or, for two keys side by side, the left one
## by its right edge and the right one by its left edge, so each grows away from the other and
## a longer name, as a pad's, never covers its neighbour.
@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

@onready var _glyph: PromptGlyph = %Glyph


func _ready() -> void:
	assert(InputMap.has_action(action), "KeyPrompt: Action %s is not in the Input Map." % action)
	_glyph.resized.connect(_place)
	_glyph.action = action
	_place()


## The text it shows now: the key's or the pad button's name, or NO_KEY_TEXT.
func get_text() -> String:
	return _glyph.get_text()


## The name of the first key or mouse button the Input Map has for action, as PromptGlyph gives it.
static func key_text(for_action: StringName) -> String:
	return PromptGlyph.key_text(for_action)


## Places the glyph on the node as Alignment says, whenever its size changes with the key's name.
func _place() -> void:
	var size: Vector2 = _glyph.size
	var x: float = -size.x / 2.0
	if alignment == HORIZONTAL_ALIGNMENT_LEFT:
		x = 0.0
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = -size.x
	_glyph.position = Vector2(x, -size.y / 2.0)
