# Checks the save. What GameState and Moral hold reads back from the file as it was. A save that is
# missing, damaged, of another version or of a scene that is gone reads as no save, and a write
# leaves no copy behind. In the main scene, Continue only shows with a save, and is then selected. A
# new game empties the state and saves at once, with the word in the corner; a level that does not
# start the game saves nothing. A save keeps the phase he is in, and a debug jump the phase it goes
# to, before the restart. A death saves nothing and undoes what came after the save; outside
# the run, as in the test room, it leaves the state alone. Leaving the tutorial saves, and a death
# after it starts in the hall. Walking into an exit saves the next phase, and Continue comes back to
# it, with the state of that moment, whatever happened after it. A new game over a save asks first.
# The run's numbers (RunStats) read back from a file of their own beside the save, and writing them
# leaves the save as it was. A new game empties them; a death counts, is written at once, and is not
# put back with the rest; Continue puts the numbers back as they were written. With three slots,
# Continue opens the slot played last, passing over a damaged one, and the game then writes to that
# slot only; a new game after it starts in the slot picked and leaves the other slots as they were.
# The tests use a file of their own, never the player's save.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_save_game.gd
extends "res://tests/support/menu_test.gd"

const SAVE_PATH: String = "user://test_save.cfg"
const PHASE_1_PATH: String = "res://scenes/levels/lust/LustLevel_Phase1_Cave.tscn"
const PHASE_2_PATH: String = "res://scenes/levels/lust/LustLevel_Phase2.tscn"
const TEST_ROOM_PATH: String = "res://scenes/levels/test_room/test_room.tscn"
const LEVEL_1_PATH: String = "res://scenes/levels/lust/level1.tscn"
const PHASE_2_ROOT: StringName = &"LustPhase2"
const AN_EVENT: StringName = &"an_event"
## Physics frames to wait for a phase change, fade in included.
const CHANGE_FRAMES: int = 180


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append(await _the_state_reads_back_from_the_file())
	results.append(await _a_save_that_can_not_be_used_reads_as_none())
	results.append(await _a_write_leaves_only_the_save())
	results.append(await _continue_shows_only_with_a_save_and_is_then_selected())
	results.append(await _a_new_game_empties_the_state_and_saves())
	results.append(await _a_save_keeps_its_phase_and_a_jump_the_one_it_goes_to())
	results.append(await _a_level_that_does_not_start_the_game_saves_nothing())
	results.append(await _a_death_saves_nothing_and_undoes_what_came_after_the_save())
	results.append(await _a_death_in_a_level_outside_the_run_leaves_the_state())
	results.append(await _past_the_tutorial_a_death_starts_in_the_hall())
	results.append(await _a_new_game_over_a_save_asks_first())
	results.append(await _an_exit_saves_and_continue_comes_back_to_that_moment())
	results.append(await _the_run_reads_back_beside_the_save())
	results.append(await _a_death_counts_and_continue_puts_the_numbers_back())
	results.append(await _continue_takes_the_slot_played_last_and_saves_there())
	results.append(await _a_new_game_after_continue_starts_in_the_slot_picked())
	_delete_save()
	_progress().reset()
	_run_stats().reset()
	SaveFile.default_path = ""
	finish(results)


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


func _moral() -> GameMoral:
	return root.get_node(^"Moral") as GameMoral


func _run_stats() -> GameRunStats:
	return root.get_node(^"RunStats") as GameRunStats


## Deletes every slot, with its run's numbers and any copy left of them.
func _delete_save() -> void:
	for slot: int in range(1, SaveSlots.COUNT + 1):
		var file: SaveFile = SaveSlots.file_of(slot)
		for path: String in [file.path, file.get_run_path()]:
			DirAccess.remove_absolute(path)
			DirAccess.remove_absolute(path + SaveFile.COPY_SUFFIX)


## Writes slot's save of the phase at scene_path, with only event marked, as if made at seconds.
func _write_slot(slot: int, scene_path: String, event: StringName, seconds: float) -> void:
	_progress().reset()
	_progress().mark_event(event)
	var file: SaveFile = SaveSlots.file_of(slot)
	file.clock = func() -> float: return seconds
	file.write(scene_path, _progress().to_save(), 1)
	_progress().reset()


func _write_text(text: String) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## The state as text, to compare two states of it.
func _state_text() -> String:
	return var_to_str(_progress().to_save())


