# Checks the ambience beds. A bed plays its sound on two players on the Ambience bus. It fades in
# from silence over Fade Time, then its volume drifts between Quiet dB and Loud dB and does not sit
# still. Each pass runs to Loop End, and the next starts from Loop Start Crossfade seconds before
# it, on the other player, so the two overlap; the cross-fade keeps the total power steady, with no
# dip, and the passes take turns. The first pass starts at a random point of the loop, a different
# one for each bed. stop() fades the bed out over Fade Time and then silences both players, and
# start() brings it back. The pause holds it, and the hitstop of a death, which slows the game's
# time but not the audio, does not slow it. The lust level's beds play on the Ambience bus, each
# with its own sound, and only come back to within a second of the same alignment after half an
# hour.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_bed.gd
extends "res://tests/support/base_test.gd"

const BED_PATH: String = "res://scenes/others/ambience/ambience_bed.tscn"
const LUST_AMBIENCE_PATH: String = "res://scenes/levels/lust/lust_ambience.tscn"
const AMBIENCE_BUS: StringName = &"Ambience"
## The length of a frame with --fixed-fps 60, as in the command above.
const FRAME_TIME: float = 1.0 / 60.0
## The silent sound the beds play, made in memory: its length, in seconds, and its sample rate.
const SOUND_LENGTH: float = 10.0
const SOUND_RATE: int = 8000
## A loop from 1 s to 8 s with a 2 s cross-fade: each pass lasts 7 s, and the next starts 5 s in.
const LOOP_START: float = 1.0
const LOOP_END: float = 8.0
const CROSSFADE: float = 2.0
const NEXT_PASS_AT: float = LOOP_END - LOOP_START - CROSSFADE
const QUIET_DB: float = -12.0
const LOUD_DB: float = -4.0
## Fast enough to see the drift move in a few seconds.
const DRIFT_RATE: float = 0.5
const FADE_TIME: float = 1.0
## The smallest swing of the drift, in dB, over the seconds between the fade-in and the first
## cross-fade.
const MIN_DRIFT_SWING: float = 1.5
## How far from steady the total power may go during a cross-fade: 2%.
const POWER_TOLERANCE: float = 0.02
## Beds made to compare where their first passes start.
const RANDOM_BEDS: int = 8
## Frames to hold a bed with the pause.
const PAUSE_FRAMES: int = 120
## The hitstop's slowed time, as in BrambleDeathStats.
const HITSTOP_TIME_SCALE: float = 0.02
## How close two beds' passes must come to count as lined up again, and the soonest that may
## happen, in seconds.
const ALIGN_TOLERANCE: float = 1.0
const MIN_ALIGN_TIME: float = 1800.0
## How far ahead to look for it, to report when it happens: five hours.
const ALIGN_SEARCH_TIME: float = 18000.0
## How far a playback position may be from where it started: the audio mixes a little meanwhile.
const POSITION_TOLERANCE: float = 0.1
const RANDOM_SEED: int = 2026
## Rounding room for the time and volume limits.
const LIMIT_TOLERANCE: float = 0.001

var _bed_scene: PackedScene


func _initialize() -> void:
	_bed_scene = load(BED_PATH) as PackedScene
	if _bed_scene == null:
		_report(false, "%s loads as a scene" % BED_PATH)
		_finish([false])
		return
	# A node added before the root is ready only gets _ready() with the root, on the first frame.
	await process_frame
	seed(RANDOM_SEED)
	var results: Array[bool] = []
	results.append(_plays_on_the_ambience_bus_with_two_players())
	results.append(await _fades_in_then_drifts_between_quiet_and_loud())
	results.append(await _the_next_pass_cross_fades_in_before_the_last_ends())
	results.append(_the_first_pass_starts_at_a_random_point_of_the_loop())
	results.append(await _stop_fades_out_and_start_brings_it_back())
	results.append(await _the_pause_holds_the_bed())
	results.append(await _the_hitstop_does_not_slow_the_bed())
	results.append(_the_lust_beds_rarely_line_up())
	# Lets the last beds' queue_free() happen before quitting.
	await process_frame
	_finish(results)


