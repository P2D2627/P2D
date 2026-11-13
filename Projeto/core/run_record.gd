class_name RunRecord
extends RefCounted

## The rules of the run's numbers, with no nodes, so they can be tested on their own; the autoload
## RunStats only puts them where the levels and the .dialogue lines can reach them. It counts the
## man's deaths in each phase of each level and in each zone, the time spent in each phase and the
## lines he skipped. None of it is moral: the moral record counts only what he decides. A death
## does not undo it, as it undoes GameState, so a death is never forgotten; only reset() starts
## over. Nothing here is shown while he plays: the numbers wait for the judgment.

## Joins a level's id and a phase, or a level's id and a zone, into one key.
const KEY_FORMAT: String = "%s/%s"

## Deaths in each phase, by "level/phase".
var _phase_deaths: Dictionary[String, int] = {}
## Deaths in each zone, by "level/zone".
var _zone_deaths: Dictionary[String, int] = {}
## Seconds spent in each phase, by "level/phase".
var _phase_seconds: Dictionary[String, float] = {}
## The "level/zone" of the last death; empty before the first.
var _last_zone: String = ""
## Lines skipped by holding the key, in all.
var _skipped_lines: int = 0


## He died in phase of level, inside zone. An empty level or zone, or a phase below 1, changes
## nothing, with a warning.
func record_death(level: StringName, phase: int, zone: StringName) -> void:
	if level.is_empty() or zone.is_empty() or phase < 1:
		push_warning("RunRecord: a death in level %s, phase %d, zone %s was left out."
				% [level, phase, zone])
		return
	var phase_key: String = _key(level, phase)
	_phase_deaths[phase_key] = _phase_deaths.get(phase_key, 0) + 1
	_last_zone = _key(level, zone)
	_zone_deaths[_last_zone] = _zone_deaths.get(_last_zone, 0) + 1


## He spent seconds more in phase of level. Negative, infinite or nan seconds change nothing.
func add_time(level: StringName, phase: int, seconds: float) -> void:
	if level.is_empty() or phase < 1 or not is_finite(seconds) or seconds < 0.0:
		return
	var key: String = _key(level, phase)
	_phase_seconds[key] = _phase_seconds.get(key, 0.0) + seconds


## He skipped count lines by holding the key. Zero or less changes nothing.
func record_skip(count: int) -> void:
	if count > 0:
		_skipped_lines += count


func deaths_in_phase(level: StringName, phase: int) -> int:
	return _phase_deaths.get(_key(level, phase), 0)


## Every death in level, in all its phases.
func deaths_in_level(level: StringName) -> int:
	var deaths: int = 0
	var prefix: String = _key(level, "")
	for key: String in _phase_deaths:
		if key.begins_with(prefix):
			deaths += _phase_deaths[key]
	return deaths


func deaths_in_zone(level: StringName, zone: StringName) -> int:
	return _zone_deaths.get(_key(level, zone), 0)


func total_deaths() -> int:
	var deaths: int = 0
	for count: int in _phase_deaths.values():
		deaths += count
	return deaths


## How many times he died in the zone of his last death, that one included; 0 before the first.
func same_spot_deaths() -> int:
	return _zone_deaths.get(_last_zone, 0)


## The zone of his last death, without the level; empty before the first.
func last_zone() -> StringName:
	return StringName(_last_zone.get_slice("/", 1)) if not _last_zone.is_empty() else &""


## The zone of level where he died most, and on a tie the one named first; empty if he never died
## there.
func deadliest_zone(level: StringName) -> StringName:
	var prefix: String = _key(level, "")
	var keys: Array[String] = []
	for key: String in _zone_deaths:
		if key.begins_with(prefix):
			keys.append(key)
	keys.sort()
	var best: String = ""
	for key: String in keys:
		if best.is_empty() or _zone_deaths[key] > _zone_deaths[best]:
			best = key
	return StringName(best.trim_prefix(prefix)) if not best.is_empty() else &""


func phase_seconds(level: StringName, phase: int) -> float:
	return _phase_seconds.get(_key(level, phase), 0.0)


func get_skipped_lines() -> int:
	return _skipped_lines


## Back to an empty run, for a new game.
func reset() -> void:
	_phase_deaths.clear()
	_zone_deaths.clear()
	_phase_seconds.clear()
	_last_zone = ""
	_skipped_lines = 0


## Everything counted, as plain values a save can keep.
func to_save() -> Dictionary:
	return {
		"phase_deaths": _phase_deaths.duplicate(),
		"zone_deaths": _zone_deaths.duplicate(),
		"phase_seconds": _phase_seconds.duplicate(),
		"last_zone": _last_zone,
		"skipped_lines": _skipped_lines,
	}


## Puts back what to_save() gave, in place of what was counted. Anything missing or of the wrong
## type counts as nothing.
func from_save(data: Dictionary) -> void:
	reset()
	var phase_deaths: Variant = data.get("phase_deaths")
	if phase_deaths is Dictionary:
		for key: Variant in phase_deaths:
			if key is String and phase_deaths[key] is int:
				_phase_deaths[key] = phase_deaths[key]
	var zone_deaths: Variant = data.get("zone_deaths")
	if zone_deaths is Dictionary:
		for key: Variant in zone_deaths:
			if key is String and zone_deaths[key] is int:
				_zone_deaths[key] = zone_deaths[key]
	var phase_seconds_saved: Variant = data.get("phase_seconds")
	if phase_seconds_saved is Dictionary:
		for key: Variant in phase_seconds_saved:
			if key is String and phase_seconds_saved[key] is float:
				_phase_seconds[key] = phase_seconds_saved[key]
	var last: Variant = data.get("last_zone")
	_last_zone = last if last is String else ""
	var skipped: Variant = data.get("skipped_lines")
	_skipped_lines = skipped if skipped is int else 0


func _key(level: StringName, part: Variant) -> String:
	return KEY_FORMAT % [level, part]
