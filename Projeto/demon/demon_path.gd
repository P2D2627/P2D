class_name DemonPath
extends RefCounted

## The way a demon came from its post's floor to the floor it stands on (ADR 0042), which its way
## back undoes from the last step to the first. One step each time it lands on a floor at another
## height than the floor it left, whatever took it off: its own jump or drop, a lunge, a fall or the
## crucifix's throw. Each step keeps where the demon last stood on the floor it left and where it
## landed. Floors are told apart by their height alone, so two floors at one height count as one.
## Landing back on a floor it left on the way cuts the way from there on, so going round never makes
## it longer. It keeps up to MAX_STEPS steps, and forgets the first one past that. It only keeps
## what the demon tells it, once per physics frame, and allocates nothing after it is made.

## The most steps it keeps. Past it, the first one is forgotten, and the way back then ends on the
## floor the oldest kept step left, not on its post's.
const MAX_STEPS: int = 8
## How far apart, in px, two floors' heights may be and count as one: as the jump and the drop tell
## a landing (DemonJumpState.LANDED_HIGHER, DemonDropState.LANDED_LOWER).
const SAME_FLOOR_TOLERANCE: float = 1.0

## Where the demon last stood on the floor each step left, and where it landed, first step first.
var _from: PackedVector2Array = PackedVector2Array()
var _to: PackedVector2Array = PackedVector2Array()
var _count: int = 0
## Where the demon last stood on a floor, once it has stood on one.
var _floor: Vector2 = Vector2.ZERO
var _has_floor: bool = false
## True if the demon was on a floor on the last physics frame.
var _was_on_floor: bool = false


func _init() -> void:
	_from.resize(MAX_STEPS)
	_to.resize(MAX_STEPS)


## The demon is at at this physics frame, after it moved, on a floor if on_floor.
func update(at: Vector2, on_floor: bool) -> void:
	if on_floor:
		if _has_floor and not _was_on_floor and absf(at.y - _floor.y) > SAME_FLOOR_TOLERANCE:
			_landed(at)
		_floor = at
		_has_floor = true
	_was_on_floor = on_floor


## How many steps it keeps; 0 on its post's floor.
func size() -> int:
	return _count


func is_empty() -> bool:
	return _count == 0


## Where the demon last stood on the floor that step left, and where it landed, from 0, the first
## step, to size() - 1, the step onto the floor it stands on.
func get_from(step: int) -> Vector2:
	return _from[step]


func get_to(step: int) -> Vector2:
	return _to[step]


## The step onto the floor the demon stands on, which its way back undoes first: where it last stood
## on the floor it left. Only while not is_empty().
func get_last_from() -> Vector2:
	return _from[_count - 1]


## Lands at at, on a floor at another height than the one it left: back on a floor it left on the
## way, the way is cut there; otherwise one more step.
func _landed(at: Vector2) -> void:
	for step: int in _count:
		if absf(_from[step].y - at.y) <= SAME_FLOOR_TOLERANCE:
			_count = step
			return
	if _count == MAX_STEPS:
		for step: int in range(1, MAX_STEPS):
			_from[step - 1] = _from[step]
			_to[step - 1] = _to[step]
		_count -= 1
	_from[_count] = _floor
	_to[_count] = at
	_count += 1