func _level_1_entry() -> Array[LevelEntry]:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1"
	entry.scene = load(PHASE_1_PATH) as PackedScene
	entry.starts_game = true
	var entries: Array[LevelEntry] = [entry]
	return entries


## A main scene with Level 1, on a new game already in the level. Enter opens the list and Enter
## picks the level.
func _main_in_a_new_game() -> Node:
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	return main


func _the_state_reads_back_from_the_file() -> bool:
	_delete_save()
	_progress().reset()
	_moral().record_tone(&"arrogant")
	_moral().record_tone(&"humble")
	_moral().record_listening(&"an_offer", 12.5)
	_progress().mark_event(AN_EVENT)
	_progress().lose_crucifix()
	_progress().player_name = "Anyone"
	var before: String = _state_text()
	var wrote: bool = SaveFile.new().write(PHASE_2_PATH, _progress().to_save(), 1)
	_progress().reset()
	var emptied: bool = _state_text() != before
	var saved: Dictionary = SaveFile.new().read()
	var scene_ok: bool = saved.get("scene", "") == PHASE_2_PATH
	_progress().from_save(saved.get("state", {}))
	var same: bool = _state_text() == before
	var kept: bool = _progress().has_event(AN_EVENT) and not _progress().has_crucifix
	_progress().reset()
	_delete_save()
	return report(wrote and emptied and scene_ok and same and kept,
			"Reads back: wrote %s, reset changed it %s, scene %s, state the same %s, event and crucifix %s"
			% [wrote, emptied, scene_ok, same, kept])


func _a_save_that_can_not_be_used_reads_as_none() -> bool:
	_delete_save()
	var missing: bool = not SaveFile.new().exists()
	_write_text("this is not [ a config file = ")
	var damaged: bool = not SaveFile.new().exists()
	_write_text('[save]\nversion=%d\nscene="%s"\nstate={}\n' % [SaveFile.FILE_VERSION + 1, PHASE_2_PATH])
	var other_version: bool = not SaveFile.new().exists()
	_write_text('[save]\nversion=%d\nscene="res://gone.tscn"\nstate={}\n' % SaveFile.FILE_VERSION)
	var gone: bool = not SaveFile.new().exists()
	var bad_fields: bool = true
	for fields: String in ['version="2"', "version=0", 'version=2\nphase="two"',
			'version=2\nsaved_at="later"']:
		_write_text('[save]\n%s\nscene="%s"\nstate={}\n' % [fields, PHASE_2_PATH])
		bad_fields = bad_fields and not SaveFile.new().exists()
	_write_text('[save]\nversion=%d\nscene="%s"\nstate={}\n' % [SaveFile.FILE_VERSION, PHASE_2_PATH])
	var good: bool = SaveFile.new().exists()
	_delete_save()
	return report(missing and damaged and other_version and gone and bad_fields and good,
			("No save from: missing %s, damaged %s, other version %s, scene gone %s, a version, phase "
			+ "or time of the wrong kind %s; a good one reads %s")
			% [missing, damaged, other_version, gone, bad_fields, good])


func _a_write_leaves_only_the_save() -> bool:
	_delete_save()
	var first: bool = SaveFile.new().write(PHASE_1_PATH, {}, 1)
	var second: bool = SaveFile.new().write(PHASE_2_PATH, {}, 1)
	var scene: String = SaveFile.new().read().get("scene", "")
	var no_copy: bool = not FileAccess.file_exists(SAVE_PATH + SaveFile.COPY_SUFFIX)
	_delete_save()
	return report(first and second and scene == PHASE_2_PATH and no_copy,
			"Two writes: %s and %s, the last one kept %s, no copy left %s"
			% [first, second, scene == PHASE_2_PATH, no_copy])


func _continue_shows_only_with_a_save_and_is_then_selected() -> bool:
	_delete_save()
	var main: Node = await new_main(_level_1_entry())
	var button: Button = main_menu_node(main, ^"%ContinueButton") as Button
	var hidden_without: bool = not button.visible
	var play_selected: bool = has_focus(main_menu_node(main, ^"%PlayButton"))
	await remove_main(main)
	SaveFile.new().write(PHASE_1_PATH, _progress().to_save(), 1)
	main = await new_main(_level_1_entry())
	button = main_menu_node(main, ^"%ContinueButton") as Button
	var shows_with: bool = button.visible
	var selected: bool = has_focus(button)
	await remove_main(main)
	_delete_save()
	return report(hidden_without and play_selected and shows_with and selected,
			"Continue: hidden with no save %s, Play selected %s; with one it shows %s, selected %s"
			% [hidden_without, play_selected, shows_with, selected])


