# Checks the wall slide. Against a wall it touches in the air, pushing into it or not, the player
# falls no faster than Wall Slide Speed from the frame after it reaches the wall, and keeps sliding
# after letting go of the direction. A jump
# along the wall peaks at Jump Height and slides after the peak, even after letting go of the
# direction in the air, and the fall after that peak speeds up as without a wall until it reaches
# Wall Slide Speed. Pushing away from the wall, from the slide or while carried into it, and running
# away from it on the floor all work as without a wall. A wall of the levels' tiles takes no push
# either, touched or carried into. Far from the origin, on either side, carried into a wall or
# jumping straight up from rest by it, he slides as near it; off the bottom of a wall that ends in
# the air, he falls straight down, and past a gap in a wall he slides on down to the floor, never
# stopping on a corner. A demon's side, a body on Knock Off Layers, still takes a push:
# touching one without pushing into it falls as without a wall, pushing into it slides, letting go
# against one that backs away never follows it, and once it is gone it leaves no wall behind.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_slide.gd
extends "res://tests/support/player_test.gd"

## The wall's face is at x = WALL_FACE, on the player's left; the floor's top is at y = 0.
const WALL_FACE: float = 0.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -3000.0
const FLOOR_RIGHT: float = 2000.0
## Where a fall starts: high enough to reach the top falling speed well before the floor.
const START_HEIGHT: float = -1500.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## How far from the wall the player starts, in px.
const GAP: float = 40.0
## The face of a tall body on the demons' layer, on the player's right when it starts by it: far
## enough from the wall that no case near the wall reaches it.
const DEMON_FACE: float = 1200.0
## The face of a tall wall of the levels' solid tiles, one tile thick, on the player's right when it
## starts by it, between the demon's side and the end of the floor.
const TILE_FACE: float = 1700.0
## The face of a body on the demons' layer that is freed while the player touches it, on the
## player's right, between the wall and the demon's side; it only exists in its own case.
const GONE_FACE: float = 800.0
## The face of another wall of tiles, as the first, far from the origin as most of a level's walls
## are, on its own floor: level 1 reaches x = 17 800. From about x = 2048 (measured), the rounding
## of 32-bit floats makes a touch the engine reads only from the safe margin come and go. Its
## mirror, a wall on the player's left, has its face at x = -FAR_TILE_FACE.
const FAR_TILE_FACE: float = 9600.0
## How far each far wall's floor reaches from its face into the open, in px.
const FAR_FLOOR_REACH: float = 400.0
## The face of a wall of tiles that ends in the air, far from the origin too, on its own floor: from
## WALL_TOP down to OVERHANG_BOTTOM, a whole number of tiles above the floor's top.
const OVERHANG_FACE: float = 12000.0
const OVERHANG_BOTTOM: float = -624.0
## The face of a far wall of tiles with a gap in it, on its own floor: from WALL_TOP down to
## GAP_TOP, then GAP_HEIGHT px of open air, then on down to the floor, in line; whole tiles.
const GAPPED_FACE: float = 14400.0
const GAP_TOP: float = -1248.0
const GAP_HEIGHT: float = 144.0
## Falling in the gap at Max Fall Speed, in line with the face below it, as after sliding down the
## wall above it: the feet start this many px over the top of the wall below the gap and the side
## of the body this many px from the face's line, under the safe margin, as level 1 measured (6.3 and
## 0.074), so the frame that takes the feet past that top starts with no wall beside.
const OVER_THE_TOP: float = 6.0
const IN_LINE_GAP: float = 0.05
## Frames a player standing against a wall waits after letting go of the direction, before a jump,
## so his run has stopped.
const STOP_FRAMES: int = 10
## The face of a body on the demons' layer that backs away slowly from the player, at BACKING_SPEED
## px/s for BACKING_FRAMES frames, between the wall and the freed demon's side; only in its own case.
const BACKING_FACE: float = 500.0
const BACKING_SPEED: float = 20.0
const BACKING_FRAMES: int = 60
## How far across the player may move where nothing should carry him across, in px.
const DRIFT_TOLERANCE: float = 0.5
const TILE_SET: TileSet = preload("res://scenes/others/tilesets/cave_placeholder_tiles.tres")
## The levels' solid block: a full cell on the physics layer of the levels' walls.
const SOLID_SOURCE: int = 0
const SOLID_ATLAS: Vector2i = Vector2i(0, 0)
const TILE_SIZE: float = 48.0
## Frames to keep pushing after the first contact, so the player is surely on the wall.
const SETTLE_FRAMES: int = 3
## How far a peak may be from Jump Height, in px, as in test_jump_height.gd.
const HEIGHT_TOLERANCE: float = 1.0
## How far a speed may be from the one expected, in px/s.
const SPEED_TOLERANCE: float = 0.01

