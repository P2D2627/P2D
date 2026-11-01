# Checks the player's options. The project has the five audio buses, each sending to Master, and
# the options as the autoload Settings. With no file, every option is its default, and applied. A
# change applies at once: the bus volume and the frame rate cap. Full screen and V-Sync do nothing
# without a window (from the first frame on, the engine reports the headless window as minimized
# and ignores a new mode), so only their values are checked, and the rest is checked by hand with
# F5. Each change is saved, with the file's version, and a new settings node reads the same values
# back. A broken file gives the defaults. Values of the wrong type, out of range or not a number
# (nan) are put right, and a frame rate cap the options do not offer turns into no cap. Reset brings
# back the defaults and saves them. In the tests, a settings node on the player's file, the autoload
# among them, keeps its options in memory: it neither reads nor writes that file. The tests use a
# settings node of their own, with a file of their own, and never touch the player's file.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_settings.gd
extends "res://tests/support/player_test.gd"

const SETTINGS_SCRIPT: GDScript = preload("res://core/settings.gd")
const TEST_PATH: String = "user://test_settings.cfg"
## How far a bus volume read back from the AudioServer may be from the one set: it goes through dB.
const VOLUME_TOLERANCE: float = 0.0001


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_the_project_has_the_buses_and_the_settings_autoload())
	results.append(await _with_no_file_every_option_is_its_default_and_applied())
	results.append(await _a_change_applies_at_once())
	results.append(await _each_change_is_saved_and_read_back())
	results.append(await _a_broken_file_gives_the_defaults())
	results.append(await _wrong_values_in_the_file_are_put_right())
	results.append(await _reset_brings_back_the_defaults_and_saves_them())
	results.append(await _in_the_tests_the_players_file_is_neither_read_nor_written())
	_delete_test_file()
	finish(results)


func _the_project_has_the_buses_and_the_settings_autoload() -> bool:
	var names: Array[StringName] = []
	var all_send_to_master: bool = true
	for index: int in AudioServer.bus_count:
		names.append(AudioServer.get_bus_name(index))
		if index > 0:
			all_send_to_master = all_send_to_master and AudioServer.get_bus_send(index) == &"Master"
	var autoload: Node = root.get_node_or_null(^"Settings")
	var is_settings: bool = autoload is GameSettings
	return report(names == GameSettings.BUSES and all_send_to_master and is_settings,
			"The buses %s, all sending to Master %s; the Settings autoload in the tree %s"
			% [names, all_send_to_master, is_settings])


func _with_no_file_every_option_is_its_default_and_applied() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var values: bool = _has_the_defaults(settings)
	var applied: bool = _is_applied(settings)
	settings.queue_free()
	return report(values and applied,
			"No file: every option its default %s, and applied %s" % [values, applied])


func _a_change_applies_at_once() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_volume(&"Music", 0.25)
	settings.set_fullscreen(true)
	settings.set_vsync(false)
	settings.set_fps_cap(120)
	var music: float = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Music"))
	var music_right: bool = absf(music - 0.25) < VOLUME_TOLERANCE
	var cap_right: bool = Engine.max_fps == 120
	var kept: bool = settings.is_fullscreen() and not settings.is_vsync_on()
	settings.reset_to_defaults()
	settings.queue_free()
	return report(music_right and cap_right and kept,
			"A change applies: Music at %.2f, max FPS 120 %s; full screen on and V-Sync off kept %s"
			% [music, cap_right, kept])


## One change at a time, each from no file: every setter saves the whole file, so a setter that did
## not save would be hidden by the next one's save.
func _each_change_is_saved_and_read_back() -> bool:
	var outcomes: PackedStringArray = []
	var all_read_back: bool = true
	var version: Variant = null
	for change: String in ["SFX volume", "full screen", "V-Sync", "frame rate cap"]:
		_delete_test_file()
		var settings: GameSettings = await _new_settings()
		match change:
			"SFX volume":
				settings.set_volume(&"SFX", 0.4)
			"full screen":
				settings.set_fullscreen(true)
			"V-Sync":
				settings.set_vsync(false)
			"frame rate cap":
				settings.set_fps_cap(240)
		settings.queue_free()
		var file: ConfigFile = ConfigFile.new()
		if file.load(TEST_PATH) == OK:
			version = file.get_value("meta", "version")
		var again: GameSettings = await _new_settings()
		var read_back: bool = false
		match change:
			"SFX volume":
				read_back = is_equal_approx(again.get_volume(&"SFX"), 0.4)
			"full screen":
				read_back = again.is_fullscreen()
			"V-Sync":
				read_back = not again.is_vsync_on()
			"frame rate cap":
				read_back = again.get_fps_cap() == 240
		again.reset_to_defaults()
		again.queue_free()
		all_read_back = all_read_back and read_back
		outcomes.append("%s %s" % [change, read_back])
	return report(version == GameSettings.FILE_VERSION and all_read_back,
			"Saved with version %s, and read back by a new settings node: %s"
			% [version, ", ".join(outcomes)])