func _a_new_game_empties_the_state_and_saves() -> bool:
	_delete_save()
	_progress().mark_event(AN_EVENT)
	var main: Node = await _main_in_a_new_game()
	var indicator: SaveIndicator = main.get_node(^"%SaveIndicator") as SaveIndicator
	var says_so: bool = await wait_until(indicator.is_showing, 30)
	var saved: Dictionary = SaveFile.new().read()
	var emptied: bool = not _progress().has_event(AN_EVENT)
	await remove_main(main)
	_delete_save()
	return report(saved.get("scene", "") == PHASE_1_PATH and says_so and emptied,
			"New game: saved phase 1 %s, the word shows %s, the state emptied %s"
			% [saved.get("scene", "") == PHASE_1_PATH, says_so, emptied])


## The debug jump saves before the restart, while the run's numbers still say the phase he jumps
## from, so it has to save the phase it goes to.
func _a_save_keeps_its_phase_and_a_jump_the_one_it_goes_to() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var phase: int = SaveFile.new().read().get("phase", 0)
	var in_phase: bool = phase == _run_stats().get_phase() and phase == 1
	await remove_main(main)
	_delete_save()
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1"
	entry.scene = load(LEVEL_1_PATH) as PackedScene
	entry.starts_game = true
	var entries: Array[LevelEntry] = [entry]
	main = await new_main(entries)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	# The save point that starts phase 2 saves phase 2: the level hears it first and moves the run's
	# numbers to phase 2, and only then does Main save. What is checked is that order, so the man's
	# walking in is told to the save point straight away.
	var level: Level = level_in(main) as Level
	var phase_2_save: SavePoint = level.get_node(^"Phase2Save") as SavePoint
	phase_2_save.body_entered.emit(level.player)
	var saved_2: bool = await wait_until(func() -> bool:
		return SaveFile.new().read().get("phase", 0) == 2, CHANGE_FRAMES)
	var seen: String = "reached %s, saved phase %s, run in phase %d" % [phase_2_save.is_reached(),
			SaveFile.new().read().get("phase", "none"), _run_stats().get_phase()]
	var jumped: bool = level.jump_to_phase(3)
	var saved_3: bool = await wait_until(func() -> bool:
		return SaveFile.new().read().get("phase", 0) == 3, CHANGE_FRAMES)
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_save()
	return report(in_phase and saved_2 and jumped and saved_3,
			("Phase: a new game saves phase 1 %s; phase 2's save point saves phase 2 %s (%s); a jump "
			+ "to 3 %s saves phase 3 %s") % [in_phase, saved_2, seen, jumped, saved_3])


func _a_level_that_does_not_start_the_game_saves_nothing() -> bool:
	_delete_save()
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Test room"
	entry.scene = load(TEST_ROOM_PATH) as PackedScene
	var entries: Array[LevelEntry] = [entry]
	var main: Node = await new_main(entries)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await wait_frames(5)
	var started: bool = level_in(main) != null
	var nothing: bool = not FileAccess.file_exists(SAVE_PATH)
	await remove_main(main)
	return report(started and nothing, "Test room: started %s, nothing saved %s" % [started, nothing])


## What the man did since the save is as if he had not done it.
func _a_death_saves_nothing_and_undoes_what_came_after_the_save() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var saved_text: String = FileAccess.get_file_as_string(SAVE_PATH)
	_progress().mark_event(AN_EVENT)
	var restarted: bool = await _die_and_wait_for_the_new_copy(main)
	var same_file: bool = FileAccess.get_file_as_string(SAVE_PATH) == saved_text
	var undone: bool = not _progress().has_event(AN_EVENT)
	await remove_main(main)
	_delete_save()
	return report(restarted and same_file and undone,
			"Death: the phase restarts %s, the file the same %s, what came after the save undone %s"
			% [restarted, same_file, undone])


## A level that does not start the game keeps no save to go back to, even with one on disk.
func _a_death_in_a_level_outside_the_run_leaves_the_state() -> bool:
	_delete_save()
	SaveFile.new().write(PHASE_1_PATH, _progress().to_save(), 1)
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Test room"
	entry.scene = load(TEST_ROOM_PATH) as PackedScene
	var entries: Array[LevelEntry] = [entry]
	var main: Node = await new_main(entries)
	# Past Continue and Load, to New Game.
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	_progress().mark_event(AN_EVENT)
	var restarted: bool = await _die_and_wait_for_the_new_copy(main)
	var kept: bool = _progress().has_event(AN_EVENT)
	await remove_main(main)
	_progress().reset()
	_delete_save()
	return report(restarted and kept, "Test room: restarts %s, state left as it was %s"
			% [restarted, kept])


