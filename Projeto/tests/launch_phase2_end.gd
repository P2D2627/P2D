# Temporary launcher: starts the game in Main with Lust phase 2 already in the level slot and the
# player just right of its End checkpoint, a few steps from the exit to phase 3. Walk left into the
# green exit. With -- --auto it walks left by itself and prints which phase it ended in.
# godot --path Projeto --script res://tests/launch_phase2_end.gd
extends SceneTree

const MAIN_SCENE_PATH: String = "res://main.tscn"
const PHASE_2_PATH: String = "res://scenes/levels/Lust/LustLevel_Phase2.tscn"
## On the floor, right of the End checkpoint (x 360 to 456) and the exit (x 216 to 312).
const NEAR_THE_END: Vector2 = Vector2(624.0, 1050.0)
## Frames the automatic run walks left and then waits for the fade, at 60 per second.
const AUTO_WALK_FRAMES: int = 120
const AUTO_WAIT_FRAMES: int = 120


func _initialize() -> void:
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var level: Node = (load(PHASE_2_PATH) as PackedScene).instantiate()
	(level.get_node(^"Player") as Node2D).position = NEAR_THE_END
	(level.get_node(^"GameCamera") as Node2D).position = NEAR_THE_END
	main.call(&"_add_level", level)
	main.get_node(^"%MainMenu").hide()
	if "--auto" in OS.get_cmdline_user_args():
		await _walk_into_the_exit(main)


func _walk_into_the_exit(main: Node) -> void:
	Input.action_press(&"move_left")
	for _frame: int in AUTO_WALK_FRAMES:
		await physics_frame
	Input.action_release(&"move_left")
	for _frame: int in AUTO_WAIT_FRAMES:
		await physics_frame
	var slot: Node = main.get_node(^"%LevelSlot")
	var current: String = slot.get_child(0).name if slot.get_child_count() > 0 else "none"
	print("Phase in the level slot after walking left: %s" % current)
	quit(0 if current == "LustPhase3" else 1)
