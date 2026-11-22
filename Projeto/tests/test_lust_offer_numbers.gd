# Checks the run's numbers Asmodeus says in Lust's offers (#277), with the real RunStats. In
# asmodeus_offer she counts the falls of the whole level; in asmodeus_second_offer, the falls of
# phase 2, the climb that brought the soul to her, even though the level is already in phase 3
# when she talks. With fewer than two falls, she says no number. A stand-in game state with no
# crucifix keeps the cross's choice out of the way.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_offer_numbers.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const LEVEL: StringName = &"a_level"
const ZONE: StringName = &"pit"
## The number in words, as NumberWords writes it (#284).
const LEVEL_FALLS_LINE: String = "Three falls on the way to me. I felt every one."
const PHASE_FALLS_LINE: String = "Three falls on that climb, and you keep getting up. Why?"
## Lines read from one cue before giving up, in case a jump loops.
const MAX_LINES: int = 20


## Stands in for GameState, with only what these lines read.
class StandInGameState extends RefCounted:
	var player_name: String = "Anyone"
	var has_crucifix: bool = false


var _stats: GameRunStats
var _offers: GameOffers


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	_stats = root.get_node(^"RunStats") as GameRunStats
	_offers = root.get_node(^"Offers") as GameOffers
	var results: Array[bool] = []
	results.append(await _the_first_offer_counts_the_falls_of_the_level())
	results.append(await _the_second_offer_counts_the_falls_of_phase_2_from_phase_3())
	results.append(await _with_one_fall_no_number_is_said())
	_stats.reset()
	_offers.clear()
	finish(results)


func _the_first_offer_counts_the_falls_of_the_level() -> bool:
	_stats.reset()
	_stats.enter(LEVEL, 1)
	_fall(2)
	_stats.enter(LEVEL, 2)
	_fall(1)
	var texts: Array[String] = await _texts("asmodeus_offer")
	return report(texts.has(LEVEL_FALLS_LINE),
			"asmodeus_offer after 2 falls in phase 1 and 1 in phase 2 says \"%s\": %s"
			% [LEVEL_FALLS_LINE, texts.has(LEVEL_FALLS_LINE)])


func _the_second_offer_counts_the_falls_of_phase_2_from_phase_3() -> bool:
	_stats.reset()
	_stats.enter(LEVEL, 2)
	_fall(3)
	_stats.enter(LEVEL, 3)
	var texts: Array[String] = await _texts("asmodeus_second_offer")
	return report(texts.has(PHASE_FALLS_LINE),
			"asmodeus_second_offer in phase 3, after 3 falls in phase 2, says \"%s\": %s"
			% [PHASE_FALLS_LINE, texts.has(PHASE_FALLS_LINE)])


func _with_one_fall_no_number_is_said() -> bool:
	_stats.reset()
	_stats.enter(LEVEL, 2)
	_fall(1)
	var first: Array[String] = await _texts("asmodeus_offer")
	_stats.enter(LEVEL, 3)
	var second: Array[String] = await _texts("asmodeus_second_offer")
	var counted: Callable = func(text: String) -> bool: return text.contains(" falls ")
	return report(not first.any(counted) and not second.any(counted),
			"with 1 fall, no number in asmodeus_offer (%s) nor in asmodeus_second_offer (%s)"
			% [first.any(counted), second.any(counted)])


func _fall(times: int) -> void:
	for death: int in times:
		_stats.record_death(ZONE)


## The texts of cue's lines up to the first choice, read with the stand-in game state.
func _texts(cue: String) -> Array[String]:
	var states: Array = [{"GameState": StandInGameState.new()}]
	var texts: Array[String] = []
	var line: DialogueLine = await LUST.get_next_dialogue_line(cue, states)
	while line != null and texts.size() < MAX_LINES:
		texts.append(line.text)
		if not line.responses.is_empty():
			break
		line = await LUST.get_next_dialogue_line(line.next_id, states)
	_offers.clear()
	return texts
