# Checks the menus' sounds (MenuFeedback, MenuSoundSynth). The sounds made in code are not silent,
# never clip, last as long as each is meant to, and come out the same on every run. On the main
# menu, the arrow key moves the selection with one click; a panel opening, which moves the selection
# itself, makes none, and its option makes the choice's blow; Back out of the options screen makes
# the way back's thud; a slider the player moves clicks, while the options screen setting its
# sliders as it opens does not; a list run through fast stays clicks a gap apart; and with the menu
# hidden, in a level, nothing sounds. On the options screen, a move from tab to tab clicks; a list
# (the frame rate's, the profiles') clicks as it opens and as its selection moves, blows as an item
# is picked, and thuds as Esc closes it; a key that remaps an action blows; a reserved key and a
# gamepad button, which are refused, sound the refusal, on its own player and not the way back's, a
# push of the stick sounds it once, and Esc, which stops the wait, thuds, after a refusal too. The
# refusal's sound is its own, longer than the way back's. No menu's sound is empty. No on the
# question before a new game over a save thuds, and only thuds. The sounds made in code, when a
# scene leaves its own empty, keep the move well under the choice.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_menu_feedback.gd
extends "res://tests/support/menu_test.gd"

const Synth := preload("res://scenes/screens/menu_sound_synth.gd")
const MenuFeedbackNode := preload("res://scenes/screens/menu_feedback.gd")
const FEEDBACK_SCENE: PackedScene = preload("res://scenes/screens/menu_feedback.tscn")
## How far the test's clock moves for each key press in the fast run, in ms: about a key's repeat.
const FAST_PRESS_MS: int = 20
## How far the test's clock moves before each unhurried key press, in ms: past every gap.
const CALM_PRESS_MS: int = 500
## How far under the choice's blow the click of a move made in code must be, at least, in dB: the
## recorded files keep it 9 dB under.
const MADE_MOVE_UNDER_DB: float = 8.0

## The sounds heard since the last clear, in order.
var _heard: Array[StringName] = []
## The test's clock for the fast run, in ms.
var _now_ms: int = 0


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_the_made_sounds_are_sound_and_the_same_every_run())
	results.append(await _the_arrow_key_clicks_once())
	results.append(await _choosing_settings_blows_and_its_opening_does_not_click())
	results.append(await _back_out_of_the_options_thuds())
	results.append(await _a_slider_the_player_moves_clicks_and_the_screen_s_own_do_not())
	results.append(await _a_list_run_through_fast_stays_clicks_a_gap_apart())
	results.append(await _a_hidden_menu_makes_no_sound())
	results.append(await _a_move_from_tab_to_tab_clicks())
	results.append(await _a_list_clicks_as_it_opens_and_moves_and_answers_as_it_closes())
	results.append(await _a_key_that_remaps_blows_and_a_refused_key_or_button_sounds_the_refusal())
	results.append(await _the_refusal_plays_a_sound_of_its_own_longer_than_the_way_back())
	results.append(await _no_menu_sound_is_empty())
	results.append(await _no_to_replacing_the_save_only_thuds())
	results.append(await _the_made_sounds_keep_the_move_under_the_choice())
	finish(results)


func _the_made_sounds_are_sound_and_the_same_every_run() -> bool:
	var streams: Dictionary[String, AudioStreamWAV] = {
		"move": Synth.move(0, 4), "confirm": Synth.confirm(0), "back": Synth.back(0)}
	var lengths: Dictionary[String, float] = {"move": 0.07, "confirm": 0.6, "back": 0.22}
	var wrong: Array[String] = []
	for sound: String in streams:
		var stream: AudioStreamWAV = streams[sound]
		var peak: float = _peak(stream)
		if peak < 0.5 or peak > Synth.PEAK + 0.01:
			wrong.append("%s peak %.2f" % [sound, peak])
		if absf(stream.get_length() - lengths[sound]) > 0.002:
			wrong.append("%s %.3f s" % [sound, stream.get_length()])
	if Synth.confirm(1).data != Synth.confirm(1).data:
		wrong.append("confirm 1 differs between two makings")
	if Synth.move(0, 4).data == Synth.move(3, 4).data:
		wrong.append("two move variants are the same")
	return report(wrong.is_empty(), "Made sounds wrong: %s" % [wrong])


func _the_arrow_key_clicks_once() -> bool:
	var main: Node = await new_main()
	_listen(main)
	await tap(KEY_DOWN)
	var heard: Array[StringName] = _heard.duplicate()
	await remove_main(main)
	return report(heard == [&"move"], "Down on the main menu: %s" % [heard])


## Enter on Settings: the blow, and the options screen opens and takes the selection with no click.
func _choosing_settings_blows_and_its_opening_does_not_click() -> bool:
	var main: Node = await new_main()
	_listen(main)
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	var heard: Array[StringName] = _heard.duplicate()
	await remove_main(main)
	return report(heard == [&"confirm"], "Enter on Settings: %s" % [heard])


func _back_out_of_the_options_thuds() -> bool:
	var main: Node = await new_main()
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	_listen(main)
	await tap(KEY_ESCAPE)
	var heard: Array[StringName] = _heard.duplicate()
	var back_on_the_menu: bool = main_menu_node(main, ^"%MainPanel").is_visible_in_tree()
	await remove_main(main)
	return report(heard == [&"back"] and back_on_the_menu,
			"Esc out of the options: %s, back on the menu %s" % [heard, back_on_the_menu])


## The options screen sets its sliders as it opens, silently; on the Audio tab's page, entered with
## Enter, the left arrow on the first volume slider moves it, and that clicks.
func _a_slider_the_player_moves_clicks_and_the_screen_s_own_do_not() -> bool:
	var main: Node = await new_main()
	_listen(main)
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	var on_opening: Array[StringName] = _heard.duplicate()
	await press_on(main_menu_node(main, ^"%OptionsMenu"), ^"%AudioTab", KEY_ENTER)
	var slider: HSlider = null
	for node: Node in main_menu_node(main, ^"%OptionsMenu").find_children("*", "HSlider", true, false):
		slider = node as HSlider
		break
	var heard_slider: bool = false
	if slider != null:
		slider.grab_focus()
		await tap(KEY_LEFT)
		heard_slider = _heard.has(&"slider")
	await remove_main(main)
	return report(on_opening == [&"confirm"] and heard_slider,
			"Options opening: %s; a slider moved by the player clicks %s" % [on_opening, heard_slider])


## Down held on the options screen: the key repeats every Fast Press ms, on the test's clock, and the
## selection runs from the Audio tab down its page's volumes to Reset; no two clicks come closer than
## Move Gap.
func _a_list_run_through_fast_stays_clicks_a_gap_apart() -> bool:
	var main: Node = await new_main()
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	var feedback: MenuFeedbackNode = _feedback_of(main)
	_now_ms = 100000
	feedback.clock = func() -> int: return _now_ms
	var times: Array[int] = []
	feedback.played.connect(func(_sound: StringName) -> void: times.append(_now_ms))
	for _press: int in 12:
		_now_ms += FAST_PRESS_MS
		Input.parse_input_event(_echo(KEY_DOWN, true))
		await process_frame
		Input.parse_input_event(_echo(KEY_DOWN, false))
		await process_frame
	var closest: int = 100000
	for index: int in range(1, times.size()):
		closest = mini(closest, times[index] - times[index - 1])
	var gap: int = feedback.move_gap_ms
	await remove_main(main)
	return report(times.size() >= 2 and closest >= gap,
			"Fast run: %d clicks, the closest %d ms apart (gap %d ms)" % [times.size(), closest, gap])