## Out of the tutorial, the game saves, and that save is the hall: a death after it starts there,
## with what he did in the tutorial kept and what he did after it undone.
func _past_the_tutorial_a_death_starts_in_the_hall() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var level: Level = level_in(main) as Level
	var point: SavePoint = level.get_node(^"TutorialSave") as SavePoint
	var hall: Vector2 = (level.get_node(^"HallStart") as Marker2D).global_position
	_moral().record_tone(&"arrogant")
	var state_of_the_tutorial: Dictionary = _progress().to_save()
	await wait_until_on_floor(level.player)
	level.player.global_position = point.global_position
	var marked: bool = await wait_until(
			func() -> bool: return _progress().has_event(point.event), 30)
	var indicator: SaveIndicator = main.get_node(^"%SaveIndicator") as SaveIndicator
	var says_so: bool = await wait_until(indicator.is_showing, 30)
	var moral_saved: bool = (SaveFile.new().read()["state"]["moral"]["arrogant"]
			== state_of_the_tutorial["moral"]["arrogant"])
	_moral().record_tone(&"arrogant")
	var restarted: bool = await _die_and_wait_for_the_new_copy(main)
	var player: Player = (level_in(main) as Level).player
	var at_hall: bool = player.global_position.distance_to(hall) < 2.0
	var camera: Node2D = level_in(main).get_node(^"GameCamera") as Node2D
	await wait_frames(2)
	var camera_there: bool = camera.global_position.distance_to(hall) < 1200.0
	var undone: bool = (_moral().to_save()["arrogant"]
			== state_of_the_tutorial["moral"]["arrogant"])
	await remove_main(main)
	_delete_save()
	return report(marked and says_so and moral_saved and restarted and at_hall and camera_there
			and undone,
			("Out of the tutorial: marked %s, the word shows %s, the tutorial's answers saved %s; a "
			+ "death restarts %s at the hall %s, the camera there %s, what came after undone %s")
			% [marked, says_so, moral_saved, restarted, at_hall, camera_there, undone])


## New Game with a save lists the slots, and the slot with the save asks first, and only then: No
## leaves the save, with that slot selected again, and Yes starts over there. With one level, New
## Game lists the slots at once, with the first empty one, slot 2, selected; Up goes to slot 1.
func _a_new_game_over_a_save_asks_first() -> bool:
	_delete_save()
	_progress().mark_event(AN_EVENT)
	var kept_state: String = _state_text()
	SaveFile.new().write(PHASE_2_PATH, _progress().to_save(), 1)
	var main: Node = await new_main(_level_1_entry())
	var dialog: ConfirmationDialog = main_menu_node(main, ^"%ReplaceSaveDialog") as ConfirmationDialog
	var slot_1: Control = main_menu_node(main, ^"%SlotButtons").get_child(0) as Control
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await tap(KEY_UP)
	await tap(KEY_ENTER)
	var asked: bool = (dialog.visible and level_in(main) == null
			and dialog.gui_get_focus_owner() == dialog.get_cancel_button())
	await tap(KEY_ENTER)
	await process_frame
	var no_leaves_it: bool = (not dialog.visible and level_in(main) == null
			and SaveFile.new().read().get("scene", "") == PHASE_2_PATH
			and _state_text() == kept_state
			and root.gui_get_focus_owner() == slot_1)
	await tap(KEY_ENTER)
	var asked_again: bool = dialog.visible
	dialog.get_ok_button().pressed.emit()
	await process_frame
	await process_frame
	var yes_starts: bool = (level_in(main) != null
			and SaveFile.new().read().get("scene", "") == PHASE_1_PATH
			and not _progress().has_event(AN_EVENT))
	await remove_main(main)
	_delete_save()
	return report(asked and no_leaves_it and asked_again and yes_starts,
			"Over a save: asks %s, No leaves it %s, asks again %s, Yes starts over %s"
			% [asked, no_leaves_it, asked_again, yes_starts])


func _die_and_wait_for_the_new_copy(main: Node) -> bool:
	var level: Level = level_in(main) as Level
	var level_id: int = level.get_instance_id()
	(level.player.get_node(^"GrabEscape") as GrabEscape).died.emit()
	return await wait_until(func() -> bool:
		var now: Node = level_in(main)
		return now != null and now.get_instance_id() != level_id)


func _an_exit_saves_and_continue_comes_back_to_that_moment() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	_progress().mark_event(AN_EVENT)
	var state_at_the_exit: String = _state_text()
	var exit: PhaseExit = level_in(main).get_node(^"PhaseExit") as PhaseExit
	var player: Player = (level_in(main) as Level).player
	await wait_until_on_floor(player)
	player.global_position = exit.global_position + Vector2(0, 72)
	var changed: bool = await wait_until(func() -> bool:
		return level_in(main) != null and level_in(main).name == PHASE_2_ROOT, CHANGE_FRAMES)
	var indicator: SaveIndicator = main.get_node(^"%SaveIndicator") as SaveIndicator
	var says_so: bool = await wait_until(indicator.is_showing, 60)
	await wait_until(func() -> bool: return is_zero_approx(
			(main.get_node(^"%Fade") as ColorRect).color.a), CHANGE_FRAMES)
	var saved: Dictionary = SaveFile.new().read()
	_moral().record_tone(&"arrogant")
	await tap(KEY_ESCAPE)
	main.call(&"_on_main_menu_requested")
	await process_frame
	var button: Button = main_menu_node(main, ^"%ContinueButton") as Button
	var offered: bool = button.visible and has_focus(button)
	await tap(KEY_ENTER)
	await wait_frames(3)
	var level: Node = level_in(main)
	var back: bool = level != null and level.name == PHASE_2_ROOT
	var same_state: bool = _state_text() == state_at_the_exit
	await remove_main(main)
	_progress().reset()
	_delete_save()
	return report(changed and says_so and saved.get("scene", "") == PHASE_2_PATH and offered
			and back and same_state,
			("Exit: phase 2 %s, the word shows %s, phase 2 saved %s; the menu offers Continue %s, it "
			+ "goes back to phase 2 %s, with the state of the exit %s")
			% [changed, says_so, saved.get("scene", "") == PHASE_2_PATH, offered, back, same_state])


func _the_run_reads_back_beside_the_save() -> bool:
	_delete_save()
	var file: SaveFile = SaveFile.new()
	var missing: bool = file.read_run().is_empty()
	file.write(PHASE_1_PATH, _progress().to_save(), 1)
	var save_text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var record: RunRecord = RunRecord.new()
	record.record_death(&"lust", 2, &"pit")
	record.add_time(&"lust", 2, 7.5)
	var wrote: bool = file.write_run(record.to_save())
	var read: RunRecord = RunRecord.new()
	read.from_save(SaveFile.new().read_run())
	var same: bool = (read.deaths_in_phase(&"lust", 2) == 1
			and is_equal_approx(read.phase_seconds(&"lust", 2), 7.5))
	var beside: bool = file.get_run_path() != SAVE_PATH and FileAccess.file_exists(file.get_run_path())
	var save_kept: bool = FileAccess.get_file_as_string(SAVE_PATH) == save_text
	var no_copy: bool = not FileAccess.file_exists(file.get_run_path() + SaveFile.COPY_SUFFIX)
	_delete_save()
	return report(missing and wrote and same and beside and save_kept and no_copy,
			("Run file: none at first %s, wrote %s, reads back %s, beside the save %s, the save as it "
			+ "was %s, no copy left %s") % [missing, wrote, same, beside, save_kept, no_copy])


## Numbers from before a new game go; a death counts, reaches the disk, and leaves the save alone;
## after the menu, Continue puts back the numbers as written, though they were emptied meanwhile.
func _a_death_counts_and_continue_puts_the_numbers_back() -> bool:
	_delete_save()
	_run_stats().enter(&"elsewhere", 1)
	_run_stats().record_death(&"old")
	var main: Node = await _main_in_a_new_game()
	var emptied: bool = _run_stats().total_deaths() == 0
	var save_text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var restarted: bool = await _die_and_wait_for_the_new_copy(main)
	var counted: bool = _run_stats().total_deaths() == 1
	var on_disk: RunRecord = RunRecord.new()
	on_disk.from_save(SaveFile.new().read_run())
	var written: bool = on_disk.total_deaths() == 1
	var save_kept: bool = FileAccess.get_file_as_string(SAVE_PATH) == save_text
	main.call(&"_on_main_menu_requested")
	await process_frame
	_run_stats().reset()
	await tap(KEY_ENTER)
	await wait_frames(3)
	var back: bool = level_in(main) != null and _run_stats().total_deaths() == 1
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_save()
	return report(emptied and restarted and counted and written and save_kept and back,
			("Run numbers: emptied by a new game %s; a death restarts %s, counts %s, is on disk %s, "
			+ "leaves the save %s; Continue puts it back %s")
			% [emptied, restarted, counted, written, save_kept, back])


