# Checks that the man and a demon never stay one on top of the other (ADR 0047). A demon that drops
# onto the man's head comes off it sideways, never up, as the man comes off a demon's (ADR 0022). In
# a hole one body wide, where the shove of the one on top is stopped on both sides, the two stop
# being stacked within a few frames either way round, and the man can jump after. In a corner, the
# one on top comes off on the open side. A demon holding the man in a grab keeps holding him while
# another drops onto his head and comes off it. The man dropped onto a demon that walks after him
# comes off it and can run and jump. With the two bodies overlapping in the hole, no bite and no grab
# lands on the man. The demons are demon.tscn with stats made here, so their bodies are the game's.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_stacked_bodies.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## A little above the floor, so a body lands on its own before a case starts.
const SPAWN_Y: float = -2.0
## The floor of every case, wide enough that nothing walks off it.
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## How long a body may stay on top of the other, in physics frames: a third of a second.
const MOST_FRAMES_STACKED: int = 20
## How many frames a case watches the two bodies for: three seconds.
const WATCH_FRAMES: int = 180
## How far to one side of the lower body's middle the upper one is dropped, and from how high above
## its top, in px.
const DROP_OFF_CENTRE: float = 8.0
const DROP_HEIGHT: float = 24.0
## How far apart the feet of the upper body and the top of the lower one may be, in px, and still be
## resting on it.
const STACK_TOLERANCE: float = 2.0
## How far the upper body may rise off the lower one's top and still count as shoved sideways, in px.
const RISE_TOLERANCE: float = 1.0
## The hole of the hole cases: a body's width and a little more, so a body falls in, and one and a
## half bodies deep, so the one on top has its feet in it and the hole's sides stop its shove.
const HOLE_SLACK: float = 4.0
const HOLE_DEPTH_IN_BODIES: float = 1.5
## How far from the middle of the corner case's lower body the wall's face is, past its side, in px.
const WALL_GAP: float = 1.0
const WALL_THICKNESS: float = 100.0
const WALL_HEIGHT: float = 400.0
## The demons' senses and chase in every case, as in test_demon.gd.
const SIGHT_DISTANCE: float = 480.0
const LOSE_DISTANCE: float = 720.0
const CHASE_SPEED: float = 300.0
## The bite of the cases that need one, as lust_demon_stats.tres has it.
const BITE_RANGE: float = 100.0
const BITE_WARNING_TIME: float = 0.2
const BITE_RECOVER_TIME: float = 0.3
## How far from the man the demon that grabs him is put, in px: within the bite's range.
const BITE_X: float = 60.0
## SP damage taken before the grab case, to leave the man at 20 of 100, under Low Threshold, so a hit
## grabs him.
const DAMAGE_TO_LOW: float = 80.0
## Frames the walking case's man runs, after he is off the demon, to show the run works.
const RUN_FRAMES: int = 10
## The pack of the pack case: this many demons, Pack Spacing apart as in lust_demon_stats.tres.
const PACK_SIZE: int = 3
const PACK_SPACING: float = 24.0
## Frames after a press of Jump in which the man must jump.
const JUMP_FRAMES: int = PRESS_DELAY_FRAMES + 2

## True on the last _longest_stacked_run() if upper was ever resting on lower.
var _was_ever_stacked: bool = false


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _a_demon_dropped_on_the_man_s_head_comes_off_sideways())
	results.append(await _a_demon_dropped_onto_the_man_in_a_hole_stops_being_on_him())
	results.append(await _the_man_dropped_onto_a_demon_in_a_hole_stops_being_on_it_and_jumps())
	results.append(await _in_a_corner_the_one_on_top_comes_off_on_the_open_side())
	results.append(await _a_demon_comes_off_the_head_of_the_man_another_one_holds())
	results.append(await _the_man_dropped_onto_a_walking_demon_comes_off_and_runs_and_jumps())
	results.append(await _the_man_dropped_onto_a_pack_comes_off_it_and_runs_and_jumps())
	results.append(await _with_the_bodies_overlapping_in_a_hole_no_hit_lands())
	finish(results)


