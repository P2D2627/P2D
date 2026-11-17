# Checks the ParallaxSprite as a member of the ActivityTracker: the screen runs right, at the man's run, far past a
# far drawing, and back. The drawing falls asleep on the way, and it is never on the screen while asleep: not where
# it should be for the camera, nor where it stopped as it fell asleep. Its Depth, 0.3, is lower than any in level 1
# (0.55 the lowest), so that on the way back the screen meets the spot where it stopped before the one where it
# should be: a drawing woken only by the second would show still, in the wrong place. Back where it started, it
# stands where a drawing that never slept would, for that camera.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_parallax_activity.gd
extends "res://tests/support/player_test.gd"

const DEPTH: float = 0.3
## The drawing's size, in px.
const SIZE: int = 400
## How far the screen runs, in px, and by how much on each frame: 720 px/s.
const RUN: float = 10000.0
const RUN_STEP: float = 12.0
## How near, in px, the drawing has to stand to where it should.
const TOLERANCE: float = 0.01

var _camera: Camera2D
var _tracker: ActivityTracker


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	_camera = Camera2D.new()
	root.add_child(_camera)
	_camera.make_current()
	_tracker = ActivityTracker.new()
	root.add_child(_tracker)
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var drawing: ParallaxSprite = ParallaxSprite.new()
	drawing.texture = ImageTexture.create_from_image(image)
	drawing.depth = DEPTH
	root.add_child(drawing)
	await _steps(1)

	var results: Array[bool] = []
	var slept: bool = false
	var seen_asleep: int = 0
	var x: float = 0.0
	var direction: float = 1.0
	while direction > 0.0 or x > 0.0:
		x += direction * RUN_STEP
		if x >= RUN:
			direction = -1.0
		_camera.position.x = maxf(x, 0.0)
		await _steps(1)
		slept = slept or _tracker.is_asleep(drawing)
		if _tracker.is_asleep(drawing) and _screen().intersects(drawing.get_global_transform() * drawing.get_rect()):
			seen_asleep += 1
	results.append(report(slept, "far from the screen, the drawing sleeps"))
	results.append(report(seen_asleep == 0,
			"asleep, it is never on the screen, out and back: on %d frames" % seen_asleep))
	await _steps(_tracker.cycle_frames)
	var expected: float = _camera.get_screen_center_position().x * (1.0 - DEPTH)
	results.append(report(not _tracker.is_asleep(drawing)
			and absf(drawing.global_position.x - expected) < TOLERANCE,
			"back, it stands where it should for the camera: x %.2f, expected %.2f"
			% [drawing.global_position.x, expected]))
	finish(results)


func _screen() -> Rect2:
	return root.get_canvas_transform().affine_inverse() * root.get_visible_rect()


## Lets frames run whole: the physics, where the tracker checks, and then the process, where the camera moves the
## screen and the drawing slides.
func _steps(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame
		await process_frame
