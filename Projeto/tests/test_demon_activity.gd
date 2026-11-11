# Checks the demon as a member of the ActivityTracker, on a long floor with a camera that only moves when the test
# moves it, the man always on the screen. A dog with Chases Only On Screen off, after the man as the screen jumps
# far from it, goes on after him, awake, past Sleep Margin and its Sight Distance: off the screen, what is busy goes
# on. A dog of lust_demon_stats.tres standing at its post far off the screen sleeps; walking the screen to it at the
# man's run, it is awake on every frame it is on the screen, and then comes after the man; once the screen jumps
# far away, it goes back to its post awake, and sleeps only once it stands there.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_activity.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
const FLOOR_HALF_WIDTH: float = 30000.0
## A little above the floor, so the bodies land on their own.
const ABOVE_FLOOR: Vector2 = Vector2(0.0, -2.0)
## Where the chasing dog starts from the man, in px: inside its Sight Distance, past its attacks' reach.
const CHASER_START: float = 900.0
## Where the screen jumps to, in px from where it was: far past Sleep Margin and any Sight Distance.
const JUMP: float = 8000.0
## Where the dog at its post stands, in px from the man's start.
const POST: float = 6000.0
## The man's run, in px a physics frame: 720 px/s.
const RUN_STEP: float = 12.0
## Physics frames to land, to notice the man, and to walk back to the post.
const SETTLE_FRAMES: int = 60
const NOTICE_FRAMES: int = 180
const RETURN_FRAMES: int = 1200
const AT_REST: Array[Demon.State] = [Demon.State.IDLE, Demon.State.PATROL]

var _camera: Camera2D
var _tracker: ActivityTracker
var _player: Player


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	_camera = Camera2D.new()
	root.add_child(_camera)
	_camera.make_current()
	_tracker = ActivityTracker.new()
	root.add_child(_tracker)
	_player = await spawn_on_floor(ABOVE_FLOOR)
	var results: Array[bool] = []
	if _player == null:
		results.append(report(false, "the man lands"))
		finish(results)
		return
	put_a_stand_in(_player)

	# A dog that may chase off the screen, after the man as the screen jumps away from it.
	var chaser: Demon = DEMON_SCENE.instantiate() as Demon
	chaser.stats = chaser.stats.duplicate() as DemonStats
	chaser.stats.chases_only_on_screen = false
	chaser.stats.lose_distance = 2.0 * JUMP
	chaser.stats.give_up_time = 10.0
	chaser.faces_left = true
	chaser.position = ABOVE_FLOOR + Vector2(CHASER_START, 0.0)
	root.add_child(chaser)
	results.append(report(await wait_until(func() -> bool: return chaser.get_state() == Demon.State.CHASE,
			NOTICE_FRAMES), "the chasing dog comes after the man"))
	await _move_screen(-JUMP)
	var chaser_x: float = chaser.global_position.x
	await _steps(2 * _tracker.cycle_frames)
	var gap: float = chaser.global_position.x - (_camera.position.x + root.get_visible_rect().size.x / 2.0)
	results.append(report(not _tracker.is_asleep(chaser) and chaser.get_state() == Demon.State.CHASE
			and chaser.global_position.x < chaser_x
			and gap > _tracker.sleep_margin + chaser.stats.sight_distance,
			"off the screen, %.0f px past its side, the chasing dog goes on after the man: %s, moved %.0f px"
			% [gap, Demon.State.find_key(chaser.get_state()), chaser.global_position.x - chaser_x]))
	chaser.queue_free()
	await _move_screen(JUMP)

	# A dog at its post, far off the screen.
	var dog: Demon = DEMON_SCENE.instantiate() as Demon
	dog.faces_left = true
	dog.position = ABOVE_FLOOR + Vector2(POST, 0.0)
	root.add_child(dog)
	await _steps(SETTLE_FRAMES + _tracker.cycle_frames)
	results.append(report(_tracker.is_asleep(dog) and dog.process_mode == Node.PROCESS_MODE_DISABLED
			and dog.get_state() in AT_REST,
			"a dog at its post far off the screen sleeps: %s" % Demon.State.find_key(dog.get_state())))

	var seen_asleep: int = 0
	while not dog.is_on_screen() or dog.global_position.x - _player.global_position.x \
			> dog.stats.sight_distance / 2.0:
		await _move_screen(RUN_STEP)
		if dog.is_on_screen() and _tracker.is_asleep(dog):
			seen_asleep += 1
	results.append(report(seen_asleep == 0,
			"walking the screen to it, the dog is awake on every frame it is on the screen: asleep on %d"
			% seen_asleep))
	results.append(report(await wait_until(func() -> bool: return not dog.get_state() in AT_REST,
			NOTICE_FRAMES), "woken, the dog comes after the man: %s" % Demon.State.find_key(dog.get_state())))

	await _move_screen(-JUMP)
	await _steps(2 * _tracker.cycle_frames)
	results.append(report(not _tracker.is_asleep(dog) and not dog.get_state() in AT_REST,
			"far off the screen, the dog goes back to its post awake: %s"
			% Demon.State.find_key(dog.get_state())))
	var home: bool = await wait_until(func() -> bool: return dog.get_state() in AT_REST, RETURN_FRAMES)
	await _steps(2 * _tracker.cycle_frames)
	results.append(report(home and _tracker.is_asleep(dog),
			"back at its post, %.0f px from it, the dog sleeps: %s"
			% [absf(dog.global_position.x - dog.get_post().x), Demon.State.find_key(dog.get_state())]))
	finish(results)


## Moves the man, and the screen with him, by dx px, and lets a frame run whole.
func _move_screen(dx: float) -> void:
	_player.global_position.x += dx
	_camera.position.x = _player.global_position.x
	await _steps(1)


## Lets frames run whole: the physics, where the tracker checks, and then the process, where the camera moves the
## screen.
func _steps(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame
		await process_frame
