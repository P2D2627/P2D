# Checks the player's options. The project has the five audio buses with a volume option, each
# sending to Master, then Alerts, which sends to SFX and so follows its option, the others under
# them, and the options as the autoload Settings. The buses of a single sound or source, there to
# mix it on its own, leave the mix as it is: at 0 dB, with no effects, and after every bus whose
# compressor listens to a bus they send to, so the compressor still hears them. With no file, every option is its default, and applied. A
# change applies at once: the bus volume and the frame rate cap. A volume option scales the bus's
# mix, its volume in the bus layout: 100% leaves the bus there and 50% puts it 6 dB under, also for
# a second settings node after the autoload has set the buses. Full screen and V-Sync do nothing
# without a window (from the first frame on, the engine reports the headless window as minimized
# and ignores a new mode), so only their values are checked, and the rest is checked by hand with
# F5. Each change is saved, with the file's version, and a new settings node reads the same values
# back. A broken file gives the defaults. Values of the wrong type, out of range or not a number
# (nan) are put right, and a frame rate cap the options do not offer turns into no cap. The
# accessibility switches Show Hidden and Hold To Escape, turned on, are saved and read back on, and
# a value of the wrong type in the file gives their default, off. Reset brings
# back the defaults and saves them. In the tests, a settings node on the player's file, the autoload
# among them, keeps its options in memory: it neither reads nor writes that file. The tests use a
# settings node of their own, with a file of their own, and never touch the player's file.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_settings.gd
extends "res://tests/support/player_test.gd"

const SETTINGS_SCRIPT: GDScript = preload("res://scenes/autoload/settings.gd")
const TEST_PATH: String = "user://test_settings.cfg"
## How far a bus volume read back from the AudioServer may be from the one set: it goes through dB.
const VOLUME_TOLERANCE: float = 0.0001
## The buses after the ones with a volume option, each with the bus it sends to and whose option it
## follows: Alerts holds the sounds that turn the ambience down, and follows SFX; Beds holds the
## ambience's beds and Gusts its passing gusts, which turn the beds down, and both follow Ambience;
## Thunder gathers the three thunder layers' buses and follows Ambience too.
const SUB_BUSES: Dictionary[StringName, StringName] = {&"Alerts": &"SFX", &"Beds": &"Ambience",
		&"Gusts": &"Ambience", &"Thunder": &"Ambience", &"ThunderBacklayer": &"Thunder",
		&"ThunderBackground": &"Thunder", &"ThunderMain": &"Thunder",
		&"Player": &"SFX", &"Demon": &"SFX", &"PlayerJump": &"Player", &"PlayerLand": &"Player",
		&"PlayerWallSlide": &"Player", &"PlayerFootsteps": &"Player", &"DemonLatch": &"Demon",
		&"DemonJump": &"Demon", &"DemonAttack": &"Demon", &"DemonCrucifixHit": &"Demon",
		&"DemonAlert": &"Alerts", &"CrucifixCue": &"Alerts", &"CrucifixHold": &"Alerts",
		&"PlayerLowSP": &"Alerts", &"Bed1": &"Beds", &"Bed2": &"Beds", &"LowRumble": &"Ambience",
		&"Fire": &"Ambience"}
## The buses of a single sound or source (the groups Player and Demon among them): only for
## mixing, so each must leave the mix as it is.
const MIX_ONLY_BUSES: Array[StringName] = [&"Player", &"Demon", &"PlayerJump", &"PlayerLand",
		&"PlayerWallSlide", &"PlayerFootsteps", &"DemonLatch", &"DemonJump", &"DemonAttack",
		&"DemonCrucifixHit", &"DemonAlert", &"CrucifixCue", &"CrucifixHold", &"PlayerLowSP",
		&"Bed1", &"Bed2", &"LowRumble", &"Fire"]
