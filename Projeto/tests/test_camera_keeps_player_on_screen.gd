# Checks that the camera keeps the player's whole body on the screen. Next to an edge of the level the
# camera stops at the edge, and the lead must not push the screen past the player: by the left wall
# with the lead to the right, by the right wall with the lead to the left, and in a long fall just
# under the top of the level. In play, a run of random input through the test room never takes the
# body off the screen.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_keeps_player_on_screen.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://levels/test_room.tscn")
const CAMERA_SCENE: PackedScene = preload("res://camera/game_camera.tscn")
## The level the hand-driven cases use: wider and taller than the screen.
const LEVEL: Rect2 = Rect2(0.0, -2000.0, 6000.0, 3000.0)
## How far from an edge of the level the player stands in the hand-driven cases, in px.
const NEAR_THE_EDGE: float = 120.0
## How far past a threshold, or short of it, the player is moved, in px.
const PAST_THE_THRESHOLD: float = 10.0
## A follow sharpness high enough for the camera to sit on its focus at once.
const INSTANT_SHARPNESS: float = 1.0e6
## Physics steps for the lead to settle: many times the time its spring needs.
const SETTLE_STEPS: int = 600
## The random play: how many runs, how long each one is and how often the input changes, at most.
const RANDOM_RUNS: int = 16
const RANDOM_RUN_FRAMES: int = 1800
const LONGEST_HOLD_FRAMES: int = 40
## The seed of the random play, fixed so that every run of the test plays the same.
const RANDOM_SEED: int = 20261012
## Where every other random run starts: over the third step, near the room's right wall, so the play
## gets near both walls.
const RIGHT_SIDE_START: Vector2 = Vector2(5040.0, 300.0)
## How likely the random play is to hold Jump, and to press it, on each change of input.
const HOLD_JUMP_CHANCE: float = 0.6
const PRESS_JUMP_CHANCE: float = 0.5


func _initialize() -> void:
	# Without a window the root is 64 × 64 px, and the Expand aspect makes that a 1920 × 1920 screen.
	# A size set before the first frame is undone when the window starts, and a new size takes
	# effect on the next frame.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(await _by_the_left_wall_a_lead_to_the_right_keeps_the_player_on_screen())
	results.append(await _by_the_right_wall_a_lead_to_the_left_keeps_the_player_on_screen())
	results.append(await _a_long_fall_under_the_top_keeps_the_player_on_screen())
	results.append(await _random_play_never_takes_the_player_off_the_screen())
	finish(results)


## The player goes Turn Threshold to the right of a spot near the left wall, so the lead turns to the
## right, and comes back short of Turn Threshold, so it stays there. The screen stops at the wall,
## and the lead must not push it past the player.
func _by_the_left_wall_a_lead_to_the_right_keeps_the_player_on_screen() -> bool:
	var start: Vector2 = Vector2(LEVEL.position.x + NEAR_THE_EDGE, 0.0)
	var player: Player = _spawn_still_player(start)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var turn: float = camera.stats.turn_threshold
	player.global_position.x = start.x + turn + PAST_THE_THRESHOLD
	_settle_by_hand(camera)
	player.global_position.x = start.x + 2.0 * PAST_THE_THRESHOLD
	_settle_by_hand(camera)
	return await _report_on_screen(player, camera, "By the left wall, lead to the right")


## The same by the right wall, with the lead to the left.
func _by_the_right_wall_a_lead_to_the_left_keeps_the_player_on_screen() -> bool:
	var start: Vector2 = Vector2(LEVEL.end.x - NEAR_THE_EDGE, 0.0)
	var player: Player = _spawn_still_player(start)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var turn: float = camera.stats.turn_threshold
	player.global_position.x = start.x - turn - PAST_THE_THRESHOLD
	_settle_by_hand(camera)
	player.global_position.x = start.x - 2.0 * PAST_THE_THRESHOLD
	_settle_by_hand(camera)
	return await _report_on_screen(player, camera, "By the right wall, lead to the left")


## The player lands just under the top of the level and then falls Look Down Threshold below that
## floor, so the camera looks down. The screen stops at the top, and the look down must not push it
## below the player.
func _a_long_fall_under_the_top_keeps_the_player_on_screen() -> bool:
	var floor_spot: Vector2 = Vector2(LEVEL.get_center().x, LEVEL.position.y + NEAR_THE_EDGE)
	var player: Player = _spawn_still_player(floor_spot)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	player.landed.emit()
	player.global_position.y = floor_spot.y + camera.stats.look_down_threshold + PAST_THE_THRESHOLD
	player.velocity.y = player.stats.max_fall_speed
	_settle_by_hand(camera)
	return await _report_on_screen(player, camera, "Falling just under the top of the level")


