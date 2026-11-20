# Checks the slots in the main menu. Load shows beside Continue, only while a slot holds a save
# that can be continued, and lists the three slots, each with its level and phase, its play time,
# deaths and date, or Empty, or Can't be read. Load selects the slot played last; a slot it can't
# open can't be selected, and the one picked opens and is the one the game then writes to. With
# no save on disk, New Game starts at once in slot 1; with one, it lists the slots with the first
# empty one selected, and the new game starts in the slot picked. A slot that holds a file asks
# first, with No selected, and says so when the file can't be read; No goes back to that slot and
# Yes starts there. Esc goes back to the button that opened the slots, a level's on the level list
# too; Back sounds as going back, and the gamepad's B closes the slots. A game opened by Load
# pauses with Esc. A slot that goes bad while the menu shows can't be picked any more, and with no
# slot left to load, the main panel comes back. The slot's text reads "1 death", not "1 deaths",
# and the date is the local one, ahead of or behind UTC. The crosses frame a slot's widest line.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_save_slots_menu.gd
extends "res://tests/support/menu_test.gd"

const SAVE_PATH: String = "user://test_save_slots_menu.cfg"
const PHASE_1_PATH: String = "res://scenes/levels/lust/LustLevel_Phase1_Cave.tscn"
const PHASE_2_PATH: String = "res://scenes/levels/lust/LustLevel_Phase2.tscn"
const A_EVENT: StringName = &"slot_a_event"
const B_EVENT: StringName = &"slot_b_event"
const DAMAGED_TEXT: String = "this is not [ a config file = "
const MenuFeedbackNode := preload("res://scenes/screens/menu_feedback.gd")


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append(await _load_shows_only_with_a_save_to_continue())
	results.append(await _load_lists_the_slots_and_selects_the_one_played_last())
	results.append(await _load_opens_the_slot_picked())
	results.append(await _a_new_game_with_no_save_starts_in_slot_1())
	results.append(await _a_new_game_with_a_save_starts_in_the_slot_picked())
	results.append(await _a_slot_that_holds_a_file_asks_first())
	results.append(await _esc_goes_back_to_the_button_that_opened_the_slots())
	results.append(_the_slot_text_says_what_the_slot_holds())
	results.append(await _the_crosses_frame_a_slot_s_widest_line())
	results.append(await _back_thuds_and_the_b_button_closes_the_slots())
	results.append(await _slots_opened_from_the_level_list_go_back_to_that_level())
	results.append(await _a_slot_damaged_after_the_menu_opened_can_t_be_picked())
	_delete_slots()
	_progress().reset()
	_run_stats().reset()
	SaveFile.default_path = ""
	finish(results)


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


func _run_stats() -> GameRunStats:
	return root.get_node(^"RunStats") as GameRunStats


func _delete_slots() -> void:
	for slot: int in range(1, SaveSlots.COUNT + 1):
		var file: SaveFile = SaveSlots.file_of(slot)
		for path: String in [file.path, file.get_run_path()]:
			DirAccess.remove_absolute(path)
			DirAccess.remove_absolute(path + SaveFile.COPY_SUFFIX)


## Writes slot's save of the phase at scene_path, in phase, with only event marked, and its run's
## numbers, all as if made at seconds.
func _write_slot(slot: int, scene_path: String, event: StringName, seconds: float, phase: int = 1,
		run: Dictionary = {}) -> void:
	_progress().reset()
	_progress().mark_event(event)
	var file: SaveFile = SaveSlots.file_of(slot)
	file.clock = func() -> float: return seconds
	file.write(scene_path, _progress().to_save(), phase)
	file.write_run(run)
	_progress().reset()


func _write_damaged(slot: int) -> void:
	var file: FileAccess = FileAccess.open(SaveSlots.path_of(slot), FileAccess.WRITE)
	file.store_string(DAMAGED_TEXT)
	file.close()


## Level 1, the one level that starts the game, as the phase 1 scene.
func _level_1_entry() -> Array[LevelEntry]:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1"
	entry.scene = load(PHASE_1_PATH) as PackedScene
	entry.starts_game = true
	var entries: Array[LevelEntry] = [entry]
	return entries


func _slot_button(main: Node, slot: int) -> Button:
	return main_menu_node(main, ^"%SlotButtons").get_child(slot - 1) as Button


