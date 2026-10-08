# Test of the game camera's window and smoothing. The test room's camera has its Stats, and the
# Camera2D's own Position Smoothing is off. The window holds a full jump and the sway of a 120 px
# chimney. While the player stays inside the window, the camera stays; past an edge, the focus
# follows just enough for the player to be on that edge. The camera closes in on the focus leaving
# exp(-sharpness × t) of the distance, and two half steps land where one whole step does. A full
# jump from the floor does not move the camera, and at full run the camera trails by the window and
# by what the smoothing leaves.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_window.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://scenes/levels/test_room.tscn")
const CAMERA_SCENE: PackedScene = preload("res://scenes/camera/game_camera.tscn")
## The width of the test room's chimneys, wall face to wall face, in px.
const CHIMNEY_WIDTH: float = 120.0
## A smoothing so fast that one step closes the whole distance, to see where the focus is.
const INSTANT_SHARPNESS: float = 1.0e6
## How close two positions must be to count as the same, in px: the float error of a few steps.
const SAME_SPOT: float = 0.01
## Where the cases that call the camera by hand put the player.
const START: Vector2 = Vector2(1000.0, 500.0)
## How far past an edge of the window those cases move the player, in px.
const PAST_THE_EDGE: Vector2 = Vector2(50.0, 30.0)
## Where the smoothing case puts the camera, away from its focus, in px.
const CAMERA_OFFSET: Vector2 = Vector2(300.0, -200.0)
## Steps the smoothing case lets the camera close in: half a second.
const SMOOTHING_STEPS: int = 30
## How far the share of the distance left may be from exp(-sharpness × t).
const SHARE_TOLERANCE: float = 0.001
## The floor of the cases with physics goes from -FLOOR_HALF_WIDTH to FLOOR_HALF_WIDTH.
const FLOOR_HALF_WIDTH: float = 3000.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## Physics frames for the camera to settle after the player lands: 1.5 s, which at Follow Sharpness
## 6 leaves exp(-9) of the distance.
const SETTLE_FRAMES: int = 90
## Physics frames for a full jump to rise and land again: about 21 up and 15 down.
const FULL_JUMP_FRAMES: int = 60
## How short of Jump Height a full jump may peak and still count as one, in px.
const JUMP_PEAK_TOLERANCE: float = 1.0
## Physics frames of the run: 2 s, long enough for the trail to stop growing.
const RUN_FRAMES: int = 120
## How far the trail at full run may be from the expected one, in px.
const TRAIL_TOLERANCE: float = 0.5


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_room_camera_has_its_stats_and_the_godot_smoothing_off())
	results.append(_the_window_holds_a_full_jump_and_a_chimney())
	results.append(await _inside_the_window_the_camera_stays())
	results.append(await _past_an_edge_the_focus_follows_to_the_edge())
	results.append(await _the_smoothing_leaves_exp_of_the_distance_whatever_the_step())
	results.append(await _a_full_jump_from_the_floor_does_not_move_the_camera())
	results.append(await _at_full_run_the_camera_trails_by_the_window_and_the_smoothing())
	finish(results)


## The test room's camera has the Stats file, and the Camera2D's own Position Smoothing is off: with
## physics interpolation on, it runs more than once per step.
func _the_room_camera_has_its_stats_and_the_godot_smoothing_off() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	var camera: GameCamera = room.get_node(^"GameCamera") as GameCamera
	var has_stats: bool = camera.stats != null
	var godot_smoothing: bool = camera.position_smoothing_enabled
	await _remove(room)
	return report(has_stats and not godot_smoothing,
			"Room camera: Stats %s, Godot Position Smoothing %s" % [has_stats, godot_smoothing])


## The window is at least as tall above the focus as a full jump, and at least as wide as the
## distance the player crosses in a 120 px chimney.
func _the_window_holds_a_full_jump_and_a_chimney() -> bool:
	var stats: CameraStats = load("res://resources/camera_stats.tres") as CameraStats
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var jump_height: float = player.stats.jump_height
	var chimney_sway: float = CHIMNEY_WIDTH - body_size(player).x
	player.queue_free()
	var holds_the_jump: bool = stats.window_up >= jump_height
	var holds_the_chimney: bool = 2.0 * stats.window_half_width >= chimney_sway
	return report(holds_the_jump and holds_the_chimney,
			"Window: %.0f px up for a %.0f px jump, %.0f px wide for a %.0f px chimney sway"
			% [stats.window_up, jump_height, 2.0 * stats.window_half_width, chimney_sway])


## While the player stays inside the window, up to each edge, the camera stays where it is.
func _inside_the_window_the_camera_stays() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	var stats: CameraStats = camera.stats
	var moves: Array[Vector2] = [
		Vector2(stats.window_half_width, 0.0),
		Vector2(-stats.window_half_width, 0.0),
		Vector2(0.0, -stats.window_up),
		Vector2(0.0, stats.window_down),
	]
	var largest_shift: float = 0.0
	for move: Vector2 in moves:
		player.global_position = START + move
		camera._physics_process(_step())
		largest_shift = maxf(largest_shift, camera.global_position.distance_to(START))
	await _remove(camera)
	await _remove(player)
	return report(largest_shift < SAME_SPOT,
			"Player on each edge of the window: largest camera shift %.3f px" % largest_shift)


