# Checks level 1's biggest dog and the ring that opens a gate when the man comes near. The ring alone: the man
# outside it opens nothing; walking inside it opens every gate on its list, once, and leaving and coming back opens
# nothing more. The biggest dog: the regular dog with its body, hit box, art and checks half again their size, a
# ring around his middle, and the gates set on him (Opens) handed to that ring. Its stats are the regular dog's
# with the distances to the man measured from its face, and it goes after him as he goes (#271): it notices him
# as far beyond its face as the regular dog, comes and bites him, bites him on its back, never gives up on him,
# jumps up a step as high as he jumps and no higher, leaps down after him, and attacks him only while it sees
# him. Its own since #284: a faster chase, still slower than the man, bites that kill after a longer warning,
# a lunge that leaps to other floors, and no crucifix (test_biggest_dog_threat.gd plays them).
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_biggest_dog.gd
extends "res://tests/support/player_test.gd"

const RING_SCENE: PackedScene = preload("res://scenes/objects/gates/proximity_unlocker.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
## How many times the regular dog's size the biggest is: a little bigger than the big dog of phase 2,
## 1.25, so it reads as the biggest, and small enough for the man to jump over (#271).
const SIZE: float = 1.5
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
## Where a dog stands in the cases about its sight and its bite, facing left; how far beyond its
## face the man's middle is when the regular dog sees him and when it does not, in px; and the
## frames given to notice him, and to come and bite him.
const DOG_X: float = 1500.0
const SEEN_BEYOND_FACE: float = 900.0
const UNSEEN_BEYOND_FACE: float = 1200.0
const NOTICE_FRAMES: int = 60
const BITE_FRAMES: int = 240
const BITE_FROM_BEYOND_FACE: float = 300.0
## The stats' fields that measure, from the dog's middle, how far it is from the man: the biggest
## dog's are the regular dog's measured from its face, its half width further out; and the attacks'
## field that does the same. To within the 10 px step of those fields.
const FROM_THE_FACE: Array[String] = ["lose_distance", "retreat_distance"]
const ATTACK_FROM_THE_FACE: Array[String] = ["attack_range"]
const STAT_STEP: float = 10.0
## The attack fields the biggest dog has its own of (#284), and the least warning before a bite that
## kills, so the man can read it.
const KILLING_ATTACK_FIELDS: Array[String] = ["warning_time", "kills", "leaps_to_other_floors"]
const KILLING_WARNING_TIME: float = 0.35
## How high above the biggest dog's back the man is dropped, in px, and the frames its back has to
## bite him.
const BACK_DROP_HEIGHT: float = 24.0
const BACK_BITE_FRAMES: int = 60
## The states of a dog that has given up on the man, or never was after him.
const GIVEN_UP: Array[int] = [Demon.State.IDLE, Demon.State.PATROL, Demon.State.SEARCH,
		Demon.State.RETURN]
## Where the man is put once a dog chases him: past any dog's Lose Distance, in px; and beyond its
## face with a camera on him, zoomed in so the dog is off the screen; and the frames given to give
## up, past its Give Up Time and Search Time.
const PAST_LOSE: float = 2500.0
const OFF_SCREEN_BEYOND_FACE: float = 900.0
const OFF_SCREEN_ZOOM: float = 2.0
const GIVE_UP_FRAMES: int = 240
## The steps of the climb case: this much lower than the man's jump, and this much higher; how far
## from the dog's face, and how wide; and the frames to climb.
const STEP_SHORT: float = 16.0
const STEP_TOO_HIGH: float = 40.0
const STEP_GAP: float = 200.0
const STEP_WIDTH: float = 600.0
const CLIMB_FRAMES: int = 240
## The ledge of the drop case: how high above the floor, how far each side of the dog, how thick;
## how far beyond the dog's face the man stands on it first, and how far past its end he is put on
## the floor; and the frames to come down.
const DROP_DEPTH: float = 700.0
const LEDGE_HALF_WIDTH: float = 300.0
const LEDGE_MAN_GAP: float = 150.0
const LEDGE_THICKNESS: float = 16.0
const PAST_THE_LEDGE: float = 300.0
const DROP_FRAMES: int = 240
## The deepest drop Max Drop takes, in px: the deepest on the man's way back round from the last
## hall of level 1's phase 3, the chimney behind gate 3 down into the hall, 31 tiles, and a tile more.
const LOOP_DROP: float = 1536.0
## How near, in px, a dog's feet must be to a top to stand on it.
const ON_TOP: float = 2.0
## The man hidden behind a wall within its lunge's reach: the wall's gap to its face, its thickness
## and height, how far beyond its face he stands, and how long it is watched.
const HIDING_WALL_GAP: float = 40.0
const HIDING_WALL_THICKNESS: float = 16.0
const HIDING_WALL_HEIGHT: float = 400.0
const HIDDEN_BEYOND_FACE: float = 200.0
const HIDDEN_FRAMES: int = 180
const ATTACKING: Array[int] = [Demon.State.WARNING, Demon.State.LUNGE]


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _the_ring_opens_its_gates_once_the_man_comes_inside())
	results.append(_the_biggest_dog_is_the_dog_half_again_as_big())
	results.append(await _the_biggest_dog_hands_his_gates_to_his_ring())
	results.append(await _the_biggest_dog_is_awake_round_his_whole_ring())
	results.append(_its_stats_are_the_dog_s_measured_from_its_face())
	results.append(await _it_notices_the_man_as_far_beyond_its_face_as_the_dog())
	results.append(await _it_bites_the_man_it_runs_into())
	results.append(await _the_man_on_its_back_is_bitten())
	results.append(await _it_never_gives_up_on_the_man())
	results.append(await _it_jumps_up_as_high_as_the_man_jumps())
	results.append(await _it_drops_down_after_the_man())
	results.append(await _it_attacks_the_man_only_while_it_sees_him())
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