func _slots_shown(main: Node) -> bool:
	return ((main_menu_node(main, ^"%SlotPanel") as Control).is_visible_in_tree()
			and not (main_menu_node(main, ^"%MainPanel") as Control).is_visible_in_tree())


func _load_shows_only_with_a_save_to_continue() -> bool:
	_delete_slots()
	var main: Node = await new_main(_level_1_entry())
	var load_button: Button = main_menu_node(main, ^"%LoadButton") as Button
	var hidden_without: bool = not load_button.visible
	await remove_main(main)
	_write_damaged(2)
	main = await new_main(_level_1_entry())
	load_button = main_menu_node(main, ^"%LoadButton") as Button
	var hidden_damaged: bool = not load_button.visible
	await remove_main(main)
	_write_slot(3, PHASE_2_PATH, A_EVENT, 100.0)
	main = await new_main(_level_1_entry())
	load_button = main_menu_node(main, ^"%LoadButton") as Button
	var continue_button: Button = main_menu_node(main, ^"%ContinueButton") as Button
	var shows_with: bool = load_button.visible and continue_button.visible
	await tap(KEY_DOWN)
	var next_to_continue: bool = has_focus(load_button)
	await remove_main(main)
	_delete_slots()
	return report(hidden_without and hidden_damaged and shows_with and next_to_continue,
			("Load: hidden with no save %s, and with a damaged one only %s; shows with a save, as "
			+ "Continue %s, right below it %s")
			% [hidden_without, hidden_damaged, shows_with, next_to_continue])


func _load_lists_the_slots_and_selects_the_one_played_last() -> bool:
	_delete_slots()
	var record: RunRecord = RunRecord.new()
	record.record_death(&"level1", 2, &"pit")
	record.record_death(&"level1", 2, &"pit")
	record.add_time(&"level1", 2, 90.0)
	_write_slot(1, PHASE_1_PATH, A_EVENT, 200.0, 2, record.to_save())
	_write_damaged(2)
	_write_slot(3, PHASE_2_PATH, B_EVENT, 300.0)
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	var listed: bool = _slots_shown(main)
	var last_selected: bool = has_focus(_slot_button(main, 3))
	var first: String = _slot_button(main, 1).text
	var slot_1: bool = (first.contains("Slot 1") and first.contains("Level 1")
			and first.contains("Phase 2") and first.contains("2 deaths") and first.contains("1m"))
	var damaged: Button = _slot_button(main, 2)
	var slot_2: bool = damaged.text.contains("Can't be read") and damaged.disabled
	var slot_3: bool = _slot_button(main, 3).text.contains("Saved game")
	await tap(KEY_UP)
	var skips_damaged: bool = has_focus(_slot_button(main, 1))
	await remove_main(main)
	_delete_slots()
	return report(listed and last_selected and slot_1 and slot_2 and slot_3 and skips_damaged,
			("Load: lists the slots %s with the one played last selected %s; slot 1 with level, "
			+ "phase, deaths and time %s, slot 2 can't be read and can't be picked %s, slot 3 with "
			+ "no level title %s; Up passes over the damaged one %s")
			% [listed, last_selected, slot_1, slot_2, slot_3, skips_damaged])


## Slot 1 was played last; Down passes the empty slot 2 to slot 3, which opens, and the game then
## writes to it: leaving for the menu writes slot 3's numbers, not slot 1's.
func _load_opens_the_slot_picked() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 300.0)
	_write_slot(3, PHASE_1_PATH, B_EVENT, 200.0)
	var slot_1_run: String = FileAccess.get_file_as_string(SaveSlots.file_of(1).get_run_path())
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await tap(KEY_DOWN)
	var passes_empty: bool = has_focus(_slot_button(main, 3))
	await tap(KEY_ENTER)
	await wait_frames(3)
	var level: Node = level_in(main)
	var opened: bool = (level != null and level.scene_file_path == PHASE_1_PATH
			and _progress().has_event(B_EVENT) and not _progress().has_event(A_EVENT))
	await tap(KEY_ESCAPE)
	opened = opened and paused
	main.call(&"_on_main_menu_requested")
	await process_frame
	var played_at_3: bool = SaveSlots.file_of(3).last_played() > 300.0
	var slot_1_left: bool = (FileAccess.get_file_as_string(SaveSlots.file_of(1).get_run_path())
			== slot_1_run)
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_slots()
	return report(passes_empty and opened and played_at_3 and slot_1_left,
			("Load: Down passes the empty slot %s, slot 3 opens and Esc pauses it %s, the game "
			+ "writes to it %s and leaves slot 1 %s") % [passes_empty, opened, played_at_3, slot_1_left])


