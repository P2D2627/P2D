class_name FallingRock
extends Node2D

## A pointed rock hanging from a ceiling, with its origin on the ceiling. When the player passes
## below it, down to the floor, it shakes for Warn Time, so the player sees it coming, and then
## falls. It breaks on the floor or on the player, and grows back in its place after Respawn Time,
## so it can fall again on the next try. Its Hazard is what hurts, and only while it falls. The
## floor is found once, on the first physics frame, with a ray straight down through the world.

## The rock fell from its place: the shaking is over.
signal fell
## The rock broke, on the floor or on the player.
signal broke

enum State { HANGING, SHAKING, FALLING, BROKEN }

## The physics layer the floor is on: the world.
const WORLD_LAYER: int = 1

## How long the rock shakes before it falls: the player's warning.
@export_range(0.0, 2.0, 0.05, "suffix:s") var warn_time: float = 0.4
## How far the rock moves either way while it shakes.
@export_range(0.0, 20.0, 0.5, "suffix:px") var shake_distance: float = 3.0
## How fast the falling rock speeds up, and its top speed.
@export_range(0.0, 20000.0, 10.0, "suffix:px/s²") var fall_gravity: float = 4000.0
@export_range(0.0, 5000.0, 10.0, "suffix:px/s") var max_fall_speed: float = 1600.0
## How long the rock stays away after breaking before it hangs again.
@export_range(0.0, 10.0, 0.1, "suffix:s") var respawn_time: float = 2.5
## How wide the strip below the rock is where the player makes it fall.
@export_range(16.0, 480.0, 8.0, "suffix:px") var trigger_width: float = 96.0
## How far below the ceiling the player makes the rock fall. 0 is all the way to the floor.
@export_range(0.0, 6000.0, 8.0, "suffix:px") var trigger_depth: float = 0.0
## The longest fall: with no floor closer than this, the rock breaks here.
@export_range(48.0, 10000.0, 8.0, "suffix:px") var max_fall_distance: float = 6000.0

var _state: State = State.HANGING
## Time left in the current state, while it shakes or while it is broken.
var _time_left: float = 0.0
var _fall_speed: float = 0.0
## How far the rock falls from the ceiling before its tip touches the floor. Negative until the ray
## has measured it.
var _fall_distance: float = -1.0

@onready var _rock: Node2D = %Rock
@onready var _tip: Marker2D = %Tip
@onready var _hazard: Hazard = %Hazard
@onready var _trigger: Area2D = %Trigger
@onready var _trigger_shape: CollisionShape2D = %TriggerShape


func _ready() -> void:
	_hazard.player_hit.connect(_on_player_hit.unbind(2))
	_hazard.monitoring = false
	# The trigger waits for the floor to be measured.
	_trigger.monitoring = false


func _physics_process(delta: float) -> void:
	if _fall_distance < 0.0:
		_measure_fall()
		return
	match _state:
		State.HANGING:
			if _trigger.has_overlapping_bodies():
				_state = State.SHAKING
				_time_left = warn_time
		State.SHAKING:
			_time_left -= delta
			_rock.position = Vector2(randf_range(-shake_distance, shake_distance), 0.0)
			if _time_left <= 0.0:
				_drop()
		State.FALLING:
			_fall_speed = minf(_fall_speed + fall_gravity * delta, max_fall_speed)
			_rock.position.y = minf(_rock.position.y + _fall_speed * delta, _fall_distance)
			if _rock.position.y >= _fall_distance:
				_break()
		State.BROKEN:
			_time_left -= delta
			if _time_left <= 0.0:
				_hang()


func get_state() -> State:
	return _state


## How far the rock falls before its tip touches the floor, or -1 before it is measured.
func get_fall_distance() -> float:
	return _fall_distance


## A ray from the rock's tip straight down finds the floor. The trigger then covers the strip below
## the rock, down to the floor or to Trigger Depth.
func _measure_fall() -> void:
	var from: Vector2 = _tip.global_position
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			from, from + Vector2.DOWN * max_fall_distance, WORLD_LAYER)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	_fall_distance = max_fall_distance
	if not hit.is_empty():
		_fall_distance = (hit.position as Vector2).y - from.y
	var depth: float = _tip.position.y + _fall_distance
	if trigger_depth > 0.0:
		depth = minf(depth, trigger_depth)
	# A shape of its own, so that rocks made from the same scene do not share one.
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(trigger_width, depth)
	_trigger_shape.shape = shape
	_trigger_shape.position = Vector2(0.0, depth / 2.0)
	_trigger.monitoring = true


func _drop() -> void:
	_state = State.FALLING
	_rock.position = Vector2.ZERO
	_fall_speed = 0.0
	_hazard.set_deferred(&"monitoring", true)
	fell.emit()


func _break() -> void:
	_state = State.BROKEN
	_time_left = respawn_time
	_rock.hide()
	_hazard.set_deferred(&"monitoring", false)
	broke.emit()


func _hang() -> void:
	_state = State.HANGING
	_rock.position = Vector2.ZERO
	_rock.show()


## Hitting the player breaks the rock, so it hits only once.
func _on_player_hit() -> void:
	if _state == State.FALLING:
		_break()
