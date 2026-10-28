# Checks the demon's jump up a step (ADR 0042). With Jump Height, a demon chasing a man out of its
# reach above it jumps up a step of one tile and of Jump Height as it lunges, on the run: it takes
# off short of the step, peaks just over its top, and lands on it; it never jumps up a step higher
# than that, nor where a ceiling over the step leaves no room for its body, nor with no lunge to
# jump as, and stands out of his reach instead. With him on a platform right over it, and no
# step in between, it stands out of his reach below him, with no jump. The crucifix throws it off
# in the middle of a jump, and a man freed in the middle of one leaves it standing once it lands.
# With Max Drop, after a man out of its reach below it, it leaps down off the end of its floor as
# it lunges, peaking just over its floor, and lands on the floor below past the corner, never
# touching it, for a drop of two tiles and of Max Drop, and as soon as it finds the end of its
# floor when it chases fast; it never leaps down a drop deeper than that, nor with no lunge to leap
# as, nor where a ceiling over the end of its floor is in the way of its leap, and stopped on its
# way to take off it stands out of his reach. The crucifix throws it off in the middle of a drop,
# and a man freed in the middle of one leaves it standing once it lands. Its leap down is one step
# of its way back (DemonPath), which its way back undoes, last step first: kept off its post on a
# higher floor, it leaps back down and walks home to its post, which never moved (ADR 0043); thrown
# down a step of Jump Height, or two, it jumps back up each; after jumping up after the man, it
# leaps back down; thrown down a step higher than Jump Height, it walks to the step's wall and
# stands there. With the man seen up a step or down a drop and then hidden, it jumps up or leaps down
# in its search, and sniffs where it last saw him. Up a step and down a drop, walking to take off
# or taking off at once, it tells one take-off and one landing, and its drawing stretches, squashes
# and settles back; thrown off in a jump it tells no landing, and stopped before it takes off it
# tells neither. With no Jump Height nor Max Drop, the step and
# edge cases of test_demon.gd hold.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_jump.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")

## The cases' demon: the test_demon.gd values it chases with, one attack that never lunges, with
## the level's Max Height Difference as its reach, and Jump Height of two tiles.
const SIGHT_DISTANCE: float = 480.0
const LOSE_DISTANCE: float = 720.0
const GIVE_UP_TIME: float = 0.5
const CHASE_SPEED: float = 300.0
const MAX_HEIGHT_DIFFERENCE: float = 24.0
const OUT_OF_REACH_WAIT: float = 3.0
const TILE: float = 48.0
const JUMP_HEIGHT: float = 2.0 * TILE
## In the case of the platform over it, a Jump Height above the platform's top, so only the lack of
## a step keeps it from jumping.
const HIGH_JUMP_HEIGHT: float = 200.0
## The floor's top is at y = 0, from x = FLOOR_LEFT to x = FLOOR_RIGHT; the demon starts at x = 0
## and the step rises at x = STEP_X, with the man MAN_INSET px on from its corner, where the corner
## never hides his head from the demon, up to the highest step.
const FLOOR_LEFT: float = -1000.0
const FLOOR_RIGHT: float = 2000.0
const SPAWN_Y: float = -2.0
const STEP_X: float = 150.0
const MAN_INSET: float = TILE
## In the case of the ceiling: its bottom CEILING_ROOM px over the step, less than the demon's
## body, CEILING_THICKNESS thick, from the step's corner CEILING_WIDTH px on; the man stands
## MAN_PAST_CEILING px on from the corner, past it, where the demon sees his middle under it.
const CEILING_ROOM: float = 60.0
const CEILING_THICKNESS: float = 20.0
const CEILING_WIDTH: float = 2.0 * TILE
const MAN_PAST_CEILING: float = CEILING_WIDTH + 2.0 * TILE
## In the case of the platform over it: its top PLATFORM_HEIGHT above the floor, SHELF_THICKNESS
## thick, from x = PLATFORM_LEFT to PLATFORM_RIGHT, with room for the demon's body below it.
const PLATFORM_HEIGHT: float = 140.0
const SHELF_THICKNESS: float = 20.0
const PLATFORM_LEFT: float = 200.0
const PLATFORM_RIGHT: float = 400.0
## In the drop cases: Max Drop of five tiles; the demon's floor ends at x = EDGE_X, with the demon
## put DROP_DEMON_AWAY px short of it and the man DROP_MAN_INSET px on from it, on the floor below,
## where the corner never hides his head from the demon, down to the deepest drop.
const MAX_DROP: float = 5.0 * TILE
const EDGE_X: float = 150.0
const DROP_DEMON_AWAY: float = 60.0
const DROP_MAN_INSET: float = 6.0 * TILE
## In the case of the ceiling over the end of its floor: its bottom LOW_CEILING_ROOM px over the
## demon's head, less than its leap's Jump Clearance, from LOW_CEILING_REACH px short of the corner
## to as far past it.
const LOW_CEILING_ROOM: float = 6.0
const LOW_CEILING_REACH: float = 2.0 * TILE
## Chase Speeds of the drop cases: fast enough that the demon's leap is longer than the way from its
## back to the corner as it finds the end of its floor, so it takes off there, with no walk; and slow
## enough that it walks on for some frames before it takes off.
const FAST_CHASE_SPEED: float = 600.0
const SLOW_CHASE_SPEED: float = 100.0
## In the case of the walk stopped: how far ahead of the demon's front, in px, a block goes up on
## its floor, and how high.
const BLOCK_AHEAD: float = 2.0
const BLOCK_HEIGHT: float = TILE
## In the case of the way home: the demon's post POST_PAST_EDGE px past the end of the high floor,
## on the low floor; the demon is put KEPT_OFF_AWAY px short of that end, on the high floor, and the
## first man FIRST_MAN_AWAY px short of it, where it chases him along that floor; it walks back at
## RETURN_SPEED.
const POST_PAST_EDGE: float = 400.0
const KEPT_OFF_AWAY: float = 300.0
const FIRST_MAN_AWAY: float = 100.0
const RETURN_SPEED: float = 150.0
# The search cases: a pillar PILLAR_PAST_MAN past where the man is seen, as high as he can never be
# seen over, and how far past there he goes to hide behind it. The search starts a few frames after
# he hides, before the chase gets the demon to the step or the end of its floor.
const PILLAR_PAST_MAN: float = 2.0 * TILE
const PILLAR_HEIGHT: float = 400.0
const HIDE_PAST_PILLAR: float = 6.0 * TILE
const SEARCH_GIVE_UP_TIME: float = 0.05
const SEARCH_TIME: float = 1.0
## Frames for a demon put somewhere new to settle on the floor there.
const SETTLE_FRAMES: int = 3
## How far, in px, a demon may be from where it must be.
const TOLERANCE: float = 6.0
## How far over the step's top and the demon's Jump Clearance its peak may go, in px: the frames
## step the arc, which a frame's fall at the top can push a few px past it.
const PEAK_TOLERANCE: float = 6.0
## Frames to watch a chase up a step or a stop below one: two seconds.
const FRAMES_TO_WATCH: int = 120
const PHYSICS_LAYERS: int = 32
const PLAYER_LAYER_NAME: String = "player"


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _jumps_up_a_step_and_lands_on_it(TILE))
	results.append(await _jumps_up_a_step_and_lands_on_it(JUMP_HEIGHT))
	results.append(await _never_jumps_up_a_step_higher_than_jump_height())
	results.append(await _with_no_lunge_it_never_jumps())
	results.append(await _never_jumps_where_a_ceiling_leaves_no_room())
	results.append(await _below_a_platform_with_no_step_it_stands_out_of_reach())
	results.append(await _the_crucifix_throws_it_off_in_the_middle_of_a_jump())
	results.append(await _a_man_freed_in_the_middle_of_a_jump_leaves_it_standing())
	results.append(await _drops_off_the_end_of_its_floor_and_lands_below(2.0 * TILE))
	results.append(await _drops_off_the_end_of_its_floor_and_lands_below(MAX_DROP))
	results.append(await _never_drops_deeper_than_max_drop())
	results.append(await _drops_off_the_end_of_its_floor_and_lands_below(2.0 * TILE,
			FAST_CHASE_SPEED))
	results.append(await _with_no_lunge_it_never_drops())
	results.append(await _never_drops_where_a_ceiling_is_in_the_way_of_its_leap())
	results.append(await _stopped_on_its_way_to_take_off_it_stands_out_of_reach())
	results.append(await _the_crucifix_throws_it_off_in_the_middle_of_a_drop())
	results.append(await _a_man_freed_in_the_middle_of_a_drop_leaves_it_standing())
	results.append(await _kept_off_its_post_on_a_higher_floor_it_leaps_back_down_and_walks_home())
	results.append(await _its_leap_down_is_a_step_of_its_way())
	results.append(await _thrown_down_a_step_it_jumps_back_up_and_walks_home())
	results.append(await _after_jumping_up_after_the_man_it_leaps_back_down_and_walks_home())
	results.append(await _two_steps_down_it_jumps_back_up_both_last_first())
	results.append(await _thrown_down_higher_than_jump_height_it_stands_below())
	results.append(await _hidden_up_a_step_it_jumps_up_to_search_there())
	results.append(await _hidden_down_a_drop_it_leaps_down_to_search_there())
	results.append(await _tells_its_take_off_and_landing_up_a_step())
	results.append(await _tells_its_take_off_and_landing_down_a_drop(CHASE_SPEED))
	results.append(await _tells_its_take_off_and_landing_down_a_drop(FAST_CHASE_SPEED))
	results.append(await _thrown_off_in_a_jump_it_tells_no_landing())
	results.append(await _stopped_on_its_way_to_take_off_it_tells_no_take_off_nor_landing())
	finish(results)


## The man on a step height px high: the demon jumps up it once, taking off short of it and never
## against its wall, peaks no more than Jump Clearance over its top, lands on it and chases on.
func _jumps_up_a_step_and_lands_on_it(height: float) -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -height)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - height))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	var highest: float = demon.position.y
	var take_off_gap: float = -1.0
	var touched_the_wall: bool = false
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		highest = minf(highest, demon.position.y)
		if demon.get_state() == Demon.State.JUMP:
			if take_off_gap < 0.0:
				take_off_gap = STEP_X - demon.position.x - _half_width(demon)
			touched_the_wall = touched_the_wall or demon.is_on_wall()
	var feet: float = demon.position.y
	var state: Demon.State = demon.get_state()
	await _clear([ground, step, man, demon])
	var jumps: int = changes.count(Demon.State.JUMP)
	var peak: float = -highest - height
	return report(jumps == 1 and take_off_gap > TOLERANCE and not touched_the_wall
			and absf(feet + height) < TOLERANCE and peak >= 0.0
			and peak <= Demon.JUMP_CLEARANCE + PEAK_TOLERANCE and state == Demon.State.CHASE,
			"Step of %d px: %d jump, took off %.1f px short of it, touched its wall %s, feet at y = %.1f, peak %.1f px over its top, then %s"
			% [height, jumps, take_off_gap, touched_the_wall, feet, peak, _name_of(state)])


