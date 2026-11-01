# Checks the SoulPoints component on its own, without a player. It starts full from its Stats,
# whatever Max SP they say. Damage and healing keep the SP between 0 and Max SP, and each change
# says so once, in this order: damaged, sp_changed, low_changed, depleted. Reaching Low Threshold,
# or leaving it, says so once each way, and running out says so once; after that, damage and
# healing do nothing. Healing a full man says nothing. Negative, infinite and nan amounts change
# nothing and say nothing: each one prints an error on purpose, four in all. Max SP and Low
# Threshold changed in Stats take effect at once: 125 SP needs only data, and a lower Max SP brings
# the SP down with it. So does a new Stats file put in place of the old one. The SP comes back on
# its own, up to Max SP and no further. From a hit on, it stays put for Regen Delay's physics
# frames and comes back on the next one, and a hit during the pause starts it again. When it comes
# back, its speed starts at Regen Start Per Second and rises in a straight line to Regen Top Per
# Second in Regen Ramp Time; a hit sends it back to the start and healing does not, a ramp time of
# 0 starts at the top, and with the two speeds the same it keeps one speed. get_regen_rate() says
# what the next frame gives. Once run out, or while the game is paused, nothing comes back. The
# player scene has its own SoulPoints, with the stats file. Only the first case and the player
# scene's use the stats file as it is; the others use a copy with values of their own (100 SP, low
# at 25, a 3 s pause), so tuning the file changes none of them.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_soul_points.gd
extends "res://tests/support/base_test.gd"

const STATS: SoulPointsStats = preload("res://player/soul_points_stats.tres")
const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
## The Max SP, Low Threshold and pause after a hit the cases are written for, set on a copy of the
## stats file, so tuning the file changes no case.
const TEST_MAX_SP: float = 100.0
const TEST_LOW_THRESHOLD: float = 25.0
const TEST_REGEN_DELAY: float = 3.0
## A Max SP above the cases' 100, set by data in the Max SP cases.
const HIGHER_MAX_SP: float = 125.0
## A Max SP below the SP the man has, in the Max SP cases.
const LOWER_MAX_SP: float = 80.0
## A Low Threshold above the SP the man has, in the Low Threshold case.
const HIGHER_LOW_THRESHOLD: float = 40.0
## How far one second of regeneration may be from the expected SP.
const REGEN_TOLERANCE: float = 0.01
## How far into the pause the second hit of the case of a hit during the pause comes: well inside.
const SECOND_HIT_INTO_THE_PAUSE: float = 2.0 / 3.0
## The single speed of the regeneration cases that are not about the ramp, in SP/s.
const ONE_SPEED: float = 2.0
## The ramp of the ramp cases: from 0.5 to 3 SP/s in 1 s, so they do not wait the file's 10 s.
const RAMP_START: float = 0.5
const RAMP_TOP: float = 3.0
const RAMP_TIME: float = 1.0
## The pause of the case where the ramp waits for it: longer than the ramp, in s.
const LONG_PAUSE: float = 2.0
## The hit of the ramp cases leaves 10 SP, so 3 s at the top never fill the man up.
const RAMP_HIT: float = 90.0
## The hit that sends the ramp back, and the healing that does not, in SP.
const SMALL_HIT: float = 1.0
const SOME_HEALING: float = 5.0
## How far a speed measured over one physics frame may be from the expected one, in SP/s.
const RATE_TOLERANCE: float = 0.001


## Writes down, in order, every signal a SoulPoints gives.
class Heard:
	var events: PackedStringArray = []

	func _init(soul_points: SoulPoints) -> void:
		soul_points.sp_changed.connect(func(current: float, maximum: float) -> void:
				events.append("sp_changed %.1f/%.1f" % [current, maximum]))
		soul_points.damaged.connect(func(amount: float) -> void:
				events.append("damaged %.1f" % amount))
		soul_points.low_changed.connect(func(is_low: bool) -> void:
				events.append("low_changed %s" % is_low))
		soul_points.depleted.connect(func() -> void: events.append("depleted"))


