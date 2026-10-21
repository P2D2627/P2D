# Checks that the man's death starts the level over (ADR 0026). The death comes through his
# GrabEscape's died, which his scene passes on as his own. In the game, the level stays as it is for
# Restart Delay, so the death shows, and then Main puts a new copy of the same level in its slot,
# with the menu still hidden and the old copy gone. The wait stops while the game is paused, and
# Main Menu in the pause takes the level out for good: none comes back behind the menu. On its own,
# as F6 runs it, the level reloads itself as the current scene.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level_restart.gd
extends "res://tests/support/menu_test.gd"

const TEST_ROOM_PATH: String = "res://levels/test_room.tscn"
## Physics frames on either side of the end of the wait: the swap comes at the end of the frame the
## wait ends on, and the old copy is freed at the end of the next.
const SETTLE_FRAMES: int = 3


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _a_death_starts_the_level_over_after_the_delay())
	results.append(await _paused_during_the_wait_it_waits())
	results.append(await _main_menu_during_the_wait_brings_no_level_back())
	results.append(await _on_its_own_it_reloads_itself())
	finish(results)


## The level is the same one up to SETTLE_FRAMES before the wait ends, and a new copy of it,
## alone in the slot, SETTLE_FRAMES after; the old one is gone and the menu still hidden.
func _a_death_starts_the_level_over_after_the_delay() -> bool:
	var main: Node = await new_main_in_a_level()
	var level: Level = level_in(main) as Level
	var player: Player = await player_on_the_floor(main)
	if level == null or player == null:
		await remove_main(main)
		return report(false, "Restart: no Level with a man on the floor in the slot")
	var path: String = level.scene_file_path
	var delay_frames: int = _delay_frames(level)
	_die(player)
	await wait_frames(delay_frames - SETTLE_FRAMES)
	var kept: bool = level_in(main) == level
	await wait_frames(2 * SETTLE_FRAMES)
	var new_level: Node = level_in(main)
	var swapped: bool = (new_level is Level and new_level.scene_file_path == path
			and levels_in(main) == 1 and not is_instance_valid(level))
	var menu_hidden: bool = not (main.get_node(^"%MainMenu") as CanvasLayer).visible
	await remove_main(main)
	return report(kept and swapped and menu_hidden,
			("Restart after %d frames: the same level %d frames before %s; after, a new copy "
			+ "alone, the old one gone %s; menu hidden %s") % [delay_frames, SETTLE_FRAMES, kept,
			swapped, menu_hidden])


## Paused SETTLE_FRAMES into the wait, for longer than the whole wait: the level stays. Resumed, it
## starts over once the rest of the wait is up.
func _paused_during_the_wait_it_waits() -> bool:
	var main: Node = await new_main_in_a_level()
	var level: Level = level_in(main) as Level
	var player: Player = await player_on_the_floor(main)
	if level == null or player == null:
		await remove_main(main)
		return report(false, "Restart paused: no Level with a man on the floor in the slot")
	var delay_frames: int = _delay_frames(level)
	_die(player)
	await wait_frames(SETTLE_FRAMES)
	await tap(KEY_ESCAPE)
	await wait_frames(delay_frames + SETTLE_FRAMES)
	var kept_while_paused: bool = paused and level_in(main) == level
	await tap(KEY_ESCAPE)
	await wait_frames(delay_frames + SETTLE_FRAMES)
	var swapped: bool = level_in(main) is Level and not is_instance_valid(level)
	await remove_main(main)
	return report(kept_while_paused and swapped,
			"Restart paused: kept while paused %s; started over once resumed %s"
			% [kept_while_paused, swapped])


## Main Menu in the pause, SETTLE_FRAMES into the wait: the slot is empty and the menu shows, and
## after the whole wait it still is and still does.
func _main_menu_during_the_wait_brings_no_level_back() -> bool:
	var main: Node = await new_main_in_a_level()
	var level: Level = level_in(main) as Level
	var player: Player = await player_on_the_floor(main)
	if level == null or player == null:
		await remove_main(main)
		return report(false, "Main Menu in the wait: no Level with a man on the floor in the slot")
	var delay_frames: int = _delay_frames(level)
	var menu: CanvasLayer = main.get_node(^"%MainMenu") as CanvasLayer
	_die(player)
	await wait_frames(SETTLE_FRAMES)
	await tap(KEY_ESCAPE)
	await press_on(main.get_node(^"%PauseMenu"), ^"%MainMenuButton", KEY_ENTER)
	var out_at_once: bool = levels_in(main) == 0 and menu.visible
	await wait_frames(delay_frames + SETTLE_FRAMES)
	var still_out: bool = levels_in(main) == 0 and menu.visible
	await remove_main(main)
	return report(out_at_once and still_out,
			"Main Menu in the wait: no level and the menu shown at once %s, and after the wait %s"
			% [out_at_once, still_out])


## The test room as the current scene, with no Main: SETTLE_FRAMES after the wait, a new copy of it
## is the current scene, and the old one is gone.
func _on_its_own_it_reloads_itself() -> bool:
	var level: Level = (load(TEST_ROOM_PATH) as PackedScene).instantiate() as Level
	root.add_child(level)
	current_scene = level
	var delay_frames: int = _delay_frames(level)
	_die(level.player)
	await wait_frames(delay_frames + SETTLE_FRAMES)
	var now: Node = current_scene
	var reloaded: bool = (now is Level and now.scene_file_path == TEST_ROOM_PATH
			and not is_instance_valid(level))
	if now != null:
		now.queue_free()
	current_scene = null
	await process_frame
	return report(reloaded, "On its own: reloaded as the current scene %s" % reloaded)


## The man dies as a grab that runs out of time makes him: through his GrabEscape's died, which his
## scene passes on as his own.
func _die(player: Player) -> void:
	(player.get_node(^"GrabEscape") as GrabEscape).died.emit()


func _delay_frames(level: Level) -> int:
	return roundi(level.restart_delay * Engine.physics_ticks_per_second)
