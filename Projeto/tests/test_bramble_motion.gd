# Checks how the brambles of lethal spikes move (#263): each one tilts from its base, which stays
# put; at rest each sways a little, on its own, held for a frame of the effects; the man stirs only
# the ones he comes at within a tile, and the stir fades in about a third of a second; on his death
# on spikes the ones near him thrash after Thrash Delay (at once in the game; a copy with a delay
# checks nothing moves before it) and lean towards him, and the far ones do not; a death by something else moves nothing; and the part that kills never
# moves.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_motion.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const MOTION_STATS: LethalSpikes.BrambleMotionStats = preload("res://scenes/objects/traps/bramble_motion_stats.tres")
const TILE: float = 48.0
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## Where the man starts, left of the strip, on the floor.
const START := Vector2(-500.0, -2.0)
## Wide enough that the far end is well beyond the thrash's reach from where he dies, at the left end.
const WIDTH_TILES: int = 9
const RUN_FRAMES: int = 120
## Frames waited after his death: past the thrash and into the lean.
const AFTER_DEATH_FRAMES: int = 75
## The delay of the thrash in the copies that check nothing moves before it: the game's is 0.
const TEST_DELAY: float = 0.1
## Where the man stands, a little left of the strip's left end, for a death by something else.
const BESIDE := Vector2(-WIDTH_TILES * TILE / 2.0 - 40.0, -2.0)
## How far apart two lengths may be and still count as the same, in px.
const SAME: float = 0.001
## The man's body, 48 x 96 px, standing at the origin.
const BODY := Rect2(-24.0, -96.0, 48.0, 96.0)
## His run, in px/s.
const RUN: float = 300.0
const FRAME: float = 1.0 / 60.0
## Frames waited before quitting, for the man's last sound to end.
const SOUND_TAIL_FRAMES: int = 30


func _initialize() -> void:
	var stats: LethalSpikes.BrambleMotionStats = MOTION_STATS
	var motion := LethalSpikes.BrambleMotion.new(stats) as LethalSpikes.BrambleMotion
	var results: Array[bool] = []
	results.append(_the_base_stays_and_the_top_moves())
	results.append(_at_rest_each_sways_a_little_on_its_own(motion, stats))
	results.append(_it_holds_each_drawing_for_a_frame_of_the_effects(motion, stats))
	results.append(_a_clock_summed_at_60_fps_changes_drawing_evenly(motion, stats))
	results.append(_he_stirs_only_those_he_comes_at_within_a_tile(motion, stats))
	results.append(_the_stir_rises_at_once_and_fades_in_a_third_of_a_second(motion))
	results.append(_on_his_death_the_near_ones_thrash_after_the_delay_and_lean_in(motion, stats))
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	await physics_frame
	results.append(_a_strip_s_brambles_each_sway_on_their_own(stats))
	results.append(await _a_death_on_them_moves_the_near_ones_and_not_the_far_ones())
	results.append(await _a_death_by_something_else_moves_nothing())
	# A footstep of the last man still playing when the run quits is reported as a leak.
	await wait_frames(SOUND_TAIL_FRAMES)
	finish(results)


func _the_base_stays_and_the_top_moves() -> bool:
	var middle := Vector2(10.0, 0.0)
	var height: float = 40.0
	var wrong: Array[String] = []
	for mirrored: bool in [false, true]:
		var still: Transform2D = LethalSpikes.BrambleMotion.tilt(middle, height, mirrored, 0.0)
		var tilted: Transform2D = LethalSpikes.BrambleMotion.tilt(middle, height, mirrored, 3.0)
		for corner: Vector2 in [Vector2(-20.0, 0.0), Vector2(20.0, 0.0)]:
			if (tilted * corner).distance_to(still * corner) > SAME:
				wrong.append("base %s moved, mirrored %s" % [corner, mirrored])
		for corner: Vector2 in [Vector2(-20.0, -height), Vector2(20.0, -height)]:
			var shift: Vector2 = tilted * corner - still * corner
			if shift.distance_to(Vector2(3.0, 0.0)) > SAME:
				wrong.append("top %s moved by %s, mirrored %s" % [corner, shift, mirrored])
	return report(wrong.is_empty(), "A tilt of 3 px: %s" % ("base still, top 3 px over" if wrong.is_empty() else str(wrong)))