## With a save in slot 3 alone, Continue shows. Then slot 3 was played after slot 1, and slot 2 is
## damaged: Continue opens slot 3, and a death there writes its numbers beside slot 3 and leaves
## slot 1 as it was.
func _continue_takes_the_slot_played_last_and_saves_there() -> bool:
	_delete_save()
	_write_slot(3, PHASE_1_PATH, &"slot_3_event", 300.0)
	var damaged: FileAccess = FileAccess.open(SaveSlots.path_of(2), FileAccess.WRITE)
	damaged.store_string("this is not [ a config file = ")
	damaged.close()
	var main: Node = await new_main(_level_1_entry())
	var shows_alone: bool = (main_menu_node(main, ^"%ContinueButton") as Button).visible
	await remove_main(main)
	_write_slot(1, PHASE_2_PATH, &"slot_1_event", 200.0)
	var slot_1_text: String = FileAccess.get_file_as_string(SaveSlots.path_of(1))
	main = await new_main(_level_1_entry())
	var button: Button = main_menu_node(main, ^"%ContinueButton") as Button
	var offered: bool = button.visible and has_focus(button)
	await tap(KEY_ENTER)
	await wait_frames(3)
	var level: Node = level_in(main)
	var in_slot_3: bool = (level != null and level.scene_file_path == PHASE_1_PATH
			and _progress().has_event(&"slot_3_event") and not _progress().has_event(&"slot_1_event"))
	var restarted: bool = await _die_and_wait_for_the_new_copy(main)
	var on_disk: RunRecord = RunRecord.new()
	on_disk.from_save(SaveSlots.file_of(3).read_run())
	var counted_there: bool = on_disk.total_deaths() == 1
	var slot_1_kept: bool = (FileAccess.get_file_as_string(SaveSlots.path_of(1)) == slot_1_text
			and SaveSlots.file_of(1).read_run().is_empty())
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_save()
	return report(shows_alone and offered and in_slot_3 and restarted and counted_there
			and slot_1_kept,
			("Slots: Continue shows with slot 3 alone %s; offered %s, it opens slot 3, played last "
			+ "%s; a death restarts %s, its numbers beside slot 3 %s, slot 1 as it was %s")
			% [shows_alone, offered, in_slot_3, restarted, counted_there, slot_1_kept])


## After Continue opened slot 3, a new game starts in the slot picked, the empty slot 2, not in
## slot 3; slots 1 and 3 are left as they were.
func _a_new_game_after_continue_starts_in_the_slot_picked() -> bool:
	_delete_save()
	_write_slot(1, PHASE_2_PATH, &"slot_1_event", 200.0)
	_write_slot(3, PHASE_1_PATH, &"slot_3_event", 300.0)
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_ENTER)
	await wait_frames(3)
	var in_slot_3: bool = _progress().has_event(&"slot_3_event")
	main.call(&"_on_main_menu_requested")
	await process_frame
	var slot_1_text: String = FileAccess.get_file_as_string(SaveSlots.path_of(1))
	var slot_3_text: String = FileAccess.get_file_as_string(SaveSlots.path_of(3))
	# Past Load to New Game, then the slot selected, the first empty one.
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await wait_frames(3)
	var saved: Dictionary = SaveSlots.file_of(2).read()
	var in_slot_2: bool = (level_in(main) != null and saved.get("scene", "") == PHASE_1_PATH
			and not saved.get("state", {}).get("events", PackedStringArray()).has("slot_3_event"))
	var others_kept: bool = (FileAccess.get_file_as_string(SaveSlots.path_of(1)) == slot_1_text
			and FileAccess.get_file_as_string(SaveSlots.path_of(3)) == slot_3_text)
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_save()
	return report(in_slot_3 and in_slot_2 and others_kept,
			("Slots: after Continue in slot 3 %s, a new game starts in the empty slot 2 %s, slots 1 "
			+ "and 3 as they were %s") % [in_slot_3, in_slot_2, others_kept])