## Past an edge of the window, the focus follows just enough for the player to be on that edge:
## to the right, then up, then down.
func _past_an_edge_the_focus_follows_to_the_edge() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	var stats: CameraStats = camera.stats
	var right: float = stats.window_half_width + PAST_THE_EDGE.x
	var cases: Array[Array] = [
		[Vector2(right, 0.0), START + Vector2(PAST_THE_EDGE.x, 0.0)],
		[Vector2(right, -stats.window_up - PAST_THE_EDGE.y),
				START + Vector2(PAST_THE_EDGE.x, -PAST_THE_EDGE.y)],
		[Vector2(right, stats.window_down + PAST_THE_EDGE.y),
				START + Vector2(PAST_THE_EDGE.x, PAST_THE_EDGE.y)],
	]
	var passed: bool = true
	var seen: PackedStringArray = []
	for case: Array in cases:
		player.global_position = START + (case[0] as Vector2)
		camera._physics_process(_step())
		var expected: Vector2 = case[1] as Vector2
		passed = passed and camera.global_position.distance_to(expected) < SAME_SPOT
		seen.append("%s (expected %s)" % [camera.global_position, expected])
	await _remove(camera)
	await _remove(player)
	return report(passed, "Player past the right, top and bottom edges: camera at %s"
			% ", ".join(seen))


## From a distance away, the camera closes in on its focus leaving exp(-sharpness × t) of the
## distance after t seconds. Two half steps land where one whole step does, so the camera does not
## depend on the frame rate, and one step does not jump all the way.
func _the_smoothing_leaves_exp_of_the_distance_whatever_the_step() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	var sharpness: float = camera.stats.follow_sharpness
	camera.global_position = START + CAMERA_OFFSET
	for _step_index: int in SMOOTHING_STEPS:
		camera._physics_process(_step())
	var share_left: float = camera.global_position.distance_to(START) / CAMERA_OFFSET.length()
	var expected_share: float = exp(-sharpness * SMOOTHING_STEPS * _step())
	camera.global_position = START + CAMERA_OFFSET
	camera._physics_process(2.0 * _step())
	var after_one_whole_step: Vector2 = camera.global_position
	camera.global_position = START + CAMERA_OFFSET
	camera._physics_process(_step())
	camera._physics_process(_step())
	var after_two_half_steps: Vector2 = camera.global_position
	await _remove(camera)
	await _remove(player)
	var share_right: bool = absf(share_left - expected_share) < SHARE_TOLERANCE
	var same_landing: bool = after_one_whole_step.distance_to(after_two_half_steps) < SAME_SPOT
	var not_there_yet: bool = after_one_whole_step.distance_to(START) > SAME_SPOT
	return report(share_right and same_landing and not_there_yet,
			"Smoothing: %.4f of the distance left after %.2f s (expected %.4f); one step %s, two half steps %s"
			% [share_left, SMOOTHING_STEPS * _step(), expected_share, after_one_whole_step,
					after_two_half_steps])


## A full jump from the floor, with the camera settled, does not move the camera: the jump stays
## inside the window.
func _a_full_jump_from_the_floor_does_not_move_the_camera() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(ground)
		return report(false, "Full jump: the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	await _wait_physics_frames(SETTLE_FRAMES)
	var settled: Vector2 = camera.global_position
	var floor_y: float = player.global_position.y
	var peak_y: float = floor_y
	var largest_shift: float = 0.0
	Input.action_press(&"jump")
	for _frame: int in FULL_JUMP_FRAMES:
		await physics_frame
		peak_y = minf(peak_y, player.global_position.y)
		largest_shift = maxf(largest_shift, camera.global_position.distance_to(settled))
	Input.action_release(&"jump")
	var rise: float = floor_y - peak_y
	var full: bool = rise >= player.stats.jump_height - JUMP_PEAK_TOLERANCE
	await _remove(camera)
	await _remove(player)
	await _remove(ground)
	return report(full and largest_shift < SAME_SPOT,
			"Full jump: rose %.1f px, largest camera shift %.3f px" % [rise, largest_shift])


## At full run, once the trail stops growing, the camera without its look ahead is behind the player
## by the window's half width plus what the smoothing leaves of each step's run:
## speed × step × (1 - w) / w, with w = 1 - exp(-sharpness × step).
func _at_full_run_the_camera_trails_by_the_window_and_the_smoothing() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(ground)
		return report(false, "Full run: the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	await _wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(&"move_right")
	await _wait_physics_frames(RUN_FRAMES)
	var trail: float = player.global_position.x - (camera.global_position.x - camera.get_look_ahead())
	var speed: float = player.velocity.x
	Input.action_release(&"move_right")
	var stats: CameraStats = camera.stats
	var weight: float = 1.0 - exp(-stats.follow_sharpness * _step())
	var expected: float = (stats.window_half_width
			+ player.stats.max_run_speed * _step() * (1.0 - weight) / weight)
	var at_full_speed: bool = is_equal_approx(speed, player.stats.max_run_speed)
	await _remove(camera)
	await _remove(player)
	await _remove(ground)
	return report(at_full_speed and absf(trail - expected) < TRAIL_TOLERANCE,
			"Full run at %.0f px/s: camera %.1f px behind (expected %.1f)" % [speed, trail, expected])


## A player that does not move on its own: its physics step is off, so only the case moves it.
func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


## A camera following player with its own copy of Stats, physics step off so that the case calls
## it by hand. An instant camera closes the whole distance in one step, so it sits on its focus.
func _spawn_camera_by_hand(player: Player, instant: bool) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	if instant:
		camera.stats.follow_sharpness = INSTANT_SHARPNESS
	root.add_child(camera)
	camera.set_physics_process(false)
	return camera


func _spawn_camera(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	root.add_child(camera)
	return camera


## The length of one physics step, in seconds.
func _step() -> float:
	return 1.0 / Engine.physics_ticks_per_second


func _wait_physics_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame
