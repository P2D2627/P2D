# The gym's dog stations (ADR 0036), in the gym itself. From the start on the ledge the dog sees the
# man but cannot reach him; behind the low wall it does not notice him; on the floor of the pack
# station both dogs come after him; with his SP low a bite grabs him, pressing Jump frees him and
# the dog lies stunned; at the crucifix station the raised crucifix throws the dog off before it
# bites, and gives SP back; and at the SP station a grab with no presses kills the man, and the gym
# starts over with him at that station.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym_dogs.gd
extends "res://tests/support/player_test.gd"

const GYM_SCENE: PackedScene = preload("res://levels/gym/gym.tscn")
## The top of every station's floor, in its own coordinates.
const FLOOR_TOP: float = 1000.0
## How far above a floor a placed man starts, in px, so he lands on it. His origin is his feet.
const DROP_HEIGHT: float = 20.0
## Where the man hides in the dog station, in its coordinates: between the ledge, which ends at 960,
## and the low wall, which starts at 1036.
const HIDING_X: float = 998.0
## Where the man stands on the pack station's floor, in its coordinates: past the ledge, in front of
## both dogs.
const PACK_FLOOR_X: float = 1060.0
## Physics frames a dog gets to notice the man, or to show it did not: three seconds.
const NOTICE_FRAMES: int = 180
## The man's SP for the grab: under the Low Threshold of 25.
const LOW_SP: float = 20.0
## Physics frames between two presses of Jump in the grab: about seven presses a second.
const PRESS_EVERY_FRAMES: int = 8
## Physics frames the grab case gets, to be grabbed and then to break free.
const GRAB_FRAMES: int = 900
## The man's SP at the crucifix station: above the Low Threshold, so a bite would hurt and not grab,
## and below the most, so the crucifix has some to give back.
const HURT_SP: float = 50.0
## Where the man raises the crucifix at its station, in its coordinates: past the ledge, in front of
## the dog.
const CRUCIFIX_FLOOR_X: float = 1060.0
## Physics frames the dog gets to come and be thrown off: the crucifix's 5 s of use.
const REPEL_FRAMES: int = 300
## Physics frames the death case gets, from the man on the floor to the gym asking to start over:
## the dog coming, the 3 s grab, the 1.5 s Restart Delay, with room to spare.
const DEATH_FRAMES: int = 600


func _initialize() -> void:
	# Without a window the root is 64 × 64 px; the dogs chase only what is on the screen.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(await _the_dog_cannot_reach_the_man_on_the_ledge())
	results.append(await _the_dog_does_not_notice_the_man_behind_the_wall())
	results.append(await _both_dogs_of_the_pack_come_after_the_man())
	results.append(await _with_low_sp_a_bite_grabs_and_jump_frees())
	results.append(await _the_raised_crucifix_throws_the_dog_off())
	results.append(await _a_death_at_the_sp_station_starts_the_gym_there())
	finish(results)


## At the dog station's start the dog sees the man, stands out of reach under him, and he keeps all
## his SP.
func _the_dog_cannot_reach_the_man_on_the_ledge() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/DogsStation") as Node2D
	var dog: Demon = station.get_node(^"Dog") as Demon
	var player: Player = gym.player
	await _place(player, (station.get_node(^"Start") as Marker2D).global_position)
	var sp: float = player.soul_points.get_sp()
	var below: bool = await wait_until(func() -> bool:
		return dog.get_state() == Demon.State.OUT_OF_REACH, NOTICE_FRAMES)
	await wait_frames(NOTICE_FRAMES)
	var sp_kept: bool = is_equal_approx(player.soul_points.get_sp(), sp)
	gym.free()
	return report(below and sp_kept,
			"Ledge: the dog out of reach under the man %s, his SP kept %s" % [below, sp_kept])


## With the man in the gap behind the low wall, the dog at its post, facing him, never notices him;
## with the wall taken away, it does: the wall is what hides him.
func _the_dog_does_not_notice_the_man_behind_the_wall() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/DogsStation") as Node2D
	var dog: Demon = station.get_node(^"Dog") as Demon
	await _place(gym.player, station.global_position
			+ Vector2(HIDING_X, FLOOR_TOP - DROP_HEIGHT))
	var noticed: Callable = func() -> bool: return dog.has_target() or dog.sees_target()
	var hidden: bool = not await wait_until(noticed, NOTICE_FRAMES)
	station.get_node(^"HidingWall").free()
	var seen_without_wall: bool = await wait_until(noticed, NOTICE_FRAMES)
	gym.free()
	return report(hidden and seen_without_wall,
			"Behind the wall: hidden %s, seen with the wall taken away %s"
			% [hidden, seen_without_wall])


## With the man on the pack station's floor, in front of both dogs, both come after him.
func _both_dogs_of_the_pack_come_after_the_man() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/PackStation") as Node2D
	var dogs: Array[Demon] = [station.get_node(^"NearDog") as Demon,
			station.get_node(^"FarDog") as Demon]
	await _place(gym.player, station.global_position
			+ Vector2(PACK_FLOOR_X, FLOOR_TOP - DROP_HEIGHT))
	var both: bool = await wait_until(func() -> bool:
		return dogs.all(func(dog: Demon) -> bool: return dog.has_target()), NOTICE_FRAMES)
	gym.free()
	return report(both, "Pack: both dogs after the man %s" % both)