## The man on a step of one tile, with Jump Height but only a bite in Attacks: with no lunge to jump
## as, the demon stays on its floor and stands out of his reach.
func _with_no_lunge_it_never_jumps() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - TILE))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT, 0.0, 0.0, &"bite")
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([ground, step, man, demon])
	return report(not changes.has(Demon.State.JUMP) and absf(feet) < TOLERANCE
			and changes.has(Demon.State.OUT_OF_REACH),
			"Only a bite: jumped %s, feet at y = %.1f, out of reach %s"
			% [changes.has(Demon.State.JUMP), feet, changes.has(Demon.State.OUT_OF_REACH)])


## The man on a step a tile over Jump Height: the demon stays on its floor, with no jump, and stands
## out of his reach.
func _never_jumps_up_a_step_higher_than_jump_height() -> bool:
	var height: float = JUMP_HEIGHT + TILE
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -height)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - height))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([ground, step, man, demon])
	return report(not changes.has(Demon.State.JUMP) and absf(feet) < TOLERANCE
			and changes.has(Demon.State.OUT_OF_REACH),
			"Step of %d px over Jump Height %d: jumped %s, feet at y = %.1f, out of reach %s"
			% [height, JUMP_HEIGHT, changes.has(Demon.State.JUMP), feet,
			changes.has(Demon.State.OUT_OF_REACH)])


## The man on a step of one tile, past a ceiling over the step's corner too low for the demon's
## body: it stays on its floor, with no jump, and stands out of his reach.
func _never_jumps_where_a_ceiling_leaves_no_room() -> bool:
	var ceiling_bottom: float = -TILE - CEILING_ROOM
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var ceiling: StaticBody2D = make_wall(STEP_X, STEP_X + CEILING_WIDTH,
			ceiling_bottom - CEILING_THICKNESS, ceiling_bottom)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_PAST_CEILING, SPAWN_Y - TILE))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([ground, step, ceiling, man, demon])
	return report(changes.has(Demon.State.CHASE) and not changes.has(Demon.State.JUMP)
			and absf(feet) < TOLERANCE and changes.has(Demon.State.OUT_OF_REACH),
			"Ceiling %d px over a step of %d px: chased %s, jumped %s, feet at y = %.1f, out of reach %s"
			% [CEILING_ROOM, TILE, changes.has(Demon.State.CHASE), changes.has(Demon.State.JUMP),
			feet, changes.has(Demon.State.OUT_OF_REACH)])


## The man on a platform with room for the demon's body below it, and no step up to it: with Jump
## Height over the platform's top, the demon chases him to below him, never jumps, and stands out of
## his reach there, instead of following him along under him.
func _below_a_platform_with_no_step_it_stands_out_of_reach() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var platform: StaticBody2D = make_wall(PLATFORM_LEFT, PLATFORM_RIGHT, -PLATFORM_HEIGHT,
			-PLATFORM_HEIGHT + SHELF_THICKNESS)
	var man: Player = await spawn_on_floor(
			Vector2((PLATFORM_LEFT + PLATFORM_RIGHT) / 2.0, SPAWN_Y - PLATFORM_HEIGHT))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, HIGH_JUMP_HEIGHT)
	await wait_frames(FRAMES_TO_WATCH)
	var gap: float = absf(man.position.x - demon.position.x)
	var feet: float = demon.position.y
	await _clear([ground, platform, man, demon])
	return report(changes.has(Demon.State.CHASE) and not changes.has(Demon.State.JUMP)
			and changes.has(Demon.State.OUT_OF_REACH) and absf(feet) < TOLERANCE,
			"Below a platform %d px up: chased %s, jumped %s, out of reach %s, feet at y = %.1f, %.1f px from under the man"
			% [PLATFORM_HEIGHT, changes.has(Demon.State.CHASE), changes.has(Demon.State.JUMP),
			changes.has(Demon.State.OUT_OF_REACH), feet, gap])


## The crucifix's touch as the demon takes off up a step: it is thrown off at once, and lands with
## no jump under way.
func _the_crucifix_throws_it_off_in_the_middle_of_a_jump() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - TILE))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	var repellable: Repellable = demon.get_node(^"Repellable") as Repellable
	var jumped: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.JUMP, FRAMES_TO_WATCH)
	repellable.repelled.emit(man.global_position)
	var thrown: bool = demon.get_state() == Demon.State.THROWN
	await wait_frames(FRAMES_TO_WATCH)
	var state: Demon.State = demon.get_state()
	await _clear([ground, step, man, demon])
	return report(jumped and thrown and state != Demon.State.JUMP
			and state != Demon.State.THROWN,
			"Crucifix in a jump: jumped %s, thrown %s, then %s" % [jumped, thrown, _name_of(state)])


## The man freed as the demon takes off up a step: it lands and stands, with no man to chase.
func _a_man_freed_in_the_middle_of_a_jump_leaves_it_standing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - TILE))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	var jumped: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.JUMP, FRAMES_TO_WATCH)
	man.queue_free()
	await wait_frames(FRAMES_TO_WATCH)
	var state: Demon.State = demon.get_state()
	var on_floor: bool = demon.is_on_floor()
	await _clear([ground, step, demon])
	return report(jumped and on_floor and state == Demon.State.IDLE,
			"Man freed in a jump: jumped %s, on the floor %s, then %s"
			% [jumped, on_floor, _name_of(state)])


## The man on a floor depth px below the end of the demon's, which chases at chase_speed: the demon
## leaps down off it once, peaks Jump Clearance over its floor, never touches the corner on the way
## down, lands on that floor past the corner, and chases on.
func _drops_off_the_end_of_its_floor_and_lands_below(depth: float,
		chase_speed: float = CHASE_SPEED) -> bool:
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.chase_speed = chase_speed
	var highest: float = demon.position.y
	var touched_the_corner: bool = false
	var landing_back: float = -INF
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		highest = minf(highest, demon.position.y)
		if demon.get_state() == Demon.State.DROP and not demon.is_on_floor():
			touched_the_corner = touched_the_corner or demon.get_slide_collision_count() > 0
		if landing_back == -INF and absf(demon.position.y - depth) < TOLERANCE:
			landing_back = demon.position.x - _half_width(demon)
	var feet: float = demon.position.y
	var state: Demon.State = demon.get_state()
	await _clear([high, low, man, demon])
	var drops: int = changes.count(Demon.State.DROP)
	var peak: float = -highest
	return report(drops == 1 and absf(peak - Demon.JUMP_CLEARANCE) <= PEAK_TOLERANCE
			and not touched_the_corner and landing_back > EDGE_X
			and absf(feet - depth) < TOLERANCE and state == Demon.State.CHASE,
			"Drop of %d px at %d px/s: %d drop, peak %.1f px over its floor, touched the corner %s, landed with its back at x = %.1f (corner %d), feet at y = %.1f, then %s"
			% [depth, chase_speed, drops, peak, touched_the_corner, landing_back, EDGE_X, feet,
			_name_of(state)])


## The man on a floor a tile deeper than Max Drop below the end of the demon's: it stays on its
## floor, with no drop, and stands out of his reach.
func _never_drops_deeper_than_max_drop() -> bool:
	var depth: float = MAX_DROP + TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([high, low, man, demon])
	return report(changes.has(Demon.State.CHASE) and not changes.has(Demon.State.DROP)
			and absf(feet) < TOLERANCE and changes.has(Demon.State.OUT_OF_REACH),
			"Drop of %d px over Max Drop %d: chased %s, dropped %s, feet at y = %.1f, out of reach %s"
			% [depth, MAX_DROP, changes.has(Demon.State.CHASE), changes.has(Demon.State.DROP), feet,
			changes.has(Demon.State.OUT_OF_REACH)])


## The man on a floor two tiles below the end of the demon's, with Max Drop but only a bite in
## Attacks: with no lunge to leap as, the demon stays on its floor and stands out of his reach.
func _with_no_lunge_it_never_drops() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY,
			&"bite")
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([high, low, man, demon])
	return report(not changes.has(Demon.State.DROP) and absf(feet) < TOLERANCE
			and changes.has(Demon.State.OUT_OF_REACH),
			"Only a bite: dropped %s, feet at y = %.1f, out of reach %s"
			% [changes.has(Demon.State.DROP), feet, changes.has(Demon.State.OUT_OF_REACH)])


## The man on a floor two tiles below the end of the demon's, under a ceiling over that end too low
## for the demon's leap to peak under: it stays on its floor, with no leap, and stands out of his
## reach.
func _never_drops_where_a_ceiling_is_in_the_way_of_its_leap() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	var ceiling_bottom: float = -2.0 * _half_height(demon) - LOW_CEILING_ROOM
	var ceiling: StaticBody2D = make_wall(EDGE_X - LOW_CEILING_REACH, EDGE_X + LOW_CEILING_REACH,
			ceiling_bottom - CEILING_THICKNESS, ceiling_bottom)
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([high, low, ceiling, man, demon])
	return report(changes.has(Demon.State.CHASE) and not changes.has(Demon.State.DROP)
			and absf(feet) < TOLERANCE and changes.has(Demon.State.OUT_OF_REACH),
			"Ceiling %d px over its head at the end of its floor: chased %s, dropped %s, feet at y = %.1f, out of reach %s"
			% [LOW_CEILING_ROOM, changes.has(Demon.State.CHASE), changes.has(Demon.State.DROP),
			feet, changes.has(Demon.State.OUT_OF_REACH)])


## The man on a floor two tiles below the end of the demon's, which chases slowly: as it walks on to
## where it takes off, a block goes up on its floor right in front of it. Stopped, it stands out of
## his reach on its floor instead of staying in DROP.
func _stopped_on_its_way_to_take_off_it_stands_out_of_reach() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.chase_speed = SLOW_CHASE_SPEED
	var dropping: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.DROP, FRAMES_TO_WATCH)
	var front: float = demon.position.x + _half_width(demon)
	var block: StaticBody2D = make_wall(front + BLOCK_AHEAD, front + BLOCK_AHEAD + TILE,
			-BLOCK_HEIGHT, 0.0)
	var stood: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	await _clear([high, low, block, man, demon])
	return report(dropping and stood and absf(feet) < TOLERANCE,
			"Walk to take-off stopped: dropping %s, then out of reach %s, feet at y = %.1f"
			% [dropping, stood, feet])


## The crucifix's touch as the demon sets off down off the end of its floor: it is thrown off at
## once, and lands with no drop under way.
func _the_crucifix_throws_it_off_in_the_middle_of_a_drop() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	var repellable: Repellable = demon.get_node(^"Repellable") as Repellable
	var dropped: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.DROP, FRAMES_TO_WATCH)
	repellable.repelled.emit(man.global_position)
	var thrown: bool = demon.get_state() == Demon.State.THROWN
	await wait_frames(FRAMES_TO_WATCH)
	var state: Demon.State = demon.get_state()
	await _clear([high, low, man, demon])
	return report(dropped and thrown and state != Demon.State.DROP
			and state != Demon.State.THROWN,
			"Crucifix in a drop: dropped %s, thrown %s, then %s" % [dropped, thrown, _name_of(state)])


## The man freed as the demon sets off down off the end of its floor: it lands and stands, with no
## man to chase.
func _a_man_freed_in_the_middle_of_a_drop_leaves_it_standing() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	var dropped: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.DROP, FRAMES_TO_WATCH)
	man.queue_free()
	await wait_frames(FRAMES_TO_WATCH)
	var state: Demon.State = demon.get_state()
	var on_floor: bool = demon.is_on_floor()
	var feet: float = demon.position.y
	await _clear([high, low, demon])
	return report(dropped and on_floor and absf(feet - depth) < TOLERANCE
			and state == Demon.State.IDLE,
			"Man freed in a drop: dropped %s, on the floor %s, feet at y = %.1f, then %s"
			% [dropped, on_floor, feet, _name_of(state)])


## A demon put on the floor below the high one, where it falls to from where it was put, and then
## moved up onto the high one, as a throw could leave it: its post is on the low floor, at that
## floor's height. Walking back after a man on the high floor, it leaps back down by its way and
## walks all the way home to its post, which never moved (ADR 0043).
func _kept_off_its_post_on_a_higher_floor_it_leaps_back_down_and_walks_home() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X + POST_PAST_EDGE)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	demon.position = Vector2(EDGE_X - KEPT_OFF_AWAY, SPAWN_Y)
	await wait_frames(SETTLE_FRAMES)
	await wait_until(demon.is_on_floor)
	var first: Player = await spawn_on_floor(Vector2(EDGE_X - FIRST_MAN_AWAY, SPAWN_Y))
	var chased: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.CHASE, FRAMES_TO_WATCH)
	first.queue_free()
	var returned: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.RETURN, MAX_FRAMES)
	var home: bool = await wait_until(func() -> bool: return _stands_at(demon, post), MAX_FRAMES)
	var dropped: bool = changes.has(Demon.State.DROP)
	await _clear([high, low, demon])
	return report(absf(post.y - depth) < TOLERANCE and chased and returned and dropped and home,
			"Post at y = %.1f on the low floor (put at y = %d): chased %s, returned %s, dropped %s, home %s"
			% [post.y, SPAWN_Y, chased, returned, dropped, home])


## After a leap down off the end of its floor after the man, its way back keeps one step: from its
## own floor, short of the corner, to the floor below, past it.
func _its_leap_down_is_a_step_of_its_way() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	var empty_before: bool = demon.get_way_back().is_empty()
	var down: bool = await wait_until(
			func() -> bool: return _chases_on_floor_at(demon, depth), FRAMES_TO_WATCH)
	var way: DemonPath = demon.get_way_back()
	var steps: int = way.size()
	var from: Vector2 = way.get_from(0) if steps > 0 else Vector2.INF
	var to: Vector2 = way.get_to(0) if steps > 0 else Vector2.INF
	await _clear([high, low, man, demon])
	return report(empty_before and down and steps == 1 and absf(from.y) < TOLERANCE
			and from.x < EDGE_X and absf(to.y - depth) < TOLERANCE and to.x > EDGE_X,
			"Leap down: empty before %s, down %s, %d steps, from %s, to %s (corner x = %d)"
			% [empty_before, down, steps, from, to, EDGE_X])


## Thrown from its post down a step of Jump Height, and then after a man there it lets go of: on its
## way back it jumps back up the step, onto its post's floor, and walks home.
func _thrown_down_a_step_it_jumps_back_up_and_walks_home() -> bool:
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, JUMP_HEIGHT)
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT, 0.0, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	await _put_down(demon, Vector2(EDGE_X + KEPT_OFF_AWAY, SPAWN_Y + JUMP_HEIGHT))
	var thrown_steps: int = demon.get_way_back().size()
	var chased: bool = await _chase_and_let_go(demon, Vector2(EDGE_X + POST_PAST_EDGE,
			SPAWN_Y + JUMP_HEIGHT))
	var home: bool = await wait_until(func() -> bool: return _stands_at(demon, post), MAX_FRAMES)
	var jumps: int = changes.count(Demon.State.JUMP)
	var steps: int = demon.get_way_back().size()
	await _clear([high, low, demon])
	return report(thrown_steps == 1 and chased and jumps == 1 and home and steps == 0,
			"Thrown down %d px: %d steps, chased %s, %d jumps back, home %s, %d steps left"
			% [JUMP_HEIGHT, thrown_steps, chased, jumps, home, steps])


