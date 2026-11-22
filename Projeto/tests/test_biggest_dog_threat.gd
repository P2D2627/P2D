# Checks what makes level 1's biggest dog the chase's last threat (#284). Its bite kills the man at
# once, whatever his SP, while a regular dog's only takes SP; it kills him also while another demon
# holds him, and never in god mode. The crucifix does not reach it: its Repellable is on no layer,
# while a regular dog's is. With the man on a ledge, another floor within its jump, it warns and then
# leaps at him through the air, and he dies if he stays; the leap keeps the aim it took as it started
# to warn, so a man who moved off meanwhile is missed, and alive when it lands: put far off, put a few
# steps along the ledge, or running off it from a standstill as the warning starts. A warning of a
# leap at a man no leap gets to ends with no attack. Its attack is asked for once a physics frame:
# asked again in the same frame, nothing is drawn again.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_biggest_dog_threat.gd
extends "res://tests/support/player_test.gd"

const DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
const FLOOR_LEFT: float = -3000.0
const FLOOR_RIGHT: float = 3000.0
## Where the dog stands, facing left, and how far beyond its face the man stands on its floor.
const DOG_X: float = 600.0
const MAN_BEYOND_FACE: float = 200.0
## The ledge the man waits on, ahead of the dog: its ends and its top, four tiles up, within the
## biggest dog's jump and above the man's reach of its back.
const LEDGE_LEFT: float = 150.0
const LEDGE_RIGHT: float = 342.0
const LEDGE_TOP: float = -192.0
## Frames given to a bite or a leap to land.
const ATTACK_FRAMES: int = 420
## Where the man is put once the dog warns, far behind it on the floor, out of its leap.
const MOVED_OFF_TO: Vector2 = Vector2(-1200.0, -2.0)
## A ledge longer to the left, and how far along it the man steps once the dog warns: a few of his
## steps, past what its body and bite cover where it lands, yet a leap aimed again would reach him.
const LONG_LEDGE_LEFT: float = -250.0
const STEP_ALONG: float = 220.0
## A ledge above the dog's jump, where no leap gets to the man.
const HIGH_LEDGE_TOP: float = -700.0


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _its_bite_kills_and_a_dog_s_does_not())
	results.append(await _its_bite_kills_a_held_man_and_not_in_god_mode())
	results.append(_the_crucifix_does_not_reach_it())
	results.append(await _it_leaps_at_the_man_on_a_ledge())
	results.append(await _a_man_who_moves_off_while_it_warns_is_missed())
	results.append(await _a_man_who_steps_along_the_ledge_while_it_warns_is_missed())
	results.append(await _a_man_who_runs_off_as_it_warns_is_missed())
	results.append(await _a_warning_with_no_leap_to_take_ends_with_no_attack())
	results.append(await _its_attack_is_asked_for_once_a_frame())
	finish(results)


func _its_bite_kills_and_a_dog_s_does_not() -> bool:
	var outcomes: Array[String] = []
	var passed: bool = true
	for scene: PackedScene in [BIGGEST_SCENE, DOG_SCENE]:
		var dog: Demon = await _spawn_facing_left(scene)
		var player: Player = await spawn_on_floor(
				Vector2(DOG_X - _half_width_of(dog) - MAN_BEYOND_FACE, -2.0))
		var full: float = player.soul_points.get_sp()
		var hits: Array[int] = [0]
		(player.get_node(^"Hurtbox") as Hurtbox).hit_received.connect(
				func(_hitbox: Hitbox) -> void: hits[0] += 1)
		await wait_until(func() -> bool: return hits[0] > 0, ATTACK_FRAMES)
		await wait_frames(2)
		var dead: bool = player.is_dead()
		var biggest: bool = scene == BIGGEST_SCENE
		var as_expected: bool = hits[0] > 0 and dead == biggest \
				and (not biggest or player.get_death_cause() == &"biggest_demon") \
				and (biggest or player.soul_points.get_sp() < full)
		outcomes.append("%s: hit %s, dead %s (cause %s), SP %.0f of %.0f" % [scene.resource_path.get_file(),
				hits[0] > 0, dead, player.get_death_cause(), player.soul_points.get_sp(), full])
		passed = passed and as_expected
		dog.queue_free()
		await remove_player(player)
	return report(passed, "One bite: %s" % "; ".join(outcomes))


