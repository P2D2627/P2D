# Test of the game camera's vertical moves. The values meet their criteria: neither a jump nor a
# drop shorter than a full jump looks down, and at top falling speed the screen shows at least
# 0.5 s of fall below the player's feet. Landing higher than the focus, inside the window, reframes
# the camera on the new floor. In a long fall the camera looks down only once the player is Look
# Down Threshold below the last floor, shows half a second below the feet, and after the landing
# comes back up and settles on the floor. A short drop and a full jump do not look down, and
# neither does the fall of a player that appears in the air, before its first landing, nor a
# player below the threshold going up. The swing down is a critically damped spring at Look Down
# Sharpness.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_vertical.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/camera/game_camera.tscn")
## The least fall, in seconds, the screen must show below the player's feet at top falling speed.
const SECONDS_BELOW: float = 0.5
## A smoothing so fast that one step closes the whole distance, to see the camera's moves on their own.
const INSTANT_SHARPNESS: float = 1.0e6
## Where the cases that call the camera by hand put the player.
const START: Vector2 = Vector2(1000.0, 500.0)
## How far above the focus the reframing case lands, in px: inside the window.
const LANDING_RISE: float = 200.0
## How far past the look-down threshold the spring case puts the player, in px.
const PAST_THE_THRESHOLD: float = 10.0
## How close two positions must be to count as the same, in px.
const SAME_SPOT: float = 0.01
## The floor's top is at y = 0, from -FLOOR_HALF_WIDTH to 3 × FLOOR_HALF_WIDTH.
const FLOOR_HALF_WIDTH: float = 1000.0
## The long fall: a ledge this high above the floor, ending at x = 0, with the player starting on it.
const HIGH_LEDGE: float = 1600.0
## The short drop: a ledge this high, shorter than a full jump.
const SHORT_DROP: float = 200.0
## Where the ledge cases start, on the ledge.
const LEDGE_START_X: float = -300.0
## Where the air case puts the player, above the floor.
const AIR_START_HEIGHT: float = 1000.0
## Physics frames a fall or a drop may take before the case gives up.
const FALL_FRAMES: int = 240
## Physics frames for the camera to settle after a landing: 1.5 s.
const SETTLE_FRAMES: int = 90
## How close to settled the camera must be after them, in px.
const SETTLE_TOLERANCE: float = 0.5
## Physics frames of the full jump in the short-drop case: about 21 up and 15 down.
const FULL_JUMP_FRAMES: int = 60
## The spring case: a swing settles in this many seconds times 1 / Look Down Sharpness.
const SETTLE_TIMES: float = 20.0
## What a critically damped spring has left to go, as a share of the swing, when it is 95 % done,
## and that time times the sharpness: (1 + x) × exp(-x) = 0.05 at x = 4.744.
const SHARE_LEFT_WHEN_DONE: float = 0.05
const DONE_TIME_TIMES_SHARPNESS: float = 4.744
## How much the first step of the swing may move, as a share of it. A spring at sharpness 10 moves
## about 1.2 %; a first-order smoothing at the same sharpness would move about 15 %.
const FIRST_STEP_SHARE: float = 0.02
## How far the swing's top speed may be from a spring's, swing × sharpness / e, as a share of it.
const PEAK_SPEED_TOLERANCE: float = 0.02


func _initialize() -> void:
	# Nodes added before the first frame only get _ready on it, and the cases need the camera ready
	# as soon as it is added.
	await process_frame
	var results: Array[bool] = []
	results.append(_the_values_meet_their_criteria())
	results.append(await _landing_higher_reframes_on_the_new_floor())
	results.append(await _a_long_fall_looks_down_enough_and_comes_back_up())
	results.append(await _a_short_drop_and_a_full_jump_do_not_look_down())
	results.append(await _a_player_that_appears_in_the_air_does_not_look_down())
	results.append(await _the_swing_down_is_a_spring_at_look_down_sharpness())
	results.append(await _going_up_below_the_threshold_does_not_look_down())
	finish(results)


## The look-down threshold is at least a full jump, and at top falling speed the screen shows at
## least 0.5 s of fall below the feet: half the screen, plus the look down, minus what the smoothing
## leaves behind.
func _the_values_meet_their_criteria() -> bool:
	var stats: CameraStats = load("res://resources/camera_stats.tres") as CameraStats
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var jump_height: float = player.stats.jump_height
	var fall_speed: float = player.stats.max_fall_speed
	player.queue_free()
	var weight: float = 1.0 - exp(-stats.follow_sharpness * _step())
	var trail: float = fall_speed * _step() * (1.0 - weight) / weight
	var below: float = _half_screen_height() + stats.look_down_distance - trail
	var jump_stays_up: bool = stats.look_down_threshold >= jump_height
	var sees_enough: bool = below >= SECONDS_BELOW * fall_speed
	return report(jump_stays_up and sees_enough,
			"Look-down threshold %.0f px for a %.0f px jump; at %.0f px/s, %.0f px below the feet, %.2f s (at least %.1f)"
			% [stats.look_down_threshold, jump_height, fall_speed, below, below / fall_speed,
					SECONDS_BELOW])


