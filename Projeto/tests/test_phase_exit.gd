# Checks the way from one phase of a level into the next. In the game, walking into phase 1's exit
# turns the screen black, puts phase 2 in the level slot in phase 1's place, with its player
# standing at its start, and brings the screen back; Esc pressed on the way does not pause, and
# pauses again once phase 2 is in. Run on its own, as with F6, phase 1's exit changes the scene to
# phase 2 by itself.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_phase_exit.gd
extends "res://tests/support/menu_test.gd"

const PHASE_1_PATH: String = "res://scenes/levels/Lust/LustLevel_Phase1_Cave.tscn"
## The names of the phases' root nodes.
const PHASE_1_ROOT: StringName = &"LustPhase1Cave"
const PHASE_2_ROOT: StringName = &"LustPhase2"
## Phase 2's start: where its player stands, in its own coordinates.
const PHASE_2_START: Vector2 = Vector2(7224, 6048)
## Physics frames to wait for the change, fade in included.
const CHANGE_FRAMES: int = 180


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _in_the_game_the_exit_fades_to_phase_2())
	results.append(await _on_its_own_the_exit_changes_the_scene())
	finish(results)


func _in_the_game_the_exit_fades_to_phase_2() -> bool:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Phase 1"
	entry.scene = load(PHASE_1_PATH) as PackedScene
	var only_phase_1: Array[LevelEntry] = [entry]
	var main: Node = await new_main(only_phase_1)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	var player: Player = await player_on_the_floor(main)
	var started: bool = player != null and level_in(main).name == PHASE_1_ROOT
	var exit: PhaseExit = level_in(main).get_node_or_null(^"PhaseExit") as PhaseExit if started else null
	if exit == null:
		await remove_main(main)
		return report(false, "In the game: phase 1 with its player and its exit (started %s)" % started)
	player.global_position = exit.global_position + Vector2(0, 72)
	var fade: ColorRect = main.get_node(^"%Fade") as ColorRect
	var darkest: float = 0.0
	var paused_on_the_way: bool = false
	var pressed_esc: bool = false
	for _frame: int in CHANGE_FRAMES:
		await physics_frame
		darkest = maxf(darkest, fade.color.a)
		if not pressed_esc and fade.color.a > 0.5:
			pressed_esc = true
			await tap(KEY_ESCAPE)
		paused_on_the_way = paused_on_the_way or paused
		if level_in(main) != null and level_in(main).name == PHASE_2_ROOT and is_zero_approx(fade.color.a):
			break
	var level: Node = level_in(main)
	var in_phase_2: bool = level != null and level.name == PHASE_2_ROOT and levels_in(main) == 1
	var next_player: Player = await player_on_the_floor(main) if in_phase_2 else null
	var at_start: bool = next_player != null and next_player.position.distance_to(PHASE_2_START) < 1.0
	var back: bool = is_zero_approx(fade.color.a)
	await tap(KEY_ESCAPE)
	var pauses_after: bool = paused
	await remove_main(main)
	return report(darkest == 1.0 and pressed_esc and not paused_on_the_way and in_phase_2 and at_start
			and back and pauses_after,
			("In the game: the screen went black %s, Esc on the way paused %s, phase 2 alone in the slot "
			+ "%s, its player at its start %s, the screen back %s, Esc pauses after %s")
			% [darkest == 1.0, paused_on_the_way, in_phase_2, at_start, back, pauses_after])


func _on_its_own_the_exit_changes_the_scene() -> bool:
	var phase_1: Node = (load(PHASE_1_PATH) as PackedScene).instantiate()
	root.add_child(phase_1)
	current_scene = phase_1
	var player: Player = phase_1.get_node(^"Player") as Player
	var on_floor: bool = await wait_until_on_floor(player)
	var exit: PhaseExit = phase_1.get_node(^"PhaseExit") as PhaseExit
	player.global_position = exit.global_position + Vector2(0, 72)
	var changed: bool = await wait_until(func() -> bool:
			return current_scene != null and current_scene.name == PHASE_2_ROOT, CHANGE_FRAMES)
	if current_scene != null:
		current_scene.queue_free()
	await physics_frame
	return report(on_floor and changed,
			"On its own: phase 1's player on the floor %s, the scene changed to phase 2 %s"
			% [on_floor, changed])
