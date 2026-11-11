# Checks the gate and its unlocker. A shut gate stops the man. The crucifix raised far from the unlocker
# opens nothing; raised next to it, it opens every gate on its list, once, and leaves the unlocker where
# it was and darker. The gate slides up by its own height in Slide Time, says so at the start and at the
# end, and the man then walks through. The size sets each instance alone, and the gate is on the world's
# layer, so demons stop at it and do not see through it. A trapdoor (Slide Way left or right) slides sideways
# by its width instead, and keeps its height.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gate.gd
extends "res://tests/support/player_test.gd"

const GATE_SCENE: PackedScene = preload("res://gates/gate.tscn")
const UNLOCKER_SCENE: PackedScene = preload("res://gates/gate_unlocker.tscn")
const TILE: float = 48.0
const FLOOR_LEFT: float = -4000.0
const FLOOR_RIGHT: float = 4000.0
## The gate's middle, and the unlocker's, far enough for its radius not to reach from the start.
const GATE_X: float = 300.0
const UNLOCKER_X: float = -400.0
## Where the man starts: between them, out of the crucifix's radius of either.
const START: Vector2 = Vector2(-50.0, -2.0)
## Where he stands to use the unlocker: inside the radius.
const NEAR_UNLOCKER_X: float = -300.0
const WORLD_LAYER: int = 1
## Frames to reach something at a run, and more.
const RUN_FRAMES: int = 120
## Frames the crucifix stays up in the far case.
const RAISED_FRAMES: int = 30
## How far from the gate's face he may stop, in px.
const FACE_TOLERANCE: float = 2.0
## How long the slide may differ from Slide Time, in frames.
const SLIDE_TOLERANCE_FRAMES: int = 2
## A trapdoor across a drop, away from the floor the man runs on.
const TRAPDOOR_WIDTH: int = 5
const TRAPDOOR_AT: Vector2 = Vector2(0.0, -2000.0)


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	var gate: Gate = _make_gate(GATE_X)
	var other_gate: Gate = _make_gate(FLOOR_RIGHT - TILE)
	var unlocker: GateUnlocker = UNLOCKER_SCENE.instantiate() as GateUnlocker
	unlocker.position = Vector2(UNLOCKER_X, 0.0)
	unlocker.gates = [gate, other_gate] as Array[Gate]
	root.add_child(unlocker)
	await physics_frame
	results.append(await _a_shut_gate_stops_the_man(gate))
	results.append(await _the_crucifix_far_from_the_unlocker_opens_nothing(gate, unlocker))
	results.append(await _next_to_it_it_opens_every_gate_and_the_man_walks_through(gate, other_gate, unlocker))
	results.append(_the_size_sets_each_gate_alone(gate))
	results.append(report(gate.collision_layer == WORLD_LAYER, "Layer: %d" % gate.collision_layer))
	results.append(await _a_trapdoor_slides_sideways_by_its_width(Gate.SlideWay.LEFT))
	results.append(await _a_trapdoor_slides_sideways_by_its_width(Gate.SlideWay.RIGHT))
	finish(results)


func _make_gate(x: float) -> Gate:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = Vector2(x, 0.0)
	root.add_child(gate)
	return gate


func _a_shut_gate_stops_the_man(gate: Gate) -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Shut: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	var face: float = GATE_X - gate.width_tiles * TILE / 2.0 - body_size(player).x / 2.0
	var stopped_at: float = player.position.x
	await remove_player(player)
	return report(absf(stopped_at - face) <= FACE_TOLERANCE, "Shut: he stops at x %.1f, the gate's face is at x %.1f"
			% [stopped_at, face])


func _the_crucifix_far_from_the_unlocker_opens_nothing(gate: Gate, unlocker: GateUnlocker) -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Far: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(RAISED_FRAMES)
	var raised: bool = (player.get_node(^"Crucifix") as Crucifix).is_raised()
	await remove_player(player)
	return report(raised and not unlocker.is_activated() and not gate.is_unlocked(),
			"Far: crucifix up %s, unlocker used %s, gate unlocked %s" % [raised, unlocker.is_activated(), gate.is_unlocked()])


func _next_to_it_it_opens_every_gate_and_the_man_walks_through(gate: Gate, other_gate: Gate,
		unlocker: GateUnlocker) -> bool:
	var player: Player = await spawn_on_floor(Vector2(NEAR_UNLOCKER_X, -2.0))
	if player == null:
		return report(false, "Near: the player never landed")
	var activations: Array[int] = [0]
	var unlocks: Array[int] = [0]
	var opened_frame: Array[int] = [-1]
	unlocker.activated.connect(func() -> void: activations[0] += 1)
	gate.unlocked.connect(func() -> void: unlocks[0] += 1)
	gate.opened.connect(func() -> void: opened_frame[0] = Engine.get_physics_frames())
	var closed_y: float = gate.position.y
	var idle: Color = unlocker.idle_color
	var at: Vector2 = unlocker.position
	var stand_in: StandInInput = put_a_stand_in(player)
	var start_frame: int = Engine.get_physics_frames()
	stand_in.crucifix_held = true
	var used: bool = await wait_until(unlocker.is_activated, RAISED_FRAMES)
	var drawing: Polygon2D = unlocker.get_node(^"%Drawing") as Polygon2D
	var darker: bool = drawing.color.v < idle.v
	await wait_until(func() -> bool: return opened_frame[0] >= 0, RUN_FRAMES)
	var slide_frames: int = opened_frame[0] - start_frame
	var expected_frames: int = roundi(gate.slide_time * Engine.physics_ticks_per_second)
	var risen: float = closed_y - gate.position.y
	stand_in.crucifix_held = false
	stand_in.run_direction = 1.0
	var through: bool = await wait_until(func() -> bool: return player.position.x > GATE_X + gate.width_tiles * TILE, RUN_FRAMES)
	await remove_player(player)
	var ok_slide: bool = absi(slide_frames - expected_frames) <= SLIDE_TOLERANCE_FRAMES + 1
	return report(used and darker and activations[0] == 1 and unlocks[0] == 1 and other_gate.is_unlocked()
			and is_equal_approx(risen, gate.height_tiles * TILE) and ok_slide and through and unlocker.position == at,
			"Near: used %s, darker %s, %d activation(s), %d unlock(s), other gate %s, rose %.1f px, slid in %d frames (%d expected), walked through %s"
			% [used, darker, activations[0], unlocks[0], other_gate.is_unlocked(), risen, slide_frames, expected_frames, through])


## A gate lying across a drop, five tiles wide and one high, slides sideways by its width and stays at its height.
func _a_trapdoor_slides_sideways_by_its_width(way: Gate.SlideWay) -> bool:
	var trapdoor: Gate = GATE_SCENE.instantiate() as Gate
	trapdoor.width_tiles = TRAPDOOR_WIDTH
	trapdoor.height_tiles = 1
	trapdoor.slide_way = way
	trapdoor.position = TRAPDOOR_AT
	root.add_child(trapdoor)
	var opened: Array[bool] = [false]
	trapdoor.opened.connect(func() -> void: opened[0] = true)
	trapdoor.unlock()
	await wait_until(func() -> bool: return opened[0], RUN_FRAMES)
	var moved: Vector2 = trapdoor.position - TRAPDOOR_AT
	trapdoor.queue_free()
	var side: float = -1.0 if way == Gate.SlideWay.LEFT else 1.0
	var expected: Vector2 = Vector2(side * TRAPDOOR_WIDTH * TILE, 0.0)
	return report(opened[0] and moved.is_equal_approx(expected), "Trapdoor %s: opened %s, moved %s, %s expected"
			% [Gate.SlideWay.keys()[way], opened[0], moved, expected])


func _the_size_sets_each_gate_alone(gate: Gate) -> bool:
	var other: Gate = GATE_SCENE.instantiate() as Gate
	other.width_tiles = 1
	other.height_tiles = 6
	root.add_child(other)
	var size: Vector2 = (other.get_node(^"%Shape").shape as RectangleShape2D).size
	var own: Vector2 = (gate.get_node(^"%Shape").shape as RectangleShape2D).size
	other.queue_free()
	return report(size == Vector2(TILE, 6.0 * TILE) and own == Vector2(gate.width_tiles, gate.height_tiles) * TILE,
			"Size: %s for one, %s for the other" % [size, own])
