# The base of every test and measure script. Before the autoloads are ready, it tells the autoload
# Settings to keep its options in memory, from the defaults, and to neither read nor write the
# player's settings file, so a test gives the same result on every computer, whatever options and
# controls were chosen on it, and never changes the player's options. A script extends this file,
# or a support file that does, instead of SceneTree, with
# extends "res://tests/support/base_test.gd"
extends SceneTree


func _init() -> void:
	GameSettings.ignore_player_file = true


## Whether the player's settings file exists and, if it does, its text and the time it was last
## written, to check that a test left it as it was.
func player_file_state() -> Array:
	var path: String = GameSettings.DEFAULT_PATH
	if not FileAccess.file_exists(path):
		return [false]
	return [true, FileAccess.get_file_as_string(path), FileAccess.get_modified_time(path)]