## The file starts well and breaks halfway, so a reader that kept what it read before the break
## would take Master at 0.3.
func _a_broken_file_gives_the_defaults() -> bool:
	_write_test_file("[audio]\nMaster=0.3\nthis is = = not [ a setting\n")
	var settings: GameSettings = await _new_settings()
	var values: bool = _has_the_defaults(settings)
	settings.queue_free()
	return report(values, "A broken file: every option its default %s" % values)


func _wrong_values_in_the_file_are_put_right() -> bool:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("audio", "Master", 3.0)
	file.set_value("audio", "Music", -1.0)
	file.set_value("audio", "SFX", "loud")
	file.set_value("audio", "Ambience", 1)
	file.set_value("audio", "UI", NAN)
	file.set_value("display", "fullscreen", "yes")
	file.set_value("display", "vsync", 0)
	file.set_value("display", "fps_cap", 75)
	file.save(TEST_PATH)
	var settings: GameSettings = await _new_settings()
	var got: Array = [settings.get_volume(&"Master"), settings.get_volume(&"Music"),
			settings.get_volume(&"SFX"), settings.get_volume(&"Ambience"),
			settings.get_volume(&"UI"), settings.is_fullscreen(), settings.is_vsync_on(),
			settings.get_fps_cap()]
	settings.set_fps_cap(75)
	var cap_by_code: int = settings.get_fps_cap()
	settings.set_volume(&"Music", NAN)
	var nan_by_code: float = settings.get_volume(&"Music")
	settings.queue_free()
	var expected: Array = [1.0, 0.0, 1.0, 1.0, 1.0, false, true, 0]
	return report(got == expected and cap_by_code == 0 and nan_by_code == 1.0,
			("Wrong values put right: Master 3.0, Music -1.0, SFX \"loud\", Ambience 1, UI nan, full "
			+ "screen \"yes\", V-Sync 0, cap 75 read as %s; set by code, a cap of 75 gives %d and a "
			+ "volume of nan %.1f") % [got, cap_by_code, nan_by_code])


func _reset_brings_back_the_defaults_and_saves_them() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_volume(&"Master", 0.5)
	settings.set_fullscreen(true)
	settings.set_vsync(false)
	settings.set_fps_cap(60)
	settings.reset_to_defaults()
	var values: bool = _has_the_defaults(settings)
	var applied: bool = _is_applied(settings)
	settings.queue_free()
	var again: GameSettings = await _new_settings()
	var saved: bool = _has_the_defaults(again)
	again.queue_free()
	return report(values and applied and saved,
			"Reset: every option its default %s, applied %s, saved %s" % [values, applied, saved])


## The autoload, and a new settings node left on the player's file, keep to memory in the tests:
## both have no path, start from the defaults, and a change to either leaves the player's file as
## it was, by its text and the time it was last written.
func _in_the_tests_the_players_file_is_neither_read_nor_written() -> bool:
	var before: Array = player_file_state()
	var autoload: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	var autoload_in_memory: bool = autoload != null and autoload.path.is_empty()
	var settings: GameSettings = SETTINGS_SCRIPT.new() as GameSettings
	root.add_child(settings)
	await process_frame
	var node_in_memory: bool = settings.path.is_empty() and _has_the_defaults(settings)
	settings.set_volume(&"Music", 0.3)
	settings.set_input_profile(InputProfiles.CUSTOM)
	if autoload != null:
		autoload.set_vsync(not autoload.is_vsync_on())
		autoload.set_vsync(not autoload.is_vsync_on())
	settings.queue_free()
	await process_frame
	var untouched: bool = player_file_state() == before
	return report(autoload_in_memory and node_in_memory and untouched,
			"In the tests: the autoload in memory %s, a new node on the player's file in memory and on the defaults %s, the player's file untouched %s"
			% [autoload_in_memory, node_in_memory, untouched])


## A settings node of the tests' own, on the test file, in the tree, where it reads the file.
func _new_settings() -> GameSettings:
	var settings: GameSettings = SETTINGS_SCRIPT.new() as GameSettings
	settings.path = TEST_PATH
	root.add_child(settings)
	await process_frame
	return settings


func _has_the_defaults(settings: GameSettings) -> bool:
	for bus: StringName in GameSettings.BUSES:
		if settings.get_volume(bus) != GameSettings.DEFAULT_VOLUME:
			return false
	return (settings.is_fullscreen() == GameSettings.DEFAULT_FULLSCREEN
			and settings.is_vsync_on() == GameSettings.DEFAULT_VSYNC
			and settings.get_fps_cap() == GameSettings.DEFAULT_FPS_CAP)


## Whether the audio and the engine show what the options say. Full screen and V-Sync are left out:
## they do nothing without a window.
func _is_applied(settings: GameSettings) -> bool:
	for bus: StringName in GameSettings.BUSES:
		var volume: float = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus))
		if absf(volume - settings.get_volume(bus)) > VOLUME_TOLERANCE:
			return false
	return Engine.max_fps == settings.get_fps_cap()


func _write_test_file(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
