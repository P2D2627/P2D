# Checks Lust phase 3. The player starts on the start ledge. Both slides carry the player down with
# no input: the hill's side to the left, the ramp under the rock ledge to the right. Dropping off the
# pillar's top while holding left, the player slides down the wall beside it and lands on the hill;
# the pit beside the pillar has spikes all across. In the crossing, Second, Lift and Ferry keep
# looping with the player away, while First rests until the player stands on it; whenever the player
# boards it, First reaches the middle at its normal speed and meets Second there. A player who jumps at each meeting crosses it: from
# First to Second as they meet in the
# middle, from Second up to Lift when Second is back at its end, from Lift to Ferry at the top; from
# Ferry, back at its end, the player walks onto the ramp, slides down it and jumps from its end onto
# the first new step. A player who stays on First falls when it flips, and one who stays on Second
# sees Lift come back down beside it again and again. From the walkway after the
# new steps, the player walks into the chimney by the right wall, climbs it by wall jumps out through
# the hole in the rock ledge and lands on the ledge. Every other chimney on the way can be climbed
# too: the retry chimney by the left block, the shaft by the pillar up to the hole into the side
# corridor, the one at the end of the spike ledge and the spiked shaft to the finish tunnel.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase3.gd
extends "res://tests/support/player_test.gd"

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/Lust/LustLevel_Phase3.tscn")
const TILE: float = 48.0
## The start ledge's top, where the player begins.
const START_LEDGE_TOP: float = 112.0 * TILE
## Spots just above each slide, and how far a slide must carry the player in SLIDE_FRAMES with no
## input.
const ON_THE_HILL_SLIDE: Vector2 = Vector2(2592.0, 5040.0)
const ON_THE_RAMP: Vector2 = Vector2(5400.0, 2190.0)
const SLIDE_FRAMES: int = 60
const MIN_SLIDE_DISTANCE: float = 96.0
## Where the ramp ends, on its right, and how far before it the bot jumps.
const RAMP_END_X: float = 6340.0
const RAMP_JUMP_MARGIN: float = 90.0
## The pillar's top and its left edge, the wall beside it and the hill's top.
const PILLAR_TOP: float = 62.0 * TILE
const PILLAR_LEFT: float = 84.0 * TILE
const WALL_RIGHT: float = 76.0 * TILE
const HILL_TOP: float = 101.0 * TILE
## A spot over the left end of the pit beside the pillar.
const OVER_THE_PIT: Vector2 = Vector2(76.5 * TILE, 110.0 * TILE)
## The walkway after the new steps, the chimney's floor at its right end, the rock ledge's top and
## its end by the hole, where the chimney comes out.
const WALKWAY: Vector2 = Vector2(148.5 * TILE, 50.0 * TILE)
const CHIMNEY_FLOOR_X: float = 155.5 * TILE
const LEDGE_TOP: float = 35.0 * TILE
const LEDGE_END: float = 154.0 * TILE
## The first new step, where the ramp leads: its top and its left and right edges.
const FIRST_STEP_TOP: float = 49.0 * TILE
const FIRST_STEP_LEFT: float = 136.0 * TILE
const FIRST_STEP_RIGHT: float = 140.0 * TILE
## Half a platform's height, above its centre, in px.
const PLATFORM_HALF_HEIGHT: float = 12.0
## How far the player keeps drifting after letting go of the direction in the air, in px; the bot
## lets go this far before the middle of what it jumps to.
const DRIFT: float = 70.0
## How long before First and Second meet the bot jumps across, in s.
const EARLY_JUMP: float = 0.3
## How far a player who stayed on First must have fallen below its top to count as dropped, in px.
const DROPPED_DEPTH: float = 2.0 * TILE
## Physics frames for a platform's rider sensor to see the player who just landed.
const SENSOR_FRAMES: int = 2
## How long the bot waits before standing on First, on each try, in s: First must meet Second
## whatever the moment.
const BOARDING_DELAYS: Array[float] = [0.0, 2.7, 5.9]
## Room for two platforms side by side in the middle, in px: their centres are a platform apart.
const PLATFORM_WIDTH: float = 192.0
const MEETING_TOLERANCE: float = 1.0
## One physics frame, in s: room for timing a trip.
const FRAME_TIME: float = 1.0 / 60.0
## Room for a platform's position at its rest, in px.
const REST_TOLERANCE: float = 1.0
## Each chimney: its name, the spot at its bottom where the climb starts (in tiles, feet) and the
## height the feet must reach to step out at the top (in tiles).
const CHIMNEYS: Array = [
	["retry chimney", Vector2(4.0, 116.0), 80.0],
	["shaft by the pillar", Vector2(104.5, 116.0), 93.0],
	["chimney at the end of the spike ledge", Vector2(157.0, 86.0), 78.0],
	["spiked shaft", Vector2(4.5, 21.0), 8.0],
]
## How long a player who stays on Second watches the crossing, in physics frames, and how many
## times Lift must come down beside Second and Ferry go to meet Lift meanwhile.
const WATCH_FRAMES: int = 30 * 60
const MIN_MEETINGS: int = 2
## Physics frames a chimney climb may take.
const CLIMB_FRAMES: int = 900

