# Checks the three save slots, on their own, without the main scene. Slot 1 is the save the game
# always had and slots 2 and 3 sit beside it, with their run's numbers beside each. A write keeps
# the phase and when it was made. A save from before the slots (version 1) still reads, as slot 1,
# with no phase, and one of level 1 without its light opens level 1 with it; the next write makes it
# a version 2 save. A slot was last played at the latest of its save and its run's numbers, or, for
# files from before the slots, when they last changed on disk. Each slot reads on its own: one that
# is damaged, or of a later version, shows as damaged and hides none of the others. Continue takes
# the slot played last, the lower one on a tie, and never a damaged one; a new game takes the first
# empty slot. A few warnings are printed on purpose, for the damaged files.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_save_slots.gd
extends "res://tests/support/player_test.gd"

const SAVE_PATH: String = "user://test_save_slots.cfg"
const PHASE_2_PATH: String = "res://scenes/levels/lust/LustLevel_Phase2.tscn"
const LEVEL_1_DARK_PATH: String = "res://scenes/levels/lust/level1.tscn"
const LEVEL_1_LIT_PATH: String = "res://scenes/levels/lust/level1_lit.tscn"


func _initialize() -> void:
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append(_the_slots_sit_beside_the_save())
	results.append(_a_write_keeps_the_phase_and_when())
	results.append(_a_save_from_before_the_slots_reads_as_slot_1())
	results.append(_last_played_is_the_latest_of_the_save_and_its_run())
	results.append(_each_slot_reads_on_its_own())
	results.append(_continue_takes_the_slot_played_last())
	results.append(_a_new_game_takes_the_first_empty_slot())
	_delete_slots()
	SaveFile.default_path = ""
	finish(results)


func _delete_slots() -> void:
	for slot: int in range(1, SaveSlots.COUNT + 1):
		var file: SaveFile = SaveSlots.file_of(slot)
		for path: String in [file.path, file.get_run_path()]:
			DirAccess.remove_absolute(path)
			DirAccess.remove_absolute(path + SaveFile.COPY_SUFFIX)


## A clock stopped at seconds, for SaveFile.clock.
func _at(seconds: float) -> Callable:
	return func() -> float: return seconds


## Slot's file, with its clock stopped at seconds.
func _file_at(slot: int, seconds: float) -> SaveFile:
	var file: SaveFile = SaveSlots.file_of(slot)
	file.clock = _at(seconds)
	return file


## Writes text as slot's save, as a damaged file would be.
func _write_text(slot: int, text: String) -> void:
	var file: FileAccess = FileAccess.open(SaveSlots.path_of(slot), FileAccess.WRITE)
	file.store_string(text)
	file.close()


## A state as GameState gave it before the slots, events and all.
func _old_state() -> Dictionary:
	return {
		"player_name": "Anyone",
		"has_crucifix": true,
		"arrival_point": "",
		"events": PackedStringArray(["velvet_met", "tutorial_done"]),
		"upgrades": PackedStringArray(),
		"moral": {"arrogant": 2, "humble": 0, "listening": {}, "refusals": {},
				"taken": PackedStringArray()},
	}


## Writes slot's save and run as the game wrote them before the slots: version 1, no phase, no time.
func _write_version_1(slot: int, scene: String, run: Dictionary) -> void:
	var file: SaveFile = SaveSlots.file_of(slot)
	var save: ConfigFile = ConfigFile.new()
	save.set_value(SaveFile.SECTION, "version", 1)
	save.set_value(SaveFile.SECTION, "scene", scene)
	save.set_value(SaveFile.SECTION, "state", _old_state())
	save.save(file.path)
	var numbers: ConfigFile = ConfigFile.new()
	numbers.set_value(SaveFile.RUN_SECTION, "version", 1)
	numbers.set_value(SaveFile.RUN_SECTION, "run", run)
	numbers.save(file.get_run_path())


## A run of deaths, in phase 1, and seconds, in phases 1 and 2 of level 1.
func _run(deaths: int, seconds_1: float, seconds_2: float) -> Dictionary:
	var record: RunRecord = RunRecord.new()
	for death: int in deaths:
		record.record_death(&"level1", 1, &"pit")
	record.add_time(&"level1", 1, seconds_1)
	record.add_time(&"level1", 2, seconds_2)
	return record.to_save()


