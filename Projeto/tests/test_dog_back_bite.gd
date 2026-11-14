# Checks the bite on a dog's back (ADR 0056): a demon with Bites Who Lands On It bites the man who
# lands on it, as in an attack, so he can't ride a pack. Landing on one bites him once, with the SP
# of its bite, and throws him up and further than a bite does: off it and, from the middle of a
# pack, clear of the pack. Between two dogs, only one bites; on a dog's edge, down to 1 px of him
# over it, it bites from any height; on the same dog again, it bites again, also when its throw is
# too small to take him off it. Touching its side, jumping beside it, passing through it on the
# floor and jumping out of it, or standing on a ledge just above it, does not bite. Without it, a
# demon only shoves him off its top (ADR 0022). With his SP low, or when it would take them all,
# the bite grabs him, as any hit, and he falls through the dog to the floor and sinks there, never
# on a back: held on two backs, he falls through both, and on two dogs' backs at low SP, one bite
# grabs him and one dog holds him; breaking free throws the dog off, and the two collide again once
# apart; in a hole too deep for a throw to take him out, a grab ends the bites; by a wall that
# leaves him no room beside the dog, it throws him to the open side. It bites him within
# any blink, after a hit or after breaking free of a grab, but not with his Hurtbox closed. A
# knockback on a demon's top throws the man up, off it, instead of the shove taking it over. The
# bite turns on and off with its stats in the scene; both dogs' stats have it, and a demon's stats
# have it off. The dogs are demon.tscn with stats made here that never see the man, so they never
# chase nor attack him, and only the bite on the back can hurt him.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dog_back_bite.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## The stats of the game's dogs, which must bite who lands on them.
const DOG_STATS_PATHS: Array[String] = [
	"res://demon/lust_demon_stats.tres",
	"res://levels/jumping_demon_stats.tres",
]
## A little above the floor, so a body lands on its own before a case starts.
const SPAWN_Y: float = -2.0
## The floor of every case, wide enough that nothing walks off it.
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## How far to one side of a dog's middle the man is dropped, and from how high above its top, in px.
const DROP_OFF_CENTRE: float = 8.0
const DROP_HEIGHT: float = 24.0
## How far apart the feet of the upper body and the top of the lower one, or the man's feet and the
## floor, may be, in px, and still be resting on it.
const STACK_TOLERANCE: float = 2.0
## How many frames a case watches for: three seconds.
const WATCH_FRAMES: int = 180
## A Sight Distance too short to see the man anywhere, so the dogs never chase nor attack him.
const SHORT_SIGHT: float = 10.0
## The bite of the cases' dogs, which gives the bite on the back its SP.
const BITE_DAMAGE: float = 10.0
## The most frames the man may stand on dogs' backs once their bite is on: the frame he lands, the
## next one if the bite lands on it, and one to spare.
const MOST_FRAMES_ON_BACKS: int = 3
## Without the bite, the most frames in a row the man rests on a demon (test_stacked_bodies.gd).
const MOST_FRAMES_STACKED: int = 20
## Share of a knockback's height the man must rise above the top he was thrown from.
const RISE_SHARE: float = 0.9
## The pack: this many dogs, Pack Spacing apart as in lust_demon_stats.tres, so the man, wider than
## the gaps, could be shoved from one back to the next all along it.
const PACK_SIZE: int = 5
const PACK_SPACING: float = 24.0
## Where the man starts in the side case, and for how many frames he runs into the dog's side and
## then watches his jump beside it.
const SIDE_START_X: float = -150.0
const SIDE_RUN_FRAMES: int = 60
const SIDE_JUMP_FRAMES: int = 60
## Frames after a press of Jump in which the man must jump.
const JUMP_FRAMES: int = PRESS_DELAY_FRAMES + 2
## Frames the case where the man and a dog pass through each other on the floor watches for.
const THROUGH_FRAMES: int = 30
## SP damage taken before the cases at low SP, to leave the man at 20 of 100, under Low Threshold,
## so a hit grabs him.
const DAMAGE_TO_LOW: float = 80.0
## Frames the grab must still be on after the man has fallen through the dog: a second.
const GRAB_HOLD_FRAMES: int = 60
## The most frames the man is still held on dogs' backs once held: the frame he is held on them and
## the next, on which he falls through the one under him, or the second of two; and the frames he
## has to reach the floor below.
const MOST_FRAMES_HELD_ON_A_BACK: int = 2
const FALL_FRAMES: int = 60
## Frames between presses of Jump to break free of a grab, and the most presses before giving up.
const PRESS_GAP_FRAMES: int = 4
const MOST_PRESSES: int = 40
## Frames the man and the dog have, once he breaks free, to be apart and collide again.
const APART_FRAMES: int = 120
## The hole of the hole case: a body's width and a little more, so the man falls in onto the dog,
## and deep enough that the bite's throw can't take him out of it; and the frames to wait for the
## grab in it.
const HOLE_SLACK: float = 4.0
const HOLE_DEPTH_IN_BODIES: float = 2.5
const HOLE_WATCH_FRAMES: int = 600
## How much more room than the man's width is between the dog and the wall in the wall case, in px:
## under 0, he can't come down beside the dog there, down to half a pixel short; over 0, he can. And
## the wall's thickness, and its top, higher than the bite throws him, in px; and how far below the
## dog's top the top of a wall lower than the dog is, in px.
const WALL_GAP_OFFSETS: Array[float] = [-31.0, -10.0, -0.5, 0.5, 10.0]
const WALL_THICKNESS: float = 32.0
const WALL_TOP: float = -600.0
const LOW_WALL_BELOW_TOP: float = 36.0
## Where the man is dropped between two dogs at low SP, from the left one's middle: at the middle of
## the gap and to either side, always on both backs; and where he waits on the floor, far from them,
## when he is added to the scene before them.
const LOW_SP_GAP_XS: Array[float] = [30.0, 36.0, 42.0]
const PARKED_X: float = 1000.0
## The ledge just above a dog's back: how far above its top, how thick and how wide each side of
## the dog's middle, in px.
const LEDGE_GAP: float = 8.0
const LEDGE_THICKNESS: float = 8.0
const LEDGE_HALF_WIDTH: float = 40.0
## The second dog of the blink case, this far from the first, and the frames after the first bite
## before the man is put above it: well within the blink of a second after a hit.
const SECOND_DOG_X: float = 600.0
const FRAMES_BEFORE_SECOND_DOG: int = 10
## How high the bite throws the man in the case where its throw is too small to take him off the
## dog, in px, straight up: well under the space above its top it looks in.
const BOUNCE_HEIGHT: float = 16.0
## The knockback of the knock-off case, a bite's.
const KNOCK_DISTANCE: float = 150.0
const KNOCK_HEIGHT: float = 40.0
## The SP of the bites in the case of the damage on the back: the first bite's is the one taken.
const FIRST_BITE_DAMAGE: float = 15.0
const SECOND_BITE_DAMAGE: float = 30.0
const LUNGE_DAMAGE: float = 20.0
## Where the man is dropped between two dogs, besides the middle of the gap: nearer the left one.
const BETWEEN_NEARER_X: float = 30.0
## How far from a dog's middle the man's middle is in the edge case, in px, with 8 px, 4 px and 1 px
## of him over its back, and the heights above its top he is dropped from there, in px.
const EDGE_OFFSETS: Array[float] = [40.0, 44.0, 47.0]
const EDGE_DROP_HEIGHTS: Array[float] = [24.0, 76.0, 89.0, 102.0, 115.0, 128.0]


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _landing_on_a_dog_bites_once_and_throws_the_man_off())
	results.append(await _a_pack_does_not_carry_the_man_across())
	results.append(await _landing_between_two_dogs_bites_once())
	results.append(await _landing_on_a_dog_s_edge_bites_from_any_height())
	results.append(await _landing_again_on_the_same_dog_bites_again())
	results.append(await _every_landing_bites_also_without_leaving_the_dog())
	results.append(await _touching_a_dog_s_side_or_passing_through_it_does_not_bite())
	results.append(await _standing_on_a_ledge_above_a_dog_does_not_bite())
	results.append(await _a_dog_without_the_bite_only_shoves_the_man_off())
	results.append(await _with_low_sp_the_bite_grabs_and_the_man_falls_through_the_dog())
	results.append(await _held_on_two_backs_the_man_falls_through_both())
	results.append(await _with_low_sp_on_two_backs_one_bite_grabs())
	results.append(await _breaking_free_of_the_bite_on_the_back_throws_the_dog_off())
	results.append(await _in_a_hole_too_deep_to_be_thrown_out_of_a_grab_ends_the_bites())
	results.append(await _by_a_wall_the_bite_throws_the_man_to_the_open_side())
	results.append(await _a_landing_in_the_blink_after_a_bite_is_bitten_again())
	results.append(await _a_landing_after_breaking_free_of_a_grab_is_bitten())
	results.append(await _with_his_hurtbox_closed_the_bite_does_not_land())
	results.append(await _a_knockback_on_a_demon_s_top_throws_the_man_off_it())
	results.append(await _the_bite_turns_on_and_off_with_its_stats())
	results.append(_both_dogs_bite_who_lands_on_them())
	finish(results)


