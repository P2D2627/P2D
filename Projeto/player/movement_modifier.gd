class_name MovementModifier
extends Resource

## A change to how the player moves, put on it by something else, such as the crucifix or, later,
## the sloth level. The player combines every modifier it holds, so it never needs to know who put
## one there, and listens to each one's changed signal, so a value changed while the modifier is on
## takes effect at once. As a Resource, a modifier can also be made in the Inspector and saved, for
## a level or a zone that slows the player down.

## Share of the running speed kept, on the floor and in the air: 1 changes nothing.
@export_range(0.0, 1.0, 0.05, "or_greater") var speed_multiplier: float = 1.0:
	set(value):
		speed_multiplier = value
		emit_changed()
## Share of the jump's height kept: 1 changes nothing.
@export_range(0.0, 1.0, 0.05, "or_greater") var jump_height_multiplier: float = 1.0:
	set(value):
		jump_height_multiplier = value
		emit_changed()
## True to stop every jump, off the floor and off walls, while the modifier is on.
@export var blocks_jump: bool = false:
	set(value):
		blocks_jump = value
		emit_changed()


func _init(speed: float = 1.0, jump_height: float = 1.0, no_jump: bool = false) -> void:
	speed_multiplier = speed
	jump_height_multiplier = jump_height
	blocks_jump = no_jump
