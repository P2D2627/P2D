# Checks the key in the grab's prompt (#284): the prompt names no action in its words and shows the
# key instead, a PromptGlyph for Jump beside its text, so it follows the device used last as the
# tutorial's band does. The key shows while the man is held and goes when he dies, leaving only the
# death's words, and comes back with the next grab. The grab itself is test_grab_escape's; here
# GrabEscape's signals are given by hand.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_prompt_glyph.gd
extends "res://tests/support/player_test.gd"

## The action names a prompt must not spell out: the key says it.
const ACTION_NAMES: PackedStringArray = ["Jump", "jump"]


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_the_words_name_no_action())
	results.append(await _the_key_shows_while_held_and_goes_at_death())
	finish(results)


func _the_words_name_no_action() -> bool:
	var named: Array[String] = []
	for text: String in [GrabPrompt.PRESS_TEXT, GrabPrompt.HOLD_TEXT, GrabPrompt.DIED_TEXT]:
		for action_name: String in ACTION_NAMES:
			if text.contains(action_name):
				named.append(text)
	return report(named.is_empty(), "The prompt's words name no action (naming one: %s)" % [named])


func _the_key_shows_while_held_and_goes_at_death() -> bool:
	var man: Player = spawn_player(Vector2.ZERO)
	await process_frame
	var escape: GrabEscape = man.get_node(^"GrabEscape") as GrabEscape
	var prompt: GrabPrompt = man.get_node(^"GrabPrompt") as GrabPrompt
	var glyph: PromptGlyph = prompt.get_node_or_null(^"%Glyph") as PromptGlyph
	var label: Label = prompt.get_node(^"%Label") as Label
	if glyph == null:
		await remove_player(man)
		return report(false, "Key in the prompt: the prompt has no Glyph")
	escape.grabbed.emit()
	await process_frame
	var held: bool = prompt.visible and glyph.is_visible_in_tree() and glyph.action == &"jump"
	escape.died.emit()
	await process_frame
	var death_text: String = label.text
	var dead: bool = prompt.visible and not glyph.visible and death_text == GrabPrompt.DIED_TEXT
	escape.broke_free.emit()
	escape.grabbed.emit()
	await process_frame
	var again: bool = prompt.visible and glyph.is_visible_in_tree() and label.text != GrabPrompt.DIED_TEXT
	await remove_player(man)
	return report(held and dead and again, ("Key in the prompt: shown for Jump while held %s; gone "
			+ "at death, with \"%s\" %s; back on the next grab %s") % [held, death_text, dead, again])