func _the_biggest_dog_is_the_dog_half_again_as_big() -> bool:
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


## The ActivityTracker keeps a demon awake while the rect it answers is near the screen; the man, always on the
## screen, inside the ring of a biggest dog asleep would open nothing. So his rect holds his whole ring.
func _the_biggest_dog_is_awake_round_his_whole_ring() -> bool:
	var big: BiggestDemon = BIGGEST_SCENE.instantiate() as BiggestDemon
	big.position = Vector2(FLOOR_RIGHT - 1200.0, 0.0)
	root.add_child(big)
	await physics_frame
	var ring: ProximityUnlocker = big.get_node(^"GateRing") as ProximityUnlocker
	var ring_box: Rect2 = Rect2(ring.global_position - Vector2.ONE * ring.reach, Vector2.ONE * 2.0 * ring.reach)
	var awake_for: Rect2 = big.get_activity_rect()
	big.queue_free()
	return report(awake_for.encloses(ring_box),
			"Awake round the ring: activity rect %s, the ring's box %s" % [awake_for, ring_box])


## The biggest dog has stats of its own: the regular dog's, but for how far it is from the man,
## which the regular dog's measure from its middle. Its are the same distances from its face, its
## half width further out than the regular dog's (#271): from its middle, no attack reached past its
## own body, and it stood by the man and never bit. How far behind it notices him, also from its
## back. How far it sees, from its eyes to the man's head, reaches as far beyond its face as the
## regular dog's. Pack Variation varies its Retreat Distance by as many px as the regular dog's,
## not by the same share of a longer distance. And it goes after the man as he goes: it never gives
## up on him, jumps up as high as he jumps, leaps down any drop a demon can, follows his trail and
## drops down shafts (#271, phase C).
func _its_stats_are_the_dog_s_measured_from_its_face() -> bool:
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	var own_file: bool = big.stats != null and big.stats != dog.stats
	var wrong: Array[String] = []
	if own_file:
		var further: float = _half_width_of(big) - _half_width_of(dog)
		var skip: Array[String] = ["attacks", "sight_distance", "sight_behind_share", "pack_variation",
				"never_gives_up", "jump_height", "max_drop", "follows_trail", "drops_down_shafts",
				"chase_speed", "ignores_crucifix"]
		skip.append_array(FROM_THE_FACE)
		wrong = _different_fields(dog.stats, big.stats, skip)
		# Its own since #284: a faster chase, still slower than the man at the fastest of its draws,
		# and no crucifix.
		if big.stats.chase_speed <= dog.stats.chase_speed \
				or big.stats.chase_speed * (1.0 + big.stats.pack_variation) >= _man_top_speed():
			wrong.append("chase_speed")
		if not big.stats.ignores_crucifix:
			wrong.append("ignores_crucifix")
		for flag: String in ["never_gives_up", "follows_trail", "drops_down_shafts"]:
			if big.stats.get(flag) != true:
				wrong.append(flag)
		if not is_equal_approx(big.stats.jump_height, _man_jump_height()):
			wrong.append("jump_height")
		if not is_equal_approx(big.stats.max_drop, LOOP_DROP):
			wrong.append("max_drop")
		for field: String in FROM_THE_FACE:
			if absf(big.stats.get(field) - dog.stats.get(field) - further) > STAT_STEP:
				wrong.append(field)
		var behind: float = big.stats.sight_distance * big.stats.sight_behind_share \
				- dog.stats.sight_distance * dog.stats.sight_behind_share
		if absf(behind - further) > STAT_STEP:
			wrong.append("sight_behind_share")
		if absf(_sight_beyond_face(big) - _sight_beyond_face(dog)) > STAT_STEP:
			wrong.append("sight_distance")
		if absf(big.stats.retreat_distance * big.stats.pack_variation
				- dog.stats.retreat_distance * dog.stats.pack_variation) > STAT_STEP:
			wrong.append("pack_variation")
		wrong.append_array(_different_attacks(dog.stats.attacks, big.stats.attacks, further))
	dog.free()
	big.free()
	return report(own_file and wrong.is_empty(),
			"Stats: a file of its own %s; fields not the dog's, or not the dog's from its face: %s"
			% [own_file, wrong])


