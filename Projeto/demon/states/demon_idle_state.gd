class_name DemonIdleState
extends DemonState

## IDLE: the demon stands. With Patrol Width, this is the pause at each end of its patrol (ADR
## 0033): it stands a draw between Patrol Pause Min and Max, and then sets off across its patrol.

## Physics frames the demon still pauses, standing, before it walks across its patrol; -1 until it
## draws one, on its first frame standing, so the draw follows Stats as they are then.
var _pause_frames_left: int = -1


func enter() -> void:
	_pause_frames_left = -1


func physics_update(_delta: float) -> void:
	_demon.velocity.x = 0.0
	if _demon.chase_if_it_notices_the_man() or _demon.stats.patrol_width <= 0.0:
		return
	if _pause_frames_left < 0:
		_pause_frames_left = _demon.stats.get_patrol_pause_frames(_demon.random_share())
	_pause_frames_left -= 1
	if _pause_frames_left > 0:
		return
	_demon.change_state(Demon.State.PATROL)
