class_name CameraShake
extends Node

## Shakes Camera for a moment after an impact, through the camera's offset, so where the camera goes
## (its following, zones and limits) never sees the shake. Impacts add trauma with add_trauma(); the
## rules are in ShakeTrauma and the look in Stats. The Screen shake option of the autoload Settings
## scales the shake, and 0 turns it off. It runs each drawn frame, since it only changes what is
## drawn, and a pause puts the screen back in place until the game goes on.

## Where the autoload Settings is in the tree. Looked up there instead of named in the code, as the
## options screen does, so this script compiles before the autoloads exist.
const SETTINGS_PATH: NodePath = ^"/root/Settings"

## How the shake looks.
@export var stats: CameraShakeStats
## The camera to shake.
@export var camera: Camera2D

var _trauma: ShakeTrauma
var _settings: GameSettings


func _ready() -> void:
	assert(stats != null, "CameraShake: assign a CameraShakeStats resource to Stats.")
	assert(camera != null, "CameraShake: assign the camera to shake to Camera.")
	_trauma = ShakeTrauma.new(stats)
	_settings = get_node_or_null(SETTINGS_PATH) as GameSettings
	if _settings == null:
		push_warning("CameraShake: no Settings at %s, so the shake ignores the Screen shake option."
				% SETTINGS_PATH)


func _process(delta: float) -> void:
	_trauma.advance(delta)
	_show_offset()


## The camera stops in a pause, and with physics interpolation it keeps drawing what it worked out on
## its last physics frame, offset and all: so the offset goes back to 0 and the camera redraws now.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_instance_valid(camera):
		camera.offset = Vector2.ZERO
		camera.reset_physics_interpolation()
		camera.force_update_scroll()


## Adds the trauma of an impact, from 0 (nothing) to 1 (the strongest shake).
func add_trauma(amount: float) -> void:
	_trauma.add(amount)


## Raises the trauma to level, for a moment that repeats fast: it never piles up past level.
func raise_trauma(level: float) -> void:
	_trauma.raise_to(level)


func get_trauma() -> float:
	return _trauma.get_trauma()


## Divided by the zoom, so the shake moves the screen by the same px at any zoom.
func _show_offset() -> void:
	var strength: float = _settings.get_screen_shake() if _settings != null else 1.0
	var offset: Vector2 = _trauma.get_offset(strength) / camera.zoom
	if offset != camera.offset:
		camera.offset = offset