var _level: Node2D
var _player: Player
var _stand_in: StandInInput
var _cycle: PlatformCycle
var _first: CyclePlatform
var _second: CyclePlatform
var _lift: CyclePlatform
var _ferry: CyclePlatform


func _initialize() -> void:
	var results: Array[bool] = []
	await _load_level()
	results.append(await _player_starts_on_the_start_ledge())
	results.append(await _slide_carries_the_player("hill's side", ON_THE_HILL_SLIDE, -1.0))
	results.append(await _slide_carries_the_player("ramp under the rock ledge", ON_THE_RAMP, 1.0))
	results.append(await _dropping_off_the_pillar_holding_left_lands_on_the_hill())
	results.append(await _pit_beside_the_pillar_hits_at_its_left_end())
	results.append(await _crossing_loops_while_first_waits_for_the_player())
	results.append(await _first_meets_second_whenever_the_player_boards())
	results.append(await _jumping_at_each_meeting_crosses_to_the_ramp_and_the_first_step())
	results.append(await _staying_on_first_drops_the_player_when_it_flips())
	results.append(await _missing_the_jump_to_lift_brings_it_back())
	results.append(await _chimney_by_the_right_wall_leads_onto_the_rock_ledge())
	for chimney: Array in CHIMNEYS:
		results.append(await _chimney_can_be_climbed(chimney[0], chimney[1], chimney[2]))
	finish(results)


func _load_level() -> void:
	_level = LEVEL_SCENE.instantiate() as Node2D
	root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_stand_in = put_a_stand_in(_player)
	_cycle = _level.get_node(^"Crossing/Cycle") as PlatformCycle
	_first = _level.get_node(^"Crossing/First") as CyclePlatform
	_second = _level.get_node(^"Crossing/Second") as CyclePlatform
	_lift = _level.get_node(^"Crossing/Lift") as CyclePlatform
	_ferry = _level.get_node(^"Crossing/Ferry") as CyclePlatform


func _player_starts_on_the_start_ledge() -> bool:
	var landed: bool = await wait_until_on_floor(_player)
	return report(landed and absf(_player.global_position.y - START_LEDGE_TOP) <= 1.0,
			"Start: the player stands at y %.0f, the start ledge's top is %.0f"
			% [_player.global_position.y, START_LEDGE_TOP])


## direction is -1 for a slide going down to the left, 1 for one going down to the right.
func _slide_carries_the_player(slide: String, spot: Vector2, direction: float) -> bool:
	_stand_in.run_direction = 0.0
	_teleport(spot)
	await wait_until(func() -> bool: return _player.is_on_wall() or _player.is_on_floor())
	var from: Vector2 = _player.global_position
	await wait_frames(SLIDE_FRAMES)
	var moved: Vector2 = _player.global_position - from
	return report(direction * moved.x >= MIN_SLIDE_DISTANCE and moved.y > 0.0,
			"Slide on the %s: with no input the player moved %.0f px %s and %.0f px down in %d frames"
			% [slide, absf(moved.x), "left" if moved.x < 0.0 else "right", moved.y, SLIDE_FRAMES])