## Landing 200 px above the focus, inside the window, does not move the camera until the landing;
## then the camera reframes on the new floor.
func _landing_higher_reframes_on_the_new_floor() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	player.global_position = START + Vector2(0.0, -LANDING_RISE)
	camera._physics_process(_step())
	var before_landing: float = camera.global_position.y
	player.landed.emit()
	camera._physics_process(_step())
	var after_landing: float = camera.global_position.y
	await _remove(camera)
	await _remove(player)
	return report(absf(before_landing - START.y) < SAME_SPOT
			and absf(after_landing - (START.y - LANDING_RISE)) < SAME_SPOT,
			"Up %.0f px: camera y %.2f before the landing (expected %.2f), %.2f after (expected %.2f)"
			% [LANDING_RISE, before_landing, START.y, after_landing, START.y - LANDING_RISE])


## Off a 1600 px ledge, the camera does not look down until the player is Look Down Threshold below
## the ledge, then shows at least 0.5 s of fall below the feet at top falling speed; after the
## landing it comes back up and settles on the floor.
func _a_long_fall_looks_down_enough_and_comes_back_up() -> bool:
	var ledge: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 0.0, -HIGH_LEDGE)
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 3.0 * FLOOR_HALF_WIDTH)
	var player: Player = await _spawn_standing(Vector2(LEDGE_START_X, -HIGH_LEDGE - 2.0))
	if player == null:
		await _remove_all([ledge, ground])
		return report(false, "Long fall: the player never landed on the ledge")
	var camera: GameCamera = _spawn_camera(player)
	var ledge_y: float = player.global_position.y
	var threshold: float = camera.stats.look_down_threshold
	var early_look_down: float = 0.0
	var most_below: float = 0.0
	var landed: bool = false
	Input.action_press(&"move_right")
	for _frame: int in FALL_FRAMES:
		await physics_frame
		if player.get_state() == Player.State.ON_FLOOR and absf(player.global_position.y) < 1.0:
			landed = true
			break
		if player.global_position.y < ledge_y + threshold:
			early_look_down = maxf(early_look_down, absf(camera.get_look_down()))
		if player.velocity.y >= player.stats.max_fall_speed:
			most_below = maxf(most_below,
					camera.global_position.y + _half_screen_height() - player.global_position.y)
	Input.action_release(&"move_right")
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
	var look_down_after: float = absf(camera.get_look_down())
	var off_the_floor_after: float = absf(camera.global_position.y - player.global_position.y)
	var fall_speed: float = player.stats.max_fall_speed
	await _remove_all([camera, player, ledge, ground])
	return report(landed and early_look_down == 0.0 and most_below >= SECONDS_BELOW * fall_speed
			and look_down_after < SETTLE_TOLERANCE and off_the_floor_after < SETTLE_TOLERANCE,
			"Fall of %.0f px: landed %s, look down before the threshold %.2f px, %.0f px below the feet at top speed (%.2f s); after settling, look down %.2f px, camera %.2f px off the floor"
			% [HIGH_LEDGE, landed, early_look_down, most_below, most_below / fall_speed,
					look_down_after, off_the_floor_after])


## A drop shorter than a full jump, and then a full jump on the lower floor, never look down.
func _a_short_drop_and_a_full_jump_do_not_look_down() -> bool:
	var ledge: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 0.0, -SHORT_DROP)
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 3.0 * FLOOR_HALF_WIDTH)
	var player: Player = await _spawn_standing(Vector2(LEDGE_START_X, -SHORT_DROP - 2.0))
	if player == null:
		await _remove_all([ledge, ground])
		return report(false, "Short drop: the player never landed on the ledge")
	var camera: GameCamera = _spawn_camera(player)
	var largest_look_down: float = 0.0
	var reached_the_floor: bool = false
	Input.action_press(&"move_right")
	for _frame: int in FALL_FRAMES:
		await physics_frame
		largest_look_down = maxf(largest_look_down, absf(camera.get_look_down()))
		if player.get_state() == Player.State.ON_FLOOR and absf(player.global_position.y) < 1.0:
			reached_the_floor = true
			break
	Input.action_release(&"move_right")
	Input.action_press(&"jump")
	for _frame: int in FULL_JUMP_FRAMES:
		await physics_frame
		largest_look_down = maxf(largest_look_down, absf(camera.get_look_down()))
	Input.action_release(&"jump")
	await _remove_all([camera, player, ledge, ground])
	return report(reached_the_floor and largest_look_down == 0.0,
			"Drop of %.0f px then a full jump: reached the floor %s, largest look down %.2f px"
			% [SHORT_DROP, reached_the_floor, largest_look_down])


