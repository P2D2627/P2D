# Shared setup for the menu tests: the main scene, keys and gamepad buttons pressed and let go as
# the player does (also both in the same frame, as a quick tap arrives on a slow frame), the level
# slot, the text sizes against the UI theme, and a counter of the Back presses and releases that
# reach the rest of the game. It keeps the tests away from the player's settings and from quitting:
# the autoload Settings saves to a test file, and Quit, instead of closing the game, counts as a
# failure. finish adds two checks: Quit was never pressed, and the player's settings file is as it
# was, by its text and the time it was last written. A test extends this file instead of SceneTree,
# with
# extends "res://tests/support/menu_test.gd"
extends "res://tests/support/player_test.gd"

const MAIN_SCENE_PATH: String = "res://main.tscn"
const UI_THEME_PATH: String = "res://ui/ui_theme.tres"
## The file the autoload Settings saves to during the menu tests, deleted when they finish.
const SETTINGS_TEST_PATH: String = "user://test_menus.cfg"
## Process frames after a key or button goes down, and again after it comes up.
const TAP_FRAMES: int = 2

## The autoload Settings, once a main scene has been made; null before.
var settings: GameSettings
## Times Quit was pressed. A test never means to: in the game, Quit would end it with exit code 0.
var _quit_presses: int = 0
## The player's settings file when the first main scene was made, as _player_file_state gives it.
var _player_file_before: Array = []


## This file only holds what the menu tests share, so on its own it says so and stops.
func _initialize() -> void:
	printerr("menu_test.gd only holds shared setup: run one of the tests/test_*.gd files.")
	quit(1)


## Before the verdict: Quit was never pressed, and the player's settings file is as it was. The test
## file goes away.
func finish(results: Array[bool]) -> void:
	results.append(report(_quit_presses == 0, "Quit pressed during the test: %d times"
			% _quit_presses))
	if _player_file_before.is_empty():
		_player_file_before = _player_file_state()
	var same: bool = _player_file_state() == _player_file_before
	results.append(report(same, "The player's settings file is as it was before the test %s"
			% same))
	if FileAccess.file_exists(SETTINGS_TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_TEST_PATH))
	super(results)


## The main scene, loaded once the autoloads are in the tree, where its menus look Settings up. The
## first time, the player's settings file is noted down, and Settings is pointed at the test file.
func main_scene() -> PackedScene:
	if settings == null:
		if root.get_node_or_null(^"Settings") == null:
			await process_frame
		settings = root.get_node_or_null(^"Settings") as GameSettings
		_player_file_before = _player_file_state()
		if settings != null:
			settings.path = SETTINGS_TEST_PATH
	return load(MAIN_SCENE_PATH) as PackedScene


## A main scene in the tree, after its first frame, with Quit only counting. With levels, its list is
## replaced before it starts.
func new_main(levels: Variant = null) -> Node:
	var main: Node = (await main_scene()).instantiate()
	if levels != null:
		main.set(&"levels", levels)
	root.add_child(main)
	await process_frame
	_count_quit_instead(main)
	return main


## A main scene with its first level started from the menu: Play, then the first level's button.
func new_main_in_a_level() -> Node:
	var main: Node = await new_main()
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	return main


## Unpauses too, so a case that fails while paused leaves the next one a running game.
func remove_main(main: Node) -> void:
	paused = false
	main.queue_free()
	await process_frame


## The level in the main scene's slot; null if there is none.
func level_in(main: Node) -> Node:
	var slot: Node = main.get_node_or_null(^"%LevelSlot")
	return slot.get_child(0) if slot != null and slot.get_child_count() > 0 else null


func levels_in(main: Node) -> int:
	var slot: Node = main.get_node_or_null(^"%LevelSlot")
	return slot.get_child_count() if slot != null else 0


## Presses a key and lets it go, as the keyboard does: the event reaches the Input Map actions and
## the selected button.
func tap(key: Key) -> void:
	await press_key(key, true)
	await press_key(key, false)


## Half of a tap: the key goes down, or comes up.
func press_key(key: Key, pressed: bool) -> void:
	Input.parse_input_event(_key_event(key, pressed))
	await _wait_tap_frames()


## A quick tap: the key goes down and comes up in the same frame.
func tap_in_one_frame(key: Key) -> void:
	Input.parse_input_event(_key_event(key, true))
	Input.parse_input_event(_key_event(key, false))
	await _wait_tap_frames()


## The same for a gamepad button.
func tap_joypad(button: JoyButton) -> void:
	await press_joypad(button, true)
	await press_joypad(button, false)


## Half of a gamepad tap: the button goes down, or comes up.
func press_joypad(button: JoyButton, pressed: bool) -> void:
	Input.parse_input_event(_joypad_event(button, pressed))
	await _wait_tap_frames()


## A quick gamepad tap: the button goes down and comes up in the same frame.
func tap_joypad_in_one_frame(button: JoyButton) -> void:
	Input.parse_input_event(_joypad_event(button, true))
	Input.parse_input_event(_joypad_event(button, false))
	await _wait_tap_frames()


## The UI theme's text size, in px; -1 if there is no theme.
func theme_font_size() -> int:
	if not ResourceLoader.exists(UI_THEME_PATH):
		return -1
	return (load(UI_THEME_PATH) as Theme).default_font_size


## The labels and buttons under node, those made at run time included; none if node is null.
func texts_in(node: Node) -> Array[Control]:
	var texts: Array[Control] = []
	if node == null:
		return texts
	for child: Node in node.find_children("*", "Control", true, false):
		if child is Label or child is Button:
			texts.append(child as Control)
	return texts


## Of the controls, those whose text is not font_size px or has a size set on the control itself,
## each as its name and size.
func off_size(controls: Array[Control], font_size: int) -> Array[String]:
	var others: Array[String] = []
	for control: Control in controls:
		var size_now: int = control.get_theme_font_size(&"font_size")
		if size_now != font_size or control.has_theme_font_size_override(&"font_size"):
			others.append("%s %d px" % [control.name, size_now])
	return others


## Main quits the game on the main menu's quit_requested; in the tests the signal only counts. The
## menu is reached by its unique name, not by its class, so this file compiles before the menus do.
func _count_quit_instead(main: Node) -> void:
	var menu: Node = main.get_node_or_null(^"%MainMenu")
	if menu == null or not menu.has_signal(&"quit_requested"):
		return
	for connection: Dictionary in menu.get_signal_connection_list(&"quit_requested"):
		menu.disconnect(&"quit_requested", connection["callable"])
	menu.connect(&"quit_requested", _on_quit_pressed)


func _on_quit_pressed() -> void:
	_quit_presses += 1


## Whether the player's settings file exists and, if it does, its text and the time it was last
## written.
func _player_file_state() -> Array:
	var path: String = GameSettings.DEFAULT_PATH
	if not FileAccess.file_exists(path):
		return [false]
	return [true, FileAccess.get_file_as_string(path), FileAccess.get_modified_time(path)]


func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	return event


func _joypad_event(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _wait_tap_frames() -> void:
	for _frame: int in TAP_FRAMES:
		await process_frame


## Counts the presses and the releases of Back (ui_cancel: Esc, or B on the gamepad) that reach it
## unhandled. Put in the tree before the main scene, it gets them only if nothing in the main scene
## handled them: unhandled input goes up the tree from the bottom. It runs while the game is paused
## too: a pausable counter would stop getting input the moment an Esc paused the game.
class BackCounter extends Node:
	var presses: int = 0
	var releases: int = 0

	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_cancel"):
			presses += 1
		elif event.is_action_released(&"ui_cancel"):
			releases += 1
