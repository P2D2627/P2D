class_name DemonOutOfReachState
extends DemonState

## OUT_OF_REACH: while the man stands out of the demon's reach, up to Out Of Reach Wait (ADR 0033).
## It stands facing him, never following him along under him, and chases him again as soon as he is
## back within its reach, on a floor or in the air. It gives up as the chase does, and after Out Of
## Reach Wait also while it still sees him.

## Physics frames the demon has stood facing the man out of its reach.
var _frames: int = 0


func enter() -> void:
	_frames = 0


func physics_update(_delta: float) -> void:
	_demon.velocity.x = 0.0
	if not _demon.keeps_after_target():
		return
	if _demon.get_target_height() <= _demon.stats.get_reach_height():
		_demon.change_state(Demon.State.CHASE)
		return
	_demon.turn_to(_demon.get_gap_to_target())
	_frames += 1
	if _frames >= _demon.stats.get_out_of_reach_frames():
		_demon.give_up_out_of_reach()
