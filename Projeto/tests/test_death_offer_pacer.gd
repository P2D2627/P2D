# Checks DeathOfferPacer on its own, on stats of its own, so tuning the game's file changes no case.
# Deaths in phase 1 never bring an offer, however many. With one death in each zone and no jitter,
# the first offer comes at the first threshold, and each next one after fewer deaths, down to Min
# Gap and never below. Dying in the same zone brings it sooner. Deaths count also while offers wait:
# the next threshold marks another zone, and each waits until its own is taken; a zone that waits
# is not marked again. Once closed, no offer comes again. A save puts back the pressure, the
# threshold and the waiting offers; reset() starts over. With jitter, the first threshold is drawn
# within First Offer Min and Max, differently for different seeds.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_death_offer_pacer.gd
extends "res://tests/support/player_test.gd"

const FIRST: float = 4.0
const SHRINK: float = 0.7
const MIN_GAP: float = 1.5
const SAME_SPOT: float = 0.5
## Deaths before giving up on an offer.
const MAX_DEATHS: int = 100
const SEEDS: int = 20


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_phase_1_never_brings_an_offer())
	results.append(_offers_come_ever_sooner_down_to_min_gap())
	results.append(_the_same_spot_brings_it_sooner())
	results.append(_deaths_count_while_offers_wait())
	results.append(_a_waiting_zone_is_not_marked_again())
	results.append(_closed_no_offer_comes_again())
	results.append(_a_save_puts_the_pressure_back())
	results.append(_the_first_threshold_is_drawn_within_its_range())
	finish(results)


func _stats(jitter: float = 0.0, first_min: float = FIRST, first_max: float = FIRST) -> DeathOfferStats:
	var stats: DeathOfferStats = DeathOfferStats.new()
	stats.first_phase_with_offers = 2
	stats.first_offer_min = first_min
	stats.first_offer_max = first_max
	stats.same_spot_bonus = SAME_SPOT
	stats.gap_shrink = SHRINK
	stats.min_gap = MIN_GAP
	stats.gap_jitter = jitter
	return stats


func _pacer(stats: DeathOfferStats = _stats(), rng_seed: int = 1) -> DeathOfferPacer:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	return DeathOfferPacer.new(stats, rng)


## Deaths in phase 2, each in a zone of its own, until an offer waits; -1 if none came.
func _deaths_to_an_offer(pacer: DeathOfferPacer, start: int) -> int:
	for death: int in MAX_DEATHS:
		if pacer.record_death(2, StringName("zone_%d" % (start + death)), 0):
			return death + 1
	return -1


func _phase_1_never_brings_an_offer() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	var any: bool = false
	for death: int in MAX_DEATHS:
		any = pacer.record_death(1, &"hall", death) or any
	return report(not any and not pacer.has_pending() and pacer.get_pressure() == 0.0,
			"%d deaths in phase 1 bring no offer and no pressure" % MAX_DEATHS)


func _offers_come_ever_sooner_down_to_min_gap() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	var gaps: Array[int] = []
	var zone: int = 0
	for offer: int in 6:
		var deaths: int = _deaths_to_an_offer(pacer, zone)
		zone += maxi(deaths, 0)
		gaps.append(deaths)
		pacer.take_pending()
	# Thresholds 4, 2.8, 1.96, then 1.5 from there: 4, 3, 2, 2, 2, 2 deaths.
	var expected: Array[int] = [4, 3, 2, 2, 2, 2]
	return report(gaps == expected and is_equal_approx(pacer.get_threshold(), MIN_GAP),
			"deaths to each offer %s (expected %s), threshold down to %.2f" % [gaps, expected,
			pacer.get_threshold()])


func _the_same_spot_brings_it_sooner() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	var deaths: int = 0
	var came: bool = false
	while not came and deaths < MAX_DEATHS:
		came = pacer.record_death(2, &"pit", deaths)
		deaths += 1
	# 1 + 1.5 + 2 = 4.5 reaches 4 on the third death; in fresh zones it takes four.
	return report(came and deaths == 3 and pacer.get_pending_zone() == &"pit",
			"in the same zone the offer comes on death %d (expected 3), at %s" % [deaths,
			pacer.get_pending_zone()])