func _plays_on_the_ambience_bus_with_two_players() -> bool:
	var sound: AudioStreamWAV = _silent_sound()
	var bed: AmbienceBed = _new_bed(sound)
	var players: Array[AudioStreamPlayer] = [bed.first_player, bed.second_player]
	var passed: bool = players[0] != null and players[1] != null and players[0] != players[1]
	for player: AudioStreamPlayer in players:
		passed = passed and player != null and player.bus == AMBIENCE_BUS and player.stream == sound
	bed.queue_free()
	return _report(passed, "a bed plays its sound on two players, both on the Ambience bus")


func _fades_in_then_drifts_between_quiet_and_loud() -> bool:
	var bed: AmbienceBed = _new_bed(_silent_sound())
	var player: AudioStreamPlayer = bed.first_player
	await process_frame
	var starts_quiet: bool = player.volume_linear <= db_to_linear(LOUD_DB) * 2.0 * FRAME_TIME / FADE_TIME
	var never_loud: bool = true
	var outside: Array[String] = []
	var lowest: float = INF
	var highest: float = -INF
	var frames: int = int((NEXT_PASS_AT - LIMIT_TOLERANCE) / FRAME_TIME)
	for frame: int in range(1, frames):
		await process_frame
		var volume: float = player.volume_db
		never_loud = never_loud and volume <= LOUD_DB + LIMIT_TOLERANCE
		if frame * FRAME_TIME > FADE_TIME + FRAME_TIME:
			if volume < QUIET_DB - LIMIT_TOLERANCE or volume > LOUD_DB + LIMIT_TOLERANCE:
				outside.append("%.2f dB" % volume)
			lowest = minf(lowest, volume)
			highest = maxf(highest, volume)
	bed.queue_free()
	return _report(starts_quiet and never_loud and outside.is_empty()
			and highest - lowest >= MIN_DRIFT_SWING,
			"a bed fades in from silence (%s), never past Loud dB (%s), then drifts between Quiet dB "
			% [starts_quiet, never_loud]
			+ "and Loud dB (outside: %s), %.2f dB from lowest to highest"
			% [", ".join(outside.slice(0, 5)), highest - lowest])


func _the_next_pass_cross_fades_in_before_the_last_ends() -> bool:
	# Without drift, the volume of the whole bed stays at Loud dB, and so must the cross-fade.
	var bed: AmbienceBed = _new_bed(_silent_sound(), false, LOUD_DB)
	var first: AudioStreamPlayer = bed.first_player
	var second: AudioStreamPlayer = bed.second_player
	var steady_power: float = db_to_linear(LOUD_DB) ** 2
	var second_starts: int = -1
	var second_from: float = -1.0
	var first_stops: int = -1
	var first_again: int = -1
	var first_again_from: float = -1.0
	var worst_power: float = 0.0
	var frames: int = int((2.0 * NEXT_PASS_AT + 0.5) / FRAME_TIME)
	for frame: int in range(1, frames + 1):
		await process_frame
		if second_starts < 0 and second.playing:
			second_starts = frame
			second_from = second.get_playback_position()
		if second_starts > 0 and first_stops < 0 and not first.playing:
			first_stops = frame
		if first_stops > 0 and first_again < 0 and first.playing:
			first_again = frame
			first_again_from = first.get_playback_position()
		if frame * FRAME_TIME > FADE_TIME + FRAME_TIME:
			var power: float = ((first.volume_linear if first.playing else 0.0) ** 2
					+ (second.volume_linear if second.playing else 0.0) ** 2)
			worst_power = maxf(worst_power, absf(power / steady_power - 1.0))
	bed.queue_free()
	var on_time: bool = (_near(second_starts, NEXT_PASS_AT) and _near(first_stops, NEXT_PASS_AT + CROSSFADE)
			and _near(first_again, 2.0 * NEXT_PASS_AT))
	var from_start: bool = (absf(second_from - LOOP_START) <= POSITION_TOLERANCE
			and absf(first_again_from - LOOP_START) <= POSITION_TOLERANCE)
	var period_right: bool = is_equal_approx(bed.get_pass_period(), NEXT_PASS_AT)
	return _report(on_time and from_start and period_right and worst_power <= POWER_TOLERANCE,
			"the next pass starts from Loop Start (%.2f s, %.2f s) on the other player at %.3f s, "
			% [second_from, first_again_from, second_starts * FRAME_TIME]
			+ "the last ends at %.3f s, the first plays again at %.3f s (Pass Period %.2f s), "
			% [first_stops * FRAME_TIME, first_again * FRAME_TIME, bed.get_pass_period()]
			+ "and the total power stays within %.1f%% of steady" % (worst_power * 100.0))


