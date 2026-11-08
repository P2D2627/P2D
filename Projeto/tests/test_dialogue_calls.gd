# Checks that every call the .dialogue files make to an autoload, such as GameState.mark_event(...)
# or Moral.record_tone(...), names a function that autoload's script has. The Dialogue Manager only
# finds out at run time, in the middle of a scene, so a mistyped or renamed function would otherwise
# stay hidden until someone plays that exact line.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_calls.gd
extends "res://tests/support/player_test.gd"

const DIALOGUE_FOLDER: String = "res://dialogue/"
## The autoloads the lines call, by the name they use, and the script each one runs.
const AUTOLOADS: Dictionary[String, String] = {
	"GameState": "res://core/game_state.gd",
	"Moral": "res://core/moral.gd",
	"Offers": "res://offers/offers.gd",
}
## A call to an autoload: its name, then the function's.
const CALL_PATTERN: String = "\\b(\\w+)\\.(\\w+)\\("


func _initialize() -> void:
	var functions: Dictionary[String, PackedStringArray] = {}
	for autoload: String in AUTOLOADS:
		functions[autoload] = _functions_of(AUTOLOADS[autoload])
	var pattern: RegEx = RegEx.create_from_string(CALL_PATTERN)
	var results: Array[bool] = []
	for file: String in DirAccess.get_files_at(DIALOGUE_FOLDER):
		if file.get_extension() != "dialogue":
			continue
		var text: String = FileAccess.get_file_as_string(DIALOGUE_FOLDER + file)
		var missing: PackedStringArray = []
		var checked: int = 0
		for found: RegExMatch in pattern.search_all(text):
			var autoload: String = found.get_string(1)
			if not functions.has(autoload):
				continue
			checked += 1
			var call: String = "%s.%s" % [autoload, found.get_string(2)]
			if not functions[autoload].has(found.get_string(2)) and not missing.has(call):
				missing.append(call)
		results.append(report(missing.is_empty(), "%s: %d calls to the autoloads, missing: %s"
				% [file, checked, missing]))
	finish(results)


func _functions_of(path: String) -> PackedStringArray:
	var names: PackedStringArray = []
	for method: Dictionary in (load(path) as Script).get_script_method_list():
		names.append(method["name"])
	return names
