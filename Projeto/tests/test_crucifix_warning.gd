# Checks the crucifix's warning that it is about to come down, which every player gets, with or
# without vibration (ADR 0062). Held up until its use runs out: its warning's progress is 0 until
# Warning Time is left, then grows to all of it, and is 0 again as it comes down; its light keeps all
# of its brightness until then and pulses after, never below what Warning Dim Depth allows, deeper as
# the end comes, the deepest as the use runs out, and no faster than Warning Pulse Rate; once it is
# down, the light is back to all of its brightness. Its hold sound wavers with the light, its volume
# following the light's share, and is back to its volume once down. The crucifix's _process() and its
# sounds' only run while it is up. Let go during the warning, the light and the sound are back at
# once, the sound to a volume set while the crucifix was down. The game's crucifix pulses three
# times a second or fewer, the most that is safe for players with photosensitive epilepsy.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_warning.gd
extends "res://tests/support/player_test.gd"

const CRUCIFIX_STATS: CrucifixStats = preload("res://scenes/characters/crucifix/crucifix_stats.tres")
## Where the player stands, above a floor at y = 0.
const START: Vector2 = Vector2(0.0, -100.0)
const FLOOR_HALF_WIDTH: float = 2000.0
## The crucifix's use time in the cases, in s: longer than its warning, so part of the use warns
## nothing.
const USE_TIME: float = 3.0
## The most times a second a light may flash and stay safe for players with photosensitive epilepsy
## (WCAG 2.2, criterion 2.3.1).
const SAFE_FLASHES: float = 3.0
## How close two numbers must be to count as the same.
const TOLERANCE: float = 0.0001
## How far the warning's progress must get by the end of a use.
const NEAR_ALL: float = 0.95
## Frames a case waits beyond the crucifix's use for it to come down, before it fails.
const MARGIN_FRAMES: int = 30
## How close the hold sound's volume must be to the light's share, in dB.
const DB_TOLERANCE: float = 0.01
## How far the let-go case turns the hold sound down before the crucifix goes up, in dB, as a
## volume set in the Remote tab while it is down.
const TUNED_DOWN_DB: float = 6.0


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_the_game_s_crucifix_pulses_at_a_safe_rate())
	results.append(await _held_up_to_the_end_its_light_warns_and_comes_back())
	results.append(await _let_go_during_the_warning_its_light_comes_back_at_once())
	finish(results)


## The crucifix's values in crucifix_stats.tres pulse its light three times a second or fewer, and
## warn for part of a use.
func _the_game_s_crucifix_pulses_at_a_safe_rate() -> bool:
	var stats: CrucifixStats = CRUCIFIX_STATS
	return report(stats.warning_pulse_rate <= SAFE_FLASHES and stats.warning_time > 0.0
			and stats.warning_time < stats.max_use_time and stats.warning_dim_depth < 1.0,
			("the light pulses %.1f times a second (%.1f at most), warns for the last %.1f s of %.1f "
			+ "and dims by %.2f at most (under 1, so it never goes out)") % [stats.warning_pulse_rate,
			SAFE_FLASHES, stats.warning_time, stats.max_use_time, stats.warning_dim_depth])


