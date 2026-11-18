# Checks the debug jump to a phase. GameState forgets the one event it is told to. A level starts
# over at the start of a phase it has, as if the man had just reached it: the save points up to that
# phase's are marked and the later ones forgotten, he starts at that save point and RunStats is in
# that phase; in the run the save keeps it, since a restart there goes back to the save. The first
# phase starts after the tutorial. A phase the level lacks does nothing, and a level of one phase has
# none to jump to, so the gym keeps its number keys. On its own (F6), the level
# reloads itself at the phase. In the debug overlay, the keys 1 to 3 jump only while its text shows,
# and not while paused.
# The tests use a save file of their own, never the player's.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_debug_phase_jump.gd
extends "res://tests/support/menu_test.gd"

const DeathIrisStats := preload("res://scenes/levels/death_iris_stats.gd")

const SAVE_PATH: String = "user://test_debug_phase_jump.cfg"
const LEVEL_1_PATH: String = "res://scenes/levels/lust/level1.tscn"
const TEST_ROOM_PATH: String = "res://scenes/levels/test_room/test_room.tscn"
const BALLOON_PATH: String = "res://scenes/screens/dialogue_balloon.tscn"
const TUTORIAL_EVENT: StringName = &"tutorial_done"
const PHASE_2_EVENT: StringName = &"lust_phase_2_reached"
const PHASE_3_EVENT: StringName = &"lust_phase_3_reached"
const AN_EVENT: StringName = &"an_event"
const ANOTHER_EVENT: StringName = &"another_event"
## How near his save point's Respawn he starts, in px, as in test_save_game.
const NEAR: float = 2.0
## Physics frames that a jump would fill, its fade and its restart, so one that should not happen
## would show by then.
const NO_JUMP_FRAMES: int = 40


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	SaveFile.default_path = SAVE_PATH
	var results: Array[bool] = []
	results.append(_forget_event_takes_back_only_that_event())
	results.append(await _in_the_run_a_jump_starts_at_the_phase_and_the_save_keeps_it())
	results.append(await _a_phase_the_level_lacks_does_nothing())
	results.append(await _on_its_own_the_level_reloads_at_the_phase())
	results.append(await _the_keys_jump_only_with_the_text_shown_and_not_paused())
	results.append(await _a_level_that_does_not_run_does_not_jump())
	results.append(await _a_key_of_the_player_s_controls_stays_his())
	results.append(await _a_second_press_keeps_the_fade_and_takes_the_last_phase())
	results.append(await _the_save_points_of_each_level_start_their_phases_in_order())
	results.append(_a_line_on_screen_lets_the_phase_keys_through())
	results.append(await _a_death_in_a_jump_s_fade_keeps_the_fade())
	results.append(await _a_jump_in_the_fade_in_darkens_on_from_there())
	_delete_save()
	_progress().reset()
	_run_stats().reset()
	SaveFile.default_path = ""
	finish(results)


func _forget_event_takes_back_only_that_event() -> bool:
	_progress().reset()
	_progress().mark_event(AN_EVENT)
	_progress().mark_event(ANOTHER_EVENT)
	_progress().forget_event(AN_EVENT)
	_progress().forget_event(&"never_marked")
	var forgotten: bool = not _progress().has_event(AN_EVENT)
	var kept: bool = _progress().has_event(ANOTHER_EVENT)
	_progress().reset()
	return report(forgotten and kept,
			"Forget event: the one told forgotten %s, the other kept %s" % [forgotten, kept])


## Phase 3 and then back to phase 1, in a new game of Level 1.
func _in_the_run_a_jump_starts_at_the_phase_and_the_save_keeps_it() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var first: Level = level_in(main) as Level
	var jumped: bool = first.jump_to_phase(3)
	var restarted: bool = await _wait_for_a_new_copy(main, first)
	var at_3: Level = level_in(main) as Level
	var starts_at_3: bool = _starts_at(at_3, ^"Phase3Save")
	var all: Array[StringName] = [TUTORIAL_EVENT, PHASE_2_EVENT, PHASE_3_EVENT]
	var none: Array[StringName] = []
	var state_3: bool = _marked(all, none) and _saved(all, none) and _run_stats().get_phase() == 3
	at_3.jump_to_phase(1)
	var restarted_again: bool = await _wait_for_a_new_copy(main, at_3)
	var at_1: Level = level_in(main) as Level
	var starts_at_1: bool = _starts_at(at_1, ^"TutorialSave")
	var tutorial: Array[StringName] = [TUTORIAL_EVENT]
	var later: Array[StringName] = [PHASE_2_EVENT, PHASE_3_EVENT]
	var state_1: bool = (_marked(tutorial, later) and _saved(tutorial, later)
			and _run_stats().get_phase() == 1)
	await remove_main(main)
	_delete_save()
	return report(jumped and restarted and starts_at_3 and state_3 and restarted_again and starts_at_1
			and state_1,
			("In the run: to phase 3 jumps %s, restarts %s, at its save point %s, marked, saved and in "
			+ "phase 3 %s; back to phase 1 restarts %s, after the tutorial %s, phases 2 and 3 "
			+ "forgotten and saved, in phase 1 %s")
			% [jumped, restarted, starts_at_3, state_3, restarted_again, starts_at_1, state_1])


func _a_phase_the_level_lacks_does_nothing() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var level: Level = level_in(main) as Level
	var state_before: String = var_to_str(_progress().to_save())
	var jumped: bool = level.jump_to_phase(4) or level.jump_to_phase(0)
	await wait_frames(NO_JUMP_FRAMES)
	var same_level: bool = level_in(main) == level
	var same_state: bool = var_to_str(_progress().to_save()) == state_before
	await remove_main(main)
	_delete_save()
	var room: Level = (load(TEST_ROOM_PATH) as PackedScene).instantiate() as Level
	root.add_child(room)
	await wait_frames(2)
	var one_phase_jumps: bool = room.jump_to_phase(1)
	room.queue_free()
	await wait_frames(2)
	return report(not jumped and same_level and same_state and not one_phase_jumps,
			("A phase it lacks: jumps %s, the same level %s, the state as it was %s; a level of one "
			+ "phase, as the test room or the gym, jumps to it %s")
			% [jumped, same_level, same_state, one_phase_jumps])


## Run with F6, with no Main and no save: the level reloads itself, and GameState keeps the jump.
func _on_its_own_the_level_reloads_at_the_phase() -> bool:
	_progress().reset()
	var first: Level = (load(LEVEL_1_PATH) as PackedScene).instantiate() as Level
	root.add_child(first)
	current_scene = first
	await wait_frames(2)
	var first_id: int = first.get_instance_id()
	var jumped: bool = first.jump_to_phase(2)
	var reloaded: bool = await wait_until(func() -> bool:
		return current_scene is Level and current_scene.get_instance_id() != first_id)
	var now: Level = current_scene as Level
	var starts_at_2: bool = reloaded and _starts_at(now, ^"Phase2Save")
	var marked: Array[StringName] = [TUTORIAL_EVENT, PHASE_2_EVENT]
	var forgotten: Array[StringName] = [PHASE_3_EVENT]
	var state: bool = _marked(marked, forgotten)
	paused = false
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	current_scene = null
	await wait_frames(2)
	_progress().reset()
	return report(jumped and reloaded and starts_at_2 and state,
			"On its own: jumps %s, reloads %s, at phase 2's save point %s, the events right %s"
			% [jumped, reloaded, starts_at_2, state])


## Level 1's overlay starts hidden: 2 does nothing; F3 shows it; paused, 3 does nothing; then 2
## starts the level over at phase 2.
func _the_keys_jump_only_with_the_text_shown_and_not_paused() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var first: Level = level_in(main) as Level
	var overlay: DebugOverlay = first.get_node(^"DebugOverlay") as DebugOverlay
	await tap(KEY_2)
	await wait_frames(NO_JUMP_FRAMES)
	if level_in(main) != first:
		await remove_main(main)
		_delete_save()
		return report(false, "Keys: hidden, 2 started the level over")
	await tap(KEY_F3)
	var shown: bool = overlay.visible
	paused = true
	await tap(KEY_3)
	# Unpaused, a jump taken while paused would go on now: none must.
	paused = false
	await wait_frames(NO_JUMP_FRAMES)
	if level_in(main) != first or _progress().has_event(PHASE_3_EVENT):
		await remove_main(main)
		_delete_save()
		return report(false, "Keys: paused, 3 started the level over once unpaused")
	await tap(KEY_2)
	var restarted: bool = await _wait_for_a_new_copy(main, first)
	var starts_at_2: bool = restarted and _starts_at(level_in(main) as Level, ^"Phase2Save")
	await remove_main(main)
	_delete_save()
	return report(shown and restarted and starts_at_2,
			("Keys: hidden, 2 leaves the level true; F3 shows the text %s; paused, 3 leaves it true; "
			+ "then 2 restarts %s at phase 2's save point %s") % [shown, restarted, starts_at_2])


## Paused, or disabled as Main's slot is during a phase change, the level neither jumps nor tells
## Main to save.
func _a_level_that_does_not_run_does_not_jump() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var level: Level = level_in(main) as Level
	var saved_before: Dictionary = SaveFile.new().read()
	paused = true
	var paused_jumps: bool = level.jump_to_phase(2)
	paused = false
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var disabled_jumps: bool = level.jump_to_phase(2)
	level.process_mode = Node.PROCESS_MODE_INHERIT
	await wait_frames(NO_JUMP_FRAMES)
	var same: bool = (level_in(main) == level and not _progress().has_event(PHASE_2_EVENT)
			and SaveFile.new().read() == saved_before)
	await remove_main(main)
	_delete_save()
	return report(not paused_jumps and not disabled_jumps and same,
			"Not running: paused jumps %s, disabled jumps %s, the level, state and save as they were %s"
			% [paused_jumps, disabled_jumps, same])


## With 3 given to Jump, as a Custom profile can, 3 is a jump and not a jump to phase 3, though the
## text shows. At the level's start, where nothing else takes the keys (see the keys' case); a line
## on screen would take them all.
func _a_key_of_the_player_s_controls_stays_his() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var level: Level = level_in(main) as Level
	(level.get_node(^"DebugOverlay") as DebugOverlay).visible = true
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_3
	InputMap.action_add_event(&"jump", key)
	await tap(KEY_3)
	await wait_frames(NO_JUMP_FRAMES)
	InputMap.action_erase_event(&"jump", key)
	var stays: bool = level_in(main) == level and not _progress().has_event(PHASE_3_EVENT)
	await remove_main(main)
	_delete_save()
	return report(stays, "A key of his controls: 3 on Jump leaves the level as it was %s" % stays)


## A second press during the fade does not start it again, and the restart takes the last phase
## asked for.
func _a_second_press_keeps_the_fade_and_takes_the_last_phase() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var first: Level = level_in(main) as Level
	first.jump_to_phase(2)
	await wait_frames(4)
	var before: float = first.get_iris().get_darkness()
	first.jump_to_phase(3)
	# process_frame comes before the nodes' _process: two of them pass one frame of the fade.
	await process_frame
	await process_frame
	var after: float = first.get_iris().get_darkness() if is_instance_valid(first) else 1.0
	var restarted: bool = await _wait_for_a_new_copy(main, first)
	var at_3: bool = restarted and _starts_at(level_in(main) as Level, ^"Phase3Save")
	await remove_main(main)
	_delete_save()
	return report(before > 0.0 and after >= before and at_3,
			"A second press: darkness %.2f, then %.2f; restarts at phase 3's save point %s"
			% [before, after, at_3])


## The jump takes the scene's order for the route's: in every level of the main menu, the save
## points that start a phase come in the order of their phases.
func _the_save_points_of_each_level_start_their_phases_in_order() -> bool:
	var main: Node = (await main_scene()).instantiate()
	var wrong: PackedStringArray = []
	for entry: LevelEntry in main.get(&"levels"):
		var level: Node = entry.scene.instantiate()
		var last: int = 0
		for node: Node in level.find_children("*", "Area2D", true, false):
			var save_point: SavePoint = node as SavePoint
			if save_point == null or save_point.starts_phase < 1:
				continue
			if save_point.starts_phase <= last:
				wrong.append("%s: %s" % [entry.scene.resource_path, save_point.name])
			last = save_point.starts_phase
		level.free()
	main.free()
	return report(wrong.is_empty(), "Phases in the scene's order in every level: out of order %s"
			% [wrong])


## The balloon of the lines lets the phase keys through, as the other debug keys: with a line on
## screen, they would not reach the overlay. test_dialogue_balloon_input checks Lets Through itself.
func _a_line_on_screen_lets_the_phase_keys_through() -> bool:
	var balloon: DialogueBalloon = (load(BALLOON_PATH) as PackedScene).instantiate() as DialogueBalloon
	var missing: Array[StringName] = []
	for action: StringName in DebugOverlay.PHASE_ACTIONS:
		if not balloon.lets_through.has(action):
			missing.append(action)
	balloon.free()
	return report(missing.is_empty(), "A line lets the phase keys through: missing %s" % [missing])


