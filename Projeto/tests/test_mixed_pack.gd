# Checks a pack of dogs of different sizes (#271): the gap between two dogs' bodies is Pack Spacing
# whatever the size of each, as between two of the same size. At a man standing still, a regular dog
# waits Pack Spacing behind the body of a big one at his side, and a big one Pack Spacing behind a
# regular one; one put with its body inside the other's steps back until the gap is Pack Spacing.
# Each dog took the other for one of its own size before, so with Pack Spacing at 24 a regular dog
# went through a big one at the man's side, not taking it for one at his side, and a big one stopped
# 38 px behind a regular one.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_mixed_pack.gd
extends "res://tests/support/player_test.gd"

const DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const BIG_DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/big_demon.tscn")
const PLAYER_LAYER_NAME: String = "player"
const ENEMY_LAYER_NAME: String = "enemy"
const PHYSICS_LAYERS: int = 32
const FLOOR_LEFT: float = -1000.0
const FLOOR_RIGHT: float = 2000.0
const SPAWN_Y: float = -2.0
## Where the man stands, inside every dog's Sight Distance.
const MAN_X: float = 300.0
## The level's Pack Spacing (lust_demon_stats.tres).
const PACK_SPACING: float = 24.0
const SIGHT_DISTANCE: float = 900.0
const LOSE_DISTANCE: float = 1400.0
const CHASE_SPEED: float = 300.0
## Where the second dog starts behind the first, so neither starts inside the other.
const SECOND_DOG_BEHIND: float = 260.0
## How deep inside the first dog's body the second is put, in the step-back cases.
const SECOND_DOG_INSIDE: float = 24.0
const FRAMES_TO_WATCH: int = 180
const GAP_TOLERANCE: float = 1.0


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _waits_pack_spacing_behind(DOG_SCENE, DOG_SCENE, "regular behind regular"))
	results.append(await _waits_pack_spacing_behind(BIG_DOG_SCENE, DOG_SCENE, "regular behind big"))
	results.append(await _waits_pack_spacing_behind(DOG_SCENE, BIG_DOG_SCENE, "big behind regular"))
	results.append(await _steps_back_to_pack_spacing(BIG_DOG_SCENE, DOG_SCENE, "regular inside big"))
	results.append(await _steps_back_to_pack_spacing(DOG_SCENE, BIG_DOG_SCENE, "big inside regular"))
	finish(results)


## A dog of front_scene at the side of a man standing still, its body solid to his, and one of
## back_scene coming after him from behind it: the second stops Pack Spacing behind the first's body,
## and is never nearer to it than that on the way.
func _waits_pack_spacing_behind(front_scene: PackedScene, back_scene: PackedScene,
		label: String) -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(MAN_X, SPAWN_Y))
	var front: Demon = await _spawn_dog(front_scene, 0.0)
	_make_the_bodies_solid(man, front)
	var back: Demon = await _spawn_dog(back_scene, -SECOND_DOG_BEHIND)
	var narrowest: float = INF
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		narrowest = minf(narrowest, _gap_between(front, back))
	var gap: float = _gap_between(front, back)
	await _clear([ground, man, front, back])
	return report(absf(gap - PACK_SPACING) <= GAP_TOLERANCE
			and narrowest >= PACK_SPACING - GAP_TOLERANCE,
			"%s, at a man standing still: %.1f px between their bodies (Pack Spacing %d), never under %.1f px"
			% [label.capitalize(), gap, PACK_SPACING, narrowest])


## A dog of front_scene at the side of a man standing still, its body solid to his, and one of
## back_scene put behind it with its body SECOND_DOG_INSIDE px inside the first's, as after crossing
## it: the second steps back until Pack Spacing is between their bodies.
func _steps_back_to_pack_spacing(front_scene: PackedScene, back_scene: PackedScene,
		label: String) -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(MAN_X, SPAWN_Y))
	var front: Demon = await _spawn_dog(front_scene, 0.0)
	_make_the_bodies_solid(man, front)
	await wait_frames(FRAMES_TO_WATCH)
	var touching: float = _half_width(front) + _half_width_of(back_scene)
	var back: Demon = await _spawn_dog(back_scene, front.position.x - touching + SECOND_DOG_INSIDE)
	await wait_frames(FRAMES_TO_WATCH)
	var gap: float = _gap_between(front, back)
	await _clear([ground, man, front, back])
	return report(absf(gap - PACK_SPACING) <= GAP_TOLERANCE,
			"%s, put %d px inside it at a man's side: %.1f px between their bodies after %d frames (Pack Spacing %d)"
			% [label.capitalize(), SECOND_DOG_INSIDE, gap, FRAMES_TO_WATCH, PACK_SPACING])


## A dog of scene at x with stats of its own: no attacks, the level's Pack Spacing, no pack
## variation, and its body not colliding with the man's. Comes back once it has landed.
func _spawn_dog(scene: PackedScene, x: float) -> Demon:
	var stats: DemonStats = DemonStats.new()
	stats.sight_distance = SIGHT_DISTANCE
	stats.lose_distance = LOSE_DISTANCE
	stats.chase_speed = CHASE_SPEED
	stats.pack_spacing = PACK_SPACING
	var dog: Demon = scene.instantiate() as Demon
	dog.stats = stats
	dog.position = Vector2(x, SPAWN_Y)
	dog.collision_mask &= ~_bit_of(PLAYER_LAYER_NAME)
	root.add_child(dog)
	await wait_until(dog.is_on_floor)
	return dog


## The gap between two dogs' bodies along the floor, under 0 when they overlap.
func _gap_between(one: Demon, other: Demon) -> float:
	return absf(one.position.x - other.position.x) - _half_width(one) - _half_width(other)


## Half the width of the dog's body box.
func _half_width(dog: Demon) -> float:
	return (dog.get_node(^"CollisionShape2D") as CollisionShape2D).shape.get_rect().size.x / 2.0


## Half the width of the body box of a dog of scene, read from a copy that is freed at once.
func _half_width_of(scene: PackedScene) -> float:
	var dog: Demon = scene.instantiate() as Demon
	var half: float = _half_width(dog)
	dog.free()
	return half


## Makes the man's body and the dog's collide with each other again, as in their scenes.
func _make_the_bodies_solid(man: Player, dog: Demon) -> void:
	man.collision_mask |= _bit_of(ENEMY_LAYER_NAME)
	dog.collision_mask |= _bit_of(PLAYER_LAYER_NAME)


func _bit_of(layer_name: String) -> int:
	for layer: int in range(1, PHYSICS_LAYERS + 1):
		if ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % layer, "") == layer_name:
			return 1 << (layer - 1)
	return 0


## Takes out what a case made at the end of the frame, and waits for it.
func _clear(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame
