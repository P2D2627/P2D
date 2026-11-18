# Checks how brambles pull the man in as they kill him (#263). The rule: the pull goes from Grab
# Time to Pull End, speeding up as it goes; with Jerk Px he jerks only while pulled, held to the
# frames of the effects; vines, when there are any, grow by Grab Time (at once at 0), root on a
# floor hedge's base line, out from under the side they climb, one side then the other, from his
# legs up, and cross him, and by a wall root on the wall's line and climb the side nearer it; a line
# cut to a share and cut where it goes past the base line keeps the right part. In play, as the game
# has it (no vines): by the end of the pull he has gone under all the way and has not moved; with
# vines, they show from the freeze on, each from the hedge, never past its base; by a wall he is
# pulled into the hedge, not under, and the vines root on it; a death by something else pulls
# nothing. The values are in his BrambleDeath's Stats.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_pull.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const BramblePull := preload("res://scenes/characters/player/bramble_pull.gd")
const BrambleDeathStats := preload("res://scenes/characters/player/bramble_death_stats.gd")
## The game's values, which the man takes: the cases with vines turn them on, and back off.
const GAME_STATS: BrambleDeathStats = preload("res://scenes/characters/player/bramble_death_stats.tres")
## Vines for the cases that check them.
const VINES: int = 3
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const FLOOR_STRIP_TILES: int = 3
const FROM_THE_LEFT := Vector2(-300.0, -2.0)
const WALL_LEFT: float = 600.0
const WALL_RIGHT: float = 700.0
const WALL_TOP: float = -800.0
const WALL_STRIP_AT := Vector2(WALL_LEFT, -300.0)
## In the air against the wall strip, as test_bramble_death puts him.
const BY_THE_WALL := Vector2(WALL_LEFT - 34.0, -240.0)
const ELSEWHERE := Vector2(-1200.0, -2.0)
const RUN_FRAMES: int = 120
## His body's box, as the rule's cases put it: feet on y = 0.
const BODY := Rect2(-24.0, -96.0, 48.0, 96.0)
const NEAR: float = 0.5


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	make_wall(WALL_LEFT, WALL_RIGHT, WALL_TOP)
	var floor_strip: LethalSpikes = _strip(Vector2.ZERO, 0.0)
	var wall_strip: LethalSpikes = _strip(WALL_STRIP_AT, -PI / 2.0)
	await physics_frame
	var results: Array[bool] = []
	results.append(_on_a_floor_the_vines_climb_each_side_from_his_legs_up())
	results.append(_by_a_wall_the_vines_root_on_it_and_climb_its_side())
	results.append(_the_pull_speeds_up_and_he_jerks_only_meanwhile())
	results.append(_the_vines_grow_by_grab_time())
	results.append(_lines_are_cut_to_a_share_and_at_the_base())
	results.append(await _walking_into_a_floor_hedge_he_is_pulled_under())
	var game_stats: BrambleDeathStats = GAME_STATS
	game_stats.vines = VINES
	results.append(await _walking_into_a_floor_hedge_he_is_pulled_under())
	results.append(await _by_a_wall_he_is_pulled_into_the_hedge_not_under())
	game_stats.vines = 0
	game_stats.pull_clips = not game_stats.pull_clips
	results.append(await _walking_into_a_floor_hedge_he_is_pulled_under())
	game_stats.pull_clips = not game_stats.pull_clips
	results.append(await _a_death_by_something_else_pulls_nothing())
	floor_strip.free()
	wall_strip.free()
	# A footstep of the last man still playing when the run quits is reported as a leak.
	await wait_frames(30)
	finish(results)


