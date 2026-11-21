# Checks Asmodeus in level 1, in the main scene, as the game plays her. In a new game:
# - Reaching phase 2's save, she talks from asmodeus_offer; while she talks the dogs stand still.
#   Refusing, he stays in the level; the camera cutscene of phase 2 plays, with the dogs moving,
#   and after it he moves again, with the dogs.
# - An offer his deaths brought waits while he stands outside its zone, and she makes it from
#   asmodeus_deaths once he walks into it; it waits until he answers. Accepting takes him to the tent at the end of level 1
#   with its light, as New Game plays it: he stands there, not at phase 2's start, though he reached
#   it. No more offers come for his deaths.
# - At the tent she gives the gift, then the stairs, and only then the level ends: the main menu
#   shows, no level in the slot, and the save keeps level 1 at the tent, marked as done. Continue
#   brings him back to the tent, in the level, with no talk and the dogs still.
# - In a new game she already stands in her room at the level's end, in sight; walking in at its
#   entrance, she gives the gift from there, not from beside him. A talk elsewhere brings her
#   beside him, and back to her room after it.
# - Reaching phase 3's save, she talks from asmodeus_second_offer.
# - Left for the menu before the answer, a talk comes again after Continue, with what he said in it
#   undone; answered, it is saved at once and does not come again. A death offer left before the
#   answer still waits for its zone.
# - Deaths count also while an offer waits: a second zone waits too, and each offer is made where
#   it waits, asking about that zone.
# He is put in the middle of a save point's area, which need not be at the node.
# The tests use a save file of their own.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_asmodeus.gd
extends "res://tests/support/menu_test.gd"

const SAVE_PATH: String = "user://test_lust_asmodeus.cfg"
const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
## Where Lust's shortcut takes him: level 1 with its light.
const SHORTCUT_PATH: String = "res://scenes/levels/lust/level1_lit.tscn"
const SHORTCUT: StringName = &"lust_shortcut"
const TENT: StringName = &"asmodeus_tent"
## The answers of Lust's shortcut cues: the first two refuse it, the last two accept it.
const ACCEPT: int = 2
const REFUSE: int = 0
## The answer of asmodeus_gift that refuses the charm and always shows ("Keep your tricks").
const KEEP_IT: int = 1
## How many answers an offer has; any other choice (the cross, "What gift?", the stairs) gets its
## first answer.
const OFFER_ANSWERS: int = 4
## Choices answered in one talk before giving up, in case a jump loops.
const MAX_CHOICES: int = 8
## Frames to wait for her to start talking, for a line, or for a phase change with its fade.
const TALK_FRAMES: int = 180
## Frames he stands outside the offer's zone, with no offer made.
const OUTSIDE_FRAMES: int = 30
## Deaths recorded at most to bring an offer.
const MAX_DEATHS: int = 40
## How far from the tent he may stand, in px: he lands from a little above it.
const NEAR_THE_POINT: float = 64.0


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append_array(await _phase_2_then_deaths_then_the_shortcut_and_the_ending())
	results.append(await _phase_3_has_the_second_offer())
	results.append(await _the_ending_is_said_in_her_room())
	results.append(await _a_talk_left_before_the_answer_comes_again())
	results.append(await _a_death_offer_left_before_the_answer_waits_again())
	results.append(await _two_zones_wait_and_each_is_made_where_it_waits())
	_delete_save()
	_progress().reset()
	_stats().reset()
	SaveFile.default_path = ""
	finish(results)


func _phase_2_then_deaths_then_the_shortcut_and_the_ending() -> Array[bool]:
	var results: Array[bool] = []
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	var start: Vector2 = level.player.global_position
	var phase_2_save: SavePoint = level.get_node(^"Phase2Save") as SavePoint
	var dogs: Node = level.get_node(^"Dogs")

	# Phase 2's save: the first offer; refused.
	level.player.global_position = _inside(phase_2_save)
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_offer")
	var talked: bool = balloon != null
	var dogs_still: bool = not dogs.can_process()
	var centred: bool = await _camera_is_centred_on_the_two(level)
	var refused: bool = await _answer(level, balloon, REFUSE)
	# The end of her offer starts phase 2's camera cutscene, gate B locking, with the dogs moving.
	var intro: CameraCutscene = level.get_node(^"Cutscenes/Phase2Intro") as CameraCutscene
	var shown: bool = intro.is_playing()
	var dogs_in_it: bool = dogs.can_process()
	await wait_until(func() -> bool: return not intro.is_playing(), TALK_FRAMES * 2)
	await physics_frame
	var moves_again: bool = (level.player.get_speed_multiplier() == 1.0 and dogs.can_process()
			and level_in(main) == level)
	results.append(report(talked and dogs_still and centred and refused and shown and dogs_in_it
			and moves_again,
			("Phase 2: she talks %s, the dogs still %s, the camera centred on the two %s; refused, the "
			+ "talk ends %s, the gate's cutscene plays %s with the dogs moving %s, then he and the dogs "
			+ "move again in the same level %s")
			% [talked, dogs_still, centred, refused, shown, dogs_in_it, moves_again]))

	# An offer for his deaths in phase 2's zone, made when he walks in.
	var respawn: Vector2 = (phase_2_save.get_node(^"Respawn") as Node2D).global_position
	var zone: StringName = level.zone_at(respawn)
	level.player.global_position = start
	await wait_until_on_floor(level.player)
	var outside: bool = level.zone_at(level.player.global_position) != zone
	var deaths: int = 0
	while not _stats().has_death_offer() and deaths < MAX_DEATHS:
		_stats().record_death(zone)
		deaths += 1
	var waits: bool = _stats().has_death_offer() and _stats().get_death_offer_zone() == zone
	await wait_frames(OUTSIDE_FRAMES)
	var not_yet: bool = not (level.get_node(^"Asmodeus") as Asmodeus).is_talking()
	level.player.global_position = respawn
	balloon = await _talk(level, "asmodeus_deaths")
	var death_talk: bool = balloon != null
	# Taken only once he answers: until then, a quit brings it back.
	var still_waits: bool = _stats().has_death_offer()
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var beside: bool = asmodeus.global_position.distance_to(level.player.global_position) < 400.0
	results.append(report(outside and waits and not_yet and death_talk and still_waits and beside,
			("Deaths: outside the zone %s, an offer waits %s after %d deaths, none made outside %s; "
			+ "walking in, she talks %s beside him %s, the offer still waits while she talks %s")
			% [outside, waits, deaths, not_yet, death_talk, beside, still_waits]))

	# Accepted: to the tent, the gift, the stairs, and the end.
	var old_id: int = level.get_instance_id()
	await _answer(level, balloon, ACCEPT)
	var changed: bool = await wait_until(func() -> bool:
		return level_in(main) != null and level_in(main).get_instance_id() != old_id, TALK_FRAMES)
	level = level_in(main) as Level
	var at_the_tent: bool = changed and await _stands_at_the_tent(level)
	var closed: bool = _stats().get_death_offer_pacer().is_closed()
	var saved: Dictionary = SaveFile.new().read()
	var saved_at: String = "%s at %s" % [saved.get("scene", ""),
			saved.get("state", {}).get("arrival_point", "")]
	var gift: DialogueBalloon = await _talk(level, "asmodeus_gift") if changed else null
	var gift_said: bool = gift != null and await _answer(level, gift, KEEP_IT)
	var stairs: DialogueBalloon = await _talk(level, "stairs") if gift_said else null
	var stairs_said: bool = stairs != null and await _answer(level, stairs, -1)
	var ended: bool = await wait_until(func() -> bool:
		return level_in(main) == null and _is_shown(main, ^"%MainPanel"), TALK_FRAMES)
	results.append(report(changed and at_the_tent and closed
			and saved_at == "%s at %s" % [SHORTCUT_PATH, TENT] and gift_said and stairs_said and ended,
			("Shortcut: a new level %s, at the tent %s, no more offers %s, saved %s; the gift %s, "
			+ "the stairs %s, then the level ends to the menu %s")
			% [changed, at_the_tent, closed, saved_at, gift_said, stairs_said, ended]))

	# Done: Continue brings him to the tent, playing on, with no talk and the dogs still.
	var done_saved: bool = (SaveFile.new().read().get("state", {}).get("events", [])
			as PackedStringArray).has("lust_done")
	(main.get_node(^"%MainMenu") as MainMenu).continue_requested.emit()
	await wait_until(func() -> bool: return level_in(main) != null, TALK_FRAMES)
	level = level_in(main) as Level
	var back_at_the_tent: bool = level != null and await _stands_at_the_tent(level)
	await wait_frames(OUTSIDE_FRAMES)
	var quiet: bool = level != null and not (level.get_node(^"Asmodeus") as Asmodeus).is_talking()
	var dogs_stay: bool = level != null and not level.get_node(^"Dogs").can_process()
	var still_in_it: bool = level_in(main) == level
	results.append(report(done_saved and back_at_the_tent and quiet and dogs_stay and still_in_it,
			("Done: saved as done %s; Continue brings him to the tent %s, with no talk %s, the dogs "
			+ "still %s, and he stays in the level %s")
			% [done_saved, back_at_the_tent, quiet, dogs_stay, still_in_it]))
	await remove_main(main)
	return results


func _phase_3_has_the_second_offer() -> bool:
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	level.player.global_position = _inside(level.get_node(^"Phase3Save") as SavePoint)
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_second_offer")
	var talked: bool = balloon != null
	var refused: bool = talked and await _answer(level, balloon, REFUSE)
	await remove_main(main)
	return report(talked and refused,
			"Phase 3: she talks from asmodeus_second_offer %s, and a refusal ends it %s"
			% [talked, refused])


## She stands in her room from the start, in sight. Phase 2's talk brings her beside him and, once
## refused, back to her room. Walking in at the room's entrance, the gift comes from her room.
func _the_ending_is_said_in_her_room() -> bool:
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var home: Node2D = level.get_node(^"AsmodeusHome") as Node2D
	var at_home_first: bool = asmodeus.visible and _at(asmodeus, home)
	level.player.global_position = _inside(level.get_node(^"Phase2Save") as SavePoint)
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_offer")
	var beside: bool = (balloon != null
			and asmodeus.global_position.distance_to(level.player.global_position) < 400.0)
	var refused: bool = balloon != null and await _answer(level, balloon, REFUSE)
	var back_home: bool = refused and asmodeus.visible and _at(asmodeus, home)
	var exit: Node2D = level.get_node(^"PhaseExit") as Node2D
	var shape: CollisionShape2D = exit.get_node(^"CollisionShape2D") as CollisionShape2D
	var left_edge: float = shape.global_position.x - (shape.shape as RectangleShape2D).size.x / 2.0
	level.player.global_position = Vector2(left_edge + 24.0, exit.global_position.y - 2.0)
	var gift: DialogueBalloon = await _talk(level, "asmodeus_gift")
	var from_home: bool = gift != null and asmodeus.visible and _at(asmodeus, home)
	var far: float = asmodeus.global_position.distance_to(level.player.global_position)
	await remove_main(main)
	return report(at_home_first and beside and back_home and from_home and far > 400.0,
			("Her room: there at the start %s; phase 2's talk beside him %s, back in her room after %s; "
			+ "at the entrance, the gift from her room %s, %.0f px from him") % [at_home_first, beside,
			back_home, from_home, far])


## Whether asmodeus stands on point.
func _at(asmodeus: Asmodeus, point: Node2D) -> bool:
	return point != null and asmodeus.global_position.distance_to(point.global_position) < 1.0


## At phase 2's save she talks; he goes to the menu before answering, and Continue brings the talk
## back at once, with the arrogant answer he gave before it undone. Refused, it is saved at once:
## the menu and Continue again, and she does not talk.
func _a_talk_left_before_the_answer_comes_again() -> bool:
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	level.player.global_position = _inside(level.get_node(^"Phase2Save") as SavePoint)
	var first: bool = await _talk(level, "asmodeus_offer") != null
	(root.get_node(^"Moral") as GameMoral).record_tone(&"arrogant")
	level = await _to_the_menu_and_back(main)
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_offer")
	var again: bool = balloon != null
	var undone: bool = not (root.get_node(^"Moral") as GameMoral).leans_arrogant()
	var refused: bool = again and await _answer(level, balloon, REFUSE)
	var saved_answer: bool = (SaveFile.new().read().get("state", {}).get("events", [])
			as PackedStringArray).has("answered_asmodeus_offer")
	level = await _to_the_menu_and_back(main)
	await wait_frames(OUTSIDE_FRAMES)
	var not_again: bool = not (level.get_node(^"Asmodeus") as Asmodeus).is_talking()
	await remove_main(main)
	return report(first and again and undone and refused and saved_answer and not_again,
			("Left before the answer: she talks %s; after Continue, again %s, the tone undone %s; "
			+ "refused %s, saved at once %s; after Continue, she does not talk again %s")
			% [first, again, undone, refused, saved_answer, not_again])


