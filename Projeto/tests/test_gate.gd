# Checks the gate and its unlocker. A shut gate stops the man. Far from the unlocker, its key does not show
# and Interact opens nothing; next to it, the key shows, and the crucifix raised there opens nothing, since the
# unlocker no longer answers it. Interact next to it opens every gate on its list, once, hides the key and
# leaves the unlocker where it was, its statue lit. The gate slides up by its own height in Slide Time, says so at
# the start and at the end, and the man then walks through. The size sets each instance alone, and the gate is
# on the world's layer, so demons stop at it and do not see through it. A trapdoor (Slide Way left or right)
# slides sideways by its width instead, and keeps its height. A gate put out of the way at once (open_now)
# says nothing, then lock() slides it back to its place in Slide Time, saying so at the start and at the end,
# and unlock() opens it again.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gate.gd
extends "res://tests/support/player_test.gd"

const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const UNLOCKER_SCENE: PackedScene = preload("res://scenes/objects/gates/gate_unlocker.tscn")
const TILE: float = 48.0
const FLOOR_LEFT: float = -4000.0
const FLOOR_RIGHT: float = 4000.0
## The gate's middle, and the unlocker's, far enough for its radius not to reach from the start.
const GATE_X: float = 300.0
const UNLOCKER_X: float = -400.0
## Where the man starts: between them, out of the unlocker's reach.
const START: Vector2 = Vector2(-50.0, -2.0)
## Where he stands to use the unlocker: inside its reach.
const NEAR_UNLOCKER_X: float = -300.0
const WORLD_LAYER: int = 1
## Frames to reach something at a run, and more.
const RUN_FRAMES: int = 120
## Frames the crucifix stays up, and frames given to a press of Interact.
const RAISED_FRAMES: int = 30
const PRESS_FRAMES: int = 5
## How far from the gate's face he may stop, in px.
const FACE_TOLERANCE: float = 2.0
## How long the slide may differ from Slide Time, in frames.
const SLIDE_TOLERANCE_FRAMES: int = 2
## A trapdoor across a drop, away from the floor the man runs on.
const TRAPDOOR_WIDTH: int = 5
const TRAPDOOR_AT: Vector2 = Vector2(0.0, -2000.0)
## A gate that locks, away from the rest.
const LOCKING_AT: Vector2 = Vector2(0.0, -4000.0)


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
	results.append(await _interact_far_from_the_unlocker_opens_nothing(gate, unlocker))
	results.append(await _the_crucifix_next_to_it_opens_nothing(gate, unlocker))
	results.append(await _next_to_it_it_opens_every_gate_and_the_man_walks_through(gate, other_gate, unlocker))
	results.append(_the_size_sets_each_gate_alone(gate))
	results.append(report(gate.collision_layer == WORLD_LAYER, "Layer: %d" % gate.collision_layer))
	results.append(await _a_trapdoor_slides_sideways_by_its_width(Gate.SlideWay.LEFT))
	results.append(await _a_trapdoor_slides_sideways_by_its_width(Gate.SlideWay.RIGHT))
	results.append(await _an_open_gate_locks_back_in_place())
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


func _interact_far_from_the_unlocker_opens_nothing(gate: Gate, unlocker: GateUnlocker) -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Far: the player never landed")
	var key_shows: bool = _key(unlocker).visible
	await _press_interact()
	await remove_player(player)
	return report(not key_shows and not unlocker.is_activated() and not gate.is_unlocked(),
			"Far: key shows %s, unlocker used %s, gate unlocked %s" % [key_shows, unlocker.is_activated(), gate.is_unlocked()])


