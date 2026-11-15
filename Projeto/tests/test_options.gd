# Checks the options screen, through the main scene. With no save, the main menu shows Settings
# (OptionsButton) between New Game (PlayButton) and Quit, and it opens the screen with the first
# volume selected, writing
# nothing. The screen
# shows what Settings holds. Each control changes Settings: the arrows move a volume, Enter turns
# full screen and V-Sync on and off, and the frame rate list picks a cap. Hold To Escape is the
# accessibility grid's last row, the down arrow and the D-pad reach it and go on, and Enter, the
# controller's A and the mouse each switch it. Reset
# brings back the
# defaults, on the screen and in Settings. Back, Esc and B close the screen onto the Options button,
# and that Esc goes no further. In the pause, the same screen opens; Esc and B go back to the pause,
# still paused, and Esc there resumes. A pause left from the options opens again on its own panel.
# All the text takes its size from the UI theme (its own, or a variation the theme sizes), with none
# set on a node. The autoload Settings saves to a test file (see
# tests/support/menu_test.gd), so the player's file is never touched.
# The cases give a button the focus straight away, unless the arrows are what they check: from the
# Options button, the down arrow and Enter would press Quit.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_options.gd
extends "res://tests/support/menu_test.gd"


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_main_menu_has_options_between_play_and_quit())
	results.append(await _options_opens_the_screen_on_the_first_volume())
	results.append(await _the_screen_shows_what_settings_holds())
	results.append(await _each_control_changes_settings())
	results.append(await _hold_to_escape_switches_with_keys_controller_and_mouse())
	results.append(await _the_down_arrow_and_the_d_pad_reach_hold_to_escape_and_go_on())
	results.append(await _reset_brings_back_the_defaults())
	results.append(await _back_esc_and_b_close_the_screen_onto_options())
	results.append(await _in_the_pause_esc_and_b_go_back_to_the_pause())
	results.append(await _a_pause_left_from_the_options_opens_on_its_own_panel())
	results.append(await _the_options_text_takes_its_size_from_the_ui_theme())
	finish(results)


func _the_main_menu_has_options_between_play_and_quit() -> bool:
	var main: Node = await _new_main_with_defaults()
	var order: PackedStringArray = []
	var panel: Node = main_menu_node(main, ^"%MainPanel")
	if panel != null:
		for child: Node in panel.get_children():
			if child is Button and (child as Button).visible:
				order.append((child as Button).text)
	await tap(KEY_DOWN)
	var selected: bool = has_focus(main_menu_node(main, ^"%OptionsButton"))
	await remove_main(main)
	return report(order == PackedStringArray(["NEW GAME", "SETTINGS", "QUIT"]) and selected,
			"The main menu's buttons %s, Options selected one below Play %s" % [order, selected])


## From Play, as the player does: the down arrow and Enter. Enter is only pressed on Options: on
## any other button it could be Quit. Opening the screen changes nothing, so it writes no file: the
## file is deleted first, and must still be missing.
func _options_opens_the_screen_on_the_first_volume() -> bool:
	var main: Node = await _new_main_with_defaults()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_TEST_PATH))
	await tap(KEY_DOWN)
	if has_focus(main_menu_node(main, ^"%OptionsButton")):
		await tap(KEY_ENTER)
	var options: Control = _options_in_the_main_menu(main)
	var shown: bool = _shows(options)
	var panel_hidden: bool = not _shows(main_menu_node(main, ^"%MainPanel") as Control)
	var sliders: Array[HSlider] = _sliders(options)
	var first_selected: bool = not sliders.is_empty() and has_focus(sliders[0])
	var nothing_written: bool = not FileAccess.file_exists(SETTINGS_TEST_PATH)
	await remove_main(main)
	return report(shown and panel_hidden and sliders.size() == GameSettings.BUSES.size()
			and first_selected and nothing_written,
			("Options: the screen shown %s, the main panel hidden %s, %d volume sliders, the first "
			+ "selected %s, no file written %s")
			% [shown, panel_hidden, sliders.size(), first_selected, nothing_written])


## With values away from the defaults, the controls change as the screen opens, and they must not
## hand those values back to Settings as changes: the file, deleted after the values were set, must
## still be missing.
func _the_screen_shows_what_settings_holds() -> bool:
	var main: Node = await _new_main_with_defaults()
	settings.set_volume(&"Music", 0.3)
	settings.set_fullscreen(true)
	settings.set_vsync(false)
	settings.set_fps_cap(120)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_TEST_PATH))
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var music: HSlider = _slider(options, &"Music")
	var slider_right: bool = music != null and is_equal_approx(music.value, 0.3)
	var shown: Array = [_value_label(music), _is_pressed(options, ^"%FullscreenCheck"),
			_is_pressed(options, ^"%VSyncCheck"), _fps_cap_shown(options)]
	var nothing_written: bool = not FileAccess.file_exists(SETTINGS_TEST_PATH)
	await remove_main(main)
	return report(slider_right and shown == ["30 %", true, false, 120] and nothing_written,
			("The screen shows Music's slider at 0.3 %s; its label, full screen, V-Sync and the cap "
			+ "%s; no file written %s") % [slider_right, shown, nothing_written])


## Each control gets the focus, as the arrows would give it, and then the keys a player presses.
## The frame rate list opens on Enter, and the down arrow and Enter pick the next cap.
func _each_control_changes_settings() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var master: HSlider = _slider(options, &"Master")
	await tap(KEY_LEFT)
	var volume_changed: bool = (is_equal_approx(settings.get_volume(&"Master"), 0.95)
			and _value_label(master) == "95 %")
	await press_on(options, ^"%FullscreenCheck", KEY_ENTER)
	var fullscreen_changed: bool = settings.is_fullscreen()
	await press_on(options, ^"%VSyncCheck", KEY_ENTER)
	var vsync_changed: bool = not settings.is_vsync_on()
	await press_on(options, ^"%FpsCapOption", KEY_ENTER)
	var list: OptionButton = null
	if options != null:
		list = options.get_node_or_null(^"%FpsCapOption") as OptionButton
	if list != null and list.get_popup().visible:
		await tap(KEY_DOWN)
		await tap(KEY_ENTER)
	var cap_changed: bool = settings.get_fps_cap() == GameSettings.FPS_CAPS[1]
	await remove_main(main)
	return report(volume_changed and fullscreen_changed and vsync_changed and cap_changed,
			("Each control changes Settings: Left on Master %s, Enter on full screen %s, on V-Sync "
			+ "%s, the second cap from the list %s")
			% [volume_changed, fullscreen_changed, vsync_changed, cap_changed])


## Hold To Escape's switch is the accessibility grid's last row, after its title, and shows the
## option off, as Settings holds it. With the focus on it, Enter turns the option on, the
## controller's A off again and a click of the mouse on again; each time the switch shows what
## Settings holds. Reset, with the option on, turns both off.
func _hold_to_escape_switches_with_keys_controller_and_mouse() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var switch: CheckButton = _accessibility_switch_titled(options, OptionsMenu.HOLD_TO_ESCAPE_TITLE)
	# Noted now: once the main scene is freed, the switch compares equal to null.
	var found: bool = switch != null
	var last_row: bool = false
	var steps: Array = []
	if found:
		last_row = switch.get_index() == switch.get_parent().get_child_count() - 2
		steps.append(_hold_to_escape_shown_and_held(switch))
		switch.grab_focus()
		await tap(KEY_ENTER)
		steps.append(_hold_to_escape_shown_and_held(switch))
		await tap_joypad(JOY_BUTTON_A)
		steps.append(_hold_to_escape_shown_and_held(switch))
		await _click_on(switch)
		steps.append(_hold_to_escape_shown_and_held(switch))
		await press_on(options, ^"%ResetButton", KEY_ENTER)
		steps.append(_hold_to_escape_shown_and_held(switch))
	await remove_main(main)
	var expected: Array = [[false, false], [true, true], [false, false], [true, true], [false, false]]
	return report(found and last_row and steps == expected,
			("Hold To Escape: a switch titled %s %s, in the last row %s; shown and in Settings at the "
			+ "start, after Enter, A, a click and Reset: %s (%s)") % [OptionsMenu.HOLD_TO_ESCAPE_TITLE,
			found, last_row, steps, expected])


## Without the mouse: from Constant Vibration's switch, the down arrow selects Hold To Escape's, the
## row under it, and the controller's D-pad down goes on to Controls.
func _the_down_arrow_and_the_d_pad_reach_hold_to_escape_and_go_on() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var constant: CheckButton = _accessibility_switch_titled(options,
			OptionsMenu.CONSTANT_VIBRATION_TITLE)
	var switch: CheckButton = _accessibility_switch_titled(options, OptionsMenu.HOLD_TO_ESCAPE_TITLE)
	var found: bool = constant != null and switch != null
	var reached: bool = false
	var went_on: bool = false
	if found:
		constant.grab_focus()
		await tap(KEY_DOWN)
		reached = has_focus(switch)
		await tap_joypad(JOY_BUTTON_DPAD_DOWN)
		went_on = has_focus(options.get_node_or_null(^"%ControlsButton"))
	await remove_main(main)
	return report(found and reached and went_on,
			("Without the mouse: both switches found %s; the down arrow from Constant vibration "
			+ "selects Hold to escape %s; the D-pad down from it selects Controls %s")
			% [found, reached, went_on])