## The man is dropped onto a dog a little to either side of its middle. Its back bites him once,
## with the SP of its bite and the knockback of the bite on the back, and throws him to that side:
## up, at least RISE_SHARE of Back Bite Knockback Height above its top, and down on the floor at
## least Back Bite Knockback Distance from its middle, further than a bite of its own throws him.
func _landing_on_a_dog_bites_once_and_throws_the_man_off() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var stats: DemonStats = _make_stats(true)
		var dog: Demon = await _spawn_dog_on_floor(0.0, stats)
		var top: float = dog.position.y - _height(dog)
		var man: Player = spawn_player(Vector2(side * DROP_OFF_CENTRE, top - DROP_HEIGHT))
		var hits: Array[Hitbox] = []
		var sp_after: Array[float] = []
		_record_hits(man, hits, sp_after)
		var flight: Flight = await _follow_the_throw(man, top, hits)
		var max_sp: float = man.soul_points.get_max_sp()
		var thrown: float = side * (flight.landed_x - dog.position.x)
		var bite_values: bool = hits.size() == 1 and hits[0].damage == BITE_DAMAGE \
				and hits[0].knockback_distance == stats.back_bite_knockback_distance \
				and hits[0].knockback_height == stats.back_bite_knockback_height
		var sp_taken: float = max_sp - sp_after[0] if sp_after.size() > 0 else 0.0
		await _clear([ground, dog, man])
		passed = report(bite_values and sp_taken == BITE_DAMAGE
				and flight.rose >= RISE_SHARE * stats.back_bite_knockback_height
				and thrown >= stats.back_bite_knockback_distance,
				("Man dropped onto a dog %+.0f px off its middle: %d hits, with the bite on the back's "
				+ "values %s, took %.0f SP (the bite's %.0f), rose %.1f px above its top (at least "
				+ "%.0f), landed on the floor %.1f px from its middle on that side (at least %.0f)")
				% [side * DROP_OFF_CENTRE, hits.size(), bite_values, sp_taken, BITE_DAMAGE,
				flight.rose, RISE_SHARE * stats.back_bite_knockback_height, thrown,
				stats.back_bite_knockback_distance]) and passed
	return passed


## PACK_SIZE dogs stand in a row, Pack Spacing apart, and the man is dropped a little to either side
## of the middle one's middle. Its back bites him once and throws him clear of the pack: he stands
## on their backs MOST_FRAMES_ON_BACKS frames at most, not carried from one to the next, and lands
## on the floor past the pack's end on that side.
func _a_pack_does_not_carry_the_man_across() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var made: Array[Node] = [ground]
		var pack: Array[Demon] = []
		var apart: float = _body_width() + PACK_SPACING
		for index: int in PACK_SIZE:
			var stats: DemonStats = _make_stats(true)
			stats.pack_spacing = PACK_SPACING
			var dog: Demon = _spawn_demon(
					Vector2((index - (PACK_SIZE - 1) / 2.0) * apart, SPAWN_Y), stats)
			pack.append(dog)
			made.append(dog)
		for dog: Demon in pack:
			await wait_until(dog.is_on_floor)
		var top: float = pack[0].position.y - _height(pack[0])
		var man: Player = spawn_player(Vector2(side * DROP_OFF_CENTRE, top - DROP_HEIGHT))
		made.append(man)
		var hits: Array[Hitbox] = []
		var sp_after: Array[float] = []
		_record_hits(man, hits, sp_after)
		var frames_on_backs: int = 0
		var landed_x: float = NAN
		for _frame: int in WATCH_FRAMES:
			await physics_frame
			for dog: Demon in pack:
				if _is_stacked(man, dog):
					frames_on_backs += 1
					break
			if _is_on_the_floor(man):
				landed_x = man.position.x
				break
		var past_the_end: float = (PACK_SIZE - 1) / 2.0 * apart + _body_width()
		var clear: bool = side * landed_x >= past_the_end
		await _clear(made)
		passed = report(hits.size() == 1 and frames_on_backs <= MOST_FRAMES_ON_BACKS and clear,
				("Man dropped onto the middle of %d dogs %.0f px apart, %+.0f px off its middle: %d "
				+ "hits (1), on their backs %d frames (at most %d), landed on the floor at x = %.1f, "
				+ "clear of the pack (past %.0f on that side) %s") % [PACK_SIZE, PACK_SPACING,
				side * DROP_OFF_CENTRE, hits.size(), frames_on_backs, MOST_FRAMES_ON_BACKS,
				landed_x, side * past_the_end, clear]) and passed
	return passed


## Two dogs side by side, Pack Spacing apart, and the man dropped between their middles: at the
## middle of the gap and nearer the left one, so he stands on both backs at once. Only one bites,
## once, and throws him off.
func _landing_between_two_dogs_bites_once() -> bool:
	var passed: bool = true
	var apart: float = _body_width() + PACK_SPACING
	for x: float in [apart / 2.0, BETWEEN_NEARER_X]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var left_stats: DemonStats = _make_stats(true)
		left_stats.pack_spacing = PACK_SPACING
		var right_stats: DemonStats = _make_stats(true)
		right_stats.pack_spacing = PACK_SPACING
		var left: Demon = await _spawn_dog_on_floor(0.0, left_stats)
		var right: Demon = await _spawn_dog_on_floor(apart, right_stats)
		var top: float = left.position.y - _height(left)
		var man: Player = spawn_player(Vector2(x, top - DROP_HEIGHT))
		var hits: Array[Hitbox] = []
		var sp_after: Array[float] = []
		_record_hits(man, hits, sp_after)
		var landed: bool = await _wait_to_land_on_the_floor(man)
		await _clear([ground, left, right, man])
		passed = report(landed and hits.size() == 1,
				("Man dropped between two dogs %.0f px apart, %.0f px from the left one's middle: "
				+ "%d hits (1), on the floor after %s") % [apart, x, hits.size(), landed]) and passed
	return passed


## The man is dropped onto a dog with only its edge under him, his middle EDGE_OFFSETS px from the
## dog's, from each of EDGE_DROP_HEIGHTS above its top, onto a new dog each time: every landing
## bites once, however fast he falls, though the shove takes him off the edge on the next frame.
func _landing_on_a_dog_s_edge_bites_from_any_height() -> bool:
	var passed: bool = true
	for offset: float in EDGE_OFFSETS:
		var counts: Array[int] = []
		for height: float in EDGE_DROP_HEIGHTS:
			var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
			var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(true))
			var top: float = dog.position.y - _height(dog)
			var man: Player = spawn_player(Vector2(offset, top - height))
			var hits: Array[Hitbox] = []
			var sp_after: Array[float] = []
			_record_hits(man, hits, sp_after)
			await _wait_to_land_on_the_floor(man)
			counts.append(hits.size())
			await _clear([ground, dog, man])
		passed = report(counts.all(func(count: int) -> bool: return count == 1),
				("Man dropped onto a dog's edge, his middle %.0f px from its middle, from %s px "
				+ "above it: hits %s (1 each)") % [offset, EDGE_DROP_HEIGHTS, counts]) and passed
	return passed


## The man dropped onto a dog is bitten and thrown off. Once on the floor and no longer blinking, he
## is put above the same dog and dropped onto it again: it bites him again.
func _landing_again_on_the_same_dog_bites_again() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(true))
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var first_landed: bool = await _wait_to_land_on_the_floor(man)
	var blink_over: bool = await wait_until(func() -> bool: return not hurtbox.is_invulnerable())
	man.position = Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT)
	man.velocity = Vector2.ZERO
	var second_landed: bool = await _wait_to_land_on_the_floor(man)
	await _clear([ground, dog, man])
	return report(first_landed and blink_over and second_landed and hits.size() == 2,
			("Man dropped onto a dog, thrown to the floor %s, done blinking %s, dropped onto it "
			+ "again and thrown to the floor %s: %d hits (2)") % [first_landed, blink_over,
			second_landed, hits.size()])


## The bite on a dog's back throws the man only BOUNCE_HEIGHT up, straight up, with Back Bite
## Knockback Distance 0, so he lands on the dog again without having left the space above its top
## it looks in: that landing bites him again and takes the SP of its bite again, as every landing
## does, not only the first since he came.
func _every_landing_bites_also_without_leaving_the_dog() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var stats: DemonStats = _make_stats(true)
	stats.back_bite_knockback_distance = 0.0
	stats.back_bite_knockback_height = BOUNCE_HEIGHT
	var dog: Demon = await _spawn_dog_on_floor(0.0, stats)
	var back: Area2D = dog.get_node(^"BackBite") as Area2D
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var damage: Array[float] = _record_damage(man)
	var stayed: bool = true
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		if hits.size() >= 2:
			break
		if not hits.is_empty():
			stayed = stayed and back.overlaps_body(man)
	await _clear([ground, dog, man])
	return report(hits.size() == 2 and stayed and damage.size() == 2 and damage[1] == BITE_DAMAGE,
			("Man thrown %.0f px straight up by a dog's back: bitten %d times (2), never left the "
			+ "space above it between bites %s, SP taken %s (%.0f each)") % [BOUNCE_HEIGHT,
			hits.size(), stayed, damage, BITE_DAMAGE])


## The man runs into a dog's side, and once against it, jumps straight up beside it and lands beside
## it again; then he and the dog pass through each other on the floor, as in a hole one body wide
## (ADR 0047), and he jumps out of it, up through its back, and falls back through it. Nothing
## bites: the bite is only for who stands on the dog.
func _touching_a_dog_s_side_or_passing_through_it_does_not_bite() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(true))
	var man: Player = await spawn_on_floor(Vector2(SIDE_START_X, SPAWN_Y))
	var stand_in: StandInInput = put_a_stand_in(man)
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	stand_in.run_direction = 1.0
	await wait_frames(SIDE_RUN_FRAMES)
	stand_in.run_direction = 0.0
	var against: bool = absf(dog.position.x - man.position.x) \
			<= _half_width(man) + _half_width(dog) + STACK_TOLERANCE
	stand_in.press_jump()
	var jumped: bool = await wait_until(func() -> bool: return not man.is_on_floor(), JUMP_FRAMES)
	await wait_frames(SIDE_JUMP_FRAMES)
	var back_beside: bool = _is_on_the_floor(man) and not _overlap_side_to_side(man, dog)
	var side_hits: int = hits.size()
	man.add_collision_exception_with(dog)
	dog.add_collision_exception_with(man)
	man.position.x = dog.position.x
	await wait_frames(THROUGH_FRAMES)
	var through: bool = _overlap_side_to_side(man, dog) and _is_on_the_floor(man)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var jumped_out: bool = await wait_until(
			func() -> bool: return man.position.y < dog.position.y - _height(dog), MAX_FRAMES)
	stand_in.hold_jump = false
	var fell_back: bool = await _wait_to_land_on_the_floor(man)
	var through_hits: int = hits.size() - side_hits
	await _clear([ground, dog, man])
	return report(against and jumped and back_beside and side_hits == 0 and through and jumped_out
			and fell_back and through_hits == 0,
			("Man against a dog's side %s, jumped beside it %s and landed beside it %s: %d hits; "
			+ "passing through it on the floor %s, jumped out above its back %s and fell back "
			+ "through it %s: %d hits") % [against, jumped, back_beside, side_hits, through,
			jumped_out, fell_back, through_hits])


## A ledge stands just above a dog, LEDGE_GAP above its top, and the man lands on it, in the space
## above the dog's top the bite looks in: standing on the ledge, he is not on the dog, so it does
## not bite.
func _standing_on_a_ledge_above_a_dog_does_not_bite() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(true))
	var top: float = dog.position.y - _height(dog)
	var ledge_top: float = top - LEDGE_GAP - LEDGE_THICKNESS
	var ledge: StaticBody2D = make_wall(-LEDGE_HALF_WIDTH, LEDGE_HALF_WIDTH, ledge_top,
			top - LEDGE_GAP)
	var man: Player = spawn_player(Vector2(0.0, ledge_top - DROP_HEIGHT))
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var on_ledge: bool = await wait_until(func() -> bool:
			return man.is_on_floor() and absf(man.position.y - ledge_top) <= STACK_TOLERANCE)
	var in_space: bool = (dog.get_node(^"BackBite") as Area2D).overlaps_body(man)
	await wait_frames(WATCH_FRAMES)
	await _clear([ground, dog, ledge, man])
	return report(on_ledge and in_space and hits.is_empty(),
			("Man on a ledge %.0f px above a dog's top: on the ledge %s, in the space above the dog "
			+ "%s, %d hits (none)") % [LEDGE_GAP, on_ledge, in_space, hits.size()])


## A dog without Bites Who Lands On It, the man dropped onto it a little to either side of its
## middle: no hit, and he is shoved off its top as before (ADR 0022), on it MOST_FRAMES_STACKED
## frames in a row at most, and on the floor after.
func _a_dog_without_the_bite_only_shoves_the_man_off() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(false))
		var top: float = dog.position.y - _height(dog)
		var man: Player = spawn_player(Vector2(side * DROP_OFF_CENTRE, top - DROP_HEIGHT))
		var hits: Array[Hitbox] = []
		var sp_after: Array[float] = []
		_record_hits(man, hits, sp_after)
		var ever_on_it: bool = false
		var longest: int = 0
		var run: int = 0
		for _frame: int in WATCH_FRAMES:
			await physics_frame
			if _is_stacked(man, dog):
				ever_on_it = true
				run += 1
				longest = maxi(longest, run)
			else:
				run = 0
		var on_floor: bool = _is_on_the_floor(man)
		await _clear([ground, dog, man])
		passed = report(ever_on_it and longest <= MOST_FRAMES_STACKED and on_floor
				and hits.is_empty(),
				("Man dropped onto a dog without the bite on its back, %+.0f px off its middle: "
				+ "landed on it %s, on it %d frames in a row (at most %d), on the floor after %s, "
				+ "%d hits") % [side * DROP_OFF_CENTRE, ever_on_it, longest, MOST_FRAMES_STACKED,
				on_floor, hits.size()]) and passed
	return passed


## With the man's SP low, and at full SP with a bite that would take them all, the bite on a dog's
## back grabs him, as any hit would (ADR 0021), and takes no SP. He is held on its back
## MOST_FRAMES_HELD_ON_A_BACK frames at most: he falls through the dog to the floor and sinks
## there, held by it (GRAB) though it had not seen him, and a second later both still hold on.
func _with_low_sp_the_bite_grabs_and_the_man_falls_through_the_dog() -> bool:
	var passed: bool = true
	for low: bool in [true, false]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var stats: DemonStats = _make_stats(true)
		var dog: Demon = await _spawn_dog_on_floor(0.0, stats)
		var top: float = dog.position.y - _height(dog)
		var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
		if low:
			man.soul_points.take_damage(DAMAGE_TO_LOW)
		else:
			stats.attacks[0].damage = man.soul_points.get_sp()
		var sp_before: float = man.soul_points.get_sp()
		var grab: GrabEscape = man.get_node(^"GrabEscape") as GrabEscape
		var hits: Array[Hitbox] = []
		var sp_after: Array[float] = []
		_record_hits(man, hits, sp_after)
		var damage: Array[float] = _record_damage(man)
		var grabbed: bool = await wait_until(grab.is_held)
		var held_on_back: int = 0
		var on_floor: bool = false
		for _frame: int in FALL_FRAMES:
			if _is_stacked(man, dog):
				held_on_back += 1
			if _is_on_the_floor(man):
				on_floor = true
				break
			await physics_frame
		await wait_frames(GRAB_HOLD_FRAMES)
		var still_held: bool = grab.is_held() and dog.get_state() == Demon.State.GRAB
		await _clear([ground, dog, man])
		passed = report(grabbed and hits.size() == 1 and damage.is_empty()
				and held_on_back <= MOST_FRAMES_HELD_ON_A_BACK and on_floor and still_held,
				("Man at %.0f SP dropped onto a dog whose bite takes %.0f: grabbed %s, %d hits (1), "
				+ "SP taken %s (none), held on its back %d frames (at most %d), on the floor below "
				+ "it %s, both still holding on %d frames later %s") % [sp_before,
				stats.get_back_bite_damage(), grabbed, hits.size(), damage, held_on_back,
				MOST_FRAMES_HELD_ON_A_BACK, on_floor, GRAB_HOLD_FRAMES, still_held]) and passed
	return passed


## The man, held still as a demon's grab holds him, is dropped between two dogs without the bite,
## Pack Spacing apart, so he lands held on both backs at once: he falls through both to the floor,
## held on them MOST_FRAMES_HELD_ON_A_BACK frames at most.
func _held_on_two_backs_the_man_falls_through_both() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var apart: float = _body_width() + PACK_SPACING
	var left_stats: DemonStats = _make_stats(false)
	left_stats.pack_spacing = PACK_SPACING
	var right_stats: DemonStats = _make_stats(false)
	right_stats.pack_spacing = PACK_SPACING
	var left: Demon = await _spawn_dog_on_floor(0.0, left_stats)
	var right: Demon = await _spawn_dog_on_floor(apart, right_stats)
	var top: float = left.position.y - _height(left)
	var man: Player = spawn_player(Vector2(apart / 2.0, top - DROP_HEIGHT))
	man.hold_still()
	var on_both: bool = await wait_until(func() -> bool:
			return _is_stacked(man, left) and _is_stacked(man, right))
	var held_on_backs: int = 0
	var on_floor: bool = false
	for _frame: int in FALL_FRAMES:
		if _is_stacked(man, left) or _is_stacked(man, right):
			held_on_backs += 1
		if _is_on_the_floor(man):
			on_floor = true
			break
		await physics_frame
	await _clear([ground, left, right, man])
	return report(on_both and held_on_backs <= MOST_FRAMES_HELD_ON_A_BACK and on_floor,
			("Man held still, dropped between two dogs %.0f px apart: on both backs %s, held on "
			+ "them %d frames (at most %d), on the floor below them %s") % [apart, on_both,
			held_on_backs, MOST_FRAMES_HELD_ON_A_BACK, on_floor])


## The man at low SP is dropped between two dogs with the bite, onto both backs at once, at each of
## LOW_SP_GAP_XS, added to the scene after the dogs and before them, as the physics runs them in
## that order: one bite grabs him and only one dog holds him, though he falls through it and onto
## the other's back on his way down.
func _with_low_sp_on_two_backs_one_bite_grabs() -> bool:
	var passed: bool = true
	var apart: float = _body_width() + PACK_SPACING
	for man_first: bool in [false, true]:
		var counts: Array[String] = []
		var all_once: bool = true
		for x: float in LOW_SP_GAP_XS:
			var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
			var man: Player = spawn_player(Vector2(PARKED_X, SPAWN_Y)) if man_first else null
			var left_stats: DemonStats = _make_stats(true)
			left_stats.pack_spacing = PACK_SPACING
			var right_stats: DemonStats = _make_stats(true)
			right_stats.pack_spacing = PACK_SPACING
			var left: Demon = await _spawn_dog_on_floor(0.0, left_stats)
			var right: Demon = await _spawn_dog_on_floor(apart, right_stats)
			var top: float = left.position.y - _height(left)
			if man_first:
				man.position = Vector2(x, top - DROP_HEIGHT)
				man.velocity = Vector2.ZERO
			else:
				man = spawn_player(Vector2(x, top - DROP_HEIGHT))
			man.soul_points.take_damage(DAMAGE_TO_LOW)
			var grab: GrabEscape = man.get_node(^"GrabEscape") as GrabEscape
			var hits: Array[Hitbox] = []
			var sp_after: Array[float] = []
			_record_hits(man, hits, sp_after)
			var grabbed: bool = await wait_until(grab.is_held)
			await wait_frames(FALL_FRAMES)
			var holding: int = 0
			for dog: Demon in [left, right]:
				if dog.get_state() == Demon.State.GRAB:
					holding += 1
			counts.append("%d/%d" % [hits.size(), holding])
			all_once = all_once and grabbed and hits.size() == 1 and holding == 1
			await _clear([ground, left, right, man])
		passed = report(all_once,
				("Man at low SP dropped between two dogs %.0f px apart, added to the scene %s them, "
				+ "at x = %s: bites/dogs holding him %s (1/1 each)") % [apart,
				"before" if man_first else "after", LOW_SP_GAP_XS, counts]) and passed
	return passed


## The man at low SP is grabbed by the bite on a dog's back, falls through it, and breaks free with
## presses of Jump: the dog lets go and is thrown off (THROWN), as from a grab of its own bite, and
## within APART_FRAMES the two collide again, their boxes apart.
func _breaking_free_of_the_bite_on_the_back_throws_the_dog_off() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(true))
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	var grab: GrabEscape = man.get_node(^"GrabEscape") as GrabEscape
	var states: Array[int] = []
	dog.state_changed.connect(func(_previous: Demon.State, current: Demon.State) -> void:
		states.append(current))
	var grabbed: bool = await wait_until(grab.is_held)
	var free: bool = false
	for _press: int in MOST_PRESSES:
		stand_in.press_jump()
		await wait_frames(PRESS_GAP_FRAMES)
		if not grab.is_held():
			free = true
			break
	var thrown: bool = states.has(Demon.State.THROWN)
	var colliding: bool = await wait_until(func() -> bool:
			return (not man.get_collision_exceptions().has(dog)
					and not dog.get_collision_exceptions().has(man)), APART_FRAMES)
	await _clear([ground, dog, man])
	return report(grabbed and free and thrown and colliding,
			("Man at low SP grabbed by the bite on a dog's back %s, broke free %s, the dog thrown "
			+ "off %s, the two colliding again %s") % [grabbed, free, thrown, colliding])


## A dog stands at the bottom of a hole one body wide, HOLE_DEPTH_IN_BODIES deep, too deep for the
## bite's throw to take the man out of it. Dropped onto the dog, he is bitten each time he falls
## back onto it, until his SP are low; then its bite grabs him, and he falls through it and is held
## on the hole's floor within HOLE_WATCH_FRAMES: he is never thrown up and down in it for ever.
func _in_a_hole_too_deep_to_be_thrown_out_of_a_grab_ends_the_bites() -> bool:
	var box: Vector2 = _demon_box()
	var half: float = (box.x + HOLE_SLACK) / 2.0
	var depth: float = HOLE_DEPTH_IN_BODIES * box.y
	var made: Array[Node] = [make_wall(FLOOR_LEFT, -half, 0.0, depth),
			make_wall(half, FLOOR_RIGHT, 0.0, depth), make_platform(-half, half, depth)]
	var stats: DemonStats = _make_stats(true)
	var dog: Demon = _spawn_demon(Vector2(0.0, depth + SPAWN_Y), stats)
	made.append(dog)
	await wait_until(dog.is_on_floor)
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(0.0, top - DROP_HEIGHT))
	made.append(man)
	var grab: GrabEscape = man.get_node(^"GrabEscape") as GrabEscape
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var held_on_its_floor: bool = await wait_until(func() -> bool:
			return (grab.is_held() and man.is_on_floor()
					and absf(man.position.y - depth) <= STACK_TOLERANCE), HOLE_WATCH_FRAMES)
	var below_the_rim: float = top - stats.back_bite_knockback_height
	await _clear(made)
	return report(below_the_rim > 0.0 and hits.size() >= 2 and held_on_its_floor,
			("Hole %.0f px deep with a dog, the man thrown at most to %.0f px below its rim: bitten "
			+ "%d times, then held on the hole's floor within %d frames %s") % [depth, below_the_rim,
			hits.size(), HOLE_WATCH_FRAMES, held_on_its_floor])


## A dog stands by a wall, the man's width and WALL_GAP_OFFSETS px from it, and the man is dropped
## onto the dog's half by the wall. With no room for him beside the dog there, its back bites him
## once and throws him to the open side, onto the floor past the dog, never against the wall and
## back onto it (ADR 0056); with room, it throws him to the wall side, between the two, as anywhere
## else. A wall lower than the dog, however near, leaves him room above it: he is thrown over it.
## The wall is on either side of the dog.
func _by_a_wall_the_bite_throws_the_man_to_the_open_side() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		for offset: float in WALL_GAP_OFFSETS:
			passed = await _drop_by_a_wall(side, offset, false) and passed
		passed = await _drop_by_a_wall(side, WALL_GAP_OFFSETS[0], true) and passed
	return passed


## One drop of the wall case, with the wall on side of the dog, offset px more than the man's width
## from it, and lower than the dog when low: whether its bite threw him the way it should.
func _drop_by_a_wall(side: float, offset: float, low: bool) -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var stats: DemonStats = _make_stats(true)
	var dog: Demon = await _spawn_dog_on_floor(0.0, stats)
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(side * DROP_OFF_CENTRE, top - DROP_HEIGHT))
	var gap: float = 2.0 * _half_width(man) + offset
	var near: float = dog.position.x + side * (_half_width(dog) + gap)
	var far: float = near + side * WALL_THICKNESS
	var wall_top: float = top + LOW_WALL_BELOW_TOP if low else WALL_TOP
	var wall: StaticBody2D = make_wall(minf(near, far), maxf(near, far), wall_top)
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var flight: Flight = await _follow_the_throw(man, top, hits)
	var thrown_to: float = signf(flight.landed_x - dog.position.x)
	var expected: float = side if offset > 0.0 or low else -side
	await _clear([ground, dog, man, wall])
	return report(hits.size() == 1 and thrown_to == expected,
			("Man dropped onto a dog's half by a %s wall %.1f px from it, on its %s: %d hits (1), "
			+ "landed at x = %.0f, thrown to %+.0f (%+.0f)") % ["low" if low else "high", gap,
			"right" if side > 0.0 else "left", hits.size(), flight.landed_x, thrown_to, expected])


## The man is dropped onto one dog and, FRAMES_BEFORE_SECOND_DOG frames after its bite, within the
## blink, put above another and dropped onto it: it bites him too and takes the SP of its bite
## again, whether the dogs' attacks pierce the blink (ADR 0055) or not, so a pack bites him on every
## back he lands on.
func _a_landing_in_the_blink_after_a_bite_is_bitten_again() -> bool:
	var passed: bool = true
	for pierces: bool in [true, false]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var first_stats: DemonStats = _make_stats(true)
		first_stats.attacks_invulnerable_man = pierces
		var second_stats: DemonStats = _make_stats(true)
		second_stats.attacks_invulnerable_man = pierces
		var first: Demon = await _spawn_dog_on_floor(0.0, first_stats)
		var second: Demon = await _spawn_dog_on_floor(SECOND_DOG_X, second_stats)
		var top: float = first.position.y - _height(first)
		var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
		var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
		var hits: Array[Hitbox] = []
		var sp_after: Array[float] = []
		_record_hits(man, hits, sp_after)
		var damage: Array[float] = _record_damage(man)
		var first_bite: bool = await wait_until(func() -> bool: return not hits.is_empty())
		await wait_frames(FRAMES_BEFORE_SECOND_DOG)
		var blinking: bool = hurtbox.is_invulnerable()
		man.position = Vector2(SECOND_DOG_X + DROP_OFF_CENTRE, top - DROP_HEIGHT)
		man.velocity = Vector2.ZERO
		var landed_on_second: bool = await wait_until(
				func() -> bool: return _is_stacked(man, second))
		await wait_frames(WATCH_FRAMES)
		await _clear([ground, first, second, man])
		passed = report(first_bite and blinking and landed_on_second and hits.size() == 2
				and damage.size() == 2 and damage[1] == BITE_DAMAGE,
				("Dogs %s Attacks Invulnerable Man, the man bitten by one %s and, still blinking %s, "
				+ "dropped onto another %s: %d hits in all (2), SP taken %s (%.0f each)") % [
				"with" if pierces else "without", first_bite, blinking, landed_on_second,
				hits.size(), damage, BITE_DAMAGE]) and passed
	return passed


## The man is dropped onto a dog while invulnerable to every hit, as for Invulnerable Time of his
## GrabEscape once he breaks free of a grab: the bite on its back lands all the same, within that,
## takes the SP of its bite and throws him off, up at least RISE_SHARE of Back Bite Knockback Height
## above its top.
func _a_landing_after_breaking_free_of_a_grab_is_bitten() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var stats: DemonStats = _make_stats(true)
	var dog: Demon = await _spawn_dog_on_floor(0.0, stats)
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	hurtbox.start_invulnerability((man.get_node(^"GrabEscape") as GrabEscape).invulnerable_time)
	var unpierceable_at_hit: Array[bool] = []
	hurtbox.hit_received.connect(func(_hitbox: Hitbox) -> void:
		unpierceable_at_hit.append(not hurtbox.can_be_pierced()))
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var damage: Array[float] = _record_damage(man)
	var flight: Flight = await _follow_the_throw(man, top, hits)
	await _clear([ground, dog, man])
	var within: bool = unpierceable_at_hit.size() == 1 and unpierceable_at_hit[0]
	return report(hits.size() == 1 and within and damage.size() == 1 and damage[0] == BITE_DAMAGE
			and flight.rose >= RISE_SHARE * stats.back_bite_knockback_height,
			("Man dropped onto a dog while invulnerable as after breaking free of a grab: %d hits "
			+ "(1), within that invulnerability %s, SP taken %s (the bite's %.0f), rose %.1f px "
			+ "above its top (at least %.0f)") % [hits.size(), within, damage, BITE_DAMAGE,
			flight.rose, RISE_SHARE * stats.back_bite_knockback_height])


## With the man's Hurtbox closed, as when held by as many demons as can hold him (ADR 0029), the
## bite on the back of a dog he lands on does not land: no hit, no SP taken and no throw, so he
## never rises above its top once on it.
func _with_his_hurtbox_closed_the_bite_does_not_land() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(true))
	var top: float = dog.position.y - _height(dog)
	var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
	(man.get_node(^"Hurtbox") as Hurtbox).set_closed(true)
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var damage: Array[float] = _record_damage(man)
	var on_it: bool = await wait_until(func() -> bool: return _is_stacked(man, dog))
	var rose: float = 0.0
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		rose = maxf(rose, top - man.position.y)
	await _clear([ground, dog, man])
	return report(on_it and hits.is_empty() and damage.is_empty() and rose <= STACK_TOLERANCE,
			("Man with his Hurtbox closed, dropped onto a dog: on it %s, %d hits (none), SP taken %s "
			+ "(none), rose %.1f px above its top once on it (at most %.0f)") % [on_it, hits.size(),
			damage, rose, STACK_TOLERANCE])


## The man stands on a demon's top, which shoves him off it (ADR 0022), and a hit knocks him back as
## he stands there, at the start of a frame, as a hit landed on the frame before does. The knockback
## throws him up, off the top, instead of the shove taking it over: he rises at least RISE_SHARE of
## its height above the top. To either side.
func _a_knockback_on_a_demon_s_top_throws_the_man_off_it() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var dog: Demon = await _spawn_dog_on_floor(0.0, _make_stats(false))
		var top: float = dog.position.y - _height(dog)
		var man: Player = spawn_player(Vector2(side * DROP_OFF_CENTRE, top - DROP_HEIGHT))
		var on_it: bool = await wait_until(func() -> bool: return _is_stacked(man, dog))
		man.knock_back(side, KNOCK_DISTANCE, KNOCK_HEIGHT)
		var rose: float = 0.0
		for _frame: int in WATCH_FRAMES:
			await physics_frame
			rose = maxf(rose, top - man.position.y)
			if _is_on_the_floor(man):
				break
		await _clear([ground, dog, man])
		passed = report(on_it and rose >= RISE_SHARE * KNOCK_HEIGHT,
				("Man on a demon's top %s, knocked back %.0f px high to the %s: rose %.1f px above "
				+ "it (at least %.0f)") % [on_it, KNOCK_HEIGHT, "right" if side > 0.0 else "left",
				rose, RISE_SHARE * KNOCK_HEIGHT]) and passed
	return passed


## A dog made without Bites Who Lands On It is given it in the scene, and the man dropped onto it is
## bitten; it is taken away again, and the man dropped onto it once more is only shoved off.
func _the_bite_turns_on_and_off_with_its_stats() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var stats: DemonStats = _make_stats(false)
	var dog: Demon = await _spawn_dog_on_floor(0.0, stats)
	var top: float = dog.position.y - _height(dog)
	stats.bites_who_lands_on_it = true
	var man: Player = spawn_player(Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT))
	var hits: Array[Hitbox] = []
	var sp_after: Array[float] = []
	_record_hits(man, hits, sp_after)
	var landed_on: bool = await _wait_to_land_on_the_floor(man)
	var bites_on: int = hits.size()
	stats.bites_who_lands_on_it = false
	man.position = Vector2(DROP_OFF_CENTRE, top - DROP_HEIGHT)
	man.velocity = Vector2.ZERO
	var landed_off: bool = await _wait_to_land_on_the_floor(man)
	var bites_off: int = hits.size() - bites_on
	await _clear([ground, dog, man])
	return report(landed_on and bites_on == 1 and landed_off and bites_off == 0,
			("A dog given the bite in the scene: %d hits (1), on the floor after %s; the bite "
			+ "taken away: %d hits (none), on the floor after %s") % [bites_on, landed_on, bites_off,
			landed_off])


## Both dogs' stats bite who lands on them, with the SP of their bite, and throw him further and
## higher than any of their attacks does. A demon's stats have it off. The bite on the back takes
## the SP of the first bite in Attacks, and none with no bite, whatever the lunges take.
func _both_dogs_bite_who_lands_on_them() -> bool:
	var passed: bool = true
	for path: String in DOG_STATS_PATHS:
		var stats: DemonStats = load(path) as DemonStats
		var bite_damage: float = 0.0
		var furthest: float = 0.0
		var highest: float = 0.0
		for attack: DemonAttack in stats.attacks:
			if attack.animation == &"bite" and bite_damage == 0.0:
				bite_damage = attack.damage
			furthest = maxf(furthest, attack.knockback_distance)
			highest = maxf(highest, attack.knockback_height)
		passed = report(stats.bites_who_lands_on_it and bite_damage > 0.0
				and stats.get_back_bite_damage() == bite_damage
				and stats.back_bite_knockback_distance > furthest
				and stats.back_bite_knockback_height > highest,
				("%s: bites who lands on it %s, with %.0f SP (its bite's %.0f), throwing him %.0f px "
				+ "away and %.0f px high (its attacks at most %.0f and %.0f)") % [path.get_file(),
				stats.bites_who_lands_on_it, stats.get_back_bite_damage(), bite_damage,
				stats.back_bite_knockback_distance, stats.back_bite_knockback_height, furthest,
				highest]) and passed
	var no_attacks: DemonStats = DemonStats.new()
	var lunge_only: DemonStats = DemonStats.new()
	lunge_only.attacks.append(_make_attack(&"lunge", LUNGE_DAMAGE))
	var two_bites: DemonStats = DemonStats.new()
	two_bites.attacks.append(_make_attack(&"lunge", LUNGE_DAMAGE))
	two_bites.attacks.append(_make_attack(&"bite", FIRST_BITE_DAMAGE))
	two_bites.attacks.append(_make_attack(&"bite", SECOND_BITE_DAMAGE))
	return report(not no_attacks.bites_who_lands_on_it
			and no_attacks.get_back_bite_damage() == 0.0
			and lunge_only.get_back_bite_damage() == 0.0
			and two_bites.get_back_bite_damage() == FIRST_BITE_DAMAGE,
			("A demon's stats bite who lands on it %s (off); the bite on the back's SP: %.0f with "
			+ "no attacks, %.0f with a lunge only, %.0f with a lunge and bites of %.0f and %.0f (the "
			+ "first bite's)") % [no_attacks.bites_who_lands_on_it,
			no_attacks.get_back_bite_damage(), lunge_only.get_back_bite_damage(),
			two_bites.get_back_bite_damage(), FIRST_BITE_DAMAGE, SECOND_BITE_DAMAGE]) and passed


## Every Hitbox that lands on the man's Hurtbox from now on, in order, into hits, and his SP right
## after each, once his HitReaction has taken what it takes, into sp_after.
func _record_hits(man: Player, hits: Array[Hitbox], sp_after: Array[float]) -> void:
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	hurtbox.hit_received.connect(func(hitbox: Hitbox) -> void:
		hits.append(hitbox)
		sp_after.append(man.soul_points.get_sp()))


## Every SP the man loses from now on, in order, one amount for each loss.
func _record_damage(man: Player) -> Array[float]:
	var amounts: Array[float] = []
	man.soul_points.damaged.connect(func(amount: float) -> void: amounts.append(amount))
	return amounts


## Waits for the man's first hit, then follows him until he lands on the floor of the cases,
## WATCH_FRAMES in all at most: how high he rose above top meanwhile, and where he landed.
func _follow_the_throw(man: Player, top: float, hits: Array[Hitbox]) -> Flight:
	var flight: Flight = Flight.new()
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		if hits.is_empty():
			continue
		flight.rose = maxf(flight.rose, top - man.position.y)
		if _is_on_the_floor(man):
			flight.landed_x = man.position.x
			break
	return flight


## The cases' dog stats: it never sees the man, so it never chases nor attacks him, its attacks
## pierce his blink, and it has a bite of BITE_DAMAGE, which gives the bite on its back its SP; with
## back_bite, it bites who lands on it.
func _make_stats(back_bite: bool) -> DemonStats:
	var stats: DemonStats = DemonStats.new()
	stats.sight_distance = SHORT_SIGHT
	stats.attacks.append(_make_attack(&"bite", BITE_DAMAGE))
	stats.attacks_invulnerable_man = true
	stats.bites_who_lands_on_it = back_bite
	return stats


func _make_attack(animation: StringName, damage: float) -> DemonAttack:
	var attack: DemonAttack = DemonAttack.new()
	attack.animation = animation
	attack.damage = damage
	return attack


## A dog from demon.tscn with stats, at x, once it stands on the floor.
func _spawn_dog_on_floor(x: float, stats: DemonStats) -> Demon:
	var dog: Demon = _spawn_demon(Vector2(x, SPAWN_Y), stats)
	await wait_until(dog.is_on_floor)
	return dog


## A demon from demon.tscn with stats, at the given spot, in the scene; it may still be in the air.
func _spawn_demon(at: Vector2, stats: DemonStats) -> Demon:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.stats = stats
	demon.position = at
	root.add_child(demon)
	return demon


## True while upper stands on lower: on a floor, overlapping it side to side, with its feet on
## lower's top.
func _is_stacked(upper: CharacterBody2D, lower: CharacterBody2D) -> bool:
	return upper.is_on_floor() and _overlap_side_to_side(upper, lower) \
			and absf(upper.position.y - (lower.position.y - _height(lower))) <= STACK_TOLERANCE


## Waits until the man stands on the floor of the cases, MAX_FRAMES at most; false if he never does.
func _wait_to_land_on_the_floor(man: Player) -> bool:
	return await wait_until(func() -> bool: return _is_on_the_floor(man))


## True while the body stands on the floor of the cases, whose top is at y = 0.
func _is_on_the_floor(body: CharacterBody2D) -> bool:
	return body.is_on_floor() and absf(body.position.y) <= STACK_TOLERANCE


## True while the two bodies' boxes overlap along x.
func _overlap_side_to_side(one: CharacterBody2D, other: CharacterBody2D) -> bool:
	return absf(one.position.x - other.position.x) < _half_width(one) + _half_width(other)


## The width of a demon's body box, read from demon.tscn.
func _body_width() -> float:
	return _demon_box().x


## A demon's body box, read from demon.tscn.
func _demon_box() -> Vector2:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	var size: Vector2 = ((demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape
			as RectangleShape2D).size
	demon.free()
	return size


func _half_width(body: CharacterBody2D) -> float:
	return _box_of(body).x / 2.0


func _height(body: CharacterBody2D) -> float:
	return _box_of(body).y


func _box_of(body: CharacterBody2D) -> Vector2:
	return ((body.get_node(^"CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size


## Takes out what a case made at the end of the frame, and waits for it.
func _clear(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame


## How the man flew once bitten: how high he rose above the top he was thrown from, in px, and his x
## when he landed on the floor, NAN if he never did.
class Flight:
	var rose: float = 0.0
	var landed_x: float = NAN
