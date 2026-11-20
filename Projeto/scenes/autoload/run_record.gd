class_name RunRecord
extends RefCounted

## The rules of the run's numbers, with no nodes, so they can be tested on their own; the autoload
## RunStats only puts them where the levels and the .dialogue lines can reach them. It counts the
## man's deaths in each phase of each level, in each zone and of each cause (spikes, the demon that
## held him), the time spent in each phase and the
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
## Seconds spent in each zone, by "level/zone".
var _zone_seconds: Dictionary[String, float] = {}
## Deaths at each spot of each zone, by "level/zone/spot". The spot is what killed him: one strip of
## spikes by its name, as Spikes2, since one jump is harder than another; the dogs by their kind, as
## a pack, whichever of them it was. Spikes 1 and 2, or the spikes and the dogs, of one zone are two
## spots.
var _spot_deaths: Dictionary[String, int] = {}
## Deaths of each cause, by "level/cause".
var _cause_deaths: Dictionary[String, int] = {}
## The "level/zone" of the last death; empty before the first.
var _last_zone: String = ""
## The "level/zone/spot" of the last death; empty before the first.
var _last_spot: String = ""
## What killed him last, as spikes or demon; empty before the first death.
var _last_cause: String = ""
## Lines skipped by holding the key, in all.
var _skipped_lines: int = 0


## He died in phase of level, inside zone, of cause (as spikes, or the demon that held him), on
## source, the one thing that killed him when which one matters (the strip of spikes, as Spikes2);
## an empty source makes the spot the cause, as for the dogs, a pack. An empty level or zone, or a
## phase below 1, changes nothing, with a warning; an empty cause counts as unknown.
func record_death(level: StringName, phase: int, zone: StringName,
		cause: StringName = Player.UNKNOWN_CAUSE, source: StringName = &"") -> void:
	if level.is_empty() or zone.is_empty() or phase < 1:
		push_warning("RunRecord: a death in level %s, phase %d, zone %s was left out."
				% [level, phase, zone])
		return
	if cause.is_empty():
		cause = Player.UNKNOWN_CAUSE
	var phase_key: String = _key(level, phase)
	_phase_deaths[phase_key] = _phase_deaths.get(phase_key, 0) + 1
	_last_zone = _key(level, zone)
	_zone_deaths[_last_zone] = _zone_deaths.get(_last_zone, 0) + 1
	_last_cause = cause
	_last_spot = _key(_last_zone, spot_of(cause, source))
	_spot_deaths[_last_spot] = _spot_deaths.get(_last_spot, 0) + 1
	var cause_key: String = _key(level, cause)
	_cause_deaths[cause_key] = _cause_deaths.get(cause_key, 0) + 1


## He spent seconds more in phase of level. Negative, infinite or nan seconds change nothing.
func add_time(level: StringName, phase: int, seconds: float) -> void:
	if level.is_empty() or phase < 1 or not is_finite(seconds) or seconds < 0.0:
		return
	var key: String = _key(level, phase)
	_phase_seconds[key] = _phase_seconds.get(key, 0.0) + seconds


## He spent seconds more in zone of level, trying to get past it. Bad seconds, or an empty level or
## zone, change nothing.
func add_zone_time(level: StringName, zone: StringName, seconds: float) -> void:
	if level.is_empty() or zone.is_empty() or not is_finite(seconds) or seconds < 0.0:
		return
	var key: String = _key(level, zone)
	_zone_seconds[key] = _zone_seconds.get(key, 0.0) + seconds


## Seconds he spent in zone of level, in all.
func zone_seconds(level: StringName, zone: StringName) -> float:
	return _zone_seconds.get(_key(level, zone), 0.0)


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


## How many times he died where and of what he died last, that one included; 0 before the first.
## Another strip of spikes, or another cause, in the same zone is another spot.
func same_spot_deaths() -> int:
	return _spot_deaths.get(_last_spot, 0)


## Deaths at spot inside zone of level; spot as spot_of() makes it.
func deaths_in_spot(level: StringName, zone: StringName, spot: StringName) -> int:
	return _spot_deaths.get(_key(_key(level, zone), spot), 0)


## The spot a death of cause on source is at: source, when one is given, or else cause.
static func spot_of(cause: StringName, source: StringName) -> StringName:
	return source if not source.is_empty() else cause


## Deaths of cause in level, in all its zones.
func deaths_of_cause(level: StringName, cause: StringName) -> int:
	return _cause_deaths.get(_key(level, cause), 0)


## What killed him last, as spikes or demon; empty before the first death.
func last_cause() -> StringName:
	return StringName(_last_cause)


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


## All the time of the run, every level and phase.
func total_seconds() -> float:
	var seconds: float = 0.0
	for phase_time: float in _phase_seconds.values():
		seconds += phase_time
	return seconds


func get_skipped_lines() -> int:
	return _skipped_lines


## Back to an empty run, for a new game.
func reset() -> void:
	_phase_deaths.clear()
	_zone_deaths.clear()
	_phase_seconds.clear()
	_zone_seconds.clear()
	_spot_deaths.clear()
	_cause_deaths.clear()
	_last_zone = ""
	_last_spot = ""
	_last_cause = ""
	_skipped_lines = 0


## Everything counted, as plain values a save can keep.
func to_save() -> Dictionary:
	return {
		"phase_deaths": _phase_deaths.duplicate(),
		"zone_deaths": _zone_deaths.duplicate(),
		"phase_seconds": _phase_seconds.duplicate(),
		"zone_seconds": _zone_seconds.duplicate(),
		"spot_deaths": _spot_deaths.duplicate(),
		"cause_deaths": _cause_deaths.duplicate(),
		"last_zone": _last_zone,
		"last_spot": _last_spot,
		"last_cause": _last_cause,
		"skipped_lines": _skipped_lines,
	}


## Puts back what to_save() gave, in place of what was counted. Anything missing or of the wrong
## type counts as nothing.
func from_save(data: Dictionary) -> void:
	reset()
	_load_counts(data.get("phase_deaths"), _phase_deaths)
	_load_counts(data.get("zone_deaths"), _zone_deaths)
	_load_counts(data.get("spot_deaths"), _spot_deaths)
	_load_counts(data.get("cause_deaths"), _cause_deaths)
	var spot: Variant = data.get("last_spot")
	_last_spot = spot if spot is String else ""
	var cause: Variant = data.get("last_cause")
	_last_cause = cause if cause is String else ""
	_load_seconds(data.get("phase_seconds"), _phase_seconds)
	_load_seconds(data.get("zone_seconds"), _zone_seconds)
	var last: Variant = data.get("last_zone")
	_last_zone = last if last is String else ""
	var skipped: Variant = data.get("skipped_lines")
	_skipped_lines = skipped if skipped is int else 0


## Copies each String key with an int count of saved into counts.
func _load_counts(saved: Variant, counts: Dictionary[String, int]) -> void:
	if not saved is Dictionary:
		return
	for key: Variant in saved:
		if key is String and saved[key] is int:
			counts[key] = saved[key]


## Copies each String key with a float of saved into seconds.
func _load_seconds(saved: Variant, seconds: Dictionary[String, float]) -> void:
	if not saved is Dictionary:
		return
	for key: Variant in saved:
		if key is String and saved[key] is float:
			seconds[key] = saved[key]


func _key(level: Variant, part: Variant) -> String:
	return KEY_FORMAT % [level, part]