func _the_slots_sit_beside_the_save() -> bool:
	var paths: PackedStringArray = [SaveSlots.path_of(1), SaveSlots.path_of(2), SaveSlots.path_of(3)]
	var beside: bool = paths == PackedStringArray(["user://test_save_slots.cfg",
			"user://test_save_slots_2.cfg", "user://test_save_slots_3.cfg"])
	var run_beside: bool = SaveSlots.file_of(2).get_run_path() == "user://test_save_slots_2_run.cfg"
	# Two errors are printed on purpose, for the slots that do not exist.
	var only_three: bool = (SaveSlots.path_of(0).is_empty() and SaveSlots.path_of(4).is_empty()
			and not SaveSlots.file_of(0).write(PHASE_2_PATH, {}, 1))
	beside = beside and only_three
	SaveFile.default_path = ""
	var none: bool = (SaveSlots.path_of(1).is_empty() and SaveSlots.path_of(2).is_empty()
			and not SaveSlots.file_of(3).write(PHASE_2_PATH, {}, 1))
	SaveFile.default_path = SAVE_PATH
	return report(beside and run_beside and none,
			("Paths: slot 1 is the save and 2 and 3 beside it, and no slot 0 or 4 %s, the run "
			+ "beside its slot %s; with no default path, none and nothing written %s")
			% [beside, run_beside, none])


func _a_write_keeps_the_phase_and_when() -> bool:
	_delete_slots()
	var wrote: bool = _file_at(1, 1000.0).write(PHASE_2_PATH, _old_state(), 3)
	var saved: Dictionary = SaveSlots.file_of(1).read()
	var kept: bool = (saved.get("scene", "") == PHASE_2_PATH and saved.get("phase", 0) == 3
			and is_equal_approx(saved.get("saved_at", 0.0), 1000.0)
			and saved.get("state", {}).get("events", []) == _old_state()["events"])
	var on_disk: ConfigFile = ConfigFile.new()
	on_disk.load(SaveSlots.path_of(1))
	var version: bool = on_disk.get_value(SaveFile.SECTION, "version", 0) == SaveFile.FILE_VERSION
	_delete_slots()
	return report(wrote and kept and version and SaveFile.FILE_VERSION == 2,
			"Write: on disk %s, scene, phase 3, time and state kept %s, version %d written %s"
			% [wrote, kept, SaveFile.FILE_VERSION, version])


## The save the game had before the slots, of level 1 without its light, opens level 1 with it, as
## slot 1; another scene stays as it was, and a version 2 save is never moved.
func _a_save_from_before_the_slots_reads_as_slot_1() -> bool:
	_delete_slots()
	_write_version_1(1, LEVEL_1_DARK_PATH, _run(2, 30.0, 0.0))
	var saved: Dictionary = SaveSlots.file_of(1).read()
	var moved: bool = saved.get("scene", "") == LEVEL_1_LIT_PATH
	var as_it_was: bool = (saved.get("state", {}) == _old_state() and saved.get("phase", -1) == 0
			and is_zero_approx(saved.get("saved_at", -1.0)))
	var record: RunRecord = RunRecord.new()
	record.from_save(SaveSlots.file_of(1).read_run())
	var numbers: bool = record.total_deaths() == 2
	SaveSlots.file_of(1).write(saved["scene"], saved["state"], 1)
	var on_disk: ConfigFile = ConfigFile.new()
	on_disk.load(SaveSlots.path_of(1))
	var upgraded: bool = on_disk.get_value(SaveFile.SECTION, "version", 0) == SaveFile.FILE_VERSION
	_write_version_1(1, PHASE_2_PATH, {})
	var other_kept: bool = SaveSlots.file_of(1).read().get("scene", "") == PHASE_2_PATH
	SaveSlots.file_of(1).write(LEVEL_1_DARK_PATH, {}, 1)
	var new_kept: bool = SaveSlots.file_of(1).read().get("scene", "") == LEVEL_1_DARK_PATH
	_delete_slots()
	return report(moved and as_it_was and numbers and upgraded and other_kept and new_kept,
			("Version 1: level 1 opens lit %s, state as it was with no phase or time %s, its "
			+ "numbers read %s, a write makes it version 2 %s; another scene kept %s; a version 2 "
			+ "save of the dark level kept %s")
			% [moved, as_it_was, numbers, upgraded, other_kept, new_kept])


func _last_played_is_the_latest_of_the_save_and_its_run() -> bool:
	_delete_slots()
	var nothing: bool = is_zero_approx(SaveSlots.file_of(1).last_played())
	_file_at(1, 100.0).write(PHASE_2_PATH, {}, 1)
	_file_at(1, 250.0).write_run({})
	var run_later: bool = is_equal_approx(SaveSlots.file_of(1).last_played(), 250.0)
	_file_at(1, 50.0).write_run({})
	var save_later: bool = is_equal_approx(SaveSlots.file_of(1).last_played(), 100.0)
	_write_version_1(2, PHASE_2_PATH, {})
	var file: SaveFile = SaveSlots.file_of(2)
	var changed: float = maxf(FileAccess.get_modified_time(file.path),
			FileAccess.get_modified_time(file.get_run_path()))
	var old_on_disk: bool = changed > 0.0 and is_equal_approx(file.last_played(), changed)
	# One file of each version, so each one's time is told apart from the other's: a save with its
	# time beside numbers from before the slots, and a save from before the slots beside numbers
	# with a time, in the future so it is the later one.
	_delete_slots()
	_file_at(1, 100.0).write(PHASE_2_PATH, {}, 1)
	var old_numbers: ConfigFile = ConfigFile.new()
	old_numbers.set_value(SaveFile.RUN_SECTION, "version", 1)
	old_numbers.set_value(SaveFile.RUN_SECTION, "run", {})
	old_numbers.save(SaveSlots.file_of(1).get_run_path())
	var numbers_changed: float = FileAccess.get_modified_time(SaveSlots.file_of(1).get_run_path())
	var old_numbers_time: bool = is_equal_approx(SaveSlots.file_of(1).last_played(), numbers_changed)
	_write_version_1(1, PHASE_2_PATH, {})
	_file_at(1, 4.0e9).write_run({})
	var new_numbers_time: bool = is_equal_approx(SaveSlots.file_of(1).last_played(), 4.0e9)
	_delete_slots()
	return report(nothing and run_later and save_later and old_on_disk and old_numbers_time
			and new_numbers_time,
			("Last played: 0 with no save %s; the run's time when later %s, the save's when later "
			+ "%s; files from before the slots, when they changed on disk %s; old numbers beside a "
			+ "new save, when they changed %s; new numbers beside an old save, their time %s")
			% [nothing, run_later, save_later, old_on_disk, old_numbers_time, new_numbers_time])


