# Checks the dark of a restart (#263). At the man's death the level waits Restart Delay; over the
# last Close Time of the wait the screen fades to dark, all dark for the last frame of the effects,
# so the swap to the new copy happens on black, and the new copy fades in over Open Time; a level
# that is not a restart shows none. With Iris on, a dark iris closes on his body instead, held to the
# frames of the effects, and the new copy opens it on him. A fresh press of Jump after Skip After
# cuts the wait to the close; one before it does nothing. Paused, the dark holds. The values are in
# the level's Iris Stats.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_death_iris.gd
extends "res://tests/support/menu_test.gd"

const DeathIrisPlan := preload("res://scenes/levels/death_iris_plan.gd")
const DeathIrisStats := preload("res://scenes/levels/death_iris_stats.gd")
## The game's values, which the levels take: the iris cases turn Iris on in them, and back off.
const GAME_IRIS_STATS: DeathIrisStats = preload("res://scenes/levels/death_iris_stats.tres")
const TEST_ROOM_PATH: String = "res://scenes/levels/test_room/test_room.tscn"
const SCREEN := Vector2(1920.0, 1080.0)
## Physics frames on either side of the end of the wait, as in test_level_restart.
const SETTLE_FRAMES: int = 3
## A press of Jump this many physics frames after the death comes before Skip After.
const EARLY_PRESS_FRAMES: int = 6
## How far the iris's centre may be from the man, as a share of its radius. It is placed in the
## frame's process, on the camera as the last physics frame left it, so a moving camera can lead it
## by one physics frame (23 px at the new man's drop in the test room, on a radius of hundreds of
## px): a share of the radius the eye does not see. A closed iris has no centre to see.
const OFF_SHARE: float = 0.1


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_the_plan_fades_smoothly_to_dark_and_back())
	results.append(_the_plan_closes_and_opens_in_held_steps())
	results.append(await _the_screen_fades_out_then_the_new_copy_fades_in())
	var game_stats: DeathIrisStats = GAME_IRIS_STATS
	game_stats.iris = true
	results.append(await _the_iris_closes_on_his_body_at_the_end_of_the_wait())
	results.append(await _the_new_copy_opens_on_him())
	game_stats.iris = false
	results.append(await _a_fresh_jump_after_skip_after_cuts_the_wait())
	results.append(await _paused_in_the_close_the_dark_holds())
	results.append(await _through_main_the_new_copy_opens_too())
	results.append(await _a_long_first_frame_does_not_skip_the_fade_in())
	results.append(await _a_death_in_the_fade_in_never_jumps())
	results.append(await _a_skipped_death_in_the_fade_in_never_jumps())
	finish(results)


## Fading out, darkness starts at 0, never falls and is all dark for the last frame of the effects
## and not before; fading in, it starts all dark, never grows and is gone at Open Time.
func _the_plan_fades_smoothly_to_dark_and_back() -> bool:
	var stats: DeathIrisStats = DeathIrisStats.new()
	var plan: DeathIrisPlan = DeathIrisPlan.new(stats)
	var close: float = stats.close_time
	var step: float = 1.0 / stats.frame_rate
	var starts_clear: bool = plan.fading_out(0.0, close) == 0.0
	var never_falls: bool = true
	var last: float = 0.0
	for frame: int in roundi(close * 60.0) + 1:
		var darkness: float = plan.fading_out(frame / 60.0, close)
		never_falls = never_falls and darkness >= last
		last = darkness
	var dark_at_the_end: bool = plan.fading_out(close - step + 0.001, close) == 1.0
	var not_dark_before: bool = plan.fading_out(close - step - 0.02, close) < 1.0
	var starts_dark: bool = plan.fading_in(0.0) == 1.0
	var never_grows: bool = true
	last = 1.0
	for frame: int in roundi(stats.open_time * 60.0) + 1:
		var darkness: float = plan.fading_in(frame / 60.0)
		never_grows = never_grows and darkness <= last
		last = darkness
	var gone: bool = plan.fading_in(stats.open_time) == 0.0
	return report(starts_clear and never_falls and dark_at_the_end and not_dark_before and starts_dark
			and never_grows and gone,
			("Fade plan: out from clear %s, never lighter %s, dark for the last frame %s and not before "
			+ "%s; in from dark %s, never darker %s, gone at Open Time %s") % [starts_clear,
			never_falls, dark_at_the_end, not_dark_before, starts_dark, never_grows, gone])


## The test room on its own, as by default: no dark until the close; in it, the screen never gets
## lighter and the last frame of the old copy is all dark; the new copy starts all dark, never gets
## darker and is clear after Open Time.
func _the_screen_fades_out_then_the_new_copy_fades_in() -> bool:
	var level: Level = await _test_room_on_its_own()
	var delay_frames: int = _frames_of(level.restart_delay)
	var close_frames: int = _frames_of(level.iris_stats.close_time)
	_die(level.player)
	var hidden_before: bool = true
	for frame: int in delay_frames - close_frames - 1:
		await process_frame
		hidden_before = hidden_before and not level.get_iris().is_drawn()
	var darkening: bool = true
	var last: float = 0.0
	var drawn_frames: int = 0
	# Its steepest step, up to the black, against the curve's own (see the death in the fade in).
	var biggest: float = 0.0
	var stats: DeathIrisStats = level.iris_stats
	var most_step: float = (stats.fade_ease / (Engine.physics_ticks_per_second
			* (stats.close_time - 1.0 / stats.frame_rate)) + 0.01)
	while current_scene == level and drawn_frames < 2 * close_frames:
		var iris: Node = level.get_iris()
		if iris.is_drawn():
			drawn_frames += 1
			darkening = darkening and iris.get_darkness() >= last
			biggest = maxf(biggest, iris.get_darkness() - last)
			last = iris.get_darkness()
		await process_frame
	var dark: bool = last == 1.0
	darkening = darkening and biggest <= most_step
	var new_level: Level = null
	for frame: int in 2 * SETTLE_FRAMES:
		if current_scene is Level and current_scene != level:
			new_level = current_scene as Level
			break
		await physics_frame
	if new_level == null:
		await _leave(current_scene)
		return report(false, "Fade: no new copy after the wait")
	var dark_at_first: bool = new_level.get_iris().is_drawn() and new_level.get_iris().get_darkness() == 1.0
	var lightening: bool = true
	last = 1.0
	for frame: int in _frames_of(new_level.iris_stats.open_time) - 1:
		await process_frame
		var iris: Node = new_level.get_iris()
		if not iris.is_drawn():
			break
		lightening = lightening and iris.get_darkness() <= last
		last = iris.get_darkness()
	await wait_frames(SETTLE_FRAMES)
	var gone: bool = not new_level.get_iris().is_drawn()
	await _leave(new_level)
	return report(hidden_before and drawn_frames > 0 and darkening and dark and dark_at_first
			and lightening and gone,
			("Fade: none before %s; out over %d frames, never lighter and its steepest step %.2f "
			+ "(at most %.2f) %s, the last frame dark %s; the new copy dark at first %s, never darker "
			+ "%s, clear after Open Time %s") % [hidden_before, drawn_frames, biggest, most_step,
			darkening, dark, dark_at_first, lightening, gone])


## Closing, the radius starts full, never grows, holds within a frame of the effects and is 0 for
## the last frame of them; opening, it starts at 0, never shrinks and ends full. The full radius
## reaches past the farthest corner of the screen by the wobble, so no ink is left in a corner.
func _the_plan_closes_and_opens_in_held_steps() -> bool:
	var stats: DeathIrisStats = DeathIrisStats.new()
	var plan: DeathIrisPlan = DeathIrisPlan.new(stats)
	var full: float = 1000.0
	var close: float = stats.close_time
	var step: float = 1.0 / stats.frame_rate
	var starts_full: bool = is_equal_approx(plan.closing(0.0, close, full), full)
	var never_grows: bool = true
	var last: float = full
	for frame: int in roundi(close * 60.0) + 1:
		var radius: float = plan.closing(frame / 60.0, close, full)
		never_grows = never_grows and radius <= last
		last = radius
	var held: bool = is_equal_approx(plan.closing(step * 1.2, close, full),
			plan.closing(step * 1.8, close, full))
	var dark_at_the_end: bool = plan.closing(close - step + 0.001, close, full) == 0.0
	var not_dark_before: bool = plan.closing(close - step - 0.001, close, full) > 0.0
	var opens_from_dark: bool = plan.opening(0.0, full) == 0.0
	var opens_full: bool = is_equal_approx(plan.opening(stats.open_time, full), full)
	var never_shrinks: bool = true
	last = 0.0
	for frame: int in roundi(stats.open_time * 60.0) + 1:
		var radius: float = plan.opening(frame / 60.0, full)
		never_shrinks = never_shrinks and radius >= last
		last = radius
	var corner: float = Vector2(100.0, 100.0).distance_to(SCREEN)
	var reaches: bool = plan.full_radius(Vector2(100.0, 100.0), SCREEN) >= corner + stats.wobble_px
	return report(starts_full and never_grows and held and dark_at_the_end and not_dark_before
			and opens_from_dark and opens_full and never_shrinks and reaches,
			("Plan: closing starts full %s, never grows %s, held %s, dark for the last frame %s and "
			+ "not before %s; opening from dark %s, ends full %s, never shrinks %s; full radius "
			+ "past the corner %s") % [starts_full, never_grows, held, dark_at_the_end,
			not_dark_before, opens_from_dark, opens_full, never_shrinks, reaches])


