# Checks Asmodeus in level 1, in the main scene, as the game plays her. In a new game:
# - Reaching phase 2's save, she talks from asmodeus_offer; while she talks the dogs stand still.
#   Refusing, he stays in the level and moves again, with the dogs.
# - An offer his deaths brought waits while he stands outside its zone, and she makes it from
#   asmodeus_deaths once he walks into it. Accepting takes him to the tent at the level's end: he
#   stands there, not at phase 2's start, though he reached it. No more offers come for his deaths.
# - At the tent she gives the gift, then the stairs, and only then the level ends: the main menu
#   shows, no level in the slot, and the save keeps level 1 at the tent.
# - Reaching phase 3's save, she talks from asmodeus_second_offer.
# The tests use a save file of their own.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_asmodeus.gd
extends "res://tests/support/menu_test.gd"

const SAVE_PATH: String = "user://test_lust_asmodeus.cfg"
const LEVEL_PATH: String = "res://levels/lust/level1.tscn"
const SHORTCUT: StringName = &"lust_shortcut"
const TENT: StringName = &"asmodeus_tent"
## The answers of Lust's shortcut cues: the first two accept it, the last two refuse it.
const ACCEPT: int = 0
const REFUSE: int = 2
## The answer of asmodeus_gift that refuses the charm.
const KEEP_IT: int = 1
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
	level.player.global_position = phase_2_save.global_position
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_offer")
	var talked: bool = balloon != null
	var dogs_still: bool = not dogs.can_process()
	var refused: bool = await _answer(level, balloon, REFUSE)
	var moves_again: bool = (level.player.get_speed_multiplier() == 1.0 and dogs.can_process()
			and level_in(main) == level)
	results.append(report(talked and dogs_still and refused and moves_again,
			("Phase 2: she talks %s, the dogs still %s; refused, the talk ends %s, he and the dogs "
			+ "move again in the same level %s") % [talked, dogs_still, refused, moves_again]))

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
	var taken: bool = not _stats().has_death_offer()
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var beside: bool = asmodeus.global_position.distance_to(level.player.global_position) < 400.0
	results.append(report(outside and waits and not_yet and death_talk and taken and beside,
			("Deaths: outside the zone %s, an offer waits %s after %d deaths, none made outside %s; "
			+ "walking in, she talks %s beside him %s, the offer taken %s")
			% [outside, waits, deaths, not_yet, death_talk, beside, taken]))

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
			and saved_at == "%s at %s" % [LEVEL_PATH, TENT] and gift_said and stairs_said and ended,
			("Shortcut: a new level %s, at the tent %s, no more offers %s, saved %s; the gift %s, "
			+ "the stairs %s, then the level ends to the menu %s")
			% [changed, at_the_tent, closed, saved_at, gift_said, stairs_said, ended]))
	await remove_main(main)
	return results


func _phase_3_has_the_second_offer() -> bool:
	_delete_save()
	var main: Node = await _new_game(main_menu_entries())
	var level: Level = level_in(main) as Level
	level.player.global_position = (level.get_node(^"Phase3Save") as Node2D).global_position
	var balloon: DialogueBalloon = await _talk(level, "asmodeus_second_offer")
	var talked: bool = balloon != null
	var refused: bool = talked and await _answer(level, balloon, REFUSE)
	await remove_main(main)
	return report(talked and refused,
			"Phase 3: she talks from asmodeus_second_offer %s, and a refusal ends it %s"
			% [talked, refused])


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


## Skips to the answers, picks the one at index (none when -1), skips the rest, and says whether
## her talk then ended.
func _answer(level: Level, balloon: DialogueBalloon, index: int) -> bool:
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var ended: Array[bool] = [false]
	asmodeus.talk_ended.connect(func(_cue: String) -> void: ended[0] = true, CONNECT_ONE_SHOT)
	balloon.skip_to_the_next_choice()
	if index >= 0:
		await wait_until(func() -> bool:
			return not is_instance_valid(balloon) or balloon.is_at_a_choice(), TALK_FRAMES)
		if not is_instance_valid(balloon) or not balloon.is_at_a_choice():
			return false
		balloon.next(balloon.dialogue_line.responses[index].next_id)
		await wait_until(func() -> bool:
			return not is_instance_valid(balloon) or balloon.dialogue_line != null, TALK_FRAMES)
		if is_instance_valid(balloon) and balloon.dialogue_line != null:
			balloon.skip_to_the_next_choice()
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
