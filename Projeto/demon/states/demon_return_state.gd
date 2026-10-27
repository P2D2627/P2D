class_name DemonReturnState
extends DemonState

## RETURN: with Return Speed, from giving up on the man until the demon is back at its post, or as
## near it as its floor lets it go. It walks back at Return Speed, facing the way it walks, and once
## there stands facing the way it was put. The end of its floor or a wall of the world on the way
## stops it where it is, which is where it stands and patrols around for now, so a demon thrown to
## another floor never stays trying to get back; its post never changes, and it tries for it again
## the next time it gives up (ADR 0043). In the air, it only falls.


func physics_update(delta: float) -> void:
	if _demon.chase_if_it_notices_the_man():
		return
	if not _demon.is_on_floor():
		_demon.velocity.x = 0.0
		return
	var gap: float = _demon.get_post().x - _demon.global_position.x
	var direction: float = signf(gap)
	if absf(gap) <= Demon.POST_REACH or _demon.is_edge_ahead(direction) \
			or _demon.is_against_a_wall(direction):
		_demon.stand_here()
		_demon.velocity.x = 0.0
		_demon.turn_to(_demon.post_facing())
		_demon.change_state(Demon.State.IDLE)
		return
	_demon.turn_to(direction)
	_demon.velocity.x = direction * minf(_demon.stats.return_speed, absf(gap) / delta)
