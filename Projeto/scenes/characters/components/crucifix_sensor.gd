class_name CrucifixSensor
extends Repellable

## Something the crucifix reaches but does not move, such as a gate's unlocker. The crucifix only knows
## Repellables, so this is one that stays where it is and only says it was reached, through repelled,
## on every physics frame the raised crucifix's radius overlaps it. Give it a CollisionShape2D child
## and put it on the repellable physics layer, as components/repellable.tscn does, with monitoring off.


## Nothing to check: unlike a Repellable, it has no Target to move.
func _ready() -> void:
	pass


## Says the crucifix at origin reached it, and moves nothing.
func push_away_from(origin: Vector2, _distance: float) -> void:
	repelled.emit(origin)
