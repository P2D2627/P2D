class_name GameRunStats
extends Node

## The run's numbers, as the autoload RunStats, so the levels and the .dialogue lines reach them by
## that name: deaths by phase and by zone, time in each phase and lines skipped. It only exposes a
## RunRecord, where the rules and their tests are, and remembers which level and phase the man is
## in, so a line can ask "how often did he die here" with no arguments. It lives apart from
## GameState because a death puts GameState back as it was at the last save, and a death must
## count. Nothing here touches the moral record.
## It also keeps the DeathOfferPacer of the level he is in, fed with every death, so the level's
## demon knows when to offer the shortcut again; a new level starts it over.

## He died; zone is where, as RunRecord names it.
signal death_recorded(phase: int, zone: StringName)
## He moved on to phase, in the level he is in.
signal phase_changed(phase: int)
## His deaths made a shortcut offer wait for him at zone.
signal death_offer_due(zone: StringName)

const DEATH_OFFER_STATS: DeathOfferStats = preload("res://offers/death_offer_stats.tres")
const LOG_HEADER: String = "time,level,phase,zone,x,y,zone_deaths,offer_due"

## The log every new RunStats writes the deaths to, for playtests; empty keeps none.
## tests/support/base_test.gd empties it, so the tests never write to the playtests' log.
static var default_log_path: String = "user://deaths_log.csv"

var _record: RunRecord = RunRecord.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pacer: DeathOfferPacer = DeathOfferPacer.new(DEATH_OFFER_STATS, _rng)
## The level he is in, as its Level names itself; empty outside a level.
var _level: StringName = &""
## The phase of that level he is in, from 1.
var _phase: int = 1
var _log_path: String = default_log_path


func _init() -> void:
	_rng.randomize()
	_pacer.reset()


## He is now in phase of level. Levels call it as they start and as a phase starts.
func enter(level: StringName, phase: int) -> void:
	var changed: bool = level != _level or phase != _phase
	if not _level.is_empty() and level != _level:
		_pacer.reset()
	_level = level
	_phase = maxi(phase, 1)
	if changed:
		phase_changed.emit(_phase)


func get_level() -> StringName:
	return _level


func get_phase() -> int:
	return _phase


## He died at point, inside zone of the level and phase he is in. Each death adds a line to a log
## on disk, for playtests, with whether it brought a shortcut offer.
func record_death(zone: StringName, point: Vector2 = Vector2.ZERO) -> void:
	var deaths_before: int = _record.deaths_in_zone(_level, zone)
	_record.record_death(_level, _phase, zone)
	death_recorded.emit(_phase, zone)
	var offer_due: bool = _pacer.record_death(_phase, zone, deaths_before)
	CsvLog.append(_log_path, LOG_HEADER, "%s,%s,%d,%s,%.0f,%.0f,%d,%s" % [
			Time.get_datetime_string_from_system(), _level, _phase, zone, point.x, point.y,
			_record.deaths_in_zone(_level, zone), offer_due])
	if offer_due:
		death_offer_due.emit(zone)


## Where the deaths are logged, as CSV; empty keeps none.
func set_log_path(path: String) -> void:
	_log_path = path


## Whether a shortcut offer waits for him, after his deaths.
func has_death_offer() -> bool:
	return _pacer.has_pending()


## The zone the waiting offer is at; empty when none waits.
func get_death_offer_zone() -> StringName:
	return _pacer.get_pending_zone()


## The waiting offer is being made: it no longer waits.
func take_death_offer() -> StringName:
	return _pacer.take_pending()


## He took the shortcut: no offer comes again in this level.
func close_death_offers() -> void:
	_pacer.close()


## The pacer itself, for the debug overlay.
func get_death_offer_pacer() -> DeathOfferPacer:
	return _pacer


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
	_pacer.reset()
	_level = &""
	_phase = 1


## Everything counted, as plain values a save can keep.
func to_save() -> Dictionary:
	var data: Dictionary = _record.to_save()
	data["death_offers"] = _pacer.to_save()
	data["level"] = String(_level)
	return data


## Puts back what to_save() gave.
func from_save(data: Dictionary) -> void:
	_record.from_save(data)
	var death_offers: Variant = data.get("death_offers")
	_pacer.from_save(death_offers if death_offers is Dictionary else {})
	var level: Variant = data.get("level")
	_level = StringName(level) if level is String else &""
