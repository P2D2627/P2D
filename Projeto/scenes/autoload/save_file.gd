class_name SaveFile
extends RefCounted

## The game's one save, a ConfigFile on disk like the options': the scene of the phase to come back
## to and the state GameState gives. It only reads and writes; Main decides when. It writes a copy
## first and only then puts it in the save's place, so a game closed half way through leaves the
## last save whole. A save that is missing, damaged, of another version or of a scene that no longer
## exists reads as no save.
## The run's numbers (RunStats) go in a file of their own beside it, with Run Suffix in its name:
## they are written on each death too, and a death must leave the save itself as it was.

## Written to the file: a save of another version is not read. Up it when the layout changes.
const FILE_VERSION: int = 1
const DEFAULT_PATH: String = "user://save.cfg"
const COPY_SUFFIX: String = ".tmp"
const SECTION: String = "save"
## Added to the save's file name, before its extension, for the file of the run's numbers.
const RUN_SUFFIX: String = "_run"
const RUN_SECTION: String = "run"

## The file every new SaveFile uses; empty keeps nothing. tests/support/base_test.gd empties it, and
## a test points it at a file of its own, so the tests never touch the player's save.
static var default_path: String = DEFAULT_PATH

var path: String = default_path


func exists() -> bool:
	return not read().is_empty()


## Saves the phase scene_path and state; true if the save is on disk. Whoever saves says so to the
## player only then.
func write(scene_path: String, state: Dictionary) -> bool:
	if path.is_empty():
		return false
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION, "version", FILE_VERSION)
	file.set_value(SECTION, "scene", scene_path)
	file.set_value(SECTION, "state", state)
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
	return _write_through_a_copy(file, run_path)


## The run's numbers as write_run() got them; empty when missing, damaged or of another version.
func read_run() -> Dictionary:
	var run_path: String = get_run_path()
	if run_path.is_empty() or not FileAccess.file_exists(run_path):
		return {}
	var file: ConfigFile = ConfigFile.new()
	if file.load(run_path) != OK or file.get_value(RUN_SECTION, "version", 0) != FILE_VERSION:
		push_warning("SaveFile: %s can't be used by this version of the game." % run_path)
		return {}
	var run: Variant = file.get_value(RUN_SECTION, "run", {})
	return run if run is Dictionary else {}


func _write_through_a_copy(file: ConfigFile, target: String) -> bool:
	var copy: String = target + COPY_SUFFIX
	var error: Error = file.save(copy)
	if error == OK:
		error = DirAccess.rename_absolute(copy, target)
	if error != OK:
		push_error("SaveFile: could not save %s (error %d)." % [target, error])
		return false
	return true


## The save as {"scene": path, "state": Dictionary}; empty with no save that can be used.
func read() -> Dictionary:
	var file: ConfigFile = ConfigFile.new()
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var error: Error = file.load(path)
	if error != OK:
		push_warning("SaveFile: could not read %s (error %d)." % [path, error])
		return {}
	var scene: Variant = file.get_value(SECTION, "scene", "")
	var state: Variant = file.get_value(SECTION, "state", {})
	if (file.get_value(SECTION, "version", 0) != FILE_VERSION or scene is not String
			or state is not Dictionary or not ResourceLoader.exists(scene)):
		push_warning("SaveFile: %s can't be used by this version of the game." % path)
		return {}
	return {"scene": scene, "state": state}
