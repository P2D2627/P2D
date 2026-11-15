class_name KeyPrompt
extends Node2D

## One key drawn on the level's background, next to the obstacle that teaches its action: a stand-in
## until the art comes (S3.31), which swaps the Label for the key's picture. It shows the first key
## or mouse button the Input Map has for Action, as the controls screen names it, so it follows the
## profile picked in the options. The options are only reached through the pause, so it reads the
## key again when the game comes back from it. It only shows: it never reads a press.

## Shown while the action has no key or mouse button.
const NO_KEY_TEXT: String = "?"

## The action whose key it shows, such as &"jump".
@export var action: StringName = &""

@onready var _label: Label = %Label


func _ready() -> void:
	assert(InputMap.has_action(action), "KeyPrompt: Action %s is not in the Input Map." % action)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED and is_node_ready():
		refresh()


## The text it shows now: the key's name, or NO_KEY_TEXT.
func get_text() -> String:
	return _label.text


## Reads the action's key again from the Input Map, and keeps the label centred on the node.
func refresh() -> void:
	_label.text = key_text(action)
	_label.reset_size()
	_label.position = -_label.size / 2.0


## The name of the first key or mouse button the Input Map has for action, as the controls screen
## shows it; NO_KEY_TEXT with none.
static func key_text(for_action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(for_action):
		var binding: String = InputProfiles.binding_from_event(event)
		if not binding.is_empty():
			return InputProfiles.binding_title(binding)
	return NO_KEY_TEXT