## The man stands on the floor in front of a dog, facing him, SEEN_BEYOND_FACE px beyond its face
## and then UNSEEN_BEYOND_FACE px: the regular dog notices him at the first and not at the second,
## and so does the biggest dog, whose eyes are half again as high (#271).
func _it_notices_the_man_as_far_beyond_its_face_as_the_dog() -> bool:
	var passed: bool = true
	for scene: PackedScene in [DOG_SCENE, BIGGEST_SCENE]:
		var noticed: Array[bool] = []
		for beyond: float in [SEEN_BEYOND_FACE, UNSEEN_BEYOND_FACE]:
			var dog: Demon = await _spawn_facing_left(scene)
			var player: Player = await spawn_on_floor(
					Vector2(DOG_X - _half_width_of(dog) - beyond, -2.0))
			var seen: bool = await wait_until(func() -> bool:
					return dog.get_state() in [Demon.State.ALERT, Demon.State.CHASE], NOTICE_FRAMES)
			noticed.append(seen)
			dog.queue_free()
			if player != null:
				await remove_player(player)
		passed = report(noticed == [true, false],
				("%s: the man %.0f px beyond its face noticed %s (true), %.0f px beyond not "
				+ "noticed %s (true)") % [scene.resource_path.get_file(), SEEN_BEYOND_FACE,
				noticed[0], UNSEEN_BEYOND_FACE, not noticed[1]]) and passed
	return passed


## The man stands BITE_FROM_BEYOND_FACE px beyond the biggest dog's face: it comes and bites him
## within BITE_FRAMES, as the regular dog would. From its middle, its bite reached only 100 px, not
## even out of its body, and it stood against him for good (#271).
func _it_bites_the_man_it_runs_into() -> bool:
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(
			Vector2(DOG_X - _half_width_of(big) - BITE_FROM_BEYOND_FACE, -2.0))
	if player == null:
		big.queue_free()
		return report(false, "Biggest dog's bite: the man never landed")
	var hits: Array[int] = [0]
	(player.get_node(^"Hurtbox") as Hurtbox).hit_received.connect(
			func(_hitbox: Hitbox) -> void: hits[0] += 1)
	var bitten: bool = await wait_until(func() -> bool: return hits[0] > 0, BITE_FRAMES)
	big.queue_free()
	await remove_player(player)
	return report(bitten, "Biggest dog's bite: the man %.0f px beyond its face bitten within %d frames %s"
			% [BITE_FROM_BEYOND_FACE, BITE_FRAMES, bitten])


## The man is dropped onto the biggest dog's back: it bites him, as a regular dog's back does. Its
## back's bite once looked for him in the regular dog's space above its back, deep inside its body:
## nothing bit him there, nothing shoved him off a back that bites either, and it was a safe perch.
func _the_man_on_its_back_is_bitten() -> bool:
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var top: float = big.position.y - _body_size_of(big).y
	var player: Player = spawn_player(Vector2(DOG_X, top - BACK_DROP_HEIGHT))
	var back_bite: Hitbox = (big.get_node(^"BackBite") as DemonBackBite).hitbox
	var bites: Array[int] = [0]
	(player.get_node(^"Hurtbox") as Hurtbox).hit_received.connect(func(hitbox: Hitbox) -> void:
			if hitbox == back_bite:
				bites[0] += 1)
	var bitten: bool = await wait_until(func() -> bool: return bites[0] > 0, BACK_BITE_FRAMES)
	big.queue_free()
	await remove_player(player)
	return report(bitten, "Biggest dog's back: the man dropped onto it bitten within %d frames %s"
			% [BACK_BITE_FRAMES, bitten])


## A dog chases the man, standing BITE_FROM_BEYOND_FACE px beyond its face; then he is put PAST_LOSE
## px away, past its Lose Distance, and then, in a run of its own, OFF_SCREEN_BEYOND_FACE px beyond
## its face with a camera on him that leaves the dog off the screen. After GIVE_UP_FRAMES the regular
## dog has given up both times, and the biggest dog never has: it is still after him (#271).
func _it_never_gives_up_on_the_man() -> bool:
	var passed: bool = true
	for scene: PackedScene in [DOG_SCENE, BIGGEST_SCENE]:
		var kept: Array[bool] = []
		for off_screen: bool in [false, true]:
			var dog: Demon = await _spawn_facing_left(scene)
			var face: float = DOG_X - _half_width_of(dog)
			var player: Player = await spawn_on_floor(Vector2(face - BITE_FROM_BEYOND_FACE, -2.0))
			var chased: bool = await wait_until(func() -> bool:
					return dog.get_state() in [Demon.State.ALERT, Demon.State.CHASE], NOTICE_FRAMES)
			var camera: Camera2D = null
			if off_screen:
				player.global_position = Vector2(face - OFF_SCREEN_BEYOND_FACE, -2.0)
				camera = Camera2D.new()
				camera.zoom = Vector2.ONE * OFF_SCREEN_ZOOM
				camera.global_position = player.global_position
				root.add_child(camera)
				camera.make_current()
			else:
				player.global_position = Vector2(DOG_X - PAST_LOSE, -2.0)
			await wait_frames(GIVE_UP_FRAMES)
			kept.append(chased and not dog.get_state() in GIVEN_UP)
			dog.queue_free()
			if camera != null:
				camera.queue_free()
			await remove_player(player)
		var expected: Array[bool] = [scene == BIGGEST_SCENE, scene == BIGGEST_SCENE]
		passed = report(kept == expected,
				("%s, still after the man %d frames on: past its Lose Distance %s, off the screen %s "
				+ "(%s)") % [scene.resource_path.get_file(), GIVE_UP_FRAMES, kept[0], kept[1],
				expected[0]]) and passed
	return passed


## A dog chases the man on its floor, and he is put on a step STEP_GAP px beyond its face, as high as
## he jumps less STEP_SHORT, and then, in a run of its own, on one STEP_TOO_HIGH px higher than he
## jumps: the biggest dog jumps up onto the first after him within CLIMB_FRAMES, as he could, and not
## onto the second, which he can't reach either (#271).
func _it_jumps_up_as_high_as_the_man_jumps() -> bool:
	var man_jump: float = _man_jump_height()
	var heights: Array[float] = [man_jump - STEP_SHORT, man_jump + STEP_TOO_HIGH]
	var climbed: Array[bool] = []
	for height: float in heights:
		var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
		var face: float = DOG_X - _half_width_of(big)
		var player: Player = await spawn_on_floor(Vector2(face - BITE_FROM_BEYOND_FACE, -2.0))
		await wait_until(func() -> bool: return big.get_state() == Demon.State.CHASE, NOTICE_FRAMES)
		var step_right: float = face - STEP_GAP
		var step: StaticBody2D = make_wall(step_right - STEP_WIDTH, step_right, -height)
		player.global_position = Vector2(step_right - STEP_WIDTH / 2.0, -height - 2.0)
		climbed.append(await wait_until(func() -> bool:
				return big.is_on_floor() and absf(big.global_position.y + height) <= ON_TOP,
				CLIMB_FRAMES))
		big.queue_free()
		step.queue_free()
		await remove_player(player)
	return report(climbed == [true, false],
			("Biggest dog: up a step %.0f px high after the man %s (true), up one %.0f px high %s "
			+ "(false); he jumps %.0f px") % [heights[0], climbed[0], heights[1], climbed[1], man_jump])


## A dog stands on a ledge DROP_DEPTH px above the floor and chases the man there; then he is put on
## the floor PAST_THE_LEDGE px past the ledge's end: the biggest dog leaps down after him and lands on
## the floor within DROP_FRAMES (#271).
func _it_drops_down_after_the_man() -> bool:
	var ledge: StaticBody2D = make_wall(DOG_X - LEDGE_HALF_WIDTH, DOG_X + LEDGE_HALF_WIDTH,
			-DROP_DEPTH, -DROP_DEPTH + LEDGE_THICKNESS)
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	big.position = Vector2(DOG_X, -DROP_DEPTH - 2.0)
	big.faces_left = true
	root.add_child(big)
	await wait_until(big.is_on_floor)
	var on_the_ledge: Vector2 = Vector2(DOG_X - _half_width_of(big) - LEDGE_MAN_GAP, -DROP_DEPTH - 2.0)
	var player: Player = await spawn_on_floor(on_the_ledge)
	await wait_until(func() -> bool: return big.get_state() == Demon.State.CHASE, NOTICE_FRAMES)
	player.global_position = Vector2(DOG_X - LEDGE_HALF_WIDTH - PAST_THE_LEDGE, -2.0)
	var down: bool = await wait_until(func() -> bool:
			return big.is_on_floor() and absf(big.global_position.y) <= ON_TOP, DROP_FRAMES)
	big.queue_free()
	ledge.queue_free()
	await remove_player(player)
	return report(down, "Biggest dog: down %.0f px off a ledge after the man within %d frames %s"
			% [DROP_DEPTH, DROP_FRAMES, down])


## The biggest dog chases the man on its floor; then a wall HIDING_WALL_HEIGHT px high goes up
## HIDING_WALL_GAP px beyond its face and he stands behind it, HIDDEN_BEYOND_FACE px beyond its face,
## within its lunge's reach: through HIDDEN_FRAMES it never warns of an attack nor lunges, since it
## attacks only a man it sees, chasing him for ever or not (#271).
func _it_attacks_the_man_only_while_it_sees_him() -> bool:
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(
			Vector2(DOG_X - _half_width_of(big) - BITE_FROM_BEYOND_FACE, -2.0))
	await wait_until(func() -> bool: return big.get_state() == Demon.State.CHASE, NOTICE_FRAMES)
	var face: float = big.global_position.x - _half_width_of(big)
	var wall_right: float = face - HIDING_WALL_GAP
	var wall: StaticBody2D = make_wall(wall_right - HIDING_WALL_THICKNESS, wall_right,
			-HIDING_WALL_HEIGHT)
	player.global_position = Vector2(face - HIDDEN_BEYOND_FACE, -2.0)
	var within_reach: bool = HIDDEN_BEYOND_FACE + _half_width_of(big) \
			<= _longest_attack_range(big)
	var attacked: bool = await wait_until(func() -> bool: return big.get_state() in ATTACKING,
			HIDDEN_FRAMES)
	big.queue_free()
	wall.queue_free()
	await remove_player(player)
	return report(within_reach and not attacked,
			("Biggest dog: the man hidden behind a wall %.0f px beyond its face, within its reach %s; "
			+ "attacked him in %d frames %s (false)") % [HIDDEN_BEYOND_FACE, within_reach,
			HIDDEN_FRAMES, attacked])


