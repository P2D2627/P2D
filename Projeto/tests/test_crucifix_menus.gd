# Checks that the left mouse button, which is both Crucifix and the menus' click, only raises the
# crucifix when it is pressed in the game. Held down through the pause and still held as Esc resumes
# the game, it leaves the crucifix down; a click on Resume, slow or quick, leaves it down; held down
# from the main menu into the level, it leaves it down. In each case, letting go and pressing again
# in the game raises it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_menus.gd
extends "res://tests/support/menu_test.gd"

## Physics frames the game is watched for after it comes back.
const WATCH_FRAMES: int = 30


func _initialize() -> void:
	# Without a window the root is 64 × 64 px, and the Expand aspect makes that a 1920 × 1920 screen,
	# so a click would land away from the button it aims at. A size set before the first frame is
	# undone when the window starts, and a new size takes effect on the next frame.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(await _held_through_the_pause_and_esc_to_resume_it_stays_down())
	results.append(await _a_click_on_resume_leaves_it_down())
	results.append(await _held_from_the_main_menu_into_the_level_it_stays_down())
	finish(results)


## The mouse button goes down in the pause and stays down while Esc resumes the game.
func _held_through_the_pause_and_esc_to_resume_it_stays_down() -> bool:
	var main: Node = await new_main_in_a_level()
	var crucifix: Crucifix = await crucifix_on_the_floor(main)
	var found: bool = crucifix != null
	await tap(KEY_ESCAPE)
	var was_paused: bool = paused
	await press_mouse(MOUSE_BUTTON_LEFT, true)
	await tap(KEY_ESCAPE)
	var resumed: bool = was_paused and not paused
	var up_while_held: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
	var up_after_fresh_press: bool = await _goes_up_after_a_fresh_press(crucifix)
	await press_mouse(MOUSE_BUTTON_LEFT, false)
	await remove_main(main)
	return report(found and resumed and not up_while_held and up_after_fresh_press,
			"Mouse held through the pause, Esc to resume: resumed %s, up while held %s, up after a fresh press %s"
			% [resumed, up_while_held, up_after_fresh_press])


## A click on Resume with the left mouse button, slow and in one frame, resumes the game with the
## crucifix down.
func _a_click_on_resume_leaves_it_down() -> bool:
	var outcomes: PackedStringArray = []
	var all_right: bool = true
	for way: String in ["slow", "in one frame"]:
		var main: Node = await new_main_in_a_level()
		var crucifix: Crucifix = await crucifix_on_the_floor(main)
		var found: bool = crucifix != null
		await tap(KEY_ESCAPE)
		var was_paused: bool = paused
		var resume: Control = pause_node(main, ^"%ResumeButton") as Control
		var at: Vector2 = resume.get_global_rect().get_center() if resume != null else Vector2.ZERO
		if way == "slow":
			await click(MOUSE_BUTTON_LEFT, at)
		else:
			Input.parse_input_event(mouse_event(MOUSE_BUTTON_LEFT, true, at))
			Input.parse_input_event(mouse_event(MOUSE_BUTTON_LEFT, false, at))
			await _wait_tap_frames()
		var resumed: bool = was_paused and not paused
		var up: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
		all_right = all_right and found and resumed and not up
		outcomes.append("%s: resumed %s, up %s" % [way, resumed, up])
		await remove_main(main)
	return report(all_right, "A click on Resume: %s" % ", ".join(outcomes))


## The mouse button goes down in the main menu and stays down while Enter starts the level and the
## player lands.
func _held_from_the_main_menu_into_the_level_it_stays_down() -> bool:
	var main: Node = await new_main()
	await press_mouse(MOUSE_BUTTON_LEFT, true)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	var crucifix: Crucifix = await crucifix_on_the_floor(main)
	var found: bool = crucifix != null
	var up_while_held: bool = await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
	var up_after_fresh_press: bool = await _goes_up_after_a_fresh_press(crucifix)
	await press_mouse(MOUSE_BUTTON_LEFT, false)
	await remove_main(main)
	return report(found and not up_while_held and up_after_fresh_press,
			"Mouse held from the main menu into the level: up while held %s, up after a fresh press %s"
			% [up_while_held, up_after_fresh_press])


## Lets the mouse button go, presses it again, and says whether the crucifix goes up.
func _goes_up_after_a_fresh_press(crucifix: Crucifix) -> bool:
	await press_mouse(MOUSE_BUTTON_LEFT, false)
	await press_mouse(MOUSE_BUTTON_LEFT, true)
	return await crucifix_goes_up_within(crucifix, WATCH_FRAMES)
