# Checks the main scene's menu. It opens with the game's name and Play selected, and nothing in the
# level slot. With two levels or more, Play opens the level list: a button for each of Main's
# levels, in order, with the first one selected; with only one, Play starts it at once, with no
# list; with no levels, the list shows only Back, selected. Back and Esc go back to Play, selected,
# and that Esc goes no further. On the gamepad, A opens the list and B goes back.
# Each level's button starts that level's scene and hides the menu. A level left empty, or with no
# scene, is left out of the list, and the others still work. A level with In Menu off gets no
# button but stays in Main's list, and the main scene keeps the development rooms (test room, old
# blockout, gym) that way, with level 1 in the menu. Inside the level, Esc goes past
# the hidden menu and pauses, and Space then presses Resume: the menu stays hidden, with nothing of
# it selected, and one level in the slot. All the menu's text takes its size from the UI theme (its
# own, or a variation the theme sizes, as the biggest first option's), with
# no size set on a single node.
# Quit fades the screen to black, in a time of its own that outlasts the choice's blow, and only
# then ends the game, once, however often it is pressed meanwhile, with the menu left without the
# focus; the end is the test's own, as the real one would end this test with exit code 0
# (menu_test.gd fails a test that ends so). A click on Options during the fade opens nothing, where
# the same click without Quit opens the options.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_main_flow.gd
extends "res://tests/support/menu_test.gd"

## Quit's fade in the case that tells it from the phases', in s: twice the default.
const SLOW_QUIT_FADE: float = 0.5
## When that case looks at the game during the fade, in s: past the default, short of the slow one.
const EARLY_LOOK: float = 0.3


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_menu_opens_with_the_game_s_name_and_play_selected())
	results.append(await _play_opens_the_level_list_with_the_first_level_selected())
	results.append(await _with_one_level_play_starts_it_at_once())
	results.append(await _with_no_levels_play_opens_a_list_with_only_back_selected())
	results.append(await _back_and_esc_go_back_to_play())
	results.append(await _with_the_gamepad_a_opens_the_list_and_b_goes_back())
	results.append(await _each_level_s_button_starts_its_scene_and_hides_the_menu())
	results.append(await _broken_levels_are_left_out_and_the_rest_work())
	results.append(await _a_level_out_of_the_menu_gets_no_button())
	results.append(await _the_development_rooms_stay_in_the_list_out_of_the_menu())
	results.append(await _esc_and_space_in_the_level_reach_no_menu_button())
	results.append(await _the_menu_text_takes_its_size_from_the_ui_theme())
	results.append(await _quit_fades_to_black_and_only_then_ends_the_game())
	results.append(await _a_click_during_quit_s_fade_opens_nothing())
	finish(results)


## Quit, asked twice, as Main hears it from the menu: at first the game goes on and the screen starts
## to go black, with nothing of the menu selected; once the fade is done, the screen is black and the
## game ends, once. The fade takes Quit's own time, whatever the phases' Fade Time: with Quit Fade
## Time at Slow Quit Fade and Fade Time at 2 s, the game still goes on at Early Look and has ended
## once Slow Quit Fade is over. Quit Fade Time, and the least the Inspector lets it be, outlast the
## choice's longest blow, which Quit plays, so the window never closes on it.
func _quit_fades_to_black_and_only_then_ends_the_game() -> bool:
	var main: Node = await new_main()
	var ends: Array[int] = []
	main.quit_game = func() -> void: ends.append(1)
	var blow: float = _longest_choice_blow(main)
	var quit_fade: float = main.quit_fade_time
	var least: float = _least_quit_fade_time(main)
	var outlasts: bool = blow > 0.0 and quit_fade >= blow and least >= blow
	main.fade_time = 2.0
	main.quit_fade_time = SLOW_QUIT_FADE
	var fade: ColorRect = main.get_node(^"%Fade") as ColorRect
	main._on_quit_requested()
	main._on_quit_requested()
	await process_frame
	var ended_at_once: bool = not ends.is_empty()
	var fading: bool = fade.color.a > 0.0 and fade.color.a < 1.0
	var nothing_selected: bool = root.gui_get_focus_owner() == null
	await wait_frames(ceili(EARLY_LOOK * Engine.physics_ticks_per_second))
	var ended_early: bool = not ends.is_empty()
	await wait_frames(ceili((SLOW_QUIT_FADE - EARLY_LOOK) * Engine.physics_ticks_per_second) + 10)
	var black: bool = is_equal_approx(fade.color.a, 1.0)
	var ended: int = ends.size()
	await remove_main(main)
	return report(not ended_at_once and fading and nothing_selected and not ended_early and black
			and ended == 1 and outlasts,
			("Quit twice: ended at once %s, fading %s, nothing selected %s, ended at %.1f s %s; after "
			+ "the fade, black %s, ended %d times; Quit Fade Time %.2f s and its least %.2f s against "
			+ "the longest blow %.3f s") % [ended_at_once, fading, nothing_selected, EARLY_LOOK,
			ended_early, black, ended, quit_fade, least, blow])


## The longest of the main menu's choice sounds, the blow Quit plays, in s; 0 with none.
func _longest_choice_blow(main: Node) -> float:
	var feedback: Node = main_menu_node(main, ^"MenuFeedback")
	var stream: AudioStream = feedback.get(&"confirm_stream") as AudioStream if feedback else null
	var randomizer: AudioStreamRandomizer = stream as AudioStreamRandomizer
	if randomizer == null:
		return stream.get_length() if stream != null else 0.0
	var longest: float = 0.0
	for index: int in randomizer.streams_count:
		longest = maxf(longest, randomizer.get_stream(index).get_length())
	return longest


## The least Quit Fade Time the Inspector takes: the first number of its range; 0 with no range.
func _least_quit_fade_time(main: Node) -> float:
	for property: Dictionary in main.get_property_list():
		if property["name"] == "quit_fade_time":
			return String(property["hint_string"]).get_slice(",", 0).to_float()
	return 0.0


## A left click on the main menu's Options opens the options; the same click, once Quit has started
## to fade the screen out, opens nothing. The window takes the viewport's size for the case, so the
## click lands on the button it aims at: without a window the screen is 1920 × 1920 px (see
## test_crucifix_menus). A new size takes effect on the next frame.
func _a_click_during_quit_s_fade_opens_nothing() -> bool:
	var window_before: Vector2i = root.size
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var opened: bool = await _a_click_on_options_opens_them(false)
	var opened_while_quitting: bool = await _a_click_on_options_opens_them(true)
	root.size = window_before
	await process_frame
	return report(opened and not opened_while_quitting,
			"A click on Options: opens the options %s; during Quit's fade %s"
			% [opened, opened_while_quitting])


## A click on the main menu's Options, after Quit if quitting; true if the options opened. The fade
## is let finish before the main scene goes, so Quit's wait never outlives it.
func _a_click_on_options_opens_them(quitting: bool) -> bool:
	var main: Node = await new_main()
	main.quit_game = func() -> void: pass
	var button: Control = main_menu_node(main, ^"%OptionsButton") as Control
	var at: Vector2 = button.get_global_rect().get_center() if button != null else Vector2.ZERO
	if quitting:
		main._on_quit_requested()
		await process_frame
	await click(MOUSE_BUTTON_LEFT, at)
	var options: Control = main_menu_node(main, ^"%OptionsMenu") as Control
	var opened: bool = options != null and options.is_visible_in_tree()
	if quitting:
		await wait_frames(ceili(main.quit_fade_time * Engine.physics_ticks_per_second) + 10)
	await remove_main(main)
	return opened


func _the_menu_opens_with_the_game_s_name_and_play_selected() -> bool:
	var main: Node = await new_main()
	var menu: CanvasLayer = _menu(main)
	var title: Label = _menu_node(menu, ^"%Title") as Label
	var game_name: String = ProjectSettings.get_setting("application/config/name") as String
	var shows: bool = menu != null and menu.visible
	var named: bool = title != null and title.text == game_name
	var selected: bool = _is_selected(menu, ^"%PlayButton")
	var levels: int = levels_in(main)
	await remove_main(main)
	return report(shows and named and selected and levels == 0,
			"The menu opens: shown %s, titled \"%s\" %s, Play selected %s, levels in the slot %d"
			% [shows, game_name, named, selected, levels])


func _play_opens_the_level_list_with_the_first_level_selected() -> bool:
	var main: Node = await new_main(_two_levels())
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ENTER)
	var titles: PackedStringArray = _titles_of(main)
	var buttons: Array[Button] = _level_buttons(menu)
	var shown: PackedStringArray = []
	for button: Button in buttons:
		shown.append(button.text)
	var opened: bool = _is_shown(menu, ^"%LevelPanel") and not _is_shown(menu, ^"%MainPanel")
	var first_selected: bool = not buttons.is_empty() and root.gui_get_focus_owner() == buttons[0]
	await remove_main(main)
	return report(opened and not titles.is_empty() and shown == titles and first_selected,
			"Play: the level list open %s, buttons %s for Main's levels %s, the first selected %s"
			% [opened, shown, titles, first_selected])


## The game has one level in the menu, and a list with one button would be a step for nothing.
func _with_one_level_play_starts_it_at_once() -> bool:
	var room: LevelEntry = LevelEntry.new()
	room.title = "Room"
	room.scene = load("res://scenes/levels/test_room/test_room.tscn") as PackedScene
	var levels: Array[LevelEntry] = [room]
	var main: Node = await new_main(levels)
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ENTER)
	var started: bool = (levels_in(main) == 1
			and level_in(main).scene_file_path == room.scene.resource_path)
	var no_list: bool = not _is_shown(menu, ^"%LevelPanel")
	var hidden: bool = menu != null and not menu.visible
	await remove_main(main)
	return report(started and no_list and hidden,
			"One level: Play starts it %s, with no list %s, the menu hidden %s"
			% [started, no_list, hidden])


func _with_no_levels_play_opens_a_list_with_only_back_selected() -> bool:
	var no_levels: Array[LevelEntry] = []
	var main: Node = await new_main(no_levels)
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ENTER)
	var opened: bool = _is_shown(menu, ^"%LevelPanel")
	var buttons: int = _level_buttons(menu).size()
	var back_selected: bool = _is_selected(menu, ^"%BackButton")
	await remove_main(main)
	return report(opened and buttons == 0 and back_selected,
			"No levels: the list open %s, level buttons %d, Back selected %s"
			% [opened, buttons, back_selected])


## Back is reached from the list with the down arrow, past every level's button. The Esc that goes
## back stops at the menu: the counter never gets it.
func _back_and_esc_go_back_to_play() -> bool:
	var back_counter: BackCounter = BackCounter.new()
	root.add_child(back_counter)
	var main: Node = await new_main(_two_levels())
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ENTER)
	for _level: int in _titles_of(main).size():
		await tap(KEY_DOWN)
	var back_reached: bool = _is_selected(menu, ^"%BackButton")
	await tap(KEY_ENTER)
	var after_back: bool = _is_on_play(menu)
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	var after_esc: bool = _is_on_play(menu)
	var esc_stopped: bool = back_counter.presses == 0
	await remove_main(main)
	back_counter.queue_free()
	return report(back_reached and after_back and after_esc and esc_stopped,
			"Back reached with the arrows %s; back on Play after Back %s, after Esc %s; Esc stopped %s"
			% [back_reached, after_back, after_esc, esc_stopped])


## A is the gamepad's bottom button (Xbox A, Sony Cross) and B the right one (Xbox B, Sony Circle).
func _with_the_gamepad_a_opens_the_list_and_b_goes_back() -> bool:
	var main: Node = await new_main(_two_levels())
	var menu: CanvasLayer = _menu(main)
	await tap_joypad(JOY_BUTTON_A)
	var buttons: Array[Button] = _level_buttons(menu)
	var a_opened: bool = (_is_shown(menu, ^"%LevelPanel") and not buttons.is_empty()
			and root.gui_get_focus_owner() == buttons[0])
	await tap_joypad(JOY_BUTTON_B)
	var b_went_back: bool = _is_on_play(menu)
	await remove_main(main)
	return report(a_opened and b_went_back,
			"Gamepad: A opens the list on the first level %s, B goes back to Play %s"
			% [a_opened, b_went_back])


## Each level is chosen in a main scene of its own, with the down arrow to its button.
func _each_level_s_button_starts_its_scene_and_hides_the_menu() -> bool:
	var probe: Node = (await main_scene()).instantiate()
	var levels: Array = _levels_of(probe)
	probe.free()
	var outcomes: PackedStringArray = []
	var all_started: bool = not levels.is_empty()
	for index: int in levels.size():
		var level: LevelEntry = levels[index] as LevelEntry
		var main: Node = await new_main()
		var menu: CanvasLayer = _menu(main)
		await tap(KEY_ENTER)
		for _step: int in index:
			await tap(KEY_DOWN)
		await tap(KEY_ENTER)
		var started: bool = (levels_in(main) == 1
				and level_in(main).scene_file_path == level.scene.resource_path
				and not menu.visible)
		all_started = all_started and started
		outcomes.append("\"%s\" %s" % [level.title, started])
		await remove_main(main)
	return report(all_started,
			"Each level's button starts its scene and hides the menu: %s" % ", ".join(outcomes))


## A level left empty (an element added in the Inspector and never filled in) and one with no scene
## are left out of the list, each with a warning, and the good one still starts.
func _broken_levels_are_left_out_and_the_rest_work() -> bool:
	var no_scene: LevelEntry = LevelEntry.new()
	no_scene.title = "No scene"
	var room: LevelEntry = LevelEntry.new()
	room.title = "Room"
	room.scene = load("res://scenes/levels/test_room/test_room.tscn") as PackedScene
	var levels: Array[LevelEntry] = [null, no_scene, room]
	var main: Node = await new_main(levels)
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ENTER)
	var shown: PackedStringArray = []
	for button: Button in _level_buttons(menu):
		shown.append(button.text)
	await tap(KEY_ENTER)
	var started: bool = (levels_in(main) == 1
			and level_in(main).scene_file_path == room.scene.resource_path)
	await remove_main(main)
	return report(shown == PackedStringArray(["Room"]) and started,
			"Broken levels left out: the list shows %s, the good one starts %s" % [shown, started])


## A level with In Menu off gets no button; the one after it is still the one its button starts.
## That the main scene keeps such levels in its list is the next case's.
func _a_level_out_of_the_menu_gets_no_button() -> bool:
	var hidden_room: LevelEntry = LevelEntry.new()
	hidden_room.title = "Hidden room"
	hidden_room.scene = load("res://scenes/levels/test_room/test_room.tscn") as PackedScene
	hidden_room.in_menu = false
	var gym: LevelEntry = LevelEntry.new()
	gym.title = "Gym"
	gym.scene = load("res://scenes/levels/gym/gym.tscn") as PackedScene
	var levels: Array[LevelEntry] = [hidden_room, gym]
	var main: Node = await new_main(levels)
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ENTER)
	var shown: PackedStringArray = []
	for button: Button in _level_buttons(menu):
		shown.append(button.text)
	await tap(KEY_ENTER)
	var started: bool = (levels_in(main) == 1
			and level_in(main).scene_file_path == gym.scene.resource_path)
	await remove_main(main)
	return report(shown == PackedStringArray(["Gym"]) and started,
			"In Menu off: the list shows %s, the shown one starts %s" % [shown, started])


## The rooms made for development stay in the main scene's list, out of the menu; level 1 is in it.
func _the_development_rooms_stay_in_the_list_out_of_the_menu() -> bool:
	const OUT_OF_THE_MENU: PackedStringArray = [
		"res://scenes/levels/test_room/test_room.tscn",
		"res://scenes/levels/lust/LustLevel_Phase1_Cave.tscn",
		"res://scenes/levels/gym/gym.tscn",
	]
	const IN_THE_MENU: String = "res://scenes/levels/lust/level1_lit.tscn"
	var probe: Node = (await main_scene()).instantiate()
	var found: Dictionary[String, bool] = {}
	for level: Variant in _all_levels_of(probe):
		var entry: LevelEntry = level as LevelEntry
		if entry != null and entry.scene != null:
			found[entry.scene.resource_path] = entry.in_menu
	probe.free()
	var all_out: bool = true
	for path: String in OUT_OF_THE_MENU:
		all_out = all_out and found.has(path) and not found[path]
	var level1_in: bool = found.get(IN_THE_MENU, false)
	return report(all_out and level1_in,
			"Development rooms kept and out of the menu %s, level 1 in it %s (In Menu by scene: %s)"
			% [all_out, level1_in, found])


## Esc must go past the hidden menu to the pause, and Space then presses Resume, not a menu button.
func _esc_and_space_in_the_level_reach_no_menu_button() -> bool:
	var main: Node = await new_main_in_a_level()
	var menu: CanvasLayer = _menu(main)
	await tap(KEY_ESCAPE)
	var esc_paused: bool = paused
	await tap(KEY_SPACE)
	var hidden: bool = menu != null and not menu.visible
	var focus: Control = root.gui_get_focus_owner()
	var menu_selected: bool = focus != null and menu != null and menu.is_ancestor_of(focus)
	var levels: int = levels_in(main)
	var resumed: bool = not paused
	await remove_main(main)
	return report(esc_paused and resumed and hidden and not menu_selected and levels == 1,
			("Esc and Space in the level: Esc paused %s, Space resumed %s, menu hidden %s, "
			+ "a menu button selected %s, levels %d")
			% [esc_paused, resumed, hidden, menu_selected, levels])


## Every label and button of the menu, in all its panels and including the buttons made at run time.
func _the_menu_text_takes_its_size_from_the_ui_theme() -> bool:
	var main: Node = await new_main()
	var expected: int = theme_font_size()
	var texts: Array[Control] = texts_in(_menu(main))
	var other_sizes: Array[String] = off_size(texts, expected)
	await remove_main(main)
	return report(expected > 0 and texts.size() > 0 and other_sizes.is_empty(),
			"Text size: theme %d px; %d labels and buttons, off the theme: %s"
			% [expected, texts.size(), other_sizes])


## Two light rooms, so Play opens the list: with one level it starts it at once.
func _two_levels() -> Array[LevelEntry]:
	var room: LevelEntry = LevelEntry.new()
	room.title = "Room"
	room.scene = load("res://scenes/levels/test_room/test_room.tscn") as PackedScene
	var gym: LevelEntry = LevelEntry.new()
	gym.title = "Gym"
	gym.scene = load("res://scenes/levels/gym/gym.tscn") as PackedScene
	var levels: Array[LevelEntry] = [room, gym]
	return levels


func _menu(main: Node) -> CanvasLayer:
	return main.get_node_or_null(^"%MainMenu") as CanvasLayer


## A node of the menu's own scene, by its unique name; null if there is no menu or no such node.
func _menu_node(menu: CanvasLayer, path: NodePath) -> Node:
	return menu.get_node_or_null(path) if menu != null else null


func _is_shown(menu: CanvasLayer, path: NodePath) -> bool:
	var control: Control = _menu_node(menu, path) as Control
	return control != null and control.is_visible_in_tree()


func _is_selected(menu: CanvasLayer, path: NodePath) -> bool:
	var control: Control = _menu_node(menu, path) as Control
	return control != null and root.gui_get_focus_owner() == control


func _is_on_play(menu: CanvasLayer) -> bool:
	return (_is_shown(menu, ^"%MainPanel") and not _is_shown(menu, ^"%LevelPanel")
			and _is_selected(menu, ^"%PlayButton"))


func _level_buttons(menu: CanvasLayer) -> Array[Button]:
	var buttons: Array[Button] = []
	var holder: Node = _menu_node(menu, ^"%LevelButtons")
	if holder != null:
		for child: Node in holder.get_children():
			buttons.append(child as Button)
	return buttons


## Main's levels the menu offers: those with a scene and In Menu on. Empty if it has none, or no
## such list.
func _levels_of(main: Node) -> Array:
	var offered: Array = []
	for level: Variant in _all_levels_of(main):
		var entry: LevelEntry = level as LevelEntry
		if entry != null and entry.scene != null and entry.in_menu:
			offered.append(entry)
	return offered


## Main's levels, those out of the menu included; empty if it has none, or no such list.
func _all_levels_of(main: Node) -> Array:
	var levels: Variant = main.get(&"levels")
	return levels if levels is Array else []


func _titles_of(main: Node) -> PackedStringArray:
	var titles: PackedStringArray = []
	for level: Variant in _levels_of(main):
		titles.append((level as LevelEntry).title)
	return titles
