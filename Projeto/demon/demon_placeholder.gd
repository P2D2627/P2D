extends Polygon2D

## The demon's stand-in until its art arrives: a rectangle that changes shape and lights up while
## the demon warns, in another shape for each attack, so the man sees which one is coming. It only
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

@onready var _rest_color: Color = color


## Back in its own shape and colour once the warning is over.
func _on_demon_state_changed(_previous: Demon.State, current: Demon.State) -> void:
	if current != Demon.State.WARNING:
		color = _rest_color
		scale = Vector2.ONE


func _on_demon_warning_started(attack: DemonAttack) -> void:
	if attack.animation == &"bite":
		color = bite_warning_color
		scale = bite_warning_scale
	else:
		color = warning_color
		scale = Vector2(1.0, warning_squash)