func _initialize() -> void:
	# Before the first frame the root is not ready yet, and a node added to it only runs _ready()
	# when the root does.
	await process_frame
	var results: Array[bool] = []
	results.append(_starts_full_from_the_stats_file())
	results.append(_starts_full_with_any_max_sp())
	results.append(_damage_takes_sp_and_says_so_once())
	results.append(_damage_never_takes_it_below_zero())
	results.append(_once_run_out_damage_and_healing_do_nothing())
	results.append(_healing_never_takes_it_above_max())
	results.append(_low_threshold_says_so_once_each_way())
	results.append(_bad_amounts_change_nothing())
	results.append(_max_sp_from_data_takes_effect_at_once())
	results.append(_low_threshold_from_data_takes_effect_at_once())
	results.append(_new_stats_file_takes_effect_at_once())
	results.append(await _with_both_speeds_the_same_it_keeps_one_speed())
	results.append(await _regeneration_stops_at_max_sp())
	results.append(await _regeneration_waits_regen_delay_after_a_hit())
	results.append(await _a_hit_during_the_pause_starts_it_again())
	results.append(await _the_ramp_rises_from_start_to_top_in_ramp_time())
	results.append(await _a_hit_sends_the_ramp_back_and_healing_does_not())
	results.append(await _the_ramp_starts_when_the_pause_ends())
	results.append(await _a_ramp_time_of_zero_starts_at_the_top())
	results.append(await _get_regen_rate_says_what_the_next_frame_gives())
	results.append(await _no_regeneration_once_run_out())
	results.append(await _no_regeneration_while_the_game_is_paused())
	results.append(_the_player_scene_has_its_soul_points())
	quit(1 if results.has(false) else 0)


## With the stats file, a new man is full and not low.
func _starts_full_from_the_stats_file() -> bool:
	var soul_points: SoulPoints = _new_soul_points(STATS)
	var passed: bool = (soul_points.get_sp() == STATS.max_sp
			and soul_points.get_max_sp() == STATS.max_sp and not soul_points.is_low()
			and not soul_points.is_depleted())
	var what: String = ("Starts with %.1f of %.1f SP, low %s, depleted %s"
			% [soul_points.get_sp(), soul_points.get_max_sp(), soul_points.is_low(),
			soul_points.is_depleted()])
	soul_points.queue_free()
	return _report(passed, what)


## Stats that say 125 SP before the man is made: he starts with 125. Max SP is only data.
func _starts_full_with_any_max_sp() -> bool:
	var stats: SoulPointsStats = _test_stats()
	stats.max_sp = HIGHER_MAX_SP
	var soul_points: SoulPoints = _new_soul_points(stats)
	var passed: bool = (soul_points.get_sp() == HIGHER_MAX_SP
			and soul_points.get_max_sp() == HIGHER_MAX_SP and not soul_points.is_low())
	var what: String = ("Made with Max SP 125: starts with %.1f of %.1f SP, low %s"
			% [soul_points.get_sp(), soul_points.get_max_sp(), soul_points.is_low()])
	soul_points.queue_free()
	return _report(passed, what)


func _damage_takes_sp_and_says_so_once() -> bool:
	var soul_points: SoulPoints = _new_soul_points(_test_stats())
	var heard: Heard = Heard.new(soul_points)
	soul_points.take_damage(30.0)
	return _report_heard(soul_points, heard, "30 of damage at 100 SP",
			["damaged 30.0", "sp_changed 70.0/100.0"])


## The damage said is what the man lost, not what was dealt.
func _damage_never_takes_it_below_zero() -> bool:
	var soul_points: SoulPoints = _new_soul_points(_test_stats())
	var heard: Heard = Heard.new(soul_points)
	soul_points.take_damage(150.0)
	var depleted: bool = soul_points.is_depleted()
	return _report_heard(soul_points, heard, "150 of damage at 100 SP, depleted %s" % depleted,
			["damaged 100.0", "sp_changed 0.0/100.0", "low_changed true", "depleted"],
			depleted)


## Running out is final here: starting the man again is not this component's job.
func _once_run_out_damage_and_healing_do_nothing() -> bool:
	var soul_points: SoulPoints = _new_soul_points(_test_stats())
	soul_points.take_damage(100.0)
	var heard: Heard = Heard.new(soul_points)
	soul_points.take_damage(10.0)
	soul_points.heal(10.0)
	return _report_heard(soul_points, heard, "10 of damage and 10 of healing after running out", [])


