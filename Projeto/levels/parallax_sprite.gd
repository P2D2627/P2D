class_name ParallaxSprite
extends Sprite2D
## A drawing in the distance that slides sideways slower than the world as the camera passes, for depth. It sits
## where it was placed in the editor when the camera's middle is right over it, so it is placed by eye; away from
## it, it trails the camera by 1 - Depth of the camera's move. It only slides sideways, so it stays on its floor,
## and only between Min X and Max X, so it never slides into another room.

## 1 moves with the world, as anything on the floor; lower is further away: 0.5 moves half as much.
@export_range(0.0, 1.0, 0.05) var depth: float = 0.8
## Leftmost and rightmost x, in the world, its middle may slide to: the ends of the floor it stands on.
@export var min_x: float = -INF
@export var max_x: float = INF

var _home_x: float = 0.0


func _ready() -> void:
	_home_x = global_position.x


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var camera_x: float = camera.get_screen_center_position().x
	global_position.x = clampf(_home_x + (camera_x - _home_x) * (1.0 - depth), min_x, max_x)