func _at_rest_each_sways_a_little_on_its_own(motion: LethalSpikes.BrambleMotion, stats: LethalSpikes.BrambleMotionStats) -> bool:
	var amplitude: float = stats.sway_amplitude
	var lowest: Array[float] = [INF, INF]
	var highest: Array[float] = [-INF, -INF]
	var apart: float = 0.0
	var time: float = 0.0
	while time < 2.0 * stats.sway_period_max:
		var one: float = motion.sway(time, stats.sway_period_min, 0.0)
		var other: float = motion.sway(time, stats.sway_period_max, 0.37)
		for k: int in 2:
			var value: float = one if k == 0 else other
			lowest[k] = minf(lowest[k], value)
			highest[k] = maxf(highest[k], value)
		apart = maxf(apart, absf(one - other))
		time += FRAME
	var within: bool = highest.max() <= amplitude + SAME and lowest.min() >= -amplitude - SAME
	var moves: bool = highest[0] - lowest[0] >= amplitude and highest[1] - lowest[1] >= amplitude
	return report(amplitude > 0.0 and within and moves and apart >= amplitude,
			"Sway up to %.1f px: from %.2f to %.2f px, each over %.2f and %.2f px, %.2f px apart at most"
			% [amplitude, lowest.min(), highest.max(), highest[0] - lowest[0], highest[1] - lowest[1], apart])


func _it_holds_each_drawing_for_a_frame_of_the_effects(motion: LethalSpikes.BrambleMotion, stats: LethalSpikes.BrambleMotionStats) -> bool:
	var frame: float = 1.0 / stats.frame_rate
	var start: float = 10.0 * frame
	var at_start: float = motion.sway(start + 0.001, stats.sway_period_min, 0.0)
	var late: float = motion.sway(start + frame - 0.001, stats.sway_period_min, 0.0)
	var next: float = motion.sway(start + frame + 0.001, stats.sway_period_min, 0.0)
	return report(absf(at_start - late) < SAME and absf(next - late) > SAME,
			"Within a frame of %.3f s: %.4f then %.4f; the next frame %.4f" % [frame, at_start, late, next])


func _he_stirs_only_those_he_comes_at_within_a_tile(motion: LethalSpikes.BrambleMotion, stats: LethalSpikes.BrambleMotionStats) -> bool:
	var near := Vector2(BODY.end.x + 16.0, -40.0)
	var far := Vector2(BODY.end.x + stats.stir_radius + 16.0, -40.0)
	var level_with_him := Vector2(BODY.end.x + 16.0, BODY.get_center().y)
	var coming: float = motion.stir_target(near, BODY, Vector2(RUN, 0.0))
	var too_far: float = motion.stir_target(far, BODY, Vector2(RUN, 0.0))
	var going: float = motion.stir_target(near, BODY, Vector2(-RUN, 0.0))
	var still: float = motion.stir_target(near, BODY, Vector2.ZERO)
	var sliding_past: float = motion.stir_target(level_with_him, BODY, Vector2(0.0, RUN))
	return report(coming > 0.0 and too_far == 0.0 and going == 0.0 and still == 0.0 and sliding_past == 0.0,
			"Stir coming at it %.2f, a tile and more away %.2f, going away %.2f, still %.2f, sliding past %.2f"
			% [coming, too_far, going, still, sliding_past])


func _the_stir_rises_at_once_and_fades_in_a_third_of_a_second(motion: LethalSpikes.BrambleMotion) -> bool:
	var risen: float = motion.stir_after(0.0, 0.6, FRAME)
	var stir: float = 1.0
	var after_a_tenth: float = 0.0
	var time: float = 0.0
	while time < 0.35 - SAME:
		stir = motion.stir_after(stir, 0.0, FRAME)
		time += FRAME
		if absf(time - 0.1) < FRAME / 2.0:
			after_a_tenth = stir
	return report(absf(risen - 0.6) < SAME and after_a_tenth > 0.2 and stir < 0.05,
			"Stir rises to %.2f at once; with him gone, %.2f after 0.1 s and %.3f after 0.35 s"
			% [risen, after_a_tenth, stir])