## An offer waits at the first zone; deaths elsewhere still count, and reaching the next threshold
## marks that zone too. Both wait, in the order they were marked, each until its own is taken.
func _deaths_count_while_offers_wait() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	_deaths_to_an_offer(pacer, 0)
	var first: StringName = pacer.get_pending_zone()
	var counted: bool = false
	var deaths: int = 0
	var marked: bool = false
	while not marked and deaths < MAX_DEATHS:
		marked = pacer.record_death(2, &"elsewhere", 0)
		counted = counted or pacer.get_pressure() > 0.0
		deaths += 1
	# The second threshold is 2.8: three deaths at 1 each.
	var expected: Array[StringName] = [first, &"elsewhere"]
	var both: bool = pacer.get_pending_zones() == expected
	var at_elsewhere: bool = pacer.has_pending_at(&"elsewhere")
	var taken: StringName = pacer.take_pending(&"elsewhere")
	var first_still: bool = pacer.get_pending_zone() == first and not pacer.has_pending_at(&"elsewhere")
	var none_taken: StringName = pacer.take_pending(&"nowhere")
	pacer.take_pending(first)
	return report(counted and deaths == 3 and both and at_elsewhere and taken == &"elsewhere"
			and first_still and none_taken.is_empty() and not pacer.has_pending(),
			("while %s waits, deaths elsewhere count %s and mark it after %d (expected 3); both wait "
			+ "%s; taking elsewhere leaves %s waiting %s; nothing waits after both are taken %s")
			% [first, counted, deaths, both, first, first_still, not pacer.has_pending()])


## Dying again where an offer waits marks that zone no more, however often, though the pressure
## grows; the next death elsewhere then reaches the threshold and marks its zone.
func _a_waiting_zone_is_not_marked_again() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	_deaths_to_an_offer(pacer, 0)
	var zone: StringName = pacer.get_pending_zone()
	var again: bool = false
	for death: int in 10:
		again = pacer.record_death(2, zone, 0) or again
	var grew: bool = pacer.get_pressure() >= pacer.get_threshold()
	var once: bool = pacer.get_pending_zones().size() == 1
	var next: bool = pacer.record_death(2, &"elsewhere", 0) and pacer.has_pending_at(&"elsewhere")
	return report(not again and grew and once and next,
			("dying again at %s marks it no more %s, the pressure grows %s; the next death "
			+ "elsewhere marks it %s") % [zone, not again and once, grew, next])


func _closed_no_offer_comes_again() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	_deaths_to_an_offer(pacer, 0)
	pacer.close()
	var any: bool = _deaths_to_an_offer(pacer, 100) != -1
	return report(pacer.is_closed() and not any and not pacer.has_pending(),
			"once closed, nothing waits and no offer comes in %d deaths" % MAX_DEATHS)


func _a_save_puts_the_pressure_back() -> bool:
	var pacer: DeathOfferPacer = _pacer()
	_deaths_to_an_offer(pacer, 0)
	pacer.take_pending()
	pacer.record_death(2, &"a", 0)
	# Pressure 1 towards a threshold of 2.8, nothing waiting.
	var with_pressure: bool = _same_after_a_save(pacer) and pacer.get_pressure() > 0.0
	_deaths_to_an_offer(pacer, 50)
	# An offer waiting, the pressure back at 0.
	var with_offer: bool = _same_after_a_save(pacer) and pacer.has_pending()
	var loaded: DeathOfferPacer = _pacer(_stats(), 99)
	loaded.from_save(pacer.to_save())
	loaded.reset()
	var started_over: bool = (loaded.get_pressure() == 0.0 and not loaded.has_pending()
			and loaded.get_offers_made() == 0 and is_equal_approx(loaded.get_threshold(), FIRST))
	return report(with_pressure and with_offer and started_over,
			("a save puts back the pressure with nothing waiting %s, and an offer waiting %s; "
			+ "reset() starts over %s") % [with_pressure, with_offer, started_over])


## Whether a new pacer, given pacer's save through text, holds the same.
func _same_after_a_save(pacer: DeathOfferPacer) -> bool:
	var loaded: DeathOfferPacer = _pacer(_stats(), 99)
	loaded.from_save(str_to_var(var_to_str(pacer.to_save())))
	return (is_equal_approx(loaded.get_pressure(), pacer.get_pressure())
			and is_equal_approx(loaded.get_threshold(), pacer.get_threshold())
			and loaded.get_pending_zones() == pacer.get_pending_zones()
			and loaded.get_offers_made() == pacer.get_offers_made())


func _the_first_threshold_is_drawn_within_its_range() -> bool:
	var low: float = 4.0
	var high: float = 7.0
	var drawn: Array[float] = []
	var inside: bool = true
	for rng_seed: int in SEEDS:
		var threshold: float = _pacer(_stats(0.15, low, high), rng_seed).get_threshold()
		inside = inside and threshold >= low and threshold <= high
		if not drawn.has(threshold):
			drawn.append(threshold)
	return report(inside and drawn.size() > 1,
			"over %d seeds, the first threshold stays within %.1f to %.1f %s, with %d values"
			% [SEEDS, low, high, inside, drawn.size()])
