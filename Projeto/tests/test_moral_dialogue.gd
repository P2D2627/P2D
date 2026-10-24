# Checks the autoload Moral with the real lines (#169). It is in the tree, at stage 0, and says
# stage_changed once when the man takes a shortcut, and 0 again on reset(). In Lust's asmodeus_gift,
# refusing the charm with "Keep it." gives his humble line at stage 0, and the worse one after he
# took Lust's shortcut, read by the lines through Moral.stage(). A stand-in game state holds what
# those lines read, since GameState does not exist yet. Moral is reset before and after each case.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_dialogue.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const PLAYER_NAME: String = "Anyone"
const GIFT_CUE: String = "asmodeus_gift"
const REFUSAL: String = "Keep it."
const CLEAN_LINE: String = "Every time I said yes to something like you, somebody got hurt."
const WORSE_LINE: String = "I have the Lord. I do not need your tricks."
## Lines read from one cue before giving up, in case a jump loops.
const MAX_LINES: int = 50


## Stands in for GameState, with only what these lines read. The wedding was already told, so the
## lines never write a flag.
class StandInGameState extends RefCounted:
	var player_name: String = PLAYER_NAME
	var has_crucifix: bool = true

	func has_flag(_flag: StringName) -> bool:
		return true

	func set_flag(_flag: StringName) -> void:
		pass


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
	results.append(await _keep_it_is_humble_at_stage_0_and_worse_after_the_shortcut())
	_moral.reset()
	finish(results)


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


func _keep_it_is_humble_at_stage_0_and_worse_after_the_shortcut() -> bool:
	_moral.reset()
	var clean: DialogueLine = await _answer_to_refusal()
	_moral.take_temptation(&"lust_shortcut")
	var worse: DialogueLine = await _answer_to_refusal()
	_moral.reset()
	var clean_text: String = clean.text if clean != null else "none"
	var worse_text: String = worse.text if worse != null else "none"
	return report(clean != null and worse != null and clean.character == PLAYER_NAME
			and clean_text == CLEAN_LINE and worse_text == WORSE_LINE,
			"\"%s\" at stage 0: \"%s\"; after the shortcut: \"%s\"" % [REFUSAL, clean_text,
			worse_text])


## The line that follows "Keep it." in asmodeus_gift, or null if the cue never offers it.
func _answer_to_refusal() -> DialogueLine:
	var states: Array = [{"GameState": StandInGameState.new()}]
	var line: DialogueLine = await LUST.get_next_dialogue_line(GIFT_CUE, states)
	var read: int = 0
	while line != null and line.responses.is_empty() and read < MAX_LINES:
		line = await LUST.get_next_dialogue_line(line.next_id, states)
		read += 1
	if line == null:
		return null
	for response: DialogueResponse in line.responses:
		if response.text == REFUSAL:
			return await LUST.get_next_dialogue_line(response.next_id, states)
	return null