func _the_crucifix_next_to_it_opens_nothing(gate: Gate, unlocker: GateUnlocker) -> bool:
	var player: Player = await spawn_on_floor(Vector2(NEAR_UNLOCKER_X, -2.0))
	if player == null:
		return report(false, "Crucifix: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(RAISED_FRAMES)
	var raised: bool = (player.get_node(^"Crucifix") as Crucifix).is_raised()
	stand_in.crucifix_held = false
	await remove_player(player)
	return report(raised and not unlocker.is_activated() and not gate.is_unlocked(),
			"Crucifix next to it: up %s, unlocker used %s, gate unlocked %s"
			% [raised, unlocker.is_activated(), gate.is_unlocked()])


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
	var statue: Sprite2D = unlocker.get_node(^"%Statue") as Sprite2D
	var unlit_before: bool = statue.frame == GateUnlocker.UNLIT_CELL
	var at: Vector2 = unlocker.position
	var stand_in: StandInInput = put_a_stand_in(player)
	await wait_frames(PRESS_FRAMES)
	var key_shows: bool = _key(unlocker).visible and unlocker.is_player_near()
	var start_frame: int = Engine.get_physics_frames()
	Input.action_press(&"interact")
	var used: bool = await wait_until(unlocker.is_activated, PRESS_FRAMES)
	Input.action_release(&"interact")
	var key_gone: bool = not _key(unlocker).visible
	var lit: bool = unlit_before and statue.frame >= GateUnlocker.FIRST_FLAME_CELL
	await wait_until(func() -> bool: return opened_frame[0] >= 0, RUN_FRAMES)
	var slide_frames: int = opened_frame[0] - start_frame
	var expected_frames: int = roundi(gate.slide_time * Engine.physics_ticks_per_second)
	var risen: float = closed_y - gate.position.y
	stand_in.run_direction = 1.0
	var through: bool = await wait_until(func() -> bool: return player.position.x > GATE_X + gate.width_tiles * TILE, RUN_FRAMES)
	await remove_player(player)
	var ok_slide: bool = absi(slide_frames - expected_frames) <= SLIDE_TOLERANCE_FRAMES + 1
	return report(key_shows and used and key_gone and lit and activations[0] == 1 and unlocks[0] == 1
			and other_gate.is_unlocked() and is_equal_approx(risen, gate.height_tiles * TILE) and ok_slide and through
			and unlocker.position == at,
			"Near: key shows %s, used with Interact %s, key gone %s, statue lit %s, %d activation(s), %d unlock(s), other gate %s, rose %.1f px, slid in %d frames (%d expected), walked through %s"
			% [key_shows, used, key_gone, lit, activations[0], unlocks[0], other_gate.is_unlocked(), risen, slide_frames,
			expected_frames, through])


## A press of Interact over a few frames, then let go.
func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_frames(PRESS_FRAMES)
	Input.action_release(&"interact")
	await physics_frame


func _key(unlocker: GateUnlocker) -> Node2D:
	return unlocker.get_node(^"%UseKey") as Node2D


## Put out of the way at once, it moves by its slide with no signal; lock() brings it back to its place in Slide
## Time, saying so at the start and at the end; unlock() opens it again.
func _an_open_gate_locks_back_in_place() -> bool:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = LOCKING_AT
	root.add_child(gate)
	var said: Array[String] = []
	for signal_name: String in ["unlocked", "opened", "locked", "shut"]:
		gate.connect(signal_name, func() -> void: said.append(signal_name))
	gate.open_now()
	var opened_at: Vector2 = gate.position
	var silent: bool = said.is_empty() and gate.is_unlocked()
	var start_frame: int = Engine.get_physics_frames()
	var shut_frame: Array[int] = [-1]
	gate.shut.connect(func() -> void: shut_frame[0] = Engine.get_physics_frames())
	gate.lock()
	var locked_at_once: bool = said == ["locked"] and not gate.is_unlocked()
	await wait_until(func() -> bool: return shut_frame[0] >= 0, RUN_FRAMES)
	var back: Vector2 = gate.position
	var slide_frames: int = shut_frame[0] - start_frame
	var expected_frames: int = roundi(gate.slide_time * Engine.physics_ticks_per_second)
	gate.unlock()
	var reopened: bool = await wait_until(func() -> bool: return said.has("opened"), RUN_FRAMES)
	var open_again: Vector2 = gate.position
	var offset: Vector2 = gate.slide_offset()
	gate.queue_free()
	var ok: bool = (opened_at.is_equal_approx(LOCKING_AT + offset) and silent and locked_at_once
			and back.is_equal_approx(LOCKING_AT) and absi(slide_frames - expected_frames) <= SLIDE_TOLERANCE_FRAMES + 1
			and reopened and open_again.is_equal_approx(LOCKING_AT + offset)
			and said == ["locked", "shut", "unlocked", "opened"])
	return report(ok, "Locking: open at once at %s with no signal %s, back at %s in %d frames (%d expected), open again at %s, said %s"
			% [opened_at, silent, back, slide_frames, expected_frames, open_again, said])


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
