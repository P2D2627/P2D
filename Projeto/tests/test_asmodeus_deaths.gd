# Checks Lust's asmodeus_deaths with the real RunStats, about the zone whose offer is being made.
# After five minutes trying to get past that zone, she says how many minutes; after three deaths
# in it, she says how many, with the number; with neither, she says the part was hard. When his
# deaths brought her before, she says she asked before; the first time, she does not. Each way she
# presents the shortcut and offers the four answers: two accept it and two refuse it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus_deaths.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const CUE: String = "asmodeus_deaths"
const SHORTCUT: StringName = &"lust_shortcut"
const ANSWERS: int = 4
const ZONE: StringName = &"pit"
const MINUTES_LINE: String = "5 minutes on this one stretch, darling. I watched every one."
const DEATHS_LINE: String = "3 times, right here. I counted. Try not to give me another."
const PLAIN_LINE: String = "This part was hard, wasn't it? Try not to die here again."
const ASKED_BEFORE_LINE: String = "I did ask you before. The offer still stands."
## Lines read from one cue before giving up, in case a jump loops.
const MAX_LINES: int = 20
## Deaths at most, in fresh zones, to bring a second offer.
const MAX_DEATHS: int = 40

var _stats: GameRunStats
var _offers: GameOffers


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	_stats = root.get_node(^"RunStats") as GameRunStats
	_offers = root.get_node(^"Offers") as GameOffers
	var results: Array[bool] = []
	results.append(await _five_minutes_in_the_zone_are_counted())
	results.append(await _three_deaths_in_the_zone_are_counted())
	results.append(await _otherwise_the_part_was_hard())
	results.append(await _asked_before_she_says_so())
	_stats.reset()
	_offers.clear()
	finish(results)


func _five_minutes_in_the_zone_are_counted() -> bool:
	_start()
	_stats.add_time(300.0, ZONE)
	return await _check("five minutes in the zone", MINUTES_LINE, false)


func _three_deaths_in_the_zone_are_counted() -> bool:
	_start()
	for death: int in 3:
		_stats.record_death(ZONE)
	return await _check("three deaths in the zone", DEATHS_LINE, false)


func _otherwise_the_part_was_hard() -> bool:
	_start()
	_stats.record_death(ZONE)
	return await _check("one death", PLAIN_LINE, false)


## Deaths, each in a zone of its own, until his deaths brought two offers.
func _asked_before_she_says_so() -> bool:
	_start()
	var death: int = 0
	while _stats.death_offers_made() < 2 and death < MAX_DEATHS:
		_stats.record_death(StringName("zone_%d" % death))
		death += 1
	return await _check("a second offer", PLAIN_LINE, true)


## A new run in phase 2 of a level, with the offer being made at ZONE.
func _start() -> void:
	_stats.reset()
	_stats.enter(&"a_level", 2)
	_stats.begin_death_offer(ZONE)


## Whether the cue opens with expected, by Asmodeus, says she asked before only when asked_before,
## presents the shortcut and ends on four answers.
func _check(what: String, expected: String, asked_before: bool) -> bool:
	_offers.clear()
	var line: DialogueLine = await LUST.get_next_dialogue_line(CUE, [])
	var first: String = line.text if line != null else "none"
	var speaker: String = line.character if line != null else "none"
	var said_asked: bool = false
	var read: int = 0
	while line != null and line.responses.is_empty() and read < MAX_LINES:
		said_asked = said_asked or line.text == ASKED_BEFORE_LINE
		line = await LUST.get_next_dialogue_line(line.next_id, [])
		read += 1
	var answers: int = line.responses.size() if line != null else 0
	var presented: bool = _offers.last_presented != null and _offers.last_presented.id == SHORTCUT
	return report(first == expected and speaker == "Asmodeus" and said_asked == asked_before
			and answers == ANSWERS and presented,
			"after %s, Asmodeus opens with \"%s\", says she asked before %s, presents the shortcut %s, %d answers"
			% [what, first, said_asked, presented, answers])