func _the_first_pass_starts_at_a_random_point_of_the_loop() -> bool:
	var starts: Array[float] = []
	var beds: Array[AmbienceBed] = []
	for _bed: int in RANDOM_BEDS:
		var bed: AmbienceBed = _new_bed(_silent_sound(), true)
		beds.append(bed)
		starts.append(bed.first_player.get_playback_position())
	for bed: AmbienceBed in beds:
		bed.queue_free()
	var inside: bool = true
	for start: float in starts:
		inside = inside and start >= LOOP_START - POSITION_TOLERANCE
		inside = inside and start <= LOOP_END - CROSSFADE + POSITION_TOLERANCE
	var differ: bool = starts.max() - starts.min() > POSITION_TOLERANCE
	return _report(inside and differ,
			"each bed's first pass starts between Loop Start and Loop End less Crossfade, "
			+ "and not all at the same point (%s)" % ", ".join(starts.map(
					func(start: float) -> String: return "%.2f" % start)))


func _stop_fades_out_and_start_brings_it_back() -> bool:
	var bed: AmbienceBed = _new_bed(_silent_sound(), false, LOUD_DB)
	await _wait_frames(int((FADE_TIME + 0.5) / FRAME_TIME))
	bed.stop()
	var stopped_running: bool = not bed.is_running()
	var falling: bool = true
	var last: float = bed.first_player.volume_linear
	var silenced: int = -1
	for frame: int in range(1, int((FADE_TIME + 0.5) / FRAME_TIME)):
		await process_frame
		if bed.first_player.playing:
			falling = falling and bed.first_player.volume_linear <= last + LIMIT_TOLERANCE
			last = bed.first_player.volume_linear
		elif silenced < 0:
			silenced = frame
	var both_silent: bool = not bed.first_player.playing and not bed.second_player.playing
	bed.start()
	await process_frame
	var back: bool = bed.is_running() and bed.first_player.playing
	bed.queue_free()
	return _report(stopped_running and falling and _near(silenced, FADE_TIME) and both_silent and back,
			"stop() fades the bed out (%s) and silences both players after %.3f s (%s), "
			% [falling, silenced * FRAME_TIME, both_silent]
			+ "and start() brings it back (%s)" % back)


func _the_pause_holds_the_bed() -> bool:
	var bed: AmbienceBed = _new_bed(_silent_sound(), false)
	await _wait_frames(int((FADE_TIME + 0.5) / FRAME_TIME))
	var volume_before: float = bed.first_player.volume_linear
	paused = true
	await _wait_frames(PAUSE_FRAMES)
	# A paused player says it is not playing: the bed must neither move its volume nor end its pass.
	var held: bool = bed.first_player.volume_linear == volume_before and not bed.second_player.playing
	paused = false
	await process_frame
	held = held and bed.first_player.playing
	await _wait_frames(int((NEXT_PASS_AT - FADE_TIME - 0.5) / FRAME_TIME) - 3)
	var no_pass_yet: bool = not bed.second_player.playing
	await _wait_frames(4)
	var then_pass: bool = bed.second_player.playing
	bed.queue_free()
	return _report(held and no_pass_yet and then_pass,
			"the pause holds the bed's volume and its passes (%s), and the next pass comes as late "
			% held + "as the pause lasted (%s, %s)" % [no_pass_yet, then_pass])