func _its_bite_kills_a_held_man_and_not_in_god_mode() -> bool:
	var outcomes: Array[String] = []
	var passed: bool = true
	for held: bool in [true, false]:
		var dog: Demon = await _spawn_facing_left(BIGGEST_SCENE)
		var player: Player = await spawn_on_floor(
				Vector2(DOG_X - _half_width_of(dog) - MAN_BEYOND_FACE, -2.0))
		if held:
			(player.get_node(^"HitReaction") as HitReaction).hold()
		else:
			player.god_mode = true
		var hits: Array[int] = [0]
		(player.get_node(^"Hurtbox") as Hurtbox).hit_received.connect(
				func(_hitbox: Hitbox) -> void: hits[0] += 1)
		await wait_until(func() -> bool: return hits[0] > 0, ATTACK_FRAMES)
		await wait_frames(2)
		var dead: bool = player.is_dead()
		passed = passed and hits[0] > 0 and dead == held
		outcomes.append("%s: hit %s, dead %s" % ["held" if held else "god mode", hits[0] > 0, dead])
		dog.queue_free()
		await remove_player(player)
	return report(passed, "Bite, held man dies, god mode lives: %s" % "; ".join(outcomes))


func _the_crucifix_does_not_reach_it() -> bool:
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	root.add_child(big)
	root.add_child(dog)
	var big_layer: int = (big.get_node(^"%Repellable") as Area2D).collision_layer
	var dog_layer: int = (dog.get_node(^"%Repellable") as Area2D).collision_layer
	big.free()
	dog.free()
	return report(big_layer == 0 and dog_layer != 0,
			"Crucifix: the biggest dog's Repellable on layers %d (0), a dog's on %d (not 0)" % [big_layer, dog_layer])


func _it_leaps_at_the_man_on_a_ledge() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, LEDGE_TOP - 2.0))
	var leaped: Array[bool] = [false]
	var dead: bool = false
	for _step: int in ATTACK_FRAMES:
		await physics_frame
		if big.get_state() == Demon.State.LUNGE and not big.is_on_floor() and big.velocity.y < 0.0:
			leaped[0] = true
		if player.is_dead():
			dead = true
			break
	var cause: StringName = player.get_death_cause()
	big.queue_free()
	await remove_player(player)
	ledge.queue_free()
	await physics_frame
	return report(leaped[0] and dead and cause == &"biggest_demon",
			"Ledge: it leaped up at the man %s, he died %s (cause %s)" % [leaped[0], dead, cause])


func _a_man_who_moves_off_while_it_warns_is_missed() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, LEDGE_TOP - 2.0))
	var warned: bool = await wait_until(func() -> bool: return big.get_state() == Demon.State.WARNING,
			ATTACK_FRAMES)
	# Far off on the floor as soon as it starts to warn: the leap keeps the aim it took then.
	player.global_position = MOVED_OFF_TO
	player.reset_physics_interpolation()
	var leaped: bool = await wait_until(func() -> bool:
			return big.get_state() == Demon.State.LUNGE and not big.is_on_floor(), ATTACK_FRAMES)
	var landed: bool = await wait_until(big.is_on_floor, ATTACK_FRAMES)
	var alive: bool = not player.is_dead()
	big.queue_free()
	await remove_player(player)
	ledge.queue_free()
	await physics_frame
	return report(warned and leaped and landed and alive,
			"Ledge, moved off: it warned %s, leaped %s, landed %s, the man alive then %s"
			% [warned, leaped, landed, alive])


func _a_man_who_steps_along_the_ledge_while_it_warns_is_missed() -> bool:
	var ledge: StaticBody2D = make_platform(LONG_LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var stands_at: Vector2 = Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, LEDGE_TOP - 2.0)
	var player: Player = await spawn_on_floor(stands_at)
	var warned: bool = await wait_until(func() -> bool: return big.get_state() == Demon.State.WARNING,
			ATTACK_FRAMES)
	# A few steps along the same ledge, away from the dog, as soon as it starts to warn.
	player.global_position = stands_at - Vector2(STEP_ALONG, 0.0)
	player.reset_physics_interpolation()
	var leaped: bool = await wait_until(func() -> bool:
			return big.get_state() == Demon.State.LUNGE and not big.is_on_floor(), ATTACK_FRAMES)
	var landed: bool = await wait_until(big.is_on_floor, ATTACK_FRAMES)
	var alive: bool = not player.is_dead()
	var landed_at: float = big.global_position.x
	big.queue_free()
	await remove_player(player)
	ledge.queue_free()
	await physics_frame
	return report(warned and leaped and landed and alive,
			"Ledge, %.0f px along it: it warned %s, leaped %s, landed %s at x %.0f (aimed at %.0f), the man alive then %s"
			% [STEP_ALONG, warned, leaped, landed, landed_at, stands_at.x, alive])


