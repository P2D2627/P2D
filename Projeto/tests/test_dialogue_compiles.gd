# Checks the dialogue files with the Dialogue Manager compiler (ADR 0030). Every .dialogue file in
# the dialogue folder compiles with no errors, and each chapter has the cues its level starts.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dialogue_compiles.gd
extends "res://tests/support/player_test.gd"

const DIALOGUE_FOLDER: String = "res://dialogue/"
const DIALOGUE_EXTENSION: String = "dialogue"
## The cues each level starts, by file.
const EXPECTED_CUES: Dictionary = {
	"lust.dialogue": [
		"waking", "name_empty", "named", "velvet", "velvet_questions", "velvet_argument",
		"velvet_advance", "velvet_burned", "asmodeus_offer", "asmodeus_second_offer",
		"asmodeus_gift", "stairs",
	],
	"gluttony.dialogue": [
		"arrival", "crumb", "crumb_wedding", "crumb_bite", "crumb_repelled", "beelzebub_offer",
		"beelzebub_second_offer", "beelzebub_gift", "stairs",
	],
	"greed.dialogue": [
		"arrival", "tally_and_chip", "ledger", "gate_1", "toll_1_stolen", "toll_1_climbed",
		"toll_1_paid", "gate_2", "toll_2_stolen", "toll_2_climbed", "toll_2_paid", "gate_3",
		"toll_3_stolen", "toll_3_climbed", "toll_3_paid", "mammon_gift", "stairs", "climbing_away",
	],
}


func _initialize() -> void:
	var results: Array[bool] = []
	var files: PackedStringArray = _dialogue_files()
	results.append(report(not files.is_empty(), "%d dialogue files found" % files.size()))
	for file_name: String in files:
		var compiled: DMCompilerResult = _compile(file_name)
		results.append(_compiles_without_errors(file_name, compiled))
		if EXPECTED_CUES.has(file_name):
			results.append(_has_expected_cues(file_name, compiled))
	for file_name: String in EXPECTED_CUES:
		results.append(report(files.has(file_name), "%s exists" % file_name))
	finish(results)


func _compiles_without_errors(file_name: String, compiled: DMCompilerResult) -> bool:
	for error: DMError in compiled.errors:
		print("  line %d, column %d: %s" % [
			error.line_number + 1, error.column_number, DMConstants.get_error_message(error.error),
		])
	return report(compiled.errors.is_empty(), "%s compiles with %d errors" % [
		file_name, compiled.errors.size(),
	])


func _has_expected_cues(file_name: String, compiled: DMCompilerResult) -> bool:
	var missing: Array[String] = []
	for cue: String in EXPECTED_CUES[file_name]:
		if not compiled.cues.has(cue):
			missing.append(cue)
	return report(missing.is_empty(), "%s has its %d cues, missing %s" % [
		file_name, EXPECTED_CUES[file_name].size(), missing,
	])


func _dialogue_files() -> PackedStringArray:
	var found: PackedStringArray = []
	for file_name: String in DirAccess.get_files_at(DIALOGUE_FOLDER):
		if file_name.get_extension() == DIALOGUE_EXTENSION:
			found.append(file_name)
	return found


func _compile(file_name: String) -> DMCompilerResult:
	var path: String = DIALOGUE_FOLDER + file_name
	return DMCompiler.compile_string(FileAccess.get_file_as_string(path), path)
