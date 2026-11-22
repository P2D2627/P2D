# Checks where a gate's door and front pillar go in a level with a Gate Fronts node (#284). With two levels
# in the tree, as when a test, a measure or a menu backdrop holds one beside the game's, each standing gate
# puts its door and pillar under its own level's Gate Fronts, drawn where its art is. A gate freed on its
# own takes its door and pillar with it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gate_fronts.gd
extends "res://tests/support/base_test.gd"

const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
## How far a drawn point may be from where it belongs, in px.
const TOLERANCE: float = 0.5
## Frames for the gates to build their art and move their fronts.
const SETUP_FRAMES: int = 3


func _initialize() -> void:
	var results: Array[bool] = []
	var first: Node2D = _make_level("FirstLevel", Vector2(300.0, 600.0))
	var second: Node2D = _make_level("SecondLevel", Vector2(2000.0, 900.0))
	for _frame: int in SETUP_FRAMES:
		await process_frame
	results.append(_fronts_in_its_own_level(first))
	results.append(_fronts_in_its_own_level(second))
	var gate: Gate = first.get_node(^"Gate") as Gate
	gate.queue_free()
	for _frame: int in SETUP_FRAMES:
		await process_frame
	var left: int = first.get_node(^"GateFronts").get_child_count()
	results.append(report(left == 0, "A gate freed on its own leaves %d holders in its level's Gate Fronts" % left))
	first.queue_free()
	second.queue_free()
	await process_frame
	quit(0 if not results.has(false) else 1)


## A level as level 1 is laid out: its Gate Fronts after its gates, one standing gate at gate_at.
func _make_level(level_name: String, gate_at: Vector2) -> Node2D:
	var level := Node2D.new()
	level.name = level_name
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.name = "Gate"
	gate.position = gate_at
	gate.slide_way = Gate.SlideWay.UP
	level.add_child(gate)
	var fronts := Node2D.new()
	fronts.name = "GateFronts"
	fronts.add_to_group(GateArt.FRONTS_GROUP)
	level.add_child(fronts)
	root.add_child(level)
	return level


func _fronts_in_its_own_level(level: Node2D) -> bool:
	var art: GateArt = level.get_node(^"Gate/%Art") as GateArt
	var fronts: Node = level.get_node(^"GateFronts")
	var back: Sprite2D = art.get_frame_layers()[0]
	var problems: Array[String] = []
	for layer: Sprite2D in [art.get_door(), art.get_frame_layers()[1]]:
		if not fronts.is_ancestor_of(layer):
			problems.append("%s under %s" % [layer.texture.resource_path.get_file(), layer.get_parent().get_path()])
		if layer.global_position.distance_to(back.global_position) > TOLERANCE:
			problems.append("%s at %s, the art at %s" % [layer.texture.resource_path.get_file(),
					layer.global_position, back.global_position])
	return report(problems.is_empty(), "%s: the door and the front pillar under its own Gate Fronts, where its art is; wrong: %s"
			% [level.name, problems])


func report(passed: bool, what: String) -> bool:
	print(("PASS: " if passed else "FAIL: ") + what)
	return passed
