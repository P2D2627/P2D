class_name KnockOff
extends RefCounted

## Keeps a body from standing on bodies on some physics layers, as the man on a demon (ADR 0022) and a
## demon on the man (ADR 0047). On every physics frame its body stands on one, it gives the way to be
## shoved off along its top: to the side of the body it is on, to the right from right over its
## middle, kept that way onto another such body, and turned the other way when something stops it.
## A body going up, as one a hit has thrown since its last move, is leaving that top, so it is not
## shoved, and the shove does not take the throw over (ADR 0056). Its body owns the speed and what
## the shove does to the rest of its movement: this only says which way. Where the shove has been
## stopped both ways, as in a hole one body wide, and the body is still on top PASS_THROUGH_FRAMES
## later, the two stop colliding with each other until their boxes are apart (ADR 0047). A held
## body is not shoved: it passes through the one it stands on at once, and then through the next
## one under it, so what holds it never holds it on top of another, as the man a dog grabs on its
## back, who sinks on the floor below it (ADR 0056). It reads the last move_and_slide(), so its body
## calls update() before moving.

## Physics frames the body stays on top once its shove was stopped both ways, before the two pass
## through each other: a tenth of a second, so a stop that clears by itself, as a demon walking off,
## never makes them pass.
const PASS_THROUGH_FRAMES: int = 6
## How far apart, in px, the two boxes must be for the bodies to collide again: more than touching,
## since on the frame they start to pass through, one still only rests on the other.
const APART_MARGIN: float = 2.0

## The way a shove carries the body along the top of one it can't stand on, 1 to the right and -1
## to the left, and 0 while it isn't on one.
var _direction: float = 0.0
## The body this one stands on, from the slide collisions; null off the floor. A frame that also
## hits something else, such as a wall, can leave the floor out of them, so it keeps the last one.
var _floor_body: CollisionObject2D = null
var _body: CharacterBody2D = null
## Whether the shove was stopped going right, and going left, since the body got on top.
var _stopped_right: bool = false
var _stopped_left: bool = false
## Physics frames on top since the shove was stopped both ways.
var _stuck_frames: int = 0
## The bodies this one passes through, with no collision between them, and their boxes around
## their origins, kept from when each started: it can stand on two at once.
var _passing: Array[PhysicsBody2D] = []
var _passing_boxes: Array[Rect2] = []
## This body's box around its origin.
var _own_box: Rect2 = Rect2()


func _init(body: CharacterBody2D) -> void:
	_body = body


## Which way to shove the body this frame, 1 to the right, -1 to the left, or 0 when it isn't on a
## body on layers, is going up, is held, or starts to pass through it. Held on one, it passes
## through it at once.
func update(layers: int, held: bool) -> float:
	_update_floor_body()
	_stop_passing_once_apart()
	var on_one: bool = is_instance_valid(_floor_body) and _floor_body.collision_layer & layers != 0
	if held and on_one:
		_pass_through(_floor_body as PhysicsBody2D)
	if held or _body.velocity.y < 0.0 or not on_one:
		_get_off()
		return _direction
	if _direction == 0.0:
		_direction = 1.0 if _body.global_position.x >= _floor_body.global_position.x else -1.0
	elif _body.is_on_wall() and _body.get_wall_normal().x * _direction < 0.0:
		_stopped_right = _stopped_right or _direction > 0.0
		_stopped_left = _stopped_left or _direction < 0.0
		_direction = -_direction
	if _stopped_right and _stopped_left:
		_stuck_frames += 1
		if _stuck_frames >= PASS_THROUGH_FRAMES:
			_pass_through(_floor_body as PhysicsBody2D)
			_get_off()
	return _direction


## True while the body is being shoved off one it can't stand on, from the last update().
func is_shoving() -> bool:
	return _direction != 0.0


## The body that body stands on, from the collisions of its last move_and_slide(), or null: off the
## floor, or on a frame whose collisions leave the floor out. On the floor, they hold it on most
## frames, one or two of them to look at.
static func floor_body_of(body: CharacterBody2D) -> CollisionObject2D:
	if not body.is_on_floor():
		return null
	for index: int in body.get_slide_collision_count():
		var collision: KinematicCollision2D = body.get_slide_collision(index)
		if collision.get_angle(body.up_direction) <= body.floor_max_angle:
			return collision.get_collider() as CollisionObject2D
	return null


## A body's first shape's box around the body's origin, unrotated and unscaled, as the bodies that
## stand on each other are.
static func box_of(body: CollisionObject2D) -> Rect2:
	var owner_id: int = body.get_shape_owners()[0]
	var box: Rect2 = body.shape_owner_get_shape(owner_id, 0).get_rect()
	return Rect2(box.position + body.shape_owner_get_transform(owner_id).origin, box.size)


## The body is no longer being shoved: what its shove met on that top is forgotten.
func _get_off() -> void:
	_direction = 0.0
	_stopped_right = false
	_stopped_left = false
	_stuck_frames = 0


## The body and other stop colliding with each other, both ways, and other's box is kept to tell
## when they are apart. It passes through each one apart from the others.
func _pass_through(other: PhysicsBody2D) -> void:
	if other == null or _passing.has(other):
		return
	_own_box = box_of(_body)
	_passing.append(other)
	_passing_boxes.append(box_of(other))
	_body.add_collision_exception_with(other)
	other.add_collision_exception_with(_body)


## Each body it passes through collides with it again once their boxes are more than APART_MARGIN
## apart, and is forgotten once gone.
func _stop_passing_once_apart() -> void:
	for index: int in range(_passing.size() - 1, -1, -1):
		if is_instance_valid(_passing[index]):
			var other: PhysicsBody2D = _passing[index]
			var own: Rect2 = Rect2(_own_box.position + _body.global_position, _own_box.size)
			var box: Rect2 = Rect2(_passing_boxes[index].position + other.global_position,
					_passing_boxes[index].size)
			if own.grow(APART_MARGIN).intersects(box):
				continue
			_body.remove_collision_exception_with(other)
			other.remove_collision_exception_with(_body)
		_passing.remove_at(index)
		_passing_boxes.remove_at(index)


## Keeps _floor_body up to date from the last move_and_slide(): on a frame whose collisions leave
## the floor out, it keeps the last one.
func _update_floor_body() -> void:
	if not _body.is_on_floor():
		_floor_body = null
		return
	var floor_body: CollisionObject2D = floor_body_of(_body)
	if floor_body != null:
		_floor_body = floor_body
