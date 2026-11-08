# Checks Lust's shortcut in the main scene. In a new game in phase 1, accepting it through Offers,
# with no balloon showing, takes the man behind the fade to phase 3, standing at the ArrivalPoint
# by Asmodeus's tent, not at the phase's start, and saves phase 3 with that point. A death there
# brings him back to the tent, and so does Continue. The tests use a save file of their own.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_offer_shortcut.gd
extends "res://tests/support/menu_test.gd"

const SAVE_PATH: String = "user://test_offer_shortcut.cfg"
const PHASE_1_PATH: String = "res://scenes/levels/Lust/LustLevel_Phase1_Cave.tscn"
const PHASE_3_PATH: String = "res://scenes/levels/Lust/LustLevel_Phase3.tscn"
const PHASE_3_ROOT: StringName = &"LustPhase3"
const SHORTCUT: StringName = &"lust_shortcut"
const TENT: StringName = &"asmodeus_tent"
## Physics frames to wait for a phase change, fade in included.
const CHANGE_FRAMES: int = 180
## How far from the point he may stand once on the floor, in px: he lands from a little above it.
const NEAR_THE_POINT: float = 64.0


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append(await _the_shortcut_goes_to_the_tent_and_comes_back_there())
	_delete_save()
	_progress().reset()
	SaveFile.default_path = ""
	finish(results)


func _the_shortcut_goes_to_the_tent_and_comes_back_there() -> bool:
	_delete_save()
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	_offers().accept(SHORTCUT)
	var changed: bool = await wait_until(func() -> bool:
		return level_in(main) != null and level_in(main).name == PHASE_3_ROOT, CHANGE_FRAMES)
	var at_the_tent: bool = changed and await _stands_at_the_tent(main)
	var saved: Dictionary = SaveFile.new().read()
	var saved_point: Variant = saved.get("state", {}).get("arrival_point", "")
	var level: Level = level_in(main) as Level
	var restarted: bool = false
	var back_after_death: bool = false
	if level != null:
		var level_id: int = level.get_instance_id()
		(level.player.get_node(^"GrabEscape") as GrabEscape).died.emit()
		restarted = await wait_until(func() -> bool:
			var now: Node = level_in(main)
			return now != null and now.get_instance_id() != level_id)
		back_after_death = restarted and await _stands_at_the_tent(main)
	main.call(&"_on_main_menu_requested")
	await process_frame
	await tap(KEY_ENTER)
	await wait_frames(3)
	var back_on_continue: bool = await _stands_at_the_tent(main)
	await remove_main(main)
	_progress().reset()
	_delete_save()
	return report(changed and at_the_tent and saved.get("scene", "") == PHASE_3_PATH
			and saved_point == String(TENT) and restarted and back_after_death and back_on_continue,
			("Shortcut: phase 3 %s, at the tent %s, saved %s at %s; a death restarts %s at the tent "
			+ "%s; Continue at the tent %s")
			% [changed, at_the_tent, saved.get("scene", ""), saved_point, restarted,
			back_after_death, back_on_continue])


## Whether the level's player lands near its ArrivalPoint TENT.
func _stands_at_the_tent(main: Node) -> bool:
	var level: Level = level_in(main) as Level
	if level == null or level.name != PHASE_3_ROOT:
		return false
	var point: ArrivalPoint = ArrivalPoint.find_in(level, TENT)
	if point == null or not await wait_until_on_floor(level.player):
		return false
	return level.player.global_position.distance_to(point.global_position) <= NEAR_THE_POINT


func _level_1_entry() -> Array[LevelEntry]:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1"
	entry.scene = load(PHASE_1_PATH) as PackedScene
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
