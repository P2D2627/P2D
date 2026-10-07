# Checks the wall slide (ADR 0010). Against a wall it pushed into, the player falls no faster than
# Wall Slide Speed from the frame after it reaches the wall, and keeps sliding after letting go of
# the direction. A jump along the wall peaks at Jump Height and slides after the peak, even after
# letting go of the direction in the air. Touching a wall without ever pushing into it, pushing away
# from it, and running away from it on the floor all work as without a wall.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_slide.gd
extends "res://tests/support/player_test.gd"

## The wall's face is at x = WALL_FACE, on the player's left; the floor's top is at y = 0.
const WALL_FACE: float = 0.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -3000.0
const FLOOR_RIGHT: float = 2000.0
## Where a fall starts: high enough to reach the top falling speed well before the floor.
const START_HEIGHT: float = -1500.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## How far from the wall the player starts, in px.
const GAP: float = 40.0
## Frames to keep pushing after the first contact, so the player is surely on the wall.
const SETTLE_FRAMES: int = 3
## How far a peak may be from Jump Height, in px, as in test_jump_height.gd.
const HEIGHT_TOLERANCE: float = 1.0
## How far a speed may be from the one expected, in px/s.
const SPEED_TOLERANCE: float = 0.01

## Half the width of the player's collision box, read from its scene.
var _half_width: float = 0.0


func _initialize() -> void:
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP)
	make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	_half_width = body_size(probe).x / 2.0
	probe.queue_free()
	var results: Array[bool] = []
	results.append(await _pushing_into_the_wall_slides_at_wall_slide_speed())
	results.append(await _letting_go_on_the_wall_keeps_sliding())
	results.append(await _letting_go_in_a_jump_along_the_wall_slides_after_the_peak())
	results.append(await _pushing_away_from_the_wall_falls_as_without_it())
	results.append(await _touching_the_wall_without_pushing_falls_as_without_it())
	results.append(await _jumping_along_the_wall_peaks_at_jump_height())
	results.append(await _running_away_from_the_wall_on_the_floor_steps_as_on_the_floor())
	finish(results)


## The slide itself, with the brake all at once: from the frame after the player reaches the wall
## it pushed into, it falls no faster than Wall Slide Speed, and it slides at that speed.
func _pushing_into_the_wall_slides_at_wall_slide_speed() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_left")
	var touched: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"move_left")
	return await _report_slide(player, touched, fall, "Falling while pushing into the wall")


## Staying on the wall needs no holding: after letting go of the direction, the player keeps
## sliding, because letting go does not take it off the wall.
func _letting_go_on_the_wall_keeps_sliding() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_left")
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_left")
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_slide(player, touched, fall, "Letting go of the direction on the wall")


## The wall also works on the way up: jumping along the wall while pushing into it puts the player
## on the wall, so after letting go of the direction in the air it still slides after the peak.
func _letting_go_in_a_jump_along_the_wall_slides_after_the_peak() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Letting go in a jump along the wall: never stood against the wall")
	Input.action_press(&"jump")
	var rose: bool = await _wait_until_rising(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_left")
	await _wait_until_falling(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"jump")
	return await _report_slide(player, rose, fall,
			"Letting go of the direction in a jump along the wall, after the peak")


## Pushing away takes the player off the wall, and it falls as without a wall again, up to the top
## falling speed.
func _pushing_away_from_the_wall_falls_as_without_it() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_left")
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_left")
	Input.action_press(&"move_right")
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"move_right")
	return await _report_fall_as_without_a_wall(player, touched, fall, "Pushing away from the wall")


## Getting on the wall needs a push into it: touching a wall without ever pushing into it falls as
## without a wall, up to the top falling speed.
func _touching_the_wall_without_pushing_falls_as_without_it() -> bool:
	var player: Player = _spawn_near_the_wall(0.0, START_HEIGHT)
	var touching: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_fall_as_without_a_wall(player, touching, fall,
			"Touching the wall without pushing into it")


## The brake only acts on the way down: a full jump along the wall, pushing into it all the way,
## still peaks at Jump Height. As the jump starts on the floor against the wall, it also checks
## that the floor still jumps there.
func _jumping_along_the_wall_peaks_at_jump_height() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Full jump along the wall: never stood against the wall")
	var floor_y: float = player.position.y
	Input.action_press(&"jump")
	var peak: float = await _peak_height(player, floor_y)
	Input.action_release(&"jump")
	Input.action_release(&"move_left")
	var expected: float = player.stats.jump_height
	await _remove(player)
	return report(absf(peak - expected) <= HEIGHT_TOLERANCE,
			"Full jump along the wall: peak %.1f px, Jump Height %.1f px, tolerance %.1f px"
			% [peak, expected, HEIGHT_TOLERANCE])