func _a_man_who_runs_off_as_it_warns_is_missed() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, LEDGE_TOP - 2.0))
	var stand_in: StandInInput = put_a_stand_in(player)
	var warned: bool = await wait_until(func() -> bool: return big.get_state() == Demon.State.WARNING,
			ATTACK_FRAMES)
	# From a standstill, he runs away from the dog as it starts to warn, off the ledge's far end.
	stand_in.run_direction = -1.0
	var leaped: bool = await wait_until(func() -> bool:
			return big.get_state() == Demon.State.LUNGE and not big.is_on_floor(), ATTACK_FRAMES)
	var landed: bool = await wait_until(big.is_on_floor, ATTACK_FRAMES)
	var alive: bool = not player.is_dead()
	var man_at: Vector2 = player.global_position
	big.queue_free()
	await remove_player(player)
	ledge.queue_free()
	await physics_frame
	return report(warned and leaped and landed and alive,
			"Ledge, runs off as it warns: it warned %s, leaped %s, landed %s, the man alive then %s, at %s"
			% [warned, leaped, landed, alive, man_at])


func _a_warning_with_no_leap_to_take_ends_with_no_attack() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	var high_ledge: StaticBody2D = make_platform(LEDGE_LEFT, LEDGE_RIGHT, HIGH_LEDGE_TOP)
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, LEDGE_TOP - 2.0))
	var sees_him: bool = await wait_until(big.has_target, ATTACK_FRAMES)
	# Up out of its jump, and a warning of the leap all the same: there is no leap to aim.
	player.global_position = Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, HIGH_LEDGE_TOP - 2.0)
	player.reset_physics_interpolation()
	big.warn_of(_leaping_attack_of(big))
	var lunged: bool = false
	for _step: int in _leaping_attack_of(big).get_warning_frames() * 4:
		await physics_frame
		lunged = lunged or big.get_state() == Demon.State.LUNGE
	var state: String = Demon.State.keys()[big.get_state()]
	big.queue_free()
	await remove_player(player)
	ledge.queue_free()
	high_ledge.queue_free()
	await physics_frame
	return report(sees_him and not lunged,
			"No leap to aim: it saw him %s, lunged anyway %s, then %s" % [sees_him, lunged, state])


func _its_attack_is_asked_for_once_a_frame() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	var big: Demon = await _spawn_facing_left(BIGGEST_SCENE)
	var player: Player = await spawn_on_floor(Vector2((LEDGE_LEFT + LEDGE_RIGHT) / 2.0, LEDGE_TOP - 2.0))
	var sees_him: bool = await wait_until(func() -> bool: return big.has_target() and big.is_on_floor(),
			ATTACK_FRAMES)
	var gap: float = big.get_gap_to_target()
	var delta: float = 1.0 / Engine.physics_ticks_per_second
	# Asked twice on one physics frame, as when one state hands over to another that asks again.
	big.attack_to_start(gap, delta)
	var after_first: Array = [big._rng.state, big._hesitation_frames_left]
	big.attack_to_start(gap, delta)
	var after_second: Array = [big._rng.state, big._hesitation_frames_left]
	big.queue_free()
	await remove_player(player)
	ledge.queue_free()
	await physics_frame
	return report(sees_him and after_first == after_second,
			"Asked twice in a frame: it saw him %s, draw and hesitation after the first %s, after the second %s"
			% [sees_him, after_first, after_second])


## The attack of the dog that Leaps To Other Floors.
func _leaping_attack_of(dog: Demon) -> DemonAttack:
	for attack: DemonAttack in dog.stats.attacks:
		if attack.leaps_to_other_floors:
			return attack
	return null


func _spawn_facing_left(scene: PackedScene) -> Demon:
	var dog: Demon = scene.instantiate() as Demon
	dog.position = Vector2(DOG_X, -2.0)
	dog.faces_left = true
	root.add_child(dog)
	await wait_until(dog.is_on_floor)
	return dog


func _half_width_of(dog: Demon) -> float:
	return ((dog.get_node(^"CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x / 2.0