## After jumping up a step after the man, who is then freed: on its way back it leaps back down off
## the step, onto its post's floor, and walks home.
func _after_jumping_up_after_the_man_it_leaps_back_down_and_walks_home() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -JUMP_HEIGHT)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - JUMP_HEIGHT))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT, MAX_DROP)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	var up: bool = await wait_until(
			func() -> bool: return _chases_on_floor_at(demon, -JUMP_HEIGHT), FRAMES_TO_WATCH)
	man.queue_free()
	var home: bool = await wait_until(func() -> bool: return _stands_at(demon, post), MAX_FRAMES)
	var drops: int = changes.count(Demon.State.DROP)
	var steps: int = demon.get_way_back().size()
	await _clear([ground, step, demon])
	return report(up and drops == 1 and home and steps == 0,
			"Up a step after the man %s, %d leaps back down, home %s, %d steps left"
			% [up, drops, home, steps])


## Thrown down a step of Jump Height and then down another, and then after a man there it lets go
## of: on its way back it jumps up the last step first, then the first, and walks home.
func _two_steps_down_it_jumps_back_up_both_last_first() -> bool:
	var second_edge: float = EDGE_X + KEPT_OFF_AWAY
	var top: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var middle: StaticBody2D = make_platform(EDGE_X, second_edge, JUMP_HEIGHT)
	var bottom: StaticBody2D = make_platform(second_edge, FLOOR_RIGHT, 2.0 * JUMP_HEIGHT)
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT, 0.0, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	await _put_down(demon, Vector2((EDGE_X + second_edge) / 2.0, SPAWN_Y + JUMP_HEIGHT))
	await _put_down(demon, Vector2(second_edge + KEPT_OFF_AWAY, SPAWN_Y + 2.0 * JUMP_HEIGHT))
	var thrown_steps: int = demon.get_way_back().size()
	var chased: bool = await _chase_and_let_go(demon, Vector2(second_edge + POST_PAST_EDGE,
			SPAWN_Y + 2.0 * JUMP_HEIGHT))
	var on_the_middle: bool = await wait_until(
			func() -> bool: return _stands_on_floor_at(demon, JUMP_HEIGHT), MAX_FRAMES)
	var home: bool = await wait_until(func() -> bool: return _stands_at(demon, post), MAX_FRAMES)
	var jumps: int = changes.count(Demon.State.JUMP)
	await _clear([top, middle, bottom, demon])
	return report(thrown_steps == 2 and chased and on_the_middle and jumps == 2 and home,
			"Thrown down two steps: %d steps, chased %s, back on the middle floor %s, %d jumps, home %s"
			% [thrown_steps, chased, on_the_middle, jumps, home])


## Thrown from its post down a step a tile higher than Jump Height, and then after a man there it
## lets go of: it never jumps, walks toward its post as far as the step's wall, and stands there,
## with the step still on its way.
func _thrown_down_higher_than_jump_height_it_stands_below() -> bool:
	var depth: float = JUMP_HEIGHT + TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT, 0.0, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.return_speed = RETURN_SPEED
	await _put_down(demon, Vector2(EDGE_X + KEPT_OFF_AWAY, SPAWN_Y + depth))
	var chased: bool = await _chase_and_let_go(demon, Vector2(EDGE_X + POST_PAST_EDGE,
			SPAWN_Y + depth))
	var returned: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.RETURN, MAX_FRAMES)
	var stopped: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.IDLE, MAX_FRAMES)
	var off_the_wall: float = demon.position.x - _half_width(demon) - EDGE_X
	var feet: float = demon.position.y
	var steps: int = demon.get_way_back().size()
	await _clear([high, low, demon])
	return report(chased and returned and stopped and not changes.has(Demon.State.JUMP)
			and off_the_wall >= 0.0 and off_the_wall < TOLERANCE and absf(feet - depth) < TOLERANCE
			and steps == 1,
			"Thrown down %d px: chased %s, returned %s, stopped %s, jumped %s, %.1f px off the wall, feet at y = %.1f, %d steps"
			% [depth, chased, returned, stopped, changes.has(Demon.State.JUMP), off_the_wall, feet,
			steps])


## The man seen on a step of Jump Height and then hidden behind a pillar on it: the demon searches,
## jumps up the step in its search, and walks on to sniff where it last saw him.
func _hidden_up_a_step_it_jumps_up_to_search_there() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -JUMP_HEIGHT)
	var pillar_x: float = STEP_X + MAN_INSET + PILLAR_PAST_MAN
	var pillar: StaticBody2D = make_wall(pillar_x, pillar_x + TILE,
			-JUMP_HEIGHT - PILLAR_HEIGHT, -JUMP_HEIGHT)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - JUMP_HEIGHT))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	var sniffed: bool = await _hide_and_search(demon, man, -JUMP_HEIGHT)
	await _clear([ground, step, pillar, man, demon])
	var jumped_in_search: bool = _changed_in_order(changes, Demon.State.SEARCH, Demon.State.JUMP)
	return report(jumped_in_search and sniffed,
			"Hidden up a step: jumped up in its search %s, sniffed where it last saw him %s"
			% [jumped_in_search, sniffed])


