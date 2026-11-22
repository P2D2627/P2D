# Checks the lines the Dialogue Manager hands out at run time (ADR 0030): who speaks, the text, the
# curly quotes and the "…" kept as written, and the questions of velvet_questions. The soul only
# says what the player picks (#277), so Velvet asks the name in the dark, says it back once it is
# typed, and speaks alone until the first choice. The questions start with a condition, so they
# come on a line of their own with no speaker or text, after Velvet's last line, with the way out
# beside them; the balloon keeps that line on screen above them and hides the ones already asked,
# which come marked as not allowed. A stand-in game state holds the player's name and the balloon's
# locals, since GameState does not exist yet. Read as text, every spoken line of Lust is Velvet's or
# Asmodeus's, and no answer has BBCode, which the balloon's plain answer buttons would show as
# written. The last case opens dialogue/lust_waking_preview.tscn, the game's balloon on the first
# cue of Lust.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_lines.gd
extends "res://tests/support/player_test.gd"

const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
const LUST_PATH: String = "res://dialogue/lust.dialogue"
const GREED: DialogueResource = preload("res://dialogue/greed.dialogue")
## Who speaks in Lust: the soul has no lines of its own (#277).
const LUST_SPEAKERS: Array[String] = ["Velvet", "Asmodeus"]
## How a line of a .dialogue file starts when it is not a spoken line.
const NOT_SPOKEN: Array[String] = ["#", "~ ", "- ", "=> ", "$> ", "if ", "elif ", "else"]
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
## Offered beside the questions, always, to go on to velvet_argument without asking them.
const WAY_OUT: String = "Just tell me how to get out."
const SPEAKER: String = "Velvet"


## Stands in for GameState, with only what these lines read.
class StandInGameState extends RefCounted:
	var player_name: String = PLAYER_NAME


func _initialize() -> void:
	# The DialogueManager autoload joins the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(await _velvet_asks_the_name_in_the_dark())
	results.append(await _velvet_says_the_typed_name())
	results.append(await _velvet_speaks_alone_until_the_questions())
	results.append(await _the_questions_come_on_their_own_line_after_velvet())
	results.append(await _an_asked_question_is_not_offered_again())
	results.append(await _with_every_question_asked_the_argument_starts())
	results.append(await _curly_quotes_and_the_ellipsis_are_kept())
	results.append(_lust_is_spoken_by_its_demons_and_its_answers_are_plain())
	results.append(await _the_preview_shows_the_first_line_of_waking())
	finish(results)


func _velvet_asks_the_name_in_the_dark() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "waking", _states())
	var speakers: Array[String] = []
	for line: DialogueLine in lines:
		speakers.append(line.character)
	return report(lines.size() == 3 and speakers.all(func(name: String) -> bool: return name == SPEAKER)
			and lines[0].text.ends_with("Mm. A new one. Still warm.")
			and lines[-1].text == "Your name. Say it, before that goes too.",
			"waking has 3 lines, all Velvet's, from \"Still warm.\" to \"Your name.\" (got %d, speakers %s)"
			% [lines.size(), speakers])


func _velvet_says_the_typed_name() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "named", _states())
	var text: String = lines[0].text if not lines.is_empty() else "none"
	return report(lines.size() == 1 and lines[0].character == SPEAKER
			and text.begins_with(PLAYER_NAME + "."),
			"named: Velvet says back the name the player typed (got %d lines: \"%s\")"
			% [lines.size(), text])


func _velvet_speaks_alone_until_the_questions() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states())
	var speakers: Array[String] = []
	for line: DialogueLine in lines:
		if line.type != DMConstants.TYPE_RESPONSE:
			speakers.append(line.character)
	var passed: bool = not speakers.is_empty() and lines[0].text.begins_with("[i](sniffing the air)[/i] Fresh.") \
			and speakers.all(func(name: String) -> bool: return name == SPEAKER)
	return report(passed, "velvet: every line before the questions is Velvet's (speakers %s)"
			% [speakers])


