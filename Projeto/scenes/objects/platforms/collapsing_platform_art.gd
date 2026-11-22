@tool
class_name CollapsingPlatformArt
extends Node2D

## The look of a collapsing platform: a thin stone slab that cracks while the platform counts down and
## breaks apart as it goes. Its platform calls it: Build when its width changes, Show Crack while it
## counts down, Break Apart when it is gone and Restore when it is back. A platform wider than Max Tiles
## takes one slab per Max Tiles, side by side, every other one mirrored, as the level's one-way slabs
## do. The slabs keep the drawing's shape, so a narrow platform has a thinner slab. The platform's own
## tiles are left as they were: the lighting rig draws them clear, and without it they still blink.

## The drawing: a horizontal sheet of Frames cells, from the whole slab to its last pieces.
@export var sheet: Texture2D
@export_range(1, 32) var frames: int = 7
## The first Crack Frames cells show in turn while the platform counts down; the rest play as it goes.
@export_range(1, 32) var crack_frames: int = 5

@export_group("Timing")
## Seconds each of the breaking cells shows.
@export_range(0.02, 0.5, 0.01, "suffix:s") var break_frame_time: float = 0.11
## Seconds the last pieces take to fade out.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_out_time: float = 0.2
## Seconds the whole slab takes to fade back in when the platform comes back.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_in_time: float = 0.25

@export_group("Fit")
## The widest run of tiles one slab covers.
@export_range(1, 16) var max_tiles: int = 4
## Where the whole slab sits in a cell, as shares of the cell, measured on the drawing: its left and
## right margins, and the stones' mean top below the cell's top, which goes on the tiles' top.
@export_range(0.0, 0.5, 0.0001) var left_margin: float = 0.0117
@export_range(0.0, 0.5, 0.0001) var right_margin: float = 0.0151
@export_range(0.0, 0.5, 0.0001) var top_in_cell: float = 0.0334

var _frame: int = 0
var _slabs: Array[Sprite2D] = []
var _tween: Tween


## The crack cell for a countdown Progress from 0 (just landed) to 1 (gone), out of Crack Count cells.
static func crack_frame(progress: float, crack_count: int) -> int:
	return clampi(floori(progress * crack_count), 0, crack_count - 1)


## Lays the slabs over a platform Width Tiles wide, Tile Size px each, whose top left corner is this
## node's origin.
func build(width_tiles: int, tile_size: float) -> void:
	for slab: Sprite2D in _slabs:
		slab.queue_free()
	_slabs.clear()
	if sheet == null or width_tiles <= 0:
		return
	var cell := Vector2(sheet.get_width() / float(frames), sheet.get_height())
	var count: int = ceili(float(width_tiles) / float(max_tiles))
	var slab_width: float = width_tiles * tile_size / float(count)
	var factor: float = slab_width / (cell.x * (1.0 - left_margin - right_margin))
	for k: int in count:
		var slab := Sprite2D.new()
		slab.texture = sheet
		slab.hframes = frames
		slab.frame = _frame
		slab.centered = false
		slab.flip_h = k % 2 == 1
		slab.scale = Vector2(factor, factor)
		var margin: float = right_margin if slab.flip_h else left_margin
		slab.position = Vector2(k * slab_width - margin * cell.x * factor, -top_in_cell * cell.y * factor)
		add_child(slab)
		_slabs.append(slab)


func get_frame() -> int:
	return _frame


func get_slabs() -> Array[Sprite2D]:
	return _slabs


## While the platform counts down: the crack cell for Progress, 0 at the landing and 1 when it goes.
func show_crack(progress: float) -> void:
	_set_frame(crack_frame(progress, crack_frames))


## The platform is gone: the breaking cells play in turn, then the pieces fade out.
func break_apart() -> void:
	_restart_tween()
	for cell: int in range(crack_frames, frames):
		_tween.tween_callback(_set_frame.bind(cell))
		_tween.tween_interval(break_frame_time)
	_tween.tween_property(self, "modulate:a", 0.0, fade_out_time)


## The platform is back: the whole slab fades in.
func restore() -> void:
	_restart_tween()
	_set_frame(0)
	modulate.a = 0.0
	_tween.tween_property(self, "modulate:a", 1.0, fade_in_time)


func _set_frame(cell: int) -> void:
	if cell == _frame:
		return
	_frame = cell
	for slab: Sprite2D in _slabs:
		slab.frame = cell


func _restart_tween() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
