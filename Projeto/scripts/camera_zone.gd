class_name CameraZone
extends Area2D

## A part of a level with its own camera limits: while the player is in it, the screen does not show
## past the box around its rectangle shapes. A zone can have several rectangles, for a shape like an
## L, and the zones of a level should cover it without overlapping. The camera reads the zones by
## their shapes, not by physics signals, so a zone monitors nothing: it is an Area2D, on the
## camera_bounds layer, so that its rectangles show and can be resized in the editor.

## The group every zone joins, where the camera finds them.
const GROUP: StringName = &"camera_zones"

## The zone's rectangles in global coordinates, and the box around them, read from the shapes the
## first time they are needed: a zone does not move.
var _rects: Array[Rect2] = []
var _limits: Rect2 = Rect2()


## Joins the group on entering the tree, before any node's _ready, so a camera that looks for the
## zones in its own _ready finds them all.
func _enter_tree() -> void:
	add_to_group(GROUP)


## The box around the zone's rectangles, in global coordinates.
func get_limits() -> Rect2:
	_read_shapes()
	return _limits


## True if point is inside one of the zone's rectangles. Points on a rectangle's right and bottom
## edges are not inside it, so two zones that touch never both have a point.
func has_point(point: Vector2) -> bool:
	_read_shapes()
	for rect: Rect2 in _rects:
		if rect.has_point(point):
			return true
	return false


## Reads each enabled rectangle shape with its whole global transform, so a scaled zone or shape has
## the rectangle the editor and the physics show. A rotated or skewed shape is not a rectangle that
## lines up with the screen, so it is left out, with an error.
func _read_shapes() -> void:
	if not _rects.is_empty():
		return
	for child: Node in get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or collision.disabled:
			continue
		var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
		if rectangle == null:
			continue
		var xform: Transform2D = collision.global_transform
		if not is_zero_approx(xform.get_rotation()) or not is_zero_approx(xform.get_skew()):
			push_error("CameraZone %s: %s is rotated or skewed, so it is left out of the zone."
					% [name, collision.name])
			continue
		var size: Vector2 = rectangle.size * xform.get_scale().abs()
		var rect: Rect2 = Rect2(xform.origin - size / 2.0, size)
		_limits = rect if _rects.is_empty() else _limits.merge(rect)
		_rects.append(rect)
