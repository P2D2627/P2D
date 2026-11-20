# Checks the balloon's look and its wheel of answers. With 1 to 4 answers, as many platforms and
# links show, in order; with three, the third's link is the one drawn alone, not the one that joins
# the fourth's. Only the
# stick held towards a place points at it: let go, or towards an empty place, nothing is, and Jump
# does nothing. The one pointed at is drawn inverted with its link, the third's own when it is the
# last, and Jump confirms it, which says that answer and writes it in the box as the man's line. The man speaks on the left, the box mirrored, and a demon on the right; while the
# balloon talks, the soul bar's group hides, and it shows again when the talk ends. The balloon sits
# under the pause menu, so a pause shows over the talk.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_wheel.gd
extends "res://tests/support/player_test.gd"

const BALLOON_SCENE: PackedScene = preload("res://scenes/screens/dialogue_balloon.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/screens/pause_menu.tscn")
const LUST: DialogueResource = preload("res://dialogue/lust.dialogue")
## Its arrival is a line of the man's.
const GLUTTONY: DialogueResource = preload("res://dialogue/gluttony.dialogue")
const CONFIRM_ACTION: StringName = &"jump"
const LINE_FRAMES: int = 60

var _offers: GameOffers


func _initialize() -> void:
	await process_frame
	_offers = root.get_node(^"Offers") as GameOffers
	var results: Array[bool] = []
	results.append(await _as_many_places_show_as_answers())
	results.append(await _pointing_picks_and_highlights_and_jump_confirms())
	results.append(await _the_man_speaks_on_the_left_and_the_hud_hides())
	results.append(_the_pause_shows_over_the_balloon())
	finish(results)


func _as_many_places_show_as_answers() -> bool:
	var balloon: DialogueBalloon = _add_balloon()
	var wheel: DialogueWheel = balloon.get_node(^"%Wheel") as DialogueWheel
	var seen: Array[String] = []
	var passed: bool = true
	for count: int in range(1, 5):
		wheel.responses = _answers(count)
		var places: int = wheel.slots.filter(func(slot: Control) -> bool: return slot.visible).size()
		var first: String = (wheel.slots[0].get_node(^"Text") as Label).text
		var links: int = wheel.links.filter(func(link: CanvasItem) -> bool: return link.visible).size()
		var alone: bool = wheel.link_3_alone.visible
		var ok: bool = (places == count and links == (2 if count == 3 else count) and alone == (count == 3)
				and first == "Answer 1" and wheel.selected == -1)
		passed = passed and ok
		seen.append("%d: %d places, %d joined links, the third's alone %s" % [count, places, links, alone])
	var asked: Array = _answers(4)
	(asked[0] as DialogueResponse).is_allowed = false
	wheel.responses = asked
	var hidden_first: String = (wheel.slots[0].get_node(^"Text") as Label).text
	var after_asked: int = wheel.slots.filter(func(slot: Control) -> bool: return slot.visible).size()
	passed = passed and hidden_first == "Answer 2" and after_asked == 3
	seen.append("one not allowed: %d places, the first %s" % [after_asked, hidden_first])
	balloon.queue_free()
	await wait_frames(2)
	return report(passed, "places and links per answers, none pointed at: %s" % [seen])


