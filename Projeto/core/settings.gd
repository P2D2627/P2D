class_name GameSettings
extends Node

## The player's options: the volume of each audio bus, full screen, V-Sync, the frame rate cap and
## the controls, a profile from InputProfiles and the bindings of the custom one. Each option
## applies as soon as it changes and is saved at once to a file, read again when the game starts.
## The project loads this script as the autoload Settings, before any scene, so the options apply
## even to a level run on its own with F6. The menus read and change the options here, and never
## touch the audio, the window, the Input Map or the engine themselves.

## The audio buses with a volume option, in the order the options show them. The project's bus
## layout, default_bus_layout.tres, has all of them.
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Ambience", &"UI"]
## The frame rate cap that means no cap: Engine.max_fps takes 0 that way.
const NO_FPS_CAP: int = 0
## The frame rate caps on offer, in frames per second. The cap only limits drawing: the physics runs
## at 60 steps a second whatever it is.
const FPS_CAPS: Array[int] = [NO_FPS_CAP, 60, 120, 240]
## Written to the file, for the day its layout changes and an older file has to be read otherwise.
const FILE_VERSION: int = 1
const DEFAULT_PATH: String = "user://settings.cfg"
## Linear volume: 0 is silent and 1 is the bus at full volume.
const DEFAULT_VOLUME: float = 1.0
const DEFAULT_FULLSCREEN: bool = false
const DEFAULT_VSYNC: bool = true
const DEFAULT_FPS_CAP: int = NO_FPS_CAP

## True only in the tests, set by tests/support/base_test.gd before the autoload is ready: then a
## settings node on the player's file keeps its options in memory, from the defaults, and neither
## reads nor writes that file. The tests then give the same results on every computer, whatever
## options and controls were chosen on it, and never change the player's options.
static var ignore_player_file: bool = false

## The file the options are kept in; empty keeps them in memory only. The tests point a settings
## node of their own at a file of their own.
var path: String = DEFAULT_PATH

var _volumes: Dictionary[StringName, float] = {}
var _fullscreen: bool = DEFAULT_FULLSCREEN
var _vsync: bool = DEFAULT_VSYNC
var _fps_cap: int = DEFAULT_FPS_CAP
## The id of the controls profile that is on, one of InputProfiles.PROFILES.
var _input_profile: StringName = InputProfiles.DEFAULT_PROFILE
## The custom profile's bindings, by action; every action in InputProfiles.ACTIONS has at least one.
var _custom_bindings: Dictionary[StringName, PackedStringArray] = {}


func _ready() -> void:
	if ignore_player_file and path == DEFAULT_PATH:
		path = ""
	load_from_file()


func get_volume(bus: StringName) -> float:
	return _volumes.get(bus, DEFAULT_VOLUME)


func set_volume(bus: StringName, volume: float) -> void:
	if bus not in BUSES:
		push_error("Settings: %s is not a bus with a volume option." % bus)
		return
	_volumes[bus] = _valid_volume(volume)
	_apply_volume(bus)
	save_to_file()


func is_fullscreen() -> bool:
	return _fullscreen


func set_fullscreen(fullscreen: bool) -> void:
	_fullscreen = fullscreen
	_apply_fullscreen()
	save_to_file()


func is_vsync_on() -> bool:
	return _vsync


func set_vsync(vsync: bool) -> void:
	_vsync = vsync
	_apply_vsync()
	save_to_file()


func get_fps_cap() -> int:
	return _fps_cap


func set_fps_cap(fps_cap: int) -> void:
	_fps_cap = _offered_fps_cap(fps_cap)
	_apply_fps_cap()
	save_to_file()


func get_input_profile() -> StringName:
	return _input_profile


func set_input_profile(profile: StringName) -> void:
	if profile not in InputProfiles.PROFILES:
		push_error("Settings: %s is not an input profile." % profile)
		return
	_input_profile = profile
	_apply_input()
	save_to_file()


## The bindings of action in the profile that is on.
func get_bindings(action: StringName) -> PackedStringArray:
	if _input_profile == InputProfiles.CUSTOM:
		return _custom_bindings.get(action, PackedStringArray())
	return InputProfiles.preset(_input_profile).get(action, PackedStringArray())


## Remaps action, in the custom profile, to binding alone. If another action had binding, the two
## swap: that action loses it and, left with none, takes action's old bindings, so no action is
## ever left without one. Does nothing outside the custom profile, or with a binding not on offer.
func set_custom_binding(action: StringName, binding: String) -> void:
	if (_input_profile != InputProfiles.CUSTOM or action not in InputProfiles.ACTIONS
			or not InputProfiles.is_valid(binding)):
		push_error("Settings: cannot bind %s to %s." % [action, binding])
		return
	var old_bindings: PackedStringArray = _custom_bindings[action]
	for other: StringName in InputProfiles.ACTIONS:
		if other == action or binding not in _custom_bindings[other]:
			continue
		var kept: PackedStringArray = _custom_bindings[other].duplicate()
		kept.remove_at(kept.find(binding))
		_custom_bindings[other] = kept if not kept.is_empty() else old_bindings
	_custom_bindings[action] = PackedStringArray([binding])
	_apply_input()
	save_to_file()


## The custom profile goes back to a copy of the default one.
func reset_custom_bindings() -> void:
	_custom_bindings = InputProfiles.preset(InputProfiles.DEFAULT_PROFILE)
	_apply_input()
	save_to_file()


## The same as reading a file with nothing in it, for every option but the controls, which have
## their own reset on the controls screen.
func reset_to_defaults() -> void:
	_take_options_from(ConfigFile.new())
	save_to_file()


## Reads the file at path and applies what it says. A file that is missing or cannot be read, or no
## path, gives every option its default.
func load_from_file() -> void:
	var file: ConfigFile = ConfigFile.new()
	var error: Error = file.load(path) if not path.is_empty() else ERR_FILE_NOT_FOUND
	if error != OK:
		if error != ERR_FILE_NOT_FOUND:
			push_warning("Settings: could not read %s (error %d); using the defaults."
					% [path, error])
		file.clear()
	_take_options_from(file)
	_take_input_from(file)


## Saves every option to the file at path; with no path, nothing is saved.
func save_to_file() -> void:
	if path.is_empty():
		return
	var file: ConfigFile = ConfigFile.new()
	file.set_value("meta", "version", FILE_VERSION)
	for bus: StringName in BUSES:
		file.set_value("audio", bus, _volumes[bus])
	file.set_value("display", "fullscreen", _fullscreen)
	file.set_value("display", "vsync", _vsync)
	file.set_value("display", "fps_cap", _fps_cap)
	file.set_value("input", "profile", String(_input_profile))
	for action: StringName in InputProfiles.ACTIONS:
		file.set_value("input_custom", action, _custom_bindings[action])
	var error: Error = file.save(path)
	if error != OK:
		push_error("Settings: could not save %s (error %d)." % [path, error])


## Takes every option from the file, or its default where the file has none or one of the wrong
## type, puts volumes into 0 to 1 and a cap not on offer to no cap, and applies them all.
func _take_options_from(file: ConfigFile) -> void:
	for bus: StringName in BUSES:
		_volumes[bus] = _valid_volume(_read_number(file, "audio", bus, DEFAULT_VOLUME))
	_fullscreen = _read_bool(file, "display", "fullscreen", DEFAULT_FULLSCREEN)
	_vsync = _read_bool(file, "display", "vsync", DEFAULT_VSYNC)
	_fps_cap = _offered_fps_cap(int(_read_number(file, "display", "fps_cap", DEFAULT_FPS_CAP)))
	for bus: StringName in BUSES:
		_apply_volume(bus)
	_apply_fullscreen()
	_apply_vsync()
	_apply_fps_cap()


## Takes the profile and the custom bindings from the file, and puts them in the Input Map. A
## profile id that is not one gives the default; a custom action with no binding on offer gives the
## default profile's, and a binding that is not on offer is dropped.
func _take_input_from(file: ConfigFile) -> void:
	var saved: Variant = file.get_value("input", "profile", "")
	var profile: StringName = StringName(saved) if saved is String or saved is StringName else &""
	_input_profile = profile if profile in InputProfiles.PROFILES else InputProfiles.DEFAULT_PROFILE
	var defaults: Dictionary[StringName, PackedStringArray] = \
			InputProfiles.preset(InputProfiles.DEFAULT_PROFILE)
	_custom_bindings = {}
	for action: StringName in InputProfiles.ACTIONS:
		var bindings: PackedStringArray = PackedStringArray()
		var value: Variant = file.get_value("input_custom", action, PackedStringArray())
		if value is PackedStringArray:
			for binding: String in value as PackedStringArray:
				if InputProfiles.is_valid(binding) and binding not in bindings:
					bindings.append(binding)
		_custom_bindings[action] = bindings if not bindings.is_empty() else defaults[action]
	_apply_input()


func _read_number(file: ConfigFile, section: String, key: String, default: float) -> float:
	var value: Variant = file.get_value(section, key, default)
	return float(value) if value is float or value is int else default


func _read_bool(file: ConfigFile, section: String, key: String, default: bool) -> bool:
	var value: Variant = file.get_value(section, key, default)
	return value as bool if value is bool else default


## A volume in 0 to 1. One that is not a number (nan), or is infinite, gives the default: clamping
## would leave nan as it is.
func _valid_volume(volume: float) -> float:
	return clampf(volume, 0.0, 1.0) if is_finite(volume) else DEFAULT_VOLUME


func _offered_fps_cap(fps_cap: int) -> int:
	return fps_cap if fps_cap in FPS_CAPS else DEFAULT_FPS_CAP


func _apply_volume(bus: StringName) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		push_error("Settings: the bus layout has no %s bus." % bus)
		return
	AudioServer.set_bus_volume_linear(index, _volumes[bus])


## Only when it differs, so a window that is already right is left alone.
func _apply_fullscreen() -> void:
	var mode: Window.Mode = Window.MODE_FULLSCREEN if _fullscreen else Window.MODE_WINDOWED
	if get_window().mode != mode:
		get_window().mode = mode


func _apply_vsync() -> void:
	var vsync_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_DISABLED
	if _vsync:
		vsync_mode = DisplayServer.VSYNC_ENABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)


func _apply_fps_cap() -> void:
	Engine.max_fps = _fps_cap


## Puts the profile's keys and mouse buttons in the Input Map, in place of the ones there, and
## leaves the gamepad's alone. An action whose keys and buttons are already the profile's is left
## alone too: taking an event out of an action lets go of the action, which would drop a key held
## down, or one a test pressed before the game started.
func _apply_input() -> void:
	for action: StringName in InputProfiles.ACTIONS:
		if not InputMap.has_action(action):
			push_error("Settings: the Input Map has no %s action." % action)
			continue
		var wanted: PackedStringArray = get_bindings(action)
		var current: PackedStringArray = []
		for event: InputEvent in InputMap.action_get_events(action):
			if InputProfiles.is_profile_event(event):
				current.append(InputProfiles.binding_from_event(event))
		if _same_bindings(current, wanted):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			if InputProfiles.is_profile_event(event):
				InputMap.action_erase_event(action, event)
		for binding: String in wanted:
			InputMap.action_add_event(action, InputProfiles.event_from_binding(binding))


## True if both hold the same bindings, in any order.
func _same_bindings(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for binding: String in a:
		if binding not in b:
			return false
	return true
