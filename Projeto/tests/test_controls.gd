# Checks the controls screen, through the main scene. The options screen's Controls tab shows it,
# and down from the tab selects the profile list; Esc there closes the options onto Settings. A fixed
# profile shows its bindings on buttons that do not press. Picking Custom from the list makes them
# press: Enter on an action's button waits, and the next key or mouse button remaps the action, on
# the screen and in Settings. A key another action had swaps over, on the screen too, and Reset
# brings the custom profile back to the default one. While waiting, a reserved key remaps nothing,
# the action's button names it as a key that can't be used and the wait goes on; a second one takes
# its place on the button, and a key with no name is named "That key". On the gamepad, A starts the
# wait as Enter does; while it waits, a gamepad button but B is refused, with a text that fits the
# button, and a push of the stick changes nothing. Esc or B stop waiting, change nothing and keep
# the screen open, after a refused key too, and the next wait starts afresh; in the pause, Esc also
# keeps the game paused. In a level with Arrows and QWEASD, Q raises the crucifix, Shift (the
# default profile's key) does not, and Ctrl is Interact. The autoload Settings saves to a test file
# (see tests/support/menu_test.gd), so the player's file is never touched, and every case starts and
# ends on the default controls.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_controls.gd
extends "res://tests/support/menu_test.gd"

## Physics frames the level is watched for.
const WATCH_FRAMES: int = 30


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_controls_tab_shows_the_controls_and_esc_closes_the_options())
	results.append(await _a_fixed_profile_shows_its_bindings_on_buttons_that_do_not_press())
	results.append(await _in_custom_a_key_or_mouse_button_remaps_an_action())
	results.append(await _a_key_another_action_had_swaps_over_on_the_screen())
	results.append(await _reset_brings_the_custom_profile_back_to_the_default())
	results.append(await _while_waiting_a_reserved_key_is_refused_and_b_stops())
	results.append(await _a_refused_key_is_named_on_the_button_and_the_wait_goes_on())
	results.append(await _a_second_refused_key_takes_the_first_one_s_place())
	results.append(await _a_key_with_no_name_is_refused_as_that_key())
	results.append(await _while_waiting_a_gamepad_button_is_refused_and_the_stick_is_not())
	results.append(await _esc_while_waiting_changes_nothing_and_stays())
	results.append(await _esc_after_a_refused_key_stops_the_wait_and_the_next_starts_afresh())
	results.append(await _in_the_pause_esc_while_waiting_keeps_the_game_paused())
	results.append(await _with_arrows_and_qweasd_q_raises_the_crucifix_and_ctrl_interacts())
	finish(results)


func _the_controls_tab_shows_the_controls_and_esc_closes_the_options() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var options: Control = await _open_controls_in_the_main_menu(main) as Control
	var controls: Control = _controls(options)
	var shown: bool = controls != null and controls.is_visible_in_tree()
	var list_selected: bool = controls != null and has_focus(
			controls.get_node_or_null(^"%ProfileOption"))
	await tap(KEY_ESCAPE)
	var closed: bool = options != null and not options.is_visible_in_tree()
	var on_settings: bool = has_focus(main_menu_node(main, ^"%OptionsButton"))
	await remove_main(main)
	return report(shown and list_selected and closed and on_settings,
			"Controls: shown %s, profile list selected %s; Esc closes the options %s, onto Settings %s"
			% [shown, list_selected, closed, on_settings])


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
	return report(texts == ["Space", "Shift"] and disabled and not waiting,
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


## While Jump waits for a key, F3, reserved for the debug overlay, is refused: Jump's button says F3
## cannot be used, and the wait goes on; K then remaps Jump, and the button shows its keys again.
func _a_refused_key_is_named_on_the_button_and_the_wait_goes_on() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var menu: ControlsMenu = controls as ControlsMenu
	var button: Button = _binding_button(controls, &"jump")
	button.grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_F3)
	var names_f3: bool = button.text == ControlsMenu.REFUSED_TEXT % "F3"
	var still_waiting: bool = menu.is_waiting_for_a_key()
	await tap(KEY_K)
	var remapped: bool = settings.get_bindings(&"jump").has(InputProfiles.key(KEY_K))
	var shows_keys: bool = not menu.is_waiting_for_a_key() and button.text.contains("K")
	var text: String = button.text
	await _back_to_default_controls()
	await remove_main(main)
	return report(names_f3 and still_waiting and remapped and shows_keys,
			("F3 while Jump waits: the button names F3 as refused %s, still waiting %s; then K: "
			+ "remapped %s, the button shows its keys %s (%s)")
			% [names_f3, still_waiting, remapped, shows_keys, text])