func _dropping_off_the_pillar_holding_left_lands_on_the_hill() -> bool:
	_stand_in.run_direction = 0.0
	_teleport(Vector2(PILLAR_LEFT + 30.0, PILLAR_TOP - 2.0))
	await wait_until_on_floor(_player)
	_stand_in.run_direction = -1.0
	await wait_until(func() -> bool: return _player.global_position.y > PILLAR_TOP + TILE)
	var landed: bool = await wait_until_on_floor(_player)
	_stand_in.run_direction = 0.0
	var at: Vector2 = _player.global_position
	return report(landed and absf(at.y - HILL_TOP) <= 1.0 and at.x < WALL_RIGHT,
			"Dropping off the pillar holding left: landed at (%.0f, %.0f); the hill's top is at y %.0f, left of x %.0f"
			% [at.x, at.y, HILL_TOP, WALL_RIGHT])


func _pit_beside_the_pillar_hits_at_its_left_end() -> bool:
	var hits: Array[String] = []
	for node: Node in _level.get_tree().get_nodes_in_group(Hazard.GROUP):
		var hazard: Hazard = node as Hazard
		hazard.player_hit.connect(func(_body: Node2D, _fraction: float) -> void:
			hits.append(hazard.name))
	_stand_in.run_direction = 0.0
	_teleport(OVER_THE_PIT)
	var hit: bool = await wait_until(func() -> bool: return not hits.is_empty())
	return report(hit and hits[0].begins_with("PillarPitSpikes"),
			"Falling into the left end of the pit beside the pillar: hit by %s"
			% (hits[0] if hit else "nothing"))


## Watching a whole loop with the player away: Second, Lift and Ferry move, First stays at its rest.
func _crossing_loops_while_first_waits_for_the_player() -> bool:
	_stand_in.run_direction = 0.0
	_teleport(ON_THE_HILL_SLIDE)
	var moved: Dictionary = {_second: 0.0, _lift: 0.0, _ferry: 0.0}
	var start: Dictionary = {}
	for platform: CyclePlatform in moved:
		start[platform] = platform.global_position
	var first_stayed: bool = true
	for _frame: int in ceili(_cycle.get_loop_time() * 60.0) + 60:
		await physics_frame
		for platform: CyclePlatform in moved:
			moved[platform] = maxf(moved[platform],
					platform.global_position.distance_to(start[platform]))
		first_stayed = first_stayed and _at(_first, _first.point_a) and not _cycle.is_first_out()
	return report(moved[_second] > TILE and moved[_lift] > TILE and moved[_ferry] > TILE
			and first_stayed,
			"Crossing with the player away for a loop: Second, Lift and Ferry moved up to %.0f, %.0f and %.0f px; First stayed at its rest %s"
			% [moved[_second], moved[_lift], moved[_ferry], first_stayed])


## Standing on First at different moments of the loop, First always gets to the middle in its
## normal time, Approach Time, however long it then waits there, and meets Second: side by side, a
## platform apart.
func _first_meets_second_whenever_the_player_boards() -> bool:
	var gaps: Array[float] = []
	var trips: Array[float] = []
	for delay: float in BOARDING_DELAYS:
		await wait_until(func() -> bool: return not _cycle.is_first_out(), MAX_FRAMES * 3)
		await wait_frames(roundi(delay * 60.0))
		var meeting: float = await _board_first()
		if meeting < 0.0:
			return report(false, "First never set off with the player")
		var set_off: float = _cycle.get_clock()
		await wait_until(func() -> bool: return _at(_first, _first.point_b), MAX_FRAMES * 3)
		trips.append(_cycle.get_clock() - set_off)
		await _wait_for_time(meeting)
		gaps.append(_second.global_position.x - _first.global_position.x)
	var on_time: bool = true
	for trip: float in trips:
		on_time = on_time and trip <= _cycle.approach_time + FRAME_TIME
	var met: bool = true
	for gap: float in gaps:
		met = met and absf(gap - PLATFORM_WIDTH) <= MEETING_TOLERANCE
	return report(on_time and met, "First boarded %s s into waiting: got to the middle in %s s (Approach Time %.1f), Second's centre was %s px right of First's at the meeting, expected %.0f"
			% [BOARDING_DELAYS, trips, _cycle.approach_time, gaps, PLATFORM_WIDTH])


