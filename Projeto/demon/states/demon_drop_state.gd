class_name DemonDropState
extends DemonState

## DROP: with Max Drop, from the end of its floor, walking off after a man out of its reach below
## it, until it lands (ADR 0042). It walks on at its Chase Speed until its body is clear of the end
## of its floor, and then falls straight down onto the floor it found below before it set off.
## Landed lower than it set off, it chases on; anything else, as when a wall stopped it before it
## got clear, it stands out of his reach, so it never walks at that end over and over. No attack
## lands while it drops.

## How much lower than where it set off, in px, the demon has to land to have got down.
const LANDED_LOWER: float = 1.0

## The demon's speed across, + to the right, until it is clear of the end of its floor.
var _speed_x: float = 0.0
## How far across, in px, it goes before it falls straight down.
var _distance: float = 0.0
## Where it set off from.
var _start: Vector2 = Vector2.ZERO
## True once it is in the air.
var _left_floor: bool = false


## Sets up the drop, right before the demon changes to DROP: speed_x across, + to the right, for
## distance px, from start.
func aim(speed_x: float, distance: float, start: Vector2) -> void:
	_speed_x = speed_x
	_distance = distance
	_start = start


func enter() -> void:
	_left_floor = false


func physics_update(delta: float) -> void:
	var left: float = _distance - absf(_demon.global_position.x - _start.x)
	var speed: float = signf(_speed_x) * minf(absf(_speed_x), maxf(left, 0.0) / delta)
	if not _demon.is_on_floor():
		_left_floor = true
		_demon.velocity.x = speed
		return
	if not _left_floor and left > 0.0:
		_demon.velocity.x = speed
		return
	_demon.velocity.x = 0.0
	if _left_floor and _demon.global_position.y - _start.y >= LANDED_LOWER:
		_demon.change_state(Demon.State.CHASE)
	else:
		_demon.change_state(Demon.State.OUT_OF_REACH)
