@tool
class_name Gate
extends AnimatableBody2D

## A gate that bars a passage until it is unlocked, and then slides out of the way: up, as a door, or
## sideways, as a trapdoor across a drop. It stops the man and the demons, and the demons' sight, as rock
## does. Its origin is the middle of its bottom edge, on the floor. Put it before the level's tiles in the
## scene, so it slides behind the rock. Something
## else, such as a GateUnlocker, calls unlock(). A level that starts over has its gates shut again.
## A cutscene that shows a gate locking puts it out of the way with open_now() and slides it back
## with lock(); unlock() opens it again.
## For now it is a gray box, until its art arrives.

## The gate started to slide out of the way.
signal unlocked
## The gate is all the way out of the way and the passage is free.
signal opened
## The gate started to slide back into the passage.
signal locked
## The gate is all the way back and bars the passage again.
signal shut

## Which way a gate slides once unlocked: up, for a door in a passage; left or right, for a trapdoor lying across
## a drop, which slides sideways into the rock beside the hole.
enum SlideWay { UP, LEFT, RIGHT }

const TILE: float = 48.0

## How wide it is, in tiles.
@export_range(1, 8) var width_tiles: int = 2:
	set(value):
		width_tiles = value
		_apply_size()
## How tall it is, in tiles: the height of the passage it bars. Sliding up, it moves by as much.
@export_range(1, 32) var height_tiles: int = 4:
	set(value):
		height_tiles = value
		_apply_size()
## Which way it slides once unlocked: up by its height, or sideways by its width.
@export var slide_way: SlideWay = SlideWay.UP
## Seconds it takes to slide all the way.
@export_range(0.05, 5.0, 0.05, "suffix:s") var slide_time: float = 0.8
## Its colour until its art arrives.
@export var color: Color = Color(0.55, 0.55, 0.55):
	set(value):
		color = value
		queue_redraw()

var _is_unlocked: bool = false
## Where it bars the passage: its place in the scene.
var _shut_position: Vector2 = Vector2.ZERO
## The slide under way, or null.
var _slide: Tween = null

@onready var _shape: CollisionShape2D = %Shape


func _ready() -> void:
	_apply_size()
	_shut_position = position


func _draw() -> void:
	draw_rect(_box(), color)


## Slides the gate out of the way, Slide Way. Only a shut or locking gate does anything.
func unlock() -> void:
	if _is_unlocked:
		return
	_is_unlocked = true
	unlocked.emit()
	_slide_to(_shut_position + slide_offset(), opened.emit)


## Slides the gate back into the passage, in Slide Time, so it bars it again. Only an open or
## opening gate does anything.
func lock() -> void:
	if not _is_unlocked:
		return
	_is_unlocked = false
	locked.emit()
	_slide_to(_shut_position, shut.emit)


## Puts the gate out of the way at once, with no slide and no signal, as if it had opened long ago:
## a cutscene does it before it shows the gate locking.
func open_now() -> void:
	_stop_slide()
	_is_unlocked = true
	position = _shut_position + slide_offset()
	reset_physics_interpolation()


func is_unlocked() -> bool:
	return _is_unlocked


## How far the gate moves once unlocked, in px: up by its height, or sideways by its width.
func slide_offset() -> Vector2:
	match slide_way:
		SlideWay.LEFT:
			return Vector2(-width_tiles * TILE, 0.0)
		SlideWay.RIGHT:
			return Vector2(width_tiles * TILE, 0.0)
		_:
			return Vector2(0.0, -height_tiles * TILE)


## Slides to target in Slide Time, from wherever it is, and calls done there. A slide under way
## stops first.
func _slide_to(target: Vector2, done: Callable) -> void:
	_stop_slide()
	_slide = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_slide.tween_property(self, ^"position", target, slide_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_slide.tween_callback(done)


func _stop_slide() -> void:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = null


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