## Dying in a jump's fade, the fade goes on, and the restart comes when it ends, at the phase asked
## for.
func _a_death_in_a_jump_s_fade_keeps_the_fade() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var first: Level = level_in(main) as Level
	var close_frames: int = roundi(first.iris_stats.close_time * Engine.physics_ticks_per_second)
	first.jump_to_phase(2)
	await wait_frames(close_frames / 3)
	var before: float = first.get_iris().get_darkness()
	(first.player.get_node(^"GrabEscape") as GrabEscape).died.emit()
	# process_frame comes before the nodes' _process: two of them pass one frame of the fade.
	await process_frame
	await process_frame
	var after: float = first.get_iris().get_darkness() if is_instance_valid(first) else 1.0
	var restarted: bool = await _wait_for_a_new_copy(main, first, close_frames)
	var at_2: bool = restarted and _starts_at(level_in(main) as Level, ^"Phase2Save")
	await remove_main(main)
	_delete_save()
	return report(after > before and restarted and at_2,
			("A death in a jump's fade: darkness %.2f, then %.2f; restarts by the fade's end %s, at "
			+ "phase 2's save point %s") % [before, after, restarted, at_2])


## A jump while the new copy still lightens darkens on from where it is, never back to clear first.
func _a_jump_in_the_fade_in_darkens_on_from_there() -> bool:
	_delete_save()
	var main: Node = await _main_in_a_new_game()
	var first: Level = level_in(main) as Level
	first.jump_to_phase(2)
	if not await _wait_for_a_new_copy(main, first):
		await remove_main(main)
		_delete_save()
		return report(false, "A jump in the fade in: no new copy after the first jump")
	var level: Level = level_in(main) as Level
	var stats: DeathIrisStats = level.iris_stats
	var shortest: float = minf(stats.close_time - 1.0 / stats.frame_rate, stats.open_time)
	var most_step: float = stats.fade_ease / (Engine.physics_ticks_per_second * shortest) + 0.01
	await wait_frames(3)
	var last: float = level.get_iris().get_darkness()
	var at_jump: float = last
	level.jump_to_phase(3)
	var biggest: float = 0.0
	for frame: int in roundi(stats.close_time * Engine.physics_ticks_per_second) + 2:
		await process_frame
		if level_in(main) != level:
			break
		var iris: Node = level.get_iris()
		var darkness: float = iris.get_darkness() if iris.is_drawn() else 0.0
		biggest = maxf(biggest, absf(darkness - last))
		last = darkness
	await remove_main(main)
	_delete_save()
	return report(at_jump > 0.0 and biggest <= most_step,
			"A jump in the fade in: darkness %.2f at the jump; the biggest jump between frames %.2f (at most %.2f)"
			% [at_jump, biggest, most_step])


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


func _run_stats() -> GameRunStats:
	return root.get_node(^"RunStats") as GameRunStats


func _delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_PATH + SaveFile.COPY_SUFFIX)
	var run_path: String = SaveFile.new().get_run_path()
	DirAccess.remove_absolute(run_path)
	DirAccess.remove_absolute(run_path + SaveFile.COPY_SUFFIX)


## A main scene with Level 1 only, on a new game already in the level: Enter opens the list and
## Enter picks the level.
func _main_in_a_new_game() -> Node:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1"
	entry.scene = load(LEVEL_1_PATH) as PackedScene
	entry.starts_game = true
	var entries: Array[LevelEntry] = [entry]
	var main: Node = await new_main(entries)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	return main


func _wait_for_a_new_copy(main: Node, old: Level, frames: int = MAX_FRAMES) -> bool:
	var old_id: int = old.get_instance_id()
	return await wait_until(func() -> bool:
		var now: Node = level_in(main)
		return now != null and now.get_instance_id() != old_id, frames)


## Whether the man of level starts at the Respawn of its save point at path.
func _starts_at(level: Level, path: NodePath) -> bool:
	var save_point: SavePoint = level.get_node(path) as SavePoint
	return level.player.global_position.distance_to(save_point.respawn.global_position) < NEAR


## Whether GameState has every event of marked and none of forgotten.
func _marked(marked: Array[StringName], forgotten: Array[StringName]) -> bool:
	for event: StringName in marked:
		if not _progress().has_event(event):
			return false
	for event: StringName in forgotten:
		if _progress().has_event(event):
			return false
	return true


## Whether the save on disk has every event of marked and none of forgotten.
func _saved(marked: Array[StringName], forgotten: Array[StringName]) -> bool:
	var saved: Dictionary = SaveFile.new().read()
	if saved.is_empty():
		return false
	var events: PackedStringArray = saved["state"]["events"]
	for event: StringName in marked:
		if not events.has(String(event)):
			return false
	for event: StringName in forgotten:
		if events.has(String(event)):
			return false
	return true