## Half the width of the player's collision box, read from its scene.
var _half_width: float = 0.0
## The player's Knock Off Layers: the layers of the demons' bodies.
var _demon_layers: int = 0


func _initialize() -> void:
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP)
	make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	_half_width = body_size(probe).x / 2.0
	_demon_layers = probe.knock_off_layers
	probe.queue_free()
	var demon_side: StaticBody2D = make_wall(DEMON_FACE, DEMON_FACE + WALL_THICKNESS, WALL_TOP)
	demon_side.collision_layer = _demon_layers
	_make_tile_wall(TILE_FACE, WALL_TOP)
	make_platform(FAR_TILE_FACE - FAR_FLOOR_REACH, FAR_TILE_FACE + TILE_SIZE)
	_make_tile_wall(FAR_TILE_FACE, WALL_TOP)
	make_platform(-FAR_TILE_FACE - TILE_SIZE, -FAR_TILE_FACE + FAR_FLOOR_REACH)
	_make_tile_wall(-FAR_TILE_FACE - TILE_SIZE, WALL_TOP)
	make_platform(OVERHANG_FACE - FAR_FLOOR_REACH, OVERHANG_FACE + TILE_SIZE)
	_make_tile_wall(OVERHANG_FACE, WALL_TOP, OVERHANG_BOTTOM)
	make_platform(GAPPED_FACE - FAR_FLOOR_REACH, GAPPED_FACE + TILE_SIZE)
	_make_tile_wall(GAPPED_FACE, WALL_TOP, GAP_TOP)
	_make_tile_wall(GAPPED_FACE, GAP_TOP + GAP_HEIGHT)
	await physics_frame
	var results: Array[bool] = []
	results.append(await _pushing_into_the_wall_slides_at_wall_slide_speed())
	results.append(await _letting_go_on_the_wall_keeps_sliding())
	results.append(await _letting_go_in_a_jump_along_the_wall_slides_after_the_peak())
	results.append(await _below_wall_slide_speed_the_fall_speeds_up_as_without_a_wall())
	results.append(await _pushing_away_from_the_wall_falls_as_without_it())
	results.append(await _touching_the_wall_without_pushing_slides())
	results.append(await _carried_into_the_wall_without_pushing_slides())
	results.append(await _pushing_away_while_touching_the_wall_never_brakes())
	results.append(await _jumping_along_the_wall_peaks_at_jump_height())
	results.append(await _running_away_from_the_wall_on_the_floor_steps_as_on_the_floor())
	results.append(await _touching_a_demon_without_pushing_falls_as_without_it())
	results.append(await _pushing_into_a_demon_slides())
	results.append(await _touching_a_wall_of_tiles_without_pushing_slides())
	results.append(await _carried_into_a_far_wall_of_tiles_without_pushing_slides(1.0))
	results.append(await _carried_into_a_far_wall_of_tiles_without_pushing_slides(-1.0))
	results.append(await _jumping_from_rest_by_a_far_wall_slides_after_the_peak())
	results.append(await _off_the_bottom_of_a_wall_falls_straight_down())
	results.append(await _past_a_gap_in_a_far_wall_slides_on_to_the_floor())
	results.append(await _falling_in_line_past_a_wall_s_top_never_lands_on_its_corner())
	results.append(await _a_demon_s_side_backing_away_is_never_followed())
	results.append(await _a_demon_s_side_freed_while_touched_leaves_no_wall())
	finish(results)


