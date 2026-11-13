# Checks Lust's asmodeus_deaths with the real RunStats. After three deaths in the same zone, she
# says how many, with the number; after ten minutes in the phase, she says how many minutes; with
# neither, a plain line. Each way she presents the shortcut and offers the four answers: two accept
# it and two refuse it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus_deaths.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const CUE: String = "asmodeus_deaths"
const SHORTCUT: StringName = &"lust_shortcut"
const ANSWERS: int = 4
const SAME_SPOT_LINE: String = "3 times, darling. Same spot. Even I get bored of the same spot."
const MINUTES_LINE: String = "10 minutes on this stretch. My bed is right here, you know."
const PLAIN_LINE: String = "Down again? You fall so prettily."
## Lines read from one cue before giving up, in case a jump loops.
const MAX_LINES: int = 20

var _stats: GameRunStats
var _offers: GameOffers


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	_stats = root.get_node(^"RunStats") as GameRunStats
	_offers = root.get_node(^"Offers") as GameOffers
	var results: Array[bool] = []
	results.append(await _three_deaths_in_one_spot_are_counted())
	results.append(await _ten_minutes_are_counted())
	results.append(await _otherwise_a_plain_line())
	_stats.reset()
	_offers.clear()
	finish(results)


func _three_deaths_in_one_spot_are_counted() -> bool:
	_stats.reset()
	_stats.enter(&"a_level", 2)
	for death: int in 3:
		_stats.record_death(&"pit")
	return await _check("three deaths in the pit", SAME_SPOT_LINE)


func _ten_minutes_are_counted() -> bool:
	_stats.reset()
	_stats.enter(&"a_level", 2)
	_stats.add_time(600.0)
	return await _check("ten minutes in the phase", MINUTES_LINE)


func _otherwise_a_plain_line() -> bool:
	_stats.reset()
	_stats.enter(&"a_level", 2)
	_stats.record_death(&"pit")
	return await _check("one death", PLAIN_LINE)


## Whether the cue opens with expected, by Asmodeus, presents the shortcut and ends on four answers.
func _check(what: String, expected: String) -> bool:
	_offers.clear()
	var line: DialogueLine = await LUST.get_next_dialogue_line(CUE, [])
	var first: String = line.text if line != null else "none"
	var speaker: String = line.character if line != null else "none"
	var read: int = 0
	while line != null and line.responses.is_empty() and read < MAX_LINES:
		line = await LUST.get_next_dialogue_line(line.next_id, [])
		read += 1
	var answers: int = line.responses.size() if line != null else 0
	var presented: bool = _offers.last_presented != null and _offers.last_presented.id == SHORTCUT
	return report(first == expected and speaker == "Asmodeus" and answers == ANSWERS and presented,
			"after %s, Asmodeus opens with \"%s\", presents the shortcut %s, %d answers"
			% [what, first, presented, answers])
