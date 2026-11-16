# Prints what SightReveal costs on a frame (#253). First in the game's level 1, with the man where
# it starts him and its demons on patrol: every reveal it holds, and how many still look, since
# spikes once seen stop. Then the worst case, what stays hidden, where each look casts a ray to every
# spot across the box and a demon asks its senses as well: the game's demons (demon.tscn, standing
# still) and spikes (lethal_spikes.tscn, four tiles wide) behind a wall from the man, half and half,
# 40 and then 200 of them; and then 40 demons in plain sight, which stop at the first spot they see.
# Each cost is what the reveals add to the same room: it is measured with them on and with them
# off, and the difference printed, on average and on the worst frame, for the physics scripts (the
# rays) and the process scripts (the fades), each timed between two Stamps.
# It checks nothing: the exit code is 1 only if the man never lands. The README quotes the result.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_sight_reveal.gd
extends "res://tests/support/player_test.gd"


## Stamps the time of its own _physics_process, or of its own _process. With the lowest priority it
## runs before every other node's, and with the highest after them all.
class Stamp extends Node:
	var usec: int = 0
	var _physics: bool

	func _init(priority: int, physics: bool) -> void:
		_physics = physics
		if physics:
			process_physics_priority = priority
		else:
			process_priority = priority

	func _ready() -> void:
		set_physics_process(_physics)
		set_process(not _physics)

	func _physics_process(_delta: float) -> void:
		usec = Time.get_ticks_usec()

	func _process(_delta: float) -> void:
		usec = Time.get_ticks_usec()


## What a measure found, in us per frame.
class Cost:
	var physics: float = 0.0
	var worst_physics: float = 0.0
	var process: float = 0.0
	var worst_process: float = 0.0


const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const DEMON_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
## How many hidden things in each hidden measure, half demons and half spikes.
const HIDDEN_COUNTS: Array[int] = [40, 200]
const SEEN_DEMONS: int = 40
## Frames measured with the reveals on, and as many with them off.
const MEASURED_FRAMES: int = 300
## Frames for the scene to settle before measuring.
const SETTLE_FRAMES: int = 30
## Px between two things in a row, starting this far from the man, who stands at x = 0.
const SPACING: float = 20.0
const FIRST_X: float = 300.0
const STAMP_PRIORITY: int = 1000000

var _physics_first: Stamp
var _physics_last: Stamp
var _process_first: Stamp
var _process_last: Stamp


func _initialize() -> void:
	_physics_first = _stamp(-STAMP_PRIORITY, true)
	_physics_last = _stamp(STAMP_PRIORITY, true)
	_process_first = _stamp(-STAMP_PRIORITY, false)
	_process_last = _stamp(STAMP_PRIORITY, false)
	await _measure_level_1()
	make_platform(-10000.0, 10000.0)
	make_wall(200.0, 240.0, -2000.0)
	var player: Player = await spawn_on_floor(Vector2(0.0, -10.0))
	if player == null:
		print("The man never landed")
		quit(1)
		return
	for count: int in HIDDEN_COUNTS:
		var things: Array[Node2D] = []
		for i: int in count:
			var x: float = FIRST_X + i * SPACING
			things.append(_add_demon(x) if i % 2 == 0 else _add_spikes(x))
		var cost: Cost = await _reveals_cost(things)
		var spikes: int = floori(count / 2.0)
		print(("%d hidden behind a wall (%d demons, %d spikes): the reveals add %.0f us on average "
				+ "and %.0f us on the worst frame to the physics scripts, and %.0f and %.0f us to the "
				+ "process scripts") % [count, count - spikes, spikes, cost.physics,
				cost.worst_physics, cost.process, cost.worst_process])
		await _remove(things)
	var seen: Array[Node2D] = []
	for i: int in SEEN_DEMONS:
		seen.append(_add_demon(-FIRST_X - i * SPACING))
	var seen_cost: Cost = await _reveals_cost(seen)
	print(("%d demons in plain sight: the reveals add %.0f us on average and %.0f us on the worst "
			+ "frame to the physics scripts, and %.0f and %.0f us to the process scripts")
			% [SEEN_DEMONS, seen_cost.physics, seen_cost.worst_physics, seen_cost.process,
			seen_cost.worst_process])
	await _remove(seen)
	quit(0)


## The game's level 1, with the screen at the viewport's size, as in test_level1.gd: every reveal in
## it, measured where the level starts the man, after the spikes he sees have settled.
func _measure_level_1() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	var reveals: Array[SightReveal] = []
	for node: Node in level.find_children("SightReveal", "", true, false):
		if node is SightReveal:
			reveals.append(node as SightReveal)
	var demons: int = 0
	for reveal: SightReveal in reveals:
		if reveal.senses != null:
			demons += 1
	await wait_frames(SETTLE_FRAMES)
	var looking: Array[SightReveal] = []
	for reveal: SightReveal in reveals:
		if reveal.is_physics_processing():
			looking.append(reveal)
	var cost: Cost = await _cost_of(looking)
	print(("Level 1, the man at its start: %d reveals (%d demons, %d spikes), %d still looking; "
			+ "they add %.0f us on average and %.0f us on the worst frame to the physics scripts, "
			+ "and %.0f and %.0f us to the process scripts") % [reveals.size(), demons,
			reveals.size() - demons, looking.size(), cost.physics, cost.worst_physics, cost.process,
			cost.worst_process])
	level.queue_free()
	await physics_frame
	await physics_frame


## What the things' reveals add: the room measured with them on, less the room with them off.
func _reveals_cost(things: Array[Node2D]) -> Cost:
	await wait_frames(SETTLE_FRAMES)
	var reveals: Array[SightReveal] = []
	for thing: Node2D in things:
		reveals.append(thing.get_node("SightReveal") as SightReveal)
	return await _cost_of(reveals)


## What the reveals add: the room measured with them on, less the room with them off.
func _cost_of(reveals: Array[SightReveal]) -> Cost:
	var on: Cost = await _measure()
	_set_reveals(reveals, false)
	var off: Cost = await _measure()
	_set_reveals(reveals, true)
	var cost: Cost = Cost.new()
	cost.physics = on.physics - off.physics
	cost.worst_physics = on.worst_physics - off.worst_physics
	cost.process = on.process - off.process
	cost.worst_process = on.worst_process - off.worst_process
	return cost


## The physics and process scripts' time between the Stamps, over MEASURED_FRAMES frames. Each read
## runs as a frame's processing starts, when its physics has run and the frame before has run whole.
func _measure() -> Cost:
	var cost: Cost = Cost.new()
	await process_frame
	for _frame: int in MEASURED_FRAMES:
		await process_frame
		var physics: float = _physics_last.usec - _physics_first.usec
		var process: float = _process_last.usec - _process_first.usec
		cost.physics += physics / MEASURED_FRAMES
		cost.worst_physics = maxf(cost.worst_physics, physics)
		cost.process += process / MEASURED_FRAMES
		cost.worst_process = maxf(cost.worst_process, process)
	return cost


func _set_reveals(reveals: Array[SightReveal], on: bool) -> void:
	for reveal: SightReveal in reveals:
		reveal.set_physics_process(on)
		reveal.set_process(on)


## The game's demon on the floor at x, standing still: its own physics is off, so only its reveal
## and what draws it run.
func _add_demon(x: float) -> Node2D:
	var demon: Node2D = DEMON_SCENE.instantiate() as Node2D
	demon.position = Vector2(x, 0.0)
	root.add_child(demon)
	demon.set_physics_process(false)
	return demon


## The game's spikes, four tiles wide, on the floor at x.
func _add_spikes(x: float) -> Node2D:
	var spikes: Node2D = SPIKES_SCENE.instantiate() as Node2D
	spikes.position = Vector2(x, 0.0)
	spikes.set("width_tiles", 4)
	root.add_child(spikes)
	return spikes


func _stamp(priority: int, physics: bool) -> Stamp:
	var stamp: Stamp = Stamp.new(priority, physics)
	root.add_child(stamp)
	return stamp


func _remove(things: Array[Node2D]) -> void:
	for thing: Node2D in things:
		thing.queue_free()
	await physics_frame
	await physics_frame