## The man seen on a floor two tiles below the end of the demon's and then hidden behind a pillar
## on it: the demon searches, leaps down in its search, and walks on to sniff where it last saw him.
func _hidden_down_a_drop_it_leaps_down_to_search_there() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var pillar_x: float = EDGE_X + DROP_MAN_INSET + PILLAR_PAST_MAN
	var pillar: StaticBody2D = make_wall(pillar_x, pillar_x + TILE, depth - PILLAR_HEIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	var sniffed: bool = await _hide_and_search(demon, man, depth)
	await _clear([high, low, pillar, man, demon])
	var leapt_in_search: bool = _changed_in_order(changes, Demon.State.SEARCH, Demon.State.DROP)
	return report(leapt_in_search and sniffed,
			"Hidden down a drop: leapt down in its search %s, sniffed where it last saw him %s"
			% [leapt_in_search, sniffed])


## Once the demon chases the man, moves him behind the pillar past him on his floor, at floor_y,
## with a search that starts a few frames later. True once it sniffs where it last saw him, on his
## floor.
func _hide_and_search(demon: Demon, man: Player, floor_y: float) -> bool:
	demon.stats.give_up_time = SEARCH_GIVE_UP_TIME
	demon.stats.search_time = SEARCH_TIME
	var chased: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.CHASE, FRAMES_TO_WATCH)
	var seen_x: float = man.position.x
	man.position.x += HIDE_PAST_PILLAR
	return chased and await wait_until(func() -> bool: return demon.get_state() \
			== Demon.State.SEARCH and _stands_on_floor_at(demon, floor_y) \
			and absf(demon.position.x - seen_x) < TOLERANCE, MAX_FRAMES)


## True when changes has first, and then, later, then.
func _changed_in_order(changes: Array[int], first: Demon.State, then: Demon.State) -> bool:
	var at: int = changes.find(first)
	return at >= 0 and changes.find(then, at) > at


## Puts the demon at at, just over a floor, as a throw would, and waits until it stands there.
func _put_down(demon: Demon, at: Vector2) -> void:
	demon.position = at
	await wait_frames(SETTLE_FRAMES)
	await wait_until(demon.is_on_floor)


## A man on the floor at at, who the demon chases, and who is then freed. False if it never chased.
func _chase_and_let_go(demon: Demon, at: Vector2) -> bool:
	var man: Player = await spawn_on_floor(at)
	var chased: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.CHASE, FRAMES_TO_WATCH)
	man.queue_free()
	return chased


## True while the demon is on the floor whose top is at y.
func _stands_on_floor_at(demon: Demon, y: float) -> bool:
	return demon.is_on_floor() and absf(demon.position.y - y) < TOLERANCE


## True while the demon stands at post, on its floor.
func _stands_at(demon: Demon, post: Vector2) -> bool:
	return demon.get_state() == Demon.State.IDLE and demon.position.distance_to(post) <= TOLERANCE


## The man on a step of one tile: the demon tells one take-off, in JUMP, and one landing, on the
## floor, and its drawing stretches as it takes off, squashes as it lands, and is back to its own
## size after.
func _tells_its_take_off_and_landing_up_a_step() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - TILE))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	var leaps: Array[Vector2] = []
	var landings: Array[Vector2] = []
	var mistimed: Array[bool] = []
	_watch_leaps(demon, leaps, landings, mistimed)
	await wait_frames(FRAMES_TO_WATCH)
	var size: Vector2 = _drawing(demon).scale
	await _clear([ground, step, man, demon])
	return _report_leap("Step of %d px" % TILE, leaps, landings, mistimed, size)


## The man on a floor two tiles below the end of the demon's, which chases at chase_speed, walking
## to where it takes off or, fast, taking off at once: as up a step, one take-off, in DROP, and one
## landing, on the floor, stretched, squashed, and back to its own size after.
func _tells_its_take_off_and_landing_down_a_drop(chase_speed: float) -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.chase_speed = chase_speed
	var leaps: Array[Vector2] = []
	var landings: Array[Vector2] = []
	var mistimed: Array[bool] = []
	_watch_leaps(demon, leaps, landings, mistimed)
	await wait_frames(FRAMES_TO_WATCH)
	var size: Vector2 = _drawing(demon).scale
	await _clear([high, low, man, demon])
	return _report_leap("Drop of %d px at %d px/s" % [depth, chase_speed], leaps, landings,
			mistimed, size)


## The crucifix's touch as the demon takes off up a step: it told its take-off, never tells a
## landing, and its drawing is back to its own size at once.
func _thrown_off_in_a_jump_it_tells_no_landing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + MAN_INSET, SPAWN_Y - TILE))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, JUMP_HEIGHT)
	var leaps: Array[Vector2] = []
	var landings: Array[Vector2] = []
	var mistimed: Array[bool] = []
	_watch_leaps(demon, leaps, landings, mistimed)
	var repellable: Repellable = demon.get_node(^"Repellable") as Repellable
	var jumped: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.JUMP, FRAMES_TO_WATCH)
	repellable.repelled.emit(man.global_position)
	var size: Vector2 = _drawing(demon).scale
	var came_down: bool = await wait_until(demon.is_on_floor, FRAMES_TO_WATCH)
	var take_offs: int = leaps.size()
	var landed: int = landings.size()
	await _clear([ground, step, man, demon])
	return report(jumped and came_down and take_offs == 1 and landed == 0 and mistimed.is_empty()
			and size.is_equal_approx(Vector2.ONE),
			"Crucifix in a jump: jumped %s, came down %s with %d take-off and %d landing, told at the wrong time %s, size when thrown %s"
			% [jumped, came_down, take_offs, landed, not mistimed.is_empty(), size])


## As in _stopped_on_its_way_to_take_off_it_stands_out_of_reach: in DROP but stopped before it
## takes off, the demon tells neither a take-off nor a landing.
func _stopped_on_its_way_to_take_off_it_tells_no_take_off_nor_landing() -> bool:
	var depth: float = 2.0 * TILE
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	demon.stats.chase_speed = SLOW_CHASE_SPEED
	var leaps: Array[Vector2] = []
	var landings: Array[Vector2] = []
	var mistimed: Array[bool] = []
	_watch_leaps(demon, leaps, landings, mistimed)
	var dropping: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.DROP, FRAMES_TO_WATCH)
	var front: float = demon.position.x + _half_width(demon)
	var block: StaticBody2D = make_wall(front + BLOCK_AHEAD, front + BLOCK_AHEAD + TILE,
			-BLOCK_HEIGHT, 0.0)
	var stood: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	await _clear([high, low, block, man, demon])
	return report(dropping and stood and leaps.is_empty() and landings.is_empty(),
			"Walk to take-off stopped: dropping %s, then out of reach %s, %d take-off, %d landing"
			% [dropping, stood, leaps.size(), landings.size()])


## Writes the size of demon's drawing into leaps each time it tells took_off, and into landings
## each time it tells landed, and true into mistimed for a take-off out of JUMP and DROP or a
## landing in the air.
func _watch_leaps(demon: Demon, leaps: Array[Vector2], landings: Array[Vector2],
		mistimed: Array[bool]) -> void:
	var on_take_off: Callable = func() -> void:
		leaps.append(_drawing(demon).scale)
		if demon.get_state() != Demon.State.JUMP and demon.get_state() != Demon.State.DROP:
			mistimed.append(true)
	var on_landing: Callable = func() -> void:
		landings.append(_drawing(demon).scale)
		if not demon.is_on_floor():
			mistimed.append(true)
	demon.took_off.connect(on_take_off)
	demon.landed.connect(on_landing)


## Passes with one take-off told with the drawing taller and narrower, one landing told with it
## wider and lower, none at the wrong time, and the drawing at size after, back to its own.
func _report_leap(what: String, leaps: Array[Vector2], landings: Array[Vector2],
		mistimed: Array[bool], size: Vector2) -> bool:
	var stretched: bool = leaps.size() == 1 and leaps[0].x < 1.0 and leaps[0].y > 1.0
	var squashed: bool = landings.size() == 1 and landings[0].x > 1.0 and landings[0].y < 1.0
	return report(stretched and squashed and mistimed.is_empty()
			and size.is_equal_approx(Vector2.ONE),
			"%s: take-offs at sizes %s, landings at sizes %s, told at the wrong time %s, size after %s"
			% [what, leaps, landings, not mistimed.is_empty(), size])


## The demon's stand-in drawing, read from its scene.
func _drawing(demon: Demon) -> Polygon2D:
	return demon.get_node(^"Placeholder") as Polygon2D


## A demon at x with the cases' values, jump_height and max_drop, and one attack of animation, with
## its own defaults, facing right, writing each state it changes to into changes. Its body lets the
## man's through, so only the floors stop it.
func _spawn_demon(changes: Array[int], jump_height: float, max_drop: float = 0.0,
		x: float = 0.0, animation: StringName = &"lunge") -> Demon:
	var attack: DemonAttack = DemonAttack.new()
	attack.animation = animation
	attack.attack_range = 0.0
	attack.max_height_difference = MAX_HEIGHT_DIFFERENCE
	var stats: DemonStats = DemonStats.new()
	stats.sight_distance = SIGHT_DISTANCE
	stats.lose_distance = LOSE_DISTANCE
	stats.give_up_time = GIVE_UP_TIME
	stats.chase_speed = CHASE_SPEED
	stats.out_of_reach_wait = OUT_OF_REACH_WAIT
	stats.jump_height = jump_height
	stats.max_drop = max_drop
	stats.attacks.append(attack)
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.stats = stats
	demon.position = Vector2(x, SPAWN_Y)
	demon.collision_mask &= ~_bit_of(PLAYER_LAYER_NAME)
	demon.state_changed.connect(
			func(_previous: Demon.State, current: Demon.State) -> void: changes.append(current))
	root.add_child(demon)
	await wait_until(demon.is_on_floor)
	return demon


## Half the width of the demon's body box, read from its scene.
func _half_width(demon: Demon) -> float:
	return (demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape.get_rect().size.x / 2.0


## True while the demon chases on the floor whose top is at y.
func _chases_on_floor_at(demon: Demon, y: float) -> bool:
	return demon.get_state() == Demon.State.CHASE and absf(demon.position.y - y) < TOLERANCE


## Half the height of the demon's body box, read from its scene.
func _half_height(demon: Demon) -> float:
	return (demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape.get_rect().size.y / 2.0


func _name_of(state: Demon.State) -> String:
	return Demon.State.keys()[state]


## The bit of the physics layer the project gives that name; 0 if none has it.
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