func _pointing_picks_and_highlights_and_jump_confirms() -> bool:
	var balloon: DialogueBalloon = _add_balloon()
	var wheel: DialogueWheel = balloon.get_node(^"%Wheel") as DialogueWheel
	wheel.responses = _answers(3)
	(balloon.get_node(^"%Balloon") as Control).show()
	wheel.show()
	var said: Array[String] = []
	wheel.response_selected.connect(func(response: DialogueResponse) -> void: said.append(response.text))
	_press(CONFIRM_ACTION)
	var nothing_before: bool = said.is_empty()
	wheel.point(Vector2(-1.0, 0.0))
	var left: int = wheel.selected
	wheel.point(Vector2(1.0, 0.0))
	var right: int = wheel.selected
	wheel.point(Vector2(0.7, 0.7))
	var empty_place: int = wheel.selected
	wheel.point(Vector2(0.0, 1.0))
	var down: int = wheel.selected
	wheel.point(Vector2.ZERO)
	var let_go: int = wheel.selected
	_press(CONFIRM_ACTION)
	var nothing_let_go: bool = said.is_empty()
	wheel.point(Vector2(-0.7, 0.7))
	var bottom_left: int = wheel.selected
	var lit: bool = (wheel.is_lit(wheel.slots[2].get_node(^"Platform") as CanvasItem)
			and wheel.is_lit(wheel.link_3_alone) and not wheel.is_lit(wheel.links[0])
			and not wheel.is_lit(wheel.slots[0].get_node(^"Platform") as CanvasItem))
	_press(CONFIRM_ACTION)
	var written: bool = (balloon.dialogue_line != null and balloon.dialogue_line.text == "Answer 3"
			and balloon.is_on_left())
	var passed: bool = (nothing_before and left == 0 and right == 1 and empty_place == -1 and down == 2
			and let_go == -1 and nothing_let_go and bottom_left == 2 and lit and said == ["Answer 3"] and written)
	balloon.queue_free()
	await wait_frames(2)
	return report(passed, ("nothing confirmed before pointing %s; left %d, right %d, down-right with 3 "
			+ "answers %d, down %d; let go %d and Jump does nothing %s; down-left %d, inverted with its "
			+ "link, the third's alone %s; Jump says %s, written in the box as his line %s")
			% [nothing_before, left, right, empty_place, down, let_go, nothing_let_go, bottom_left, lit,
			said, written])


func _the_man_speaks_on_the_left_and_the_hud_hides() -> bool:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.add_to_group(DialogueBalloon.HIDDEN_DURING_DIALOGUE)
	root.add_child(hud)
	var balloon: DialogueBalloon = _add_balloon()
	balloon.start(GLUTTONY, "arrival")
	await wait_until(func() -> bool: return balloon.dialogue_line != null, LINE_FRAMES)
	var man_left: bool = balloon.is_on_left()
	var hidden: bool = not hud.visible
	var box: TextureRect = balloon.get_node(^"%Box") as TextureRect
	var mirrored: bool = box.flip_h
	balloon.queue_free()
	await wait_frames(2)
	var back: bool = hud.visible
	var demon: DialogueBalloon = _add_balloon()
	demon.start(LUST, "asmodeus_offer")
	await wait_until(func() -> bool: return demon.dialogue_line != null, LINE_FRAMES)
	var demon_right: bool = not demon.is_on_left()
	demon.queue_free()
	hud.queue_free()
	await wait_frames(2)
	_offers.clear()
	return report(man_left and mirrored and hidden and back and demon_right,
			"the man on the left %s, mirrored %s; Asmodeus on the right %s; the HUD hidden %s, back %s"
			% [man_left, mirrored, demon_right, hidden, back])


func _the_pause_shows_over_the_balloon() -> bool:
	var balloon: DialogueBalloon = BALLOON_SCENE.instantiate()
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	var under: bool = balloon.layer < pause.layer
	var what: String = "balloon on layer %d, pause on %d" % [balloon.layer, pause.layer]
	balloon.free()
	pause.free()
	return report(under, what)


func _add_balloon() -> DialogueBalloon:
	var balloon: DialogueBalloon = BALLOON_SCENE.instantiate()
	balloon.dialogue_resource = LUST
	balloon.next_action = CONFIRM_ACTION
	balloon.skip_action = CONFIRM_ACTION
	root.add_child(balloon)
	return balloon


func _answers(count: int) -> Array:
	var answers: Array = []
	for i: int in count:
		var answer: DialogueResponse = DialogueResponse.new()
		answer.text = "Answer %d" % (i + 1)
		answer.next_id = DMConstants.ID_END
		answers.append(answer)
	return answers


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var release: InputEventAction = InputEventAction.new()
	release.action = action
	Input.parse_input_event(release)
	Input.flush_buffered_events()