## The second heal, at full SP, says nothing.
func _healing_never_takes_it_above_max() -> bool:
	var soul_points: SoulPoints = _new_soul_points(_test_stats())
	soul_points.take_damage(10.0)
	var heard: Heard = Heard.new(soul_points)
	soul_points.heal(30.0)
	soul_points.heal(5.0)
	return _report_heard(soul_points, heard, "30 and then 5 of healing at 90 SP",
			["sp_changed 100.0/100.0"])


## 25 SP is already low. The last hit stays low, so it says nothing about it.
func _low_threshold_says_so_once_each_way() -> bool:
	var soul_points: SoulPoints = _new_soul_points(_test_stats())
	var heard: Heard = Heard.new(soul_points)
	soul_points.take_damage(75.0)
	soul_points.heal(1.0)
	soul_points.take_damage(1.0)
	soul_points.take_damage(1.0)
	return _report_heard(soul_points, heard, "Down to 25 SP, up to 26, down to 25 and to 24",
			["damaged 75.0", "sp_changed 25.0/100.0", "low_changed true",
			"sp_changed 26.0/100.0", "low_changed false",
			"damaged 1.0", "sp_changed 25.0/100.0", "low_changed true",
			"damaged 1.0", "sp_changed 24.0/100.0"])


## A negative damage must never heal, nor a negative heal hurt. 0 is not an error: a heal of 0 SP
## per second gives 0 every frame.
func _bad_amounts_change_nothing() -> bool:
	var soul_points: SoulPoints = _new_soul_points(_test_stats())
	soul_points.take_damage(50.0)
	var heard: Heard = Heard.new(soul_points)
	soul_points.take_damage(-10.0)
	soul_points.heal(-10.0)
	soul_points.take_damage(NAN)
	soul_points.heal(INF)
	soul_points.take_damage(0.0)
	soul_points.heal(0.0)
	var sp: float = soul_points.get_sp()
	return _report_heard(soul_points, heard,
			"-10, nan and 0 of damage, -10, inf and 0 of healing at 50 SP: %.1f SP after" % sp,
			[], sp == 50.0)


## Max SP up to 125 leaves the SP where it was, and healing then goes up to 125. Max SP down to 80
## brings the SP down with it.
func _max_sp_from_data_takes_effect_at_once() -> bool:
	var stats: SoulPointsStats = _test_stats()
	var soul_points: SoulPoints = _new_soul_points(stats)
	var heard: Heard = Heard.new(soul_points)
	stats.max_sp = HIGHER_MAX_SP
	soul_points.heal(50.0)
	stats.max_sp = LOWER_MAX_SP
	return _report_heard(soul_points, heard, "Max SP to 125, 50 of healing, Max SP to 80",
			["sp_changed 100.0/125.0", "sp_changed 125.0/125.0", "sp_changed 80.0/80.0"])


func _low_threshold_from_data_takes_effect_at_once() -> bool:
	var stats: SoulPointsStats = _test_stats()
	var soul_points: SoulPoints = _new_soul_points(stats)
	soul_points.take_damage(70.0)
	var heard: Heard = Heard.new(soul_points)
	stats.low_threshold = HIGHER_LOW_THRESHOLD
	return _report_heard(soul_points, heard, "Low Threshold to 40 at 30 SP",
			["sp_changed 30.0/100.0", "low_changed true"])


## The old file no longer reaches it: a change to it says nothing.
func _new_stats_file_takes_effect_at_once() -> bool:
	var old_stats: SoulPointsStats = _test_stats()
	var new_stats: SoulPointsStats = _test_stats()
	new_stats.max_sp = LOWER_MAX_SP
	var soul_points: SoulPoints = _new_soul_points(old_stats)
	var heard: Heard = Heard.new(soul_points)
	soul_points.stats = new_stats
	old_stats.max_sp = HIGHER_MAX_SP
	return _report_heard(soul_points, heard,
			"A file with Max SP 80 put in place, then the old one changed to 125",
			["sp_changed 80.0/80.0"])


## With Regen Start Per Second and Regen Top Per Second both at 2 SP/s and no pause, one second
## takes 24 SP to 26, as a single speed would, and leaving the low zone says so once.
func _with_both_speeds_the_same_it_keeps_one_speed() -> bool:
	var stats: SoulPointsStats = _test_stats()
	stats.regen_delay = 0.0
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(76.0)
	var heard: Heard = Heard.new(soul_points)
	await _wait_physics_frames(Engine.physics_ticks_per_second)
	var sp: float = soul_points.get_sp()
	var expected: float = 24.0 + ONE_SPEED
	var low_left: int = heard.events.count("low_changed false")
	var low_entered: int = heard.events.count("low_changed true")
	soul_points.queue_free()
	return _report(absf(sp - expected) <= REGEN_TOLERANCE and low_left == 1 and low_entered == 0,
			"One second of regeneration from 24 SP: %.3f SP, expected %.3f; left low %d times, entered %d"
			% [sp, expected, low_left, low_entered])


## From 99.5 SP it stops at 100, and once full it says nothing more.
func _regeneration_stops_at_max_sp() -> bool:
	var stats: SoulPointsStats = _test_stats()
	stats.regen_delay = 0.0
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(0.5)
	var heard: Heard = Heard.new(soul_points)
	await _wait_physics_frames(Engine.physics_ticks_per_second)
	var sp: float = soul_points.get_sp()
	var heard_when_full: int = heard.events.size()
	await _wait_physics_frames(Engine.physics_ticks_per_second)
	var heard_since: int = heard.events.size() - heard_when_full
	soul_points.queue_free()
	return _report(sp == stats.max_sp and heard_since == 0,
			"One second of regeneration from 99.5 SP: %.3f SP; signals in the next second: %d"
			% [sp, heard_since])


## The default 3 s: nothing for the 180 frames from the hit on, the hit's own frame included, and
## up on the next one.
func _regeneration_waits_regen_delay_after_a_hit() -> bool:
	var stats: SoulPointsStats = _test_stats()
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(50.0)
	var delay_frames: int = stats.get_regen_delay_frames()
	await _wait_physics_frames(delay_frames)
	var sp_at_the_end: float = soul_points.get_sp()
	await physics_frame
	var sp_after: float = soul_points.get_sp()
	soul_points.queue_free()
	return _report(sp_at_the_end == 50.0 and sp_after > 50.0,
			"50 SP after a hit: %.3f SP after %d frames, %.3f SP on the next one"
			% [sp_at_the_end, delay_frames, sp_after])


## A second hit two thirds into the pause, 120 frames: nothing for the 180 frames from the second
## hit.
func _a_hit_during_the_pause_starts_it_again() -> bool:
	var stats: SoulPointsStats = _test_stats()
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(50.0)
	var delay_frames: int = stats.get_regen_delay_frames()
	var frames_between_hits: int = roundi(delay_frames * SECOND_HIT_INTO_THE_PAUSE)
	await _wait_physics_frames(frames_between_hits)
	soul_points.take_damage(10.0)
	await _wait_physics_frames(delay_frames)
	var sp_at_the_end: float = soul_points.get_sp()
	await physics_frame
	var sp_after: float = soul_points.get_sp()
	soul_points.queue_free()
	return _report(sp_at_the_end == 40.0 and sp_after > 40.0,
			"A second hit %d frames into the pause, at 40 SP: %.3f SP %d frames later, %.3f SP on the next"
			% [frames_between_hits, sp_at_the_end, delay_frames, sp_after])


func _no_regeneration_once_run_out() -> bool:
	var stats: SoulPointsStats = _test_stats()
	stats.regen_delay = 0.0
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(100.0)
	var heard: Heard = Heard.new(soul_points)
	await _wait_physics_frames(Engine.physics_ticks_per_second)
	return _report_heard(soul_points, heard, "One second after running out", [],
			soul_points.get_sp() == 0.0)


## The node is Pausable, like the level it goes in.
func _no_regeneration_while_the_game_is_paused() -> bool:
	var stats: SoulPointsStats = _test_stats()
	stats.regen_delay = 0.0
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(50.0)
	paused = true
	await _wait_physics_frames(Engine.physics_ticks_per_second)
	var sp_paused: float = soul_points.get_sp()
	paused = false
	await physics_frame
	var sp_after: float = soul_points.get_sp()
	soul_points.queue_free()
	return _report(sp_paused == 50.0 and sp_after > 50.0,
			"One second paused at 50 SP: %.3f SP; %.3f SP one frame after the pause"
			% [sp_paused, sp_after])