const BusRoute = preload("res://tests/support/bus_route.gd")
const BUS_LAYOUT_PATH: String = "res://default_bus_layout.tres"
## A volume option at half, 6.02 dB under the mix, and how far a bus's dB may be from the expected.
const HALF_VOLUME: float = 0.5
const DB_TOLERANCE: float = 0.01


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_the_project_has_the_buses_and_the_settings_autoload())
	results.append(_the_mix_only_buses_leave_the_mix_as_it_is())
	results.append(await _with_no_file_every_option_is_its_default_and_applied())
	results.append(await _a_change_applies_at_once())
	results.append(await _a_volume_option_scales_the_bus_layouts_mix())
	results.append(await _each_change_is_saved_and_read_back())
	results.append(await _a_broken_file_gives_the_defaults())
	results.append(await _wrong_values_in_the_file_are_put_right())
	results.append(await _the_switches_are_saved_read_back_and_put_right())
	results.append(await _the_gamepad_buttons_are_saved_read_back_and_put_right())
	results.append(await _reset_brings_back_the_defaults_and_saves_them())
	results.append(await _in_the_tests_the_players_file_is_neither_read_nor_written())
	_delete_test_file()
	finish(results)


func _the_project_has_the_buses_and_the_settings_autoload() -> bool:
	var names: Array[StringName] = []
	var sends_right: bool = true
	for index: int in AudioServer.bus_count:
		var bus: StringName = AudioServer.get_bus_name(index)
		names.append(bus)
		if index > 0:
			var to: StringName = SUB_BUSES.get(bus, &"Master")
			sends_right = sends_right and AudioServer.get_bus_send(index) == to
	var expected: Array[StringName] = GameSettings.BUSES.duplicate()
	expected.append_array(SUB_BUSES.keys())
	var autoload: Node = root.get_node_or_null(^"Settings")
	var is_settings: bool = autoload is GameSettings
	return report(names == expected and sends_right and is_settings,
			"The buses %s, the option buses sending to Master and the others to theirs %s; "
			% [names, sends_right]
			+ "the Settings autoload in the tree %s" % is_settings)


## Godot mixes the buses from the last to the first, so a compressor's sidechain hears a bus sent
## into the bus it listens to only when the sending bus comes after the compressor's bus.
func _the_mix_only_buses_leave_the_mix_as_it_is() -> bool:
	var layout: AudioBusLayout = load(BUS_LAYOUT_PATH) as AudioBusLayout
	var off: Array[String] = []
	for bus: StringName in MIX_ONLY_BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		if index == -1:
			off.append("%s missing" % bus)
			continue
		var stored: Variant = layout.get("bus/%d/volume_db" % index)
		if stored is float and not is_zero_approx(stored):
			off.append("%s at %.2f dB in the layout" % [bus, stored])
		if AudioServer.get_bus_effect_count(index) > 0:
			off.append("%s has effects" % bus)
		if AudioServer.is_bus_mute(index) or AudioServer.is_bus_solo(index) 				or AudioServer.is_bus_bypassing_effects(index):
			off.append("%s muted, solo or bypassed" % bus)
		var route: Array[StringName] = BusRoute.route(bus)
		if route.is_empty() or route[-1] != &"Master":
			off.append("%s does not reach Master (%s)" % [bus, route])
		for listener: int in AudioServer.bus_count:
			for effect: int in AudioServer.get_bus_effect_count(listener):
				var compressor := AudioServer.get_bus_effect(listener, effect) as AudioEffectCompressor
				if compressor != null and compressor.sidechain in route and index <= listener:
					off.append("%s comes before %s, whose compressor listens to %s"
							% [bus, AudioServer.get_bus_name(listener), compressor.sidechain])
	return report(off.is_empty(), "The %d mix-only buses are at 0 dB, with no effects, reach "
			% MIX_ONLY_BUSES.size() + "Master and come after the compressors that listen to them "
			+ "(off: %s)" % "; ".join(off))


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
	var music_right: bool = absf(music - 0.25 * db_to_linear(_layout_db(&"Music"))) < VOLUME_TOLERANCE
	var cap_right: bool = Engine.max_fps == 120
	var kept: bool = settings.is_fullscreen() and not settings.is_vsync_on()
	settings.reset_to_defaults()
	settings.queue_free()
	return report(music_right and cap_right and kept,
			"A change applies: Music at %.2f, max FPS 120 %s; full screen on and V-Sync off kept %s"
			% [music, cap_right, kept])