func _the_questions_come_on_their_own_line_after_velvet() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states())
	var offered: Array[String] = _allowed_texts(lines[-1])
	var expected: Array[String] = VELVET_QUESTIONS.duplicate()
	expected.append(WAY_OUT)
	var passed: bool = lines.size() == 4 and lines[2].character == SPEAKER \
			and lines[2].responses.is_empty() and lines[3].type == DMConstants.TYPE_RESPONSE \
			and lines[3].character.is_empty() and lines[3].text.is_empty() \
			and offered == expected
	return report(passed,
			"after Velvet's 3rd line, a line with only the 4 questions and the way out (got %d lines, %s)"
			% [lines.size(), offered])


func _an_asked_question_is_not_offered_again() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states(["asked_who"]))
	var offered: Array[String] = _allowed_texts(lines[-1])
	var expected: Array[String] = VELVET_QUESTIONS.slice(1)
	expected.append(WAY_OUT)
	return report(lines[-1].responses.size() == VELVET_QUESTIONS.size() + 1 and offered == expected,
			"with \"Who are you?\" asked, it comes not allowed and the other 3 and the way out allowed "
			+ "(got %s)" % [offered])


func _with_every_question_asked_the_argument_starts() -> bool:
	var lines: Array[DialogueLine] = await _lines(LUST, "velvet", _states(ASKED_FLAGS))
	var answers: Array[String] = []
	if not lines.is_empty():
		answers = _allowed_texts(lines[-1])
	var passed: bool = lines.size() == 4 and lines[2].responses.is_empty() \
			and lines[3].character == SPEAKER and lines[3].text.begins_with("Out? [i](laughing)[/i] On your first day?") \
			and answers.has("I don't belong here. I was a good person.")
	return report(passed, "with every question asked, velvet goes on to velvet_argument (got %d lines, %s)"
			% [lines.size(), answers])


func _curly_quotes_and_the_ellipsis_are_kept() -> bool:
	var lines: Array[DialogueLine] = await _lines(GREED, "ledger", _states())
	var passed: bool = lines.size() >= 6 and lines[3].character == "Chip" \
			and lines[3].text == "Seventy thousand! You cried! And you said: “That's it. I'm stopping.”" \
			and lines[5].character == "Tally" \
			and lines[5].text == "At three in the morning you were at seventy-one. By breakfast… Nothing."
	return report(passed, "the ledger keeps the curly quotes, the colon inside the text and the \"…\"")


## Read as text, every spoken line of lust.dialogue is Velvet's or Asmodeus's, and no answer has
## BBCode: the balloon's answer is a plain Button, so "[i]" would show as written.
func _lust_is_spoken_by_its_demons_and_its_answers_are_plain() -> bool:
	var file: FileAccess = FileAccess.open(LUST_PATH, FileAccess.READ)
	if file == null:
		return report(false, "%s opens as text" % LUST_PATH)
	var other_speakers: Array[String] = []
	var marked_answers: Array[String] = []
	for raw: String in file.get_as_text().split("\n"):
		var line: String = raw.strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("- "):
			var answer: String = line.get_slice("[if ", 0)
			if answer.contains("["):
				marked_answers.append(answer)
			continue
		if NOT_SPOKEN.any(func(start: String) -> bool: return line.begins_with(start)):
			continue
		var speaker: String = line.get_slice(":", 0) if line.contains(":") else ""
		if not LUST_SPEAKERS.has(speaker):
			other_speakers.append(line)
	return report(other_speakers.is_empty() and marked_answers.is_empty(),
			"lust.dialogue: lines not by %s %s; answers with BBCode %s"
			% [LUST_SPEAKERS, other_speakers, marked_answers])


func _the_preview_shows_the_first_line_of_waking() -> bool:
	var preview: DialogueBalloon = PREVIEW_SCENE.instantiate()
	root.add_child(preview)
	var shown: bool = await wait_until(func() -> bool:
		return preview.dialogue_line != null and preview.dialogue_line.text.ends_with("Still warm."))
	var passed: bool = shown and preview.is_speaker_shown()
	preview.queue_free()
	await process_frame
	return report(passed, "the preview opens on Velvet's \"Still warm.\" with her name shown")


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