func _reset_brings_back_the_defaults() -> bool:
	var main: Node = await _new_main_with_defaults()
	settings.set_volume(&"SFX", 0.2)
	settings.set_fullscreen(true)
	settings.set_fps_cap(240)
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	await press_on(options, ^"%ResetButton", KEY_ENTER)
	var in_settings: bool = (settings.get_volume(&"SFX") == GameSettings.DEFAULT_VOLUME
			and settings.is_fullscreen() == GameSettings.DEFAULT_FULLSCREEN
			and settings.get_fps_cap() == GameSettings.DEFAULT_FPS_CAP)
	var sfx: HSlider = _slider(options, &"SFX")
	var on_screen: bool = (sfx != null and is_equal_approx(sfx.value, GameSettings.DEFAULT_VOLUME)
			and _value_label(sfx) == "100 %"
			and _is_pressed(options, ^"%FullscreenCheck") == GameSettings.DEFAULT_FULLSCREEN
			and _fps_cap_shown(options) == GameSettings.DEFAULT_FPS_CAP)
	await remove_main(main)
	return report(in_settings and on_screen,
			"Reset: the defaults in Settings %s, on the screen %s" % [in_settings, on_screen])


## Back is pressed with the focus on it; Esc and B from anywhere on the screen. The counter gets Esc
## only if nothing in the main scene handled it.
func _back_esc_and_b_close_the_screen_onto_options() -> bool:
	var back_counter: BackCounter = BackCounter.new()
	root.add_child(back_counter)
	var main: Node = await _new_main_with_defaults()
	var outcomes: PackedStringArray = []
	var all_right: bool = true
	for way: String in ["Back", "Esc", "B"]:
		await _open_options_in_the_main_menu(main)
		var options: Control = _options_in_the_main_menu(main)
		match way:
			"Back":
				await press_on(options, ^"%BackButton", KEY_ENTER)
			"Esc":
				await tap(KEY_ESCAPE)
			"B":
				await tap_joypad(JOY_BUTTON_B)
		var closed: bool = (not _shows(options)
				and _shows(main_menu_node(main, ^"%MainPanel") as Control)
				and has_focus(main_menu_node(main, ^"%OptionsButton")))
		all_right = all_right and closed
		outcomes.append("%s %s" % [way, closed])
	var stopped: bool = back_counter.presses == 0
	await remove_main(main)
	back_counter.queue_free()
	return report(all_right and stopped,
			"Closed onto the Options button: %s; Esc and B stopped at the screen %s"
			% [", ".join(outcomes), stopped])


## Options is the button below Resume, and the up arrow goes back to Resume. Esc and B on the
## screen go back to the pause, which stays; then Esc on the pause resumes.
func _in_the_pause_esc_and_b_go_back_to_the_pause() -> bool:
	var main: Node = await _new_main_with_defaults()
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	var outcomes: PackedStringArray = []
	var all_right: bool = paused
	for way: String in ["Esc", "B"]:
		await tap(KEY_DOWN)
		if not has_focus(pause_node(main, ^"%OptionsButton")):
			all_right = false
			outcomes.append("%s: Options not below Resume" % way)
			break
		await tap(KEY_ENTER)
		var options: Control = _options_in_the_pause(main)
		var opened: bool = _shows(options)
		if way == "Esc":
			await tap(KEY_ESCAPE)
		else:
			await tap_joypad(JOY_BUTTON_B)
		var back: bool = (opened and paused and not _shows(options)
				and has_focus(pause_node(main, ^"%OptionsButton")))
		all_right = all_right and back
		outcomes.append("%s %s" % [way, back])
		await tap(KEY_UP)
	await tap(KEY_ESCAPE)
	var resumed: bool = not paused
	await remove_main(main)
	return report(all_right and resumed,
			("In the pause, the screen opens and goes back to the pause, still paused: %s; Esc "
			+ "resumes %s") % [", ".join(outcomes), resumed])


