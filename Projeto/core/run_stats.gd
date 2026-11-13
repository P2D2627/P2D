class_name GameRunStats
extends Node

## The run's numbers, as the autoload RunStats, so the levels and the .dialogue lines reach them by
## that name: deaths by phase and by zone, time in each phase and lines skipped. It only exposes a
## RunRecord, where the rules and their tests are, and remembers which level and phase the man is
## in, so a line can ask "how often did he die here" with no arguments. It lives apart from
## GameState because a death puts GameState back as it was at the last save, and a death must
## count. Nothing here touches the moral record.

## He died; zone is where, as RunRecord names it.
signal death_recorded(phase: int, zone: StringName)
## He moved on to phase, in the level he is in.
signal phase_changed(phase: int)

var _record: RunRecord = RunRecord.new()
## The level he is in, as its Level names itself; empty outside a level.
var _level: StringName = &""
## The phase of that level he is in, from 1.
var _phase: int = 1


## He is now in phase of level. Levels call it as they start and as a phase starts.
func enter(level: StringName, phase: int) -> void:
	var changed: bool = level != _level or phase != _phase
	_level = level
	_phase = maxi(phase, 1)
	if changed:
		phase_changed.emit(_phase)


func get_level() -> StringName:
	return _level


func get_phase() -> int:
	return _phase


## He died inside zone of the level and phase he is in.
func record_death(zone: StringName) -> void:
	_record.record_death(_level, _phase, zone)
	death_recorded.emit(_phase, zone)


## He spent seconds more in the phase he is in.
func add_time(seconds: float) -> void:
	_record.add_time(_level, _phase, seconds)


## He skipped count lines by holding the key.
func record_skip(count: int) -> void:
	_record.record_skip(count)


## Deaths in phase of the level he is in; in the phase he is in when phase is 0.
func deaths_in_phase(phase: int = 0) -> int:
	return _record.deaths_in_phase(_level, phase if phase > 0 else _phase)


## Deaths in all the phases of the level he is in.
func deaths_in_level() -> int:
	return _record.deaths_in_level(_level)


func total_deaths() -> int:
	return _record.total_deaths()


## How many times he died where he died last.
func same_spot_deaths() -> int:
	return _record.same_spot_deaths()


func last_zone() -> StringName:
	return _record.last_zone()


## The zone of the level he is in where he died most.
func deadliest_zone() -> StringName:
	return _record.deadliest_zone(_level)


func deaths_in_zone(zone: StringName) -> int:
	return _record.deaths_in_zone(_level, zone)


## Seconds in phase of the level he is in; in the phase he is in when phase is 0.
func phase_seconds(phase: int = 0) -> float:
	return _record.phase_seconds(_level, phase if phase > 0 else _phase)


## Whole minutes in the phase he is in, for the lines.
func phase_minutes() -> int:
	return floori(phase_seconds() / 60.0)


func get_skipped_lines() -> int:
	return _record.get_skipped_lines()


## Back to an empty run, for a new game.
func reset() -> void:
	_record.reset()
	_level = &""
	_phase = 1


## Everything counted, as plain values a save can keep.
func to_save() -> Dictionary:
	return _record.to_save()


## Puts back what to_save() gave.
func from_save(data: Dictionary) -> void:
	_record.from_save(data)