## A clock summed from 60 fps deltas, as the strips keep it, lands a hair under a frame's start now
## and then: each drawing is still held for the same number of frames, never one fewer or more.
func _a_clock_summed_at_60_fps_changes_drawing_evenly(motion: LethalSpikes.BrambleMotion, stats: LethalSpikes.BrambleMotionStats) -> bool:
	var per_drawing: int = roundi(60.0 / stats.frame_rate)
	var clock: float = 0.0
	var last: int = motion.frame_of(clock)
	var held_for: int = 0
	var uneven: int = 0
	for frame: int in 600:
		clock += FRAME
		held_for += 1
		var now: int = motion.frame_of(clock)
		if now != last:
			if held_for != per_drawing:
				uneven += 1
			held_for = 0
			last = now
	return report(uneven == 0, "Summed clock: drawings not held %d frames: %d of %d"
			% [per_drawing, uneven, 600 / per_drawing])


func _on_his_death_the_near_ones_thrash_after_the_delay_and_lean_in(motion: LethalSpikes.BrambleMotion, stats: LethalSpikes.BrambleMotionStats) -> bool:
	var death := Vector2(0.0, 0.0)
	var near_left := Vector2(-30.0, 0.0)
	var near_right := Vector2(30.0, 0.0)
	var far := Vector2(stats.thrash_radius + 10.0, 0.0)
	# The game's delay is 0, at once; a copy with one checks nothing moves before it.
	var delayed := stats.duplicate() as LethalSpikes.BrambleMotionStats
	delayed.thrash_delay = TEST_DELAY
	var delayed_motion := LethalSpikes.BrambleMotion.new(delayed) as LethalSpikes.BrambleMotion
	var too_soon: float = absf(delayed_motion.thrash(near_left, death, TEST_DELAY - 0.02, 0)) \
			+ absf(delayed_motion.lean(near_left, death, TEST_DELAY - 0.02))
	var effects_frame: float = 1.0 / stats.frame_rate
	var by_the_first_frame: float = absf(motion.thrash(near_left, death,
			stats.thrash_delay + stats.thrash_spread + effects_frame, 0))
	var largest: float = 0.0
	var far_largest: float = 0.0
	var time: float = 0.0
	while time < 1.0:
		largest = maxf(largest, absf(motion.thrash(near_left, death, time, 0)))
		far_largest = maxf(far_largest, absf(motion.thrash(far, death, time, 1)) + absf(motion.lean(far, death, time)))
		time += FRAME
	var settled: float = absf(motion.thrash(near_left, death, 1.2, 0))
	var lean_left: float = motion.lean(near_left, death, 1.0)
	var lean_right: float = motion.lean(near_right, death, 1.0)
	return report(too_soon == 0.0 and by_the_first_frame > 0.0 and largest >= stats.thrash_amplitude / 3.0
			and far_largest == 0.0 and settled < 0.05 * stats.thrash_amplitude and lean_left > 0.0
			and lean_right < 0.0,
			"With a delay of %.2f s, before it: %.2f px; with the game's, by the first frame of the effects %.2f px; thrash up to %.2f px, beyond its reach %.2f px, after 1.2 s %.3f px; lean of the one left of him %+.2f px, right %+.2f px"
			% [TEST_DELAY, too_soon, by_the_first_frame, largest, far_largest, settled, lean_left,
			lean_right])


func _a_strip_s_brambles_each_sway_on_their_own(stats: LethalSpikes.BrambleMotionStats) -> bool:
	var spikes: LethalSpikes = _strip(stats)
	var brambles: Array[LethalSpikes.Bramble] = spikes.get_drawn_brambles()
	var out_of_range: Array[String] = []
	var in_step: int = 0
	for k: int in brambles.size():
		var period: float = brambles[k].sway_period
		if period < stats.sway_period_min - SAME or period > stats.sway_period_max + SAME:
			out_of_range.append("%.2f" % period)
		if k > 0 and absf(brambles[k].sway_start - brambles[k - 1].sway_start) < 0.02 \
				and absf(period - brambles[k - 1].sway_period) < 0.02:
			in_step += 1
	var count: int = brambles.size()
	var expected: int = roundi(WIDTH_TILES * spikes.brambles_per_tile)
	spikes.free()
	return report(count == expected and out_of_range.is_empty() and in_step == 0,
			"%d brambles; periods off %.1f to %.1f s: %s; neighbours in step: %d"
			% [count, stats.sway_period_min, stats.sway_period_max, out_of_range, in_step])


func _a_death_on_them_moves_the_near_ones_and_not_the_far_ones() -> bool:
	var stats: LethalSpikes.BrambleMotionStats = _still_stats()
	stats.thrash_delay = TEST_DELAY
	var spikes: LethalSpikes = _strip(stats)
	var shape: CollisionShape2D = spikes.get_node(^"%Shape") as CollisionShape2D
	var killing_part := Rect2(shape.position, (shape.shape as RectangleShape2D).size)
	var player: Player = await spawn_on_floor(START)
	if player == null:
		spikes.free()
		return report(false, "Death on them: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var died: bool = await wait_until(player.is_dead, RUN_FRAMES)
	stand_in.run_direction = 0.0
	var brambles: Array[LethalSpikes.Bramble] = spikes.get_drawn_brambles()
	var near: LethalSpikes.Bramble = brambles[0]
	var far: LethalSpikes.Bramble = brambles[-1]
	var too_soon: float = 0.0
	var near_largest: float = 0.0
	var far_largest: float = 0.0
	var frames_to_the_thrash: int = ceili(stats.thrash_delay * 60.0) - 2
	for frame: int in AFTER_DEATH_FRAMES:
		await process_frame
		if frame < frames_to_the_thrash:
			too_soon = maxf(too_soon, absf(near.offset))
		near_largest = maxf(near_largest, absf(near.offset))
		far_largest = maxf(far_largest, absf(far.offset))
	var near_lean: float = near.offset
	var still_part := Rect2(shape.position, (shape.shape as RectangleShape2D).size)
	await remove_player(player)
	spikes.free()
	return report(died and too_soon == 0.0 and near_largest > 0.0 and far_largest == 0.0 and near_lean < 0.0
			and still_part == killing_part,
			"Died %s; with a delay of %.2f s, nearest bramble before it %.2f px, then up to %.2f px, at the end %+.2f px (towards him is -); farthest up to %.2f px; the part that kills %s"
			% [died, TEST_DELAY, too_soon, near_largest, near_lean, far_largest,
			"still" if still_part == killing_part else "moved"])


func _a_death_by_something_else_moves_nothing() -> bool:
	var stats: LethalSpikes.BrambleMotionStats = _still_stats()
	var spikes: LethalSpikes = _strip(stats)
	var player: Player = await spawn_on_floor(BESIDE)
	if player == null:
		spikes.free()
		return report(false, "Other death: the player never landed")
	await wait_frames(5)
	player.die(&"dog")
	var largest: float = 0.0
	for frame: int in AFTER_DEATH_FRAMES:
		await process_frame
		for bramble: LethalSpikes.Bramble in spikes.get_drawn_brambles():
			largest = maxf(largest, absf(bramble.offset))
	await remove_player(player)
	spikes.free()
	return report(largest == 0.0, "A death by a dog beside them: brambles moved up to %.2f px" % largest)


## A strip of Width Tiles at the origin, on the floor, moving by Stats.
func _strip(stats: LethalSpikes.BrambleMotionStats) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.width_tiles = WIDTH_TILES
	spikes.motion_stats = stats
	root.add_child(spikes)
	return spikes


## The motion with no sway and no stir, so what moves a bramble is his death alone.
func _still_stats() -> Resource:
	var stats := MOTION_STATS.duplicate() as LethalSpikes.BrambleMotionStats
	stats.sway_amplitude = 0.0
	stats.stir_amplitude = 0.0
	return stats
