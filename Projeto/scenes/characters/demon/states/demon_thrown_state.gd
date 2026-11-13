class_name DemonThrownState
extends DemonState

## THROWN: from the man breaking free or the crucifix's touch until the demon lands. The throw starts
## on the first physics frame in THROWN, with its velocity put in after that frame's gravity, as a
## lunge takes off, so it peaks at Throw Height, pulled down by the throw's own gravity. In the air,
## it only goes across and falls from where it is, so a throw in the middle of a lunge never takes
## it above Lunge Height. It is in the air from then until it lands, with no attack. Thrown by the
## crucifix, it then stays still for Repelled Time (REPELLED); by the man breaking free, it lies
## stunned for Stunned Time (STUNNED, ADR 0028), or with none backs off from him or chases him again
## at once, as after an attack.

## True once the throw has started, on the first physics frame in THROWN.
var _started: bool = false
## 1 when the demon is thrown off to the right, -1 to the left.
var _direction: float = 0.0
## True when the crucifix threw the demon off: once it lands, it stays still for Repelled Time.
var _repelled_on_landing: bool = false


## Sets up the throw, right before the demon changes to THROWN: direction 1 to the right and -1 to
## the left, and with repelled_on_landing, still for Repelled Time once it lands.
func aim(direction: float, repelled_on_landing: bool) -> void:
	_direction = direction
	_repelled_on_landing = repelled_on_landing


func enter() -> void:
	_started = false


func physics_update(delta: float) -> void:
	if not _started:
		var fall: float = maxf(_demon.velocity.y, 0.0)
		_demon.velocity = _demon.stats.get_throw_velocity() * Vector2(_direction, 1.0)
		if not _demon.is_on_floor():
			_demon.velocity.y = fall
		_started = true
	elif _demon.is_on_floor():
		_demon.velocity.x = 0.0
		if _repelled_on_landing:
			_demon.change_state(Demon.State.REPELLED)
		elif _demon.stats.get_stunned_frames() > 0:
			_demon.change_state(Demon.State.STUNNED)
		else:
			_demon.back_off_or_chase(delta)


func get_gravity() -> Vector2:
	return Vector2.DOWN * _demon.stats.get_throw_gravity()
