# Checks that the biggest dog goes after the man by his trail (#271, phase C), as a dog by his scent: where he
# went up and down, in order, not straight to where he is. Built here: it jumps up onto a one-way platform
# narrower than its body where he went, and without Follows Trail the same dog stays below him; only the biggest
# dog follows the trail. With the man gone up by a platform to its left onto a shelf and along it to right above
# it, it goes left by that platform and up onto the shelf, as he did, where a dog going straight to him would
# wait below. It drops onto the floor where he stands; his footing on its back is no step of his trail; put back
# on the floor, as if thrown, it takes his trail again; at a step higher than its jump it barks, and at one up
# across a pit too wide for its jump it barks at the edge, never going into the pit; with him standing on a
# narrow platform right over it or to its side, or near the edge of a solid block on its side, it barks below
# and never jumps into him, while on a wide platform it jumps up beside him, on its own side; once he moves on
# from over it, it jumps up after him at once, without waiting its Trail Retry Time; and with him
# back beside it, in its sight and within its reach, it lets go of his trail, so once he hides on its floor it
# never goes back up the way he went. In level 1, with the man going the way back round from its hall (the
# steps, the column, gate 3, the corridor, the well and the chimney) and on past its post, it goes the same way
# after him and comes down the chimney into the hall again. The cases built here give the dog a copy of its
# attacks with Leaps To Other Floors off, so they check the trail and the refuge, which still hold where no leap
# gets to him; with its own attacks (#284, ADR 0076), the man on that narrow platform to its side is leapt at
# and killed, from several seeds.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dog_trail.gd
extends "res://tests/support/player_test.gd"

const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const STATS_PATHS: Array[String] = [
	"res://scenes/characters/demon/lust_demon_stats.tres",
	"res://scenes/characters/demon/big_demon_stats.tres",
	"res://scenes/characters/demon/jumping_demon_stats.tres",
	"res://scenes/characters/demon/tutorial_blocker_stats.tres",
]
const BIGGEST_STATS_PATH: String = "res://scenes/characters/demon/biggest_demon_stats.tres"
## How thick, in px, the one-way platforms built here are: a tile's top half, as level 1's.
const PLATFORM_DEPTH: float = 24.0
const FLOOR_HALF_LENGTH: float = 2400.0
## The dog's spot on the floor, and the man's beside it, where it notices him.
const DOG_X: float = 900.0
const MAN_NOTICED_X: float = 600.0
## A one-way platform narrower than the biggest dog's 168 px body, one jump of the man's up.
const NARROW_LEFT: float = -400.0
const NARROW_RIGHT: float = -256.0
const NARROW_TOP: float = -192.0
## A one-way platform up to the left, a one-way shelf above it reaching right over the dog, and where the man
## stands on each: the shelf's spot is right above the dog.
const LEFT_PLATFORM_LEFT: float = -500.0
const LEFT_PLATFORM_RIGHT: float = -356.0
const LEFT_PLATFORM_TOP: float = -192.0
const SHELF_LEFT: float = -450.0
const SHELF_RIGHT: float = 1400.0
const SHELF_TOP: float = -384.0
const ON_LEFT_PLATFORM: Vector2 = Vector2(-428.0, -192.0)
const ON_SHELF_LEFT: Vector2 = Vector2(-300.0, -384.0)
const ON_SHELF_ABOVE_THE_DOG: Vector2 = Vector2(900.0, -384.0)
## West of the left platform's right side: the dog got this far only by going the man's way.
const WENT_LEFT_X: float = -300.0
## How high over a spot, in px, the man is put, so he lands there.
const DROP_IN: float = 40.0
## Frames given to the dog to notice the man, to him to land, and to the dog to get where he went.
const NOTICE_FRAMES: int = 120
const LAND_FRAMES: int = 120
const FOLLOW_FRAMES: int = 900
## How near a floor's top, in px, feet are to stand on it.
const ON_TOP: float = 4.0
## Level 1, on its grid of 48 px tiles: the hall's floor; where the man stands to be noticed by the biggest
## dog at its post; then, landing by landing, the way back round: the four steps of the hall's west end, the
## column's platforms and floors, the floor of gate 3 and its corridor, the step and the well down from it, the
## hall again under the chimney, and on past the dog's post.
const HALL_FLOOR: float = 10320.0
const LEVEL_MAN_START: Vector2 = Vector2(7400.0, 10320.0)
const WAY_BACK: Array[Vector2] = [
	Vector2(4728.0, 10128.0), Vector2(4488.0, 9936.0), Vector2(4248.0, 9792.0), Vector2(3900.0, 9696.0),
	Vector2(3504.0, 9600.0), Vector2(3312.0, 9408.0), Vector2(3504.0, 9216.0), Vector2(3780.0, 9168.0),
	Vector2(4200.0, 8976.0), Vector2(4080.0, 8784.0), Vector2(3640.0, 8784.0), Vector2(3432.0, 8640.0),
	Vector2(3336.0, 8496.0), Vector2(3432.0, 8304.0), Vector2(4700.0, 8304.0), Vector2(5000.0, 8448.0),
	Vector2(5550.0, 8832.0), Vector2(7008.0, 10320.0), Vector2(8600.0, 10320.0),
]
## The corridor behind gate 3: the dog is in it with its feet on the corridor's floor between these x.
const CORRIDOR_FLOOR: float = 8304.0
const CORRIDOR_LEFT: float = 4400.0
const CORRIDOR_RIGHT: float = 4850.0
const LEVEL_SETTLE_FRAMES: int = 30
const LEVEL_NOTICE_FRAMES: int = 600
## Frames the man waits on each landing of the way back, and frames given to the dog to go round after him.
const WAYPOINT_FRAMES: int = 20
const LOOP_FRAMES: int = 6000
## The seed every case starts from, so the dogs' draws repeat.
const SEED: int = 27
## The seeds the leap at the man on the narrow platform is tried from.
const LEAP_SEEDS: Array[int] = [1, 2, 3, 5, 7]
## A block the dog stands on, LEDGE_TOP px over the floor, and where the man stands below it, west of it,
## where the dog's drop off its west end lands with nobody there (x -27, measured on 2026-11-20).
const LEDGE_LEFT: float = 300.0
const LEDGE_RIGHT: float = 1400.0
const LEDGE_TOP: float = -384.0
const MAN_ON_LEDGE_X: float = 600.0
const UNDER_THE_DROP: Vector2 = Vector2(-27.0, 0.0)
## How high over the dog's back, in px, the man is put to land on it, and the frames he stands there.
const ON_ITS_BACK_FRAMES: int = 3
## A second one-way platform, up and to the left of the narrow one, for a trail of two steps up.
const HIGHER_LEFT: float = -700.0
const HIGHER_RIGHT: float = -556.0
const HIGHER_TOP: float = -384.0
## Where the dog is put back on the floor, as if thrown, once on the first platform, and the frames it stands
## there first, so it counts the step up there as taken.
const THROWN_TO: Vector2 = Vector2(600.0, -2.0)
const ON_FIRST_FRAMES: int = 10
## A block higher than the dog's Jump Height, and where the man stands on it.
const TOO_HIGH_LEFT: float = -700.0
const TOO_HIGH_RIGHT: float = -300.0
const TOO_HIGH_TOP: float = -300.0
## Where the man comes back down to, in the dog's sight and within its reach, and frames he stands there.
const BACK_BESIDE_IT: Vector2 = Vector2(700.0, 0.0)
const BESIDE_IT_FRAMES: int = 20
## A narrow one-way platform right over the dog's spot, out of its reach, where the man stands.
const ABOVE_IT_HALF_WIDTH: float = 72.0
const ABOVE_IT_TOP: float = -144.0
## Heights of the narrow platform, to its side, the man stands on, as a refuge.
const SIDE_REFUGE_TOPS: Array[float] = [-144.0, -192.0]
## A wide one-way platform the man stands on, and where, with room beside him for the dog.
const WIDE_LEFT: float = -900.0
const WIDE_RIGHT: float = 300.0
const WIDE_TOP: float = -192.0
const ON_THE_WIDE_ONE: Vector2 = Vector2(-300.0, -192.0)
## Where on a solid block as wide as that platform the man moves on to after landing: 100 px from its edge on the
## dog's side, too near it for the dog's body beside him.
const NEAR_ITS_EDGE: Vector2 = Vector2(200.0, -192.0)
## Frames the dog has, once the man has moved on from where he stood over it, to jump: well under its Trail
## Retry Time, so it goes as soon as he lands somewhere else.
const MOVED_ON_FRAMES: int = 20
## A wall the man hides behind, on the dog's floor, where he stands, and frames the dog is watched.
const HIDING_WALL_LEFT: float = 1600.0
const HIDING_WALL_RIGHT: float = 1700.0
const HIDING_WALL_TOP: float = -1500.0
const HIDDEN: Vector2 = Vector2(2200.0, 0.0)
const HIDDEN_FRAMES: int = 600
## How near the hiding wall, in px, the dog's body gets for it to count as gone after him there.
const NEAR_THE_WALL: float = 48.0
## Frames given to the dog to bark at a step it cannot take.
const BARK_FRAMES: int = 400
## A pit between the dog's floor and a block whose top is PIT_FAR_TOP, too wide for the dog to jump up across,
## with its bottom PIT_BOTTOM px down; where the man stands on that block; and how far down, in px, the dog's
## feet go for it to count as in the pit.
const PIT_LEFT: float = -300.0
const PIT_RIGHT: float = 300.0
const PIT_BOTTOM: float = 600.0
const PIT_FAR_TOP: float = -220.0
const ACROSS_THE_PIT: Vector2 = Vector2(-500.0, -220.0)
const IN_THE_PIT: float = 100.0
## The dog's floor ending at FLOOR_END over a gap, past which a block's top is FAR_BLOCK_TOP, and where the man
## lands on it, too far along for the dog's jump to reach, though not the block's near end.
const FLOOR_END: float = 300.0
const FAR_BLOCK_RIGHT: float = 200.0
const FAR_BLOCK_TOP: float = -192.0
const FAR_ALONG: Vector2 = Vector2(-500.0, -192.0)


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _it_jumps_up_onto_a_narrow_platform_after_the_man())
	results.append(await _without_follows_trail_it_stays_below())
	results.append(_only_the_biggest_dog_follows_trail())
	results.append(await _it_goes_his_way_not_straight_to_him())
	results.append(await _it_drops_onto_the_floor_where_the_man_stands())
	results.append(await _the_man_on_its_back_is_no_step_of_his_trail())
	results.append(await _thrown_back_it_takes_the_trail_again())
	results.append(await _at_a_step_too_high_it_barks())
	results.append(await _at_a_pit_too_wide_to_jump_up_across_it_stops_and_barks())
	results.append(await _it_jumps_up_onto_the_near_end_of_a_floor_he_landed_far_along())
	results.append(await _with_the_man_standing_right_above_it_it_barks_below())
	for top: float in SIDE_REFUGE_TOPS:
		results.append(await _with_the_man_on_a_narrow_platform_to_its_side_it_barks_below(top))
	results.append(await _with_its_leap_the_man_on_a_narrow_platform_to_its_side_dies())
	results.append(await _with_the_man_on_a_wide_platform_it_jumps_up_beside_him())
	results.append(await _with_the_man_near_the_edge_on_its_side_it_barks_below())
	results.append(await _once_he_moves_on_from_over_it_it_jumps_at_once())
	results.append(await _with_the_man_back_beside_it_it_lets_go_of_the_trail())
	results.append(await _in_level_1_it_goes_the_way_back_round_after_him())
	finish(results)