## The test room on its own: no iris until the close; in it, the radius never grows, around his
## body where he died, through the camera as it is; and the last frame of the old copy is dark.
func _the_iris_closes_on_his_body_at_the_end_of_the_wait() -> bool:
	var level: Level = await _test_room_on_its_own()
	var player: Player = level.player
	var body: Node2D = player.get_node(^"CollisionShape2D") as Node2D
	var died_at: Vector2 = body.global_position
	var delay_frames: int = _frames_of(level.restart_delay)
	var close_frames: int = _frames_of(level.iris_stats.close_time)
	_die(player)
	var hidden_before: bool = true
	for frame: int in delay_frames - close_frames - 1:
		await process_frame
		hidden_before = hidden_before and not level.get_iris().is_drawn()
	var closing: bool = true
	var off_him: float = 0.0
	var last: float = INF
	var drawn_frames: int = 0
	while current_scene == level and drawn_frames < 2 * close_frames:
		var iris: Node = level.get_iris()
		if iris.is_drawn():
			drawn_frames += 1
			closing = closing and iris.get_radius() <= last
			last = iris.get_radius()
			if last > 0.0:
				off_him = maxf(off_him, iris.get_centre().distance_to(
						level.get_canvas_transform() * died_at) / last)
		await process_frame
	var dark: bool = last == 0.0
	await _leave(current_scene)
	return report(hidden_before and drawn_frames > 0 and closing and off_him <= OFF_SHARE and dark,
			("Close: hidden before %s; drawn %d frames, never grows %s, at most %.3f of its radius "
			+ "off his body; the last frame dark %s") % [hidden_before, drawn_frames, closing,
			off_him, dark])


## After the swap, the new copy shows the iris dark at first and opening, around the new man, and
## none once Open Time is over; a copy that is not a restart shows none.
func _the_new_copy_opens_on_him() -> bool:
	var first: Level = await _test_room_on_its_own()
	var fresh_none: bool = not first.get_iris().is_drawn()
	var delay_frames: int = _frames_of(first.restart_delay)
	_die(first.player)
	await wait_frames(delay_frames)
	var level: Level = null
	for frame: int in 2 * SETTLE_FRAMES:
		if current_scene is Level and current_scene != first:
			level = current_scene as Level
			break
		await physics_frame
	if level == null:
		await _leave(current_scene)
		return report(false, "Open: no new copy after the wait")
	var dark_at_first: bool = level.get_iris().is_drawn() and level.get_iris().get_radius() <= 0.0
	var opening: bool = true
	var off_him: float = 0.0
	var last: float = -1.0
	var open_frames: int = _frames_of(level.iris_stats.open_time)
	var body: Node2D = level.player.get_node(^"CollisionShape2D") as Node2D
	for frame: int in open_frames - 1:
		await process_frame
		var iris: Node = level.get_iris()
		if not iris.is_drawn():
			break
		opening = opening and iris.get_radius() >= last
		last = iris.get_radius()
		if last > 0.0:
			off_him = maxf(off_him, iris.get_centre().distance_to(
					level.get_canvas_transform() * body.global_position) / last)
	await wait_frames(SETTLE_FRAMES)
	var gone: bool = not level.get_iris().is_drawn()
	await _leave(level)
	return report(fresh_none and dark_at_first and opening and off_him <= OFF_SHARE and gone,
			("Open: a fresh copy shows none %s; the new copy dark at first %s, opening %s, at most "
			+ "%.3f of its radius off him, gone after Open Time %s") % [fresh_none, dark_at_first,
			opening, off_him, gone])


