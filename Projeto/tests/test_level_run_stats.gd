# Checks that level 1 tells RunStats where the man is and where he dies. Started fresh, it is
# phase 1 of "level1"; with phase 2's or phase 3's save already reached in GameState, it starts in
# that phase, and walking into phase 2's save moves him on. A death counts in the phase he is in,
# inside the smallest camera zone around him, and a death outside every zone counts in a cell.
# Time adds up in the phase while the level runs, stops while the game is paused, and is not lost
# when a new copy of the level takes the place of the old one, as after a death.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level_run_stats.gd
extends "res://tests/support/player_test.gd"

const LEVEL_1: PackedScene = preload("res://levels/lust/level1.tscn")
const PHASE_2_EVENT: StringName = &"lust_phase_2_reached"
const PHASE_3_EVENT: StringName = &"lust_phase_3_reached"
## Frames for the level to settle after it is added.
const SETTLE_FRAMES: int = 3
## Frames of the time cases: a second at --fixed-fps 60.
const TIME_FRAMES: int = 60
## How far the time counted can be from the frames' time: up to a frame either way.
const TIME_TOLERANCE: float = 1.5 / 60.0

var _stats: GameRunStats
var _progress: GameProgress


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	_stats = root.get_node(^"RunStats") as GameRunStats
	_progress = root.get_node(^"GameState") as GameProgress
	var results: Array[bool] = []
	results.append(await _fresh_it_is_phase_1_of_level1())
	results.append(await _a_reached_save_starts_in_its_phase())
	results.append(await _walking_into_phase_2s_save_moves_him_on())
	results.append(await _a_death_counts_in_the_smallest_zone())
	results.append(await _outside_every_zone_a_death_counts_in_a_cell())
	results.append(await _time_counts_in_the_phase_but_not_while_paused())
	finish(results)


func _fresh_it_is_phase_1_of_level1() -> bool:
	_progress.reset()
	_stats.reset()
	var level: Level = await _add_level()
	var passed: bool = _stats.get_level() == &"level1" and _stats.get_phase() == 1
	await _remove(level)
	return report(passed, "fresh, it is phase %d of %s" % [_stats.get_phase(), _stats.get_level()])


func _a_reached_save_starts_in_its_phase() -> bool:
	_progress.reset()
	_stats.reset()
	_progress.mark_event(PHASE_2_EVENT)
	var level: Level = await _add_level()
	var in_2: int = _stats.get_phase()
	await _remove(level)
	_progress.mark_event(PHASE_3_EVENT)
	level = await _add_level()
	var in_3: int = _stats.get_phase()
	await _remove(level)
	return report(in_2 == 2 and in_3 == 3, "with a phase's save reached, it starts there (%d, %d)"
			% [in_2, in_3])


func _walking_into_phase_2s_save_moves_him_on() -> bool:
	_progress.reset()
	_stats.reset()
	var level: Level = await _add_level()
	var save: SavePoint = level.get_node(^"Phase2Save") as SavePoint
	level.player.global_position = save.global_position
	await wait_frames(SETTLE_FRAMES)
	var phase: int = _stats.get_phase()
	await _remove(level)
	return report(phase == 2, "walking into phase 2's save moves him to phase %d" % phase)


func _a_death_counts_in_the_smallest_zone() -> bool:
	_progress.reset()
	_stats.reset()
	var level: Level = await _add_level()
	var point: Vector2 = level.player.global_position
	var expected: StringName = _smallest_zone_at(level, point)
	level.player.die()
	var passed: bool = (not expected.is_empty() and _stats.deaths_in_phase(1) == 1
			and _stats.last_zone() == expected and _stats.same_spot_deaths() == 1)
	await _remove(level)
	return report(passed, "a death counts in phase 1, in the smallest zone (%s, expected %s)"
			% [_stats.last_zone(), expected])


func _outside_every_zone_a_death_counts_in_a_cell() -> bool:
	_progress.reset()
	_stats.reset()
	var level: Level = await _add_level()
	var far: Vector2 = Vector2(-100000.0, -100000.0)
	var zone: StringName = level.zone_at(far)
	await _remove(level)
	return report(String(zone).begins_with("cell_"), "outside every zone, a death counts in %s" % zone)


## A second of frames counts about a second in phase 1, a paused second adds nothing, and a new copy
## of the level, as after a death, goes on from there instead of starting at 0.
func _time_counts_in_the_phase_but_not_while_paused() -> bool:
	_progress.reset()
	_stats.reset()
	var level: Level = await _add_level()
	var start: float = _stats.phase_seconds()
	await wait_frames(TIME_FRAMES)
	var running: float = _stats.phase_seconds() - start
	paused = true
	var before_pause: float = _stats.phase_seconds()
	await wait_frames(TIME_FRAMES)
	var while_paused: float = _stats.phase_seconds() - before_pause
	paused = false
	await _remove(level)
	var before_copy: float = _stats.phase_seconds()
	level = await _add_level()
	var kept: bool = _stats.phase_seconds() >= before_copy
	await _remove(level)
	var second: float = TIME_FRAMES / 60.0
	return report(absf(running - second) < TIME_TOLERANCE and while_paused == 0.0 and kept,
			("time in the phase: %.3f s in %d frames (expected %.3f), %.3f s while paused, kept by a "
			+ "new copy %s") % [running, TIME_FRAMES, second, while_paused, kept])


func _add_level() -> Level:
	var level: Level = LEVEL_1.instantiate() as Level
	root.add_child(level)
	await wait_frames(SETTLE_FRAMES)
	return level


func _remove(level: Level) -> void:
	level.queue_free()
	await wait_frames(2)


func _smallest_zone_at(level: Level, point: Vector2) -> StringName:
	var best: CameraZone = null
	for node: Node in level.find_children("*", "Area2D", true, false):
		var zone: CameraZone = node as CameraZone
		if zone != null and zone.has_point(point) and (best == null or zone.get_area() < best.get_area()):
			best = zone
	return StringName(best.name) if best != null else &""