## The dog stands on a block after the man; he goes down off its west end and stands right where the dog's
## drop lands. It gets down onto the floor all the same (#271): his body is no floor to aim for, and a drop
## that met him on the way would land nowhere.
func _it_drops_onto_the_floor_where_the_man_stands() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var ledge: StaticBody2D = make_wall(LEDGE_LEFT, LEDGE_RIGHT, LEDGE_TOP)
	seed(SEED)
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	big.stats = big.stats.duplicate() as DemonStats
	big.stats.pack_variation = 0.0
	big.stats.attacks = _copy_of_attacks(big.stats, false)
	big.position = Vector2(DOG_X, LEDGE_TOP - 2.0)
	big.faces_left = true
	root.add_child(big)
	await wait_until(big.is_on_floor)
	var player: Player = await spawn_on_floor(Vector2(MAN_ON_LEDGE_X, LEDGE_TOP - 2.0))
	player.god_mode = true
	await wait_until(big.has_target, NOTICE_FRAMES)
	await _land(player, UNDER_THE_DROP)
	var apart: float = big.get_half_size().x + KnockOff.box_of(player).size.x / 2.0
	var over_him: Array[bool] = [false]
	var down: bool = await wait_until(func() -> bool:
			if not big.is_on_floor() and big.global_position.y > LEDGE_TOP \
					and absf(big.global_position.x - player.global_position.x) < apart:
				over_him[0] = true
			return _stands_at(big, 0.0), FOLLOW_FRAMES)
	big.queue_free()
	ground.queue_free()
	ledge.queue_free()
	await remove_player(player)
	return report(down and over_him[0], ("Biggest dog: down off a block %.0f px high onto the floor where the man "
			+ "stands %s, coming down over him %s") % [-LEDGE_TOP, down, over_him[0]])


## The man lands on the dog's back, then goes up from there onto the narrow platform, and on out of its sight:
## his trail starts with one step, from the floor he stood on before to the platform, and the dog jumps up onto
## it. A step onto its own back would hold it there for ever.
func _the_man_on_its_back_is_no_step_of_his_trail() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var narrow: StaticBody2D = _make_one_way(NARROW_LEFT, NARROW_RIGHT, NARROW_TOP)
	var wall: StaticBody2D = make_wall(HIDING_WALL_LEFT, HIDING_WALL_RIGHT, HIDING_WALL_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var back: float = big.global_position.y - big.get_half_size().y * 2.0
	await _land(player, Vector2(big.global_position.x, back))
	await wait_frames(ON_ITS_BACK_FRAMES)
	await _land(player, Vector2((NARROW_LEFT + NARROW_RIGHT) / 2.0, NARROW_TOP))
	await _land(player, HIDDEN)
	var up: bool = await wait_until(func() -> bool: return _stands_at(big, NARROW_TOP), FOLLOW_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [ground, narrow, wall]:
		body.queue_free()
	await remove_player(player)
	return report(up, "Biggest dog: the man went up by its back onto a platform, and it jumped up onto it %s" % up)


## The man goes up two platforms, and on out of the dog's sight; once the dog is on the first, it is put back
## on the floor, as if thrown off. It takes his trail again from there and gets up onto the second.
func _thrown_back_it_takes_the_trail_again() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var narrow: StaticBody2D = _make_one_way(NARROW_LEFT, NARROW_RIGHT, NARROW_TOP)
	var higher: StaticBody2D = _make_one_way(HIGHER_LEFT, HIGHER_RIGHT, HIGHER_TOP)
	var wall: StaticBody2D = make_wall(HIDING_WALL_LEFT, HIDING_WALL_RIGHT, HIDING_WALL_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	await _land(player, Vector2((NARROW_LEFT + NARROW_RIGHT) / 2.0, NARROW_TOP))
	await _land(player, Vector2((HIGHER_LEFT + HIGHER_RIGHT) / 2.0, HIGHER_TOP))
	await _land(player, HIDDEN)
	var on_first: bool = await wait_until(func() -> bool: return _stands_at(big, NARROW_TOP), FOLLOW_FRAMES)
	await wait_frames(ON_FIRST_FRAMES)
	big.global_position = THROWN_TO
	big.velocity = Vector2.ZERO
	var up: bool = await wait_until(func() -> bool: return _stands_at(big, HIGHER_TOP), FOLLOW_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [ground, narrow, higher, wall]:
		body.queue_free()
	await remove_player(player)
	return report(on_first and up, ("Biggest dog: up on the first platform %s; put back on the floor, it took the "
			+ "trail again up onto the second %s") % [on_first, up])


## The man goes up onto a block higher than the dog's Jump Height. The dog cannot take that step, and barks
## at it, out of his reach, as any dog does, instead of standing still and silent.
func _at_a_step_too_high_it_barks() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var block: StaticBody2D = make_wall(TOO_HIGH_LEFT, TOO_HIGH_RIGHT, TOO_HIGH_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var barks: Array[int] = [0]
	big.barked.connect(func(_hops: bool) -> void: barks[0] += 1)
	await _land(player, Vector2((TOO_HIGH_LEFT + TOO_HIGH_RIGHT) / 2.0, TOO_HIGH_TOP))
	var barked: bool = await wait_until(func() -> bool: return barks[0] > 0, BARK_FRAMES)
	big.queue_free()
	ground.queue_free()
	block.queue_free()
	await remove_player(player)
	return report(barked, "Biggest dog: the man on a block %.0f px high, over its Jump Height; it barked %s"
			% [-TOO_HIGH_TOP, barked])


## The man goes up across a pit onto a block on its far side, too far for the dog's jump. It stops at the pit's
## edge and barks at him, never walking on into the pit, where it would lose his trail.
func _at_a_pit_too_wide_to_jump_up_across_it_stops_and_barks() -> bool:
	var near_side: StaticBody2D = make_wall(PIT_RIGHT, FLOOR_HALF_LENGTH, 0.0, PIT_BOTTOM)
	var far_side: StaticBody2D = make_wall(-FLOOR_HALF_LENGTH, PIT_LEFT, PIT_FAR_TOP, PIT_BOTTOM)
	var bottom: StaticBody2D = make_platform(PIT_LEFT, PIT_RIGHT, PIT_BOTTOM)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var barks: Array[int] = [0]
	big.barked.connect(func(_hops: bool) -> void: barks[0] += 1)
	await _land(player, ACROSS_THE_PIT)
	var fell_in: Array[bool] = [false]
	await wait_until(func() -> bool:
			fell_in[0] = fell_in[0] or big.global_position.y > IN_THE_PIT
			return fell_in[0], BARK_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [near_side, far_side, bottom]:
		body.queue_free()
	await remove_player(player)
	return report(not fell_in[0] and barks[0] > 0, ("Biggest dog: the man across a pit %.0f px wide, %.0f px up; it "
			+ "fell into the pit %s (false), barked %s") % [PIT_RIGHT - PIT_LEFT, -PIT_FAR_TOP, fell_in[0], barks[0] > 0])


## The man goes up across a gap at the end of the dog's floor onto a higher block, and lands far along it, too
## far for the dog to jump to his spot. From the end of its floor, it jumps up at its Chase Speed onto the
## block's near end, the floor he landed on, as at the top of level 1's column.
func _it_jumps_up_onto_the_near_end_of_a_floor_he_landed_far_along() -> bool:
	var near_side: StaticBody2D = make_wall(FLOOR_END, FLOOR_HALF_LENGTH, 0.0, PIT_BOTTOM)
	var far_side: StaticBody2D = make_wall(-FLOOR_HALF_LENGTH, FAR_BLOCK_RIGHT, FAR_BLOCK_TOP, PIT_BOTTOM)
	var bottom: StaticBody2D = make_platform(FAR_BLOCK_RIGHT, FLOOR_END, PIT_BOTTOM)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	await _land(player, FAR_ALONG)
	var up: bool = await wait_until(func() -> bool: return _stands_at(big, FAR_BLOCK_TOP), FOLLOW_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [near_side, far_side, bottom]:
		body.queue_free()
	await remove_player(player)
	return report(up, ("Biggest dog: the man %.0f px up across a gap of %.0f px, landed %.0f px past its near end; "
			+ "it jumped up onto that floor %s") % [-FAR_BLOCK_TOP, FLOOR_END - FAR_BLOCK_RIGHT,
			FAR_BLOCK_RIGHT - FAR_ALONG.x, up])


## The man goes up onto a narrow platform to the dog's side, top px over the floor, and stands there. The dog
## comes to it from the side: there is no room beside him up there, so it barks below, as at a refuge, and
## never jumps, neither sliding up his side nor pushing him off.
func _with_the_man_on_a_narrow_platform_to_its_side_it_barks_below(top: float) -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var narrow: StaticBody2D = _make_one_way(NARROW_LEFT, NARROW_RIGHT, top)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var jumps: Array[int] = [0]
	var barks: Array[int] = [0]
	big.took_off.connect(func() -> void: jumps[0] += 1)
	big.barked.connect(func(_hops: bool) -> void: barks[0] += 1)
	var there: bool = await _land(player, Vector2((NARROW_LEFT + NARROW_RIGHT) / 2.0, top))
	await wait_frames(BARK_FRAMES)
	var still_there: bool = player.is_on_floor() and absf(player.global_position.y - top) <= ON_TOP
	big.queue_free()
	ground.queue_free()
	narrow.queue_free()
	await remove_player(player)
	return report(there and still_there and jumps[0] == 0 and barks[0] > 0, ("Biggest dog: the man on a platform "
			+ "%.0f px wide, %.0f px up, to its side %s, still there %s; it jumped %d time(s) (0) and barked %s")
			% [NARROW_RIGHT - NARROW_LEFT, -top, there, still_there, jumps[0], barks[0] > 0])


## With its own attacks, which Leap To Other Floors, the dog leaps at the man on the narrow platform to its side,
## NARROW_TOP px up, and kills him: no refuge for him there (#284). From each of LEAP_SEEDS, with god mode only
## until he stands there.
func _with_its_leap_the_man_on_a_narrow_platform_to_its_side_dies() -> bool:
	var outcomes: Array[String] = []
	var passed: bool = true
	for leap_seed: int in LEAP_SEEDS:
		var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
		var narrow: StaticBody2D = _make_one_way(NARROW_LEFT, NARROW_RIGHT, NARROW_TOP)
		var big: Demon = await _spawn_biggest(true, true, leap_seed)
		var player: Player = await _noticed_man(big)
		var there: bool = await _land(player, Vector2((NARROW_LEFT + NARROW_RIGHT) / 2.0, NARROW_TOP))
		player.god_mode = false
		var died: bool = await wait_until(player.is_dead, FOLLOW_FRAMES)
		var cause: StringName = player.get_death_cause()
		passed = passed and there and died and cause == &"biggest_demon"
		outcomes.append("seed %d: there %s, died %s (%s)" % [leap_seed, there, died, cause])
		big.queue_free()
		ground.queue_free()
		narrow.queue_free()
		await remove_player(player)
	return report(passed, "Biggest dog with its leap, the man on a platform %.0f px wide, %.0f px up, to its side: %s"
			% [NARROW_RIGHT - NARROW_LEFT, -NARROW_TOP, "; ".join(outcomes)])


## The man stands on a wide platform where he landed. The dog jumps up beside him, on its own side of him:
## where he stands is no refuge when there is room for it next to him.
func _with_the_man_on_a_wide_platform_it_jumps_up_beside_him() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var wide: StaticBody2D = _make_one_way(WIDE_LEFT, WIDE_RIGHT, WIDE_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	await _land(player, ON_THE_WIDE_ONE)
	var up: bool = await wait_until(func() -> bool: return _stands_at(big, WIDE_TOP), FOLLOW_FRAMES)
	var his_side: bool = signf(big.global_position.x - player.global_position.x) == signf(DOG_X - ON_THE_WIDE_ONE.x)
	var still_there: bool = player.is_on_floor() and absf(player.global_position.y - WIDE_TOP) <= ON_TOP
	big.queue_free()
	ground.queue_free()
	wide.queue_free()
	await remove_player(player)
	return report(up and his_side and still_there, ("Biggest dog: the man standing on a platform %.0f px wide, %.0f px "
			+ "up; it jumped up beside him %s, on its own side of him %s, with him still there %s")
			% [WIDE_RIGHT - WIDE_LEFT, -WIDE_TOP, up, his_side, still_there])


## The man lands on a solid block as wide as that platform, then moves on to stand near its edge on the dog's
## side: in its way up, and with no room for its body beside him there. It never jumps, neither up his side nor
## past him, and barks below, as at a refuge.
func _with_the_man_near_the_edge_on_its_side_it_barks_below() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var block: StaticBody2D = make_wall(WIDE_LEFT, WIDE_RIGHT, WIDE_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var jumps: Array[int] = [0]
	var barks: Array[int] = [0]
	big.took_off.connect(func() -> void: jumps[0] += 1)
	big.barked.connect(func(_hops: bool) -> void: barks[0] += 1)
	var landed: bool = await _land(player, ON_THE_WIDE_ONE)
	var moved_on: bool = await _land(player, NEAR_ITS_EDGE)
	await wait_frames(BARK_FRAMES)
	var still_there: bool = player.is_on_floor() and absf(player.global_position.y - WIDE_TOP) <= ON_TOP
	big.queue_free()
	ground.queue_free()
	block.queue_free()
	await remove_player(player)
	return report(landed and moved_on and still_there and jumps[0] == 0 and barks[0] > 0, ("Biggest dog: the man "
			+ "landed on a block %.0f px up %s, then stood %.0f px from its edge on its side %s, still there %s; it "
			+ "jumped %d time(s) (0) and barked %s") % [-WIDE_TOP, landed, WIDE_RIGHT - NEAR_ITS_EDGE.x, moved_on,
			still_there, jumps[0], barks[0] > 0])


## The man stands on the narrow platform right over the dog until it barks at him, then moves on out of its
## sight. That landing elsewhere is a new step of his trail, so the dog jumps up after him within MOVED_ON_FRAMES,
## not once its Trail Retry Time is up.
func _once_he_moves_on_from_over_it_it_jumps_at_once() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var above: StaticBody2D = _make_one_way(DOG_X - ABOVE_IT_HALF_WIDTH, DOG_X + ABOVE_IT_HALF_WIDTH, ABOVE_IT_TOP)
	var wall: StaticBody2D = make_wall(HIDING_WALL_LEFT, HIDING_WALL_RIGHT, HIDING_WALL_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var barks: Array[int] = [0]
	var jumps: Array[int] = [0]
	big.barked.connect(func(_hops: bool) -> void: barks[0] += 1)
	big.took_off.connect(func() -> void: jumps[0] += 1)
	await _land(player, Vector2(DOG_X, ABOVE_IT_TOP))
	var barked: bool = await wait_until(func() -> bool: return barks[0] > 0, BARK_FRAMES)
	var gone: bool = await _land(player, HIDDEN)
	var jumped: bool = await wait_until(func() -> bool: return jumps[0] > 0, MOVED_ON_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [ground, above, wall]:
		body.queue_free()
	await remove_player(player)
	return report(barked and gone and jumped, ("Biggest dog: barked at the man over it %s; he moved on out of its "
			+ "sight %s; it jumped up after him within %d frames %s") % [barked, gone, MOVED_ON_FRAMES, jumped])


## The man goes up onto the narrow platform and at once comes back down beside the dog, in its sight and
## within its reach: it lets go of his trail. He then hides behind a wall on its floor, and it goes after him
## there, never up onto the platform, as a trail kept from before would take it.
func _with_the_man_back_beside_it_it_lets_go_of_the_trail() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var narrow: StaticBody2D = _make_one_way(NARROW_LEFT, NARROW_RIGHT, NARROW_TOP)
	var wall: StaticBody2D = make_wall(HIDING_WALL_LEFT, HIDING_WALL_RIGHT, HIDING_WALL_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	await _land(player, Vector2((NARROW_LEFT + NARROW_RIGHT) / 2.0, NARROW_TOP))
	await _land(player, BACK_BESIDE_IT)
	await wait_frames(BESIDE_IT_FRAMES)
	var hidden: bool = await _land(player, HIDDEN)
	var eastmost: Array[float] = [big.global_position.x]
	var went_up: bool = await wait_until(func() -> bool:
			eastmost[0] = maxf(eastmost[0], big.global_position.x)
			return _stands_at(big, NARROW_TOP), HIDDEN_FRAMES)
	var to_the_wall: bool = eastmost[0] >= HIDING_WALL_LEFT - big.get_half_size().x - NEAR_THE_WALL
	big.queue_free()
	for body: StaticBody2D in [ground, narrow, wall]:
		body.queue_free()
	await remove_player(player)
	return report(hidden and not went_up and to_the_wall, ("Biggest dog: the man back beside it from the platform, "
			+ "then hidden behind a wall on its floor %s; it went up onto the platform %s (false), and went after him "
			+ "to the wall %s (x %.0f)") % [hidden, went_up, to_the_wall, eastmost[0]])


func _it_jumps_up_onto_a_narrow_platform_after_the_man() -> bool:
	var up: bool = await _up_onto_the_narrow_platform(true)
	return report(up, "Biggest dog: up onto a one-way platform %.0f px wide, %.0f px up, after the man %s"
			% [NARROW_RIGHT - NARROW_LEFT, -NARROW_TOP, up])


func _without_follows_trail_it_stays_below() -> bool:
	var up: bool = await _up_onto_the_narrow_platform(false)
	return report(not up, "Biggest dog without Follows Trail: up onto the same platform %s (false)" % up)


func _only_the_biggest_dog_follows_trail() -> bool:
	var others: Array[String] = []
	if DemonStats.new().follows_trail:
		others.append("DemonStats.new()")
	for path: String in STATS_PATHS:
		if (load(path) as DemonStats).follows_trail:
			others.append(path.get_file())
	var biggest: bool = (load(BIGGEST_STATS_PATH) as DemonStats).follows_trail
	return report(biggest and others.is_empty(), "Follows Trail: biggest dog %s (true), others with it: %s"
			% [biggest, others if not others.is_empty() else "none"])


## The biggest dog, with Follows Trail as given, notices the man on the floor; he goes up onto the narrow
## platform, and on out of its sight, so he is not in its way there. True when it stands on that platform
## within FOLLOW_FRAMES.
func _up_onto_the_narrow_platform(follows_trail: bool) -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var narrow: StaticBody2D = _make_one_way(NARROW_LEFT, NARROW_RIGHT, NARROW_TOP)
	var wall: StaticBody2D = make_wall(HIDING_WALL_LEFT, HIDING_WALL_RIGHT, HIDING_WALL_TOP)
	var big: Demon = await _spawn_biggest(follows_trail)
	var player: Player = await _noticed_man(big)
	await _land(player, Vector2((NARROW_LEFT + NARROW_RIGHT) / 2.0, NARROW_TOP))
	await _land(player, HIDDEN)
	var up: bool = await wait_until(func() -> bool: return _stands_at(big, NARROW_TOP), FOLLOW_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [ground, narrow, wall]:
		body.queue_free()
	await remove_player(player)
	return up


## The man goes up onto a narrow platform right over the dog, out of its reach, and stands there. A jump up
## would bump into him or land on him, so the dog stays below and barks at him, as at a refuge, until he moves
## on, and never jumps: bumping into his feet over and over was what it did before (#271).
func _with_the_man_standing_right_above_it_it_barks_below() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var above: StaticBody2D = _make_one_way(DOG_X - ABOVE_IT_HALF_WIDTH, DOG_X + ABOVE_IT_HALF_WIDTH, ABOVE_IT_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	var jumps: Array[int] = [0]
	var barks: Array[int] = [0]
	big.took_off.connect(func() -> void: jumps[0] += 1)
	big.barked.connect(func(_hops: bool) -> void: barks[0] += 1)
	var there: bool = await _land(player, Vector2(DOG_X, ABOVE_IT_TOP))
	await wait_frames(BARK_FRAMES)
	big.queue_free()
	ground.queue_free()
	above.queue_free()
	await remove_player(player)
	return report(there and jumps[0] == 0 and barks[0] > 0, ("Biggest dog: the man standing on a platform %.0f px "
			+ "over it %s; it jumped %d time(s) (0) and barked %s") % [-ABOVE_IT_TOP, there, jumps[0], barks[0] > 0])


func _it_goes_his_way_not_straight_to_him() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH)
	var left: StaticBody2D = _make_one_way(LEFT_PLATFORM_LEFT, LEFT_PLATFORM_RIGHT, LEFT_PLATFORM_TOP)
	var shelf: StaticBody2D = _make_one_way(SHELF_LEFT, SHELF_RIGHT, SHELF_TOP)
	var big: Demon = await _spawn_biggest(true)
	var player: Player = await _noticed_man(big)
	for spot: Vector2 in [ON_LEFT_PLATFORM, ON_SHELF_LEFT, ON_SHELF_ABOVE_THE_DOG]:
		await _land(player, spot)
	var westmost: Array[float] = [big.global_position.x]
	var up: bool = await wait_until(func() -> bool:
			westmost[0] = minf(westmost[0], big.global_position.x)
			return _stands_at(big, SHELF_TOP), FOLLOW_FRAMES)
	big.queue_free()
	for body: StaticBody2D in [ground, left, shelf]:
		body.queue_free()
	await remove_player(player)
	return report(up and westmost[0] <= WENT_LEFT_X,
			("Biggest dog: the man went up by a platform to its left and along a shelf to right above it; it "
			+ "went as far west as x %.0f (%.0f or less) and up onto the shelf %s") % [westmost[0], WENT_LEFT_X, up])


## Level 1: the man, out of harm's way with god mode, is noticed by the biggest dog at its post, and goes the
## way back round, landing by landing, gate 3 open. The dog gets into the corridor behind gate 3 and then
## back onto the hall's floor within LOOP_FRAMES.
func _in_level_1_it_goes_the_way_back_round_after_him() -> bool:
	seed(SEED)
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await wait_frames(LEVEL_SETTLE_FRAMES)
	var big: Demon = level.get_node(^"Dogs/P3BiggestDog") as Demon
	var man: Player = level.get_node(^"Player") as Player
	man.god_mode = true
	(level.get_node(^"Gates/P3Gate3") as Gate).open_now()
	man.global_position = LEVEL_MAN_START + Vector2(0.0, -DROP_IN)
	man.velocity = Vector2.ZERO
	var noticed: bool = await wait_until(big.has_target, LEVEL_NOTICE_FRAMES)
	var landed_all: bool = true
	for spot: Vector2 in WAY_BACK:
		landed_all = await _land(man, spot) and landed_all
		await wait_frames(WAYPOINT_FRAMES)
	var in_corridor: Array[bool] = [false]
	var back: bool = await wait_until(func() -> bool:
			var at: Vector2 = big.global_position
			if big.is_on_floor() and absf(at.y - CORRIDOR_FLOOR) <= ON_TOP \
					and at.x >= CORRIDOR_LEFT and at.x <= CORRIDOR_RIGHT:
				in_corridor[0] = true
			return in_corridor[0] and _stands_at(big, HALL_FLOOR), LOOP_FRAMES)
	var dog_at: Vector2 = big.global_position
	level.queue_free()
	await wait_frames(2)
	return report(noticed and landed_all and back,
			("Level 1: noticed %s; the man landed on every spot of the way back %s; the dog went through the "
			+ "corridor behind gate 3 %s and back down into the hall %s within %d frames (at %.0f, %.0f)")
			% [noticed, landed_all, in_corridor[0], back, LOOP_FRAMES, dog_at.x, dog_at.y])


## The biggest dog at DOG_X on the floor, facing left, with its own copy of Stats, Follows Trail as given, no
## Pack Variation and its own copy of its attacks, which Leap To Other Floors only with leaps, from a_seed, so a
## case repeats.
func _spawn_biggest(follows_trail: bool, leaps: bool = false, a_seed: int = SEED) -> Demon:
	seed(a_seed)
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	big.stats = big.stats.duplicate() as DemonStats
	big.stats.follows_trail = follows_trail
	big.stats.pack_variation = 0.0
	big.stats.attacks = _copy_of_attacks(big.stats, leaps)
	big.position = Vector2(DOG_X, -2.0)
	big.faces_left = true
	root.add_child(big)
	await wait_until(big.is_on_floor)
	return big


## A copy of each of the attacks in stats, those that Leap To Other Floors keeping it only with leaps.
func _copy_of_attacks(stats: DemonStats, leaps: bool) -> Array[DemonAttack]:
	var attacks: Array[DemonAttack] = []
	for attack: DemonAttack in stats.attacks:
		var copy: DemonAttack = attack.duplicate() as DemonAttack
		copy.leaps_to_other_floors = leaps and attack.leaps_to_other_floors
		attacks.append(copy)
	return attacks


## The man on the floor at MAN_NOTICED_X, once the dog has noticed him, out of harm's way with god mode.
func _noticed_man(big: Demon) -> Player:
	var player: Player = await spawn_on_floor(Vector2(MAN_NOTICED_X, -2.0))
	player.god_mode = true
	await wait_until(big.has_target, NOTICE_FRAMES)
	return player


## Puts the man DROP_IN px over spot, and waits for him to land there. True when he does within LAND_FRAMES.
func _land(man: Player, spot: Vector2) -> bool:
	man.global_position = spot + Vector2(0.0, -DROP_IN)
	man.velocity = Vector2.ZERO
	return await wait_until(func() -> bool:
			return man.is_on_floor() and absf(man.global_position.y - spot.y) <= ON_TOP, LAND_FRAMES)


## True when the dog stands on a floor whose top is at y.
func _stands_at(dog: Demon, y: float) -> bool:
	return dog.is_on_floor() and absf(dog.global_position.y - y) <= ON_TOP


## A one-way platform from x = left to x = right, with its top edge at y = top, already in the scene.
func _make_one_way(left: float, right: float, top: float) -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(right - left, PLATFORM_DEPTH)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = true
	var platform: StaticBody2D = StaticBody2D.new()
	platform.position = Vector2((left + right) / 2.0, top + PLATFORM_DEPTH / 2.0)
	platform.add_child(collision)
	root.add_child(platform)
	return platform
