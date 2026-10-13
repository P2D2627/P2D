# Checks the controls screen, through the main scene. Controls, on the options screen, swaps it for
# the controls screen with the profile list selected, and Esc swaps them back onto Controls. A fixed
# profile shows its bindings on buttons that do not press. Picking Custom from the list makes them
# press: Enter on an action's button waits, and the next key or mouse button remaps the action, on
# the screen and in Settings. A key another action had swaps over, on the screen too, and Reset
# brings the custom profile back to the default one. While waiting, a reserved key is ignored, and
# Esc or B stop waiting, change nothing and keep the screen open; in the pause, Esc also keeps the
# game paused. In a level with Arrows and QWEASD, Q raises the crucifix, the left mouse button does
# not, and Ctrl is Interact. The autoload Settings saves to a test file (see
# tests/support/menu_test.gd), so the player's file is never touched, and every case starts and
# ends on the default controls.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_controls.gd
extends "res://tests/support/menu_test.gd"

## Physics frames the level is watched for.
const WATCH_FRAMES: int = 30


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _controls_opens_its_screen_and_esc_comes_back())
	results.append(await _a_fixed_profile_shows_its_bindings_on_buttons_that_do_not_press())
	results.append(await _in_custom_a_key_or_mouse_button_remaps_an_action())
	results.append(await _a_key_another_action_had_swaps_over_on_the_screen())
	results.append(await _reset_brings_the_custom_profile_back_to_the_default())
	results.append(await _while_waiting_a_reserved_key_is_ignored_and_b_stops())
	results.append(await _esc_while_waiting_changes_nothing_and_stays())
	results.append(await _in_the_pause_esc_while_waiting_keeps_the_game_paused())
	results.append(await _with_arrows_and_qweasd_q_raises_the_crucifix_and_ctrl_interacts())
	finish(results)


func _controls_opens_its_screen_and_esc_comes_back() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var options: Node = await _open_controls_in_the_main_menu(main)
	var controls: Control = _controls(options)
	var shown: bool = controls != null and controls.is_visible_in_tree()
	var options_hidden: bool = not _general(options).is_visible_in_tree()
	var list_selected: bool = has_focus(controls.get_node_or_null(^"%ProfileOption"))
	await tap(KEY_ESCAPE)
	var back: bool = not controls.is_visible_in_tree() and _general(options).is_visible_in_tree()
	var on_controls_button: bool = has_focus(options.get_node_or_null(^"%ControlsButton"))
	await remove_main(main)
	return report(shown and options_hidden and list_selected and back and on_controls_button,
			"Controls: shown %s, options hidden %s, profile list selected %s; Esc back %s, on Controls %s"
			% [shown, options_hidden, list_selected, back, on_controls_button])


func _a_fixed_profile_shows_its_bindings_on_buttons_that_do_not_press() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	var jump: Button = _binding_button(controls, &"jump")
	var crucifix: Button = _binding_button(controls, &"crucifix")
	var texts: Array[String] = [jump.text, crucifix.text]
	var disabled: bool = jump.disabled and crucifix.disabled
	jump.grab_focus()
	await tap(KEY_ENTER)
	var waiting: bool = (controls as ControlsMenu).is_waiting_for_a_key()
	await remove_main(main)
	return report(texts == ["Space", "Left mouse button"] and disabled and not waiting,
			"A fixed profile: Jump and Crucifix show %s, buttons disabled %s, Enter made it wait %s"
			% [texts, disabled, waiting])