## A press of Jump EARLY_PRESS_FRAMES after the death leaves the wait whole; a fresh press once Skip
## After is over brings the swap Close Time later, before the wait would have ended.
func _a_fresh_jump_after_skip_after_cuts_the_wait() -> bool:
	var level: Level = await _test_room_on_its_own()
	var stand_in: StandInInput = put_a_stand_in(level.player)
	var skip_frames: int = _frames_of(level.skip_after) + 1
	var close_frames: int = _frames_of(level.iris_stats.close_time)
	var delay_frames: int = _frames_of(level.restart_delay)
	_die(level.player)
	await wait_frames(EARLY_PRESS_FRAMES)
	stand_in.press_jump()
	await wait_frames(skip_frames - EARLY_PRESS_FRAMES)
	var early_ignored: bool = current_scene == level
	if early_ignored:
		stand_in.press_jump()
	await wait_frames(close_frames - SETTLE_FRAMES)
	var kept: bool = current_scene == level
	await wait_frames(2 * SETTLE_FRAMES)
	var swapped: bool = current_scene is Level and current_scene != level
	var sooner: bool = skip_frames + close_frames + SETTLE_FRAMES < delay_frames
	await _leave(current_scene)
	return report(early_ignored and kept and swapped and sooner,
			("Skip: an early press ignored %s; after a fresh press at %d frames, the same level %d "
			+ "frames before the close ends %s and a new copy after %s, sooner than the wait %s")
			% [early_ignored, skip_frames, SETTLE_FRAMES, kept, swapped, sooner])


## Paused in the middle of the fade out for longer than the rest of the wait: the darkness and the
## level stay as they were.
func _paused_in_the_close_the_dark_holds() -> bool:
	var level: Level = await _test_room_on_its_own()
	var delay_frames: int = _frames_of(level.restart_delay)
	var close_frames: int = _frames_of(level.iris_stats.close_time)
	_die(level.player)
	await wait_frames(delay_frames - close_frames / 2)
	var before: float = level.get_iris().get_darkness()
	paused = true
	await wait_frames(2 * close_frames)
	var held: bool = (current_scene == level and level.get_iris().is_drawn()
			and level.get_iris().get_darkness() == before)
	paused = false
	await wait_frames(close_frames)
	await _leave(current_scene)
	return report(held and before > 0.0 and before < 1.0,
			"Paused in the fade: darkness %.2f held %s" % [before, held])


## Through Main, as in the game: the first level started shows no iris; after a death, the copy Main
## puts in the slot opens it.
func _through_main_the_new_copy_opens_too() -> bool:
	var main: Node = await new_main_in_a_level()
	var level: Level = level_in(main) as Level
	var player: Player = await player_on_the_floor(main)
	if level == null or player == null:
		await remove_main(main)
		return report(false, "Main: no Level with a man on the floor in the slot")
	var first_none: bool = not level.get_iris().is_drawn()
	_die(player)
	await wait_frames(_frames_of(level.restart_delay) + 1)
	var new_level: Level = level_in(main) as Level
	var opening: bool = (new_level != null and new_level != level
			and new_level.get_iris().is_drawn())
	await remove_main(main)
	return report(first_none and opening,
			"Main: the first level shows none %s; the new copy opens the iris %s" % [first_none,
			opening])


## A new copy's first frames can be long (level 1 takes about 0.4 s to draw its first one): a frame
## longer than Open Time still leaves the fade in to be seen, not cut to clear.
func _a_long_first_frame_does_not_skip_the_fade_in() -> bool:
	var level: Level = await _a_new_copy()
	if level == null:
		return report(false, "Long frame: no new copy after the wait")
	var long_frame: float = level.iris_stats.open_time + 0.1
	level._process(long_frame)
	var iris: Node = level.get_iris()
	var still_dark: bool = iris.is_drawn() and iris.get_darkness() > 0.0
	var darkness: float = iris.get_darkness() if iris.is_drawn() else 0.0
	await _leave(level)
	return report(still_dark, "Long frame: after a frame of %.2f s the fade in still shows %s, darkness %.2f"
			% [long_frame, still_dark, darkness])


