class_name DemonGrabState
extends DemonState

## GRAB: while the demon's hit holds the man (ADR 0028). It holds on where it is, falling from there
## if the hold started in the middle of a lunge, with no attack, until he breaks free and throws it
## off (THROWN). With the man gone, as on a respawn that would swap only him, nothing is left to
## break free: it lets go and stands or walks back, falling first if it is in the air.


func physics_update(_delta: float) -> void:
	_demon.velocity.x = 0.0
	if not _demon.has_target():
		_demon.stand_or_return()
