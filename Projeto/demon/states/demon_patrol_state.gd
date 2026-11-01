class_name DemonPatrolState
extends DemonState

## PATROL: with Patrol Width, the demon walks across its patrol at Patrol Speed, facing the way it
## walks, up to the end of Patrol Width around where it stands for now, its post or, kept off it by
## its floor, where it stopped (ADR 0043), and there pauses, standing in IDLE, and turns back; the
## end of its floor and a wall of the world turn it back sooner (ADR 0033), and so does another
## demon, with Pack Spacing (ADR 0046). Off the screen it stands
## where it is, so no demon wanders where the player cannot see it, and in the air it only falls.

## 1 for right and -1 for left: the way the demon walks its patrol next. At first, the way it faces
## at its post.
var _direction: float = 1.0


func _init(demon: Demon) -> void:
	super(demon)
	_direction = demon.get_facing()


func enter() -> void:
	_demon.turn_to(_direction)


func physics_update(delta: float) -> void:
	_demon.velocity.x = 0.0
	if _demon.chase_if_it_notices_the_man() or not _demon.is_on_floor() \
			or not _demon.is_on_screen():
		return
	var gap: float = _demon.get_stand_x() + _direction * _demon.stats.patrol_width / 2.0 \
			- _demon.global_position.x
	if absf(gap) <= Demon.POST_REACH or signf(gap) != _direction \
			or _demon.is_edge_ahead(_direction) or _demon.is_against_a_wall(_direction) \
			or _demon.is_packmate_in_the_way(_direction):
		_direction = -_direction
		_demon.change_state(Demon.State.IDLE)
		return
	_demon.turn_to(_direction)
	_demon.velocity.x = _direction * minf(_demon.stats.patrol_speed, absf(gap) / delta)