## The floor comes before the wall: on the floor against the wall, the first step of a run away
## from it is the floor's, which is larger than the air's.
func _running_away_from_the_wall_on_the_floor_steps_as_on_the_floor() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Running away from the wall on the floor: never stood against it")
	Input.action_release(&"move_left")
	Input.action_press(&"move_right")
	var first_step: float = 0.0
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.velocity.x > 0.0:
			first_step = player.velocity.x
			break
	Input.action_release(&"move_right")
	var floor_step: float = (player.stats.max_run_speed / player.stats.time_to_max_speed
			/ Engine.physics_ticks_per_second)
	var on_floor: bool = player.is_on_floor()
	await _remove(player)
	return report(on_floor and is_equal_approx(first_step, floor_step),
			"Running away from the wall on the floor: first step %.1f px/s, floor step %.1f px/s"
			% [first_step, floor_step])


## The x at which the side of the player's body is gap px from the wall.
func _x_near_the_wall(gap: float) -> float:
	return WALL_FACE + _half_width + gap


func _spawn_near_the_wall(gap: float, height: float) -> Player:
	return spawn_player(Vector2(_x_near_the_wall(gap), height))


## A player on the floor that walked from GAP px away into the wall and is still pushing into it,
## with move_left held. Null, with nothing held, if it never lands or never reaches the wall.
func _spawn_against_the_wall_on_the_floor() -> Player:
	var player: Player = await spawn_on_floor(Vector2(_x_near_the_wall(GAP), FLOOR_SPAWN_HEIGHT))
	if player == null:
		return null
	Input.action_press(&"move_left")
	if not await _wait_until_on_wall(player):
		Input.action_release(&"move_left")
		await _remove(player)
		return null
	await _wait_frames(SETTLE_FRAMES)
	return player


func _wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


## True once the player is off the floor and going up, which only a jump does here.
func _wait_until_rising(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor() and player.velocity.y < 0.0:
			return true
	return false


## Waits for the peak: the first frame on which the player no longer goes up.
func _wait_until_falling(player: Player) -> void:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.velocity.y >= 0.0:
			return


func _wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


## Follows the player down until it lands, for the fastest falling speed and the last one.
func _fall_until_the_floor(player: Player) -> FallResult:
	var fall: FallResult = FallResult.new()
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			break
		fall.fastest = maxf(fall.fastest, player.velocity.y)
		fall.last = player.velocity.y
	return fall


## How high the feet go above floor_y before the player lands again, in px; 0 if it never leaves
## the floor.
func _peak_height(player: Player, floor_y: float) -> float:
	var highest_y: float = floor_y
	var left_floor: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			if left_floor:
				break
			continue
		left_floor = true
		highest_y = minf(highest_y, player.position.y)
	return floor_y - highest_y


## PASS if the case got going and the player never fell faster than Wall Slide Speed, ending at it.
func _report_slide(player: Player, got_going: bool, fall: FallResult, what: String) -> bool:
	var slide_speed: float = player.stats.wall_slide_speed
	var passed: bool = (got_going and fall.fastest <= slide_speed + SPEED_TOLERANCE
			and absf(fall.last - slide_speed) <= SPEED_TOLERANCE)
	await _remove(player)
	return report(passed, "%s: fastest fall %.1f px/s, last %.1f px/s, Wall Slide Speed %.1f px/s%s"
			% [what, fall.fastest, fall.last, slide_speed, _got_going_note(got_going)])


## PASS if the case got going and the player fell up to the top falling speed, as without a wall.
func _report_fall_as_without_a_wall(player: Player, got_going: bool, fall: FallResult,
		what: String) -> bool:
	var top_speed: float = player.stats.max_fall_speed
	var passed: bool = got_going and absf(fall.fastest - top_speed) <= SPEED_TOLERANCE
	await _remove(player)
	return report(passed, "%s: fastest fall %.1f px/s, Max Fall Speed %.1f px/s%s"
			% [what, fall.fastest, top_speed, _got_going_note(got_going)])


func _got_going_note(got_going: bool) -> String:
	return "" if got_going else " (the case never got going)"


func _remove(player: Player) -> void:
	player.queue_free()
	await physics_frame


## What _fall_until_the_floor follows, in px/s: the fastest falling speed until the landing, and the
## falling speed on the last frame before it.
class FallResult:
	var fastest: float = 0.0
	var last: float = 0.0
