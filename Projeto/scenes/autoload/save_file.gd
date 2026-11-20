class_name SaveFile
extends RefCounted

## One save, a ConfigFile on disk like the options': the scene of the phase to come back to, the
## state GameState gives, the phase he was in and when it was written. It only reads and writes;
## Main decides when, and SaveSlots gives each slot its file. It writes a copy first and only then
## puts it in the save's place, so a game closed half way through leaves the last save whole. A save
## that is missing, damaged, of a later version or of a scene that no longer exists reads as no
## save. A save from before the slots (version 1) still reads, with no phase and no time, its scene
## through Moved Scenes; the next write makes it version 2.
## The run's numbers (RunStats) go in a file of their own beside it, with Run Suffix in its name:
## they are written on each death too, and a death must leave the save itself as it was.

## Written to the file: a save of a later version is not read. Up it when the layout changes.
const FILE_VERSION: int = 2
## The oldest version still read.
const OLDEST_VERSION: int = 1
## The version whose saves go through Moved Scenes: the one before the slots.
const MOVED_SCENES_VERSION: int = 1
## Scenes a save of Moved Scenes Version may name, and the scene the game opens in their place:
## level 1 without its light became level 1 with it.
const MOVED_SCENES: Dictionary[String, String] = {
	"res://scenes/levels/lust/level1.tscn": "res://scenes/levels/lust/level1_lit.tscn",
}
const DEFAULT_PATH: String = "user://save.cfg"
const COPY_SUFFIX: String = ".tmp"
const SECTION: String = "save"
## Added to the save's file name, before its extension, for the file of the run's numbers.
const RUN_SUFFIX: String = "_run"
const RUN_SECTION: String = "run"

## The file every new SaveFile uses, which is slot 1's; empty keeps nothing.
## tests/support/base_test.gd empties it, and a test points it at a file of its own, so the tests
## never touch the player's saves.
static var default_path: String = DEFAULT_PATH

var path: String = default_path
## Gives the time written with the save and with the run's numbers, in Unix seconds. A test stops it.
var clock: Callable = Time.get_unix_time_from_system


func exists() -> bool:
	return not read().is_empty()


## Saves the phase scene_path, as state and phase say; true if the save is on disk. Whoever saves
## says so to the player only then.
func write(scene_path: String, state: Dictionary, phase: int) -> bool:
	if path.is_empty():
		return false
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION, "version", FILE_VERSION)
	file.set_value(SECTION, "scene", scene_path)
	file.set_value(SECTION, "state", state)
	file.set_value(SECTION, "phase", phase)
	file.set_value(SECTION, "saved_at", _now())
	return _write_through_a_copy(file, path)


## The file of the run's numbers, beside the save; empty when the save keeps nothing.
func get_run_path() -> String:
	if path.is_empty():
		return ""
	return "%s%s.%s" % [path.get_basename(), RUN_SUFFIX, path.get_extension()]


## Saves the run's numbers, as RunStats gives them; true if they are on disk.
func write_run(run: Dictionary) -> bool:
	var run_path: String = get_run_path()
	if run_path.is_empty():
		return false
	var file: ConfigFile = ConfigFile.new()
	file.set_value(RUN_SECTION, "version", FILE_VERSION)
	file.set_value(RUN_SECTION, "run", run)
	file.set_value(RUN_SECTION, "played_at", _now())
	return _write_through_a_copy(file, run_path)


## The run's numbers as write_run() got them; empty when missing, damaged or of a later version.
func read_run() -> Dictionary:
	var file: ConfigFile = _load(get_run_path(), RUN_SECTION)
	if file == null:
		return {}
	var run: Variant = file.get_value(RUN_SECTION, "run", {})
	return run if run is Dictionary else {}


## When this save was last played, in Unix seconds: the later of its write and its run's numbers'.
## A file with no time in it, from before the slots, counts from when it last changed on disk. 0
## with no save that can be used.
func last_played() -> float:
	var saved: Dictionary = read()
	if saved.is_empty():
		return 0.0
	var latest: float = _time_or_change(saved["saved_at"], path)
	var run: ConfigFile = _load(get_run_path(), RUN_SECTION)
	if run != null:
		latest = maxf(latest,
				_time_or_change(run.get_value(RUN_SECTION, "played_at", 0.0), get_run_path()))
	return latest


func _now() -> float:
	return float(clock.call())


## time, if the file at file_path has one; when it last changed on disk if not.
func _time_or_change(time: Variant, file_path: String) -> float:
	if (time is float or time is int) and time > 0:
		return float(time)
	return float(FileAccess.get_modified_time(file_path))


## The file at file_path, loaded, if it is of a version this game reads; null if not, with a warning
## unless it is missing.
func _load(file_path: String, section: String) -> ConfigFile:
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return null
	var file: ConfigFile = ConfigFile.new()
	var error: Error = file.load(file_path)
	if error != OK:
		push_warning("SaveFile: could not read %s (error %d)." % [file_path, error])
		return null
	var version: Variant = file.get_value(section, "version", 0)
	if version is not int or version < OLDEST_VERSION or version > FILE_VERSION:
		push_warning("SaveFile: %s can't be used by this version of the game." % file_path)
		return null
	return file


func _write_through_a_copy(file: ConfigFile, target: String) -> bool:
	var copy: String = target + COPY_SUFFIX
	var error: Error = file.save(copy)
	if error == OK:
		error = DirAccess.rename_absolute(copy, target)
	if error != OK:
		push_error("SaveFile: could not save %s (error %d)." % [target, error])
		return false
	return true


## The save as {"scene": path, "state": Dictionary, "phase": int, "saved_at": Unix seconds}; empty
## with no save that can be used. A save from before the slots has phase 0 and saved_at 0.
func read() -> Dictionary:
	var file: ConfigFile = _load(path, SECTION)
	if file == null:
		return {}
	var scene: Variant = file.get_value(SECTION, "scene", "")
	if file.get_value(SECTION, "version") == MOVED_SCENES_VERSION and scene is String:
		scene = MOVED_SCENES.get(scene, scene)
	var state: Variant = file.get_value(SECTION, "state", {})
	var phase: Variant = file.get_value(SECTION, "phase", 0)
	var saved_at: Variant = file.get_value(SECTION, "saved_at", 0.0)
	if (scene is not String or state is not Dictionary or phase is not int
			or not (saved_at is float or saved_at is int) or not ResourceLoader.exists(scene)):
		push_warning("SaveFile: %s can't be used by this version of the game." % path)
		return {}
	return {"scene": scene, "state": state, "phase": phase, "saved_at": float(saved_at)}
