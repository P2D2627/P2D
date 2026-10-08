# Test of the game camera's look ahead. The values meet their criteria: at full run the screen shows
# at least 1.5 s of run ahead of the player, and the turn threshold is wider than what the player
# crosses in the widest chimney climbed tapping Jump. Before the player first goes Turn Threshold
# from where it started, the camera does not lead; past it, the camera leads that way by Look Ahead
# Distance. Going back and forth less than the threshold, as in a chimney, keeps the lead; going
# back past it turns the lead to the other side. The turn starts slowly, peaks at the speed of a
# critically damped spring, never goes past its new side and is 95 % done when the spring says. Two
# half steps land where one whole step does. At full run, with the physics, the screen shows at
# least 1.5 s ahead.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_look_ahead.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/camera/game_camera.tscn")
## The least run, in seconds, the screen must show ahead of the player at full run.
const SECONDS_AHEAD: float = 1.5
## The widest chimney climbed pressing only Jump on touching a wall, wall face to wall face, in px,
## as measure_movement.gd measures it.
const WIDEST_TAPPED_CHIMNEY: float = 222.0
## A smoothing so fast that one step closes the whole distance, to see the look ahead on its own.
const INSTANT_SHARPNESS: float = 1.0e6
## Where the cases that call the camera by hand put the player.
const START: Vector2 = Vector2(1000.0, 500.0)
## How far past the turn threshold those cases move the player, in px.
const PAST_THE_THRESHOLD: float = 10.0
## How far the player runs on, the way the camera leads, before turning back, in px.
const RUN_ON: float = 1000.0
## A swing settles in this many seconds times 1 / Look Ahead Sharpness: a critically damped spring
## then has (1 + 20) × exp(-20), under a millionth of the swing, left to go.
const SETTLE_TIMES: float = 20.0
## How close the lead must be to where it settles, in px.
const LEAD_TOLERANCE: float = 0.01
## Back-and-forth trips of the chimney case, and the steps it waits at each wall.
const CHIMNEY_TRIPS: int = 10
const STEPS_AT_A_WALL: int = 20
## What a critically damped spring has left to go, as a share of the swing, when it is 95 % done,
## and that time times the sharpness: (1 + x) × exp(-x) = 0.05 at x = 4.744.
const SHARE_LEFT_WHEN_DONE: float = 0.05
const DONE_TIME_TIMES_SHARPNESS: float = 4.744
## How much the first step of a swing may move, as a share of the swing. A spring starts at rest and
## moves about 0.2 %; a first-order smoothing at the same sharpness would move about 6 %.
const FIRST_STEP_SHARE: float = 0.005
## How far a swing's top speed may be from a spring's, swing × sharpness / e, as a share of it.
const PEAK_SPEED_TOLERANCE: float = 0.02
## How close two positions must be to count as the same, in px.
const SAME_SPOT: float = 0.01
## The floor of the run case goes from -FLOOR_HALF_WIDTH to FLOOR_HALF_WIDTH.
const FLOOR_HALF_WIDTH: float = 4000.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## Physics frames of the run: 4 s, long enough for the lead and the trail to settle.
const RUN_FRAMES: int = 240


func _initialize() -> void:
	# Nodes added before the first frame only get _ready on it, and the cases that call the camera by
	# hand need it ready, with its turn reference set, as soon as it is added.
	await process_frame
	var results: Array[bool] = []
	results.append(_the_values_meet_their_criteria())
	results.append(await _before_the_player_commits_there_is_no_lead())
	results.append(await _past_the_threshold_the_camera_leads_that_way())
	results.append(await _going_back_and_forth_less_than_the_threshold_keeps_the_lead())
	results.append(await _going_back_past_the_threshold_turns_the_lead())
	results.append(await _the_turn_starts_slowly_and_stops_without_going_past())
	results.append(await _two_half_steps_land_where_one_whole_step_does())
	results.append(await _at_full_run_the_screen_shows_enough_ahead())
	finish(results)


## At full run, the screen shows at least 1.5 s of run ahead of the player: half the screen, plus
## the look ahead, minus what the window and the smoothing leave behind. And the turn threshold is
## wider than what the player crosses in the widest chimney climbed tapping Jump.
func _the_values_meet_their_criteria() -> bool:
	var stats: CameraStats = load("res://resources/camera_stats.tres") as CameraStats
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var run_speed: float = player.stats.max_run_speed
	var chimney_sway: float = WIDEST_TAPPED_CHIMNEY - body_size(player).x
	player.queue_free()
	var weight: float = 1.0 - exp(-stats.follow_sharpness * _step())
	var trail: float = stats.window_half_width + run_speed * _step() * (1.0 - weight) / weight
	var ahead: float = _half_screen_width() + stats.look_ahead_distance - trail
	var sees_enough: bool = ahead >= SECONDS_AHEAD * run_speed
	var chimney_keeps_the_lead: bool = stats.turn_threshold > chimney_sway
	return report(sees_enough and chimney_keeps_the_lead,
			"At full run %.0f px ahead, %.2f s (at least %.1f); turn threshold %.0f px for a %.0f px chimney sway"
			% [ahead, ahead / run_speed, SECONDS_AHEAD, stats.turn_threshold, chimney_sway])