func _jumping_at_each_meeting_crosses_to_the_ramp_and_the_first_step() -> bool:
	var starts: Array[int] = [0]
	_cycle.first_set_off.connect(func() -> void: starts[0] += 1)
	var meeting: float = await _board_first()
	if meeting < 0.0 or not await _wait_for_time(meeting - EARLY_JUMP):
		return report(false, "First never set off with the player")
	var on_second: bool = await _jump_onto(_second)
	await _wait_for_time(_cycle.get_flip_after(meeting) + _cycle.flip_time)
	var first_flipped: bool = absf(_first.rotation_degrees) >= 45.0
	await _wait_for_time(_cycle.get_lift_meeting_after(meeting))
	var on_lift: bool = await _jump_onto(_lift)
	await _wait_for_time(_cycle.get_ferry_meeting_after(meeting))
	var on_ferry: bool = await _jump_onto(_ferry)
	var carried_back: bool = await wait_until(func() -> bool: return _at(_ferry, _ferry.point_a))
	# Off Ferry to the right, onto the block and the ramp, then the ramp does the rest.
	_stand_in.run_direction = 1.0
	await wait_until(func() -> bool: return _player.global_position.x >= ON_THE_RAMP.x)
	_stand_in.run_direction = 0.0
	var reached_the_end: bool = await wait_until(func() -> bool:
		return _player.global_position.x >= RAMP_END_X - RAMP_JUMP_MARGIN)
	var on_step: bool = await _jump_onto_the_first_step()
	return report(on_second and first_flipped and on_lift and on_ferry and carried_back
			and reached_the_end and on_step and starts[0] == 1,
			"Crossing: onto Second %s (First flipped %s), onto Lift %s, onto Ferry %s, carried back %s, slid to the ramp's end %s, onto the first step %s, runs started %d"
			% [on_second, first_flipped, on_lift, on_ferry, carried_back, reached_the_end, on_step,
			starts[0]])


func _staying_on_first_drops_the_player_when_it_flips() -> bool:
	var meeting: float = await _board_first()
	if meeting < 0.0 or not await _wait_for_time(_cycle.get_flip_after(meeting) + _cycle.flip_time):
		return report(false, "First never set off with the player again")
	var top_at_the_flip: float = _first.global_position.y - PLATFORM_HALF_HEIGHT
	var dropped: bool = await wait_until(func() -> bool:
		return _player.global_position.y > top_at_the_flip + DROPPED_DEPTH)
	return report(dropped, "Staying on First: dropped below it after the flip %s" % dropped)


## The bug: the crossing used to stop after one run, so a player who missed the jump from Second to
## Lift stayed on Second for good. A player who stays on Second must see Lift come down beside it
## again and again, and Ferry keep going to meet Lift.
func _missing_the_jump_to_lift_brings_it_back() -> bool:
	if not await _stand_on(_second):
		return report(false, "the player never stood on Second")
	var lift_meetings: int = 0
	var ferry_meetings: int = 0
	var lift_was_down: bool = false
	var ferry_was_over: bool = false
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		var lift_down: bool = (_at(_lift, _lift.point_b) and _at(_second, _second.point_a)
				and _second.has_rider())
		if lift_down and not lift_was_down:
			lift_meetings += 1
		lift_was_down = lift_down
		var ferry_over: bool = _at(_ferry, _ferry.point_b) and _at(_lift, _lift.point_a)
		if ferry_over and not ferry_was_over:
			ferry_meetings += 1
		ferry_was_over = ferry_over
	return report(lift_meetings >= MIN_MEETINGS and ferry_meetings >= MIN_MEETINGS,
			"Staying on Second for %d s: Lift came down beside it %d times and Ferry met Lift %d times, expected at least %d each"
			% [WATCH_FRAMES / 60, lift_meetings, ferry_meetings, MIN_MEETINGS])


func _at(platform: CyclePlatform, point: Marker2D) -> bool:
	return platform.global_position.distance_to(point.global_position) <= REST_TOLERANCE


