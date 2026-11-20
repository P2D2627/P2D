# Checks the game's balloon skipping lines. On asmodeus_second_offer, skipping runs to the line with
# the four answers and stops there, with none chosen; the offer the skipped lines present is
# presented all the same, and the lines that went by count in RunStats. At a choice, skipping does
# nothing. Holding Jump for Skip Hold Time skips once, a short tap does not, and on waking, which
# has no answers, a skip runs to the end and the balloon goes. The portrait is a stand-in with the
# speaker's initial while no picture is given, as for Crumb; Asmodeus has hers, on the right, and
# its top drawn over the frame too.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_skip.gd
extends "res://tests/support/player_test.gd"

const BALLOON_SCENE: PackedScene = preload("res://scenes/screens/dialogue_balloon.tscn")
const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
## Crumb, who has no picture yet, opens its crumb cue.
const GLUTTONY: DialogueResource = preload("res://dialogue/gluttony.dialogue")
const SHORTCUT: StringName = &"lust_shortcut"
## Lines with no choice before the offer's four answers.
const OFFER_CUE: StringName = &"asmodeus_second_offer"
## Several lines and no answers at all.
const NO_ANSWERS_CUE: StringName = &"waking"
const ANSWERS: int = 4
const HOLD_ACTION: StringName = &"jump"
## Frames to wait for a line to come, or for a skip to end.
const LINE_FRAMES: int = 60

var _stats: GameRunStats
var _offers: GameOffers


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	_stats = root.get_node(^"RunStats") as GameRunStats
	_offers = root.get_node(^"Offers") as GameOffers
	var results: Array[bool] = []
	results.append(await _a_skip_stops_at_the_answers_and_still_presents_the_offer())
	results.append(await _at_a_choice_a_skip_does_nothing())
	results.append(await _a_hold_skips_and_a_tap_does_not())
	results.append(await _with_no_answers_a_skip_ends_the_talk())
	results.append(await _the_stand_in_portrait_shows_the_initial())
	results.append(await _a_demon_with_a_picture_shows_it_on_the_right())
	finish(results)


func _a_skip_stops_at_the_answers_and_still_presents_the_offer() -> bool:
	_stats.reset()
	_offers.clear()
	var balloon: DialogueBalloon = await _open(OFFER_CUE)
	var counted: Array[int] = []
	balloon.lines_skipped.connect(func(count: int) -> void: counted.append(count))
	await balloon.skip_to_the_next_choice()
	await wait_frames(2)
	var at_choice: bool = balloon.is_at_a_choice() and balloon.dialogue_line.responses.size() == ANSWERS
	var presented: bool = _offers.last_presented != null and _offers.last_presented.id == SHORTCUT
	var skipped: int = counted[0] if counted.size() == 1 else -1
	var in_stats: bool = _stats.get_skipped_lines() == skipped and skipped > 0
	var none_taken: bool = not _offers.has_accepted(SHORTCUT)
	await _close(balloon)
	_offers.clear()
	return report(at_choice and presented and in_stats and none_taken,
			("A skip on %s: stops at the %d answers %s, the offer presented %s, %d lines "
			+ "counted in RunStats %s, nothing accepted %s") % [OFFER_CUE, ANSWERS, at_choice, presented,
			skipped, in_stats, none_taken])


func _at_a_choice_a_skip_does_nothing() -> bool:
	_stats.reset()
	_offers.clear()
	var balloon: DialogueBalloon = await _open(OFFER_CUE)
	await balloon.skip_to_the_next_choice()
	var line: DialogueLine = balloon.dialogue_line
	var counted_before: int = _stats.get_skipped_lines()
	await balloon.skip_to_the_next_choice()
	await wait_frames(2)
	var same: bool = balloon.dialogue_line == line and _stats.get_skipped_lines() == counted_before
	await _close(balloon)
	_offers.clear()
	return report(same, "at a choice, a skip changes nothing %s" % same)