func _a_new_game_with_no_save_starts_in_slot_1() -> bool:
	_delete_slots()
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_ENTER)
	await wait_frames(3)
	var started: bool = level_in(main) != null
	var no_list: bool = not (main_menu_node(main, ^"%SlotPanel") as Control).visible
	var in_slot_1: bool = SaveSlots.file_of(1).read().get("scene", "") == PHASE_1_PATH
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_slots()
	return report(started and no_list and in_slot_1,
			"New game with no save: starts at once %s, no slots shown %s, in slot 1 %s"
			% [started, no_list, in_slot_1])


func _a_new_game_with_a_save_starts_in_the_slot_picked() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	var slot_1_text: String = FileAccess.get_file_as_string(SaveSlots.path_of(1))
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	var listed: bool = _slots_shown(main) and level_in(main) == null
	var empty_selected: bool = has_focus(_slot_button(main, 2))
	await tap(KEY_ENTER)
	await wait_frames(3)
	var in_slot_2: bool = (level_in(main) != null
			and SaveSlots.file_of(2).read().get("scene", "") == PHASE_1_PATH)
	var slot_1_left: bool = FileAccess.get_file_as_string(SaveSlots.path_of(1)) == slot_1_text
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_slots()
	return report(listed and empty_selected and in_slot_2 and slot_1_left,
			("New game with a save: lists the slots %s with the first empty one selected %s, starts "
			+ "in slot 2 %s, slot 1 left %s") % [listed, empty_selected, in_slot_2, slot_1_left])


## Every slot holds a file, so slot 1 is selected. Slot 2, damaged, asks and says it can't be read;
## No goes back to it. Slot 1 asks, and Yes starts the new game there, leaving slot 3.
func _a_slot_that_holds_a_file_asks_first() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	_write_damaged(2)
	_write_slot(3, PHASE_2_PATH, B_EVENT, 200.0)
	var slot_3_text: String = FileAccess.get_file_as_string(SaveSlots.path_of(3))
	var main: Node = await new_main(_level_1_entry())
	var dialog: ConfirmationDialog = main_menu_node(main, ^"%ReplaceSaveDialog") as ConfirmationDialog
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	var first_selected: bool = has_focus(_slot_button(main, 1))
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	var asks_damaged: bool = (dialog.visible and level_in(main) == null
			and dialog.gui_get_focus_owner() == dialog.get_cancel_button()
			and dialog.dialog_text.contains("can't be read"))
	await tap(KEY_ENTER)
	await process_frame
	var no_goes_back: bool = (not dialog.visible and level_in(main) == null
			and root.gui_get_focus_owner() == _slot_button(main, 2)
			and FileAccess.get_file_as_string(SaveSlots.path_of(2)) == DAMAGED_TEXT)
	await tap(KEY_UP)
	await tap(KEY_ENTER)
	var asks_saved: bool = dialog.visible and not dialog.dialog_text.contains("can't be read")
	dialog.get_ok_button().pressed.emit()
	await process_frame
	await process_frame
	var saved: Dictionary = SaveSlots.file_of(1).read()
	var yes_starts: bool = (level_in(main) != null and saved.get("scene", "") == PHASE_1_PATH
			and not (saved.get("state", {}).get("events", PackedStringArray()) as PackedStringArray)
					.has(String(A_EVENT)))
	var slot_3_left: bool = FileAccess.get_file_as_string(SaveSlots.path_of(3)) == slot_3_text
	await remove_main(main)
	_progress().reset()
	_run_stats().reset()
	_delete_slots()
	return report(first_selected and asks_damaged and no_goes_back and asks_saved and yes_starts
			and slot_3_left,
			("Used slots: none empty, slot 1 selected %s; the damaged one asks and says so %s, No "
			+ "goes back to it %s; slot 1 asks %s and Yes starts there %s; slot 3 left %s")
			% [first_selected, asks_damaged, no_goes_back, asks_saved, yes_starts, slot_3_left])


