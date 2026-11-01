# Checks the lines the Dialogue Manager hands out at run time (ADR 0030): who speaks, the text, the
# curly quotes and the "…" kept as written, and the questions of velvet_questions. Those start with a
# condition, so they come on a line of their own with no speaker or text, after Velvet's last line;
# the balloon keeps that line on screen above them and hides the ones already asked, which come
# marked as not allowed. A stand-in game state holds the player's name and the balloon's locals,
# since GameState does not exist yet. The last case opens dialogue/lust_waking_preview.tscn, the
# example balloon on the first cue of Lust.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_lines.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const GREED: DialogueResource = preload("res://dialogue/greed.dialogue")
const PREVIEW_SCENE: PackedScene = preload("res://dialogue/lust_waking_preview.tscn")
const PLAYER_NAME: String = "Anyone"
## Lines read from one cue before giving up, in case a jump loops.
const MAX_LINES: int = 50
const VELVET_QUESTIONS: Array[String] = [
	"Who are you?", "What happened to me?", "Am I dead?", "Where am I?",
]
const ASKED_FLAGS: Array[String] = [
	"asked_who", "asked_what_happened", "asked_dead", "asked_where",
]


## Stands in for GameState, with only what these lines read.
class StandInGameState extends RefCounted:
	var player_name: String = PLAYER_NAME


func _initialize() -> void:
	# The DialogueManager autoload joins the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(await _waking_has_no_speaker_and_stops_at_the_name())
	results.append(await _velvet_and_the_player_are_named())
	results.append(await _the_questions_come_on_their_own_line_after_velvet())
	results.append(await _an_asked_question_is_not_offered_again())
	results.append(await _with_every_question_asked_the_argument_starts())
	results.append(await _curly_quotes_and_the_ellipsis_are_kept())
	results.append(await _the_preview_shows_the_first_line_of_waking())
	finish(results)


func _waking_has_no_speaker_and_stops_at_the_name() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "waking", _states())
	var speakers: Array[String] = []
	for line: DialogueLine in lines:
		speakers.append(line.character)
	return report(lines.size() == 6 and speakers.all(func(name: String) -> bool: return name.is_empty())
			and lines[0].text == "Lord..."
			and lines[-1].text == "Breathe. Start with what you know. My name. My name is...",
			"waking has 6 lines with no speaker, from \"Lord...\" to \"My name is...\" (got %d, speakers %s)"
			% [lines.size(), speakers])


func _velvet_and_the_player_are_named() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states())
	var passed: bool = lines.size() >= 2 and lines[0].character == "Velvet" \
			and lines[0].text.begins_with("Well, well.") and lines[1].character == PLAYER_NAME \
			and lines[1].text == "Stay back. In the name of the Lord, stay back."
	return report(passed, "velvet opens with Velvet, then the player by the name he typed")


func _the_questions_come_on_their_own_line_after_velvet() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states())
	var offered: Array[String] = _allowed_texts(lines[-1])
	var passed: bool = lines.size() == 5 and lines[3].character == "Velvet" \
			and lines[3].responses.is_empty() and lines[4].type == DMConstants.TYPE_RESPONSE \
			and lines[4].character.is_empty() and lines[4].text.is_empty() \
			and offered == VELVET_QUESTIONS
	return report(passed, "after Velvet's 4th line, a line with only the 4 questions (got %d lines, %s)"
			% [lines.size(), offered])


func _an_asked_question_is_not_offered_again() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states(["asked_who"]))
	var offered: Array[String] = _allowed_texts(lines[-1])
	return report(lines[-1].responses.size() == VELVET_QUESTIONS.size()
			and offered == VELVET_QUESTIONS.slice(1),
			"with \"Who are you?\" asked, it comes not allowed and the other 3 allowed (got %s)" % [offered])


func _with_every_question_asked_the_argument_starts() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states(ASKED_FLAGS))
	var passed: bool = lines.size() >= 5 and lines[3].responses.is_empty() \
			and lines[4].character == PLAYER_NAME and lines[4].text.begins_with("There must be a mistake.")
	return report(passed, "with every question asked, velvet goes on to velvet_argument")


func _curly_quotes_and_the_ellipsis_are_kept() -> bool:
	var lines: Array[DialogueLine] = await _lines(GREED, "ledger", _states())
	var passed: bool = lines.size() >= 6 and lines[3].character == "Chip" \
			and lines[3].text == "Seventy thousand! You cried! And you said: “That's it. I'm stopping.”" \
			and lines[5].character == "Tally" \
			and lines[5].text == "At three in the morning you were at seventy-one. By breakfast… Nothing."
	return report(passed, "the ledger keeps the curly quotes, the colon inside the text and the \"…\"")


func _the_preview_shows_the_first_line_of_waking() -> bool:
	var preview: DialogueManagerExampleBalloon = PREVIEW_SCENE.instantiate()
	root.add_child(preview)
	var shown: bool = await wait_until(func() -> bool:
		return preview.dialogue_line != null and preview.dialogue_line.text == "Lord...")
	var passed: bool = shown and not preview.character_label.visible
	preview.queue_free()
	await process_frame
	return report(passed, "the preview opens on \"Lord...\" with no name shown")


## The lines of a cue in order, up to the first one that offers responses or the end.
func _lines(resource: DialogueResource, cue: String, states: Array) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	var line: DialogueLine = await resource.get_next_dialogue_line(cue, states)
	while line != null and lines.size() < MAX_LINES:
		lines.append(line)
		if not line.responses.is_empty():
			break
		line = await resource.get_next_dialogue_line(line.next_id, states)
	return lines


## The game states the lines read: GameState, and the balloon's locals with the given flags set.
func _states(asked: Array[String] = []) -> Array:
	var locals: Dictionary = {}
	for flag: String in asked:
		locals[flag] = true
	return [{"GameState": StandInGameState.new(), "locals": locals}]


## The responses the balloon shows: the ones not allowed are hidden.
func _allowed_texts(line: DialogueLine) -> Array[String]:
	var texts: Array[String] = []
	for response: DialogueResponse in line.responses:
		if response.is_allowed:
			texts.append(response.text)
	return texts