## The slide itself, with the brake all at once: from the frame after the player reaches the wall
## it pushed into, it falls no faster than Wall Slide Speed, and it slides at that speed.
func _pushing_into_the_wall_slides_at_wall_slide_speed() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_left")
	var touched: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"move_left")
	return await _report_slide(player, touched, fall, "Falling while pushing into the wall")


## Staying on the wall needs no holding: after letting go of the direction, the player keeps
## sliding, because letting go does not take it off the wall.
func _letting_go_on_the_wall_keeps_sliding() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_left")
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_left")
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_slide(player, touched, fall, "Letting go of the direction on the wall")


## The wall also works on the way up: jumping along the wall while pushing into it puts the player
## on the wall, so after letting go of the direction in the air it still slides after the peak.
func _letting_go_in_a_jump_along_the_wall_slides_after_the_peak() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Letting go in a jump along the wall: never stood against the wall")
	Input.action_press(&"jump")
	var rose: bool = await _wait_until_rising(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_left")
	await _wait_until_falling(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"jump")
	return await _report_slide(player, rose, fall,
			"Letting go of the direction in a jump along the wall, after the peak")


## The brake is a cap, not a set speed: after the peak of a jump along the wall, slower than Wall
## Slide Speed, the fall speeds up by one frame of Fall Gravity at a time, as without a wall, until
## it reaches Wall Slide Speed.
func _below_wall_slide_speed_the_fall_speeds_up_as_without_a_wall() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Falling after the peak along the wall: never stood against the wall")
	Input.action_press(&"jump")
	var rose: bool = await _wait_until_rising(player)
	await _wait_until_falling(player)
	var slide_speed: float = player.stats.wall_slide_speed
	var step: float = player.stats.fall_gravity / Engine.physics_ticks_per_second
	var speeds: Array[float] = [player.velocity.y]
	while speeds[-1] < slide_speed - SPEED_TOLERANCE and speeds.size() < MAX_FRAMES:
		await physics_frame
		speeds.append(player.velocity.y)
	Input.action_release(&"jump")
	Input.action_release(&"move_left")
	var passed: bool = rose and speeds[0] < slide_speed - SPEED_TOLERANCE
	var texts: PackedStringArray = []
	for i: int in speeds.size():
		texts.append("%.1f" % speeds[i])
		if i > 0:
			var expected: float = minf(speeds[i - 1] + step, slide_speed)
			passed = passed and absf(speeds[i] - expected) <= SPEED_TOLERANCE
	await _remove(player)
	return report(passed,
			"After the peak along the wall: falls %s px/s, Fall Gravity per frame %.1f px/s%s"
			% [", ".join(texts), step, _got_going_note(rose)])


## Pushing away takes the player off the wall, and it falls as without a wall again, up to the top
## falling speed.
func _pushing_away_from_the_wall_falls_as_without_it() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_left")
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_left")
	Input.action_press(&"move_right")
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"move_right")
	return await _report_fall_as_without_a_wall(player, touched, fall, "Pushing away from the wall")


## Getting on the wall needs no push into it: touching a wall without ever pushing into it slides,
## as pushing into it does.
func _touching_the_wall_without_pushing_slides() -> bool:
	var player: Player = _spawn_near_the_wall(0.0, START_HEIGHT)
	var touching: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_slide(player, touching, fall, "Touching the wall without pushing into it")


## The way most players met the wall: carried into it by the speed of a jump, with no direction
## held, the player slides once he reaches it.
func _carried_into_the_wall_without_pushing_slides() -> bool:
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	player.velocity = Vector2(-player.stats.max_run_speed, 0.0)
	var touching: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_slide(player, touching, fall,
			"Carried into the wall with no direction held")


