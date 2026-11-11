class_name ParallaxSprite
extends Sprite2D
## A drawing in the distance that slides sideways slower than the world as the camera passes, for depth. It sits
## where it was placed in the editor when the camera's middle is right over it, so it is placed by eye; away from
## it, it trails the camera by 1 - Depth of the camera's move. It only slides sideways, so it stays on its floor,
## and only between Min X and Max X, so it never slides into another room. It is a member of the level's
## ActivityTracker, so far off the screen it sleeps, and with it the script that slides it.

## 1 moves with the world, as anything on the floor; lower is further away: 0.5 moves half as much.
@export_range(0.0, 1.0, 0.05) var depth: float = 0.8
## Leftmost and rightmost x, in the world, its middle may slide to: the ends of the floor it stands on.
@export var min_x: float = -INF
@export var max_x: float = INF

var _home_x: float = 0.0


func _ready() -> void:
	_home_x = global_position.x
	ActivityTracker.join(self)


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	global_position.x = slide_x(camera.get_screen_center_position().x)


## Where its middle stands, in the world, with the camera's middle at camera_x.
func slide_x(camera_x: float) -> float:
	return clampf(_home_x + (camera_x - _home_x) * (1.0 - depth), min_x, max_x)


## For the ActivityTracker: where the drawing is, together with where it should be for the camera as it is now.
## Asleep, it stays where it was as it fell asleep, which the screen may meet before the other on its way back; with
## both, it wakes before either shows. With no camera, where it is.
func get_activity_rect() -> Rect2:
	var rect: Rect2 = get_global_transform() * get_rect()
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return rect
	var should_be: Rect2 = rect
	should_be.position.x += slide_x(camera.get_screen_center_position().x) - global_position.x
	return rect.merge(should_be)