## A player that appears in the air, with the camera added at the same time, falls to the floor
## without the camera looking down: there is no floor it fell from yet.
func _a_player_that_appears_in_the_air_does_not_look_down() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = spawn_player(Vector2(0.0, -AIR_START_HEIGHT))
	var camera: GameCamera = _spawn_camera(player)
	var largest_look_down: float = 0.0
	var landed: bool = false
	for _frame: int in FALL_FRAMES:
		await physics_frame
		largest_look_down = maxf(largest_look_down, absf(camera.get_look_down()))
		if player.get_state() == Player.State.ON_FLOOR:
			landed = true
			break
	await _remove_all([camera, player, ground])
	return report(landed and largest_look_down == 0.0,
			"Appeared %.0f px above the floor: landed %s, largest look down %.2f px"
			% [AIR_START_HEIGHT, landed, largest_look_down])


## Once the player falls past the threshold, the look down swings like a critically damped spring at
## Look Down Sharpness: the first step moves little, the top speed is swing × sharpness / e, it never
## goes past Look Down Distance and it is 95 % done at 4.744 / sharpness s.
func _the_swing_down_is_a_spring_at_look_down_sharpness() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = camera.stats
	player.landed.emit()
	player.global_position = START + Vector2(0.0, stats.look_down_threshold + PAST_THE_THRESHOLD)
	player.velocity = Vector2(0.0, player.stats.max_fall_speed)
	var swing: float = stats.look_down_distance
	var previous: float = camera.get_look_down()
	var first_move: float = -1.0
	var top_speed: float = 0.0
	var highest: float = previous
	var done_time: float = -1.0
	var steps: int = ceili(SETTLE_TIMES / stats.look_down_sharpness / _step())
	for step_index: int in steps:
		camera._physics_process(_step())
		var look_down: float = camera.get_look_down()
		var move: float = absf(look_down - previous)
		if first_move < 0.0:
			first_move = move
		top_speed = maxf(top_speed, move / _step())
		highest = maxf(highest, look_down)
		if done_time < 0.0 and swing - look_down <= SHARE_LEFT_WHEN_DONE * swing:
			done_time = (step_index + 1) * _step()
		previous = look_down
	await _remove_all([camera, player])
	var spring_top_speed: float = swing * stats.look_down_sharpness / exp(1.0)
	var spring_done_time: float = DONE_TIME_TIMES_SHARPNESS / stats.look_down_sharpness
	var starts_slowly: bool = first_move <= FIRST_STEP_SHARE * swing
	var spring_speed: bool = absf(top_speed - spring_top_speed) <= PEAK_SPEED_TOLERANCE * spring_top_speed
	var never_past: bool = highest <= swing + SAME_SPOT
	var done_on_time: bool = done_time > 0.0 and absf(done_time - spring_done_time) <= _step()
	return report(starts_slowly and spring_speed and never_past and done_on_time,
			"Swing down of %.0f px: first step %.2f px, top speed %.0f px/s (spring %.0f), highest %.3f px, 95 %% done at %.3f s (spring %.3f)"
			% [swing, first_move, top_speed, spring_top_speed, highest, done_time, spring_done_time])


## Below the threshold but going up, as when climbing back up a wall after a fall, the camera does
## not look down: only a fall does.
func _going_up_below_the_threshold_does_not_look_down() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = camera.stats
	player.landed.emit()
	player.global_position = START + Vector2(0.0, stats.look_down_threshold + PAST_THE_THRESHOLD)
	player.velocity = Vector2(0.0, -player.stats.max_fall_speed)
	var largest_look_down: float = 0.0
	for _step_index: int in ceili(SETTLE_TIMES / stats.look_down_sharpness / _step()):
		camera._physics_process(_step())
		largest_look_down = maxf(largest_look_down, absf(camera.get_look_down()))
	await _remove_all([camera, player])
	return report(largest_look_down == 0.0,
			"%.0f px below the floor, going up: largest look down %.2f px"
			% [stats.look_down_threshold + PAST_THE_THRESHOLD, largest_look_down])


## A player that does not move on its own: its physics step is off, so only the case moves it.
func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


## spawn_on_floor, then waits for the state to turn ON_FLOOR too, which comes a frame after the
## touch. Returns null if the player never lands.
func _spawn_standing(at: Vector2) -> Player:
	var player: Player = await spawn_on_floor(at)
	if player == null:
		return null
	for _frame: int in MAX_FRAMES:
		if player.get_state() == Player.State.ON_FLOOR:
			return player
		await physics_frame
	player.queue_free()
	return null


## A camera following player with its own copy of Stats and an instant follow, so that it sits on
## its focus plus its lead. Its physics step is off, so the case calls it by hand.
func _spawn_camera_by_hand(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.follow_sharpness = INSTANT_SHARPNESS
	root.add_child(camera)
	camera.set_physics_process(false)
	return camera


func _spawn_camera(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	root.add_child(camera)
	return camera


## Half the height of the screen the game is made for, in px.
func _half_screen_height() -> float:
	return float(ProjectSettings.get_setting("display/window/size/viewport_height")) / 2.0


## The length of one physics step, in seconds.
func _step() -> float:
	return 1.0 / Engine.physics_ticks_per_second


func _remove_all(nodes: Array) -> void:
	for node: Node in nodes:
		node.queue_free()
	await physics_frame


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame
