# Checks the options screen, through the main scene. With no save, the main menu shows Settings
# (OptionsButton) between New Game (PlayButton) and Quit, and it opens the screen on the Audio tab,
# selected, with Audio's page, and Enter goes onto the first volume, writing nothing. Left and right
# on the tabs go round them, the D-pad too, each showing its page and only it, with the screen
# standing still; down goes into the page and up from its first row back to the tab. A band marks
# the selection, a tab, a row or a button, appearing in place, and the menu's crosses stay away;
# the mouse over a tab leaves the page alone, and a click selects the tab. The line under the
# pages says what the selected option does. The screen shows what Settings holds. Each control
# changes Settings: the arrows move a volume, Enter turns full screen and V-Sync on and off, and the
# frame rate list picks a cap. Hold To Escape is the accessibility grid's row before the last and
# Show Hidden its last; the down arrow and the D-pad reach each and go on to Reset, and Enter, the
# controller's A and the mouse each switch them. Reset brings back the defaults, on the screen and
# in Settings. Back, and Esc and B from a tab or a page, close the screen onto the Options button,
# and that Esc goes no further. In the pause, the same screen opens; Esc and B go back to the pause,
# still paused, and Esc there resumes. A pause left from the options opens again on its own panel.
# Esc with a list open closes only the list, and the next Esc the screen. The tabs keep their places
# as the selected one changes. Each description fits its lines, and two lines of it leave the screen
# where one does.
# All the text takes its size from the UI theme (its own, or a variation the theme sizes), with none
# set on a node. The autoload Settings saves to a test file (see
# tests/support/menu_test.gd), so the player's file is never touched.
# The cases give a button the focus straight away, unless the arrows are what they check: from the
# Options button, the down arrow and Enter would press Quit.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_options.gd
extends "res://tests/support/menu_test.gd"

## Each tab, by its name, and its page, in the tabs' order.
const PAGES: Dictionary[String, NodePath] = {
	"Audio": ^"%AudioPage",
	"Display": ^"%DisplayPage",
	"Controls": ^"%ControlsMenu",
	"Accessibility": ^"%AccessibilityPage",
}
## How long the band gets to stop gliding: 0.75 s, about 13 of its time constants at the default
## sharpness.
const SETTLE_FRAMES: int = 45


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_main_menu_has_options_between_play_and_quit())
	results.append(await _options_opens_on_the_audio_tab_and_enter_goes_to_the_first_volume())
	results.append(await _the_tabs_go_round_each_showing_its_page_with_the_screen_still())
	results.append(await _a_band_marks_the_selection_and_the_crosses_stay_away())
	results.append(await _the_mouse_over_a_tab_leaves_the_page_alone_and_a_click_selects_it())
	results.append(await _the_line_says_what_the_selected_option_does())
	results.append(await _the_screen_shows_what_settings_holds())
	results.append(await _each_control_changes_settings())
	results.append(await _hold_to_escape_switches_with_keys_controller_and_mouse())
	results.append(await _the_down_arrow_and_the_d_pad_reach_hold_to_escape_and_go_on())
	results.append(await _show_hidden_switches_with_keys_controller_and_mouse())
	results.append(await _the_down_arrow_and_the_d_pad_reach_show_hidden_and_go_on())
	results.append(await _reset_brings_back_the_defaults())
	results.append(await _back_esc_and_b_close_the_screen_onto_options())
	results.append(await _in_the_pause_esc_and_b_go_back_to_the_pause())
	results.append(await _a_pause_left_from_the_options_opens_on_its_own_panel())
	results.append(await _the_options_text_takes_its_size_from_the_ui_theme())
	results.append(await _esc_with_a_list_open_closes_the_list_and_then_the_screen())
	results.append(await _the_tabs_keep_their_places_as_the_selection_moves())
	results.append(await _each_description_fits_and_two_lines_leave_the_screen_still())
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
## any other button it could be Quit. The screen opens on the Audio tab, selected, with Audio's page,
## and Enter there goes onto its first volume. Opening the screen changes nothing, so it writes no
## file: the file is deleted first, and must still be missing.
func _options_opens_on_the_audio_tab_and_enter_goes_to_the_first_volume() -> bool:
	var main: Node = await _new_main_with_defaults()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_TEST_PATH))
	await tap(KEY_DOWN)
	if has_focus(main_menu_node(main, ^"%OptionsButton")):
		await tap(KEY_ENTER)
	var options: Control = _options_in_the_main_menu(main)
	var shown: bool = _shows(options)
	var panel_hidden: bool = not _shows(main_menu_node(main, ^"%MainPanel") as Control)
	var on_audio: bool = options != null and _tab_and_page_shown(options) == "Audio"
	if on_audio:
		await tap(KEY_ENTER)
	var sliders: Array[HSlider] = _sliders(options)
	var first_selected: bool = not sliders.is_empty() and has_focus(sliders[0])
	var nothing_written: bool = not FileAccess.file_exists(SETTINGS_TEST_PATH)
	await remove_main(main)
	return report(shown and panel_hidden and on_audio and sliders.size() == GameSettings.BUSES.size()
			and first_selected and nothing_written,
			("Options: the screen shown %s, the main panel hidden %s, Audio selected %s; Enter: %d "
			+ "volume sliders, the first selected %s; no file written %s")
			% [shown, panel_hidden, on_audio, sliders.size(), first_selected, nothing_written])


## From the Audio tab: right three times and once more goes round to Audio, left from it to
## Accessibility, and the D-pad's right on to Audio again. Each step shows the focused tab's page and
## only it, with that tab alone in the selected look, and the line under the pages stays where it
## was. Down goes into a page, onto its first row, and up from there comes back to the tab: on Audio,
## and on Controls, whose page is the controls screen.
func _the_tabs_go_round_each_showing_its_page_with_the_screen_still() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var line: Control = options.get_node_or_null(^"%Description") as Control if options else null
	var line_y: float = line.global_position.y if line != null else NAN
	var still: bool = line != null
	var steps: Array[String] = []
	var expected: Array[String] = []
	for move: Array in [["right", "Display"], ["right", "Controls"],
			["right", "Accessibility"], ["right", "Audio"], ["left", "Accessibility"],
			["D-pad right", "Audio"]]:
		match move[0]:
			"right":
				await tap(KEY_RIGHT)
			"left":
				await tap(KEY_LEFT)
			"D-pad right":
				await tap_joypad(JOY_BUTTON_DPAD_RIGHT)
		steps.append(_tab_and_page_shown(options))
		expected.append(move[1])
		still = still and is_equal_approx(line.global_position.y, line_y)
	var in_and_out: Array[bool] = []
	if options != null:
		for tab: String in ["Audio", "Controls"]:
			await press_on(options, NodePath("%" + tab + "Tab"), KEY_DOWN)
			in_and_out.append(has_focus(_first_row_control(options, tab)))
			await tap(KEY_UP)
			in_and_out.append(has_focus(options.get_node_or_null(NodePath("%" + tab + "Tab"))))
	await remove_main(main)
	return report(steps == expected and still and in_and_out == [true, true, true, true],
			("The tabs go round: %s (%s); the line stays put %s; down into Audio and Controls and up "
			+ "back to the tab %s") % [steps, expected, still, in_and_out])


## The band appears in place, on the Audio tab, as the screen opens, with no glide from elsewhere.
## Once it stops gliding, it covers the selection and no more: the Audio tab, not the next tab; the
## first volume's whole row, its title and value too, after Down, not the next row; Reset after
## going down past the last volume; and Back, right of it. The menu's crosses, which show on the
## main menu, never show on the screen, not even on Reset or Back.
func _a_band_marks_the_selection_and_the_crosses_stay_away() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _settle()
	var crosses_on_the_menu: bool = _crosses_show(main)
	await _open_options_in_the_main_menu(main)
	var band: OptionsMenu = _options_in_the_main_menu(main) as OptionsMenu
	var options: Control = band
	var volumes: Node = options.get_node_or_null(^"%Volumes") if options else null
	var covers: Array[bool] = []
	var crosses_on_the_screen: bool = false
	if band != null and volumes != null:
		covers.append(_band_covers(band, [options.get_node(^"%AudioTab")]))
		await _settle()
		covers.append(_band_covers(band, [options.get_node(^"%AudioTab")])
				and not _band_covers(band, [options.get_node(^"%DisplayTab")]))
		await tap(KEY_DOWN)
		await _settle()
		covers.append(_band_covers(band, [volumes.get_child(0), volumes.get_child(1),
				volumes.get_child(2)]) and not _band_covers(band, [volumes.get_child(4)]))
		for _row: int in GameSettings.BUSES.size():
			await tap(KEY_DOWN)
		await _settle()
		covers.append(has_focus(options.get_node(^"%ResetButton"))
				and _band_covers(band, [options.get_node(^"%ResetButton")]))
		crosses_on_the_screen = _crosses_show(main)
		await tap(KEY_RIGHT)
		await _settle()
		covers.append(has_focus(options.get_node(^"%BackButton"))
				and _band_covers(band, [options.get_node(^"%BackButton")]))
		crosses_on_the_screen = crosses_on_the_screen or _crosses_show(main)
	await remove_main(main)
	return report(crosses_on_the_menu and covers == [true, true, true, true, true]
			and not crosses_on_the_screen,
			("The band on the Audio tab at once, then settled on it, the first volume's row, Reset "
			+ "and Back: %s; the crosses on the main menu %s, on the screen %s")
			% [covers, crosses_on_the_menu, crosses_on_the_screen])