## On open floor, a demon dropped onto the man's head, a little to either side of his middle, comes
## off it to the side it lands on, which its chase in the air may change: on it for
## MOST_FRAMES_STACKED at most, never up, and it lands on the floor clear of him on that side.
func _a_demon_dropped_on_the_man_s_head_comes_off_sideways() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
		var height: float = body_size(man).y
		var demon: Demon = _spawn_demon(
				Vector2(side * DROP_OFF_CENTRE, -height - DROP_HEIGHT), _make_stats())
		var longest: int = 0
		var run: int = 0
		var rose: float = 0.0
		var landed_side: float = 0.0
		for _frame: int in WATCH_FRAMES:
			await physics_frame
			if _is_stacked(demon, man):
				if landed_side == 0.0:
					landed_side = 1.0 if demon.position.x >= man.position.x else -1.0
				run += 1
				longest = maxi(longest, run)
				rose = maxf(rose, -height - demon.position.y)
			else:
				run = 0
		var clearance: float = (landed_side * (demon.position.x - man.position.x)
				- _contact_distance(man, demon))
		var on_floor: bool = demon.is_on_floor() and absf(demon.position.y) <= STACK_TOLERANCE
		await _clear([ground, man, demon])
		passed = report(landed_side != 0.0 and longest <= MOST_FRAMES_STACKED
				and rose <= RISE_TOLERANCE and on_floor and clearance >= -STACK_TOLERANCE,
				("Demon dropped onto the man's head %+.0f px off his middle: landed on his %s, on it "
				+ "%d frames in a row (at most %d), rose %.2f px, on the floor %s, %.1f px clear of "
				+ "him on that side") % [side * DROP_OFF_CENTRE,
				"right" if landed_side > 0.0 else "left", longest, MOST_FRAMES_STACKED, rose,
				on_floor, clearance]) and passed
	return passed


## The man stands in a hole one body wide; a demon dropped into it lands on him with its feet in the
## hole, so its sides touch the hole's. It is on him for MOST_FRAMES_STACKED at most.
func _a_demon_dropped_onto_the_man_in_a_hole_stops_being_on_him() -> bool:
	var hole: Array[Node] = _make_hole()
	var depth: float = _hole_depth()
	var man: Player = await spawn_on_floor(Vector2(0.0, depth + SPAWN_Y))
	var demon: Demon = _spawn_demon(Vector2(0.0, -DROP_HEIGHT), _make_stats())
	var longest: int = await _longest_stacked_run(demon, man)
	var ever_on_him: bool = _was_ever_stacked
	hole.append_array([man, demon])
	await _clear(hole)
	return report(ever_on_him and longest <= MOST_FRAMES_STACKED,
			"Hole one body wide, demon dropped onto the man in it: landed on him %s, on him %d frames in a row (at most %d)"
			% [ever_on_him, longest, MOST_FRAMES_STACKED])


## A demon stands in a hole one body wide; the man dropped into it lands on it with his feet in the
## hole, so his shove is stopped on both sides. He is on it for MOST_FRAMES_STACKED at most, and
## after that a press of Jump jumps.
func _the_man_dropped_onto_a_demon_in_a_hole_stops_being_on_it_and_jumps() -> bool:
	var hole: Array[Node] = _make_hole()
	var depth: float = _hole_depth()
	var demon: Demon = _spawn_demon(Vector2(0.0, depth + SPAWN_Y), _make_stats())
	await wait_until(demon.is_on_floor)
	var man: Player = spawn_player(Vector2(0.0, -DROP_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(man)
	var longest: int = await _longest_stacked_run(man, demon)
	var ever_on_it: bool = _was_ever_stacked
	var jumped: bool = await _jumps_on_a_press(man, stand_in)
	hole.append_array([man, demon])
	await _clear(hole)
	return report(ever_on_it and longest <= MOST_FRAMES_STACKED and jumped,
			("Hole one body wide, the man dropped onto the demon in it: landed on it %s, on it %d "
			+ "frames in a row (at most %d), jumped on a press after %s")
			% [ever_on_it, longest, MOST_FRAMES_STACKED, jumped])


## The lower body stands against a wall, and the upper one is dropped onto it a little off its middle
## towards the wall, so its shove first goes into the wall. It is on it for MOST_FRAMES_STACKED at
## most and ends up on the open side. Both ways round, with the wall on either side.
func _in_a_corner_the_one_on_top_comes_off_on_the_open_side() -> bool:
	var passed: bool = true
	for man_on_top: bool in [true, false]:
		for side: float in [1.0, -1.0]:
			var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
			var lower_x: float = 0.0
			var man: Player = null
			var demon: Demon = null
			if man_on_top:
				demon = _spawn_demon(Vector2(lower_x, SPAWN_Y), _make_stats())
				await wait_until(demon.is_on_floor)
			else:
				man = await spawn_on_floor(Vector2(lower_x, SPAWN_Y))
			var lower: CharacterBody2D = man
			if man_on_top:
				lower = demon
			var half_width: float = _half_width(lower)
			var face: float = lower_x + side * (half_width + WALL_GAP)
			var wall: StaticBody2D = make_wall(minf(face, face + side * WALL_THICKNESS),
					maxf(face, face + side * WALL_THICKNESS), -WALL_HEIGHT)
			var drop_at: Vector2 = Vector2(lower_x + side * DROP_OFF_CENTRE,
					-_height(lower) - DROP_HEIGHT)
			if man_on_top:
				man = spawn_player(drop_at)
			else:
				demon = _spawn_demon(drop_at, _make_stats())
			var upper: CharacterBody2D = demon
			if man_on_top:
				upper = man
			var longest: int = await _longest_stacked_run(upper, lower)
			var open_side: bool = signf(upper.position.x - lower_x) == -side
			await _clear([ground, wall, man, demon])
			passed = report(longest <= MOST_FRAMES_STACKED and open_side,
					("Corner, wall on the %s, %s dropped onto the %s towards the wall: on it %d frames "
					+ "in a row (at most %d), ended on the open side %s") % [
					"right" if side > 0.0 else "left", "man" if man_on_top else "demon",
					"demon" if man_on_top else "man", longest, MOST_FRAMES_STACKED, open_side]) \
					and passed
	return passed


## The man, at low SP, is bitten and so grabbed by a demon beside him. Another demon, with no attacks,
## dropped onto his head on the other side of his middle comes off it within MOST_FRAMES_STACKED,
## and the first one still holds him.
func _a_demon_comes_off_the_head_of_the_man_another_one_holds() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
		man.soul_points.take_damage(DAMAGE_TO_LOW)
		var holder: Demon = _spawn_demon(Vector2(side * BITE_X, SPAWN_Y), _make_stats(true))
		var grabbed: bool = await wait_until(
				func() -> bool: return holder.get_state() == Demon.State.GRAB)
		var other: Demon = _spawn_demon(
				Vector2(-side * DROP_OFF_CENTRE, -body_size(man).y - DROP_HEIGHT), _make_stats())
		var longest: int = await _longest_stacked_run(other, man)
		var ever_on_him: bool = _was_ever_stacked
		var still_held: bool = holder.get_state() == Demon.State.GRAB
		await _clear([ground, man, holder, other])
		passed = report(grabbed and ever_on_him and longest <= MOST_FRAMES_STACKED and still_held,
				("Man grabbed by a demon on his %s %s; another dropped onto his head landed on it %s, "
				+ "on it %d frames in a row (at most %d), the grab still on %s") % [
				"right" if side > 0.0 else "left", grabbed, ever_on_him, longest,
				MOST_FRAMES_STACKED, still_held]) and passed
	return passed


## The man is dropped onto a demon a little to either side of its middle, and the demon walks after
## him as his shove carries him along its top. He is on it for MOST_FRAMES_STACKED at most; then
## running moves him that way and a press of Jump jumps.
func _the_man_dropped_onto_a_walking_demon_comes_off_and_runs_and_jumps() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var demon: Demon = _spawn_demon(Vector2(0.0, SPAWN_Y), _make_stats())
		await wait_until(demon.is_on_floor)
		var man: Player = spawn_player(
				Vector2(side * DROP_OFF_CENTRE, -_height(demon) - DROP_HEIGHT))
		var stand_in: StandInInput = put_a_stand_in(man)
		var longest: int = await _longest_stacked_run(man, demon)
		var ever_on_it: bool = _was_ever_stacked
		var start_x: float = man.position.x
		stand_in.run_direction = side
		await wait_frames(RUN_FRAMES)
		var ran: bool = side * (man.position.x - start_x) > 0.0
		stand_in.run_direction = 0.0
		var jumped: bool = await _jumps_on_a_press(man, stand_in)
		await _clear([ground, man, demon])
		passed = report(ever_on_it and longest <= MOST_FRAMES_STACKED and ran and jumped,
				("Man dropped onto a demon %+.0f px off its middle, the demon after him: landed on it "
				+ "%s, on it %d frames in a row (at most %d), ran after %s, jumped after %s") % [
				side * DROP_OFF_CENTRE, ever_on_it, longest, MOST_FRAMES_STACKED, ran, jumped]) \
				and passed
	return passed


## PACK_SIZE demons after the man stand in a row, Pack Spacing apart, which is less than his width,
## and he is dropped a little to either side of the middle one's middle. His shove carries him from
## one top to the next as they walk after him. He is on their tops for MOST_FRAMES_STACKED at most
## in all; then running moves him that way and a press of Jump jumps.
func _the_man_dropped_onto_a_pack_comes_off_it_and_runs_and_jumps() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var made: Array[Node] = [ground]
		var pack: Array[Demon] = []
		var apart: float = _body_width() + PACK_SPACING
		for index: int in PACK_SIZE:
			var stats: DemonStats = _make_stats()
			stats.pack_spacing = PACK_SPACING
			var demon: Demon = _spawn_demon(
					Vector2((index - (PACK_SIZE - 1) / 2.0) * apart, SPAWN_Y), stats)
			pack.append(demon)
			made.append(demon)
		for demon: Demon in pack:
			await wait_until(demon.is_on_floor)
		var man: Player = spawn_player(
				Vector2(side * DROP_OFF_CENTRE, -_body_height() - DROP_HEIGHT))
		made.append(man)
		var stand_in: StandInInput = put_a_stand_in(man)
		var frames_on_tops: int = 0
		for _frame: int in WATCH_FRAMES:
			await physics_frame
			for demon: Demon in pack:
				if _is_stacked(man, demon):
					frames_on_tops += 1
					break
		var start_x: float = man.position.x
		stand_in.run_direction = side
		await wait_frames(RUN_FRAMES)
		var ran: bool = side * (man.position.x - start_x) > 0.0
		stand_in.run_direction = 0.0
		var jumped: bool = await _jumps_on_a_press(man, stand_in)
		await _clear(made)
		passed = report(frames_on_tops > 0 and frames_on_tops <= MOST_FRAMES_STACKED and ran
				and jumped,
				("Man dropped onto the middle of %d demons %.0f px apart, %+.0f px off its middle: on "
				+ "their tops %d frames in all (at most %d), ran after %s, jumped after %s") % [
				PACK_SIZE, PACK_SPACING, side * DROP_OFF_CENTRE, frames_on_tops,
				MOST_FRAMES_STACKED, ran, jumped]) and passed
	return passed


## The man stands in a hole one body wide and a demon with a bite, after him, drops in on him. While
## their bodies overlap side to side, whether stacked or one inside the other, no hit lands on his
## Hurtbox. The demon must be after him at some point, or the case shows nothing.
func _with_the_bodies_overlapping_in_a_hole_no_hit_lands() -> bool:
	var hole: Array[Node] = _make_hole()
	var depth: float = _hole_depth()
	var man: Player = await spawn_on_floor(Vector2(0.0, depth + SPAWN_Y))
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	var demon: Demon = _spawn_demon(Vector2(0.0, -DROP_HEIGHT), _make_stats(true))
	var overlapping: Array[bool] = [false]
	var hits_while_overlapping: Array[int] = [0]
	var count_hit: Callable = func(_hitbox: Hitbox) -> void:
		if overlapping[0]:
			hits_while_overlapping[0] += 1
	hurtbox.hit_received.connect(count_hit)
	var after_him: bool = false
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		overlapping[0] = _overlap_side_to_side(man, demon)
		after_him = after_him or (overlapping[0] and demon.has_target())
	hole.append_array([man, demon])
	await _clear(hole)
	return report(after_him and hits_while_overlapping[0] == 0,
			"Hole one body wide, demon with a bite dropped onto the man: after him while overlapping %s, hits that landed then %d"
			% [after_him, hits_while_overlapping[0]])


## Watches upper and lower for WATCH_FRAMES and hands back the longest run of frames upper rests on
## lower; _was_ever_stacked says whether it ever did.
func _longest_stacked_run(upper: CharacterBody2D, lower: CharacterBody2D) -> int:
	_was_ever_stacked = false
	var longest: int = 0
	var run: int = 0
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		if _is_stacked(upper, lower):
			_was_ever_stacked = true
			run += 1
			longest = maxi(longest, run)
		else:
			run = 0
	return longest


## True while upper stands on lower: on a floor, overlapping it side to side, with its feet on
## lower's top.
func _is_stacked(upper: CharacterBody2D, lower: CharacterBody2D) -> bool:
	return upper.is_on_floor() and _overlap_side_to_side(upper, lower) \
			and absf(upper.position.y - (lower.position.y - _height(lower))) <= STACK_TOLERANCE


## True while the two bodies' boxes overlap along x.
func _overlap_side_to_side(one: CharacterBody2D, other: CharacterBody2D) -> bool:
	return absf(one.position.x - other.position.x) < _half_width(one) + _half_width(other)


## Presses Jump once the man is on a floor and true if he jumps within the jump buffer.
func _jumps_on_a_press(man: Player, stand_in: StandInInput) -> bool:
	if not await wait_until_on_floor(man):
		return false
	stand_in.press_jump()
	var previous_speed: float = man.velocity.y
	for _frame: int in JUMP_FRAMES:
		await physics_frame
		if is_jump(previous_speed, man.velocity.y):
			return true
		previous_speed = man.velocity.y
	return false


## A floor with a hole one body wide around x = 0, _hole_depth() deep, its sides solid down to its
## bottom, already in the scene.
func _make_hole() -> Array[Node]:
	var half: float = (_body_width() + HOLE_SLACK) / 2.0
	var depth: float = _hole_depth()
	return [make_wall(FLOOR_LEFT, -half, 0.0, depth), make_wall(half, FLOOR_RIGHT, 0.0, depth),
			make_platform(-half, half, depth)]


func _hole_depth() -> float:
	return HOLE_DEPTH_IN_BODIES * _body_height()


## A demon from demon.tscn with stats, at the given spot, in the scene; it may still be in the air.
func _spawn_demon(at: Vector2, stats: DemonStats) -> Demon:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.stats = stats
	demon.position = at
	root.add_child(demon)
	return demon


## The cases' demon stats: it sees and chases the man and has no attacks, or only a bite with bite.
func _make_stats(bite: bool = false) -> DemonStats:
	var stats: DemonStats = DemonStats.new()
	stats.sight_distance = SIGHT_DISTANCE
	stats.lose_distance = LOSE_DISTANCE
	stats.chase_speed = CHASE_SPEED
	if bite:
		var attack: DemonAttack = DemonAttack.new()
		attack.animation = &"bite"
		attack.keeps_chasing = true
		attack.attack_range = BITE_RANGE
		attack.warning_time = BITE_WARNING_TIME
		attack.recover_time = BITE_RECOVER_TIME
		stats.attacks.append(attack)
	return stats


## The demon's body box, read from demon.tscn; the man's in player.tscn is the same size, so the
## hole fits either.
func _body_box() -> Vector2:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	var size: Vector2 = ((demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape
			as RectangleShape2D).size
	demon.free()
	return size


func _body_width() -> float:
	return _body_box().x


func _body_height() -> float:
	return _body_box().y


func _half_width(body: CharacterBody2D) -> float:
	return _box_of(body).x / 2.0


func _height(body: CharacterBody2D) -> float:
	return _box_of(body).y


func _box_of(body: CharacterBody2D) -> Vector2:
	return ((body.get_node(^"CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size


## How far apart the man's middle and the demon's are with their bodies touching side to side.
func _contact_distance(man: Player, demon: Demon) -> float:
	return _half_width(man) + _half_width(demon)


## Takes out what a case made at the end of the frame, and waits for it.
func _clear(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame
