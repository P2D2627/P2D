# Checks RunRecord on its own, without the autoload. A new record counts nothing. Deaths count by
# phase and by zone, apart for each level, so level 2's phase 1 does not add to level 1's. The
# same spot is the zone and what killed him last: each strip of spikes on its own, the dogs as one
# pack, so two strips, or spikes and a demon, in one zone are two; the deadliest zone is the one
# with most deaths, and on a tie the one named first. Time adds up by phase, and bad times change
# nothing. Skipped lines add up. A save keeps everything and puts it back, a broken save counts as
# nothing, and reset() empties it all. Three warnings are printed on purpose: deaths with no level,
# no zone and phase 0.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_run_record.gd
extends "res://tests/support/player_test.gd"

const LUST: StringName = &"lust"
const GLUTTONY: StringName = &"gluttony"
const TOLERANCE: float = 0.0001


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_a_new_record_counts_nothing())
	results.append(_deaths_count_by_phase_and_level())
	results.append(_bad_deaths_change_nothing())
	results.append(_the_same_spot_is_the_last_zone())
	results.append(_the_same_spot_is_the_same_zone_and_cause())
	results.append(_each_strip_of_spikes_is_a_spot_and_the_dogs_one())
	results.append(_the_deadliest_zone_breaks_ties_by_name())
	results.append(_time_adds_up_by_phase())
	results.append(_skipped_lines_add_up())
	results.append(_a_save_puts_everything_back())
	results.append(_a_broken_save_counts_nothing())
	results.append(_reset_empties_everything())
	finish(results)


func _a_new_record_counts_nothing() -> bool:
	var record: RunRecord = RunRecord.new()
	return report(record.total_deaths() == 0 and record.same_spot_deaths() == 0
			and record.last_zone().is_empty() and record.deadliest_zone(LUST).is_empty()
			and record.phase_seconds(LUST, 1) == 0.0 and record.get_skipped_lines() == 0,
			"a new record counts nothing")


func _deaths_count_by_phase_and_level() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 1, &"hall")
	record.record_death(LUST, 2, &"pit")
	record.record_death(LUST, 2, &"pit")
	record.record_death(GLUTTONY, 1, &"table")
	var passed: bool = (record.deaths_in_phase(LUST, 1) == 1 and record.deaths_in_phase(LUST, 2) == 2
			and record.deaths_in_phase(GLUTTONY, 1) == 1 and record.deaths_in_level(LUST) == 3
			and record.deaths_in_level(GLUTTONY) == 1 and record.total_deaths() == 4
			and record.deaths_in_zone(LUST, &"pit") == 2 and record.deaths_in_zone(GLUTTONY, &"pit") == 0)
	return report(passed, "deaths count by phase, zone and level (lust %d, gluttony %d, total %d)"
			% [record.deaths_in_level(LUST), record.deaths_in_level(GLUTTONY), record.total_deaths()])


func _bad_deaths_change_nothing() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(&"", 1, &"hall")
	record.record_death(LUST, 1, &"")
	record.record_death(LUST, 0, &"hall")
	return report(record.total_deaths() == 0 and record.last_zone().is_empty(),
			"a death with no level, no zone or phase 0 changes nothing")


func _the_same_spot_is_the_last_zone() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 2, &"pit")
	record.record_death(LUST, 2, &"pit")
	record.record_death(LUST, 2, &"pit")
	var after_pit: int = record.same_spot_deaths()
	record.record_death(LUST, 2, &"ledge")
	return report(after_pit == 3 and record.same_spot_deaths() == 1 and record.last_zone() == &"ledge",
			"the same spot is the last zone (3 in the pit, then %d on the ledge)" % record.same_spot_deaths())


## Spikes and a demon in one zone are two spots: the same spot is the same zone and the same cause.
## The zone still counts both, each cause counts apart, and a death with no cause counts as unknown.
## A save keeps the spots.
func _the_same_spot_is_the_same_zone_and_cause() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 2, &"pit", &"spikes")
	record.record_death(LUST, 2, &"pit", &"spikes")
	var after_spikes: int = record.same_spot_deaths()
	record.record_death(LUST, 2, &"pit", &"demon")
	var after_demon: int = record.same_spot_deaths()
	var last: StringName = record.last_cause()
	record.record_death(LUST, 2, &"pit", &"")
	var unknown: bool = record.last_cause() == Player.UNKNOWN_CAUSE
	var copy: RunRecord = RunRecord.new()
	copy.from_save(record.to_save())
	var kept: bool = (copy.deaths_in_spot(LUST, &"pit", &"spikes") == 2
			and copy.same_spot_deaths() == 1 and copy.last_cause() == Player.UNKNOWN_CAUSE)
	return report(after_spikes == 2 and after_demon == 1 and last == &"demon" and unknown
			and record.deaths_in_zone(LUST, &"pit") == 4
			and record.deaths_of_cause(LUST, &"spikes") == 2
			and record.deaths_of_cause(LUST, &"demon") == 1 and kept,
			("same spot, same cause: 2 on the spikes, then %d by the demon (%s); 4 in the pit; "
			+ "no cause is unknown %s; kept by a save %s") % [after_demon, last, unknown, kept])


