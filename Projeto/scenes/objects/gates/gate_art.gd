@tool
class_name GateArt
extends Node2D

## The look of a gate: a door of stone blocks in a frame, a post behind it and a pillar in front. Its
## gate calls it: Build when its size or way changes, Play Open and Play Close as it starts to slide,
## Show Open and Show Shut when the slide ends or when it is put out of the way at once, so the gate's
## slide is the one clock. A door (Slide Way up, Stays In Place) stays where it bars the passage while
## its gate's body slides into the rock, since the gate moves it back by as much as it slides, and
## plays its opening (it topples out) or its closing over the gate's Slide Time, so the door is gone
## when the gate says the passage is free; its frame stays. It stays a child drawn in the gate's place
## in the level, so it draws behind what comes after the gate, as the man, the demons and the rock. A
## trapdoor (left or right) is the still door laid on its side, as long as the gate is wide, its top on
## the gate's top, where the man stands, which slides with the body, with no frame; it is thicker than
## the gate and hangs below it. The door keeps the drawing's shape: what stands above the gate's top
## is hidden by the rock, which the level draws over the gate.

const STILL_CELL: int = 0

## The door's drawing: a horizontal sheet of Door Cells, the still door first, then the opening's
## cells and the closing's.
@export var door_sheet: Texture2D
@export_range(1, 64) var door_cells: int = 20
@export_range(0, 63) var opening_first: int = 1
@export_range(1, 64) var opening_count: int = 10
@export_range(0, 63) var closing_first: int = 11
@export_range(1, 64) var closing_count: int = 9
## The frame's layers, cut to the same box as the door's cells, so they line up with it.
@export var frame_back: Texture2D
@export var frame_front: Texture2D

@export_group("Fit")
## The still door in a cell, in the cell's px, measured on the drawing: its width, its height and the
## middle of its bottom edge.
@export var door_width_in_cell: float = 117.0
@export var door_height_in_cell: float = 410.0
@export var door_bottom_middle_in_cell: Vector2 = Vector2(120.5, 526.0)

var _door: Sprite2D
var _back: Sprite2D
var _front: Sprite2D
var _tween: Tween
var _sideways: bool = false


func _ready() -> void:
	_back = _make_layer(frame_back, 1)
	_door = _make_layer(door_sheet, door_cells)
	_front = _make_layer(frame_front, 1)


## Fits the art to a gate Size px big whose origin is the middle of its bottom edge, standing up as a
## door or, Sideways, lying across a drop as a trapdoor.
func build(size: Vector2, sideways: bool) -> void:
	if _door == null:
		return
	_sideways = sideways
	var factor: float = (size.x / door_height_in_cell) if sideways else (size.x / door_width_in_cell)
	for layer: Sprite2D in [_back, _door, _front]:
		layer.scale = Vector2(factor, factor)
		layer.visible = not sideways or layer == _door
		if sideways:
			# The door's middle a quarter turn round, centred across the box, with its top, half its
			# width above its middle, on the box's top.
			layer.offset = -(door_bottom_middle_in_cell - Vector2(0.0, door_height_in_cell / 2.0))
			layer.position = Vector2(0.0, -size.y + door_width_in_cell * factor / 2.0)
			layer.rotation = PI / 2.0
		else:
			layer.offset = -door_bottom_middle_in_cell
			layer.position = Vector2.ZERO
			layer.rotation = 0.0
	_show_cell(STILL_CELL)


## True for a door, which stays where it bars the passage while the gate's body slides away; false
## for a trapdoor, which goes with it.
func stays_in_place() -> bool:
	return not _sideways


## The gate started to open: a door plays its opening over Seconds.
func play_open(seconds: float) -> void:
	if not _sideways:
		_play(opening_first, opening_count, seconds)


## The gate started to shut: a door plays its closing over Seconds.
func play_close(seconds: float) -> void:
	if not _sideways:
		_play(closing_first, closing_count, seconds)


## The gate is out of the way: no door shows.
func show_open() -> void:
	if _sideways:
		return
	_stop()
	_door.visible = false


## The gate bars the passage: the still door.
func show_shut() -> void:
	_stop()
	_show_cell(STILL_CELL)


func get_door() -> Sprite2D:
	return _door


func get_frame_layers() -> Array[Sprite2D]:
	return [_back, _front]


func _make_layer(texture: Texture2D, cells: int) -> Sprite2D:
	var layer := Sprite2D.new()
	layer.texture = texture
	layer.hframes = cells
	layer.centered = false
	add_child(layer)
	return layer


## Cells First to First + Count - 1 in turn, each Seconds / Count, in step with the gate's slide.
func _play(first: int, count: int, seconds: float) -> void:
	_stop()
	_show_cell(first)
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for cell: int in range(first + 1, first + count):
		_tween.tween_interval(seconds / count)
		_tween.tween_callback(_show_cell.bind(cell))


func _show_cell(cell: int) -> void:
	_door.frame = cell
	_door.visible = true


func _stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