## The mouse over a tab leaves the page and the selection alone: the pointer crosses the tabs on its
## way to a page. Over Back it selects Back, so the mouse's moves do reach the screen; a click on a
## tab then shows its page.
func _the_mouse_over_a_tab_leaves_the_page_alone_and_a_click_selects_it() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var steps: Array[String] = []
	if options != null:
		await _point_at(options.get_node(^"%DisplayTab") as Control)
		steps.append(_tab_and_page_shown(options))
		await _point_at(options.get_node(^"%BackButton") as Control)
		steps.append("Back" if has_focus(options.get_node(^"%BackButton")) else "(not Back)")
		await _click_on(options.get_node(^"%AccessibilityTab") as Control)
		var page: Control = options.get_node(^"%AccessibilityPage") as Control
		steps.append("Accessibility" if page.is_visible_in_tree() else "(not Accessibility)")
	await remove_main(main)
	var expected: Array[String] = ["Audio", "Back", "Accessibility"]
	return report(steps == expected,
			"Pointed at Display, at Back, then a click on Accessibility: %s (%s)" % [steps, expected])


## The line under the pages says what the selected option does, changes with the selection, and
## says nothing on a tab.
func _the_line_says_what_the_selected_option_does() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var said: Array[String] = []
	if options != null:
		said.append(_description(options))
		await press_on(options, ^"%DisplayTab", KEY_ENTER)
		said.append(_description(options))
		await tap(KEY_DOWN)
		said.append(_description(options))
		await press_on(options, ^"%AccessibilityTab", KEY_ENTER)
		said.append(_description(options))
	await remove_main(main)
	var expected: Array[String] = ["", OptionsMenu.FULLSCREEN_DESCRIPTION,
			OptionsMenu.VSYNC_DESCRIPTION, OptionsMenu.SCREEN_SHAKE_DESCRIPTION]
	return report(said == expected,
			"Descriptions on the Audio tab, on Display, after Down, on Accessibility: %s (%s)"
			% [said, expected])


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


## Each control gets the focus, as the arrows would give it, and then the keys a player presses, on
## its tab's page. The frame rate list opens on Enter, and the down arrow and Enter pick the next
## cap.
func _each_control_changes_settings() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var master: HSlider = _slider(options, &"Master")
	await press_on(options, ^"%AudioTab", KEY_ENTER)
	await tap(KEY_LEFT)
	var volume_changed: bool = (is_equal_approx(settings.get_volume(&"Master"), 0.95)
			and _value_label(master) == "95 %")
	await press_on(options, ^"%DisplayTab", KEY_ENTER)
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


## Hold To Escape's switch is in the accessibility grid's row before the last, after its title, and
## shows the option off, as Settings holds it. With the focus on it, Enter turns the option on, the
## controller's A off again and a click of the mouse on again; each time the switch shows what
## Settings holds. Reset, under the page, with the option on, turns both off.
func _hold_to_escape_switches_with_keys_controller_and_mouse() -> bool:
	var main: Node = await _new_main_with_defaults()
	var options: Control = await _open_accessibility_in_the_main_menu(main)
	var switch: CheckButton = _accessibility_switch_titled(options, OptionsMenu.HOLD_TO_ESCAPE_TITLE)
	# Noted now: once the main scene is freed, the switch compares equal to null.
	var found: bool = switch != null
	var row_before_last: bool = false
	var steps: Array = []
	if found:
		# Three cells a row: the last row's switch is second from the end, this one three before.
		row_before_last = switch.get_index() == switch.get_parent().get_child_count() - 5
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
	return report(found and row_before_last and steps == expected,
			("Hold To Escape: a switch titled %s %s, in the row before the last %s; shown and in "
			+ "Settings at the start, after Enter, A, a click and Reset: %s (%s)")
			% [OptionsMenu.HOLD_TO_ESCAPE_TITLE, found, row_before_last, steps, expected])


