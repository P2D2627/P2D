@tool
class_name CameraLookout
extends Area2D

## A spot before a drop, a climb or a fork. While the player is in the lookout's rectangles, and on
## through the jump or fall that follows until it lands, the camera pulls back to show its View and
## nothing outside it. The View is the lookout's ReferenceRect child: draw it over that stretch of
## the way only, so no other path shows. A lookout goes before any camera zone.
## Selected in the editor, it shows the screen the camera will have (white). The screen never leaves
## the View, so a View shaped like the screen (16:9) shows whole.

const GROUP: StringName = &"camera_lookouts"
const VIEW_COLOR: Color = Color(1.0, 0.8, 0.2, 0.9)

## The trigger's rectangles in global coordinates and their area. Read once in the game; every time
## in the editor.
var _rects: Array[Rect2] = []
var _area: float = 0.0
var _previewing: bool = false
var _preview_key: String = ""


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	var selected: bool = CameraZone.is_selected_in_editor(self)
	var key: String = str(CameraZone.read_rects(self), get_view())
	if key != _preview_key:
		update_configuration_warnings()
	if selected != _previewing or (selected and key != _preview_key):
		queue_redraw()
	_previewing = selected
	_preview_key = key


func _draw() -> void:
	if not Engine.is_editor_hint() or not _previewing:
		return
	var camera: GameCamera = CameraZone.find_editor_camera(self)
	var view: Rect2 = get_view()
	if camera == null or camera.stats == null or not view.has_area():
		return
	var preview: Dictionary = camera.get_lookout_view(self)
	var reach: Rect2 = preview["view"]
	var screen: Vector2 = preview["screen"]
	draw_set_transform_matrix(global_transform.affine_inverse())
	draw_rect(view, VIEW_COLOR, false, CameraZone.PREVIEW_LINE)
	var frame: Rect2 = Rect2(reach.get_center() - screen / 2.0, screen)
	CameraZone.draw_preview_screen(self, frame, preview["zoom"])


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var view: Rect2 = get_view()
	if not view.has_area():
		warnings.append("Add a ReferenceRect child: the View the camera shows.")
		return warnings
	for rect: Rect2 in CameraZone.read_rects(self):
		if not view.encloses(rect):
			warnings.append("The rectangles should be inside the View, or the player can be off it.")
			break
	return warnings


## The View in global coordinates: the first ReferenceRect child. Empty without one.
func get_view() -> Rect2:
	for child: Node in get_children():
		if child is ReferenceRect:
			return (child as ReferenceRect).get_global_rect()
	return Rect2()


## The trigger's total area, in px². Between overlapping lookouts, the smallest counts.
func get_area() -> float:
	_read_shapes()
	return _area


## True if point is in one of the trigger's rectangles.
func has_point(point: Vector2) -> bool:
	_read_shapes()
	for rect: Rect2 in _rects:
		if rect.has_point(point):
			return true
	return false


## True if rect overlaps one of the trigger's rectangles.
func touches(rect: Rect2) -> bool:
	_read_shapes()
	for own: Rect2 in _rects:
		if own.intersects(rect):
			return true
	return false


func _read_shapes() -> void:
	if not _rects.is_empty() and not Engine.is_editor_hint():
		return
	_rects = CameraZone.read_rects(self)
	_area = 0.0
	for rect: Rect2 in _rects:
		_area += rect.get_area()
