# Checks the ledge assist. Falling into the side of a ledge with the feet a little below its top,
# within Ledge Assist Height, while moving toward it or only touching it, the player is lifted onto
# it by the fewest px, going right or left, onto a ledge of the levels' tiles as onto one that is a
# body, and also falling at Max Fall Speed while drifting slowly into it. A press of Jump just after
# the lift jumps from the ledge, not off its face. Further below, with Ledge Assist Height at 0,
# pushing away from it, against a demon's side, under a ceiling that leaves no room, held still or
# in a knockback, he is never lifted and falls along the side; a one-way platform has no side, so
# he goes through it, and on the floor a low step is never climbed. Going up, he is not lifted: the
# jump carries him on, over the top.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ledge_assist.gd
extends "res://tests/support/player_test.gd"

## The floor's top is at y = 0. Every ledge is a block standing on it, with its top at LEDGE_TOP.
const LEDGE_TOP: float = -200.0
const BLOCK_WIDTH: float = 400.0
const FLOOR_LEFT: float = -1600.0
const FLOOR_RIGHT: float = 5600.0
## The face of the ledge met going right, and of the one met going left.
const RIGHT_LEDGE_FACE: float = 600.0
const LEFT_LEDGE_FACE: float = -600.0
## The face of a block on the demons' layer, met going right.
const DEMON_FACE: float = 1600.0
## The face of a ledge with a ceiling over the way to it, met going right. Nothing is over the
## ledge, so only the ceiling can stop the lift.
const CEILING_LEDGE_FACE: float = 2600.0
## How far from that face the ceiling reaches over the way to the ledge, and how thick it is, in px.
const CEILING_REACH: float = 300.0
const CEILING_THICKNESS: float = 100.0
## The face of a ledge of the levels' solid tiles, met going right, with its top at LEDGE_TOP and
## TILE_LEDGE_COLUMNS tiles wide.
const TILE_LEDGE_FACE: float = 3600.0
const TILE_LEDGE_COLUMNS: int = 4
## The left end of a one-way platform of the levels' tiles, met going right, with its top at
## LEDGE_TOP and TILE_LEDGE_COLUMNS tiles long.
const ONE_WAY_FACE: float = 5300.0
const TILE_SET: TileSet = preload("res://scenes/levels/Lust/cave_placeholder_tiles.tres")
## The levels' solid block: a full cell on the physics layer of the levels' walls.
const SOLID_SOURCE: int = 0
const SOLID_ATLAS: Vector2i = Vector2i(0, 0)
## The One Way tile: an alternative of the solid block that collides only by its top edge.
const ONE_WAY_ALTERNATIVE: int = 1
const TILE_SIZE: float = 48.0
## Room between the player's head and the ceiling when he starts, in px: less than any lift.
const CEILING_ROOM: float = 2.0
## How far from a face the side of the player's body starts, in px: less than one frame of a run.
const GAP: float = 2.0
## How far below the top the feet start in reach of the assist, under Ledge Assist Height, and out
## of it, over it, in px. The lift goes by whole px, so the edge itself is not checked.
const UNDER_REACH: float = 1.0
const OVER_REACH: float = 2.0
## How far from a top the feet may end and still stand on it, in px.
const STAND_TOLERANCE: float = 1.0
## How far the feet may rise above where they start without counting as lifted, in px.
const LIFT_TOLERANCE: float = 0.5
## A slow drift sideways, in px/s. The run speeds it up before the lift, but a step still carries
## him only about a px past the face.
const DRIFT_SPEED: float = 30.0
## Going up into the ledge, in px/s, with Jump held: enough to rise RISE_ABOVE px over its top.
const RISE_SPEED: float = 600.0
const RISE_ABOVE: float = 30.0
## Rising slowly along a face, touching it, from this many px below the top, in px, at this speed,
## in px/s: one frame up along it, then the peak, in reach of the assist.
const SLOW_RISE_DEPTH: float = 10.0
const SLOW_RISE_SPEED: float = 60.0
## How far below the top the feet start for the smallest lift, in px, and how far over the top a
## lift by the fewest px may leave them, in px.
const SHALLOW_DEPTH: float = 4.0
const OVER_THE_TOP: float = 1.5
## A low step on the floor, met going right, and its height in px: under Ledge Assist Height.
const STEP_FACE: float = 4600.0
const STEP_HEIGHT: float = 10.0
## How far from the step the player starts on the floor, in px, and for how many frames he runs.
const STEP_GAP: float = 40.0
const STEP_RUN_FRAMES: int = 30
## The knockback thrown at the player, in px; the case then sets his speed at the top of its arc.
const KNOCKBACK_DISTANCE: float = 200.0
const KNOCKBACK_HEIGHT: float = 40.0