## Without the mouse: from Constant Vibration's switch, the down arrow selects Hold To Escape's, the
## row under it, and the controller's D-pad down goes on to Show Hidden's, the row under that.
func _the_down_arrow_and_the_d_pad_reach_hold_to_escape_and_go_on() -> bool:
	var main: Node = await _new_main_with_defaults()
	var options: Control = await _open_accessibility_in_the_main_menu(main)
	var constant: CheckButton = _accessibility_switch_titled(options,
			OptionsMenu.CONSTANT_VIBRATION_TITLE)
	var switch: CheckButton = _accessibility_switch_titled(options, OptionsMenu.HOLD_TO_ESCAPE_TITLE)
	var next: CheckButton = _accessibility_switch_titled(options, OptionsMenu.SHOW_HIDDEN_TITLE)
	var found: bool = constant != null and switch != null and next != null
	var reached: bool = false
	var went_on: bool = false
	if found:
		constant.grab_focus()
		await tap(KEY_DOWN)
		reached = has_focus(switch)
		await tap_joypad(JOY_BUTTON_DPAD_DOWN)
		went_on = has_focus(next)
	await remove_main(main)
	return report(found and reached and went_on,
			("Without the mouse: the three switches found %s; the down arrow from Constant vibration "
			+ "selects Hold to escape %s; the D-pad down from it selects Show hidden dangers %s")
			% [found, reached, went_on])


## Show Hidden's switch is the accessibility grid's last row, after its title, and shows the option
## off, as Settings holds it. With the focus on it, Enter turns the option on, the controller's A
## off again and a click of the mouse on again; each time the switch shows what Settings holds.
## Reset, under the page, with the option on, turns both off.
func _show_hidden_switches_with_keys_controller_and_mouse() -> bool:
	var main: Node = await _new_main_with_defaults()
	var options: Control = await _open_accessibility_in_the_main_menu(main)
	var switch: CheckButton = _accessibility_switch_titled(options, OptionsMenu.SHOW_HIDDEN_TITLE)
	# Noted now: once the main scene is freed, the switch compares equal to null.
	var found: bool = switch != null
	var last_row: bool = false
	var steps: Array = []
	if found:
		last_row = switch.get_index() == switch.get_parent().get_child_count() - 2
		steps.append(_show_hidden_shown_and_held(switch))
		switch.grab_focus()
		await tap(KEY_ENTER)
		steps.append(_show_hidden_shown_and_held(switch))
		await tap_joypad(JOY_BUTTON_A)
		steps.append(_show_hidden_shown_and_held(switch))
		await _click_on(switch)
		steps.append(_show_hidden_shown_and_held(switch))
		await press_on(options, ^"%ResetButton", KEY_ENTER)
		steps.append(_show_hidden_shown_and_held(switch))
	await remove_main(main)
	var expected: Array = [[false, false], [true, true], [false, false], [true, true], [false, false]]
	return report(found and last_row and steps == expected,
			("Show Hidden: a switch titled %s %s, in the last row %s; shown and in Settings at the "
			+ "start, after Enter, A, a click and Reset: %s (%s)") % [OptionsMenu.SHOW_HIDDEN_TITLE,
			found, last_row, steps, expected])