## Dying while the new copy fades in, the screen goes on lightening and then darkens for the wait,
## with no jump between two frames bigger than the fades' own steepest one. A fade of T s eased to
## the power Fade Ease climbs at most Fade Ease times its average, at its firm end, so a frame moves
## it by at most Fade Ease / (frames a second * T); Step Margin covers the clock's rounding. A fixed
## bound would fail each time the fades were tuned faster, though nothing jumped. A bound of Most
## Step Cap or more is a cut, not a fade, so it fails too: a fade tuned that fast would pass
## whatever it did.
func _a_death_in_the_fade_in_never_jumps() -> bool:
	const STEP_MARGIN: float = 0.01
	const MOST_STEP_CAP: float = 0.5
	var level: Level = await _a_new_copy()
	if level == null:
		return report(false, "Death in the fade in: no new copy after the wait")
	var stats: DeathIrisStats = level.iris_stats
	var darkening: float = stats.close_time - 1.0 / stats.frame_rate
	var shortest: float = maxf(minf(darkening, stats.open_time), 1.0 / Engine.physics_ticks_per_second)
	var most_step: float = (stats.fade_ease / (Engine.physics_ticks_per_second * shortest)
			+ STEP_MARGIN)
	await wait_frames(SETTLE_FRAMES)
	var at_death: float = level.get_iris().get_darkness()
	_die(level.player)
	var last: float = at_death
	var biggest: float = 0.0
	for frame: int in _frames_of(level.restart_delay) - SETTLE_FRAMES:
		await process_frame
		var iris: Node = level.get_iris()
		var darkness: float = iris.get_darkness() if iris.is_drawn() else 0.0
		biggest = maxf(biggest, absf(darkness - last))
		last = darkness
	await _leave(current_scene)
	return report(at_death > 0.0 and biggest <= most_step and most_step < MOST_STEP_CAP,
			"Death in the fade in: darkness %.2f at the death; the biggest jump between frames %.2f (at most %.2f)"
			% [at_death, biggest, most_step])


## Dying as the new copy appears and skipping the wait as soon as Skip After allows, the close
## begins while the screen still lightens: it darkens on from where it is, with no step bigger than
## the fade's own, never back to clear first.
func _a_skipped_death_in_the_fade_in_never_jumps() -> bool:
	var level: Level = await _a_new_copy()
	if level == null:
		return report(false, "Skipped death in the fade in: no new copy after the wait")
	var stats: DeathIrisStats = level.iris_stats
	var shortest: float = minf(stats.close_time - 1.0 / stats.frame_rate, stats.open_time)
	var most_step: float = stats.fade_ease / (Engine.physics_ticks_per_second * shortest) + 0.01
	var stand_in: StandInInput = put_a_stand_in(level.player)
	var last: float = level.get_iris().get_darkness()
	_die(level.player)
	var biggest: float = 0.0
	var skip_frames: int = _frames_of(level.skip_after) + 1
	var skipped: bool = false
	# Physics frames: a press counts as fresh only in the physics frame it is made in.
	for frame: int in skip_frames + _frames_of(stats.close_time) + 2 * SETTLE_FRAMES:
		await physics_frame
		if frame == skip_frames:
			stand_in.press_jump()
		if current_scene != level:
			skipped = true
			break
		var iris: Node = level.get_iris()
		var darkness: float = iris.get_darkness() if iris.is_drawn() else 0.0
		biggest = maxf(biggest, absf(darkness - last))
		last = darkness
	await _leave(current_scene)
	return report(skipped and biggest <= most_step,
			"Skipped death in the fade in: skipped %s; the biggest jump between frames %.2f (at most %.2f)"
			% [skipped, biggest, most_step])


## The copy that takes the test room's place after its man dies, in its first frame.
func _a_new_copy() -> Level:
	var first: Level = await _test_room_on_its_own()
	_die(first.player)
	await wait_frames(_frames_of(first.restart_delay))
	for frame: int in 2 * SETTLE_FRAMES:
		if current_scene is Level and current_scene != first:
			return current_scene as Level
		await physics_frame
	await _leave(current_scene)
	return null


## The test room as the current scene, with no Main, after its first frames, with the screen set as
## the viewport of the game.
func _test_room_on_its_own() -> Level:
	var level: Level = (load(TEST_ROOM_PATH) as PackedScene).instantiate() as Level
	root.add_child(level)
	current_scene = level
	await process_frame
	root.size = Vector2i(SCREEN)
	await wait_frames(SETTLE_FRAMES)
	return level


func _leave(level: Node) -> void:
	paused = false
	if is_instance_valid(level):
		level.queue_free()
	current_scene = null
	await wait_frames(SETTLE_FRAMES)


## The man dies as a grab that runs out of time makes him, as in test_level_restart.
func _die(player: Player) -> void:
	(player.get_node(^"GrabEscape") as GrabEscape).died.emit()


func _frames_of(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)