func _esc_goes_back_to_the_button_that_opened_the_slots() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	var back_to_load: bool = (not _slots_shown(main)
			and has_focus(main_menu_node(main, ^"%LoadButton") as Control))
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	var listed: bool = _slots_shown(main)
	await tap(KEY_ESCAPE)
	var back_to_new_game: bool = (not _slots_shown(main)
			and has_focus(main_menu_node(main, ^"%PlayButton") as Control))
	await remove_main(main)
	_delete_slots()
	return report(back_to_load and listed and back_to_new_game,
			"Esc: from Load's slots back to Load %s; from New Game's %s back to New Game %s"
			% [back_to_load, listed, back_to_new_game])


func _the_slot_text_says_what_the_slot_holds() -> bool:
	var ready: SaveSlots.Summary = SaveSlots.Summary.new()
	ready.slot = 1
	ready.state = SaveSlots.State.READY
	ready.phase = 2
	ready.seconds = 3725.0
	ready.deaths = 1
	var before: Dictionary = Time.get_datetime_dict_from_system()
	ready.last_played = Time.get_unix_time_from_system()
	var text: String = MainMenu.slot_text(ready, "Level 1")
	var after: Dictionary = Time.get_datetime_dict_from_system()
	var lines: PackedStringArray = text.split("\n")
	var first_line: bool = lines[0] == "Slot 1 · Level 1 · Phase 2"
	var numbers: bool = lines.size() == 2 and lines[1].begins_with("1h 02m · 1 death · ")
	var local: bool = lines[1].ends_with(_local_date(before)) or lines[1].ends_with(_local_date(after))
	var old: SaveSlots.Summary = SaveSlots.Summary.new()
	old.slot = 1
	old.state = SaveSlots.State.READY
	var unnamed: bool = MainMenu.slot_text(old, "").begins_with("Slot 1 · Saved game\n0m · 0 deaths")
	var empty: SaveSlots.Summary = SaveSlots.Summary.new()
	empty.slot = 2
	var damaged: SaveSlots.Summary = SaveSlots.Summary.new()
	damaged.slot = 3
	damaged.state = SaveSlots.State.DAMAGED
	var others: bool = (MainMenu.slot_text(empty, "") == "Slot 2\nEmpty"
			and MainMenu.slot_text(damaged, "") == "Slot 3\nCan't be read")
	# This computer may be on UTC, as Portugal is in winter; the offset is then checked on its own,
	# both its use and how it is found from a local time and the same moment in UTC.
	var noon_utc: float = Time.get_unix_time_from_datetime_dict(
			{"year": 2026, "month": 7, "day": 1, "hour": 12, "minute": 0, "second": 0})
	var offset: bool = (MainMenu.date_text(0.0, 3600) == "1970-01-01 01:00"
			and MainMenu.date_text(0.0, -5400) == "1969-12-31 22:30"
			and MainMenu.utc_offset({"year": 2026, "month": 7, "day": 1, "hour": 13, "minute": 0,
					"second": 0}, noon_utc + 0.4) == 3600
			and MainMenu.utc_offset({"year": 2026, "month": 7, "day": 1, "hour": 10, "minute": 30,
					"second": 0}, noon_utc) == -5400)
	return report(first_line and numbers and local and unnamed and others and offset,
			("Slot text: slot, level and phase %s; time, one death %s; the local date %s; no phase "
			+ "and no title %s; empty and damaged %s; an hour ahead and an hour and a half behind "
			+ "UTC %s; read %s")
			% [first_line, numbers, local, unnamed, others, offset, text.replace("\n", " / ")])


## The crosses frame a slot's widest line, not its two lines laid end to end, so they stay by the
## button.
func _the_crosses_frame_a_slot_s_widest_line() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await wait_frames(2)
	var slot: Button = _slot_button(main, 1)
	var crosses: MenuCrosses = main.get_node(^"%MainMenu").get_node(^"Crosses") as MenuCrosses
	var right_edge: float = -INF
	for cross: Node in crosses.get_children():
		right_edge = maxf(right_edge, (cross as Control).global_position.x)
	var box: Rect2 = slot.get_global_rect()
	var gap: float = crosses.gap
	var by_the_button: bool = has_focus(slot) and right_edge <= box.end.x + gap + 1.0
	await remove_main(main)
	_delete_slots()
	return report(by_the_button,
			"Crosses: the right one at %.0f px, the slot's right edge at %.0f px, gap %.0f px: by it %s"
			% [right_edge, box.end.x, gap, by_the_button])