## Start resumes the game from the screen; the next pause opens on Resume, not on the screen.
func _a_pause_left_from_the_options_opens_on_its_own_panel() -> bool:
	var main: Node = await _new_main_with_defaults()
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	await press_on(main.get_node_or_null(^"%PauseMenu"), ^"%OptionsButton", KEY_ENTER)
	var opened: bool = _shows(_options_in_the_pause(main))
	await tap_joypad(JOY_BUTTON_START)
	var resumed: bool = opened and not paused
	await tap(KEY_ESCAPE)
	var own_panel: bool = (paused and not _shows(_options_in_the_pause(main))
			and has_focus(pause_node(main, ^"%ResumeButton")))
	await remove_main(main)
	return report(resumed and own_panel,
			"Start from the screen resumes %s; the next pause opens on Resume %s"
			% [resumed, own_panel])


func _the_options_text_takes_its_size_from_the_ui_theme() -> bool:
	var main: Node = await _new_main_with_defaults()
	var expected: int = theme_font_size()
	var texts: Array[Control] = texts_in(_options_in_the_main_menu(main))
	var other_sizes: Array[String] = off_size(texts, expected)
	await remove_main(main)
	return report(expected > 0 and texts.size() > 0 and other_sizes.is_empty(),
			"Options text size: theme %d px; %d labels and buttons, off the theme: %s"
			% [expected, texts.size(), other_sizes])


## A main scene, with Settings back to the defaults, in the test file. The screen reads Settings when
## it opens, so the reset can come after the scene is made.
func _new_main_with_defaults() -> Node:
	var main: Node = await new_main()
	if settings != null:
		settings.reset_to_defaults()
	return main


func _open_options_in_the_main_menu(main: Node) -> void:
	await press_on(main.get_node_or_null(^"%MainMenu"), ^"%OptionsButton", KEY_ENTER)


func _options_in_the_main_menu(main: Node) -> Control:
	return main_menu_node(main, ^"%OptionsMenu") as Control


func _options_in_the_pause(main: Node) -> Control:
	return pause_node(main, ^"%OptionsMenu") as Control


func _shows(control: Control) -> bool:
	return control != null and control.is_visible_in_tree()


## Whether the check button at path is on; null if there is no such button.
func _is_pressed(options: Control, path: NodePath) -> Variant:
	var check: CheckButton = options.get_node_or_null(path) as CheckButton if options else null
	return check.button_pressed if check != null else null


## The volume sliders, in the order of GameSettings.BUSES.
func _sliders(options: Control) -> Array[HSlider]:
	var sliders: Array[HSlider] = []
	var volumes: Node = options.get_node_or_null(^"%Volumes") if options != null else null
	if volumes != null:
		for child: Node in volumes.get_children():
			if child is HSlider:
				sliders.append(child as HSlider)
	return sliders


func _slider(options: Control, bus: StringName) -> HSlider:
	var sliders: Array[HSlider] = _sliders(options)
	var index: int = GameSettings.BUSES.find(bus)
	return sliders[index] if index >= 0 and index < sliders.size() else null


## The text of the label after the slider, which shows its volume.
func _value_label(slider: HSlider) -> String:
	if slider == null or slider.get_index() + 1 >= slider.get_parent().get_child_count():
		return ""
	var after: Node = slider.get_parent().get_child(slider.get_index() + 1)
	return (after as Label).text if after is Label else ""


## The switch after the label titled title in the accessibility grid; null if there is none.
func _accessibility_switch_titled(options: Control, title: String) -> CheckButton:
	var grid: Node = options.get_node_or_null(^"%Accessibility") if options != null else null
	if grid == null:
		return null
	for child: Node in grid.get_children():
		var titled: bool = child is Label and (child as Label).text == title
		if titled and child.get_index() + 1 < grid.get_child_count():
			return grid.get_child(child.get_index() + 1) as CheckButton
	return null


## Whether the switch shows the option on, and whether Settings holds it on. Untyped, as the case's
## expected steps are.
func _hold_to_escape_shown_and_held(switch: CheckButton) -> Array:
	return [switch.button_pressed, settings.is_hold_to_escape_on()]


## A click of the left mouse button in the middle of control, handed to the screen where the control
## is drawn, as a real click lands.
func _click_on(control: Control) -> void:
	var at: Vector2 = control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = mouse_event(MOUSE_BUTTON_LEFT, pressed, at)
		root.push_input(event, true)
		await process_frame


func _fps_cap_shown(options: Control) -> int:
	var list: OptionButton = null
	if options != null:
		list = options.get_node_or_null(^"%FpsCapOption") as OptionButton
	if list == null or list.selected < 0:
		return -1
	return GameSettings.FPS_CAPS[list.selected]
