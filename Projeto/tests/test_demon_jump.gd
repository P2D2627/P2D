# Checks the demon's jump up a step (ADR 0042). With Jump Height, a demon chasing a man out of its
# reach above it jumps up a step of one tile and of Jump Height as it lunges, on the run: it takes
# off short of the step, peaks just over its top, and lands on it; it never jumps up a step higher
# than that, nor where a ceiling over the step leaves no room for its body, nor with no lunge to
# jump as, and stands out of his reach instead. With him on a platform right over it, and no
# step in between, it stands out of his reach below him, with no jump. The crucifix throws it off
# in the middle of a jump, and a man freed in the middle of one leaves it standing once it lands.
# With Max Drop, after a man out of its reach below it, it walks off the end of its floor and lands
# on the floor below, a tile clear of the corner, for a drop of two tiles and of Max Drop, and
# never off a drop deeper than that. With no Jump Height nor Max Drop, the step and edge cases of
# test_demon.gd hold.
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


## The man on a floor depth px below the end of the demon's: the demon drops off it once, lands on
## that floor clear of the corner, and chases on.
func _drops_off_the_end_of_its_floor_and_lands_below(depth: float) -> bool:
	var high: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var low: StaticBody2D = make_platform(EDGE_X, FLOOR_RIGHT, depth)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + DROP_MAN_INSET, SPAWN_Y + depth))
	var changes: Array[int] = []
	var demon: Demon = await _spawn_demon(changes, 0.0, MAX_DROP, EDGE_X - DROP_DEMON_AWAY)
	await wait_frames(FRAMES_TO_WATCH)
	var feet: float = demon.position.y
	var back: float = demon.position.x - _half_width(demon)
	var state: Demon.State = demon.get_state()
	await _clear([high, low, man, demon])
	var drops: int = changes.count(Demon.State.DROP)
	return report(drops == 1 and absf(feet - depth) < TOLERANCE and back >= EDGE_X
			and state == Demon.State.CHASE,
			"Drop of %d px: %d drop, feet at y = %.1f, back at x = %.1f, then %s"
			% [depth, drops, feet, back, _name_of(state)])


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
