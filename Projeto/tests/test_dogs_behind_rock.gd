# Checks that no dog is drawn in front of the rock (#271), on level 1 with the lighting rig and its
# depth on, as the game shows it: a dog at rest, and one raised as it warns, lunges or holds the man,
# is drawn below the rock's tiles and the stone rim, so a tail against a wall and a dog that pulls the
# man down stay behind the rock. What the raise is for still holds: the raised dog is drawn over the
# man and over a dog at rest (ADR 0053). And what was over the rock stays there: a dog's alert mark
# and the spikes. The man stays before the dogs in the tree, so he moves first on each physics frame,
# as the bite on a dog's back counts on (DemonBackBite). Drawn over means a higher Z Index, counted up through the parents that pass theirs
# on, or the same and later in the tree. A dog's art takes its stand-in's Z Index on every frame drawn
# (DemonPlaceholder), so the stand-in stands for the art here, as the dogs far from the man sleep.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dogs_behind_rock.gd
extends "res://tests/support/base_test.gd"

const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")
const ROOM: PackedScene = preload("res://scenes/levels/prototypes/lighting/lighting_level1.tscn")
## Frames for the level and the rig to set up.
const SETUP_FRAMES: int = 10
const RAISED_STATES: Array[Demon.State] = [Demon.State.WARNING, Demon.State.LUNGE, Demon.State.GRAB]


func _initialize() -> void:
	LightingRig.depth_on = true
	var room: Node = ROOM.instantiate()
	root.add_child(room)
	for _frame: int in SETUP_FRAMES:
		await process_frame
	var level: Node = (room.get_rig() as Node).get_parent()
	var tiles: CanvasItem = level.get_node(^"Tiles") as CanvasItem
	var rim: CanvasItem = level.get_node(^"Art/StoneRim") as CanvasItem
	var man: CanvasItem = level.get_node(^"Player") as CanvasItem
	var dogs: Node = level.get_node(^"Dogs")
	var raised_dog: Demon = dogs.get_child(0) as Demon
	var resting_dog: Demon = dogs.get_child(1) as Demon
	var raised: DemonPlaceholder = raised_dog.get_node(^"Placeholder") as DemonPlaceholder
	var resting: DemonPlaceholder = resting_dog.get_node(^"Placeholder") as DemonPlaceholder
	var spike: CanvasItem = _first_spike(level.get_node(^"Spikes"))
	var mark: CanvasItem = resting_dog.get_node(^"Mark") as CanvasItem
	var results: Array[bool] = []
	results.append(report(_drawn_over(tiles, resting) and _drawn_over(rim, resting),
			"A dog at rest: below the rock's tiles %s and the rim %s"
			% [_drawn_over(tiles, resting), _drawn_over(rim, resting)]))
	for state: Demon.State in RAISED_STATES:
		raised._on_demon_state_changed(Demon.State.CHASE, state)
		var below_rock: bool = _drawn_over(tiles, raised) and _drawn_over(rim, raised)
		var over_the_rest: bool = _drawn_over(raised, man) and _drawn_over(raised, resting)
		results.append(report(below_rock and over_the_rest,
				"A dog raised in %s (Z Index %d): below the rock's tiles and the rim %s; over the man and a dog at rest %s"
				% [Demon.State.keys()[state], raised.z_index, below_rock, over_the_rest]))
	raised._on_demon_state_changed(Demon.State.GRAB, Demon.State.CHASE)
	results.append(report(dogs.is_greater_than(man),
			"The man before the dogs in the tree, so he moves first on each physics frame (DemonBackBite): %s"
			% dogs.is_greater_than(man)))
	results.append(report(_drawn_over(mark, tiles) and _drawn_over(mark, rim)
			and spike != null and _drawn_over(spike, tiles),
			"Over the rock still: a dog's alert mark %s, the spikes %s"
			% [_drawn_over(mark, tiles) and _drawn_over(mark, rim),
					spike != null and _drawn_over(spike, tiles)]))
	room.queue_free()
	await process_frame
	var passed: bool = not results.has(false)
	quit(0 if passed else 1)


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


## The first drawn spike under spikes, or null.
static func _first_spike(spikes: Node) -> CanvasItem:
	for child: Node in spikes.get_children():
		if child is CanvasItem:
			return child as CanvasItem
	return null


func report(passed: bool, what: String) -> bool:
	print(("PASS: " if passed else "FAIL: ") + what)
	return passed
