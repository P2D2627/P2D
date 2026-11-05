@tool
class_name Gate
extends AnimatableBody2D

## A gate that bars a passage until it is unlocked, and then slides up out of the way. It stops the man
## and the demons, and the demons' sight, as rock does. Its origin is the middle of its bottom edge, on
## the floor. Put it before the level's tiles in the scene, so it slides up behind the rock. Something
## else, such as a GateUnlocker, calls unlock(). A level that starts over has its gates shut again.
## For now it is a gray box, until its art arrives.

## The gate started to slide up.
signal unlocked
## The gate is all the way up and the passage is free.
signal opened

const TILE: float = 48.0

## How wide it is, in tiles.
@export_range(1, 8) var width_tiles: int = 2:
	set(value):
		width_tiles = value
		_apply_size()
## How tall it is, in tiles: the height of the passage it bars. It slides up by as much.
@export_range(1, 32) var height_tiles: int = 4:
	set(value):
		height_tiles = value
		_apply_size()
## Seconds it takes to slide all the way up.
@export_range(0.05, 5.0, 0.05, "suffix:s") var slide_time: float = 0.8
## Its colour until its art arrives.
@export var color: Color = Color(0.55, 0.55, 0.55):
	set(value):
		color = value
		queue_redraw()

var _is_unlocked: bool = false

@onready var _shape: CollisionShape2D = %Shape


func _ready() -> void:
	_apply_size()


func _draw() -> void:
	draw_rect(_box(), color)


## Slides the gate up. Only the first call does anything.
func unlock() -> void:
	if _is_unlocked:
		return
	_is_unlocked = true
	unlocked.emit()
	var slide: Tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	slide.tween_property(self, ^"position:y", position.y - height_tiles * TILE, slide_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	slide.tween_callback(opened.emit)


func is_unlocked() -> bool:
	return _is_unlocked


## The gate's box, with its origin in the middle of its bottom edge.
func _box() -> Rect2:
	var size: Vector2 = Vector2(width_tiles, height_tiles) * TILE
	return Rect2(-size.x / 2.0, -size.y, size.x, size.y)


func _apply_size() -> void:
	if not is_node_ready():
		return
	var box: Rect2 = _box()
	var rectangle: RectangleShape2D = _shape.shape as RectangleShape2D
	rectangle.size = box.size
	_shape.position = box.get_center()
	queue_redraw()
