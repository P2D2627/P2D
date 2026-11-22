# Checks the project setting the controller's vibration needs in an exported game (#284): text
# resources are not converted to binary on export. On 20/11, with the conversion on, the 18 pulses
# that rumble_stats.gd creates as script defaults came out null in the .exe (jump, hit and death did
# not vibrate); with it off, they came through. Turning it back on in Project Settings fails here;
# the README's "Vibração do comando" says why and what it costs.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_export_settings.gd
extends "res://tests/support/player_test.gd"

const SETTING: String = "editor/export/convert_text_resources_to_binary"


func _initialize() -> void:
	var results: Array[bool] = []
	var value: Variant = ProjectSettings.get_setting(SETTING, true)
	results.append(report(value is bool and value == false, "%s is %s (false)" % [SETTING, value]))
	finish(results)