## The longest Attack Range among a dog's attacks, in px from its middle.
func _longest_attack_range(dog: Demon) -> float:
	var longest: float = 0.0
	for attack: DemonAttack in dog.stats.attacks:
		longest = maxf(longest, attack.attack_range)
	return longest


## The man's top run speed, in px/s, from his scene's stats.
func _man_top_speed() -> float:
	var man: Player = PLAYER_SCENE.instantiate() as Player
	var speed: float = man.stats.max_run_speed
	man.free()
	return speed


## The height of the man's full jump, in px, from his scene's stats.
func _man_jump_height() -> float:
	var man: Player = PLAYER_SCENE.instantiate() as Player
	var height: float = man.stats.jump_height
	man.free()
	return height


## How far beyond its face, in px, a dog's sight reaches a man standing on its floor: from its
## eyes, the SightArea, a circle of Sight Distance, down to the man's head when the eyes are higher.
func _sight_beyond_face(dog: Demon) -> float:
	var eyes: float = -(dog.get_node(^"SightArea") as Node2D).position.y
	var man: Player = PLAYER_SCENE.instantiate() as Player
	var man_height: float = ((man.get_node(^"CollisionShape2D") as CollisionShape2D).shape
			as RectangleShape2D).size.y
	man.free()
	var drop: float = maxf(eyes - man_height, 0.0)
	return sqrt(dog.stats.sight_distance ** 2 - drop ** 2) - _half_width_of(dog)


## A dog of scene at DOG_X, facing left, once it stands on the floor.
func _spawn_facing_left(scene: PackedScene) -> Demon:
	var dog: Demon = scene.instantiate() as Demon
	dog.position = Vector2(DOG_X, -2.0)
	dog.faces_left = true
	root.add_child(dog)
	await wait_until(dog.is_on_floor)
	return dog


## Half the width of a dog's body, in px, from its scene.
func _half_width_of(dog: Demon) -> float:
	return _body_size_of(dog).x / 2.0


## The size of a dog's body, in px, from its scene; its feet are at its position.
func _body_size_of(dog: Demon) -> Vector2:
	return ((dog.get_node(^"CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size


## What differs between two lists of attacks, other than the fields of ATTACK_FROM_THE_FACE, which
## in large must be small's further px out.
func _different_attacks(small: Array[DemonAttack], large: Array[DemonAttack], further: float) -> Array[String]:
	if small.size() != large.size():
		return ["attacks: %d, not %d" % [large.size(), small.size()]]
	var wrong: Array[String] = []
	var skip: Array[String] = []
	skip.append_array(ATTACK_FROM_THE_FACE)
	skip.append_array(KILLING_ATTACK_FIELDS)
	for i: int in small.size():
		for field: String in _different_fields(small[i], large[i], skip):
			wrong.append("%s %s" % [small[i].animation, field])
		# Its own since #284: every bite kills, after a warning long enough to read, and its lunge
		# leaps to other floors.
		if not large[i].kills or large[i].warning_time < KILLING_WARNING_TIME:
			wrong.append("%s kills after %.2f s" % [large[i].animation, large[i].warning_time])
		if not large[i].keeps_chasing and not large[i].leaps_to_other_floors:
			wrong.append("%s leaps_to_other_floors" % large[i].animation)
		for field: String in ATTACK_FROM_THE_FACE:
			if absf(large[i].get(field) - small[i].get(field) - further) > STAT_STEP:
				wrong.append("%s %s" % [small[i].animation, field])
	return wrong


## Names of the saved script fields whose values differ between a and b, leaving out those in skip.
## The same as test_big_dog.gd's.
func _different_fields(a: Resource, b: Resource, skip: Array[String]) -> Array[String]:
	var different: Array[String] = []
	for property: Dictionary in a.get_property_list():
		var usage: int = property["usage"]
		var field: String = property["name"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 or (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		if field in skip:
			continue
		if a.get(field) != b.get(field):
			different.append(field)
	return different
