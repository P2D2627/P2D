class_name DemonTarget
extends RefCounted

## The man a demon is after, and what it remembers of him (ADR 0037): his body box, his Hurtbox, his
## speed along the floor, and where and when it last saw him. It only keeps what the demon tells it:
## the demon looks through its DemonSenses and decides in its states. Letting go of the man keeps
## where the demon last saw him, which its search goes to afterwards (ADR 0035).

## How many physics frames after the one the demon saw the man on it still counts as seeing him.
const SEEN_FRAMES: int = 1

## The man, while the demon is after him.
var _man: Node2D = null
## The man's body box and half its size, in px, while the demon is after him.
var _box: CollisionShape2D = null
var _half_size: Vector2 = Vector2.ZERO
## The man's Hurtbox while the demon is after him, or null if he has none.
var _hurtbox: Hurtbox = null
## The man's x on the last physics frame, and his speed along the floor from it, in px/s, + to the
## right: how far he went, whatever moved him, so a platform that carries him counts too.
var _last_x: float = 0.0
var _speed: float = 0.0
## Physics frames in a row the demon has been after the man without seeing him.
var _unseen_frames: int = 0
## The man's x the last time the demon saw him, and the physics frame it saw him on.
var _last_seen_x: float = 0.0
var _seen_on_frame: int = -2


## Starts after man, who the demon sees now, standing still until track says otherwise.
func take(man: Node2D) -> void:
	_man = man
	var body: CollisionObject2D = man as CollisionObject2D
	_box = body.shape_owner_get_owner(body.get_shape_owners()[0]) as CollisionShape2D
	_half_size = _box.shape.get_rect().size / 2.0
	_hurtbox = _hurtbox_of(man)
	_last_x = man.global_position.x
	_last_seen_x = _last_x
	_speed = 0.0
	_unseen_frames = 0


## Lets go of the man, and keeps where it last saw him.
func forget() -> void:
	_man = null
	_box = null
	_hurtbox = null


## True while the demon is after the man, and he is still there.
func has_man() -> bool:
	return is_instance_valid(_man)


## The man while the demon is after him, or null.
func get_man() -> Node2D:
	return _man


## The man's body box while the demon is after him, or null; and half its size, in px.
func get_box() -> CollisionShape2D:
	return _box


func get_half_size() -> Vector2:
	return _half_size


## Keeps the man's speed along the floor up to date on a physics frame of delta seconds.
func track(delta: float) -> void:
	if not has_man():
		return
	var x: float = _man.global_position.x
	_speed = (x - _last_x) / delta
	_last_x = x


## The man's speed along the floor, in px/s, + to the right.
func get_speed() -> float:
	return _speed


## The demon saw the man on physics frame frame. Only while has_man(): it reads where he is.
func saw_him(frame: int) -> void:
	_unseen_frames = 0
	_last_seen_x = _man.global_position.x
	_seen_on_frame = frame


## The demon looked and did not see the man.
func missed_him() -> void:
	_unseen_frames += 1


func get_unseen_frames() -> int:
	return _unseen_frames


## The man's x the last time the demon saw him.
func get_last_seen_x() -> float:
	return _last_seen_x


## True while the demon is after the man and saw him on physics frame frame or just before.
func sees_him_on(frame: int) -> bool:
	return has_man() and frame - _seen_on_frame <= SEEN_FRAMES


## True while the man's Hurtbox lets no hit land.
func takes_no_hits() -> bool:
	return is_instance_valid(_hurtbox) and not _hurtbox.takes_hits()


## The first Hurtbox among the man's children, where its scene puts it, or null. Looked for once,
## as the demon takes him, by index, so no list is made.
func _hurtbox_of(man: Node2D) -> Hurtbox:
	for index: int in man.get_child_count():
		var hurtbox: Hurtbox = man.get_child(index) as Hurtbox
		if hurtbox != null:
			return hurtbox
	return null
