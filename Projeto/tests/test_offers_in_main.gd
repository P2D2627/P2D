# Checks the offers with the main scene, in a new game in the test room. An upgrade, once accepted,
# is saved at once, so a death before the next checkpoint keeps it and keeps the crucifix lost. A
# level left with a balloon showing, as by the pause's Main Menu, forgets the offers waiting on it:
# an upgrade accepted afterwards, with no balloon, is given at once, and a shortcut accepted in the
# balloon that was cut short never takes him anywhere. The tests use a save file of their own.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_offers_in_main.gd
extends "res://tests/support/menu_test.gd"

const SAVE_PATH: String = "user://test_offers_in_main.cfg"
const TEST_ROOM_PATH: String = "res://scenes/levels/test_room/test_room.tscn"
const CHARM: StringName = &"charm"
const SHORTCUT: StringName = &"lust_shortcut"


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append(await _an_upgrade_is_saved_at_once_and_outlives_a_death())
	results.append(await _a_level_left_mid_balloon_forgets_the_offers())
	_delete_save()
	_progress().reset()
	_offers().clear()
	SaveFile.default_path = ""
	finish(results)


func _an_upgrade_is_saved_at_once_and_outlives_a_death() -> bool:
	var main: Node = await _new_game()
	_offers().accept(CHARM)
	var state: Dictionary = SaveFile.new().read().get("state", {})
	var saved_upgrade: bool = String(CHARM) in state.get("upgrades", PackedStringArray())
	var saved_without_crucifix: bool = state.get("has_crucifix", true) == false
	var level: Level = level_in(main) as Level
	var restarted: bool = false
	if level != null:
		var level_id: int = level.get_instance_id()
		level.player.died.emit()
		restarted = await wait_until(func() -> bool:
			var now: Node = level_in(main)
			return now != null and now.get_instance_id() != level_id)
	var kept: bool = _progress().has_upgrade(CHARM)
	var crucifix_back: bool = _progress().has_crucifix
	await _end(main)
	return report(saved_upgrade and saved_without_crucifix and restarted and kept
			and not crucifix_back,
			("The charm, then a death: saved %s, saved without the crucifix %s; restarted %s, "
			+ "charm kept %s, crucifix back %s")
			% [saved_upgrade, saved_without_crucifix, restarted, kept, crucifix_back])


func _a_level_left_mid_balloon_forgets_the_offers() -> bool:
	var main: Node = await _new_game()
	var dialogue_manager: Node = root.get_node(^"DialogueManager")
	dialogue_manager.dialogue_started.emit(null)
	_offers().accept(SHORTCUT)
	main.call(&"_on_main_menu_requested")
	await process_frame
	_offers().accept(CHARM)
	var given_at_once: bool = _progress().has_upgrade(CHARM)
	var asked: Array = []
	var listen: Callable = func(path: String, arrival: StringName) -> void:
		asked.append([path, arrival])
	_offers().scene_requested.connect(listen)
	dialogue_manager.dialogue_started.emit(null)
	dialogue_manager.dialogue_ended.emit(null)
	_offers().scene_requested.disconnect(listen)
	await _end(main)
	return report(given_at_once and asked.is_empty(),
			"Main Menu with a balloon showing: the next upgrade given at once %s, then asked %s"
			% [given_at_once, asked])


## A main scene in a new game in the test room, with no save before it.
func _new_game() -> Node:
	_delete_save()
	_progress().reset()
	_offers().clear()
	var main: Node = await new_main(_test_room_entry())
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	return main


func _end(main: Node) -> void:
	await remove_main(main)
	_progress().reset()
	_offers().clear()
	_delete_save()


func _test_room_entry() -> Array[LevelEntry]:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Test room"
	entry.scene = load(TEST_ROOM_PATH) as PackedScene
	entry.starts_game = true
	var entries: Array[LevelEntry] = [entry]
	return entries


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


func _offers() -> GameOffers:
	return root.get_node(^"Offers") as GameOffers


func _delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_PATH + SaveFile.COPY_SUFFIX)
