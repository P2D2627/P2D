# Prints what the screen shake (ADR 0061) costs on a drawn frame: CameraShake's _process(), which
# moves the trauma on and sets the camera's offset, called many times in a row on a camera of its
# own, first at rest (no trauma, so the offset stays put) and then at full trauma (the offset changes
# on every call). Calls made before the measured ones warm the processor's cache up. It checks
# nothing: the exit code is 1 only if the shake never moves the camera. The README quotes the result
# in the camera's section.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_camera_shake.gd
extends "res://tests/support/base_test.gd"

const SHAKE_STATS: CameraShakeStats = preload("res://scenes/others/camera/camera_shake_stats.tres")
## One drawn frame at 60 frames a second, in s.
const FRAME: float = 1.0 / 60.0
## Calls made before the measured ones, so the first calls' setup does not count.
const WARM_UP_CALLS: int = 1000
## Calls in a row in each measure; the result is their average.
const CALLS: int = 100000
## A drawn frame's whole time at 60 frames a second, in µs.
const FRAME_TIME: float = 1000000.0 / 60.0


func _initialize() -> void:
	var camera: Camera2D = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var shake: CameraShake = CameraShake.new()
	shake.stats = SHAKE_STATS
	shake.camera = camera
	camera.add_child(shake)
	root.add_child(camera)
	await process_frame
	var at_rest: float = _cost(shake, 0.0)
	var shaking: float = _cost(shake, 1.0)
	var moved: bool = camera.offset != Vector2.ZERO
	print("CameraShake._process(): %.2f µs a frame at rest, %.2f µs at full trauma (%.3f %% of a frame at 60 FPS)"
			% [at_rest, shaking, shaking / FRAME_TIME * 100.0])
	camera.queue_free()
	await process_frame
	quit(0 if moved else 1)


## The average cost, in µs, of one call of shake's _process() with trauma added before it.
func _cost(shake: CameraShake, trauma: float) -> float:
	for index: int in WARM_UP_CALLS:
		shake.add_trauma(trauma)
		shake._process(FRAME)
	var start: int = Time.get_ticks_usec()
	for index: int in CALLS:
		shake.add_trauma(trauma)
		shake._process(FRAME)
	return float(Time.get_ticks_usec() - start) / CALLS
