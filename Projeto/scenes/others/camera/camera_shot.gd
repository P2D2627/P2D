@tool
class_name CameraShot
extends Node2D

## One framing of a CameraCutscene, its parent: the camera moves to show the shot's View whole (or,
## with Keep Zoom, only its middle), in Travel Time, says so with arrived, and stays there Hold Time.
## The View is the shot's ReferenceRect child, drawn over what the camera should show; the screen's
## shape leaves more around it on one side. Hook what should happen on camera to arrived, such as a gate's lock() or unlock(). The shots
## play in their order among the cutscene's children.

## The camera got to the shot: what it shows can happen now.
signal arrived

## Seconds the camera takes to get here from the shot before (or from the man, for the first).
@export_range(0.1, 10.0, 0.1, "suffix:s") var travel_time: float = 2.0
## Seconds the camera stays on the shot once there.
@export_range(0.0, 10.0, 0.1, "suffix:s") var hold_time: float = 1.5
## On: the camera keeps the zoom it had on the man and only moves to put the View's middle in the
## middle of the screen, for a quick look somewhere. Off: it zooms to show the View whole.
@export var keep_zoom: bool = false


## The View in global coordinates: the first ReferenceRect child. Empty without one.
func get_view() -> Rect2:
	for child: Node in get_children():
		if child is ReferenceRect:
			return (child as ReferenceRect).get_global_rect()
	return Rect2()


func _get_configuration_warnings() -> PackedStringArray:
	if not get_view().has_area():
		return ["Add a ReferenceRect child: the View the camera shows."]
	return []