var _half_width: float = 0.0
## Ledge Assist Height and Max Fall Speed in the player's Stats.
var _reach: float = 0.0
var _max_fall_speed: float = 0.0


func _initialize() -> void:
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	var size: Vector2 = body_size(probe)
	_half_width = size.x / 2.0
	_reach = probe.stats.ledge_assist_height
	_max_fall_speed = probe.stats.max_fall_speed
	var demon_layers: int = probe.knock_off_layers
	probe.queue_free()
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	make_wall(RIGHT_LEDGE_FACE, RIGHT_LEDGE_FACE + BLOCK_WIDTH, LEDGE_TOP)
	make_wall(LEFT_LEDGE_FACE - BLOCK_WIDTH, LEFT_LEDGE_FACE, LEDGE_TOP)
	var demon: StaticBody2D = make_wall(DEMON_FACE, DEMON_FACE + BLOCK_WIDTH, LEDGE_TOP)
	demon.collision_layer = demon_layers
	make_wall(CEILING_LEDGE_FACE, CEILING_LEDGE_FACE + BLOCK_WIDTH, LEDGE_TOP)
	var ceiling_bottom: float = LEDGE_TOP + _reach - UNDER_REACH - size.y - CEILING_ROOM
	make_wall(CEILING_LEDGE_FACE - CEILING_REACH, CEILING_LEDGE_FACE,
			ceiling_bottom - CEILING_THICKNESS, ceiling_bottom)
	_make_tile_ledge(TILE_LEDGE_FACE)
	_make_one_way_platform(ONE_WAY_FACE)
	make_wall(STEP_FACE, STEP_FACE + BLOCK_WIDTH, -STEP_HEIGHT)
	await physics_frame
	var results: Array[bool] = []
	results.append(await _a_little_below_the_top_climbs_onto_the_ledge(1.0))
	results.append(await _a_little_below_the_top_climbs_onto_the_ledge(-1.0))
	results.append(await _a_ledge_of_tiles_is_climbed_as_one_of_bodies())
	results.append(await _just_below_the_top_the_lift_is_the_smallest())
	results.append(await _touching_the_face_with_no_direction_climbs_onto_the_ledge())
	results.append(await _further_below_the_top_falls_along_the_side())
	results.append(await _with_ledge_assist_height_at_0_falls_along_the_side())
	results.append(await _pushing_away_falls_along_the_side())
	results.append(await _a_demon_is_never_climbed())
	results.append(await _a_ceiling_with_no_room_stops_the_lift())
	results.append(await _falling_fast_while_drifting_into_a_ledge_climbs_onto_it())
	results.append(await _going_up_into_a_ledge_keeps_rising())
	results.append(await _jump_just_after_the_lift_jumps_from_the_ledge())
	results.append(await _held_still_falls_along_the_side())
	results.append(await _in_a_knockback_falls_along_the_side())
	results.append(await _on_the_floor_a_low_step_is_never_climbed())
	results.append(await _a_one_way_platform_gets_no_lift())
	finish(results)


## Feet a little below the top, under Ledge Assist Height: lifted onto the ledge, on either side.
func _a_little_below_the_top_climbs_onto_the_ledge(side: float) -> bool:
	var face: float = RIGHT_LEDGE_FACE if side > 0.0 else LEFT_LEDGE_FACE
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(face, side, depth, side)
	return _report_on_the_ledge(approach,
			"Falling into a ledge %.1f px below its top, going %s" % [depth, _side_name(side)])