func _local_date(when: Dictionary) -> String:
	return "%04d-%02d-%02d %02d:%02d" % [when.year, when.month, when.day, when.hour, when.minute]


## Back on the slots, as with the mouse, sounds as going back, not as a choice, and goes back to
## Load; the gamepad's B closes the slots too.
func _back_thuds_and_the_b_button_closes_the_slots() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	var main: Node = await new_main(_level_1_entry())
	var heard: Array[StringName] = []
	var feedback: MenuFeedbackNode = main_menu_node(main, ^"MenuFeedback") as MenuFeedbackNode
	feedback.played.connect(func(sound: StringName) -> void: heard.append(sound))
	var load_button: Control = main_menu_node(main, ^"%LoadButton") as Control
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	heard.clear()
	(main_menu_node(main, ^"%SlotPanel").get_node(^"BackButton") as Button).pressed.emit()
	await process_frame
	var thuds: bool = heard.has(&"back") and not heard.has(&"confirm")
	var back_to_load: bool = not _slots_shown(main) and has_focus(load_button)
	await tap(KEY_ENTER)
	await tap_joypad(JOY_BUTTON_B)
	var b_closes: bool = not _slots_shown(main) and has_focus(load_button)
	await remove_main(main)
	_delete_slots()
	return report(thuds and back_to_load and b_closes,
			"Back: sounds as going back %s (heard %s), back to Load %s; B closes the slots %s"
			% [thuds, heard, back_to_load, b_closes])


## With two levels, New Game opens the level list; picking the level that starts the game opens the
## slots, and Esc goes back to that level's button on the list.
func _slots_opened_from_the_level_list_go_back_to_that_level() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	var room: LevelEntry = LevelEntry.new()
	room.title = "Test room"
	room.scene = load("res://scenes/levels/test_room/test_room.tscn") as PackedScene
	var entries: Array[LevelEntry] = [room]
	entries.append_array(_level_1_entry())
	var main: Node = await new_main(entries)
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	await tap(KEY_DOWN)
	var level_1: Control = main_menu_node(main, ^"%LevelButtons").get_child(1) as Control
	var on_level_1: bool = has_focus(level_1)
	await tap(KEY_ENTER)
	var listed: bool = _slots_shown(main)
	await tap(KEY_ESCAPE)
	var back_to_level: bool = (not _slots_shown(main)
			and (main_menu_node(main, ^"%LevelPanel") as Control).is_visible_in_tree()
			and has_focus(level_1))
	await remove_main(main)
	_delete_slots()
	return report(on_level_1 and listed and back_to_level,
			"Level list: on Level 1 %s, its slots shown %s, Esc back to its button %s"
			% [on_level_1, listed, back_to_level])


## Slots 1 and 3 hold games, slot 3 played last. With Load open on slot 3, slot 3 goes bad on disk:
## picking it opens nothing, and it then reads Can't be read and can't be picked, with slot 1
## selected. When slot 1 goes bad too, the main panel comes back, with New Game selected.
func _a_slot_damaged_after_the_menu_opened_can_t_be_picked() -> bool:
	_delete_slots()
	_write_slot(1, PHASE_2_PATH, A_EVENT, 100.0)
	_write_slot(3, PHASE_2_PATH, B_EVENT, 200.0)
	var main: Node = await new_main(_level_1_entry())
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	_write_damaged(3)
	await tap(KEY_ENTER)
	var slot_3: Button = _slot_button(main, 3)
	var stays: bool = (level_in(main) == null and _slots_shown(main) and slot_3.disabled
			and slot_3.text.contains("Can't be read") and has_focus(_slot_button(main, 1)))
	_write_damaged(1)
	await tap(KEY_ENTER)
	var back_to_main: bool = (level_in(main) == null and not _slots_shown(main)
			and has_focus(main_menu_node(main, ^"%PlayButton") as Control)
			and not (main_menu_node(main, ^"%LoadButton") as Control).visible)
	await remove_main(main)
	_delete_slots()
	return report(stays and back_to_main,
			("Gone bad with the menu open: slot 3 opens nothing and can't be picked, slot 1 "
			+ "selected %s; with none left, the main panel on New Game %s") % [stays, back_to_main])
