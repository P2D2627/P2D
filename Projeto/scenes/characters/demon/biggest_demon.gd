class_name BiggestDemon
extends Demon

## Level 1's biggest dog, at the end of phase 3: the regular dog half again as big in its scene (body, hit box,
## art and checks), with a ring around it that opens Opens the first time the man comes inside. It goes after
## him to the end (#271): its stats, biggest_demon_stats.tres, are the regular dog's with each distance to the
## man measured from its face, not its middle, so it sees and attacks him as far out of its body as the regular
## dog does; once it chases him it never gives up, and it jumps up as high as he jumps. His way to be rid of it is
## back round, from the last hall up to gate 3, which its ring opens, and down the chimney behind it into the hall
## again; its Max Drop reaches the chimney's depth, though it does not yet follow him that way (#201).

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