## Custom is picked from the list with the arrows and Enter. Jump then goes to J, by the keyboard,
## and Crucifix to the right mouse button.
func _in_custom_a_key_or_mouse_button_remaps_an_action() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var custom: bool = settings.get_input_profile() == InputProfiles.CUSTOM
	var jump: Button = _binding_button(controls, &"jump")
	var enabled: bool = not jump.disabled
	jump.grab_focus()
	await tap(KEY_ENTER)
	var waiting: bool = (controls as ControlsMenu).is_waiting_for_a_key()
	await tap(KEY_J)
	var jump_text: String = jump.text
	var crucifix: Button = _binding_button(controls, &"crucifix")
	crucifix.grab_focus()
	await tap(KEY_ENTER)
	await click(MOUSE_BUTTON_RIGHT)
	var crucifix_text: String = crucifix.text
	var bindings: Array = [settings.get_bindings(&"jump"), settings.get_bindings(&"crucifix")]
	var still_open: bool = controls.is_visible_in_tree()
	await _back_to_default_controls()
	await remove_main(main)
	var expected: Array = [PackedStringArray([InputProfiles.key(KEY_J)]),
			PackedStringArray([InputProfiles.mouse(MOUSE_BUTTON_RIGHT)])]
	return report(custom and enabled and waiting and jump_text == "J"
			and crucifix_text == "Right mouse button" and bindings == expected and still_open,
			"Custom: picked %s, buttons enabled %s, Enter waits %s; Jump shows '%s', Crucifix shows '%s', Settings %s, screen open %s"
			% [custom, enabled, waiting, jump_text, crucifix_text, bindings, still_open])


## In Custom, Jump goes to E, Interact's key: the screen then shows E on Jump and Space, Jump's old
## key, on Interact.
func _a_key_another_action_had_swaps_over_on_the_screen() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	await _remap(controls, &"jump", KEY_E)
	var texts: Array[String] = [_binding_button(controls, &"jump").text,
			_binding_button(controls, &"interact").text]
	await _back_to_default_controls()
	await remove_main(main)
	return report(texts == ["E", "Space"],
			"A swap on the screen: Jump and Interact show %s" % [texts])


## In Custom, Jump goes to J; Reset, pressed on the screen, brings Space back, on the screen and in
## Settings.
func _reset_brings_the_custom_profile_back_to_the_default() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	await _remap(controls, &"jump", KEY_J)
	var remapped: bool = _binding_button(controls, &"jump").text == "J"
	await press_on(controls, ^"%ControlsResetButton", KEY_ENTER)
	var text: String = _binding_button(controls, &"jump").text
	var in_settings: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	await _back_to_default_controls()
	await remove_main(main)
	return report(remapped and text == "Space" and in_settings,
			"Reset: Jump remapped to J first %s; after Reset it shows '%s', Space in Settings %s"
			% [remapped, text, in_settings])


## While Jump waits for a key, F3 is taken and ignored, and B stops the waiting with Jump unchanged
## and the screen open.
func _while_waiting_a_reserved_key_is_ignored_and_b_stops() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var menu: ControlsMenu = controls as ControlsMenu
	_binding_button(controls, &"jump").grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_F3)
	var waiting_after_f3: bool = menu.is_waiting_for_a_key()
	await tap_joypad(JOY_BUTTON_B)
	var waiting_after_b: bool = menu.is_waiting_for_a_key()
	var unchanged: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	var still_open: bool = controls.is_visible_in_tree()
	await _back_to_default_controls()
	await remove_main(main)
	return report(waiting_after_f3 and not waiting_after_b and unchanged and still_open,
			"While waiting: still waiting after F3 %s, after B %s; Jump unchanged %s, screen open %s"
			% [waiting_after_f3, waiting_after_b, unchanged, still_open])


func _esc_while_waiting_changes_nothing_and_stays() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var jump: Button = _binding_button(controls, &"jump")
	jump.grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	var waiting: bool = (controls as ControlsMenu).is_waiting_for_a_key()
	var unchanged: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	var text: String = jump.text
	var still_open: bool = controls.is_visible_in_tree()
	await _back_to_default_controls()
	await remove_main(main)
	return report(not waiting and unchanged and text == "Space" and still_open,
			"Esc while waiting: still waiting %s, Jump unchanged %s, shows '%s', screen open %s"
			% [waiting, unchanged, text, still_open])


func _in_the_pause_esc_while_waiting_keeps_the_game_paused() -> bool:
	var main: Node = await _new_main_with_default_controls(true)
	await tap(KEY_ESCAPE)
	var controls: Control = _controls(await _open_controls_in_the_pause(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	_binding_button(controls, &"jump").grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	var still_paused: bool = paused
	var still_open: bool = controls != null and controls.is_visible_in_tree()
	await _back_to_default_controls()
	await remove_main(main)
	return report(still_paused and still_open,
			"Esc while waiting in the pause: still paused %s, controls open %s"
			% [still_paused, still_open])


## Arrows and QWEASD picked on the controls screen in the pause; back in the game, the left mouse
## button leaves the crucifix down, Q raises it, and Ctrl is Interact.
func _with_arrows_and_qweasd_q_raises_the_crucifix_and_ctrl_interacts() -> bool:
	var main: Node = await _new_main_with_default_controls(true)
	var crucifix: Crucifix = await crucifix_on_the_floor(main)
	var found: bool = crucifix != null
	await tap(KEY_ESCAPE)
	await _pick_profile(_controls(await _open_controls_in_the_pause(main)),
			InputProfiles.ARROWS_AND_QWEASD)
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	var resumed: bool = not paused
	await press_mouse(MOUSE_BUTTON_LEFT, true)
	var up_by_mouse: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
	await press_mouse(MOUSE_BUTTON_LEFT, false)
	await press_key(KEY_Q, true)
	var up_by_q: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
	await press_key(KEY_Q, false)
	await press_key(KEY_CTRL, true)
	var interact: bool = Input.is_action_pressed(&"interact")
	await press_key(KEY_CTRL, false)
	await _back_to_default_controls()
	await remove_main(main)
	return report(found and resumed and not up_by_mouse and up_by_q and interact,
			"Arrows and QWEASD in a level: resumed %s, up by the left mouse button %s, up by Q %s, Ctrl is Interact %s"
			% [resumed, up_by_mouse, up_by_q, interact])


## A main scene on the default controls; with in_a_level, with the first level started. Settings is
## only changed once it is ready: before, it has no options to save.
func _new_main_with_default_controls(in_a_level: bool = false) -> Node:
	await main_scene()
	if settings != null and not settings.is_node_ready():
		await settings.ready
	await _back_to_default_controls()
	return await new_main_in_a_level() if in_a_level else await new_main()


func _back_to_default_controls() -> void:
	if settings != null:
		settings.set_input_profile(InputProfiles.DEFAULT_PROFILE)
		settings.reset_custom_bindings()
	await process_frame


## Opens the options from the main menu, then the controls screen, and hands back the options.
func _open_controls_in_the_main_menu(main: Node) -> Node:
	await press_on(main.get_node_or_null(^"%MainMenu"), ^"%OptionsButton", KEY_ENTER)
	var options: Node = main_menu_node(main, ^"%OptionsMenu")
	await press_on(options, ^"%ControlsButton", KEY_ENTER)
	return options


## The same from the pause, already open.
func _open_controls_in_the_pause(main: Node) -> Node:
	await press_on(main.get_node_or_null(^"%PauseMenu"), ^"%OptionsButton", KEY_ENTER)
	var options: Node = pause_node(main, ^"%OptionsMenu")
	await press_on(options, ^"%ControlsButton", KEY_ENTER)
	return options


## Picks profile from the list as the player does: Enter opens it, the arrows move from the profile
## that is on, and Enter picks. The list has the profiles in the order of InputProfiles.PROFILES.
func _pick_profile(controls: Control, profile: StringName) -> void:
	var list: OptionButton = controls.get_node_or_null(^"%ProfileOption") as OptionButton \
			if controls != null else null
	if list == null:
		return
	list.grab_focus()
	await tap(KEY_ENTER)
	var steps: int = InputProfiles.PROFILES.keys().find(profile) - list.selected
	for _step: int in absi(steps):
		await tap(KEY_DOWN if steps > 0 else KEY_UP)
	await tap(KEY_ENTER)


## Enter on the action's button, then the key, as the player remaps it.
func _remap(controls: Control, action: StringName, key: Key) -> void:
	_binding_button(controls, action).grab_focus()
	await tap(KEY_ENTER)
	await tap(key)


func _controls(options: Node) -> Control:
	return options.get_node_or_null(^"%ControlsMenu") as Control if options != null else null


func _general(options: Node) -> Control:
	return options.get_node_or_null(^"%General") as Control


func _binding_button(controls: Control, action: StringName) -> Button:
	var path: NodePath = NodePath("%%Bindings/%sButton" % String(action).to_pascal_case())
	return controls.get_node_or_null(path) as Button if controls != null else null
