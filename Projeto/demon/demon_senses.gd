class_name DemonSenses
extends Node

## What a demon makes out of the man, for the demon to act on (ADR 0032): who is inside its sight
## area, whether it sees him from where it stands, whether it notices him, which it does less far
## behind it, and whether it is on the screen itself. It only looks: it never moves the demon nor
## changes its state.

## How far below the top of the man's body box, in px, the demon looks for his head: a little inside
## it, so a ceiling right over him does not hide it.
const HEAD_INSET: float = 8.0

## Finds the man inside Sight Distance of the demon's eyes, seen or not.
@export var sight_area: Area2D
@export var sight_shape: CollisionShape2D
## Looks from the demon's eyes to two spots on the man: his middle, at the same height as its eyes,
## since both are about the same size, and his head. Only the world blocks it: one-way platforms do
## not hide him.
@export var line_of_sight: RayCast2D
## The demon's body box, for whether the demon is on the screen.
@export var body_box: CollisionShape2D

## The man, while he is inside the sight area, seen or not.
var _in_sight_area: Node2D = null
## Where the man's head is from his origin, found once as he comes into the sight area, so no list
## is made each frame.
var _head_offset: Vector2 = Vector2.ZERO
@onready var _body_half_size: Vector2 = body_box.shape.get_rect().size / 2.0


func _ready() -> void:
	sight_area.body_entered.connect(_on_sight_area_body_entered)
	sight_area.body_exited.connect(_on_sight_area_body_exited)


## The man inside the sight area, seen or not; null if there is none.
func get_man_in_sight_area() -> Node2D:
	return _in_sight_area if is_instance_valid(_in_sight_area) else null


## How near, in px, the man has to come to be inside the sight area.
func set_sight_distance(distance: float) -> void:
	(sight_shape.shape as CircleShape2D).radius = distance


## True when no wall stands between the demon's eyes and either the man's middle or his head, so a
## low wall or a ledge that hides one of them does not hide him. His head is known only for the man
## inside the sight area.
func can_see(man: Node2D) -> bool:
	if _is_in_view(man.global_position + line_of_sight.position):
		return true
	return man == _in_sight_area and _is_in_view(man.global_position + _head_offset)


## True when the demon, facing that way, 1 for right and -1 for left, sees the man and he is no more
## than behind_reach px behind it, the way it does not face: what it takes to notice him.
func can_notice(man: Node2D, facing: float, behind_reach: float) -> bool:
	var behind: float = (line_of_sight.global_position.x - man.global_position.x) * facing
	return behind <= behind_reach and can_see(man)


## True while some of the demon's body is on the screen, with the camera's zoom; with no camera, as
## in the tests, all of the world counts as on it.
func is_on_screen() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport.get_camera_2d() == null:
		return true
	var screen: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	return screen.intersects(Rect2(body_box.global_position - _body_half_size,
			2.0 * _body_half_size))


func _is_in_view(spot: Vector2) -> bool:
	line_of_sight.target_position = line_of_sight.to_local(spot)
	line_of_sight.force_raycast_update()
	return not line_of_sight.is_colliding()


## Keeps where the man's head is: a little inside the top of his first collision box. With no box,
## his head is his middle.
func _on_sight_area_body_entered(body: Node2D) -> void:
	_in_sight_area = body
	_head_offset = line_of_sight.position
	var man_body: CollisionObject2D = body as CollisionObject2D
	if man_body == null or man_body.get_shape_owners().is_empty():
		return
	var box: CollisionShape2D = man_body.shape_owner_get_owner(
			man_body.get_shape_owners()[0]) as CollisionShape2D
	if box != null and box.shape != null:
		_head_offset = Vector2(box.position.x,
				box.position.y - box.shape.get_rect().size.y / 2.0 + HEAD_INSET)


func _on_sight_area_body_exited(body: Node2D) -> void:
	if body == _in_sight_area:
		_in_sight_area = null
