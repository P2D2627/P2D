class_name DemonOutOfReachState
extends DemonState

## OUT_OF_REACH: while the man stands out of the demon's reach, up to Out Of Reach Wait (ADR 0033).
## With Out Of Reach Pace Width it never stands stiff (ADR 0039): it pauses turned to him and barks,
## then paces to and fro across that stretch around where it stopped, at Patrol Speed, never
## following him along under him, and at each end pauses turned to him and barks again; where a
## wall or the end of its floor stops it on his side, it hops at it. With none, it stands facing
## him. It chases him again as soon as he is back within its reach, on a floor or in the air. It
## gives up as the chase does, but not for the time a ledge or a wall hides him, since it knows he is
## up or down there; and after Out Of Reach Wait, whether it sees him or not (ADR 0039).

## Physics frames the demon has been out of the man's reach.
var _frames: int = 0
## The x the demon paces around: where it stopped.
var _anchor_x: float = 0.0
## 1 for right and -1 for left: the way it paces next, drawn as it stops.
var _direction: float = 1.0
## Physics frames it still pauses where it stopped or at the end it reached, turned to the man; at 0
## it paces. Each pause is drawn, so two demons stopped together set off and bark apart.
var _pause_frames_left: int = 0
## True through the first pause, which ends with a bark as it sets off.
var _barks_as_it_sets_off: bool = false


func enter() -> void:
	_frames = 0
	_anchor_x = _demon.global_position.x
	_pause_frames_left = 0
	_barks_as_it_sets_off = false
	if _demon.stats.out_of_reach_pace_width > 0.0:
		_direction = 1.0 if _demon.random_share() < 0.5 else -1.0
		_pause_frames_left = _demon.stats.get_out_of_reach_pause_frames(_demon.random_share())
		_barks_as_it_sets_off = true


func physics_update(delta: float) -> void:
	_demon.velocity.x = 0.0
	if not _demon.keeps_after_target(false):
		return
	if _demon.get_target_height() <= _demon.stats.get_reach_height():
		_demon.change_state(Demon.State.CHASE)
		return
	_frames += 1
	if _frames >= _demon.stats.get_out_of_reach_frames():
		_demon.give_up_out_of_reach()
		return
	if _demon.stats.out_of_reach_pace_width <= 0.0 or _pause_frames_left > 0:
		_pause_frames_left = maxi(_pause_frames_left - 1, 0)
		_demon.turn_to(_demon.get_gap_to_target())
		if _pause_frames_left == 0 and _barks_as_it_sets_off:
			_barks_as_it_sets_off = false
			_bark()
		return
	if _demon.is_on_floor():
		_pace(delta)


## Walks to the end of the stretch it paces to, and stops there, or sooner at a wall or the end of
## its floor, to pause and bark.
func _pace(delta: float) -> void:
	var gap: float = _anchor_x + _direction * _demon.stats.out_of_reach_pace_width / 2.0 \
			- _demon.global_position.x
	if _demon.is_edge_ahead(_direction) or _demon.is_against_a_wall(_direction) \
			or absf(gap) <= Demon.POST_REACH or signf(gap) != _direction:
		_bark()
		_direction = -_direction
		_pause_frames_left = _demon.stats.get_out_of_reach_pause_frames(_demon.random_share())
		return
	_demon.turn_to(_direction)
	_demon.velocity.x = _direction * minf(_demon.stats.patrol_speed, absf(gap) / delta)


## Barks turned to the man, hopping if a wall or the end of its floor stops it on his side.
func _bark() -> void:
	var to_the_man: float = signf(_demon.get_gap_to_target())
	_demon.turn_to(to_the_man)
	_demon.bark(to_the_man != 0.0
			and (_demon.is_edge_ahead(to_the_man) or _demon.is_against_a_wall(to_the_man)))