## The bus layout holds the mix, what the editor's Audio panel sets: an option at 1 leaves each bus at
## its volume there, and 0.5 puts it 6 dB under. The autoload has already set the buses, so a second
## settings node that took the buses' volumes for the mix would put them under it twice.
func _a_volume_option_scales_the_bus_layouts_mix() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var off: Array[String] = []
	for volume: float in [GameSettings.DEFAULT_VOLUME, HALF_VOLUME]:
		for bus: StringName in GameSettings.BUSES:
			settings.set_volume(bus, volume)
			var expected: float = _layout_db(bus) + linear_to_db(volume)
			var actual: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
			if absf(actual - expected) > DB_TOLERANCE:
				off.append("%s at %.2f: %.2f dB, not %.2f" % [bus, volume, actual, expected])
	settings.reset_to_defaults()
	settings.queue_free()
	var mixes: Array = GameSettings.BUSES.map(func(bus: StringName) -> String:
			return "%s %.2f dB" % [bus, _layout_db(bus)])
	return report(off.is_empty(),
			"Each bus at its mix in the layout (%s) plus its option, at 100%% and 50%% (off: %s)"
			% [", ".join(mixes), ", ".join(off)])


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


## Show Hidden (#253) and Hold To Escape (#246), the accessibility switches: off by default, so on is
## what must survive a save, and a wrong type in the file must not turn one on.
func _the_switches_are_saved_read_back_and_put_right() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	settings.set_show_hidden(true)
	settings.set_hold_to_escape(true)
	settings.queue_free()
	var again: GameSettings = await _new_settings()
	var read_back: Array = [again.is_show_hidden_on(), again.is_hold_to_escape_on()]
	again.reset_to_defaults()
	again.queue_free()
	var file: ConfigFile = ConfigFile.new()
	file.set_value("accessibility", "show_hidden", "yes")
	file.set_value("accessibility", "hold_to_escape", 1)
	file.save(TEST_PATH)
	var wrong: GameSettings = await _new_settings()
	var put_right: Array = [wrong.is_show_hidden_on(), wrong.is_hold_to_escape_on()]
	wrong.queue_free()
	return report(read_back == [true, true] and put_right == [false, false],
			("Show Hidden and Hold To Escape turned on, read back by a new settings node: %s "
			+ "(expected [true, true]); \"yes\" and 1 in the file read as %s (expected [false, false])")
			% [read_back, put_right])


## Gamepad buttons starts on Automatic, PlayStation is read back by a new settings node, and an id
## that is not one, in the file or handed to the setter, gives or keeps a valid one.
func _the_gamepad_buttons_are_saved_read_back_and_put_right() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var first: StringName = settings.get_pad_buttons()
	settings.set_pad_buttons(GameSettings.PAD_BUTTONS_PLAYSTATION)
	settings.queue_free()
	var again: GameSettings = await _new_settings()
	var read_back: StringName = again.get_pad_buttons()
	again.queue_free()
	var file: ConfigFile = ConfigFile.new()
	file.set_value("input", "pad_buttons", "gamecube")
	file.save(TEST_PATH)
	var wrong: GameSettings = await _new_settings()
	var put_right: StringName = wrong.get_pad_buttons()
	wrong.set_pad_buttons(GameSettings.PAD_BUTTONS_XBOX)
	wrong.set_pad_buttons(&"gamecube")
	var kept: StringName = wrong.get_pad_buttons()
	wrong.queue_free()
	return report(first == GameSettings.PAD_BUTTONS_AUTO
			and read_back == GameSettings.PAD_BUTTONS_PLAYSTATION
			and put_right == GameSettings.PAD_BUTTONS_AUTO and kept == GameSettings.PAD_BUTTONS_XBOX,
			("Gamepad buttons starts on %s (expected auto), PlayStation read back as %s, \"gamecube\" "
			+ "in the file reads as %s (expected auto), and handed to the setter keeps %s (expected xbox)")
			% [first, read_back, put_right, kept])


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
		var expected: float = settings.get_volume(bus) * db_to_linear(_layout_db(bus))
		if absf(volume - expected) > VOLUME_TOLERANCE:
			return false
	return Engine.max_fps == settings.get_fps_cap()


## The bus's volume in the project's bus layout, in dB, read from the file: 0 when it is not set.
func _layout_db(bus: StringName) -> float:
	var layout: AudioBusLayout = load(BUS_LAYOUT_PATH) as AudioBusLayout
	var stored: Variant = layout.get("bus/%d/volume_db" % AudioServer.get_bus_index(bus))
	return stored if stored is float else 0.0


func _write_test_file(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