## Random input through the test room, the same on every run of the test: the body never leaves the
## screen, on any frame. Half the runs start by the right wall, and the play must get the body within
## Look Ahead Distance of both walls, where a lead in the wrong place would hide it; otherwise the
## case proves nothing about the walls, and fails.
func _random_play_never_takes_the_player_off_the_screen() -> bool:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = RANDOM_SEED
	var frames_off: int = 0
	var worst: float = 0.0
	var closest_to_left: float = INF
	var closest_to_right: float = INF
	var near_a_wall: float = 0.0
	for run: int in RANDOM_RUNS:
		var room: Node = TEST_ROOM_SCENE.instantiate()
		var player: Player = room.get_node(^"Player") as Player
		var camera: GameCamera = room.get_node(^"GameCamera") as GameCamera
		if run % 2 == 1:
			player.position = RIGHT_SIDE_START
		root.add_child(room)
		near_a_wall = camera.stats.look_ahead_distance
		var random_input: RandomInput = RandomInput.new()
		player.add_child(random_input)
		player.input = random_input
		var hold_frames: int = 0
		for _frame: int in RANDOM_RUN_FRAMES:
			if hold_frames <= 0:
				random_input.run_direction = float(random.randi_range(-1, 1))
				random_input.hold_jump = random.randf() < HOLD_JUMP_CHANCE
				if random.randf() < PRESS_JUMP_CHANCE:
					random_input.press_jump()
				hold_frames = random.randi_range(1, LONGEST_HOLD_FRAMES)
			hold_frames -= 1
			await physics_frame
			var out: float = _how_far_off_screen(player, camera)
			if out > 0.0:
				frames_off += 1
				worst = maxf(worst, out)
			var body_x: float = player.global_position.x
			var half_width: float = body_size(player).x / 2.0
			closest_to_left = minf(closest_to_left, body_x - half_width - camera.limit_left)
			closest_to_right = minf(closest_to_right, camera.limit_right - body_x - half_width)
		room.queue_free()
		await physics_frame
	var reached_the_walls: bool = closest_to_left <= near_a_wall and closest_to_right <= near_a_wall
	return report(frames_off == 0 and reached_the_walls,
			("Random play, %d runs of %d frames: %d frames with the body off the screen, at worst %.0f px;"
			+ " closest to the left wall %.0f px and to the right one %.0f px (at most %.0f)")
			% [RANDOM_RUNS, RANDOM_RUN_FRAMES, frames_off, worst, closest_to_left, closest_to_right,
					near_a_wall])


## PASS if the player's whole body is on the screen.
func _report_on_screen(player: Player, camera: GameCamera, what: String) -> bool:
	var out: float = _how_far_off_screen(player, camera)
	var screen: Rect2 = _screen(camera)
	var passed: bool = out <= 0.0
	var note: String = "on the screen" if passed else "%.0f px off the screen" % out
	player.queue_free()
	camera.queue_free()
	await physics_frame
	return report(passed, "%s: body %s, screen from %s to %s"
			% [what, note, screen.position.round(), screen.end.round()])


## How far the player's body sticks out of the screen, in px; 0 when all of it is on the screen.
func _how_far_off_screen(player: Player, camera: GameCamera) -> float:
	var size: Vector2 = body_size(player)
	var body: Rect2 = Rect2(player.global_position - Vector2(size.x / 2.0, size.y), size)
	var screen: Rect2 = _screen(camera)
	return maxf(maxf(screen.position.x - body.position.x, body.end.x - screen.end.x),
			maxf(screen.position.y - body.position.y, body.end.y - screen.end.y))


## The screen as the engine shows it: around the camera, clamped by the camera's own limits.
func _screen(camera: GameCamera) -> Rect2:
	var half: Vector2 = camera.get_viewport_rect().size / (2.0 * camera.zoom)
	var centre: Vector2 = Vector2(
			clampf(camera.global_position.x, camera.limit_left + half.x, camera.limit_right - half.x),
			clampf(camera.global_position.y, camera.limit_top + half.y, camera.limit_bottom - half.y))
	return Rect2(centre - half, half * 2.0)


## A player that does not move on its own: its physics step is off, so only the case moves it.
func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


## A camera following player inside LEVEL, with its own copy of Stats and an instant follow. Its
## physics step is off, so the case calls it by hand.
func _spawn_camera_by_hand(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.follow_sharpness = INSTANT_SHARPNESS
	camera.limit_left = int(LEVEL.position.x)
	camera.limit_top = int(LEVEL.position.y)
	camera.limit_right = int(LEVEL.end.x)
	camera.limit_bottom = int(LEVEL.end.y)
	root.add_child(camera)
	camera.set_physics_process(false)
	return camera


func _settle_by_hand(camera: GameCamera) -> void:
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(1.0 / Engine.physics_ticks_per_second)


## A PlayerInput the random play drives: it never reads the keyboard, only what the case sets.
class RandomInput extends PlayerInput:
	## What _press_frame holds before the first press.
	const NO_PRESS: int = -1

	var run_direction: float = 0.0
	var hold_jump: bool = false
	## The physics frame of the last press of Jump.
	var _press_frame: int = NO_PRESS

	## Jump counts as just pressed for the whole of the current physics frame, as on the keyboard.
	func press_jump() -> void:
		_press_frame = Engine.get_physics_frames()

	func get_run_direction() -> float:
		return run_direction

	func is_jump_just_pressed() -> bool:
		return Engine.get_physics_frames() == _press_frame

	func is_jump_held() -> bool:
		return hold_jump
