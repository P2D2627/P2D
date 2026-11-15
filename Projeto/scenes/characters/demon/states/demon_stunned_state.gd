class_name DemonStunnedState
extends DemonState

## STUNNED: for Stunned Time from landing after the man broke free and threw it off (ADR 0028), the
## demon lies still, and then backs off from him or chases him again. Only its own physics frames
## count, so a pause never shortens it.

## Physics frames the demon has lain still since it landed.
var _frames: int = 0


func enter() -> void:
	_frames = 0


func physics_update(delta: float) -> void:
	_frames += 1
	if _frames >= _demon.stats.get_stunned_frames():
		_demon.back_off_or_chase(delta)