func _on_a_floor_the_vines_climb_each_side_from_his_legs_up() -> bool:
	var stats: BrambleDeathStats = BrambleDeathStats.new()
	stats.vines = VINES
	var pull: BramblePull = BramblePull.new(stats)
	var vines: Array[BramblePull.Vine] = pull.vines(BODY, Vector2.ZERO, Vector2.UP, true, 3)
	var counted: bool = vines.size() == stats.vines
	var rooted: bool = true
	var outside: bool = true
	var crossing: bool = true
	var alternating: bool = true
	var rising: bool = true
	var in_band: bool = true
	var half_wrap: float = BODY.size.x * stats.wrap_share / 2.0
	for k: int in vines.size():
		var points: PackedVector2Array = vines[k].points
		var root: Vector2 = points[0]
		var near: Vector2 = points[BramblePull.ON_HIM]
		var far: Vector2 = points[BramblePull.ON_HIM + 1]
		rooted = rooted and absf(root.y) < 0.01
		outside = outside and absf(root.x) > half_wrap
		crossing = crossing and signf(near.x) == -signf(far.x) and absf(near.x) > 0.0
		var height: float = -near.y / BODY.size.y
		in_band = in_band and height >= stats.vine_first - 0.01 and height <= stats.vine_last + 0.01
		if k > 0:
			var before: Vector2 = vines[k - 1].points[BramblePull.ON_HIM]
			alternating = alternating and signf(near.x) != signf(before.x)
			rising = rising and near.y < before.y
	return report(counted and rooted and outside and crossing and alternating and rising and in_band,
			("Floor rule: %d vines %s, rooted on the base %s, out from under him %s, crossing him %s, "
			+ "each side in turn %s, from his legs up %s, within the band %s") % [vines.size(),
			counted, rooted, outside, crossing, alternating, rising, in_band])


func _by_a_wall_the_vines_root_on_it_and_climb_its_side() -> bool:
	var stats: BrambleDeathStats = BrambleDeathStats.new()
	stats.vines = VINES
	var pull: BramblePull = BramblePull.new(stats)
	var body := Rect2(WALL_LEFT - 60.0, -200.0, 48.0, 96.0)
	var vines: Array[BramblePull.Vine] = pull.vines(body, Vector2(WALL_LEFT, -150.0), Vector2.LEFT,
			false, 3)
	var rooted: bool = true
	var wall_side: bool = true
	for vine: BramblePull.Vine in vines:
		rooted = rooted and absf(vine.points[0].x - WALL_LEFT) < 0.01
		wall_side = wall_side and vine.points[BramblePull.ON_HIM].x > body.get_center().x
	return report(not vines.is_empty() and rooted and wall_side,
			"Wall rule: rooted on the wall's line %s, climbing the side nearer it %s" % [rooted,
			wall_side])


## Vines growing over 0.15 s: none at first, all the way by then, held; at Grab Time 0, at once.
func _the_vines_grow_by_grab_time() -> bool:
	var stats: BrambleDeathStats = BrambleDeathStats.new()
	var at_once: bool = BramblePull.new(stats).grown(0.0) == 1.0
	stats.grab_time = 0.15
	var pull: BramblePull = BramblePull.new(stats)
	var step: float = 1.0 / stats.frame_rate
	var grows: bool = (pull.grown(0.0) == 0.0 and pull.grown(stats.grab_time) == 1.0
			and pull.grown(step * 1.2) == pull.grown(step * 1.8))
	return report(at_once and grows, "Growth: at once at Grab Time 0 %s; over Grab Time, held %s"
			% [at_once, grows])


## The pull goes from nothing at Grab Time to all the way at Pull End, under half by the middle, so
## he still shows until the screen darkens, never back; with Jerk Px, he jerks only while pulled,
## within one, held to the frames of the effects.
func _the_pull_speeds_up_and_he_jerks_only_meanwhile() -> bool:
	var stats: BrambleDeathStats = BrambleDeathStats.new()
	stats.jerk_px = 2.0
	var pull: BramblePull = BramblePull.new(stats)
	var step: float = 1.0 / stats.frame_rate
	var grows: bool = true
	var middle: float = (stats.grab_time + stats.pull_end) / 2.0
	var pulls: bool = (pull.pulled(stats.grab_time) == 0.0 and pull.pulled(stats.pull_end) == 1.0
			and pull.pulled(middle) > 0.0 and pull.pulled(middle) < 0.5)
	var never_back: bool = true
	var last: float = 0.0
	for frame: int in roundi(stats.pull_end * 60.0) + 2:
		var share: float = pull.pulled(frame / 60.0)
		never_back = never_back and share >= last
		last = share
	var still_before: bool = pull.jerk(stats.grab_time - step, 7) == 0.0
	var still_after: bool = pull.jerk(stats.pull_end + step, 7) == 0.0
	var bounded: bool = true
	var moved: bool = false
	var frame_of_middle: float = (floorf(middle * stats.frame_rate) + 0.1) / stats.frame_rate
	var held: bool = pull.jerk(frame_of_middle, 7) == pull.jerk(frame_of_middle + step * 0.7, 7)
	for frame: int in range(roundi(stats.grab_time * 60.0) + 3, roundi(stats.pull_end * 60.0) - 1):
		var jerk: float = pull.jerk(frame / 60.0, 7)
		bounded = bounded and absf(jerk) <= 1.0
		moved = moved or jerk != 0.0
	return report(grows and pulls and never_back and still_before and still_after and bounded and moved
			and held,
			("Timing: %s pulls from Grab Time to Pull End, under half by the middle %s, never back %s; "
			+ "jerks only while pulling (before %s, after %s), within one %s, at all %s, held %s")
			% [grows, pulls, never_back, still_before, still_after, bounded,
			moved, held])


func _lines_are_cut_to_a_share_and_at_the_base() -> bool:
	var line := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, -10.0), Vector2(10.0, -10.0)])
	var none: bool = BramblePull.part(line, 0.0).is_empty()
	var whole: bool = BramblePull.part(line, 1.0) == line
	var half: PackedVector2Array = BramblePull.part(line, 0.5)
	var halfway: bool = half.size() == 2 and half[1].is_equal_approx(Vector2(0.0, -10.0))
	var dipping := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, -10.0), Vector2(0.0, 10.0)])
	var cut: PackedVector2Array = BramblePull.above(dipping, Vector2.ZERO, Vector2.UP)
	var at_the_base: bool = cut.size() == 3 and cut[2].is_equal_approx(Vector2.ZERO)
	return report(none and whole and halfway and at_the_base,
			"Lines: none at 0 %s, whole at 1 %s, half at a half %s, cut at the base %s" % [none, whole,
			halfway, at_the_base])


## Frozen, the vines show only if they grow at once (Grab Time 0); once grown, each starts on the
## hedge; by the end of the pull he is all the way under, no vine goes past the base and he has not
## moved. With no vines, none ever shows.
func _walking_into_a_floor_hedge_he_is_pulled_under() -> bool:
	var player: Player = await spawn_on_floor(FROM_THE_LEFT)
	if player == null:
		return report(false, "Pull: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	var stats: BrambleDeathStats = death.stats
	var drawing: CanvasItem = player.get_node(^"Sprite") as CanvasItem
	var sinking: SinkingDrawing = player.get_node(^"SinkingDrawing") as SinkingDrawing
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	for frame: int in RUN_FRAMES:
		await process_frame
		if player.is_dead():
			break
	stand_in.run_direction = 0.0
	var died: bool = player.is_dead()
	var caught_at: Vector2 = player.global_position
	var rest_y: float = (drawing as Node2D).position.y
	var frozen_lines: int = -1
	for frame: int in RUN_FRAMES:
		if not death.is_frozen():
			break
		await process_frame
		if death.is_frozen():
			frozen_lines = _drawn(death.get_vine_lines())
	var none_frozen: bool = frozen_lines == (stats.vines if stats.grab_time <= 0.0 else 0)
	await wait_frames(roundi(stats.grab_time * 60.0) + 2)
	var base: Vector2 = death.get_hedge_base()
	var lines: Array[PackedVector2Array] = death.get_vine_lines()
	var grown: bool = _drawn(lines) == stats.vines
	var from_the_hedge: bool = true
	for line: PackedVector2Array in lines:
		from_the_hedge = from_the_hedge and line.size() >= 2 and absf(line[0].y - base.y) < NEAR
	await wait_frames(roundi((stats.pull_end - stats.grab_time) * 60.0) + 4)
	var sunk: float = _sunk_px(drawing)
	var down: float = (drawing as Node2D).position.y - rest_y
	var under: bool = absf(sunk - sinking.depth) < NEAR
	if not stats.pull_clips:
		under = (absf(down - stats.pull_depth) < NEAR and sunk < NEAR
				and drawing.z_index == stats.pull_z)
	var not_past_the_base: bool = true
	for line: PackedVector2Array in death.get_vine_lines():
		for point: Vector2 in line:
			not_past_the_base = not_past_the_base and point.y <= base.y + NEAR
	var still: bool = player.global_position.distance_to(caught_at) < NEAR
	var depth: float = sinking.depth
	await remove_player(player)
	return report(died and none_frozen and grown and from_the_hedge and under and not_past_the_base
			and still,
			("Pull with %d vines, clipping %s: died %s; %d vines while frozen, as Grab Time says %s; "
			+ "grown, %d %s, each from the hedge %s; sunk %.1f px of %.0f, drawn %.1f px down (%.0f), "
			+ "pulled all the way %s; no vine past the base %s, he has not moved %s") % [stats.vines,
			stats.pull_clips, died, frozen_lines, none_frozen, _drawn(lines), grown, from_the_hedge,
			sunk, depth, down, stats.pull_depth, under, not_past_the_base, still])


## By the wall strip: the vines root on the wall's line, and his drawing ends Wall Pull nearer the
## wall, not sunk.
func _by_a_wall_he_is_pulled_into_the_hedge_not_under() -> bool:
	var player: Player = spawn_player(BY_THE_WALL)
	var death: Node = player.get_node(^"BrambleDeath")
	var stats: BrambleDeathStats = death.stats
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	var rest_x: float = drawing.position.x
	for frame: int in 10:
		await process_frame
		if player.is_dead():
			break
	var died: bool = player.is_dead()
	for frame: int in RUN_FRAMES:
		if not death.is_frozen():
			break
		await process_frame
	await wait_frames(roundi(stats.pull_end * 60.0) + 4)
	var rooted: bool = _drawn(death.get_vine_lines()) > 0
	var roots: PackedVector2Array = PackedVector2Array()
	for line: PackedVector2Array in death.get_vine_lines():
		if not line.is_empty():
			roots.append(line[0])
			rooted = rooted and absf(line[0].x - WALL_LEFT) < NEAR
	var pulled: float = drawing.position.x - rest_x
	var into_it: bool = absf(pulled - stats.wall_pull) < NEAR
	var sunk: float = _sunk_px(drawing)
	await remove_player(player)
	return report(died and rooted and into_it and sunk < NEAR,
			"Wall: died %s; vines rooted on the wall %s %s; pulled %.1f px towards it (%.0f) %s; sunk %.1f px"
			% [died, rooted, roots, pulled, stats.wall_pull, into_it, sunk])


func _a_death_by_something_else_pulls_nothing() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Other death: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	var stats: BrambleDeathStats = death.stats
	var drawing: Node2D = player.get_node(^"Sprite") as Node2D
	var rest: Vector2 = drawing.position
	player.die(&"dog")
	await wait_frames(roundi((stats.hitstop + stats.pull_end) * 60.0) + 4)
	var caught: bool = death.is_caught()
	var moved: float = drawing.position.distance_to(rest)
	var sunk: float = _sunk_px(drawing)
	var no_vines: bool = death.get_vine_lines().is_empty()
	await remove_player(player)
	return report(not caught and moved < NEAR and sunk == 0.0 and no_vines,
			"A death by a dog: caught %s, drawing moved %.2f px, sunk %.2f, no vines %s"
			% [caught, moved, sunk, no_vines])


## How many of Lines show: two points or more.
func _drawn(lines: Array[PackedVector2Array]) -> int:
	var count: int = 0
	for line: PackedVector2Array in lines:
		if line.size() >= 2:
			count += 1
	return count


## A strip of Floor Strip Tiles at At, turned by Turn.
func _strip(at: Vector2, turn: float) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.width_tiles = FLOOR_STRIP_TILES
	spikes.position = at
	spikes.rotation = turn
	root.add_child(spikes)
	return spikes


## How far the drawing is sunk, in the world's px.
func _sunk_px(drawing: CanvasItem) -> float:
	var shader_material: ShaderMaterial = drawing.material as ShaderMaterial
	var value: Variant = shader_material.get_shader_parameter(&"sink_depth") if shader_material != null else null
	return float(value) * absf(drawing.get_global_transform().get_scale().y) if value != null else 0.0