## The levels' walls are tiles, not bodies: a ledge of tiles is climbed as one that is a body.
func _a_ledge_of_tiles_is_climbed_as_one_of_bodies() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(TILE_LEDGE_FACE, 1.0, depth, 1.0)
	return _report_on_the_ledge(approach,
			"Falling into a ledge of tiles %.1f px below its top" % depth)


## The lift is by the fewest px: with the feet just below the top, they end just over it, never up
## to Ledge Assist Height over it.
func _just_below_the_top_the_lift_is_the_smallest() -> bool:
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, SHALLOW_DEPTH, 1.0)
	return _report_on_the_ledge(approach,
			"Falling into a ledge %.1f px below its top" % SHALLOW_DEPTH)


## Touching a ledge's face with no direction held, at the top of a slow rise along it, he is lifted
## onto it too: the assist takes no push, as the wall slide takes none.
func _touching_the_face_with_no_direction_climbs_onto_the_ledge() -> bool:
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, SLOW_RISE_DEPTH, 0.0, -1.0,
			0.0, -SLOW_RISE_SPEED, 0.0)
	return _report_on_the_ledge(approach,
			"Rising along a ledge's face with no direction held, %.1f px below its top"
			% SLOW_RISE_DEPTH)


## Feet further below the top than Ledge Assist Height: never lifted, so he falls along the side.
func _further_below_the_top_falls_along_the_side() -> bool:
	var depth: float = _reach + OVER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, 1.0)
	return _report_along_the_side(approach,
			"Falling into a ledge %.1f px below its top" % depth)


## Ledge Assist Height at 0 turns the assist off, even a few px below the top.
func _with_ledge_assist_height_at_0_falls_along_the_side() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, 1.0, 0.0)
	return _report_along_the_side(approach,
			"Ledge Assist Height 0, falling into a ledge %.1f px below its top" % depth)


## Carried into the ledge by the run while pushing away from it: no lift, as the player chose to go.
func _pushing_away_falls_along_the_side() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, -1.0)
	return _report_along_the_side(approach,
			"Pushing away while carried into a ledge %.1f px below its top" % depth)


## A demon is never a ledge: falling into its side a little below its top lifts nothing.
func _a_demon_is_never_climbed() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(DEMON_FACE, 1.0, depth, 1.0)
	return _report_along_the_side(approach,
			"Falling into a demon's side %.1f px below its top" % depth)


## No lift goes through a ceiling: with the head CEILING_ROOM px under one, he is never lifted,
## though the ledge has room over it.
func _a_ceiling_with_no_room_stops_the_lift() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(CEILING_LEDGE_FACE, 1.0, depth, 1.0)
	return _report_along_the_side(approach,
			"Under a ceiling %.1f px over the head, falling into a ledge %.1f px below its top"
			% [CEILING_ROOM, depth])


## The assist stops the fall as it lifts: falling at Max Fall Speed, drifting into the face at
## DRIFT_SPEED from right against it, a step carries him over the top and he lands on it.
func _falling_fast_while_drifting_into_a_ledge_climbs_onto_it() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, 1.0, -1.0,
			DRIFT_SPEED, _max_fall_speed, 0.0)
	return _report_on_the_ledge(approach,
			"Falling at Max Fall Speed, drifting into a ledge %.1f px below its top" % depth)


## No lift going up: rising into the face a little below the top, with Jump held, the jump carries
## him on past the top, well over it, instead of being cut at its height.
func _going_up_into_a_ledge_keeps_rising() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, 1.0, -1.0, -1.0,
			-RISE_SPEED)
	var over_the_top: float = LEDGE_TOP - approach.highest_y
	return report(over_the_top >= RISE_ABOVE,
			("Going up at %.1f px/s into a ledge %.1f px below its top: rose %.1f px over it, at "
			+ "least %.1f") % [RISE_SPEED, depth, over_the_top, RISE_ABOVE])