## Pushing away keeps the player off the wall even while it touches it: carried into the wall by its
## run while pushing away from it, at the top falling speed, it keeps that speed, with no brake on
## any frame.
func _pushing_away_while_touching_the_wall_never_brakes() -> bool:
	var what: String = "Pushing away while carried into the wall"
	var player: Player = _spawn_near_the_wall(GAP, START_HEIGHT)
	Input.action_press(&"move_right")
	player.velocity = Vector2(-player.stats.max_run_speed, player.stats.max_fall_speed)
	var touching: bool = await _wait_until_on_wall(player)
	var slowest: float = await _slowest_fall_until_the_floor(player)
	Input.action_release(&"move_right")
	var top_speed: float = player.stats.max_fall_speed
	await _remove(player)
	return report(touching and absf(slowest - top_speed) <= SPEED_TOLERANCE,
			"%s: slowest fall %.1f px/s, Max Fall Speed %.1f px/s%s"
			% [what, slowest, top_speed, _got_going_note(touching)])


## The brake only acts on the way down: a full jump along the wall, pushing into it all the way,
## still peaks at Jump Height. As the jump starts on the floor against the wall, it also checks
## that the floor still jumps there.
func _jumping_along_the_wall_peaks_at_jump_height() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Full jump along the wall: never stood against the wall")
	var floor_y: float = player.position.y
	Input.action_press(&"jump")
	var peak: float = await _peak_height(player, floor_y)
	Input.action_release(&"jump")
	Input.action_release(&"move_left")
	var expected: float = player.stats.jump_height
	await _remove(player)
	return report(absf(peak - expected) <= HEIGHT_TOLERANCE,
			"Full jump along the wall: peak %.1f px, Jump Height %.1f px, tolerance %.1f px"
			% [peak, expected, HEIGHT_TOLERANCE])


## The floor comes before the wall: on the floor against the wall, the first step of a run away
## from it is the floor's, which is larger than the air's.
func _running_away_from_the_wall_on_the_floor_steps_as_on_the_floor() -> bool:
	var player: Player = await _spawn_against_the_wall_on_the_floor()
	if player == null:
		return report(false, "Running away from the wall on the floor: never stood against it")
	Input.action_release(&"move_left")
	Input.action_press(&"move_right")
	var first_step: float = 0.0
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.velocity.x > 0.0:
			first_step = player.velocity.x
			break
	Input.action_release(&"move_right")
	var floor_step: float = (player.stats.max_run_speed / player.stats.time_to_max_speed
			/ Engine.physics_ticks_per_second)
	var on_floor: bool = player.is_on_floor()
	await _remove(player)
	return report(on_floor and is_equal_approx(first_step, floor_step),
			"Running away from the wall on the floor: first step %.1f px/s, floor step %.1f px/s"
			% [first_step, floor_step])


## A demon's side still takes a push into it: touching a body on Knock Off Layers without pushing
## into it falls as without a wall, up to the top falling speed.
func _touching_a_demon_without_pushing_falls_as_without_it() -> bool:
	var player: Player = _spawn_near_the_demon(0.0, START_HEIGHT)
	var touching: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_fall_as_without_a_wall(player, touching, fall,
			"Touching a demon's side without pushing into it")


## Pushing into a demon's side still slides, as into any wall.
func _pushing_into_a_demon_slides() -> bool:
	var player: Player = _spawn_near_the_demon(GAP, START_HEIGHT)
	Input.action_press(&"move_right")
	var touched: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"move_right")
	return await _report_slide(player, touched, fall, "Falling while pushing into a demon's side")


## The levels' walls are tiles, not bodies: touching a wall of tiles without pushing into it slides,
## as touching a wall that is a body does.
func _touching_a_wall_of_tiles_without_pushing_slides() -> bool:
	var player: Player = spawn_player(Vector2(TILE_FACE - _half_width, START_HEIGHT))
	var touching: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_slide(player, touching, fall,
			"Touching a wall of tiles without pushing into it")