## Walks from the walkway into the chimney, climbs it like any chimney until the feet are above the
## ledge, then holds left to land on it.
func _chimney_by_the_right_wall_leads_onto_the_rock_ledge() -> bool:
	_stand_in.run_direction = 0.0
	_teleport(WALKWAY + Vector2(0.0, -2.0))
	await wait_until_on_floor(_player)
	_stand_in.run_direction = 1.0
	var walked_in: bool = await wait_until(func() -> bool:
		return _player.global_position.x >= CHIMNEY_FLOOR_X)
	var climbed: bool = await _chimney_can_be_climbed("chimney up to the rock ledge",
			_player.global_position / TILE, LEDGE_TOP / TILE - 0.5)
	_stand_in.run_direction = -1.0
	_stand_in.hold_jump = false
	await wait_until(func() -> bool: return _player.is_on_floor())
	_stand_in.run_direction = 0.0
	var at: Vector2 = _player.global_position
	return report(walked_in and climbed and absf(at.y - LEDGE_TOP) <= 1.0 and at.x < LEDGE_END,
			"From the walkway into the chimney and up: walked in %s, climbed %s, landed at (%.0f, %.0f); the rock ledge's top is at y %.0f, left of x %.0f"
			% [walked_in, climbed, at.x, at.y, LEDGE_TOP, LEDGE_END])


## A climber who jumps whenever it touches a wall and keeps flying the way it goes, from the bottom
## of the chimney until its feet reach the top.
func _chimney_can_be_climbed(chimney: String, bottom: Vector2, top: float) -> bool:
	_teleport(Vector2(bottom.x * TILE, bottom.y * TILE - 2.0))
	await wait_until_on_floor(_player)
	_stand_in.run_direction = -1.0
	_stand_in.hold_jump = true
	_stand_in.press_jump()
	var highest: float = _player.global_position.y
	for _frame: int in CLIMB_FRAMES:
		await physics_frame
		if _player.is_on_wall():
			_stand_in.press_jump()
		if absf(_player.velocity.x) > 1.0:
			_stand_in.run_direction = signf(_player.velocity.x)
		highest = minf(highest, _player.global_position.y)
		if highest <= top * TILE:
			break
	_stand_in.run_direction = 0.0
	_stand_in.hold_jump = false
	return report(highest <= top * TILE, "Climbing the %s: feet reached tile %.1f, the top is %.0f"
			% [chimney, highest / TILE, top])


## Waits for First to be back at its rest, stands on it and waits for it to set off. Returns when
## First meets Second in the middle, or -1 if it never sets off.
func _board_first() -> float:
	await wait_until(func() -> bool: return not _cycle.is_first_out(), MAX_FRAMES * 3)
	if not await _stand_on(_first):
		return -1.0
	await wait_until(func() -> bool: return _cycle.is_first_out())
	return _cycle.get_first_meeting()


## Puts the player just above platform and waits until the crossing has noticed it there.
func _stand_on(platform: CyclePlatform) -> bool:
	_stand_in.run_direction = 0.0
	_teleport(platform.global_position + Vector2(0.0, -PLATFORM_HALF_HEIGHT - 2.0))
	return await wait_until(func() -> bool: return platform.has_rider() and _player.is_on_floor())


## Jumps towards platform, holding the direction until DRIFT before its middle, and waits for the
## landing. True if the player ends up standing on it.
func _jump_onto(platform: CyclePlatform) -> bool:
	var direction: float = signf(platform.global_position.x - _player.global_position.x)
	_stand_in.run_direction = direction
	_stand_in.hold_jump = true
	_stand_in.press_jump()
	await wait_until(func() -> bool:
		return direction * (platform.global_position.x - _player.global_position.x) <= DRIFT)
	_stand_in.run_direction = 0.0
	await wait_frames(PRESS_DELAY_FRAMES)
	await wait_until(func() -> bool: return _player.is_on_floor())
	_stand_in.hold_jump = false
	# An Area2D sees a body that came in only after the next physics step.
	await wait_frames(SENSOR_FRAMES)
	return platform.has_rider()


func _jump_onto_the_first_step() -> bool:
	_stand_in.run_direction = 1.0
	_stand_in.hold_jump = true
	_stand_in.press_jump()
	var middle: float = (FIRST_STEP_LEFT + FIRST_STEP_RIGHT) / 2.0
	await wait_until(func() -> bool: return _player.global_position.x >= middle - DRIFT)
	_stand_in.run_direction = 0.0
	await wait_frames(PRESS_DELAY_FRAMES)
	await wait_until(func() -> bool: return _player.is_on_floor())
	_stand_in.hold_jump = false
	return absf(_player.global_position.y - FIRST_STEP_TOP) <= 1.0


func _wait_for_time(time: float) -> bool:
	return await wait_until(func() -> bool: return _cycle.get_clock() >= time, MAX_FRAMES * 3)


func _teleport(at: Vector2) -> void:
	_player.global_position = at
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
