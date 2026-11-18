# Checks the man's death in brambles (#263): walking into a floor hedge, he dies, the game freezes
# for the hitstop while his drawing flashes, then lets it go; after it he buckles and slumps the way
# he faces, held to the frame of the effects, with his feet where they were and no sinking, since
# they were on the floor already, and a sink from elsewhere gives way to the pose; falling into one,
# he settles down to the floor it grows from; the freeze ends on time with the game paused, and if he
# leaves the tree while frozen; on a wall hedge he stays where it caught him, in the air, and leans
# into it by Wall Tilt, without sinking; a death by something else neither freezes nor poses him;
# and the brambles are drawn in front of him.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_death.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const BrambleDeathPose := preload("res://scenes/characters/player/bramble_death_pose.gd")
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## A floor strip at the origin, three tiles wide; he starts left of it and runs at it.
const FLOOR_STRIP_TILES: int = 3
const START := Vector2(-300.0, -2.0)
## A wall to the right, with a strip of three tiles on its left face, which faces left.
const WALL_LEFT: float = 600.0
const WALL_RIGHT: float = 700.0
const WALL_TOP: float = -800.0
const WALL_STRIP_AT := Vector2(WALL_LEFT, -300.0)
## Where he is put in the air against the wall strip, his body over the part that kills.
const BY_THE_WALL := Vector2(WALL_LEFT - 34.0, -240.0)
## Over the middle of the floor strip, to fall into it.
const OVER_THE_FLOOR_STRIP := Vector2(0.0, -150.0)
## Somewhere far from both strips, for deaths not on them.
const ELSEWHERE := Vector2(-1200.0, -2.0)
const RUN_FRAMES: int = 120
## Frames at 60 fps: past the hitstop and the whole pose.
const POSE_FRAMES: int = 60
## How far apart two values may be and still count as the same.
const SAME: float = 0.01
const DEGREE: float = PI / 180.0


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	make_wall(WALL_LEFT, WALL_RIGHT, WALL_TOP)
	var floor_strip: LethalSpikes = _strip(Vector2.ZERO, 0.0)
	var wall_strip: LethalSpikes = _strip(WALL_STRIP_AT, -PI / 2.0)
	await physics_frame
	var results: Array[bool] = []
	results.append(_brambles_draw_in_front_of_him())
	results.append(await _a_death_on_a_floor_hedge_freezes_flashes_and_poses_him())
	results.append(await _falling_into_a_floor_hedge_he_settles_to_its_floor())
	results.append(await _the_freeze_ends_with_the_game_paused())
	results.append(await _leaving_the_tree_while_frozen_brings_time_back())
	results.append(await _on_a_wall_hedge_he_stays_where_it_caught_him_and_leans_into_it())
	results.append(await _a_death_by_something_else_neither_freezes_nor_poses())
	results.append(await _the_freeze_slows_time_but_never_stops_it())
	results.append(await _a_man_already_dead_is_not_caught_by_brambles())
	results.append(await _a_catch_out_of_the_tree_does_nothing())
	floor_strip.free()
	wall_strip.free()
	# A footstep of the last man still playing when the run quits is reported as a leak.
	await wait_frames(30)
	finish(results)


func _brambles_draw_in_front_of_him() -> bool:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var sprite: CanvasItem = player.get_node(^"Sprite") as CanvasItem
	var brambles_z: int = spikes.z_index
	var his_z: int = player.z_index + sprite.z_index
	spikes.free()
	player.free()
	return report(brambles_z > his_z, "Brambles drawn at z %d, his drawing at z %d" % [brambles_z, his_z])


func _a_death_on_a_floor_hedge_freezes_flashes_and_poses_him() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Floor hedge: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	var stats: Resource = _posed(player)
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	var feet: Vector2 = drawing.position
	var rest_rotation: float = drawing.rotation
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	for frame: int in RUN_FRAMES:
		await process_frame
		if player.is_dead():
			break
	stand_in.run_direction = 0.0
	var died: bool = player.is_dead()
	var frozen_at_death: bool = death.is_frozen() and Engine.time_scale == stats.hitstop_time_scale
	var flash_at_death: float = _flash(drawing)
	var frozen_frames: int = 0
	while death.is_frozen() and frozen_frames < RUN_FRAMES:
		await process_frame
		frozen_frames += 1
	var flash_after: float = _flash(drawing)
	var facing: float = player.get_facing()
	var rotations: Array[float] = []
	for frame: int in POSE_FRAMES:
		await process_frame
		rotations.append(drawing.rotation)
	var changed_on_back_to_back_frames: int = 0
	for k: int in range(2, rotations.size()):
		if absf(rotations[k] - rotations[k - 1]) > SAME * DEGREE and absf(rotations[k - 1] - rotations[k - 2]) > SAME * DEGREE:
			changed_on_back_to_back_frames += 1
	var tilt: float = (drawing.rotation - rest_rotation) / DEGREE
	var sunk: float = _sunk_px(drawing)
	var feet_moved: float = drawing.position.distance_to(feet)
	# A sink from elsewhere, as a grab's, gives way to the pose on the next frames.
	(player.get_node(^"SinkingDrawing") as SinkingDrawing).set_sink(1.0)
	await wait_frames(4)
	var sunk_after_other: float = _sunk_px(drawing)
	var expected_frames: int = roundi(stats.hitstop * 60.0)
	await remove_player(player)
	return report(died and frozen_at_death and absf(frozen_frames - expected_frames) <= 1
			and flash_at_death == 1.0 and flash_after == 0.0
			and absf(tilt - stats.slump_tilt * facing) < SAME and sunk < 0.5
			and changed_on_back_to_back_frames == 0 and feet_moved < SAME and sunk_after_other < 0.5,
			"Died %s; frozen at death %s, for %d frames (%d expected); flash %.1f, then %.1f; facing %+.0f, tilt %.1f deg (%.1f expected), sunk %.1f px (none, his feet on the floor), changes on back-to-back frames %d, feet moved %.2f px; after a sink from elsewhere %.1f px"
			% [died, frozen_at_death, frozen_frames, expected_frames, flash_at_death, flash_after, facing,
			tilt, stats.slump_tilt * facing, sunk, changed_on_back_to_back_frames, feet_moved,
			sunk_after_other])


func _falling_into_a_floor_hedge_he_settles_to_its_floor() -> bool:
	var player: Player = spawn_player(OVER_THE_FLOOR_STRIP)
	var stats: BrambleDeathPose.BrambleDeathStats = _posed(player)
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	for frame: int in RUN_FRAMES:
		await process_frame
		if player.is_dead():
			break
	var died: bool = player.is_dead()
	var caught_height: float = -player.global_position.y
	await wait_frames(POSE_FRAMES)
	var sunk: float = _sunk_px(drawing)
	var feet_above_floor: float = caught_height - sunk
	await remove_player(player)
	# Caught higher than the part that kills is tall never happens in play: the pose's own rule.
	var pose: BrambleDeathPose = BrambleDeathPose.new(stats)
	var settled: float = pose.sink(1.0, 12.0)
	var capped: float = pose.sink(1.0, 60.0)
	var none_below: float = pose.sink(1.0, -5.0)
	return report(died and caught_height >= 0.0 and absf(feet_above_floor) < 0.5 and absf(settled - 12.0) < SAME
			and absf(capped - stats.sink_px) < SAME and none_below == 0.0,
			"Died %s; caught with his feet %.1f px up, sunk %.1f px, feet %.1f px above the floor; caught 12 px up he sinks %.1f, 60 px up %.1f (at most %.0f), under it %.1f"
			% [died, caught_height, sunk, feet_above_floor, settled, capped, stats.sink_px, none_below])


func _the_freeze_ends_with_the_game_paused() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Paused: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	player.die(LethalSpikes.CAUSE)
	death.catch(Vector2.UP)
	var frozen: bool = death.is_frozen()
	paused = true
	await wait_frames(roundi(death.stats.hitstop * 60.0) + 4)
	var back: float = Engine.time_scale
	paused = false
	await remove_player(player)
	return report(frozen and back == 1.0, "Frozen %s; with the game paused, time back to %.1f" % [frozen, back])


func _leaving_the_tree_while_frozen_brings_time_back() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Freed: the player never landed")
	player.die(LethalSpikes.CAUSE)
	player.get_node(^"BrambleDeath").catch(Vector2.UP)
	var frozen: bool = Engine.time_scale < 1.0
	player.queue_free()
	await process_frame
	await process_frame
	var back: float = Engine.time_scale
	Engine.time_scale = 1.0
	return report(frozen and back == 1.0, "Frozen %s; freed while frozen, time back to %.1f" % [frozen, back])


func _on_a_wall_hedge_he_stays_where_it_caught_him_and_leans_into_it() -> bool:
	var player: Player = spawn_player(BY_THE_WALL)
	_posed(player)
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	var rest_rotation: float = drawing.rotation
	for frame: int in 10:
		await process_frame
		if player.is_dead():
			break
	var died: bool = player.is_dead()
	var caught_at: Vector2 = player.global_position
	var wall_tilt: float = player.get_node(^"BrambleDeath").stats.wall_tilt
	await wait_frames(POSE_FRAMES + 10)
	var moved: float = player.global_position.distance_to(caught_at)
	var tilt: float = (drawing.rotation - rest_rotation) / DEGREE
	var sunk: float = _sunk_px(drawing)
	var cause: StringName = player.get_death_cause()
	await remove_player(player)
	return report(died and cause == LethalSpikes.CAUSE and moved < 0.5 and absf(tilt - wall_tilt) < SAME
			and sunk < SAME,
			"Died %s of %s; moved %.1f px after; tilt %.1f deg (%.1f expected, towards the wall is +); sunk %.1f px"
			% [died, cause, moved, tilt, wall_tilt, sunk])


