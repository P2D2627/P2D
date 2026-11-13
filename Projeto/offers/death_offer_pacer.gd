class_name DeathOfferPacer
extends RefCounted

## The rules of when a level's demon offers the shortcut again after the man keeps dying, with no
## nodes, so they can be tested on their own; RunStats feeds it every death. Deaths in a phase
## before First Phase With Offers add nothing: that phase is always played through. Each other
## death adds 1, plus Same Spot Bonus for each death he already had in that zone. When the pressure
## reaches the threshold, an offer becomes pending for the zone of that death, and the pressure goes
## back to 0. The first threshold is drawn between First Offer Min and Max; each next one is the
## last one's base times Gap Shrink, never below Min Gap, drawn within Gap Jitter of it. While an
## offer is pending, deaths add nothing: one offer at a time. Once he accepts, close() ends the
## offers for good. Nothing here is moral, nor ever shown.

## How far below the threshold the pressure can be and still reach it: sums such as 1.5 + 2.5 can
## come out a hair short.
const PRESSURE_TOLERANCE: float = 0.0001

var _stats: DeathOfferStats
var _rng: RandomNumberGenerator
## Pressure since the last offer.
var _pressure: float = 0.0
## The pressure the next offer needs.
var _threshold: float = 0.0
## The next threshold's value before the jitter; it shrinks after each offer.
var _base: float = 0.0
## The zone an offer waits at; empty when none waits.
var _pending_zone: StringName = &""
var _offers_made: int = 0
var _closed: bool = false


## Starts with no pressure, drawing the first threshold with rng.
func _init(stats: DeathOfferStats, rng: RandomNumberGenerator) -> void:
	assert(stats != null, "DeathOfferPacer: give it the DeathOfferStats to use.")
	assert(rng != null, "DeathOfferPacer: give it a RandomNumberGenerator.")
	_stats = stats
	_rng = rng
	reset()


## He died in phase, inside zone, where he had already died deaths_before times. True when this
## death made an offer pending.
func record_death(phase: int, zone: StringName, deaths_before: int) -> bool:
	if _closed or has_pending() or phase < _stats.first_phase_with_offers or zone.is_empty():
		return false
	_pressure += 1.0 + _stats.same_spot_bonus * maxi(deaths_before, 0)
	if _pressure + PRESSURE_TOLERANCE < _threshold:
		return false
	_pending_zone = zone
	_pressure = 0.0
	_offers_made += 1
	_base = maxf(_base * _stats.gap_shrink, _stats.min_gap)
	_threshold = _draw(_base)
	return true


func has_pending() -> bool:
	return not _pending_zone.is_empty()


## The zone the pending offer waits at; empty when none waits.
func get_pending_zone() -> StringName:
	return _pending_zone


## The pending offer was made: it no longer waits. Gives back its zone.
func take_pending() -> StringName:
	var zone: StringName = _pending_zone
	_pending_zone = &""
	return zone


## He accepted: no offer comes again, and none waits.
func close() -> void:
	_closed = true
	_pending_zone = &""


func is_closed() -> bool:
	return _closed


func get_pressure() -> float:
	return _pressure


func get_threshold() -> float:
	return _threshold


func get_offers_made() -> int:
	return _offers_made


## Back to the start of a level: no pressure, nothing pending, open, a new first threshold.
func reset() -> void:
	_pressure = 0.0
	_pending_zone = &""
	_offers_made = 0
	_closed = false
	_base = _rng.randf_range(minf(_stats.first_offer_min, _stats.first_offer_max),
			maxf(_stats.first_offer_min, _stats.first_offer_max))
	_threshold = _base


## Everything it holds, as plain values a save can keep.
func to_save() -> Dictionary:
	return {
		"pressure": _pressure,
		"threshold": _threshold,
		"base": _base,
		"pending_zone": String(_pending_zone),
		"offers_made": _offers_made,
		"closed": _closed,
	}


## Puts back what to_save() gave. A save without a threshold keeps the one drawn now.
func from_save(data: Dictionary) -> void:
	reset()
	var pressure: Variant = data.get("pressure")
	_pressure = pressure if pressure is float else 0.0
	var threshold: Variant = data.get("threshold")
	if threshold is float and threshold > 0.0:
		_threshold = threshold
	var base: Variant = data.get("base")
	if base is float and base > 0.0:
		_base = base
	var pending: Variant = data.get("pending_zone")
	_pending_zone = StringName(pending) if pending is String else &""
	var made: Variant = data.get("offers_made")
	_offers_made = made if made is int else 0
	var closed: Variant = data.get("closed")
	_closed = closed if closed is bool else false


func _draw(base: float) -> float:
	var jitter: float = base * _stats.gap_jitter
	return maxf(_rng.randf_range(base - jitter, base + jitter), _stats.min_gap)
