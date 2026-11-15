@tool
class_name CollapsingPlatform
extends Node2D

## A platform that looks and acts like the levels' one-way platform, the same tile on the same layer,
## until the man lands on it: it blinks for Collapse Time and then is gone, and he falls through. Jumping
## up through it does nothing, since only standing on it counts. With Come Back Time above 0 it comes
## back after that long, so a fall never leaves him with no way up. Its origin is the top left corner of
## its first tile, so it sits on the tile grid when its position is on the grid.

## The man landed on it: it starts to blink.
signal collapsing
## It is gone: nothing stands on it now.
signal collapsed
## It is back.
signal came_back

enum Phase { STILL, BLINKING, GONE }

const TILE: float = 48.0
## The one-way platform of the levels' TileSet: an alternative of the rock tile, on its own physics
## layer.
const ONE_WAY_SOURCE: int = 0
const ONE_WAY_ATLAS: Vector2i = Vector2i.ZERO
const ONE_WAY_ALTERNATIVE: int = 1

## How wide it is, in tiles.
@export_range(1, 32) var width_tiles: int = 3:
	set(value):
		width_tiles = value
		_apply_width()
## Seconds from the landing until it is gone.
@export_range(0.05, 5.0, 0.05, "suffix:s") var collapse_time: float = 0.6
## Seconds each blink lasts, on or off.
@export_range(0.02, 0.5, 0.01, "suffix:s") var blink_interval: float = 0.08
## Seconds it stays gone before it comes back. At 0, it stays gone until the level starts over.
@export_range(0.0, 60.0, 0.5, "suffix:s") var come_back_time: float = 3.0

var _phase: Phase = Phase.STILL
## Seconds left in this phase, while BLINKING or GONE.
var _time_left: float = 0.0

@onready var _tiles: TileMapLayer = %Tiles
@onready var _sensor: Area2D = %RiderSensor
@onready var _sensor_shape: CollisionShape2D = %RiderShape


func _ready() -> void:
	_apply_width()
	set_physics_process(not Engine.is_editor_hint())


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.STILL:
			_physics_still()
		Phase.BLINKING:
			_physics_blinking(delta)
		Phase.GONE:
			_physics_gone(delta)


func get_phase() -> Phase:
	return _phase


## Starts to blink when the man stands on it. The sensor only reaches just above the tile, and the man
## rising through it is not on a floor, so jumping up through it counts for nothing.
func _physics_still() -> void:
	for body: Node2D in _sensor.get_overlapping_bodies():
		var player: CharacterBody2D = body as CharacterBody2D
		if player != null and player.is_on_floor():
			_phase = Phase.BLINKING
			_time_left = collapse_time
			collapsing.emit()
			return


func _physics_blinking(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_tiles.enabled = false
		_tiles.visible = true
		_phase = Phase.GONE
		_time_left = come_back_time
		collapsed.emit()
		return
	_tiles.visible = fmod(collapse_time - _time_left, 2.0 * blink_interval) < blink_interval


## Counts down to coming back; with Come Back Time at 0, it stays gone.
func _physics_gone(delta: float) -> void:
	if is_zero_approx(come_back_time):
		set_physics_process(false)
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_tiles.enabled = true
		_phase = Phase.STILL
		came_back.emit()


## Lays the tiles and fits the sensor to them, just above their top edge.
func _apply_width() -> void:
	if not is_node_ready():
		return
	_tiles.clear()
	for column: int in width_tiles:
		_tiles.set_cell(Vector2i(column, 0), ONE_WAY_SOURCE, ONE_WAY_ATLAS, ONE_WAY_ALTERNATIVE)
	var rectangle: RectangleShape2D = _sensor_shape.shape as RectangleShape2D
	rectangle.size.x = width_tiles * TILE
	_sensor_shape.position.x = width_tiles * TILE / 2.0