func _the_hitstop_does_not_slow_the_bed() -> bool:
	var bed: AmbienceBed = _new_bed(_silent_sound(), false)
	Engine.time_scale = HITSTOP_TIME_SCALE
	var started: int = -1
	for frame: int in range(1, int((NEXT_PASS_AT + 0.5) / FRAME_TIME)):
		await process_frame
		if bed.second_player.playing:
			started = frame
			break
	Engine.time_scale = 1.0
	bed.queue_free()
	# The frame the time scale changes on counts for at most MAX_STEP instead of one frame.
	var on_time: bool = (started > 0 and absf(started * FRAME_TIME - NEXT_PASS_AT)
			<= AmbienceBed.MAX_STEP + FRAME_TIME + LIMIT_TOLERANCE)
	return _report(on_time,
			"with the hitstop's time scale, the next pass still starts at %.3f s of real time"
			% (started * FRAME_TIME))


func _the_lust_beds_rarely_line_up() -> bool:
	var scene: PackedScene = load(LUST_AMBIENCE_PATH) as PackedScene
	if scene == null:
		return _report(false, "%s loads as a scene" % LUST_AMBIENCE_PATH)
	var ambience: Node = scene.instantiate()
	var beds: Array[AmbienceBed] = []
	for child: Node in ambience.find_children("*", "AmbienceBed", true, false):
		beds.append(child as AmbienceBed)
	var ready: bool = beds.size() >= 2
	var sounds: Array[AudioStream] = []
	for bed: AmbienceBed in beds:
		ready = ready and bed.sound != null and bed.sound not in sounds and bed.autostart
		ready = ready and bed.first_player.bus == AMBIENCE_BUS and bed.second_player.bus == AMBIENCE_BUS
		ready = ready and bed.get_pass_period() > 0.0
		sounds.append(bed.sound)
	var soonest: float = INF
	for index: int in beds.size():
		for other: int in range(index + 1, beds.size()):
			soonest = minf(soonest, _soonest_alignment(beds[index].get_pass_period(),
					beds[other].get_pass_period()))
	var periods: Array = beds.map(func(bed: AmbienceBed) -> String:
			return "%.2f s" % bed.get_pass_period())
	ambience.queue_free()
	return _report(ready and soonest >= MIN_ALIGN_TIME,
			"the lust level has %d beds on the Ambience bus, each with its own sound (%s), with "
			% [beds.size(), ready] + "passes of %s that come back in line only after %.0f s"
			% [", ".join(periods), soonest])


## The first time, up to ALIGN_SEARCH_TIME, at which a pass of one period starts within
## ALIGN_TOLERANCE of a pass of the other; INF if none does.
func _soonest_alignment(period: float, other_period: float) -> float:
	var passes: int = int(ALIGN_SEARCH_TIME / period) + 1
	for count: int in range(1, passes + 1):
		var time: float = count * period
		var off: float = fmod(time, other_period)
		if minf(off, other_period - off) < ALIGN_TOLERANCE:
			return time
	return INF


## A bed on a silent sound, with a short loop, already in the tree: with autostart, it starts now.
## Without random_start, its first pass starts at Loop Start. With quiet_db, it drifts from there to
## Loud dB; with Quiet dB at Loud dB, it does not drift.
func _new_bed(sound: AudioStream, random_start: bool = false,
		quiet_db: float = QUIET_DB) -> AmbienceBed:
	var bed: AmbienceBed = _bed_scene.instantiate() as AmbienceBed
	bed.sound = sound
	bed.random_start = random_start
	bed.loop_start = LOOP_START
	bed.loop_end = LOOP_END
	bed.crossfade = CROSSFADE
	bed.quiet_db = quiet_db
	bed.loud_db = LOUD_DB
	bed.drift_rate = DRIFT_RATE
	bed.fade_time = FADE_TIME
	root.add_child(bed)
	return bed


## Whether frame is the frame on which time, in seconds, ends, give or take one.
func _near(frame: int, time: float) -> bool:
	return frame > 0 and absf(frame * FRAME_TIME - time) <= FRAME_TIME + LIMIT_TOLERANCE


func _silent_sound() -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	sound.mix_rate = SOUND_RATE
	var bytes := PackedByteArray()
	bytes.resize(int(SOUND_LENGTH * SOUND_RATE))
	sound.data = bytes
	return sound


func _wait_frames(frames: int) -> void:
	for _step: int in frames:
		await process_frame


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func _finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)