## Two strips of spikes in one zone are two spots, since one jump is harder than the other; the dogs
## are one spot whichever of them held him, as a pack. Both strips still count as spikes.
func _each_strip_of_spikes_is_a_spot_and_the_dogs_one() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 2, &"pit", &"spikes", &"Spikes2")
	record.record_death(LUST, 2, &"pit", &"spikes", &"Spikes2")
	record.record_death(LUST, 2, &"pit", &"spikes", &"Spikes1")
	var on_strip_1: int = record.same_spot_deaths()
	record.record_death(LUST, 2, &"pit", &"spikes", &"Spikes2")
	var on_strip_2: int = record.same_spot_deaths()
	record.record_death(LUST, 2, &"pit", &"demon")
	record.record_death(LUST, 2, &"pit", &"demon")
	var dogs: int = record.same_spot_deaths()
	return report(on_strip_1 == 1 and on_strip_2 == 3 and dogs == 2
			and record.deaths_of_cause(LUST, &"spikes") == 4 and record.last_cause() == &"demon"
			and record.deaths_in_spot(LUST, &"pit", &"Spikes2") == 3,
			("each strip a spot: Spikes1 %d, Spikes2 %d, the dogs %d; spikes in all %d, last %s")
			% [on_strip_1, on_strip_2, dogs, record.deaths_of_cause(LUST, &"spikes"),
			record.last_cause()])


func _the_deadliest_zone_breaks_ties_by_name() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 1, &"zeta")
	record.record_death(LUST, 1, &"alpha")
	var tie: StringName = record.deadliest_zone(LUST)
	record.record_death(LUST, 1, &"zeta")
	record.record_death(GLUTTONY, 1, &"alpha")
	record.record_death(GLUTTONY, 1, &"alpha")
	return report(tie == &"alpha" and record.deadliest_zone(LUST) == &"zeta"
			and record.deadliest_zone(GLUTTONY) == &"alpha",
			"the deadliest zone wins, ties go to the first name (%s, then %s)"
			% [tie, record.deadliest_zone(LUST)])


func _time_adds_up_by_phase() -> bool:
	var record: RunRecord = RunRecord.new()
	record.add_time(LUST, 1, 1.5)
	record.add_time(LUST, 1, 2.0)
	record.add_time(LUST, 2, 4.0)
	record.add_time(LUST, 1, -1.0)
	record.add_time(LUST, 1, INF)
	record.add_time(LUST, 1, NAN)
	record.add_time(LUST, 0, 9.0)
	return report(absf(record.phase_seconds(LUST, 1) - 3.5) < TOLERANCE
			and absf(record.phase_seconds(LUST, 2) - 4.0) < TOLERANCE,
			"time adds up by phase, and bad times change nothing (%.2f s, %.2f s)"
			% [record.phase_seconds(LUST, 1), record.phase_seconds(LUST, 2)])


func _skipped_lines_add_up() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_skip(3)
	record.record_skip(0)
	record.record_skip(-2)
	record.record_skip(2)
	return report(record.get_skipped_lines() == 5, "skipped lines add up (%d)" % record.get_skipped_lines())


func _a_save_puts_everything_back() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 2, &"pit")
	record.record_death(LUST, 2, &"pit")
	record.add_time(LUST, 2, 12.5)
	record.record_skip(4)
	# Through text, as the save file keeps it.
	var data: Dictionary = str_to_var(var_to_str(record.to_save()))
	var loaded: RunRecord = RunRecord.new()
	loaded.from_save(data)
	return report(loaded.deaths_in_phase(LUST, 2) == 2 and loaded.same_spot_deaths() == 2
			and loaded.last_zone() == &"pit" and absf(loaded.phase_seconds(LUST, 2) - 12.5) < TOLERANCE
			and loaded.get_skipped_lines() == 4,
			"a save puts deaths, the last zone, time and skips back")


func _a_broken_save_counts_nothing() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 1, &"hall")
	record.from_save({"phase_deaths": "nope", "zone_deaths": {1: 2}, "phase_seconds": {"lust/1": "x"},
			"last_zone": 3, "skipped_lines": 1.5})
	return report(record.total_deaths() == 0 and record.same_spot_deaths() == 0
			and record.phase_seconds(LUST, 1) == 0.0 and record.get_skipped_lines() == 0,
			"a broken save counts as nothing")


func _reset_empties_everything() -> bool:
	var record: RunRecord = RunRecord.new()
	record.record_death(LUST, 1, &"hall")
	record.add_time(LUST, 1, 3.0)
	record.record_skip(2)
	record.reset()
	return report(record.total_deaths() == 0 and record.last_zone().is_empty()
			and record.phase_seconds(LUST, 1) == 0.0 and record.get_skipped_lines() == 0,
			"reset() empties everything")
