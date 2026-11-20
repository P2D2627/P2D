# Checks the autoload Moral with the real lines (#169). It is in the tree, at stage 0, and says
# stage_changed once when the soul takes a shortcut, and 0 again on reset(). The soul rots by what
# it can still say (#277): in Lust's asmodeus_gift, the humble refusal of the charm is offered at
# stage 0 and hidden after Lust's shortcut, read by the lines through Moral.stage(). At stage 0, it
# is also hidden when more answers were arrogant than humble (Moral.leans_arrogant()), and not on a
# tie. The other three answers stay. A stand-in game state holds what those lines read. Moral is
# reset before and after each case.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_dialogue.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const PLAYER_NAME: String = "Anyone"
const GIFT_CUE: String = "asmodeus_gift"
## Picked at the first choice of asmodeus_gift, to reach the charm's answers.
const FIRST_ANSWER: String = "What gift?"
const HUMBLE_REFUSAL: String = "No. I'd want it too much."
## The charm's other answers, in the order the cue offers them.
const OTHER_ANSWERS: Array[String] = [
	"Keep your tricks. I don't need them.", "I can't do this alone. Give it to me.",
	"Give it here. I've earned it.",
]
## Lines read from one cue before giving up, in case a jump loops.
const MAX_LINES: int = 50


## Stands in for GameState, with only what these lines read.
class StandInGameState extends RefCounted:
	var player_name: String = PLAYER_NAME
	var has_crucifix: bool = true


var _moral: GameMoral


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	_moral = root.get_node_or_null(^"Moral") as GameMoral
	if not report(_moral != null, "The autoload Moral is in the tree"):
		finish([false])
		return
	var results: Array[bool] = []
	results.append(_moral_says_each_stage_change_once())
	results.append(await _the_humble_refusal_is_offered_at_stage_0_and_hidden_after_the_shortcut())
	results.append(await _the_humble_refusal_is_hidden_when_more_answers_were_proud())
	_moral.reset()
	finish(results)


## Still at stage 0, with as many humble as arrogant answers the humble refusal is offered; with
## one arrogant answer more, it is hidden, as the tone so far says.
func _the_humble_refusal_is_hidden_when_more_answers_were_proud() -> bool:
	_moral.reset()
	_moral.record_tone(&"arrogant")
	_moral.record_tone(&"humble")
	var tied: Array[String] = await _charm_answers()
	_moral.record_tone(&"arrogant")
	var stage: int = _moral.stage()
	var proud: Array[String] = await _charm_answers()
	_moral.reset()
	return report(stage == 0 and tied == _all_answers() and proud == OTHER_ANSWERS,
			"\"%s\" with tied answers: %s; with one arrogant more, still at stage %d: %s"
			% [HUMBLE_REFUSAL, tied, stage, proud])


func _moral_says_each_stage_change_once() -> bool:
	_moral.reset()
	var said: Array[int] = []
	var listen: Callable = func(stage: int) -> void: said.append(stage)
	_moral.stage_changed.connect(listen)
	var at_start: int = _moral.stage()
	_moral.take_temptation(&"lust_shortcut")
	var after_shortcut: int = _moral.stage()
	_moral.reset()
	_moral.stage_changed.disconnect(listen)
	var expected: Array[int] = [1, 0]
	return report(at_start == 0 and after_shortcut == 1 and said == expected
			and not _moral.has_taken(&"lust_shortcut"),
			"Moral: stage %d, %d after Lust's shortcut, back to %d on reset(); it said %s"
			% [at_start, after_shortcut, _moral.stage(), said])


func _the_humble_refusal_is_offered_at_stage_0_and_hidden_after_the_shortcut() -> bool:
	_moral.reset()
	var clean: Array[String] = await _charm_answers()
	_moral.take_temptation(&"lust_shortcut")
	var after: Array[String] = await _charm_answers()
	_moral.reset()
	return report(clean == _all_answers() and after == OTHER_ANSWERS,
			"\"%s\" at stage 0: %s; after the shortcut: %s" % [HUMBLE_REFUSAL, clean, after])


## The charm's four answers, in the order the cue offers them, the humble refusal first.
func _all_answers() -> Array[String]:
	var answers: Array[String] = OTHER_ANSWERS.duplicate()
	answers.insert(0, HUMBLE_REFUSAL)
	return answers


## The charm's answers asmodeus_gift lets the player pick, after "What gift?" at its first choice;
## empty if the cue never gets there.
func _charm_answers() -> Array[String]:
	var states: Array = [{"GameState": StandInGameState.new()}]
	var line: DialogueLine = await LUST.get_next_dialogue_line(GIFT_CUE, states)
	var answers: Array[String] = []
	var past_first_choice: bool = false
	var read: int = 0
	while line != null and read < MAX_LINES:
		read += 1
		if line.responses.is_empty():
			line = await LUST.get_next_dialogue_line(line.next_id, states)
			continue
		if past_first_choice:
			break
		var first: DialogueResponse = null
		for response: DialogueResponse in line.responses:
			if response.text == FIRST_ANSWER:
				first = response
		if first == null:
			return answers
		past_first_choice = true
		line = await LUST.get_next_dialogue_line(first.next_id, states)
	if line == null:
		return answers
	for response: DialogueResponse in line.responses:
		if response.is_allowed:
			answers.append(response.text)
	return answers