## A press of Jump on the frame after the lift jumps from the ledge, never off the face the player
## rose along until the lift: with no direction held, the jump goes straight up, over the top, and
## he lands back on the ledge.
func _jump_just_after_the_lift_jumps_from_the_ledge() -> bool:
	var start: Vector2 = Vector2(RIGHT_LEDGE_FACE - _half_width, LEDGE_TOP + SLOW_RISE_DEPTH)
	var player: Player = spawn_player(start)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	stand_in.hold_jump = true
	player.velocity = Vector2(0.0, -SLOW_RISE_SPEED)
	var touched: bool = false
	var lifted: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.position.y < start.y - SLOW_RISE_DEPTH / 2.0:
			lifted = true
			break
		touched = touched or player.is_on_wall()
	stand_in.run_direction = 0.0
	stand_in.hold_jump = false
	stand_in.press_jump()
	var jump_top: float = LEDGE_TOP - player.stats.min_jump_height / 2.0
	var highest_y: float = player.position.y
	var rose: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		highest_y = minf(highest_y, player.position.y)
		rose = rose or highest_y < jump_top
		if rose and player.is_on_floor():
			break
	var end: Vector2 = player.position
	await remove_player(player)
	var on_ledge: bool = rose and absf(end.y - LEDGE_TOP) <= STAND_TOLERANCE
	return report(touched and lifted and on_ledge,
			("Jump pressed on the frame after the lift: touched the face %s, lifted %s, rose over "
			+ "the top %s, landed at x %.1f, y %.1f, the ledge from x %.1f, its top at %.1f")
			% [touched, lifted, rose, end.x, end.y, RIGHT_LEDGE_FACE, LEDGE_TOP])


## Held still, as by Velvet's talk or by his death, he is never lifted, though the run still carries
## him into the ledge he touches: he falls along its side.
func _held_still_falls_along_the_side() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, 1.0, -1.0, -1.0, 0.0,
			0.0, func(player: Player) -> void: player.hold_still())
	return _report_along_the_side(approach,
			"Held still, carried into a ledge %.1f px below its top" % depth)


## In a knockback he is never lifted, though it carries him into the ledge at the top of its arc:
## he falls along its side.
func _in_a_knockback_falls_along_the_side() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(RIGHT_LEDGE_FACE, 1.0, depth, 1.0, -1.0, -1.0, 0.0,
			GAP, _knock_toward_the_ledge)
	return _report_along_the_side(approach,
			"In a knockback, carried into a ledge %.1f px below its top" % depth)