## An offer his deaths brought, and she starts it; he goes to the menu before answering. After
## Continue, it still waits for its zone, and walking in brings it back.
func _a_death_offer_left_before_the_answer_waits_again() -> bool:
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	var phase_2_save: SavePoint = level.get_node(^"Phase2Save") as SavePoint
	level.player.global_position = _inside(phase_2_save)
	await _answer(level, await _talk(level, "asmodeus_offer"), REFUSE)
	var respawn: Vector2 = (phase_2_save.get_node(^"Respawn") as Node2D).global_position
	var zone: StringName = level.zone_at(respawn)
	var deaths: int = 0
	while not _stats().has_death_offer() and deaths < MAX_DEATHS:
		_stats().record_death(zone)
		deaths += 1
	level.player.global_position = respawn
	var first: bool = await _talk(level, "asmodeus_deaths") != null
	level = await _to_the_menu_and_back(main)
	var still_waits: bool = _stats().has_death_offer() and _stats().get_death_offer_zone() == zone
	level.player.global_position = respawn
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_deaths")
	var again: bool = balloon != null
	var refused: bool = again and await _answer(level, balloon, REFUSE)
	var taken: bool = not _stats().has_death_offer()
	await remove_main(main)
	return report(first and still_waits and again and refused and taken,
			("A death offer left before the answer: she talks %s; after Continue it still waits "
			+ "at its zone %s, and walking in she talks again %s; refused %s, it no longer waits %s")
			% [first, still_waits, again, refused, taken])


## His deaths mark the zone of phase 2's start, and deaths elsewhere still count and mark that zone
## too. Standing in the second, she makes its offer there, asking about its deaths; refused, the
## first still waits, and she makes it once he stands there.
func _two_zones_wait_and_each_is_made_where_it_waits() -> bool:
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	var start: Vector2 = level.player.global_position
	var phase_2_save: SavePoint = level.get_node(^"Phase2Save") as SavePoint
	level.player.global_position = _inside(phase_2_save)
	await _answer(level, await _talk(level, "asmodeus_offer"), REFUSE)
	var respawn: Vector2 = (phase_2_save.get_node(^"Respawn") as Node2D).global_position
	var first: StringName = level.zone_at(respawn)
	var second: StringName = level.zone_at(start)
	var deaths: int = 0
	while not _stats().has_death_offer_at(first) and deaths < MAX_DEATHS:
		_stats().record_death(first)
		deaths += 1
	while not _stats().has_death_offer_at(second) and deaths < MAX_DEATHS * 2:
		_stats().record_death(second)
		deaths += 1
	var both: bool = (first != second and _stats().has_death_offer_at(first)
			and _stats().has_death_offer_at(second))
	level.player.global_position = start
	await wait_until_on_floor(level.player)
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_deaths")
	var at_second: bool = (balloon != null
			and _stats().offer_zone_deaths() == _stats().deaths_in_zone(second))
	var refused: bool = balloon != null and await _answer(level, balloon, REFUSE)
	var first_waits: bool = (not _stats().has_death_offer_at(second)
			and _stats().has_death_offer_at(first))
	level.player.global_position = respawn
	balloon = await _talk(level, "asmodeus_deaths")
	var at_first: bool = balloon != null and _stats().offer_zone_deaths() == _stats().deaths_in_zone(first)
	var refused_again: bool = balloon != null and await _answer(level, balloon, REFUSE)
	var none: bool = not _stats().has_death_offer()
	await remove_main(main)
	return report(both and at_second and refused and first_waits and at_first and refused_again
			and none,
			("Two zones: %s and %s both wait %s; in the second she asks about its deaths %s; refused "
			+ "%s, the first still waits %s; there she asks about its own %s; refused %s, none waits %s")
			% [first, second, both, at_second, refused, first_waits, at_first, refused_again, none])


## Whether, once her glide is over, the level's camera is held by her and its middle is between her
## and the man, Centre Height above their feet, whatever the zone would show.
func _camera_is_centred_on_the_two(level: Level) -> bool:
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var camera: GameCamera = level.get_node(^"GameCamera") as GameCamera
	await wait_frames(ceili(asmodeus.centre_time * 60.0) + 2)
	var middle: Vector2 = ((asmodeus.global_position + level.player.global_position) / 2.0
			- Vector2(0.0, asmodeus.centre_height))
	var centred: bool = camera.is_directed() and camera.global_position.distance_to(middle) < 1.0
	if not centred:
		print("  camera at %s, directed %s; the middle of the two %s" % [camera.global_position,
				camera.is_directed(), middle])
	return centred


## Main Menu from the pause, then Continue, as the player would; the new level, on the floor.
func _to_the_menu_and_back(main: Node) -> Level:
	(main.get_node(^"%PauseMenu") as PauseMenu).main_menu_requested.emit()
	await wait_frames(2)
	(main.get_node(^"%MainMenu") as MainMenu).continue_requested.emit()
	await wait_until(func() -> bool: return level_in(main) != null, TALK_FRAMES)
	var level: Level = level_in(main) as Level
	await wait_until_on_floor(level.player)
	return level


## Main with only level 1, in a new game.
func _new_game(entries: Array[LevelEntry]) -> Node:
	_progress().reset()
	_stats().reset()
	var main: Node = await new_main(entries)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await wait_until(func() -> bool: return level_in(main) != null, TALK_FRAMES)
	await wait_until_on_floor((level_in(main) as Level).player)
	return main


func main_menu_entries() -> Array[LevelEntry]:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1"
	entry.scene = load(LEVEL_PATH) as PackedScene
	entry.starts_game = true
	var entries: Array[LevelEntry] = [entry]
	return entries


## Her balloon once she talks from cue in level and shows a line; null if she never does.
func _talk(level: Level, cue: String) -> DialogueBalloon:
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var found: Array[DialogueBalloon] = []
	await wait_until(func() -> bool:
		if not is_instance_valid(asmodeus) or asmodeus.get_talking_cue() != cue:
			return false
		for child: Node in asmodeus.get_children():
			if child is DialogueBalloon and (child as DialogueBalloon).dialogue_line != null:
				found.append(child)
				return true
		return false, TALK_FRAMES)
	return found[0] if not found.is_empty() else null


## Skips the lines and answers each choice until her talk ends: at the offer's answers, the one at
## index (none when -1, and then the talk must have no offer), at any other choice the first. Says
## whether the talk ended, and with index set, whether the offer was answered.
func _answer(level: Level, balloon: DialogueBalloon, index: int) -> bool:
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var ended: Array[bool] = [false]
	asmodeus.talk_ended.connect(func(_cue: String) -> void: ended[0] = true, CONNECT_ONE_SHOT)
	var offer_answered: bool = false
	for i: int in MAX_CHOICES:
		if not is_instance_valid(balloon) or ended[0]:
			break
		balloon.skip_to_the_next_choice()
		await wait_until(func() -> bool:
			return not is_instance_valid(balloon) or ended[0] or balloon.is_at_a_choice(), TALK_FRAMES)
		if not is_instance_valid(balloon) or ended[0] or not balloon.is_at_a_choice():
			break
		var line: DialogueLine = balloon.dialogue_line
		var at_offer: bool = line.responses.size() == OFFER_ANSWERS and not offer_answered
		if at_offer and index < 0:
			return false
		balloon.next(line.responses[index if at_offer else 0].next_id)
		offer_answered = offer_answered or at_offer
		await wait_until(func() -> bool:
			return not is_instance_valid(balloon) or ended[0] or balloon.dialogue_line != line,
			TALK_FRAMES)
	if index >= 0 and not offer_answered:
		return false
	return await wait_until(func() -> bool: return ended[0], TALK_FRAMES)


## Whether level's man lands near its ArrivalPoint TENT.
func _stands_at_the_tent(level: Level) -> bool:
	var point: ArrivalPoint = ArrivalPoint.find_in(level, TENT)
	if point == null or not await wait_until_on_floor(level.player):
		return false
	return level.player.global_position.distance_to(point.global_position) <= NEAR_THE_POINT


func _is_shown(main: Node, path: NodePath) -> bool:
	var node: CanvasItem = main.get_node_or_null(^"MainMenu").get_node_or_null(path) as CanvasItem
	return node != null and node.is_visible_in_tree()


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


func _stats() -> GameRunStats:
	return root.get_node(^"RunStats") as GameRunStats


func _delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_PATH + SaveFile.COPY_SUFFIX)
	DirAccess.remove_absolute(SaveFile.new().get_run_path())


## The middle of save_point's area, where the man walks into it: the area need not be at the node.
func _inside(save_point: SavePoint) -> Vector2:
	return (save_point.get_node(^"CollisionShape2D") as Node2D).global_position
