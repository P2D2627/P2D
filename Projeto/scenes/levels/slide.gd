class_name Slide
extends StaticBody2D

## A slope the player slides down, however gentle it is. Every physics frame, a body standing on
## the slope is moved down it at Slide Speed, with its own collisions, as on a conveyor belt; above
## the run speed, the slope cannot be walked up. The body's velocity is left alone, so the slide
## adds no momentum: leaving its end, the player keeps only their own speed. The slope is read from
## the CollisionPolygon2D child: its longest edge that is neither level nor upright, going downhill.
## Reshaping the polygon in the editor keeps the slide working.

## How fast the slide carries the player down its slope. Above the player's run speed, the slide
## cannot be walked up.
@export_range(0.0, 3000.0, 10.0, "suffix:px/s") var slide_speed: float = 900.0

## An edge shorter than this on either axis counts as level or upright, in px.
const STRAIGHT_TOLERANCE: float = 1.0
## How far above the slope the sensor reaches, to find the bodies standing on it, in px.
const SENSOR_HEIGHT: float = 8.0
## How closely a body's floor must face the way the slope faces to count as standing on it.
const SAME_SLOPE: float = 0.99
## The physics layer the player is on.
const PLAYER_LAYER: int = 2

## The direction down the slope, in global coordinates, and the way the slope's top faces.
var _downhill: Vector2 = Vector2.ZERO
var _surface_normal: Vector2 = Vector2.ZERO
## Finds the bodies on or just above the slope.
var _sensor: Area2D


func _ready() -> void:
	var polygon: CollisionPolygon2D = _find_polygon()
	_downhill = _downhill_of(polygon)
	if _downhill == Vector2.ZERO:
		push_warning("Slide %s: its CollisionPolygon2D has no sloped edge, so it carries nothing."
				% name)
		set_physics_process(false)
		return
	# The top of a slope going down to the right faces up and to the right, and to the left the other
	# way round.
	_surface_normal = Vector2(_downhill.y, -_downhill.x) * signf(_downhill.x)
	_sensor = _make_sensor(polygon)


func _physics_process(delta: float) -> void:
	for body: Node2D in _sensor.get_overlapping_bodies():
		var character: CharacterBody2D = body as CharacterBody2D
		if (character != null and character.is_on_floor()
				and character.get_floor_normal().dot(_surface_normal) >= SAME_SLOPE):
			character.move_and_collide(_downhill * slide_speed * delta)


func _find_polygon() -> CollisionPolygon2D:
	for child: Node in get_children():
		if child is CollisionPolygon2D:
			return child as CollisionPolygon2D
	return null


## The direction down the polygon's longest sloped edge, in global coordinates, or zero.
func _downhill_of(polygon: CollisionPolygon2D) -> Vector2:
	if polygon == null:
		return Vector2.ZERO
	var points: PackedVector2Array = polygon.global_transform * polygon.polygon
	var best: Vector2 = Vector2.ZERO
	for index: int in points.size():
		var edge: Vector2 = points[(index + 1) % points.size()] - points[index]
		var sloped: bool = (absf(edge.x) > STRAIGHT_TOLERANCE
				and absf(edge.y) > STRAIGHT_TOLERANCE)
		if sloped and edge.length() > best.length():
			best = edge
	# Downhill is where y grows.
	return (best if best.y > 0.0 else -best).normalized()


## An Area2D with the slope's shape, raised a little, so it overlaps whoever stands on it.
func _make_sensor(polygon: CollisionPolygon2D) -> Area2D:
	var sensor: Area2D = Area2D.new()
	sensor.name = "Sensor"
	sensor.collision_layer = 0
	sensor.collision_mask = PLAYER_LAYER
	sensor.monitorable = false
	var shape: CollisionPolygon2D = CollisionPolygon2D.new()
	shape.polygon = polygon.polygon
	shape.transform = polygon.transform
	shape.position += _surface_normal * SENSOR_HEIGHT
	sensor.add_child(shape)
	add_child(sensor)
	return sensor
