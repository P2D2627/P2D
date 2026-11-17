class_name MotionBlur
extends CanvasLayer

## A slight streak over the whole screen along the camera's move, for its fast moves, as a camera
## cutscene's pans: each pixel shows the mean of the screen along the streak. It sits over the level
## and under the pause menu, the dialogue and the HUD (keep Layer between the level's 0 and theirs).
## Its GameCamera sets the streak; with none, it hides and costs nothing.

## Below this length, in px of the screen, there is no streak.
const MIN_STREAK: float = 0.5
const SHADER: Shader = preload("res://scenes/others/camera/motion_blur.gdshader")

## How many points along the streak are averaged: more is smoother and costs more.
@export_range(2, 32, 1) var samples: int = 12

var _streak: Vector2 = Vector2.ZERO
var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"samples", samples)
	_rect = ColorRect.new()
	_rect.name = &"Streak"
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.hide()
	add_child(_rect)


## Streaks the screen along streak, in px of the screen; its way does not matter, only its line.
## Shorter than MIN_STREAK, it hides.
func set_streak(streak: Vector2) -> void:
	_streak = streak if streak.length() >= MIN_STREAK else Vector2.ZERO
	if _rect == null:
		return
	_rect.visible = _streak != Vector2.ZERO
	if _rect.visible:
		_material.set_shader_parameter(&"streak", _streak / _rect.get_viewport_rect().size)


## The streak on the screen now, in px. For the tests.
func get_streak() -> Vector2:
	return _streak
