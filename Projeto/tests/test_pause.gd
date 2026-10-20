# Checks the pause, through the main scene. In a level, Esc pauses the game and shows the pause with
# Resume selected, and that Esc stops at Main. While paused, the level stands still and the debug
# overlay keeps running. Esc again, or Resume, unpauses and hides the pause. Main Menu unpauses,
# takes the level out at once and shows the main menu on Play, and a new choice leaves one level in
# the slot. Start on the gamepad pauses and resumes like Esc. In the main menu, Esc and Start do not
# pause. Losing the window's focus pauses, only in a level and only with Pause On Focus Loss on, and
# while paused it changes nothing. All the pause's text takes its size from the UI theme, with no
# size set on a single node. Leaving the pause never makes the player jump: not with Space or A on
# Resume, both also Jump, nor with Space held through the pause and Esc to resume. In the game, B
# reaches the game. A B pressed in the pause closes it and stops there, one that went down in the
# game does not, and Interact, B's other action, is not just pressed when the game comes back. All
# of this holds for a quick tap too, with the press and the release in the same frame.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_pause.gd
extends "res://tests/support/menu_test.gd"

## Physics frames the player runs before the pause, and the level is watched during it.
const RUN_FRAMES: int = 20
const WATCH_FRAMES: int = 30

## The jumps of the player _player_on_the_floor found, from its jumped signal.
var _jumps: int = 0


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _esc_in_a_level_pauses_with_resume_selected())
	results.append(await _while_paused_the_level_stands_still_and_the_overlay_runs())
	results.append(await _esc_again_or_resume_unpause_and_hide_the_pause())
	results.append(await _main_menu_unpauses_takes_the_level_out_and_shows_play())
	results.append(await _start_on_the_gamepad_pauses_and_resumes())
	results.append(await _in_the_main_menu_esc_and_start_do_not_pause())
	results.append(await _losing_the_window_focus_pauses_only_in_a_level())
	results.append(await _the_pause_text_takes_its_size_from_the_ui_theme())
	results.append(await _resuming_with_space_or_a_does_not_jump())
	results.append(await _space_held_through_the_pause_and_esc_to_resume_does_not_jump())
	results.append(await _b_closes_the_pause_and_leaves_interact_unpressed())
	results.append(await _a_quick_tap_to_resume_neither_jumps_nor_interacts())
	finish(results)


## The counter gets Esc only if nothing in the main scene handled it.
func _esc_in_a_level_pauses_with_resume_selected() -> bool:
	var back_counter: BackCounter = BackCounter.new()
	root.add_child(back_counter)
	var main: Node = await new_main_in_a_level()
	await tap(KEY_ESCAPE)
	var shown: bool = _pause_shows(main)
	var resume_selected: bool = has_focus(pause_node(main, ^"%ResumeButton"))
	var levels: int = levels_in(main)
	var esc_stopped: bool = back_counter.presses == 0
	var was_paused: bool = paused
	await remove_main(main)
	back_counter.queue_free()
	return report(was_paused and shown and resume_selected and levels == 1 and esc_stopped,
			"Esc in a level: paused %s, pause shown %s, Resume selected %s, levels %d, Esc stopped %s"
			% [was_paused, shown, resume_selected, levels, esc_stopped])


func _while_paused_the_level_stands_still_and_the_overlay_runs() -> bool:
	var main: Node = await new_main_in_a_level()
	var level: Node = level_in(main)
	var player: Player = level.get_node_or_null(^"Player") as Player if level != null else null
	var overlay: Node = level.get_node_or_null(^"DebugOverlay") if level != null else null
	Input.action_press(&"move_right")
	for _frame: int in RUN_FRAMES:
		await physics_frame
	var running: bool = player != null and player.velocity.x > 0.0
	await tap(KEY_ESCAPE)
	var x_at_pause: float = player.position.x if player != null else 0.0
	for _frame: int in WATCH_FRAMES:
		await physics_frame
	var moved: float = absf(player.position.x - x_at_pause) if player != null else -1.0
	var overlay_runs: bool = overlay != null and overlay.can_process()
	Input.action_release(&"move_right")
	var was_paused: bool = paused
	await remove_main(main)
	return report(running and was_paused and moved == 0.0 and overlay_runs,
			"While paused: running before %s, paused %s, moved %.1f px in %d frames, overlay runs %s"
			% [running, was_paused, moved, WATCH_FRAMES, overlay_runs])


## Each way out is checked only after a pause that really happened.
func _esc_again_or_resume_unpause_and_hide_the_pause() -> bool:
	var main: Node = await new_main_in_a_level()
	await tap(KEY_ESCAPE)
	var esc_resumes: bool = paused
	await tap(KEY_ESCAPE)
	esc_resumes = esc_resumes and not paused and not _pause_shows(main) and _nothing_selected()
	await tap(KEY_ESCAPE)
	var resume_resumes: bool = paused
	await tap(KEY_ENTER)
	resume_resumes = (resume_resumes and not paused and not _pause_shows(main)
			and _nothing_selected())
	await remove_main(main)
	return report(esc_resumes and resume_resumes,
			"Paused, then unpaused with the pause hidden and nothing selected: by Esc %s, by Resume %s"
			% [esc_resumes, resume_resumes])


## Main Menu is two buttons below Resume, past Options.
func _main_menu_unpauses_takes_the_level_out_and_shows_play() -> bool:
	var main: Node = await new_main_in_a_level()
	var menu: CanvasLayer = main.get_node_or_null(^"%MainMenu") as CanvasLayer
	await tap(KEY_ESCAPE)
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	var main_menu_reached: bool = has_focus(pause_node(main, ^"%MainMenuButton"))
	await tap(KEY_ENTER)
	var unpaused: bool = not paused and not _pause_shows(main)
	var levels_after: int = levels_in(main)
	var on_play: bool = (menu != null and menu.visible
			and has_focus(main_menu_node(main, ^"%PlayButton")))
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	var levels_again: int = levels_in(main)
	await remove_main(main)
	return report(main_menu_reached and unpaused and levels_after == 0 and on_play
			and levels_again == 1,
			("Main Menu reached %s: unpaused %s, levels %d, the main menu on Play %s; "
			+ "a new choice leaves %d level") % [main_menu_reached, unpaused, levels_after, on_play,
			levels_again])


func _start_on_the_gamepad_pauses_and_resumes() -> bool:
	var main: Node = await new_main_in_a_level()
	await tap_joypad(JOY_BUTTON_START)
	var pauses: bool = paused and _pause_shows(main)
	await tap_joypad(JOY_BUTTON_START)
	var resumes: bool = pauses and not paused and not _pause_shows(main)
	await remove_main(main)
	return report(pauses and resumes, "Start: pauses %s, then resumes %s" % [pauses, resumes])


## Checked after each one: Esc pausing and Start resuming would end up looking the same.
func _in_the_main_menu_esc_and_start_do_not_pause() -> bool:
	var main: Node = await new_main()
	await tap(KEY_ESCAPE)
	var after_esc: bool = not paused and not _pause_shows(main)
	await tap_joypad(JOY_BUTTON_START)
	var after_start: bool = not paused and not _pause_shows(main)
	await remove_main(main)
	return report(after_esc and after_start,
			"In the main menu, not paused: after Esc %s, after Start %s" % [after_esc, after_start])


## The window losing the focus is sent to the whole tree, as the engine does. Lost again while
## paused, it leaves the pause as it was: the selection stays on Main Menu.
func _losing_the_window_focus_pauses_only_in_a_level() -> bool:
	var main: Node = await new_main()
	_lose_focus()
	var in_the_menu: bool = paused
	await remove_main(main)
	main = await new_main_in_a_level()
	_lose_focus()
	var in_a_level: bool = (paused and _pause_shows(main)
			and has_focus(pause_node(main, ^"%ResumeButton")))
	await tap(KEY_DOWN)
	await tap(KEY_DOWN)
	_lose_focus()
	await process_frame
	var kept: bool = paused and has_focus(pause_node(main, ^"%MainMenuButton"))
	await remove_main(main)
	main = await new_main_in_a_level()
	main.set(&"pause_on_focus_loss", false)
	_lose_focus()
	var with_the_option_off: bool = paused
	await remove_main(main)
	return report(not in_the_menu and in_a_level and kept and not with_the_option_off,
			("Losing the focus pauses: in the main menu %s, in a level %s, already paused it keeps "
			+ "the selection %s, with the option off %s")
			% [in_the_menu, in_a_level, kept, with_the_option_off])


func _the_pause_text_takes_its_size_from_the_ui_theme() -> bool:
	var main: Node = await new_main()
	var expected: int = theme_font_size()
	var texts: Array[Control] = texts_in(main.get_node_or_null(^"%PauseMenu"))
	var other_sizes: Array[String] = off_size(texts, expected)
	await remove_main(main)
	return report(expected > 0 and texts.size() > 0 and other_sizes.is_empty(),
			"Pause text size: theme %d px; %d labels and buttons, off the theme: %s"
			% [expected, texts.size(), other_sizes])


## On the floor, paused with Esc, and resumed by pressing Resume with Space, then with A, each in a
## main scene of its own. Space and A are also Jump: the resume must work, and the player must not
## jump on the frames after it.
func _resuming_with_space_or_a_does_not_jump() -> bool:
	var outcomes: PackedStringArray = []
	var all_right: bool = true
	for way: String in ["Space", "A"]:
		var main: Node = await new_main_in_a_level()
		var on_the_floor: bool = (await _player_on_the_floor(main)) != null
		await tap(KEY_ESCAPE)
		var was_paused: bool = paused
		if way == "Space":
			await tap(KEY_SPACE)
		else:
			await tap_joypad(JOY_BUTTON_A)
		var resumed: bool = was_paused and not paused
		for _frame: int in WATCH_FRAMES:
			await physics_frame
		all_right = all_right and on_the_floor and resumed and _jumps == 0
		outcomes.append("%s: on the floor %s, resumed %s, jumps %d"
				% [way, on_the_floor, resumed, _jumps])
		await remove_main(main)
	return report(all_right, "Resume with Space or A: %s" % ", ".join(outcomes))


## Space goes down during the pause and stays down while Esc resumes the game.
func _space_held_through_the_pause_and_esc_to_resume_does_not_jump() -> bool:
	var main: Node = await new_main_in_a_level()
	var on_the_floor: bool = (await _player_on_the_floor(main)) != null
	await tap(KEY_ESCAPE)
	var was_paused: bool = paused
	await press_key(KEY_SPACE, true)
	await tap(KEY_ESCAPE)
	var resumed: bool = was_paused and not paused
	for _frame: int in WATCH_FRAMES:
		await physics_frame
	await press_key(KEY_SPACE, false)
	for _frame: int in WATCH_FRAMES:
		await physics_frame
	var jumps: int = _jumps
	await remove_main(main)
	return report(on_the_floor and resumed and jumps == 0,
			"Space held through the pause, Esc to resume: on the floor %s, resumed %s, jumps %d"
			% [on_the_floor, resumed, jumps])


