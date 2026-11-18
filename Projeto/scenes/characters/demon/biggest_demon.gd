class_name BiggestDemon
extends Demon

## Level 1's biggest dog, at the end of phase 3: for now the regular dog, eight times its size in its scene
## (body, hit box, art and checks), with a ring around it that opens Opens the first time the man comes inside.
## How he is beaten comes later; this is only the dog and the ring.

## The gates the ring opens.
@export var opens: Array[Gate] = []

@onready var _ring: ProximityUnlocker = %GateRing


func _ready() -> void:
	super()
	_ring.gates = opens


## For the ActivityTracker: the regular dog's rect and its ring's whole reach, so it is awake whenever the man,
## always on the screen, could come inside the ring, however far the ring reaches.
func get_activity_rect() -> Rect2:
	var ring: Rect2 = Rect2(_ring.global_position - Vector2.ONE * _ring.reach, Vector2.ONE * 2.0 * _ring.reach)
	return super().merge(ring)