func _a_death_by_something_else_neither_freezes_nor_poses() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Other death: the player never landed")
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	var rest_rotation: float = drawing.rotation
	var rest_scale: Vector2 = drawing.scale
	player.die(&"dog")
	var frozen: bool = Engine.time_scale != 1.0
	await wait_frames(POSE_FRAMES)
	var posed: bool = absf(drawing.rotation - rest_rotation) > SAME * DEGREE or drawing.scale != rest_scale
	var flash: float = _flash(drawing)
	await remove_player(player)
	return report(not frozen and not posed and flash == 0.0,
			"A death by a dog: frozen %s, posed %s, flash %.1f" % [frozen, posed, flash])


## During the freeze, time runs slowly but never stops: a stopped clock gives every _process and
## _physics_process a delta of 0, and some divide by it, as the camera's follow speed and the dogs'.
func _the_freeze_slows_time_but_never_stops_it() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Slow time: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	player.die(LethalSpikes.CAUSE)
	death.catch(Vector2.UP)
	var scale: float = Engine.time_scale
	var smallest_physics: float = INF
	var smallest_process: float = INF
	for frame: int in roundi(death.stats.hitstop * 60.0) - 1:
		await physics_frame
		smallest_physics = minf(smallest_physics, root.get_physics_process_delta_time())
		await process_frame
		smallest_process = minf(smallest_process, root.get_process_delta_time())
	await remove_player(player)
	return report(scale > 0.0 and scale < 1.0 and smallest_physics > 0.0 and smallest_process > 0.0,
			"Slow time: scale %.3f in the freeze; the smallest delta, physics %.6f s, process %.6f s"
			% [scale, smallest_physics, smallest_process])


## A man something else killed, who then falls into brambles, is not caught by them: no second
## freeze, no flash, no pull, as when a dog's grab runs out over a hedge.
func _a_man_already_dead_is_not_caught_by_brambles() -> bool:
	var player: Player = spawn_player(OVER_THE_FLOOR_STRIP)
	var death: Node = player.get_node(^"BrambleDeath")
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	await physics_frame
	player.die(&"dog")
	var fell_in: bool = false
	for frame: int in RUN_FRAMES:
		await physics_frame
		if player.global_position.y > -1.0:
			fell_in = true
			break
	await wait_frames(4)
	var caught: bool = death.is_caught()
	var scale: float = Engine.time_scale
	var flash: float = _flash(drawing)
	var cause: StringName = player.get_death_cause()
	await remove_player(player)
	return report(fell_in and not caught and scale == 1.0 and flash == 0.0 and cause == &"dog",
			"Already dead: fell into the hedge %s; caught %s, time scale %.2f, flash %.1f, cause %s"
			% [fell_in, caught, scale, flash, cause])


## Out of the tree, as when a level with no wait starts over in the frame he dies, catch() does
## nothing: no freeze with no timer left to end it.
func _a_catch_out_of_the_tree_does_nothing() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Out of the tree: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	root.remove_child(player)
	death.catch(Vector2.UP)
	var caught: bool = death.is_caught()
	var scale: float = Engine.time_scale
	Engine.time_scale = 1.0
	player.free()
	return report(not caught and scale == 1.0,
			"Out of the tree: caught %s, time scale %.2f" % [caught, scale])


## Turns Cut Apart and Pulled In off for Player's death, on a copy of his stats, so the game's are
## not touched: he buckles and slumps, the pose these cases check. Hands the copy back.
func _posed(player: Player) -> BrambleDeathPose.BrambleDeathStats:
	var death: Node = player.get_node(^"BrambleDeath")
	var copy: BrambleDeathPose.BrambleDeathStats = death.stats.duplicate()
	copy.cut_apart = false
	copy.pulled_in = false
	death.stats = copy
	return copy


## A strip of Floor Strip Tiles at At, turned by Turn.
func _strip(at: Vector2, turn: float) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.width_tiles = FLOOR_STRIP_TILES
	spikes.position = at
	spikes.rotation = turn
	root.add_child(spikes)
	return spikes


func _flash(drawing: CanvasItem) -> float:
	var shader_material: ShaderMaterial = drawing.material as ShaderMaterial
	var value: Variant = shader_material.get_shader_parameter(&"flash") if shader_material != null else null
	return float(value) if value != null else 0.0


## How far the drawing is sunk, in the world's px.
func _sunk_px(drawing: CanvasItem) -> float:
	var shader_material: ShaderMaterial = drawing.material as ShaderMaterial
	var value: Variant = shader_material.get_shader_parameter(&"sink_depth") if shader_material != null else null
	return float(value) * absf(drawing.get_global_transform().get_scale().y) if value != null else 0.0
