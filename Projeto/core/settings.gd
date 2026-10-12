class_name GameSettings
extends Node

## The player's options: the volume of each audio bus, full screen, V-Sync and the frame rate cap.
## Each option applies as soon as it changes and is saved at once to a file, read again when the
## game starts. The project loads this script as the autoload Settings, before any scene, so the
## options apply even to a level run on its own with F6. The menus read and change the options
## here, and never touch the audio, the window or the engine themselves.

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

## The file the options are kept in. The tests point a settings node of their own at another file.
var path: String = DEFAULT_PATH

var _volumes: Dictionary[StringName, float] = {}
var _fullscreen: bool = DEFAULT_FULLSCREEN
var _vsync: bool = DEFAULT_VSYNC
var _fps_cap: int = DEFAULT_FPS_CAP


func _ready() -> void:
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


## The same as reading a file with nothing in it.
func reset_to_defaults() -> void:
	_take_options_from(ConfigFile.new())
	save_to_file()


## Reads the file at path and applies what it says. A file that is missing or cannot be read gives
## every option its default.
func load_from_file() -> void:
	var file: ConfigFile = ConfigFile.new()
	var error: Error = file.load(path)
	if error != OK:
		if error != ERR_FILE_NOT_FOUND:
			push_warning("Settings: could not read %s (error %d); using the defaults."
					% [path, error])
		file.clear()
	_take_options_from(file)


func save_to_file() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("meta", "version", FILE_VERSION)
	for bus: StringName in BUSES:
		file.set_value("audio", bus, _volumes[bus])
	file.set_value("display", "fullscreen", _fullscreen)
	file.set_value("display", "vsync", _vsync)
	file.set_value("display", "fps_cap", _fps_cap)
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
