class_name DemonDropState
extends DemonState

## DROP: with Max Drop, from the end of its floor, leaping down, as after a man out of its reach
## below it, until it lands (ADR 0042). It walks on at its Chase Speed to where it takes off, if it
## is short of it, and leaps as it lunges, pulled down by the leap's own gravity, keeping its Chase
## Speed across all the way down onto the floor its arc lands on. Landed lower than it set off, it
## goes back to the state it dropped in, as to the chase; anything else, as when something in the
## way stopped it, on the way to where it takes off or in the leap, the demon decides
## (Demon.land_off_its_floor). No attack lands while it drops.

## How much lower than where it set off, in px, the demon has to land to have got down.
const LANDED_LOWER: float = 1.0
## How near where it takes off, in px, the demon walking there has to be to be there.
const TAKE_OFF_REACH: float = 0.5

## The take-off velocity of the leap, + to the right and down.
var _leap: Vector2 = Vector2.ZERO
## How far, in px, it walks along its floor before it takes off.
var _walk: float = 0.0
## Where it set off from.
var _start: Vector2 = Vector2.ZERO
## How far, in px, it has walked by the last physics frame.
var _walked: float = 0.0
## True once it has taken off.
var _leapt: bool = false
## True once it is in the air.
var _left_floor: bool = false
## The state it dropped in.
var _for_state: Demon.State = Demon.State.CHASE


## Sets up the drop, right before the demon changes to DROP: a leap with take-off velocity leap,
## after walking walk px from start, in for_state; with no walk, the demon has taken off already.
func aim(leap: Vector2, walk: float, start: Vector2, for_state: Demon.State) -> void:
	_leap = leap
	_walk = walk
	_start = start
	_for_state = for_state


func enter() -> void:
	_leapt = _walk <= 0.0
	_left_floor = false
	_walked = 0.0


func physics_update(delta: float) -> void:
	if not _demon.is_on_floor():
		_left_floor = true
		_demon.velocity.x = _leap.x
		return
	if not _leapt:
		var walked: float = absf(_demon.global_position.x - _start.x)
		var left: float = _walk - walked
		if left > TAKE_OFF_REACH and is_equal_approx(walked, _walked):
			_demon.land_off_its_floor(_for_state, false)
			return
		_walked = walked
		if left > TAKE_OFF_REACH:
			_demon.velocity.x = signf(_leap.x) * minf(absf(_leap.x), left / delta)
			return
		_leapt = true
		_demon.velocity = _leap
		_demon.take_off()
		return
	_demon.land_off_its_floor(_for_state,
			_left_floor and _demon.global_position.y - _start.y >= LANDED_LOWER)


func get_gravity() -> Vector2:
	return Vector2.DOWN * _demon.stats.get_jump_gravity()