## Held up until its use runs out: its _process() is off before it goes up and once it is down; the
## warning's progress is 0 while more than Warning Time is left, grows to near all of it by the end
## and is 0 as it comes down; the light keeps all of its brightness before the warning, stays between
## 1 - Warning Dim Depth and all of it during it, dips deeper in its second half than in its first, the
## deepest on the use's last frame, and no more often than Warning Pulse Rate allows; once down, it
## has all of it back.
func _held_up_to_the_end_its_light_warns_and_comes_back() -> bool:
	var floor_body: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(START)
	if player == null:
		floor_body.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var crucifix: Crucifix = _crucifix_with_use_time(player)
	var stats: CrucifixStats = crucifix.stats
	var light: PointLight2D = crucifix.get_node(^"%Light") as PointLight2D
	var full: float = light.energy
	var sounds: CrucifixSounds = crucifix.get_node(^"CrucifixSounds") as CrucifixSounds
	var hold_db: float = sounds.hold.volume_db
	var input: StandInInput = put_a_stand_in(player)
	var progress_as_lowered: Array[float] = []
	crucifix.lowered.connect(func() -> void:
			progress_as_lowered.append(crucifix.get_warning_progress()))
	await physics_frame
	var processing_down: bool = crucifix.is_processing() or sounds.is_processing()
	input.crucifix_held = true
	var raised: bool = await wait_until(crucifix.is_raised)
	var processing_up: bool = crucifix.is_processing() and sounds.is_processing()
	var sound_off: float = 0.0
	var wrong: Array[String] = []
	var dips: Array[float] = []
	var halfway_deepest: Array[float] = [1.0, 1.0]
	var deepest: float = 1.0
	var last_share: float = 1.0
	var falling: bool = false
	var top_progress: float = 0.0
	var frames_left: int = stats.get_max_use_frames() + MARGIN_FRAMES
	while crucifix.is_raised() and frames_left > 0:
		frames_left -= 1
		await process_frame
		if not crucifix.is_raised():
			break
		var progress: float = crucifix.get_warning_progress()
		var share: float = light.energy / full
		var time_left: float = crucifix.get_use_time_left()
		top_progress = maxf(top_progress, progress)
		if time_left > stats.warning_time and (progress != 0.0 or not is_equal_approx(share, 1.0)):
			wrong.append("%.2f s left: progress %.2f, light at %.2f" % [time_left, progress, share])
		if share < 1.0 - stats.warning_dim_depth - TOLERANCE or share > 1.0 + TOLERANCE:
			wrong.append("%.2f s left: light at %.2f" % [time_left, share])
		if progress > 0.0:
			var half: int = 0 if progress < 0.5 else 1
			halfway_deepest[half] = minf(halfway_deepest[half], share)
			if share > last_share and falling:
				dips.append(last_share)
			falling = share < last_share
		deepest = minf(deepest, share)
		last_share = share
		sound_off = maxf(sound_off, absf(sounds.hold.volume_db - hold_db - linear_to_db(share)))
	var down: bool = not crucifix.is_raised()
	var back: bool = is_equal_approx(light.energy, full) and crucifix.get_warning_progress() == 0.0
	var sound_back: bool = is_equal_approx(sounds.hold.volume_db, hold_db)
	var processing_after: bool = crucifix.is_processing() or sounds.is_processing()
	var none_as_lowered: bool = progress_as_lowered.size() == 1 and progress_as_lowered[0] == 0.0
	await remove_player(player)
	floor_body.queue_free()
	var most_dips: int = ceili(stats.warning_pulse_rate * stats.warning_time)
	return report(not processing_down and raised and processing_up and wrong.is_empty()
			and top_progress > NEAR_ALL and halfway_deepest[1] < halfway_deepest[0]
			and halfway_deepest[0] < 1.0 and is_equal_approx(last_share, deepest)
			and not dips.is_empty() and dips.size() <= most_dips and sound_off < DB_TOLERANCE
			and down and back and sound_back and not processing_after and none_as_lowered,
			("processing while down: %s (false); raised: %s, processing: %s; wrong: %s; the warning's "
			+ "progress reaches %.2f; the deepest dip in its first half %.2f, in its second %.2f "
			+ "(deeper), on the last frame %.2f (the deepest, %.2f); %d dips before it (%d at most); "
			+ "the hold sound off the light's share by %.3f dB at most; down: %s, with all of its "
			+ "light back: %s and the sound's volume back: %s, processing: %s (false), the warning's "
			+ "progress as it came down: %s ([0])") % [processing_down, raised, processing_up, wrong,
			top_progress, halfway_deepest[0], halfway_deepest[1], last_share, deepest, dips.size(),
			most_dips, sound_off, down, back, sound_back, processing_after, progress_as_lowered])


## Let go halfway through the warning, the crucifix comes down and its light has all of its
## brightness back at once, with no warning left. Its hold sound, turned down while the crucifix was
## down, as in the Remote tab, wavers from that volume and is back to it.
func _let_go_during_the_warning_its_light_comes_back_at_once() -> bool:
	var floor_body: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(START)
	if player == null:
		floor_body.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var crucifix: Crucifix = _crucifix_with_use_time(player)
	var light: PointLight2D = crucifix.get_node(^"%Light") as PointLight2D
	var full: float = light.energy
	var sounds: CrucifixSounds = crucifix.get_node(^"CrucifixSounds") as CrucifixSounds
	sounds.hold.volume_db -= TUNED_DOWN_DB
	var hold_db: float = sounds.hold.volume_db
	var input: StandInInput = put_a_stand_in(player)
	await physics_frame
	input.crucifix_held = true
	var raised: bool = await wait_until(crucifix.is_raised)
	var warning: bool = await wait_until(func() -> bool:
			return crucifix.get_warning_progress() >= 0.5)
	await wait_until(func() -> bool: return light.energy < full)
	var dimmed: bool = light.energy < full and sounds.hold.volume_db < hold_db
	input.crucifix_held = false
	var down: bool = await wait_until(func() -> bool: return not crucifix.is_raised())
	var back: bool = (is_equal_approx(light.energy, full) and crucifix.get_warning_progress() == 0.0
			and is_equal_approx(sounds.hold.volume_db, hold_db))
	var processing_after: bool = crucifix.is_processing() or sounds.is_processing()
	await remove_player(player)
	floor_body.queue_free()
	return report(raised and warning and dimmed and down and back and not processing_after,
			("raised: %s; halfway through the warning: %s, the light and the sound dimmed: %s; let go, "
			+ "it is down: %s, with all of its light, the sound's volume and no warning back: %s, "
			+ "processing: %s (false)") % [raised, warning, dimmed, down, back, processing_after])


## The player's crucifix, with its own copy of Stats lasting USE_TIME, so the .tres stays as it is.
func _crucifix_with_use_time(player: Player) -> Crucifix:
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var stats: CrucifixStats = crucifix.stats.duplicate() as CrucifixStats
	stats.max_use_time = USE_TIME
	crucifix.stats = stats
	return crucifix
