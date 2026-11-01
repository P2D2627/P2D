# Checks the main scene's menu. It opens with the game's name and Play selected, and nothing in the
# level slot. Play opens the level list: a button for each of Main's levels, in order, with the
# first one selected; with no levels, only Back, selected. Back and Esc go back to Play, selected,
# and that Esc goes no further. On the gamepad, A opens the list and B goes back.
# Each level's button starts that level's scene and hides the menu. A level left empty, or with no
# scene, is left out of the list, and the others still work. Inside the level, Esc goes past
# the hidden menu and pauses, and Space then presses Resume: the menu stays hidden, with nothing of
# it selected, and one level in the slot. All the menu's text takes its size from the UI theme, with
# no size set on a single node.
# Quit closes the game, which would also end this test with exit code 0, so it is checked by hand.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_main_flow.gd
extends "res://tests/support/menu_test.gd"


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_menu_opens_with_the_game_s_name_and_play_selected())
	results.append(await _play_opens_the_level_list_with_the_first_level_selected())
	results.append(await _with_no_levels_play_opens_a_list_with_only_back_selected())
	results.append(await _back_and_esc_go_back_to_play())
	results.append(await _with_the_gamepad_a_opens_the_list_and_b_goes_back())
	results.append(await _each_level_s_button_starts_its_scene_and_hides_the_menu())
	results.append(await _broken_levels_are_left_out_and_the_rest_work())
	results.append(await _esc_and_space_in_the_level_reach_no_menu_button())
	results.append(await _the_menu_text_takes_its_size_from_the_ui_theme())
	finish(results)


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
	var main: Node = await new_main()
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
	var main: Node = await new_main()
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
	var main: Node = await new_main()
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
	room.scene = load("res://levels/test_room.tscn") as PackedScene
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


## Main's levels; empty if it has none, or no such list.
func _levels_of(main: Node) -> Array:
	var levels: Variant = main.get(&"levels")
	return levels if levels is Array else []


func _titles_of(main: Node) -> PackedStringArray:
	var titles: PackedStringArray = []
	for level: Variant in _levels_of(main):
		titles.append((level as LevelEntry).title)
	return titles