func _a_hold_skips_and_a_tap_does_not() -> bool:
	_stats.reset()
	_offers.clear()
	var balloon: DialogueBalloon = await _open(OFFER_CUE)
	var hold_frames: int = ceili(balloon.skip_hold_time * 60.0)
	Input.action_press(HOLD_ACTION)
	await wait_frames(hold_frames / 3)
	Input.action_release(HOLD_ACTION)
	await wait_frames(2)
	var tap_skipped: bool = _stats.get_skipped_lines() > 0 or balloon.is_at_a_choice()
	Input.action_press(HOLD_ACTION)
	var reached: bool = await wait_until(balloon.is_at_a_choice, hold_frames + LINE_FRAMES)
	Input.action_release(HOLD_ACTION)
	await _close(balloon)
	_offers.clear()
	return report(not tap_skipped and reached,
			"a tap of %d frames skips %s; a hold of %d frames reaches the answers %s"
			% [hold_frames / 3, tap_skipped, hold_frames, reached])


func _with_no_answers_a_skip_ends_the_talk() -> bool:
	_stats.reset()
	var balloon: DialogueBalloon = await _open(NO_ANSWERS_CUE)
	var left: Array[bool] = [false]
	balloon.tree_exited.connect(func() -> void: left[0] = true)
	balloon.skip_to_the_next_choice()
	var gone: bool = await wait_until(func() -> bool: return left[0], LINE_FRAMES)
	if not gone:
		await _close(balloon)
	return report(gone and _stats.get_skipped_lines() > 0,
			"on %s, a skip runs to the end and the balloon goes %s (%d lines)"
			% [NO_ANSWERS_CUE, gone, _stats.get_skipped_lines()])


func _the_stand_in_portrait_shows_the_initial() -> bool:
	var balloon: DialogueBalloon = await _open(&"crumb", GLUTTONY)
	var stand_in: ColorRect = balloon.get_node(^"%PortraitStandIn") as ColorRect
	var initial: Label = balloon.get_node(^"%PortraitInitial") as Label
	var picture: TextureRect = balloon.get_node(^"%Portrait") as TextureRect
	var passed: bool = (balloon.dialogue_line.character == "Crumb" and stand_in.visible
			and initial.text == "C" and not picture.visible
			and stand_in.color == DialogueBalloon.DEFAULT_PORTRAIT_COLOR)
	var what: String = ("Crumb's stand-in portrait: shown %s, initial %s, no picture %s"
			% [stand_in.visible, initial.text, not picture.visible])
	await _close(balloon)
	return report(passed, what)


func _a_demon_with_a_picture_shows_it_on_the_right() -> bool:
	var balloon: DialogueBalloon = await _open(&"asmodeus_offer")
	var stand_in: ColorRect = balloon.get_node(^"%PortraitStandIn") as ColorRect
	var picture: TextureRect = balloon.get_node(^"%Portrait") as TextureRect
	var pop: TextureRect = balloon.get_node(^"%PortraitPop") as TextureRect
	var passed: bool = (balloon.dialogue_line.character == "Asmodeus" and picture.visible
			and pop.visible and pop.texture == picture.texture and not stand_in.visible
			and not balloon.is_on_left())
	var what: String = ("Asmodeus's picture: shown %s, over the frame too %s, no stand-in %s, on the "
			+ "right %s") % [picture.visible, pop.visible, not stand_in.visible, not balloon.is_on_left()]
	await _close(balloon)
	_offers.clear()
	return report(passed, what)


func _open(cue: StringName, resource: DialogueResource = LUST) -> DialogueBalloon:
	var balloon: DialogueBalloon = BALLOON_SCENE.instantiate()
	balloon.next_action = HOLD_ACTION
	balloon.skip_action = HOLD_ACTION
	root.add_child(balloon)
	balloon.start(resource, String(cue))
	await wait_until(func() -> bool: return balloon.dialogue_line != null, LINE_FRAMES)
	return balloon


func _close(balloon: DialogueBalloon) -> void:
	if is_instance_valid(balloon):
		balloon.queue_free()
	await wait_frames(2)
