class_name SaveFile
extends RefCounted

## The game's one save, a ConfigFile on disk like the options': the scene of the phase to come back
## to and the state GameState gives. It only reads and writes; Main decides when. It writes a copy
## first and only then puts it in the save's place, so a game closed half way through leaves the
## last save whole. A save that is missing, damaged, of another version or of a scene that no longer
## exists reads as no save.

## Written to the file: a save of another version is not read. Up it when the layout changes.
const FILE_VERSION: int = 1
const DEFAULT_PATH: String = "user://save.cfg"
const COPY_SUFFIX: String = ".tmp"
const SECTION: String = "save"

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
	var copy: String = path + COPY_SUFFIX
	var error: Error = file.save(copy)
	if error == OK:
		error = DirAccess.rename_absolute(copy, path)
	if error != OK:
		push_error("SaveFile: could not save %s (error %d)." % [path, error])
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
