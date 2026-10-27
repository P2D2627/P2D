class_name DemonRetreatState
extends DemonState

## RETREAT: with Retreat Distance in Stats, after each attack (ADR 0023). The demon backs off from
## the man at its Retreat Speed, facing him, with no attack, until he is its Retreat Distance away or
## it has backed off for as long as that takes, and then chases him again, so it never stays on him.
## An edge behind it stops it where it is, and a wall stops its body.

## Physics frames the demon has backed off for.
var _frames: int = 0


func enter() -> void:
	_frames = 0


func physics_update(_delta: float) -> void:
	if not _demon.keeps_after_target():
		return
	var gap: float = _demon.get_gap_to_target()
	_demon.turn_to(gap)
	if absf(gap) >= _demon.retreat_distance() or _frames >= _demon.retreat_max_frames():
		_demon.velocity.x = 0.0
		_demon.change_state(Demon.State.CHASE)
		return
	_frames += 1
	var away: float = -_demon.get_facing()
	_demon.velocity.x = 0.0 if _demon.is_on_floor() and _demon.is_edge_ahead(away) \
			else away * _demon.retreat_speed()
