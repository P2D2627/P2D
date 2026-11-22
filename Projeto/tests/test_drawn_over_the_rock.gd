# Checks what level 1 draws against its rock with the lighting rig and its depth on, as the game shows it
# (#284). The rig raises the rock's tiles and the stone rim to Z Index 1. A spike strip turned onto a wall
# or a ceiling is drawn over both, so its brambles show off the face; an upright one, on a floor, below
# both, so it grows from between the stones. A gate statue's key, which stands over the statue and in a
# low room reaches into the rock above, is drawn over both, so it shows wherever the room ends. A gate
# that stands as a door has the man and the dogs between its frame's layers: its back post below them,
# its door and front pillar over them, drawn where the back post is, and all three below the rock and the
# rim, which hide what of the door stands above the gate. A trapdoor keeps its door, under the man. While the gate slides into the rock, the door and the pillar stay where
# they barred the passage, as the back post does.
# Drawn over means a higher Z Index, counted up through the parents that pass theirs on, or the same and
# later in the tree.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_drawn_over_the_rock.gd
extends "res://tests/support/base_test.gd"

const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")
const ROOM: PackedScene = preload("res://scenes/levels/prototypes/lighting/lighting_level1.tscn")
## Frames for the level and the rig to set up.
const SETUP_FRAMES: int = 10
## How far a door's layer may be drawn from its back post, in px.
const PLACE_TOLERANCE: float = 0.5


func _initialize() -> void:
	LightingRig.depth_on = true
	var room: Node = ROOM.instantiate()
	root.add_child(room)
	for _frame: int in SETUP_FRAMES:
		await process_frame
	var level: Node = (room.get_rig() as Node).get_parent()
	var rock: Array[CanvasItem] = [level.get_node(^"Tiles") as CanvasItem,
			level.get_node(^"Art/StoneRim") as CanvasItem]
	var results: Array[bool] = []
	results.append(_spikes_against_the_rock(level.get_node(^"Spikes"), rock))
	results.append(_statue_keys_over_the_rock(level.get_node(^"GateUnlockers"), rock))
	var characters: Array[CanvasItem] = [level.get_node(^"Player") as CanvasItem]
	for dog: Node in level.get_node(^"Dogs").get_children():
		if dog is CanvasItem:
			characters.append(dog as CanvasItem)
	results.append(_doors_round_the_characters(level.get_node(^"Gates"), characters, rock))
	results.append(await _a_door_stays_in_place_as_its_gate_slides(level.get_node(^"Gates/GateA") as Gate))
	room.queue_free()
	await process_frame
	quit(0 if not results.has(false) else 1)


func _spikes_against_the_rock(spikes: Node, rock: Array[CanvasItem]) -> bool:
	var turned: int = 0
	var upright: int = 0
	var wrong: Array[String] = []
	for child: Node in spikes.get_children():
		var strip := child as LethalSpikes
		if strip == null:
			continue
		var is_turned: bool = not is_zero_approx(wrapf(strip.rotation, -PI, PI))
		if is_turned:
			turned += 1
		else:
			upright += 1
		if is_turned != _over_all(strip, rock) or (not is_turned and _over_any(strip, rock)):
			wrong.append("%s (%s, Z Index %d)" % [strip.name, "turned" if is_turned else "upright", strip.z_index])
	return report(turned > 0 and upright > 0 and wrong.is_empty(),
			"Spikes: %d turned onto a wall or a ceiling over the rock and the rim, %d upright below both; wrong: %s"
			% [turned, upright, wrong])


func _statue_keys_over_the_rock(unlockers: Node, rock: Array[CanvasItem]) -> bool:
	var keys: int = 0
	var under: Array[String] = []
	for child: Node in unlockers.get_children():
		var unlocker := child as GateUnlocker
		if unlocker == null:
			continue
		keys += 1
		var key: CanvasItem = unlocker.get_node(^"%UseKey") as CanvasItem
		if not _over_all(key, rock):
			under.append("%s (Z Index %d)" % [unlocker.name, _absolute_z(key)])
	return report(keys > 0 and under.is_empty(),
			"Gate statues: the key of each of %d drawn over the rock and the rim; under them: %s" % [keys, under])


func _doors_round_the_characters(gates: Node, characters: Array[CanvasItem], rock: Array[CanvasItem]) -> bool:
	var doors: int = 0
	var trapdoors: int = 0
	var wrong: Array[String] = []
	for child: Node in gates.get_children():
		var gate := child as Gate
		if gate == null:
			continue
		var art: GateArt = gate.get_node(^"%Art") as GateArt
		if gate.slide_way != Gate.SlideWay.UP:
			trapdoors += 1
			if art.get_door().get_parent() != art:
				wrong.append("%s: the trapdoor's door left the gate, for %s" % [gate.name, art.get_door().get_parent().name])
			continue
		doors += 1
		var layers: Array[Sprite2D] = art.get_frame_layers()
		var back: Sprite2D = layers[0]
		var in_front: Array[Sprite2D] = [art.get_door(), layers[1]]
		var problems: Array[String] = []
		for layer: Sprite2D in in_front:
			if layer.global_position.distance_to(back.global_position) > PLACE_TOLERANCE:
				problems.append("%s at %s, the back post at %s" % [layer.texture.resource_path.get_file(),
						layer.global_position, back.global_position])
		for character: CanvasItem in characters:
			if _drawn_over(back, character):
				problems.append("back post over %s" % character.name)
			for layer: Sprite2D in in_front:
				if not _drawn_over(layer, character):
					problems.append("%s under %s" % [layer.texture.resource_path.get_file(), character.name])
		for layer: Sprite2D in [back, in_front[0], in_front[1]]:
			if _over_any(layer, rock):
				problems.append("%s over the rock" % layer.texture.resource_path.get_file())
		if not problems.is_empty():
			wrong.append("%s: %s" % [gate.name, ", ".join(problems.slice(0, 3))])
	return report(doors > 0 and trapdoors > 0 and wrong.is_empty(),
			("Doors: %d with the door and the front pillar drawn where the back post is, the back post under the man "
			+ "and the dogs, the door and the pillar over them, all under the rock; %d trapdoors keep their door; "
			+ "wrong: %s") % [doors, trapdoors, wrong])


func _a_door_stays_in_place_as_its_gate_slides(gate: Gate) -> bool:
	var art: GateArt = gate.get_node(^"%Art") as GateArt
	var layers: Array[Sprite2D] = [art.get_door()]
	layers.append_array(art.get_frame_layers())
	var before: Array[Vector2] = []
	for layer: Sprite2D in layers:
		before.append(layer.global_position)
	gate.unlock()
	for _step: int in roundi(gate.slide_time * Engine.physics_ticks_per_second / 2.0):
		await physics_frame
	var moved: Array[float] = []
	for k: int in layers.size():
		moved.append(snappedf(layers[k].global_position.distance_to(before[k]), 0.1))
	var slid: float = absf(gate.global_position.y - before[0].y)
	return report(moved.all(func(px: float) -> bool: return px <= 0.5) and slid > 0.0,
			"%s mid-slide: the door, back post and front pillar moved %s px; the gate's body %.1f px from the door"
			% [gate.name, moved, slid])


## True when item is drawn over every one of items.
static func _over_all(item: CanvasItem, items: Array[CanvasItem]) -> bool:
	for other: CanvasItem in items:
		if not _drawn_over(item, other):
			return false
	return true


## True when item is drawn over any one of items.
static func _over_any(item: CanvasItem, items: Array[CanvasItem]) -> bool:
	for other: CanvasItem in items:
		if _drawn_over(item, other):
			return true
	return false


## True when a is drawn over b on the same canvas: a higher Z Index, counted up through the parents
## that pass theirs on, or the same and later in the tree.
static func _drawn_over(a: CanvasItem, b: CanvasItem) -> bool:
	var z_a: int = _absolute_z(a)
	var z_b: int = _absolute_z(b)
	return z_a > z_b or (z_a == z_b and a.is_greater_than(b))


## The item's Z Index with those of the parents it counts from, while each counts from its parent.
static func _absolute_z(item: CanvasItem) -> int:
	var z: int = item.z_index
	var current: CanvasItem = item
	while current.z_as_relative and current.get_parent() is CanvasItem:
		current = current.get_parent() as CanvasItem
		z += current.z_index
	return z


func report(passed: bool, what: String) -> bool:
	print(("PASS: " if passed else "FAIL: ") + what)
	return passed
