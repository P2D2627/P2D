class_name DemonRepelledState
extends DemonState

## REPELLED: for Repelled Time from landing after the crucifix's throw (ADR 0021), the demon stays
## still, and then chases the man again, or with no man to chase stands or walks back to its post.
## Only its own physics frames count, so a pause never shortens it.

## Physics frames the demon has stood still since it landed.
var _frames: int = 0


func enter() -> void:
	_frames = 0


func physics_update(_delta: float) -> void:
	_frames += 1
	if _frames < _demon.stats.get_repelled_frames():
		return
	if _demon.has_target():
		_demon.change_state(Demon.State.CHASE)
	else:
		_demon.stand_or_return()