## On the floor there is no lift: running into a step lower than Ledge Assist Height, he stays on
## the floor against it, as without the assist.
func _on_the_floor_a_low_step_is_never_climbed() -> bool:
	var player: Player = await spawn_on_floor(Vector2(STEP_FACE - _half_width - STEP_GAP, -2.0))
	if player == null:
		return report(false, "Running on the floor into a low step: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var highest_y: float = player.position.y
	for _frame: int in STEP_RUN_FRAMES:
		await physics_frame
		highest_y = minf(highest_y, player.position.y)
	var end: Vector2 = player.position
	await remove_player(player)
	return report(highest_y >= -LIFT_TOLERANCE and end.x < STEP_FACE,
			("Running on the floor into a step %.0f px high: highest y %.1f, ended at x %.1f, the "
			+ "step from x %.1f") % [STEP_HEIGHT, highest_y, end.x, STEP_FACE])


## A one-way platform has no side to meet, so the assist never lifts onto one: falling into its end
## a little below its top, he goes through it and lands on the floor.
func _a_one_way_platform_gets_no_lift() -> bool:
	var depth: float = _reach - UNDER_REACH
	var approach: Approach = await _approach(ONE_WAY_FACE, 1.0, depth, 1.0)
	return _report_along_the_side(approach,
			"Falling into the end of a one-way platform %.1f px below its top" % depth)


## Throws the player back toward the ledge, then sets him at the top of the arc at Max Run Speed
## toward it: the knockback is under way, and the ledge's top in reach of a lift.
func _knock_toward_the_ledge(player: Player) -> void:
	player.knock_back(1.0, KNOCKBACK_DISTANCE, KNOCKBACK_HEIGHT)
	player.velocity = Vector2(player.stats.max_run_speed, 0.0)


## Spawns the player with its side gap px from face, on the side away from it, the feet depth px
## below LEDGE_TOP, with run_direction held, and follows him until he lands. He moves toward the
## face at across px/s, Max Run Speed if across is negative, and down at down px/s: 0 at the top of
## a jump, below 0 going up, with Jump held. A reach of 0 or more replaces Ledge Assist Height. A
## valid setup is called with the player once he moves, before his first frame.
func _approach(face: float, side: float, depth: float, run_direction: float,
		reach: float = -1.0, across: float = -1.0, down: float = 0.0, gap: float = GAP,
		setup: Callable = Callable()) -> Approach:
	var start: Vector2 = Vector2(face - side * (_half_width + gap), LEDGE_TOP + depth)
	var player: Player = spawn_player(start)
	if reach >= 0.0:
		player.stats.ledge_assist_height = reach
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = run_direction
	stand_in.hold_jump = down < 0.0
	var speed_across: float = player.stats.max_run_speed if across < 0.0 else across
	player.velocity = Vector2(side * speed_across, down)
	if setup.is_valid():
		setup.call(player)
	var approach: Approach = Approach.new()
	approach.start_y = start.y
	approach.highest_y = start.y
	for _frame: int in MAX_FRAMES:
		await physics_frame
		approach.highest_y = minf(approach.highest_y, player.position.y)
		if player.is_on_floor():
			approach.landed = true
			break
	approach.end = player.position
	await remove_player(player)
	return approach


## PASS if he landed standing on the ledge's top, lifted by the fewest px: the feet never went more
## than OVER_THE_TOP px over it.
func _report_on_the_ledge(approach: Approach, what: String) -> bool:
	var on_ledge: bool = approach.landed and absf(approach.end.y - LEDGE_TOP) <= STAND_TOLERANCE
	var smallest: bool = approach.highest_y >= LEDGE_TOP - OVER_THE_TOP
	return report(on_ledge and smallest,
			"%s: landed at y %.1f, highest %.1f, the ledge's top at %.1f, the floor's at 0.0"
			% [what, approach.end.y, approach.highest_y, LEDGE_TOP])


## PASS if he was never lifted and landed on the floor below the ledge.
func _report_along_the_side(approach: Approach, what: String) -> bool:
	var lifted_by: float = approach.start_y - approach.highest_y
	var on_floor: bool = approach.landed and absf(approach.end.y) <= STAND_TOLERANCE
	return report(on_floor and lifted_by <= LIFT_TOLERANCE,
			"%s: lifted by %.1f px, landed at y %.1f, the floor's top at 0.0"
			% [what, lifted_by, approach.end.y])


func _side_name(side: float) -> String:
	return "right" if side > 0.0 else "left"


## A ledge of the levels' solid tiles, TILE_LEDGE_COLUMNS tiles wide, with its left face at x = face
## and its top at LEDGE_TOP, from there down past the floor's top.
func _make_tile_ledge(face: float) -> void:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = TILE_SET
	tiles.position = Vector2(face, LEDGE_TOP)
	for row: int in ceili(-LEDGE_TOP / TILE_SIZE):
		for column: int in TILE_LEDGE_COLUMNS:
			tiles.set_cell(Vector2i(column, row), SOLID_SOURCE, SOLID_ATLAS)
	root.add_child(tiles)


## A one-way platform of the levels' One Way tiles, TILE_LEDGE_COLUMNS tiles long, with its left end
## at x = face and its top at LEDGE_TOP.
func _make_one_way_platform(face: float) -> void:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = TILE_SET
	tiles.position = Vector2(face, LEDGE_TOP)
	for column: int in TILE_LEDGE_COLUMNS:
		tiles.set_cell(Vector2i(column, 0), SOLID_SOURCE, SOLID_ATLAS, ONE_WAY_ALTERNATIVE)
	root.add_child(tiles)


## What _approach follows: where the feet started and the highest they went, in y, whether he
## landed, and where.
class Approach:
	var start_y: float = 0.0
	var highest_y: float = 0.0
	var landed: bool = false
	var end: Vector2 = Vector2.ZERO