## The way most players meet a wall of the levels: carried into it by a jump's speed, with no
## direction held, far from the origin, as most of a level's walls are, on the right (side 1) or
## on the left (-1). The move that reaches it leaves him a hair off its face; he slides all the way
## down to the floor, as near the origin.
func _carried_into_a_far_wall_of_tiles_without_pushing_slides(side: float) -> bool:
	var face: float = side * FAR_TILE_FACE
	var player: Player = spawn_player(Vector2(face - side * (_half_width + GAP), START_HEIGHT))
	player.velocity = Vector2(side * player.stats.max_run_speed, 0.0)
	var touching: bool = await _wait_until_on_wall(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	return await _report_slide(player, touching, fall,
			"Carried into a far wall of tiles on the %s with no direction held"
			% ("right" if side > 0.0 else "left"))


## Getting on a far wall needs no push either: standing against it, having let go of the direction,
## a straight jump with no direction held puts him on the wall, so he slides after the peak.
func _jumping_from_rest_by_a_far_wall_slides_after_the_peak() -> bool:
	var what: String = "Jumping straight up from rest by a far wall"
	var player: Player = await spawn_on_floor(
			Vector2(FAR_TILE_FACE - _half_width - GAP, FLOOR_SPAWN_HEIGHT))
	if player == null:
		return report(false, "%s: never landed" % what)
	Input.action_press(&"move_right")
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_right")
	await _wait_frames(STOP_FRAMES)
	Input.action_press(&"jump")
	var rose: bool = await _wait_until_rising(player)
	await _wait_until_falling(player)
	var fall: FallResult = await _fall_until_the_floor(player)
	Input.action_release(&"jump")
	return await _report_slide(player, touched and rose, fall, what)


## Staying on a wall with no direction held only presses into a wall that is still there: sliding
## off the bottom of a wall that ends in the air, he falls straight down, never drifting under it.
func _off_the_bottom_of_a_wall_falls_straight_down() -> bool:
	var player: Player = spawn_player(Vector2(OVERHANG_FACE - _half_width - GAP, START_HEIGHT))
	player.velocity = Vector2(player.stats.max_run_speed, 0.0)
	var touching: bool = await _wait_until_on_wall(player)
	var x_on_the_wall: float = player.position.x
	await _fall_until_the_floor(player)
	var drift: float = player.position.x - x_on_the_wall
	var landed: bool = player.is_on_floor()
	await _remove(player)
	return report(touching and landed and absf(drift) <= DRIFT_TOLERANCE,
			"Off the bottom of a wall with no direction held: %.2f px across, tolerance %.2f px%s"
			% [drift, DRIFT_TOLERANCE, _got_going_note(touching and landed)])


## Coming down along a wall never leaves him on a corner: sliding down a far wall with a gap in it,
## with no direction held, he falls past the gap, gets on the wall below it and slides on to the
## floor. The ledge assist never lifts him onto the top corner of the wall below the gap, as he comes
## down to it from above, not up to it (ADR 0059).
func _past_a_gap_in_a_far_wall_slides_on_to_the_floor() -> bool:
	var player: Player = spawn_player(Vector2(GAPPED_FACE - _half_width - GAP, START_HEIGHT))
	player.velocity = Vector2(player.stats.max_run_speed, 0.0)
	var touching: bool = await _wait_until_on_wall(player)
	await _fall_until_the_floor(player)
	var end_y: float = player.position.y
	await _remove(player)
	return report(touching and absf(end_y) <= HEIGHT_TOLERANCE,
			("Past a gap in a far wall: landed at y %.1f, the floor's top at 0.0, the top of the "
			+ "wall below the gap at %.1f%s")
			% [end_y, GAP_TOP + GAP_HEIGHT, _got_going_note(touching)])


## Pressing him against a wall needs the wall beside him for the whole frame: falling in a gap, in
## line with the face below it and just over its top, with no direction held, he never lands on
## that top's corner, as he would if a press made on the way past its top carried him onto it.
func _falling_in_line_past_a_wall_s_top_never_lands_on_its_corner() -> bool:
	var top: float = GAP_TOP + GAP_HEIGHT
	var player: Player = spawn_player(
			Vector2(GAPPED_FACE - _half_width - IN_LINE_GAP, top - OVER_THE_TOP))
	player.velocity = Vector2(0.0, player.stats.max_fall_speed)
	await _fall_until_the_floor(player)
	var end_y: float = player.position.y
	await _remove(player)
	return report(absf(end_y) <= HEIGHT_TOLERANCE,
			("Falling in line past the top of a far wall, %.1f px over it: landed at y %.1f, the "
			+ "floor's top at 0.0, the wall's top at %.1f") % [OVER_THE_TOP, end_y, top])


## What keeps him on a wall with no direction held only holds him to the level's walls: pushed into a
## demon's side and let go, while it backs away slowly he never follows it across.
func _a_demon_s_side_backing_away_is_never_followed() -> bool:
	var what: String = "Let go against a demon's side that backs away"
	var side: StaticBody2D = make_wall(BACKING_FACE, BACKING_FACE + WALL_THICKNESS, WALL_TOP)
	side.collision_layer = _demon_layers
	var player: Player = spawn_player(Vector2(BACKING_FACE - _half_width - GAP, START_HEIGHT))
	Input.action_press(&"move_right")
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(&"move_right")
	await _wait_frames(STOP_FRAMES)
	var x_let_go: float = player.position.x
	for _frame: int in BACKING_FRAMES:
		side.position.x += BACKING_SPEED / Engine.physics_ticks_per_second
		await physics_frame
	var across: float = player.position.x - x_let_go
	side.queue_free()
	await _remove(player)
	return report(touched and absf(across) <= DRIFT_TOLERANCE,
			"%s at %.1f px/s: followed it %.2f px, tolerance %.2f px%s"
			% [what, BACKING_SPEED, across, DRIFT_TOLERANCE, _got_going_note(touched)])


## A demon's side that is freed while the player touches it leaves no wall behind: falling at the
## top falling speed against it with no push, on the frame after it goes he keeps that speed, with
## no brake from a wall that is no longer there.
func _a_demon_s_side_freed_while_touched_leaves_no_wall() -> bool:
	var side: StaticBody2D = make_wall(GONE_FACE, GONE_FACE + WALL_THICKNESS, WALL_TOP)
	side.collision_layer = _demon_layers
	var player: Player = spawn_player(Vector2(GONE_FACE - _half_width, START_HEIGHT))
	var top_speed: float = player.stats.max_fall_speed
	player.velocity = Vector2(0.0, top_speed)
	var touching: bool = await _wait_until_on_wall(player)
	side.queue_free()
	# physics_frame comes before the player's own physics on that frame: the side goes at the end of
	# this one, the next one is the first to run without it, and the one after reads what it did.
	await _wait_frames(2)
	var speed: float = player.velocity.y
	await _remove(player)
	return report(touching and absf(speed - top_speed) <= SPEED_TOLERANCE,
			("Falling against a demon's side freed while touched: the next frame %.1f px/s, "
			+ "Max Fall Speed %.1f px/s%s") % [speed, top_speed, _got_going_note(touching)])


## A wall of the levels' solid tiles, one tile thick, with its left face at x = face, from bottom up
## to top or a little over it. Bottom is the floor's top unless given, and a whole number of tiles.
func _make_tile_wall(face: float, top: float, bottom: float = 0.0) -> void:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = TILE_SET
	tiles.position = Vector2(face, 0.0)
	for row: int in range(floori(top / TILE_SIZE), floori(bottom / TILE_SIZE)):
		tiles.set_cell(Vector2i(0, row), SOLID_SOURCE, SOLID_ATLAS)
	root.add_child(tiles)


## The x at which the side of the player's body is gap px from the wall.
func _x_near_the_wall(gap: float) -> float:
	return WALL_FACE + _half_width + gap


func _spawn_near_the_wall(gap: float, height: float) -> Player:
	return spawn_player(Vector2(_x_near_the_wall(gap), height))


## A player gap px to the left of the demon's side, at the given height.
func _spawn_near_the_demon(gap: float, height: float) -> Player:
	return spawn_player(Vector2(DEMON_FACE - _half_width - gap, height))


## A player on the floor that walked from GAP px away into the wall and is still pushing into it,
## with move_left held. Null, with nothing held, if it never lands or never reaches the wall.
func _spawn_against_the_wall_on_the_floor() -> Player:
	var player: Player = await spawn_on_floor(Vector2(_x_near_the_wall(GAP), FLOOR_SPAWN_HEIGHT))
	if player == null:
		return null
	Input.action_press(&"move_left")
	if not await _wait_until_on_wall(player):
		Input.action_release(&"move_left")
		await _remove(player)
		return null
	await _wait_frames(SETTLE_FRAMES)
	return player


func _wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


## True once the player is off the floor and going up, which only a jump does here.
func _wait_until_rising(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor() and player.velocity.y < 0.0:
			return true
	return false


## Waits for the peak: the first frame on which the player no longer goes up.
func _wait_until_falling(player: Player) -> void:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.velocity.y >= 0.0:
			return


func _wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


## Follows the player down until it lands, for the fastest falling speed and the last one.
func _fall_until_the_floor(player: Player) -> FallResult:
	var fall: FallResult = FallResult.new()
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			break
		fall.fastest = maxf(fall.fastest, player.velocity.y)
		fall.last = player.velocity.y
	return fall


## Follows the player down until it lands, for the slowest falling speed on the way; INF if it lands
## at once.
func _slowest_fall_until_the_floor(player: Player) -> float:
	var slowest: float = INF
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			break
		slowest = minf(slowest, player.velocity.y)
	return slowest


## How high the feet go above floor_y before the player lands again, in px; 0 if it never leaves
## the floor.
func _peak_height(player: Player, floor_y: float) -> float:
	var highest_y: float = floor_y
	var left_floor: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			if left_floor:
				break
			continue
		left_floor = true
		highest_y = minf(highest_y, player.position.y)
	return floor_y - highest_y


## PASS if the case got going and the player never fell faster than Wall Slide Speed, ending at it.
func _report_slide(player: Player, got_going: bool, fall: FallResult, what: String) -> bool:
	var slide_speed: float = player.stats.wall_slide_speed
	var passed: bool = (got_going and fall.fastest <= slide_speed + SPEED_TOLERANCE
			and absf(fall.last - slide_speed) <= SPEED_TOLERANCE)
	await _remove(player)
	return report(passed, "%s: fastest fall %.1f px/s, last %.1f px/s, Wall Slide Speed %.1f px/s%s"
			% [what, fall.fastest, fall.last, slide_speed, _got_going_note(got_going)])


## PASS if the case got going and the player fell up to the top falling speed, as without a wall.
func _report_fall_as_without_a_wall(player: Player, got_going: bool, fall: FallResult,
		what: String) -> bool:
	var top_speed: float = player.stats.max_fall_speed
	var passed: bool = got_going and absf(fall.fastest - top_speed) <= SPEED_TOLERANCE
	await _remove(player)
	return report(passed, "%s: fastest fall %.1f px/s, Max Fall Speed %.1f px/s%s"
			% [what, fall.fastest, top_speed, _got_going_note(got_going)])


func _got_going_note(got_going: bool) -> String:
	return "" if got_going else " (the case never got going)"


func _remove(player: Player) -> void:
	player.queue_free()
	await physics_frame


## What _fall_until_the_floor follows, in px/s: the fastest falling speed until the landing, and the
## falling speed on the last frame before it.
class FallResult:
	var fastest: float = 0.0
	var last: float = 0.0
