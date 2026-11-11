# Plays level 1's phase 3 with the real man, without the dogs, from its S: to unlocker 1, through gate 2 to unlocker 2,
# through gate 1 down to the way out at F, along the moves the paper check found (support/level1_phase3_route.json,
# made by verificar_f3.py, outside the repository). See support/route_test.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_phase3_route.gd
extends "res://tests/support/route_test.gd"

const SCENE_PATH: String = "res://levels/lust/level1.tscn"
const ROUTE_PATH: String = "res://tests/support/level1_phase3_route.json"
## With these events the level starts at phase 3's S, and Velvet does not stop the man to talk.
const EVENTS: Array[StringName] = [&"velvet_met", &"tutorial_done", &"lust_phase_2_reached", &"lust_phase_3_reached"]


func _initialize() -> void:
	# The GameState autoload joins the tree on the first frame.
	await process_frame
	var progress: GameProgress = root.get_node(^"GameState") as GameProgress
	for event: StringName in EVENTS:
		progress.mark_event(event)
	await replay(SCENE_PATH, ROUTE_PATH)


func prepare_level(level: Node) -> void:
	super(level)
	level.get_node("Tutorial/BlockerDemon").free()