## Before the player first goes Turn Threshold from where it started, either way, the camera does not
## lead.
func _before_the_player_commits_there_is_no_lead() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var near: float = camera.stats.turn_threshold - PAST_THE_THRESHOLD
	var largest_lead: float = 0.0
	for x: float in [near, -near, 0.0]:
		player.global_position = START + Vector2(x, 0.0)
		_settle_by_hand(camera)
		largest_lead = maxf(largest_lead, absf(camera.get_look_ahead()))
	await _remove(camera)
	await _remove(player)
	return report(largest_lead < LEAD_TOLERANCE,
			"Up to %.0f px from the start: largest lead %.3f px" % [near, largest_lead])


## Once the player goes Turn Threshold to the right of where it started, the camera leads to the
## right by Look Ahead Distance: it sits that far ahead of the focus.
func _past_the_threshold_the_camera_leads_that_way() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = camera.stats
	var right: float = stats.turn_threshold + PAST_THE_THRESHOLD
	player.global_position = START + Vector2(right, 0.0)
	_settle_by_hand(camera)
	var lead: float = camera.get_look_ahead()
	var focus_x: float = START.x + right - stats.window_half_width
	var ahead_of_the_focus: float = camera.global_position.x - focus_x
	await _remove(camera)
	await _remove(player)
	return report(absf(lead - stats.look_ahead_distance) < LEAD_TOLERANCE
			and absf(ahead_of_the_focus - stats.look_ahead_distance) < LEAD_TOLERANCE,
			"%.0f px to the right: lead %.3f px, camera %.3f px ahead of the focus (Look Ahead Distance %.0f)"
			% [right, lead, ahead_of_the_focus, stats.look_ahead_distance])


## Leading to the right, the player going back and forth across the widest chimney climbed tapping
## Jump keeps the lead: it never goes Turn Threshold back.
func _going_back_and_forth_less_than_the_threshold_keeps_the_lead() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = camera.stats
	var right_wall: Vector2 = START + Vector2(stats.turn_threshold + PAST_THE_THRESHOLD, 0.0)
	player.global_position = right_wall
	_settle_by_hand(camera)
	var sway: float = WIDEST_TAPPED_CHIMNEY - body_size(player).x
	var smallest_lead: float = camera.get_look_ahead()
	for _trip: int in CHIMNEY_TRIPS:
		for x: float in [-sway, 0.0]:
			player.global_position = right_wall + Vector2(x, 0.0)
			for _step_index: int in STEPS_AT_A_WALL:
				camera._physics_process(_step())
			smallest_lead = minf(smallest_lead, camera.get_look_ahead())
	await _remove(camera)
	await _remove(player)
	return report(absf(smallest_lead - stats.look_ahead_distance) < LEAD_TOLERANCE,
			"%d trips across a %.0f px chimney sway: smallest lead %.3f px"
			% [CHIMNEY_TRIPS, sway, smallest_lead])


## Leading to the right, and after running on that way, the player going back Turn Threshold past the
## farthest point it reached turns the lead to the left, by Look Ahead Distance. Going back less than
## that from the farthest point keeps the lead, even when it is more than that from where the lead
## first turned.
func _going_back_past_the_threshold_turns_the_lead() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = camera.stats
	var back: Vector2 = Vector2(stats.turn_threshold + PAST_THE_THRESHOLD, 0.0)
	player.global_position = START + back
	_settle_by_hand(camera)
	var farthest: Vector2 = START + back + Vector2(RUN_ON, 0.0)
	player.global_position = farthest
	_settle_by_hand(camera)
	player.global_position = farthest - back + Vector2(2.0 * PAST_THE_THRESHOLD, 0.0)
	_settle_by_hand(camera)
	var lead_short_of_it: float = camera.get_look_ahead()
	player.global_position = farthest - back
	_settle_by_hand(camera)
	var lead_past_it: float = camera.get_look_ahead()
	await _remove(camera)
	await _remove(player)
	return report(absf(lead_short_of_it - stats.look_ahead_distance) < LEAD_TOLERANCE
			and absf(lead_past_it + stats.look_ahead_distance) < LEAD_TOLERANCE,
			"After running on %.0f px: back %.0f px from the farthest point, lead %.3f px; back %.0f px, lead %.3f px"
			% [RUN_ON, back.x - 2.0 * PAST_THE_THRESHOLD, lead_short_of_it, back.x, lead_past_it])


