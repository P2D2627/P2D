# Checks level 1's biggest dog and the ring that opens a gate when the man comes near. The ring alone: the man
# outside it opens nothing; walking inside it opens every gate on its list, once, and leaving and coming back opens
# nothing more. The biggest dog: the regular dog with its body, hit box, art and checks eight times their size, a
# ring around his middle, and the gates set on him (Opens) handed to that ring.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_biggest_dog.gd
extends "res://tests/support/player_test.gd"

const RING_SCENE: PackedScene = preload("res://scenes/objects/gates/proximity_unlocker.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
## How many times the regular dog's size the biggest is.
const SIZE: float = 8.0
const FLOOR_LEFT: float = -3000.0
const FLOOR_RIGHT: float = 3000.0
## The ring's middle, a little over the floor, and its reach.
const RING_AT: Vector2 = Vector2(0.0, -60.0)
const REACH: float = 300.0
## Where the man waits outside the ring, and where he stands inside it.
const OUTSIDE_X: float = 700.0
const INSIDE_X: float = 150.0
## Frames for the ring to see him, and for nothing to happen.
const AREA_FRAMES: int = 5
const WAIT: int = 30


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _the_ring_opens_its_gates_once_the_man_comes_inside())
	results.append(_the_biggest_dog_is_the_dog_eight_times_over())
	results.append(await _the_biggest_dog_hands_his_gates_to_his_ring())
	finish(results)


func _the_ring_opens_its_gates_once_the_man_comes_inside() -> bool:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = Vector2(FLOOR_RIGHT - 200.0, 0.0)
	root.add_child(gate)
	var ring: ProximityUnlocker = RING_SCENE.instantiate() as ProximityUnlocker
	ring.position = RING_AT
	ring.reach = REACH
	ring.gates = [gate] as Array[Gate]
	root.add_child(ring)
	var activations: Array[int] = [0]
	ring.activated.connect(func() -> void: activations[0] += 1)
	var player: Player = await spawn_on_floor(Vector2(OUTSIDE_X, -2.0))
	if player == null:
		return report(false, "Ring: the player never landed")
	await wait_frames(WAIT)
	var shut_outside: bool = not gate.is_unlocked() and activations[0] == 0
	player.global_position = Vector2(INSIDE_X, -2.0)
	await wait_frames(AREA_FRAMES)
	var opened_inside: bool = gate.is_unlocked() and activations[0] == 1
	player.global_position = Vector2(OUTSIDE_X, -2.0)
	await wait_frames(AREA_FRAMES)
	player.global_position = Vector2(INSIDE_X, -2.0)
	await wait_frames(AREA_FRAMES)
	var radius: float = ((ring.get_node(^"%Shape") as CollisionShape2D).shape as CircleShape2D).radius
	await remove_player(player)
	ring.queue_free()
	gate.queue_free()
	return report(shut_outside and opened_inside and activations[0] == 1 and is_equal_approx(radius, REACH),
			"Ring: shut while he is outside %s, open once he is inside %s, %d activation(s), radius %.0f"
			% [shut_outside, opened_inside, activations[0], radius])


func _the_biggest_dog_is_the_dog_eight_times_over() -> bool:
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	var pairs: Array[String] = []
	var wrong: Array[String] = []
	for path: NodePath in [^"CollisionShape2D", ^"Repellable/RepellableShape", ^"Hitbox/HitboxShape"]:
		var small: CollisionShape2D = dog.get_node(path) as CollisionShape2D
		var large: CollisionShape2D = big.get_node(path) as CollisionShape2D
		var small_size: Vector2 = (small.shape as RectangleShape2D).size
		var large_size: Vector2 = (large.shape as RectangleShape2D).size
		pairs.append("%s %s" % [path, large_size])
		if not large_size.is_equal_approx(small_size * SIZE) or not large.position.is_equal_approx(small.position * SIZE):
			wrong.append(String(path))
	var small_art: Node2D = dog.get_node(^"Sprite") as Node2D
	var large_art: Node2D = big.get_node(^"Sprite") as Node2D
	if not large_art.scale.is_equal_approx(small_art.scale * SIZE):
		wrong.append("Sprite")
	var ledge_reach: float = (big.get_node(^"LedgeCheck") as Node2D).position.x
	var small_reach: float = (dog.get_node(^"LedgeCheck") as Node2D).position.x
	var small_half: float = ((dog.get_node(^"CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x / 2.0
	if not is_equal_approx(ledge_reach, small_half * SIZE + (small_reach - small_half)):
		wrong.append("LedgeCheck")
	var has_ring: bool = big.get_node_or_null(^"GateRing") is ProximityUnlocker
	dog.free()
	big.free()
	return report(wrong.is_empty() and has_ring, "Size: %s; wrong %s; ring %s" % [", ".join(pairs), wrong, has_ring])


func _the_biggest_dog_hands_his_gates_to_his_ring() -> bool:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = Vector2(FLOOR_LEFT + 200.0, 0.0)
	root.add_child(gate)
	var big: BiggestDemon = BIGGEST_SCENE.instantiate() as BiggestDemon
	big.position = Vector2(FLOOR_RIGHT - 1200.0, 0.0)
	big.opens = [gate] as Array[Gate]
	root.add_child(big)
	await physics_frame
	var ring: ProximityUnlocker = big.get_node(^"GateRing") as ProximityUnlocker
	var handed: bool = ring.gates == [gate]
	big.queue_free()
	gate.queue_free()
	return report(handed, "Opens: the ring opens %s" % [ring.gates])