func _a_hidden_menu_makes_no_sound() -> bool:
	var main: Node = await new_main_in_a_level()
	_listen(main)
	await tap(KEY_DOWN)
	await tap(KEY_UP)
	var heard: Array[StringName] = _heard.duplicate()
	await remove_main(main)
	return report(heard.is_empty(), "In a level, with the menu hidden: %s" % [heard])


## Right from the Audio tab, where the options screen opens, selects Display: a click.
func _a_move_from_tab_to_tab_clicks() -> bool:
	var main: Node = await new_main()
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	_listen_on_the_test_clock(main)
	await _tap_calmly(KEY_RIGHT)
	var heard: Array[StringName] = _heard.duplicate()
	await remove_main(main)
	return report(heard == [&"move"], "Right from the Audio tab: %s" % [heard])


## The frame rate list: Enter opens it with a switch's click, Down moves its selection with a click,
## and Enter picks the next cap with the choice's blow. The profile list: Enter, Down, then Esc,
## which closes it with the way back's thud, picks nothing and leaves the screen open.
func _a_list_clicks_as_it_opens_and_moves_and_answers_as_it_closes() -> bool:
	var main: Node = await new_main()
	settings.reset_to_defaults()
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	var options: Node = main_menu_node(main, ^"%OptionsMenu")
	await press_on(options, ^"%DisplayTab", KEY_ENTER)
	_listen_on_the_test_clock(main)
	(options.get_node(^"%FpsCapOption") as Control).grab_focus()
	for key: Key in [KEY_ENTER, KEY_DOWN, KEY_ENTER]:
		await _tap_calmly(key)
	var on_the_frame_rate: Array[StringName] = _heard.duplicate()
	var cap_picked: bool = settings.get_fps_cap() == GameSettings.FPS_CAPS[1]
	await press_on(options, ^"%ControlsTab", KEY_DOWN)
	_heard.clear()
	for key: Key in [KEY_ENTER, KEY_DOWN, KEY_ESCAPE]:
		await _tap_calmly(key)
	var on_the_profiles: Array[StringName] = _heard.duplicate()
	var nothing_picked: bool = settings.get_input_profile() == InputProfiles.DEFAULT_PROFILE
	var screen_open: bool = (options as Control).is_visible_in_tree()
	settings.reset_to_defaults()
	await remove_main(main)
	return report(on_the_frame_rate == [&"switch", &"move", &"confirm"] and cap_picked
			and on_the_profiles == [&"switch", &"move", &"back"] and nothing_picked and screen_open,
			("Frame rate list, Enter, Down, Enter: %s, the next cap picked %s; profile list, Enter, "
			+ "Down, Esc: %s, nothing picked %s, the screen open %s")
			% [on_the_frame_rate, cap_picked, on_the_profiles, nothing_picked, screen_open])


## In the custom profile, Enter on an action's button blows, as any button does; F3, reserved for the
## debug overlay, is refused with the refusal's sound, which its own player plays, not the way
## back's; K remaps the action and blows: the binding took. Enter again starts another wait: A on the
## gamepad is refused with the same sound, and so is a push of the stick, once for all the events of
## its way; Esc stops the wait with the way back's thud.
func _a_key_that_remaps_blows_and_a_refused_key_or_button_sounds_the_refusal() -> bool:
	var main: Node = await new_main()
	settings.reset_to_defaults()
	settings.set_input_profile(InputProfiles.CUSTOM)
	await press_on(main_menu_node(main, ^"%MainPanel"), ^"OptionsButton", KEY_ENTER)
	var options: Node = main_menu_node(main, ^"%OptionsMenu")
	await press_on(options, ^"%ControlsTab", KEY_DOWN)
	var action: StringName = InputProfiles.ACTIONS.keys()[0]
	var button: Control = options.find_child("%sButton" % String(action).to_pascal_case(), true,
			false) as Control
	_listen_on_the_test_clock(main)
	var feedback: MenuFeedbackNode = _feedback_of(main)
	var heard: Array[Array] = []
	var remapped: bool = false
	var on_its_own_player: bool = false
	if button != null:
		button.grab_focus()
		for key: Key in [KEY_ENTER, KEY_F3, KEY_K]:
			await _tap_calmly(key)
			heard.append(_heard.duplicate())
			if key == KEY_F3:
				on_its_own_player = (_is_playing(feedback, feedback.refuse_stream)
						and not _is_playing(feedback, feedback.back_stream))
		remapped = settings.get_bindings(action).has(InputProfiles.key(KEY_K))
		_heard.clear()
		await _tap_calmly(KEY_ENTER)
		_now_ms += CALM_PRESS_MS
		await tap_joypad(JOY_BUTTON_A)
		_now_ms += CALM_PRESS_MS
		await push_axis()
		await _tap_calmly(KEY_ESCAPE)
		heard.append(_heard.duplicate())
	settings.reset_custom_bindings()
	settings.reset_to_defaults()
	await remove_main(main)
	var expected: Array[Array] = [[&"confirm"], [&"confirm", &"refuse"],
			[&"confirm", &"refuse", &"confirm"], [&"confirm", &"refuse", &"refuse", &"back"]]
	return report(heard == expected and remapped and on_its_own_player,
			("Enter, F3, K on the first action, heard after each, then Enter, A, the stick and Esc: "
			+ "%s (%s), remapped to K %s; F3 on the refusal's own player %s")
			% [heard, expected, remapped, on_its_own_player])


## The main menu's MenuFeedback has a player for the refusal's own sound, the one its scene sets, and
## that sound lasts longer than the way back's: two thuds, never the way back's one.
func _the_refusal_plays_a_sound_of_its_own_longer_than_the_way_back() -> bool:
	var main: Node = await new_main()
	var feedback: MenuFeedbackNode = _feedback_of(main)
	var refuse: AudioStream = feedback.refuse_stream
	var own_player: bool = false
	for child: Node in feedback.get_children():
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		own_player = own_player or (player != null and refuse != null and player.stream == refuse)
	var refuse_ms: float = _shortest_length(refuse) * 1000.0
	var back_ms: float = _shortest_length(feedback.back_stream) * 1000.0
	await remove_main(main)
	return report(own_player and refuse_ms > back_ms,
			"The refusal: a player of its own %s; %.0f ms, the way back %.0f ms"
			% [own_player, refuse_ms, back_ms])


## Every menu's MenuFeedback, the main menu's and the pause's, has something to play for each sound:
## each player's stream, or each stream of its random set, lasts.
func _no_menu_sound_is_empty() -> bool:
	var main: Node = await new_main()
	var feedbacks: int = 0
	var empty: Array[String] = []
	for node: Node in main.find_children("*", "", true, false):
		if not node is MenuFeedbackNode:
			continue
		feedbacks += 1
		for child: Node in node.get_children():
			var player: AudioStreamPlayer = child as AudioStreamPlayer
			if player != null and _shortest_length(player.stream) <= 0.0:
				empty.append("%s/%d" % [node.get_parent().name, player.get_index()])
	await remove_main(main)
	return report(feedbacks == 2 and empty.is_empty(),
			"%d menus' feedback (2 expected); empty sounds: %s" % [feedbacks, empty])


## The question before a new game over slot 1's save, opened straight from the menu's code rather
## than through the slots, with No selected: Enter on No answers it with the way back's thud, and
## with nothing else.
func _no_to_replacing_the_save_only_thuds() -> bool:
	var main: Node = await new_main()
	var menu: Node = main.get_node(^"%MainMenu")
	var dialog: ConfirmationDialog = main_menu_node(main, ^"%ReplaceSaveDialog") as ConfirmationDialog
	var answered: bool = false
	_listen_on_the_test_clock(main)
	if dialog != null:
		menu.ask_to_replace_save(1)
		await process_frame
		await _tap_calmly(KEY_ENTER)
		answered = not dialog.visible
	var heard: Array[StringName] = _heard.duplicate()
	await remove_main(main)
	return report(answered and heard == [&"back"],
			"Enter on No: the question answered %s, heard %s" % [answered, heard])


## The menus' MenuFeedback scene, its players at 0 dB as its files hold their own mix, with its
## sounds left empty: it plays the ones made in code, all at one peak, and their own mix keeps the
## move's click well under the choice's blow.
func _the_made_sounds_keep_the_move_under_the_choice() -> bool:
	var menu: CanvasLayer = CanvasLayer.new()
	var feedback: MenuFeedbackNode = FEEDBACK_SCENE.instantiate() as MenuFeedbackNode
	for sound: StringName in [&"move_stream", &"confirm_stream", &"back_stream", &"tick_stream",
			&"switch_stream", &"refuse_stream"]:
		feedback.set(sound, null)
	feedback.menu = menu
	menu.add_child(feedback)
	root.add_child(menu)
	await process_frame
	var volumes: Dictionary[String, float] = {}
	for child: Node in feedback.get_children():
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		if player != null and player.stream == MenuFeedbackNode._made.get(&"move"):
			volumes["move"] = player.volume_db
		elif player != null and player.stream == MenuFeedbackNode._made.get(&"confirm"):
			volumes["confirm"] = player.volume_db
	menu.queue_free()
	await process_frame
	var under: float = volumes.get("confirm", NAN) - volumes.get("move", NAN)
	return report(under >= MADE_MOVE_UNDER_DB,
			"Made in code: the move %.1f dB under the choice (at least %.1f); volumes %s"
			% [under, MADE_MOVE_UNDER_DB, volumes])


## The main menu's MenuFeedback; its sounds go to _heard from now on.
func _listen(main: Node) -> void:
	_heard.clear()
	_feedback_of(main).played.connect(func(sound: StringName) -> void: _heard.append(sound))


func _feedback_of(main: Node) -> MenuFeedbackNode:
	return main.get_node(^"%MainMenu").get_node(^"MenuFeedback") as MenuFeedbackNode


## As _listen, with the main menu's MenuFeedback on the test's clock, which only _tap_calmly moves:
## the cases' sounds then never fall within one another's gaps, however fast the frames run.
func _listen_on_the_test_clock(main: Node) -> void:
	_listen(main)
	_now_ms = 100000
	_feedback_of(main).clock = func() -> int: return _now_ms


## Whether one of feedback's players with stream is playing; false with no stream.
func _is_playing(feedback: Node, stream: AudioStream) -> bool:
	for child: Node in feedback.get_children():
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		if player != null and stream != null and player.stream == stream and player.playing:
			return true
	return false


## A tap a while after the last, on the test's clock.
func _tap_calmly(key: Key) -> void:
	_now_ms += CALM_PRESS_MS
	await tap(key)


## The shortest of what stream can play, in s: its length, or for a random set its shortest stream's;
## 0 with no stream.
func _shortest_length(stream: AudioStream) -> float:
	var randomizer: AudioStreamRandomizer = stream as AudioStreamRandomizer
	if randomizer == null:
		return stream.get_length() if stream != null else 0.0
	var shortest: float = INF if randomizer.streams_count > 0 else 0.0
	for index: int in randomizer.streams_count:
		shortest = minf(shortest, _shortest_length(randomizer.get_stream(index)))
	return shortest


func _peak(stream: AudioStreamWAV) -> float:
	var loudest: int = 0
	for index: int in range(0, stream.data.size(), 2):
		loudest = maxi(loudest, absi(stream.data.decode_s16(index)))
	return float(loudest) / 32767.0


## A key press, or its release, as a key held down repeats it: pressed and marked as an echo.
func _echo(key: Key, pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = pressed
	return event
