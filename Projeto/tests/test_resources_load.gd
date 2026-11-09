# Loads every scene, resource, script, shader and imported asset under res:// (outside addons/, android/ and
# .godot/) and checks four things. Each file loads. Each script compiles: a script with an error still loads, so
# this is what catches a preload of a path that no longer exists. Each dependency of a scene or resource exists,
# and the UID it names belongs to that same path. No scene or resource points into the import cache
# (res://.godot/): git does not keep that folder, each machine builds it again on import, and a path into it breaks
# when its source file moves. The engine does not list such a path among the dependencies when it sits in a
# sub-resource's load_path, so the test looks for it in the text. To fix one, pick the texture or file again in the
# editor, from its place under res://.
# Run it after the editor has imported the project: with an old import cache it reports UID problems that are not
# real.
# With "-- --trace" at the end of the command, it also prints a CHECK line on stderr before each file, the stream
# the engine's errors use, so each engine error comes after the CHECK line of the file being loaded at the time
# (for a broken dependency, the first file that loads it); one UID line per file that has a UID; and the first few
# raw dependency strings, as DEPENDENCY_SAMPLE lines.
# Limits: an error the engine prints while a scene or resource loads does not fail the test by itself, it only
# shows in the output; abstract scripts are not checked for compiling; and on Windows a path with the wrong letter
# case still loads, so letter case is only checked where a dependency also names a UID.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_resources_load.gd
extends "res://tests/support/base_test.gd"

const SKIPPED: PackedStringArray = ["res://addons", "res://android", "res://.godot"]
const LOADED_TYPES: PackedStringArray = ["tscn", "tres", "res", "scn", "gd", "gdshader", "gdshaderinc"]
## Text scenes and resources: their dependencies are checked one by one and their text is searched.
const TEXT_TYPES: PackedStringArray = ["tscn", "tres"]
const IMPORT_CACHE: String = "res://.godot/"
## How many raw dependency strings --trace prints, to show the engine's format in the log.
const DEPENDENCY_SAMPLES: int = 3

var _trace: bool = false
var _samples_left: int = DEPENDENCY_SAMPLES


func _initialize() -> void:
	_trace = OS.get_cmdline_user_args().has("--trace")
	await process_frame
	var files: PackedStringArray = []
	_collect("res://", files)
	if files.is_empty():
		printerr("PROBLEM: no files found under res://")
		quit(1)
		return
	var not_loading: PackedStringArray = []
	var not_compiling: PackedStringArray = []
	var broken: PackedStringArray = []
	var into_cache: PackedStringArray = []
	for path: String in files:
		if _trace:
			printerr("CHECK %s" % path)
			var uid: int = ResourceLoader.get_resource_uid(path)
			if uid != ResourceUID.INVALID_ID:
				print("UID\t%s\t%s" % [path, ResourceUID.id_to_text(uid)])
		if path.get_extension() in TEXT_TYPES:
			broken.append_array(_dependency_problems(path))
			var line: int = _cache_line(path)
			if line > 0:
				into_cache.append(_problem("%s points into the import cache at line %d" % [path, line]))
		var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		if resource == null:
			not_loading.append(_problem("%s does not load" % path))
		elif resource is Script and not _compiles(resource as Script):
			not_compiling.append(_problem("%s does not compile" % path))
	var results: Array[bool] = [
		_verdict(not_loading, "every file loads", "files that do not load"),
		_verdict(not_compiling, "every script compiles", "scripts that do not compile"),
		_verdict(broken, "every dependency exists, with the UID of its path", "broken dependencies"),
		_verdict(into_cache, "no scene or resource points into the import cache",
				"scenes or resources that point into the import cache (pick the file again in the editor)"),
	]
	print("test_resources_load: %d files, %d problems"
			% [files.size(), not_loading.size() + not_compiling.size() + broken.size() + into_cache.size()])
	quit(1 if results.has(false) else 0)


func _collect(folder: String, files: PackedStringArray) -> void:
	for child: String in DirAccess.get_directories_at(folder):
		var path: String = folder.path_join(child)
		if path not in SKIPPED:
			_collect(path, files)
	for file: String in DirAccess.get_files_at(folder):
		var path: String = folder.path_join(file)
		if file.get_extension() in LOADED_TYPES or FileAccess.file_exists(path + ".import"):
			files.append(path)


## The problems with a scene's or resource's dependencies, each printed as it is found.
func _dependency_problems(path: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	for dependency: String in ResourceLoader.get_dependencies(path):
		if _trace and _samples_left > 0:
			_samples_left -= 1
			print("DEPENDENCY_SAMPLE %s" % dependency)
		var uid_text: String = ""
		var paths: PackedStringArray = []
		for part: String in dependency.split("::"):
			if part.begins_with("uid://"):
				uid_text = part
			elif part.begins_with("res://"):
				paths.append(part)
		for needed: String in paths:
			if not ResourceLoader.exists(needed) and not FileAccess.file_exists(needed):
				problems.append(_problem("%s needs %s, which does not exist" % [path, needed]))
		if not uid_text.is_empty():
			var id: int = ResourceUID.text_to_id(uid_text)
			if not ResourceUID.has_id(id):
				problems.append(_problem("%s names %s, which no file has" % [path, uid_text]))
			elif not paths.is_empty() and ResourceUID.get_id_path(id) != paths[paths.size() - 1]:
				problems.append(_problem("%s: %s belongs to %s, the text path says %s"
						% [path, uid_text, ResourceUID.get_id_path(id), paths[paths.size() - 1]]))
	return problems


## The first line of the file that names the import cache, or 0 when none does.
func _cache_line(path: String) -> int:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	for index: int in lines.size():
		if lines[index].contains(IMPORT_CACHE):
			return index + 1
	return 0


## A script with an error still loads; can_instantiate() is what turns false. Abstract scripts cannot be
## instantiated either, so they count as compiling.
func _compiles(script: Script) -> bool:
	return script.can_instantiate() or script.is_abstract()


## Prints a problem on stderr, where the engine's errors go, and hands it back.
func _problem(text: String) -> String:
	printerr("PROBLEM: %s" % text)
	return text


## PASS, or FAIL with how many problems there are; the problems themselves are the PROBLEM lines above.
func _verdict(problems: PackedStringArray, passed: String, failed: String) -> bool:
	if problems.is_empty():
		print("PASS: %s" % passed)
	else:
		print("FAIL: %s: %d" % [failed, problems.size()])
	return problems.is_empty()
