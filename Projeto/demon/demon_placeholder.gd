extends Polygon2D

## The demon's stand-in until its art arrives: a rectangle that changes shape and lights up while
## the demon warns, in another shape for each attack, so the man sees which one is coming, and lies
## flat and dark while the demon is stunned, so he sees he has time to get away (ADR 0028). It only
## listens to the demon's state_changed and warning_started, wired in demon.tscn, and goes when
## the art comes.

## The colour while the demon warns of a lunge: much lighter than the rectangle's own, so the
## warning shows also to whom does not tell red from orange; the crouch shows it too.
@export var warning_color: Color = Color(1.0, 0.6, 0.25)
## The rectangle's height while the demon warns of a lunge, as a fraction of its own. Its feet stay
## on the floor.
@export_range(0.1, 1.0, 0.05) var warning_squash: float = 0.7
## The colour while the demon warns of a bite. The shape, not this, tells a bite from a lunge.
@export var bite_warning_color: Color = Color(1.0, 0.85, 0.4)
## The rectangle's size while the demon warns of a bite, as a fraction of its own: wider and a
## little lower, where a lunge only crouches. Its feet stay on the floor.
@export var bite_warning_scale: Vector2 = Vector2(1.3, 0.9)
## The rectangle's size while the demon lies stunned, as a fraction of its own: flat and wide, as if
## knocked down, lower than either warning, so the shape tells it apart. Its feet stay on the floor.
@export var stunned_scale: Vector2 = Vector2(1.4, 0.45)
## The colour while the demon lies stunned: darker than the rectangle's own, where the warnings are
## lighter.
@export var stunned_color: Color = Color(0.32, 0.08, 0.11)
## The rectangle's Z Index while the demon lunges: above the other demons', so a lunge over one of
## them reads as a leap past it, not into it.
@export var lunge_z_index: int = 1
## The rectangle's Z Index while the demon holds the man: above his, which the level draws after
## its demons, so he reads as held in its jaws, not standing in front of it.
@export var grab_z_index: int = 1

@onready var _rest_color: Color = color
@onready var _rest_z_index: int = z_index


## Flat and dark while stunned, back in its own shape and colour once the warning or the stun is
## over, drawn over the other demons while it lunges, and over the man while it holds him.
func _on_demon_state_changed(_previous: Demon.State, current: Demon.State) -> void:
	match current:
		Demon.State.LUNGE:
			z_index = lunge_z_index
		Demon.State.GRAB:
			z_index = grab_z_index
		_:
			z_index = _rest_z_index
	if current == Demon.State.STUNNED:
		color = stunned_color
		scale = stunned_scale
	elif current != Demon.State.WARNING:
		color = _rest_color
		scale = Vector2.ONE


func _on_demon_warning_started(attack: DemonAttack) -> void:
	if attack.animation == &"bite":
		color = bite_warning_color
		scale = bite_warning_scale
	else:
		color = warning_color
		scale = Vector2(1.0, warning_squash)
