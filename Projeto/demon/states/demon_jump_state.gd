class_name DemonJumpState
extends DemonState

## JUMP: with Jump Height, from take-off at a step in its way, as in the way of a man out of its
## reach above it, until the demon lands (ADR 0042). It takes off with its speed up put in on the
## frame it chose the step, peaks just over the step's top, pulled down by the jump's own gravity,
## and keeps its Chase Speed across all the way, along the wall on the way up and onto the step over
## it. Landed higher than it took off, it goes back to the state it jumped in, as to the chase;
## back on the floor it took off from, as when something in the way stopped it, the demon decides
## (Demon.land_off_its_floor). No attack lands while it jumps.

## How much higher than where it took off, in px, the demon has to land to have got up the step.
const LANDED_HIGHER: float = 1.0

## The demon's speed across, + to the right, kept up through the jump.
var _speed_x: float = 0.0
## The y of the floor it took off from.
var _take_off_y: float = 0.0
## The state it jumped in.
var _for_state: Demon.State = Demon.State.CHASE


## Sets up the jump, right before the demon changes to JUMP: speed_x across, + to the right, from
## the floor at take_off_y, in for_state.
func aim(speed_x: float, take_off_y: float, for_state: Demon.State) -> void:
	_speed_x = speed_x
	_take_off_y = take_off_y
	_for_state = for_state


## The demon's physics_update runs only on the frames after the one it took off on, so on the floor
## here it has landed.
func physics_update(_delta: float) -> void:
	if not _demon.is_on_floor():
		_demon.velocity.x = _speed_x
		return
	_demon.land_off_its_floor(_for_state,
			_take_off_y - _demon.global_position.y >= LANDED_HIGHER)


func get_gravity() -> Vector2:
	return Vector2.DOWN * _demon.stats.get_jump_gravity()