## A turn from one side to the other starts slowly, peaks at the speed of a critically damped spring
## (swing × sharpness / e), never goes past its new side and is 95 % done at 4.744 / sharpness s.
func _the_turn_starts_slowly_and_stops_without_going_past() -> bool:
	var player: Player = _spawn_still_player(START)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = camera.stats
	var farthest: Vector2 = START + Vector2(stats.turn_threshold + PAST_THE_THRESHOLD, 0.0)
	player.global_position = farthest
	_settle_by_hand(camera)
	player.global_position = farthest - Vector2(stats.turn_threshold + PAST_THE_THRESHOLD, 0.0)
	var swing: float = 2.0 * stats.look_ahead_distance
	var previous: float = camera.get_look_ahead()
	var first_move: float = -1.0
	var top_speed: float = 0.0
	var lowest: float = previous
	var done_time: float = -1.0
	for step_index: int in _settle_steps(stats):
		camera._physics_process(_step())
		var lead: float = camera.get_look_ahead()
		var move: float = absf(lead - previous)
		if first_move < 0.0:
			first_move = move
		top_speed = maxf(top_speed, move / _step())
		lowest = minf(lowest, lead)
		if done_time < 0.0 and lead + stats.look_ahead_distance <= SHARE_LEFT_WHEN_DONE * swing:
			done_time = (step_index + 1) * _step()
		previous = lead
	await _remove(camera)
	await _remove(player)
	var spring_top_speed: float = swing * stats.look_ahead_sharpness / exp(1.0)
	var spring_done_time: float = DONE_TIME_TIMES_SHARPNESS / stats.look_ahead_sharpness
	var starts_slowly: bool = first_move <= FIRST_STEP_SHARE * swing
	var spring_speed: bool = absf(top_speed - spring_top_speed) <= PEAK_SPEED_TOLERANCE * spring_top_speed
	var never_past: bool = lowest >= -stats.look_ahead_distance - SAME_SPOT
	var done_on_time: bool = done_time > 0.0 and absf(done_time - spring_done_time) <= _step()
	return report(starts_slowly and spring_speed and never_past and done_on_time,
			"Turn of %.0f px: first step %.2f px, top speed %.0f px/s (spring %.0f), lowest %.3f px, 95 %% done at %.3f s (spring %.3f)"
			% [swing, first_move, top_speed, spring_top_speed, lowest, done_time, spring_done_time])


## Two cameras set up the same way turn their lead, one with a step twice as long and the other with
## two steps. They land on the same lead and stay together on the next step, so the swing does not
## depend on the length of the step.
func _two_half_steps_land_where_one_whole_step_does() -> bool:
	var player: Player = _spawn_still_player(START)
	var whole: GameCamera = _spawn_camera_by_hand(player)
	var halves: GameCamera = _spawn_camera_by_hand(player)
	var stats: CameraStats = whole.stats
	var farthest: Vector2 = START + Vector2(stats.turn_threshold + PAST_THE_THRESHOLD, 0.0)
	player.global_position = farthest
	_settle_by_hand(whole)
	_settle_by_hand(halves)
	player.global_position = farthest - Vector2(stats.turn_threshold + PAST_THE_THRESHOLD, 0.0)
	var before: float = whole.get_look_ahead()
	whole._physics_process(2.0 * _step())
	halves._physics_process(_step())
	halves._physics_process(_step())
	var apart_after_the_step: float = absf(whole.get_look_ahead() - halves.get_look_ahead())
	whole._physics_process(_step())
	halves._physics_process(_step())
	var apart_after_the_next: float = absf(whole.get_look_ahead() - halves.get_look_ahead())
	var moved: float = absf(whole.get_look_ahead() - before)
	await _remove(whole)
	await _remove(halves)
	await _remove(player)
	return report(apart_after_the_step < SAME_SPOT and apart_after_the_next < SAME_SPOT
			and moved > SAME_SPOT,
			"One step of %.4f s against two of %.4f s: %.4f px apart, then %.4f px apart; moved %.2f px"
			% [2.0 * _step(), _step(), apart_after_the_step, apart_after_the_next, moved])


## At full run, with the physics, once the lead and the trail settle, the screen shows at least
## 1.5 s of run ahead of the player.
func _at_full_run_the_screen_shows_enough_ahead() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(ground)
		return report(false, "Full run: the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	Input.action_press(&"move_right")
	for _frame: int in RUN_FRAMES:
		await physics_frame
	var ahead: float = camera.global_position.x + _half_screen_width() - player.global_position.x
	var speed: float = player.velocity.x
	Input.action_release(&"move_right")
	await _remove(camera)
	await _remove(player)
	await _remove(ground)
	return report(speed > 0.0 and ahead >= SECONDS_AHEAD * speed,
			"Full run at %.0f px/s: %.0f px ahead, %.2f s" % [speed, ahead, ahead / maxf(speed, 1.0)])


## A player that does not move on its own: its physics step is off, so only the case moves it.
func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


## A camera following player with its own copy of Stats and an instant follow, so that it sits on its
## focus plus its look ahead. Its physics step is off, so the case calls it by hand.
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


## Calls the camera's physics step by hand until a swing of its look ahead has settled.
func _settle_by_hand(camera: GameCamera) -> void:
	for _step_index: int in _settle_steps(camera.stats):
		camera._physics_process(_step())


func _settle_steps(stats: CameraStats) -> int:
	return ceili(SETTLE_TIMES / stats.look_ahead_sharpness / _step())


## Half the width of the screen the game is made for, in px.
func _half_screen_width() -> float:
	return float(ProjectSettings.get_setting("display/window/size/viewport_width")) / 2.0


## The length of one physics step, in seconds.
func _step() -> float:
	return 1.0 / Engine.physics_ticks_per_second


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame
