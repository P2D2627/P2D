@tool
class_name CameraZone
extends Area2D

## A part of a level with its own camera limits and zoom, made of rectangle shapes. While the player
## is in it, the screen does not show above or below the box around them (nor past its sides, with
## Limit Horizontally). Where zones overlap, the one entered last wins; entered together, the
## smallest. The camera reads the shapes itself, so the zone monitors nothing.
## Selected in the editor, the zone shows what the screen can show in it (blue) and one screen at
## its zoom (white), as the level's GameCamera computes them.

const GROUP: StringName = &"camera_zones"
const PREVIEW_FILL: Color = Color(0.3, 0.6, 1.0, 0.12)
const PREVIEW_EDGE: Color = Color(0.3, 0.6, 1.0, 0.9)
const PREVIEW_SCREEN: Color = Color(1.0, 1.0, 1.0, 0.9)
const PREVIEW_LINE: float = 6.0
const PREVIEW_FONT_SIZE: int = 64

## On a zone shorter than the screen, where the screen sits: 1 its bottom on the zone's bottom, 0 its
## top on the zone's top.
@export_range(0.0, 1.0, 0.05) var vertical_anchor: float = 0.5:
	set(value):
		vertical_anchor = value
		queue_redraw()
## How much further than the zone's bottom the screen may show, in px. 96 = two tiles more of floor.
@export_range(0.0, 540.0, 1.0, "suffix:px") var bottom_margin: float = 0.0:
	set(value):
		bottom_margin = value
		queue_redraw()
## On: the screen does not pass the zone's sides either (shafts, rooms that hold the camera still).
@export var limit_horizontally: bool = false:
	set(value):
		limit_horizontally = value
		queue_redraw()
## With Limit Horizontally, on a zone narrower than the screen: 1 the screen's right edge on the
## zone's right edge, 0 its left on the left.
@export_range(0.0, 1.0, 0.05) var horizontal_anchor: float = 0.5:
	set(value):
		horizontal_anchor = value
		queue_redraw()
## How close the camera comes at least, 1 being the normal view. Fit Height and Auto Zoom only go
## closer.
@export_range(0.5, 3.0, 0.05) var zoom: float = 1.0:
	set(value):
		zoom = value
		queue_redraw()
## On a zone shorter than the screen, zoom in until the zone fills the screen's height (low tunnels).
@export var fit_height: bool = false:
	set(value):
		fit_height = value
		queue_redraw()
## Zoom in just enough that no other passage shows above the zone. Openings out of it still show.
@export var auto_zoom: bool = true:
	set(value):
		auto_zoom = value
		queue_redraw()

## The zone's rectangles in global coordinates, the box around them and their area. Read once in the
## game, where zones do not move; every time in the editor.
var _rects: Array[Rect2] = []
var _limits: Rect2 = Rect2()
var _area: float = 0.0
## In the editor: whether the preview is drawn, and what it was drawn from.
var _previewing: bool = false
var _preview_key: String = ""


## Before any _ready, so a camera finds every zone in its own _ready.
func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	var selected: bool = is_selected_in_editor(self)
	var key: String = str(read_rects(self)) if selected else ""
	if selected != _previewing or key != _preview_key:
		_previewing = selected
		_preview_key = key
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() or not _previewing:
		return
	var camera: GameCamera = find_editor_camera(self)
	if camera == null or camera.stats == null or get_limits().size == Vector2.ZERO:
		return
	var preview: Dictionary = camera.get_zone_view(self)
	var view: Rect2 = preview["view"]
	var screen: Vector2 = preview["screen"]
	var box: Rect2 = get_limits()
	var frame: Rect2 = Rect2(Vector2(clampf(box.get_center().x - screen.x / 2.0, view.position.x,
			view.end.x - screen.x), view.end.y - screen.y), screen)
	draw_set_transform_matrix(global_transform.affine_inverse())
	draw_rect(view, PREVIEW_FILL)
	draw_rect(view, PREVIEW_EDGE, false, PREVIEW_LINE)
	draw_preview_screen(self, frame, preview["zoom"])


func get_limits() -> Rect2:
	_read_shapes()
	return _limits


## The total area, in px². Breaks a tie between overlapping zones.
func get_area() -> float:
	_read_shapes()
	return _area


## Points on a rectangle's right and bottom edges are outside it, so touching zones never share one.
func has_point(point: Vector2) -> bool:
	_read_shapes()
	for rect: Rect2 in _rects:
		if rect.has_point(point):
			return true
	return false


## The rectangles of area's enabled rectangle shapes, in global coordinates. Rotated or skewed ones
## are left out, with an error: they do not line up with the screen. Lookouts use it too.
static func read_rects(area: Area2D) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child: Node in area.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or collision.disabled:
			continue
		var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
		if rectangle == null:
			continue
		var xform: Transform2D = collision.global_transform
		if not is_zero_approx(xform.get_rotation()) or not is_zero_approx(xform.get_skew()):
			push_error("%s: %s is rotated or skewed, so it is left out." % [area.name, collision.name])
			continue
		var size: Vector2 = rectangle.size * xform.get_scale().abs()
		rects.append(Rect2(xform.origin - size / 2.0, size))
	return rects


## In the editor, true if node or one of its children is selected.
static func is_selected_in_editor(node: Node) -> bool:
	if not Engine.has_singleton("EditorInterface"):
		return false
	var editor: Object = Engine.get_singleton("EditorInterface")
	for selected: Node in editor.call("get_selection").call("get_selected_nodes"):
		if selected == node or selected.get_parent() == node:
			return true
	return false


## The GameCamera of the scene open in the editor, or null.
static func find_editor_camera(node: Node) -> GameCamera:
	var root: Node = node.get_tree().edited_scene_root
	if root == null:
		return null
	for camera: Node in root.find_children("*", "Camera2D", true, false):
		if camera is GameCamera:
			return camera as GameCamera
	return null


## Draws, in global coordinates, one screen at its zoom, with the zoom and size written in it.
static func draw_preview_screen(item: CanvasItem, frame: Rect2, level: float) -> void:
	item.draw_rect(frame, PREVIEW_SCREEN, false, PREVIEW_LINE)
	item.draw_string(ThemeDB.fallback_font, frame.position + Vector2(24.0, 24.0 + PREVIEW_FONT_SIZE),
			"zoom %.2f  (%d x %d px)" % [level, roundi(frame.size.x), roundi(frame.size.y)],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, PREVIEW_FONT_SIZE, PREVIEW_SCREEN)


## Read once in the game, where zones do not move; every time in the editor.
func _read_shapes() -> void:
	if not _rects.is_empty() and not Engine.is_editor_hint():
		return
	_rects = read_rects(self)
	_limits = Rect2()
	_area = 0.0
	for i: int in _rects.size():
		_limits = _rects[i] if i == 0 else _limits.merge(_rects[i])
		_area += _rects[i].get_area()
