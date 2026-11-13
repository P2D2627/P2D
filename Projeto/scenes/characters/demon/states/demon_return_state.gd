class_name DemonReturnState
extends DemonState

## RETURN: with Return Speed, from giving up on the man until the demon is back at its post, or as
## near it as it can get. Off its post's floor, it first undoes its way there (ADR 0042), last step
## first: it walks back to where it left the floor it came from, and jumps up or leaps down onto that
## floor, at its Chase Speed, as in the chase. On its post's floor, or at a step of its way it
## cannot undo, as a drop deeper than Max Drop or a step higher than Jump Height, it walks toward
## its post at Return Speed, facing the way it walks, and once there stands facing the way it was
## put. The end of its floor, a wall of the world or, with Pack Spacing, another demon (ADR 0046) on
## the way stops it where it is, which is where
## it stands and patrols around for now, so a demon thrown to another floor never stays trying to get back; its
## post never changes, and it tries for it again the next time it gives up (ADR 0043). In the air,
## it only falls.

## True once a step of its way could not be undone on this way back, so it walks toward its post on
## this floor from then on, instead of turning between the two.
var _way_blocked: bool = false


func enter() -> void:
	_way_blocked = false


func physics_update(delta: float) -> void:
	if _demon.chase_if_it_notices_the_man():
		return
	if not _demon.is_on_floor():
		_demon.velocity.x = 0.0
		return
	if not _way_blocked and not _demon.get_way_back().is_empty():
		if _demon.goes_back_a_step(delta):
			return
		_way_blocked = true
	var gap: float = _demon.get_post().x - _demon.global_position.x
	var direction: float = signf(gap)
	if absf(gap) <= Demon.POST_REACH or _demon.is_edge_ahead(direction) \
			or _demon.is_against_a_wall(direction) or _demon.is_packmate_in_the_way(direction):
		_demon.stop_returning_here()
		return
	_demon.turn_to(direction)
	_demon.velocity.x = direction * minf(_demon.stats.return_speed, absf(gap) / delta)
