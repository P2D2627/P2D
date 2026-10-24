class_name MoralRecord
extends RefCounted

## The rules of the man's hidden moral record (#169), with no nodes, so they can be tested on their
## own; the autoload Moral only puts them where the lines and the offers can reach them. Everything
## he does adds to one total of points, by the values in MoralStats: each accepted temptation, each
## arrogant answer, and each offer he listened to for too long before refusing it. Two totals in
## the stats pick the stage, 0 to 2, that chooses how badly he speaks. Points never go down, so his
## speech never mends; only reset() starts over. Nothing here is ever shown on screen.

## The stage went up after something he did, or back to 0 on reset().
signal stage_changed(stage: int)

const HUMBLE: StringName = &"humble"
const ARROGANT: StringName = &"arrogant"
## How far below a threshold a total can be and still reach it: sums such as 0.7 + 0.1 come out a
## hair short of 0.8.
const POINTS_TOLERANCE: float = 0.0001

var _stats: MoralStats
## The temptations taken, each once, in the order he took them.
var _taken: Array[StringName] = []
var _humble_answers: int = 0
var _arrogant_answers: int = 0
## The longest he listened to each offer before refusing it, in seconds.
var _listening: Dictionary[StringName, float] = {}
## The stage after the last thing he did, to say when it changes.
var _stage: int = 0


## Starts an empty record, with the values in stats.
func _init(stats: MoralStats) -> void:
	assert(stats != null, "MoralRecord: give it the MoralStats to use.")
	_stats = stats


## He accepted the temptation id. One already taken does not count twice. An id missing from
## Temptation Points counts Unknown Temptation Points, with a warning.
func take_temptation(id: StringName) -> void:
	if id.is_empty():
		push_warning("MoralRecord: a temptation with no id was left out.")
		return
	if _taken.has(id):
		return
	if not _stats.temptation_points.has(id):
		push_warning("MoralRecord: temptation %s is not in Temptation Points, so it counts %s."
				% [id, _stats.unknown_temptation_points])
	_taken.append(id)
	_update_stage()


## He answered in tone, HUMBLE or ARROGANT. Any other tone changes nothing, with a warning.
func record_tone(tone: StringName) -> void:
	match tone:
		HUMBLE:
			_humble_answers += 1
		ARROGANT:
			_arrogant_answers += 1
			_update_stage()
		_:
			push_warning("MoralRecord: tone %s is neither humble nor arrogant, so it was left out."
					% tone)


## He refused offer_id after listening to it for seconds. Heard again, as after a restart, only the
## longest time counts. Negative, infinite or nan seconds change nothing, with a warning.
func record_listening(offer_id: StringName, seconds: float) -> void:
	if offer_id.is_empty() or not is_finite(seconds) or seconds < 0.0:
		push_warning("MoralRecord: listening to %s for %s s was left out." % [offer_id, seconds])
		return
	_listening[offer_id] = maxf(seconds, _listening.get(offer_id, 0.0))
	_update_stage()


## Whether he accepted the temptation id. An id missing from Temptation Points, likely mistyped in
## a line, says so with a warning.
func has_taken(id: StringName) -> bool:
	if not _stats.temptation_points.has(id):
		push_warning("MoralRecord: has_taken asks for %s, which is not in Temptation Points." % id)
	return _taken.has(id)


## 0 while his points are below Stage 1 Points, 2 from Stage 2 Points on, and 1 between.
func stage() -> int:
	var points: float = get_points() + POINTS_TOLERANCE
	if points >= maxf(_stats.stage_1_points, _stats.stage_2_points):
		return 2
	if points >= _stats.stage_1_points:
		return 1
	return 0


## The total of points, added up now from the stats, so a value tuned in the Remote tab counts at
## once.
func get_points() -> float:
	var points: float = _arrogant_answers * _stats.arrogant_answer_points
	for id: StringName in _taken:
		points += _stats.temptation_points.get(id, _stats.unknown_temptation_points)
	for seconds: float in _listening.values():
		points += clampf((seconds - _stats.listening_grace) * _stats.listening_points_per_second,
				0.0, _stats.most_listening_points)
	return points


## How many answers he gave in tone, HUMBLE or ARROGANT; 0 for any other. Humble answers add no
## points, but the judgment shows him the numbers of both.
func get_tone_count(tone: StringName) -> int:
	match tone:
		HUMBLE:
			return _humble_answers
		ARROGANT:
			return _arrogant_answers
	return 0


## The longest he listened to offer_id before refusing it, or 0 if he never did; for the judgment.
func get_listening_seconds(offer_id: StringName) -> float:
	return _listening.get(offer_id, 0.0)


## Back to an empty record, for a new game. Says stage_changed(0) if the stage was not 0.
func reset() -> void:
	_taken.clear()
	_humble_answers = 0
	_arrogant_answers = 0
	_listening.clear()
	_update_stage()


func _update_stage() -> void:
	var now: int = stage()
	if now != _stage:
		_stage = now
		stage_changed.emit(now)
