class_name DemonGrabState
extends DemonState

## GRAB: while the demon's hit holds the man (ADR 0028). It holds on where it is, falling from there
## if the hold started in the middle of a lunge, with no attack, until he breaks free and throws it
## off (THROWN).


func physics_update(_delta: float) -> void:
	_demon.velocity.x = 0.0