## B, the gamepad's back button, is also Interact. In the game, B goes past the hidden pause to the
## game. A B that went down in the game and comes up in the pause leaves the pause open; a B pressed
## in the pause closes it and stops there. The probe sits in the level, so it only runs while the
## game does.
func _b_closes_the_pause_and_leaves_interact_unpressed() -> bool:
	var back_counter: BackCounter = BackCounter.new()
	root.add_child(back_counter)
	var main: Node = await new_main_in_a_level()
	var level: Node = level_in(main)
	var probe: InteractProbe = InteractProbe.new()
	if level != null:
		level.add_child(probe)
	await tap_joypad(JOY_BUTTON_B)
	var reaches_the_game: bool = not paused and back_counter.releases == 1
	await press_joypad(JOY_BUTTON_B, true)
	await tap_joypad(JOY_BUTTON_START)
	await press_joypad(JOY_BUTTON_B, false)
	var stays_open: bool = paused and _pause_shows(main)
	probe.just_pressed_frames = 0
	back_counter.releases = 0
	await tap_joypad(JOY_BUTTON_B)
	var resumed: bool = stays_open and not paused and not _pause_shows(main)
	var stopped: bool = back_counter.releases == 0
	for _frame: int in WATCH_FRAMES:
		await physics_frame
	var interacts: int = probe.just_pressed_frames
	await remove_main(main)
	back_counter.queue_free()
	return report(reaches_the_game and resumed and stopped and interacts == 0,
			("B: in the game it reaches the game %s; let go in the pause after going down in the "
			+ "game, the pause stays %s; pressed in the pause, resumes %s and stops there %s; "
			+ "frames with Interact just pressed after it %d")
			% [reaches_the_game, stays_open, resumed, stopped, interacts])


## A quick tap, as on a slow frame: the press and the release reach the game in the same frame, and
## Resume, or B, fires on that frame. Jump and Interact read as just pressed for the whole of the
## frame the key went down in, even once it is up, so the game must not come back until a later one.
## Each way in a main scene of its own, with the player on the floor, where a jump is possible.
func _a_quick_tap_to_resume_neither_jumps_nor_interacts() -> bool:
	var outcomes: PackedStringArray = []
	var all_right: bool = true
	for way: String in ["Space", "A", "B"]:
		var main: Node = await new_main_in_a_level()
		var on_the_floor: bool = (await _player_on_the_floor(main)) != null
		var probe: InteractProbe = InteractProbe.new()
		if level_in(main) != null:
			level_in(main).add_child(probe)
		await tap(KEY_ESCAPE)
		var was_paused: bool = paused
		match way:
			"Space":
				await tap_in_one_frame(KEY_SPACE)
			"A":
				await tap_joypad_in_one_frame(JOY_BUTTON_A)
			"B":
				await tap_joypad_in_one_frame(JOY_BUTTON_B)
		var resumed: bool = was_paused and not paused
		for _frame: int in WATCH_FRAMES:
			await physics_frame
		var interacts: int = probe.just_pressed_frames
		all_right = all_right and on_the_floor and resumed and _jumps == 0 and interacts == 0
		outcomes.append("%s: resumed %s, jumps %d, Interact just pressed %d"
				% [way, resumed, _jumps, interacts])
		await remove_main(main)
	return report(all_right, "A quick tap to resume: %s" % ", ".join(outcomes))


## The level's player, once it stands on the floor, with its jumps counted from then on; null if
## there is none or it never lands.
func _player_on_the_floor(main: Node) -> Player:
	var player: Player = await player_on_the_floor(main)
	if player == null:
		return null
	_jumps = 0
	player.jumped.connect(_on_jumped)
	return player


func _on_jumped(_late_frames: int, _buffered_frames: int) -> void:
	_jumps += 1


func _pause_shows(main: Node) -> bool:
	var pause: CanvasLayer = main.get_node_or_null(^"%PauseMenu") as CanvasLayer
	return pause != null and pause.visible


func _nothing_selected() -> bool:
	return root.gui_get_focus_owner() == null


func _lose_focus() -> void:
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)


## Counts the physics frames on which Interact reads as just pressed.
class InteractProbe extends Node:
	var just_pressed_frames: int = 0

	func _physics_process(_delta: float) -> void:
		if Input.is_action_just_pressed(&"interact"):
			just_pressed_frames += 1
