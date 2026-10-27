class_name DemonJumpState
extends DemonState

## JUMP: with Jump Height, from take-off at a step in the way of a man out of its reach above it
## until the demon lands (ADR 0042). It takes off with its speed up put in on the frame it chose the
## step, peaks just over the step's top, pulled down by the jump's own gravity, and keeps its Chase
## Speed across all the way, along the wall on the way up and onto the step over it. Landed higher
## than it took off, it chases on; back on the floor it took off from, as when something in the way
## stopped it, it stands out of the man's reach, so it never hops at that step over and over. No
## attack lands while it jumps.

## How much higher than where it took off, in px, the demon has to land to have got up the step.
const LANDED_HIGHER: float = 1.0

## The demon's speed across, + to the right, kept up through the jump.
var _speed_x: float = 0.0
## The y of the floor it took off from.
var _take_off_y: float = 0.0


## Sets up the jump, right before the demon changes to JUMP: speed_x across, + to the right, from
## the floor at take_off_y.
func aim(speed_x: float, take_off_y: float) -> void:
	_speed_x = speed_x
	_take_off_y = take_off_y


## The demon's physics_update runs only on the frames after the one it took off on, so on the floor
## here it has landed.
func physics_update(_delta: float) -> void:
	if not _demon.is_on_floor():
		_demon.velocity.x = _speed_x
		return
	_demon.velocity.x = 0.0
	if _take_off_y - _demon.global_position.y >= LANDED_HIGHER:
		_demon.change_state(Demon.State.CHASE)
	else:
		_demon.change_state(Demon.State.OUT_OF_REACH)


func get_gravity() -> Vector2:
	return Vector2.DOWN * _demon.stats.get_jump_gravity()