## With the man's SP low on the pack station's floor, a dog's bite grabs him, pressing Jump again
## and again breaks him free before he sinks, and a dog that held him lies stunned.
func _with_low_sp_a_bite_grabs_and_jump_frees() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/PackStation") as Node2D
	var dogs: Array[Demon] = [station.get_node(^"NearDog") as Demon,
			station.get_node(^"FarDog") as Demon]
	var player: Player = gym.player
	var grab_escape: GrabEscape = player.get_node(^"GrabEscape") as GrabEscape
	var stand_in: StandInInput = put_a_stand_in(player)
	await _place(player, station.global_position + Vector2(PACK_FLOOR_X, FLOOR_TOP - DROP_HEIGHT))
	player.soul_points.take_damage(player.soul_points.get_sp() - LOW_SP)
	var broke_free: Array[bool] = [false]
	var died: Array[bool] = [false]
	grab_escape.broke_free.connect(func() -> void: broke_free[0] = true)
	grab_escape.died.connect(func() -> void: died[0] = true)
	var grabbed: bool = await wait_until(grab_escape.is_held, GRAB_FRAMES)
	var held_at: Vector2 = player.global_position
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	root.push_input(key)
	var kept_by_the_grab: bool = player.global_position == held_at
	var frame: Array[int] = [0]
	var freed: bool = grabbed and await wait_until(func() -> bool:
		frame[0] += 1
		if frame[0] % PRESS_EVERY_FRAMES == 0:
			stand_in.press_jump()
		return broke_free[0] or died[0], GRAB_FRAMES)
	var stunned: bool = freed and await wait_until(func() -> bool:
		return dogs.any(func(dog: Demon) -> bool: return dog.get_state() == Demon.State.STUNNED),
		NOTICE_FRAMES)
	gym.free()
	return report(grabbed and kept_by_the_grab and freed and broke_free[0] and not died[0] \
			and stunned,
			"Grab: low SP %s, grabbed %s, key 1 ignored %s, broke free %s, died %s, a dog stunned %s"
			% [LOW_SP, grabbed, kept_by_the_grab, broke_free[0], died[0], stunned])


## With the man hurt but not low on the crucifix station's floor, holding Crucifix from the start,
## the dog that comes is thrown off and stays still, the man is never bitten, and he gets SP back.
func _the_raised_crucifix_throws_the_dog_off() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/CrucifixStation") as Node2D
	var dog: Demon = station.get_node(^"Dog") as Demon
	var player: Player = gym.player
	var stand_in: StandInInput = put_a_stand_in(player)
	await _place(player, station.global_position
			+ Vector2(CRUCIFIX_FLOOR_X, FLOOR_TOP - DROP_HEIGHT))
	player.soul_points.take_damage(player.soul_points.get_sp() - HURT_SP)
	var bitten: Array[bool] = [false]
	player.soul_points.damaged.connect(func(_amount: float) -> void: bitten[0] = true)
	stand_in.crucifix_held = true
	var repelled: bool = await wait_until(func() -> bool:
		return dog.get_state() == Demon.State.REPELLED, REPEL_FRAMES)
	var healed: bool = player.soul_points.get_sp() > HURT_SP
	gym.free()
	return report(repelled and not bitten[0] and healed,
			"Crucifix: the dog thrown off and still %s, the man bitten %s, SP given back %s"
			% [repelled, bitten[0], healed])


## With the man's SP low on the SP station's floor and no press of anything, the dog's grab kills
## him, the gym asks to start over, and its new copy puts him at the SP station's start.
func _a_death_at_the_sp_station_starts_the_gym_there() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/SoulPointsStation") as Node2D
	var start: Vector2 = (station.get_node(^"Start") as Marker2D).global_position
	var player: Player = gym.player
	put_a_stand_in(player)
	await _place(player, station.global_position + Vector2(PACK_FLOOR_X, FLOOR_TOP - DROP_HEIGHT))
	player.soul_points.take_damage(player.soul_points.get_sp() - LOW_SP)
	var asked: Array[bool] = [false]
	gym.restart_requested.connect(func() -> void: asked[0] = true)
	var restarted: bool = await wait_until(func() -> bool: return asked[0], DEATH_FRAMES)
	gym.free()
	# Read before any physics frame: from the start the man falls onto the ledge.
	var again: Level = _make_gym()
	var at_start: bool = again.player.global_position.is_equal_approx(start)
	again.free()
	return report(restarted and at_start,
			"Death: the gym asked to start over %s, the man back at the SP station's start %s"
			% [restarted, at_start])


## Puts the man at, standing, and waits for him to be on the floor there.
func _place(player: Player, at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await wait_until_on_floor(player)


func _make_gym() -> Level:
	var gym: Level = GYM_SCENE.instantiate() as Level
	root.add_child(gym)
	return gym