## Right after a hit, regeneration gives Regen Start Per Second, halfway through Regen Ramp Time it
## is halfway to the top, at its end it gives Regen Top Per Second, and it never goes past it.
func _the_ramp_rises_from_start_to_top_in_ramp_time() -> bool:
	var stats: SoulPointsStats = _ramp_stats()
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(RAMP_HIT)
	var ramp_frames: int = stats.get_regen_ramp_frames()
	var halfway_frames: int = roundi(ramp_frames / 2.0)
	var at_the_start: float = await _rate_of_next_frame(soul_points)
	await _wait_physics_frames(halfway_frames - 1)
	var halfway: float = await _rate_of_next_frame(soul_points)
	await _wait_physics_frames(ramp_frames - halfway_frames - 1)
	var at_the_end: float = await _rate_of_next_frame(soul_points)
	await _wait_physics_frames(ramp_frames)
	var long_after: float = await _rate_of_next_frame(soul_points)
	soul_points.queue_free()
	return _report_rates("The ramp at its start, halfway, at its end and a ramp later",
			[at_the_start, halfway, at_the_end, long_after],
			[RAMP_START, (RAMP_START + RAMP_TOP) / 2.0, RAMP_TOP, RAMP_TOP])


## Healing halfway up the ramp, as the crucifix's does, leaves it there; a hit sends it back to
## Regen Start Per Second.
func _a_hit_sends_the_ramp_back_and_healing_does_not() -> bool:
	var stats: SoulPointsStats = _ramp_stats()
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(RAMP_HIT)
	await _wait_physics_frames(roundi(stats.get_regen_ramp_frames() / 2.0))
	soul_points.heal(SOME_HEALING)
	var after_healing: float = await _rate_of_next_frame(soul_points)
	soul_points.take_damage(SMALL_HIT)
	var after_the_hit: float = await _rate_of_next_frame(soul_points)
	soul_points.queue_free()
	return _report_rates("Halfway up the ramp, after healing and then after a hit",
			[after_healing, after_the_hit], [(RAMP_START + RAMP_TOP) / 2.0, RAMP_START])


## The ramp does not climb during the pause after a hit, so when the pause ends regeneration gives
## Regen Start Per Second, even with a pause longer than the ramp.
func _the_ramp_starts_when_the_pause_ends() -> bool:
	var stats: SoulPointsStats = _ramp_stats()
	stats.regen_delay = LONG_PAUSE
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(RAMP_HIT)
	await _wait_physics_frames(stats.get_regen_delay_frames())
	var first: float = await _rate_of_next_frame(soul_points)
	soul_points.queue_free()
	return _report_rates("The first frame after a pause longer than the ramp", [first], [RAMP_START])


## With Regen Ramp Time at 0, regeneration gives Regen Top Per Second from its first frame.
func _a_ramp_time_of_zero_starts_at_the_top() -> bool:
	var stats: SoulPointsStats = _ramp_stats()
	stats.regen_ramp_time = 0.0
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	soul_points.take_damage(RAMP_HIT)
	var first: float = await _rate_of_next_frame(soul_points)
	soul_points.queue_free()
	return _report_rates("The first frame with a ramp time of 0", [first], [RAMP_TOP])


## get_regen_rate() says what the next physics frame gives: nothing when full or during the pause
## after a hit, the ramp's speed once regeneration runs, and nothing once run out, also after the
## pause of the last hit.
func _get_regen_rate_says_what_the_next_frame_gives() -> bool:
	var stats: SoulPointsStats = _ramp_stats()
	stats.regen_delay = LONG_PAUSE
	var soul_points: SoulPoints = _new_soul_points(stats)
	await physics_frame
	var when_full: float = soul_points.get_regen_rate()
	soul_points.take_damage(RAMP_HIT)
	var in_the_pause: float = soul_points.get_regen_rate()
	await _wait_physics_frames(stats.get_regen_delay_frames())
	var said_first: float = soul_points.get_regen_rate()
	var gave_first: float = await _rate_of_next_frame(soul_points)
	await _wait_physics_frames(roundi(stats.get_regen_ramp_frames() / 2.0) - 1)
	var said_halfway: float = soul_points.get_regen_rate()
	var gave_halfway: float = await _rate_of_next_frame(soul_points)
	soul_points.take_damage(RAMP_HIT)
	await _wait_physics_frames(stats.get_regen_delay_frames())
	var once_run_out: float = soul_points.get_regen_rate()
	soul_points.queue_free()
	var halfway: float = (RAMP_START + RAMP_TOP) / 2.0
	return _report_rates(
			"Said full, in the pause, then said and given at the start and halfway, and run out",
			[when_full, in_the_pause, said_first, gave_first, said_halfway, gave_halfway, once_run_out],
			[0.0, 0.0, RAMP_START, RAMP_START, halfway, halfway, 0.0])


## The player scene has its own SoulPoints, with the stats file, in the player's Soul Points, so
## what hurts or heals the man finds it there; a new man is full.
func _the_player_scene_has_its_soul_points() -> bool:
	var player: Player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	var soul_points: SoulPoints = player.soul_points
	var found: bool = soul_points != null and soul_points.get_parent() == player
	var stats_path: String = soul_points.stats.resource_path if found else ""
	var sp: float = soul_points.get_sp() if found else 0.0
	player.queue_free()
	return _report(found and stats_path == STATS.resource_path and sp == STATS.max_sp,
			"Player scene: own SoulPoints %s, stats \"%s\", %.1f SP" % [found, stats_path, sp])


## Waits for count physics frames. Code after it runs before the nodes' physics of the frame it
## stops on, as code after a hit does.
func _wait_physics_frames(count: int) -> void:
	for i: int in count:
		await physics_frame


## A copy of the stats file with the values the cases are written for: TEST_MAX_SP,
## TEST_LOW_THRESHOLD and TEST_REGEN_DELAY, and regeneration at ONE_SPEED, for the cases not about
## the ramp.
func _test_stats() -> SoulPointsStats:
	var stats: SoulPointsStats = STATS.duplicate()
	stats.max_sp = TEST_MAX_SP
	stats.low_threshold = TEST_LOW_THRESHOLD
	stats.regen_delay = TEST_REGEN_DELAY
	stats.regen_start_per_second = ONE_SPEED
	stats.regen_top_per_second = ONE_SPEED
	return stats


## The cases' values with the short ramp of the ramp cases, and no pause after a hit.
func _ramp_stats() -> SoulPointsStats:
	var stats: SoulPointsStats = _test_stats()
	stats.regen_delay = 0.0
	stats.regen_start_per_second = RAMP_START
	stats.regen_top_per_second = RAMP_TOP
	stats.regen_ramp_time = RAMP_TIME
	return stats


## The speed regeneration gives on the next physics frame, in SP/s, from what that frame adds.
func _rate_of_next_frame(soul_points: SoulPoints) -> float:
	var before: float = soul_points.get_sp()
	await physics_frame
	return (soul_points.get_sp() - before) * Engine.physics_ticks_per_second


## A SoulPoints with these stats, in the tree, so its _ready() has run.
func _new_soul_points(stats: SoulPointsStats) -> SoulPoints:
	var soul_points: SoulPoints = SoulPoints.new()
	soul_points.stats = stats
	root.add_child(soul_points)
	return soul_points


## Passes if the signals heard are the expected ones, in order, and also_passed holds. Frees the
## SoulPoints.
func _report_heard(soul_points: SoulPoints, heard: Heard, what: String,
		expected: PackedStringArray, also_passed: bool = true) -> bool:
	soul_points.queue_free()
	return _report(also_passed and heard.events == expected,
			"%s: heard %s, expected %s" % [what, heard.events, expected])


## Passes if each speed is within RATE_TOLERANCE of the expected one, in the same order.
func _report_rates(what: String, rates: Array[float], expected: Array[float]) -> bool:
	var passed: bool = rates.size() == expected.size()
	var texts: PackedStringArray = []
	for i: int in rates.size():
		texts.append("%.3f" % rates[i])
		passed = passed and i < expected.size() and absf(rates[i] - expected[i]) <= RATE_TOLERANCE
	return _report(passed, "%s: %s SP/s, expected %s" % [what, ", ".join(texts), expected])


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
