class_name DemonTrail
extends RefCounted

## The man's trail, which a demon with Follows Trail goes by after him, as a dog by his scent (#271):
## the floors he went by, in order, as the steps between them. One step each time he lands on a floor
## at another height than the floor he left, whatever took him off it: a jump, a fall or a drop. Each
## step keeps where he last stood on the floor he left and where he landed. The demon takes the steps
## first to last; the steps it has taken stay, so a demon thrown or fallen back down the trail takes
## them again from the floor it is on (go_to_floor). Floors are told apart by their height alone, so
## two floors at one height count as one, and walking from one to the other is no step. It keeps up to
## MAX_STEPS steps, taken or not, and forgets the first one past that. It only keeps what the demon
## tells it, once per physics frame, and allocates nothing after it is made. DemonPath is the same for
## the demon's own way back, undone last step first.

## The most steps it keeps, taken or not. Past it, the first one is forgotten.
const MAX_STEPS: int = 32
## How far apart, in px, two floors' heights may be and count as one.
const SAME_FLOOR_TOLERANCE: float = 2.0

## Where the man last stood on the floor each step left, and where he landed, first step first.
var _from: PackedVector2Array = PackedVector2Array()
var _to: PackedVector2Array = PackedVector2Array()
var _count: int = 0
## The first step the demon has not taken yet; those before it it has.
var _next: int = 0
## Where the man last stood on a floor, once he has stood on one.
var _floor: Vector2 = Vector2.ZERO
var _has_floor: bool = false
## True if the man was on a floor on the last physics frame.
var _was_on_floor: bool = false
## How many steps were ever kept, so the demon tells when the man lands somewhere new.
var _landings: int = 0


func _init() -> void:
	_from.resize(MAX_STEPS)
	_to.resize(MAX_STEPS)


## The man's feet are at at this physics frame, on a floor if on_floor.
func update(at: Vector2, on_floor: bool) -> void:
	if on_floor:
		if _has_floor and not _was_on_floor and absf(at.y - _floor.y) > SAME_FLOOR_TOLERANCE:
			_landed(at)
		_floor = at
		_has_floor = true
	_was_on_floor = on_floor


## Lets go of every step, taken or not, as when the demon is with the man again. Where he last stood
## stays, so his next landing on another floor is a step from there.
func clear() -> void:
	_count = 0
	_next = 0


## Lets go of everything, the man's last spot too, as when the demon takes after another man.
func reset() -> void:
	clear()
	_has_floor = false
	_was_on_floor = false


## How many steps the demon has still to take.
func size() -> int:
	return _count - _next


func is_empty() -> bool:
	return size() == 0


## How many steps it has ever kept, cleared, reset or forgotten since or not: it goes up by one each
## time the man lands on a floor at another height than the one he left.
func get_landings() -> int:
	return _landings


## Where the man last stood on the floor the next step leaves, and where he landed. Only while not
## is_empty().
func get_first_from() -> Vector2:
	return _from[_next]


func get_first_to() -> Vector2:
	return _to[_next]


## The demon has taken the next step: it stands on the floor that step lands on.
func drop_first() -> void:
	_next = mini(_next + 1, _count)


## For a demon on a floor at height y, in px down, that the next step does not leave: the next step
## ahead that leaves that floor, the ones before it counted as taken, as after it got ahead of him; or
## else the last step taken that leaves it, it and those after it counted as not taken, as after a
## throw or a fall back down the trail. Going back, a step taken that lands on that floor stops it:
## the demon came there by the trail, so the steps before are done, as when the man went up and came
## back down. True when one does; false, changing nothing, when no step kept leaves that floor.
func go_to_floor(y: float) -> bool:
	for step: int in range(_next, _count):
		if absf(_from[step].y - y) <= SAME_FLOOR_TOLERANCE:
			_next = step
			return true
	for step: int in range(_next - 1, -1, -1):
		if absf(_to[step].y - y) <= SAME_FLOOR_TOLERANCE:
			return false
		if absf(_from[step].y - y) <= SAME_FLOOR_TOLERANCE:
			_next = step
			return true
	return false


## Lands at at, on a floor at another height than the one he left: one more step, the first one kept
## forgotten when MAX_STEPS are kept already.
func _landed(at: Vector2) -> void:
	if _count == MAX_STEPS:
		for step: int in range(1, _count):
			_from[step - 1] = _from[step]
			_to[step - 1] = _to[step]
		_count -= 1
		_next = maxi(_next - 1, 0)
	_from[_count] = _floor
	_to[_count] = at
	_count += 1
	_landings += 1