func _each_slot_reads_on_its_own() -> bool:
	_delete_slots()
	_file_at(1, 100.0).write(PHASE_2_PATH, {}, 2)
	_file_at(1, 100.0).write_run(_run(2, 7.5, 4.0))
	_write_text(2, "this is not [ a config file = ")
	var all: Array[SaveSlots.Summary] = SaveSlots.summaries()
	var first: SaveSlots.Summary = all[0]
	var ready: bool = (first.slot == 1 and first.state == SaveSlots.State.READY
			and first.scene == PHASE_2_PATH and first.phase == 2 and first.deaths == 2
			and is_equal_approx(first.seconds, 11.5) and is_equal_approx(first.last_played, 100.0))
	var damaged: bool = all[1].slot == 2 and all[1].state == SaveSlots.State.DAMAGED
	var empty: bool = all.size() == 3 and all[2].slot == 3 and all[2].state == SaveSlots.State.EMPTY
	_write_text(3, '[save]\nversion=%d\nscene="%s"\nstate={}\n'
			% [SaveFile.FILE_VERSION + 1, PHASE_2_PATH])
	var later_version: bool = SaveSlots.summary_of(3).state == SaveSlots.State.DAMAGED
	var still_ready: bool = SaveSlots.summary_of(1).state == SaveSlots.State.READY
	_delete_slots()
	return report(ready and damaged and empty and later_version and still_ready,
			("Slots: 1 ready with its phase, deaths, time and when %s, 2 damaged %s, 3 empty %s; "
			+ "one of a later version damaged %s, and slot 1 still ready %s")
			% [ready, damaged, empty, later_version, still_ready])


func _continue_takes_the_slot_played_last() -> bool:
	_delete_slots()
	var none: bool = SaveSlots.last_played() == 0
	_write_text(2, "this is not [ a config file = ")
	var only_damaged: bool = SaveSlots.last_played() == 0
	_file_at(1, 300.0).write(PHASE_2_PATH, {}, 1)
	_file_at(3, 200.0).write(PHASE_2_PATH, {}, 1)
	var saved_last: bool = SaveSlots.last_played() == 1
	_file_at(3, 500.0).write_run({})
	var played_last: bool = SaveSlots.last_played() == 3
	_file_at(1, 500.0).write_run({})
	var tie: bool = SaveSlots.last_played() == 1
	_delete_slots()
	return report(none and only_damaged and saved_last and played_last and tie,
			("Continue: none with no save %s, nor with a damaged one %s; the slot saved last %s, the "
			+ "one played last though saved earlier %s, the lower on a tie %s")
			% [none, only_damaged, saved_last, played_last, tie])


func _a_new_game_takes_the_first_empty_slot() -> bool:
	_delete_slots()
	var first: bool = SaveSlots.first_empty() == 1 and not SaveSlots.has_any()
	_file_at(1, 100.0).write(PHASE_2_PATH, {}, 1)
	var second: bool = SaveSlots.first_empty() == 2 and SaveSlots.has_any()
	_write_text(2, "this is not [ a config file = ")
	var past_damaged: bool = SaveSlots.first_empty() == 3
	_file_at(3, 100.0).write(PHASE_2_PATH, {}, 1)
	var full: bool = SaveSlots.first_empty() == 0
	_delete_slots()
	_write_text(3, "this is not [ a config file = ")
	var only_damaged: bool = SaveSlots.has_any() and SaveSlots.first_empty() == 1
	_delete_slots()
	return report(first and second and past_damaged and full and only_damaged,
			("New game: slot 1 with nothing saved %s, then 2 %s, past a damaged one %s, none when "
			+ "full %s; a damaged slot alone counts as a save %s")
			% [first, second, past_damaged, full, only_damaged])