## While Jump waits, F3 and then F4, both reserved, are refused: the button names F4, the last one,
## and the wait goes on.
func _a_second_refused_key_takes_the_first_one_s_place() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var button: Button = _binding_button(controls, &"jump")
	button.grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_F3)
	await tap(KEY_F4)
	var text: String = button.text
	var still_waiting: bool = (controls as ControlsMenu).is_waiting_for_a_key()
	var unchanged: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	await _back_to_default_controls()
	await remove_main(main)
	return report(text == ControlsMenu.REFUSED_TEXT % "F4" and still_waiting and unchanged,
			"F3, then F4, while Jump waits: the button shows '%s', still waiting %s, Jump unchanged %s"
			% [text, still_waiting, unchanged])


## While Jump waits, a key that arrives with no code, so with no name, is refused as "That key", and
## the wait goes on.
func _a_key_with_no_name_is_refused_as_that_key() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var button: Button = _binding_button(controls, &"jump")
	button.grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_NONE)
	var text: String = button.text
	var still_waiting: bool = (controls as ControlsMenu).is_waiting_for_a_key()
	var unchanged: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	await _back_to_default_controls()
	await remove_main(main)
	return report(text == ControlsMenu.REFUSED_TEXT % ControlsMenu.UNNAMED_KEY and still_waiting
			and unchanged,
			"A key with no name while Jump waits: the button shows '%s', still waiting %s, Jump unchanged %s"
			% [text, still_waiting, unchanged])


## On the gamepad, A on Jump's button starts the wait, with the waiting text: the A that started it is
## not refused. A push of the stick leaves the text as it is. A again, as any gamepad button but B,
## is refused: the button says the gamepad's buttons are fixed, with no need to grow past its width,
## and the wait goes on with Jump unchanged and the screen open.
func _while_waiting_a_gamepad_button_is_refused_and_the_stick_is_not() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var button: Button = _binding_button(controls, &"jump")
	button.grab_focus()
	await tap_joypad(JOY_BUTTON_A)
	var started: String = button.text
	await push_stick()
	var after_stick: String = button.text
	await tap_joypad(JOY_BUTTON_A)
	var refused: String = button.text
	var width: float = button.get_combined_minimum_size().x
	var still_waiting: bool = (controls as ControlsMenu).is_waiting_for_a_key()
	var unchanged: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	var still_open: bool = controls.is_visible_in_tree()
	await tap_joypad(JOY_BUTTON_B)
	await _back_to_default_controls()
	await remove_main(main)
	return report(started == ControlsMenu.WAITING_TEXT and after_stick == ControlsMenu.WAITING_TEXT
			and refused == ControlsMenu.GAMEPAD_REFUSED_TEXT
			and width <= ControlsMenu.BINDING_WIDTH and still_waiting and unchanged and still_open,
			("The gamepad while Jump waits: A starts it with '%s'; after the stick '%s'; A again "
			+ "shows '%s', %.0f px wide (at most %.0f), still waiting %s, Jump unchanged %s, screen "
			+ "open %s") % [started, after_stick, refused, width, ControlsMenu.BINDING_WIDTH,
			still_waiting, unchanged, still_open])


## While Jump waits for a key, F3 is refused, and B stops the waiting with Jump unchanged and the
## screen open.
func _while_waiting_a_reserved_key_is_refused_and_b_stops() -> bool:
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


## While Jump waits, F3 is refused, and Esc then stops the wait: Jump unchanged, its button shows
## Space and the screen stays open. Enter on the button waits again, with the waiting text, not the
## refusal.
func _esc_after_a_refused_key_stops_the_wait_and_the_next_starts_afresh() -> bool:
	var main: Node = await _new_main_with_default_controls()
	var controls: Control = _controls(await _open_controls_in_the_main_menu(main))
	await _pick_profile(controls, InputProfiles.CUSTOM)
	var menu: ControlsMenu = controls as ControlsMenu
	var jump: Button = _binding_button(controls, &"jump")
	jump.grab_focus()
	await tap(KEY_ENTER)
	await tap(KEY_F3)
	await tap(KEY_ESCAPE)
	var waiting: bool = menu.is_waiting_for_a_key()
	var unchanged: bool = settings.get_bindings(&"jump") == PackedStringArray(
			[InputProfiles.key(KEY_SPACE)])
	var text: String = jump.text
	var still_open: bool = controls.is_visible_in_tree()
	jump.grab_focus()
	await tap(KEY_ENTER)
	var next_text: String = jump.text
	await tap(KEY_ESCAPE)
	await _back_to_default_controls()
	await remove_main(main)
	return report(not waiting and unchanged and text == "Space" and still_open
			and next_text == ControlsMenu.WAITING_TEXT,
			("F3, then Esc, while Jump waits: still waiting %s, Jump unchanged %s, shows '%s', screen "
			+ "open %s; the next wait shows '%s'")
			% [waiting, unchanged, text, still_open, next_text])


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


## Arrows and QWEASD picked on the controls screen in the pause; back in the game, Shift, the default
## profile's crucifix key, leaves the crucifix down, Q raises it, and Ctrl is Interact.
func _with_arrows_and_qweasd_q_raises_the_crucifix_and_ctrl_interacts() -> bool:
	var main: Node = await _new_main_with_default_controls(true)
	var crucifix: Crucifix = await crucifix_on_the_floor(main)
	var found: bool = crucifix != null
	await tap(KEY_ESCAPE)
	await _pick_profile(_controls(await _open_controls_in_the_pause(main)),
			InputProfiles.ARROWS_AND_QWEASD)
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	var resumed: bool = not paused
	await press_key(KEY_SHIFT, true)
	var up_by_shift: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
	await press_key(KEY_SHIFT, false)
	await press_key(KEY_Q, true)
	var up_by_q: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
	await press_key(KEY_Q, false)
	await press_key(KEY_CTRL, true)
	var interact: bool = Input.is_action_pressed(&"interact")
	await press_key(KEY_CTRL, false)
	await _back_to_default_controls()
	await remove_main(main)
	return report(found and resumed and not up_by_shift and up_by_q and interact,
			"Arrows and QWEASD in a level: resumed %s, up by Shift %s, up by Q %s, Ctrl is Interact %s"
			% [resumed, up_by_shift, up_by_q, interact])


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


## Opens the options from the main menu, then, as the player does, the Controls tab and down into
## it, and hands back the options.
func _open_controls_in_the_main_menu(main: Node) -> Node:
	await press_on(main.get_node_or_null(^"%MainMenu"), ^"%OptionsButton", KEY_ENTER)
	var options: Node = main_menu_node(main, ^"%OptionsMenu")
	await press_on(options, ^"%ControlsTab", KEY_DOWN)
	return options


## The same from the pause, already open.
func _open_controls_in_the_pause(main: Node) -> Node:
	await press_on(main.get_node_or_null(^"%PauseMenu"), ^"%OptionsButton", KEY_ENTER)
	var options: Node = pause_node(main, ^"%OptionsMenu")
	await press_on(options, ^"%ControlsTab", KEY_DOWN)
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


func _binding_button(controls: Control, action: StringName) -> Button:
	var path: NodePath = NodePath("%%Bindings/%sButton" % String(action).to_pascal_case())
	return controls.get_node_or_null(path) as Button if controls != null else null