## Without the mouse: from Hold To Escape's switch, the down arrow selects Show Hidden's, the row
## under it, and the controller's D-pad down goes on to Reset, under the page.
func _the_down_arrow_and_the_d_pad_reach_show_hidden_and_go_on() -> bool:
	var main: Node = await _new_main_with_defaults()
	var options: Control = await _open_accessibility_in_the_main_menu(main)
	var hold: CheckButton = _accessibility_switch_titled(options, OptionsMenu.HOLD_TO_ESCAPE_TITLE)
	var switch: CheckButton = _accessibility_switch_titled(options, OptionsMenu.SHOW_HIDDEN_TITLE)
	var found: bool = hold != null and switch != null
	var reached: bool = false
	var went_on: bool = false
	if found:
		hold.grab_focus()
		await tap(KEY_DOWN)
		reached = has_focus(switch)
		await tap_joypad(JOY_BUTTON_DPAD_DOWN)
		went_on = has_focus(options.get_node_or_null(^"%ResetButton"))
	await remove_main(main)
	return report(found and reached and went_on,
			("Without the mouse: both switches found %s; the down arrow from Hold to escape selects "
			+ "Show hidden dangers %s; the D-pad down from it selects Reset %s")
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


## Back is pressed with the focus on it; Esc and B on the tab the screen opens on, and on a page,
## on Display's first row. The counter gets Esc only if nothing in the main scene handled it.
func _back_esc_and_b_close_the_screen_onto_options() -> bool:
	var back_counter: BackCounter = BackCounter.new()
	root.add_child(back_counter)
	var main: Node = await _new_main_with_defaults()
	var outcomes: PackedStringArray = []
	var all_right: bool = true
	for way: String in ["Back", "Esc", "B", "Esc on a page", "B on a page"]:
		await _open_options_in_the_main_menu(main)
		var options: Control = _options_in_the_main_menu(main)
		if way.ends_with("on a page"):
			await press_on(options, ^"%DisplayTab", KEY_ENTER)
		match way:
			"Back":
				await press_on(options, ^"%BackButton", KEY_ENTER)
			"Esc", "Esc on a page":
				await tap(KEY_ESCAPE)
			"B", "B on a page":
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


## On Display's page, Enter on the frame rate list opens it; Esc closes the list, with the screen
## still open and the list still selected; the next Esc closes the screen.
func _esc_with_a_list_open_closes_the_list_and_then_the_screen() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var steps: Array[String] = []
	var list: OptionButton = options.get_node_or_null(^"%FpsCapOption") as OptionButton \
			if options != null else null
	if list != null:
		await press_on(options, ^"%DisplayTab", KEY_ENTER)
		await press_on(options, ^"%FpsCapOption", KEY_ENTER)
		steps.append("list open" if list.get_popup().visible else "(list shut)")
		await tap(KEY_ESCAPE)
		steps.append("list shut" if not list.get_popup().visible else "(list open)")
		steps.append("screen open, list selected" if _shows(options) and has_focus(list)
				else "(screen open %s, list selected %s)" % [_shows(options), has_focus(list)])
		await tap(KEY_ESCAPE)
		steps.append("screen shut" if not _shows(options) else "(screen open)")
	await remove_main(main)
	var expected: Array[String] = ["list open", "list shut", "screen open, list selected",
			"screen shut"]
	return report(steps == expected, "Esc with the frame rate list open: %s (%s)" % [steps, expected])


## Each tab's place and size, as each tab in turn is selected with the arrows, stay what they were
## with Audio selected: the selected look changes the colour and adds a line under it, never the
## width.
func _the_tabs_keep_their_places_as_the_selection_moves() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var tabs: Node = options.get_node_or_null(^"%Tabs") if options != null else null
	var found: bool = tabs != null
	var moved: Array[String] = []
	if found:
		var first: Array[Rect2] = _tab_rects(tabs)
		for _tab: int in tabs.get_child_count():
			await tap(KEY_RIGHT)
			if _tab_rects(tabs) != first:
				moved.append("%s selected: %s, was %s" % [root.gui_get_focus_owner().name,
						_tab_rects(tabs), first])
	await remove_main(main)
	return report(found and moved.is_empty(), "The tabs moved as the selection did: %s" % [moved])


## Each description, on the line under the pages, takes no more lines than the screen keeps room for;
## and a description that wraps onto all those lines leaves Reset where it is with none.
func _each_description_fits_and_two_lines_leave_the_screen_still() -> bool:
	var main: Node = await _new_main_with_defaults()
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	var line: Label = options.get_node_or_null(^"%Description") as Label if options != null else null
	var reset: Control = options.get_node_or_null(^"%ResetButton") as Control if options != null else null
	var too_long: Array[String] = []
	var reset_moved: float = NAN
	if line != null and reset != null:
		var descriptions: Array[String] = [OptionsMenu.FULLSCREEN_DESCRIPTION,
				OptionsMenu.VSYNC_DESCRIPTION, OptionsMenu.FPS_CAP_DESCRIPTION,
				OptionsMenu.SCREEN_SHAKE_DESCRIPTION, OptionsMenu.VIBRATION_DESCRIPTION,
				OptionsMenu.CONSTANT_VIBRATION_DESCRIPTION, OptionsMenu.HOLD_TO_ESCAPE_DESCRIPTION,
				OptionsMenu.SHOW_HIDDEN_DESCRIPTION]
		descriptions.append_array(OptionsMenu.BUS_DESCRIPTIONS.values())
		for description: String in descriptions:
			line.text = description
			if line.get_line_count() > OptionsMenu.DESCRIPTION_LINES:
				too_long.append("%s (%d lines)" % [description, line.get_line_count()])
		line.text = ""
		await process_frame
		var reset_y: float = reset.global_position.y
		line.text = _wrapped_text(line, OptionsMenu.DESCRIPTION_LINES)
		await process_frame
		reset_moved = reset.global_position.y - reset_y
		if line.get_line_count() != OptionsMenu.DESCRIPTION_LINES:
			too_long.append("(the test's text took %d lines)" % line.get_line_count())
	await remove_main(main)
	return report(too_long.is_empty() and is_zero_approx(reset_moved),
			"Descriptions longer than the room: %s; Reset moved %.1f px with two lines"
			% [too_long, reset_moved])


## One paragraph that wraps onto lines lines of label, at its width, as a long description does: words
## are added until one more would start another line. At most MAX_WORDS words.
func _wrapped_text(label: Label, lines: int) -> String:
	const MAX_WORDS: int = 1000
	var text: String = "word"
	for _word: int in MAX_WORDS:
		label.text = text + " word"
		if label.get_line_count() > lines:
			break
		text = label.text
	return text


## Each tab's global rect, in the tabs' order.
func _tab_rects(tabs: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for tab: Node in tabs.get_children():
		rects.append((tab as Control).get_global_rect())
	return rects


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


## Opens the options from the main menu and, as the player does, goes into Accessibility's page with
## Enter on its tab; hands back the options screen.
func _open_accessibility_in_the_main_menu(main: Node) -> Control:
	await _open_options_in_the_main_menu(main)
	var options: Control = _options_in_the_main_menu(main)
	await press_on(options, ^"%AccessibilityTab", KEY_ENTER)
	return options


## The text on the line under the pages.
func _description(options: Node) -> String:
	var line: Label = options.get_node_or_null(^"%Description") as Label
	return line.text if line != null else "(no description line)"


## The name of the focused tab, as "Display", if its page shows and no other does, and it alone has
## the selected look; otherwise what is off.
func _tab_and_page_shown(options: Node) -> String:
	var focused: Control = root.gui_get_focus_owner()
	var focused_tab: String = "(none)"
	var shown: Array[String] = []
	var selected: Array[String] = []
	for tab_name: String in PAGES:
		var tab: Button = options.get_node_or_null(NodePath("%" + tab_name + "Tab")) as Button
		var page: Control = options.get_node_or_null(PAGES[tab_name]) as Control
		if tab == null or page == null:
			return "(no %s tab or page)" % tab_name
		if tab == focused:
			focused_tab = tab_name
		if page.is_visible_in_tree():
			shown.append(tab_name)
		if tab.theme_type_variation == OptionsMenu.SELECTED_TAB:
			selected.append(tab_name)
	if shown == [focused_tab] and selected == [focused_tab]:
		return focused_tab
	return "(focus on %s, pages shown %s, tabs selected %s)" % [focused_tab, shown, selected]


## The first control of the page of the tab named tab_name, where Down from the tab goes.
func _first_row_control(options: Node, tab_name: String) -> Control:
	if tab_name == "Controls":
		return options.get_node_or_null(^"%ControlsMenu/%ProfileOption") as Control
	return _slider(options, GameSettings.BUSES[0])


## Waits for the band to stop gliding: SETTLE_FRAMES frames, many times its time constant.
func _settle() -> void:
	for _frame: int in SETTLE_FRAMES:
		await process_frame


## Whether the band of options shows and covers the middle of each of controls.
func _band_covers(options: OptionsMenu, controls: Array) -> bool:
	var area: Rect2 = options.highlight_rect()
	if not area.has_area():
		return false
	for control: Control in controls:
		if control == null or not area.has_point(control.get_global_rect().get_center()):
			return false
	return true


## Whether the main menu's crosses show, either of them.
func _crosses_show(main: Node) -> bool:
	var crosses: Node = main_menu_node(main, ^"Crosses")
	if crosses == null:
		return false
	for cross: Node in crosses.get_children():
		if cross is CanvasItem and (cross as CanvasItem).visible:
			return true
	return false


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


## Whether the switch shows Show Hidden on, and whether Settings holds it on, as above.
func _show_hidden_shown_and_held(switch: CheckButton) -> Array:
	return [switch.button_pressed, settings.is_show_hidden_on()]


## The mouse moves onto the middle of control, with no button down.
func _point_at(control: Control) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = control.get_global_rect().get_center()
	motion.global_position = motion.position
	root.push_input(motion, true)
	await process_frame
	await process_frame


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
