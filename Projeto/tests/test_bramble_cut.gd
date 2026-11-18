# Checks how brambles cut the man apart as they kill him (#263). The rule: the slashes split the box
# around his drawing into convex pieces, one more than the slashes, that fill it; the higher a piece,
# the harder it is thrown and the faster it spins, every other one the other way, the bottom one not
# at all; pieces fall, rest on the floor and stay; they fade after Fade Start; the slashes fade
# after the freeze; and the point of the frame drawn at a place follows the sprite's mirror. In
# play: during the freeze his drawing is whole and white and the slashes are drawn; after it, his
# drawing is hidden and the pieces show the frame he died on, each where that part was drawn, then
# fly, rest above the floor and fade out; by a wall the top piece flies away from it; a death by
# something else cuts nothing. The values are in his BrambleDeath's Stats.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_bramble_cut.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const BrambleCut := preload("res://scenes/characters/player/bramble_cut.gd")
const BrambleDeathStats := preload("res://scenes/characters/player/bramble_death_stats.gd")
## The game's values, which the man takes: Cut Apart is off in them; the cases in play turn it on,
## and back off.
const GAME_STATS: BrambleDeathStats = preload("res://scenes/characters/player/bramble_death_stats.tres")
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const FLOOR_STRIP_TILES: int = 3
## Starts on either side of the floor strip, so he walks into it facing each way.
const FROM_THE_LEFT := Vector2(-300.0, -2.0)
const FROM_THE_RIGHT := Vector2(300.0, -2.0)
const WALL_LEFT: float = 600.0
const WALL_RIGHT: float = 700.0
const WALL_TOP: float = -800.0
const WALL_STRIP_AT := Vector2(WALL_LEFT, -300.0)
## In the air against the wall strip, as test_bramble_death puts him.
const BY_THE_WALL := Vector2(WALL_LEFT - 34.0, -240.0)
const ELSEWHERE := Vector2(-1200.0, -2.0)
const RUN_FRAMES: int = 120
## A frame of the man's sheets, and his body box in its px, as the tests of the rule use them.
const FRAME_SIZE := Vector2(384.0, 384.0)
const OFFSET := Vector2(0.0, -176.0)
const BODY_TOP: float = -358.0
const CHANCES: int = 20
const NEAR: float = 0.5


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	make_wall(WALL_LEFT, WALL_RIGHT, WALL_TOP)
	var floor_strip: LethalSpikes = _strip(Vector2.ZERO, 0.0)
	var wall_strip: LethalSpikes = _strip(WALL_STRIP_AT, -PI / 2.0)
	await physics_frame
	var results: Array[bool] = []
	results.append(_the_slashes_split_the_box_into_pieces_that_fill_it())
	results.append(_the_pieces_fly_rest_and_fade())
	results.append(_the_frame_point_follows_the_mirror())
	var game_stats: BrambleDeathStats = GAME_STATS
	game_stats.cut_apart = true
	results.append(await _walking_into_the_hedge_he_is_slashed_then_cut_apart(FROM_THE_LEFT, 1.0))
	results.append(await _walking_into_the_hedge_he_is_slashed_then_cut_apart(FROM_THE_RIGHT, -1.0))
	results.append(await _by_a_wall_the_top_piece_flies_away_from_it())
	results.append(await _a_death_by_something_else_cuts_nothing())
	game_stats.cut_apart = false
	floor_strip.free()
	wall_strip.free()
	# A footstep of the last man still playing when the run quits is reported as a leak.
	await wait_frames(30)
	finish(results)


## For CHANCES deaths: one piece more than the slashes, each convex and inside the box, filling it,
## from the top down; the slashes tilt between the least and the most, one way then the other, and
## not every death the same.
func _the_slashes_split_the_box_into_pieces_that_fill_it() -> bool:
	var stats: BrambleDeathStats = BrambleDeathStats.new()
	var cut: BrambleCut = BrambleCut.new(stats)
	var box: PackedVector2Array = _box(stats)
	var box_area: float = BrambleCut.area(box)
	var bounds: Rect2 = Rect2(box[0], box[2] - box[0])
	var counted: bool = true
	var filled: bool = true
	var inside: bool = true
	var convex: bool = true
	var ordered: bool = true
	var tilted: bool = true
	var same_way: bool = true
	var tilts: Dictionary[int, bool] = {}
	var sides: Dictionary[float, bool] = {}
	for chance: int in CHANCES:
		var cuts: Array[BrambleCut.Cut] = cut.cuts(BODY_TOP, 0.0, 0.0, chance)
		var pieces: Array[PackedVector2Array] = cut.split(box, cuts)
		counted = counted and pieces.size() == stats.cuts + 1
		var total: float = 0.0
		for k: int in pieces.size():
			total += BrambleCut.area(pieces[k])
			convex = convex and _is_convex(pieces[k])
			for point: Vector2 in pieces[k]:
				inside = inside and bounds.grow(0.01).has_point(point)
			if k > 0:
				ordered = ordered and BrambleCut.centre(pieces[k - 1]).y < BrambleCut.centre(pieces[k]).y
		filled = filled and absf(total - box_area) < box_area * 0.001
		for i: int in cuts.size():
			var degrees: float = absf(rad_to_deg(cuts[i].angle))
			tilted = tilted and degrees >= stats.cut_tilt_min - 0.01 and degrees <= stats.cut_tilt_max + 0.01
			same_way = same_way and absf(cuts[i].shift) <= stats.slash_stagger + 0.0001
			if i > 0:
				same_way = same_way and signf(cuts[i].angle) == signf(cuts[i - 1].angle)
		tilts[roundi(rad_to_deg(cuts[0].angle))] = true
		sides[signf(cuts[0].angle)] = true
	var varied: bool = tilts.size() > 1 and sides.size() == 2
	return report(counted and filled and inside and convex and ordered and tilted and same_way
			and varied,
			("Rule, %d deaths: %d pieces each %s, filling the box %s, inside it %s, convex %s, top down "
			+ "%s; tilts between the least and the most %s, all the same way and slid within the "
			+ "stagger %s, varied (%d tilts, %d sides) %s") % [CHANCES, stats.cuts + 1, counted,
			filled, inside, convex, ordered, tilted, same_way, tilts.size(), sides.size(), varied])


## The top piece goes up and to the side, the next the other way and slower, the bottom one stays;
## spins likewise; a thrown piece rises, comes down to rest and stays, held to the frames of the
## effects, and stops turning when it lands; fade and the slashes' strength go from whole to gone on
## time.
func _the_pieces_fly_rest_and_fade() -> bool:
	var stats: BrambleDeathStats = BrambleDeathStats.new()
	var cut: BrambleCut = BrambleCut.new(stats)
	var count: int = stats.cuts + 1
	var top: Vector2 = cut.throw(0, count, 1.0)
	var next: Vector2 = cut.throw(1, count, 1.0)
	var bottom: Vector2 = cut.throw(count - 1, count, 1.0)
	var thrown: bool = (top.x > 0.0 and top.y < 0.0 and next.x < 0.0 and absf(next.x) < absf(top.x)
			and next.y > top.y and bottom == Vector2.ZERO)
	var spins: bool = (cut.spin(0, count, 1.0) > 0.0 and cut.spin(1, count, 1.0) < 0.0
			and cut.spin(count - 1, count, 1.0) == 0.0 and cut.spin(0, count, -1.0) < 0.0)
	var start := Vector2(0.0, -60.0)
	var gravity: float = 980.0
	var rest_y: float = -10.0
	var rises: bool = cut.place(start, top, gravity, rest_y, 0.1).y < start.y
	var lands: float = BrambleCut.landing(start, top, gravity, rest_y)
	var rests: bool = (absf(cut.place(start, top, gravity, rest_y, lands + 0.2).y - rest_y) < 0.01
			and cut.place(start, top, gravity, rest_y, lands + 0.2) == cut.place(start, top, gravity,
			rest_y, lands + 1.0))
	var step: float = 1.0 / stats.frame_rate
	var held: bool = cut.place(start, top, gravity, rest_y, step * 1.2) == cut.place(start, top,
			gravity, rest_y, step * 1.8)
	var spin_speed: float = cut.spin(0, count, 1.0)
	var stops_turning: bool = is_equal_approx(
			cut.turn(spin_speed, start, top, gravity, rest_y, lands + 0.3),
			cut.turn(spin_speed, start, top, gravity, rest_y, lands + 1.0))
	var fades: bool = (cut.fade(stats.fade_start - step) == 0.0
			and cut.fade(stats.fade_start + stats.fade_time) == 1.0
			and cut.fade(stats.fade_start + stats.fade_time / 2.0) > 0.0)
	var slashes: bool = cut.slash_strength(0.0) == 1.0 and cut.slash_strength(stats.slash_fade) == 0.0
	return report(thrown and spins and rises and rests and held and stops_turning and fades and slashes,
			("Rule: thrown %s (top %s, next %s, bottom %s), spins %s; rises %s, rests and stays %s, "
			+ "held %s, stops turning %s; fades on time %s; slashes fade %s") % [thrown, top, next,
			bottom, spins, rises, rests, held, stops_turning, fades, slashes])


## Centred: the frame's top left is drawn at the top left of the sprite's rect, or, mirrored, at its
## top right; its middle at the offset either way.
func _the_frame_point_follows_the_mirror() -> bool:
	var top_left: Vector2 = OFFSET - FRAME_SIZE / 2.0
	var top_right: Vector2 = OFFSET + Vector2(FRAME_SIZE.x, -FRAME_SIZE.y) / 2.0
	var plain: bool = BrambleCut.frame_point(top_left, FRAME_SIZE, OFFSET, false).is_zero_approx()
	var mirrored: bool = BrambleCut.frame_point(top_right, FRAME_SIZE, OFFSET, true).is_zero_approx()
	var middle: bool = (BrambleCut.frame_point(OFFSET, FRAME_SIZE, OFFSET, true) == FRAME_SIZE / 2.0
			and BrambleCut.frame_point(OFFSET, FRAME_SIZE, OFFSET, false) == FRAME_SIZE / 2.0)
	return report(plain and mirrored and middle,
			"Frame point: plain %s, mirrored %s, middle both ways %s" % [plain, mirrored, middle])


## Walking into the floor hedge facing Facing: frozen, his drawing white and whole, slashes drawn, no
## pieces; once the freeze is over, his drawing hidden and one piece more than the slashes, showing
## the frame he died on where each part was drawn; then the top piece rises, and every piece rests
## above the floor; once faded, none shows.
func _walking_into_the_hedge_he_is_slashed_then_cut_apart(from: Vector2, facing: float) -> bool:
	var player: Player = await spawn_on_floor(from)
	if player == null:
		return report(false, "Cut: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	var stats: BrambleDeathStats = death.stats
	var drawing: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = facing
	for frame: int in RUN_FRAMES:
		await process_frame
		if player.is_dead():
			break
	stand_in.run_direction = 0.0
	var died: bool = player.is_dead() and player.get_facing() == facing
	var frozen: bool = death.is_frozen()
	var whole: bool = drawing.visible and _flash(drawing) == 1.0
	var slashed: bool = death.get_slashes() != null and death.get_slashes().visible
	var no_pieces_yet: bool = _shown(death.get_pieces()).is_empty()
	var drawn_at: Transform2D = drawing.global_transform
	for frame: int in RUN_FRAMES:
		if not death.is_frozen():
			break
		await process_frame
	var pieces: Array[Polygon2D] = _shown(death.get_pieces())
	var hidden: bool = not drawing.visible
	var counted: bool = pieces.size() == stats.cuts + 1
	var region: Rect2 = death.get_cut_region()
	var in_place: bool = true
	for piece: Polygon2D in pieces:
		for i: int in piece.polygon.size():
			var local: Vector2 = drawn_at.affine_inverse() * (piece.transform * piece.polygon[i])
			var expected: Vector2 = region.position + BrambleCut.frame_point(local, region.size,
					drawing.offset, drawing.flip_h)
			in_place = in_place and expected.distance_to(piece.uv[i]) < NEAR
	var top_start: float = pieces[0].position.y if not pieces.is_empty() else 0.0
	await wait_frames(roundi(0.1 * 60.0))
	var top_rose: bool = not pieces.is_empty() and pieces[0].position.y < top_start
	await wait_frames(roundi(stats.fade_start * 60.0) - 6)
	var above_the_floor: bool = true
	for piece: Polygon2D in pieces:
		above_the_floor = above_the_floor and piece.position.y < 0.0
	await wait_frames(roundi((stats.fade_start + stats.fade_time) * 60.0))
	var gone: bool = _shown(death.get_pieces()).is_empty()
	await remove_player(player)
	return report(died and frozen and whole and slashed and no_pieces_yet and hidden and counted
			and in_place and top_rose and above_the_floor and gone,
			("Cut facing %+.0f: died %s; frozen %s with his drawing whole and white %s, slashes %s, no "
			+ "pieces %s; after, his drawing hidden %s, %d pieces (%d expected), each where its part "
			+ "was drawn %s; the top one rose %s; all above the floor %s; gone once faded %s")
			% [facing, died, frozen, whole, slashed, no_pieces_yet, hidden, pieces.size(),
			stats.cuts + 1, in_place, top_rose, above_the_floor, gone])


## Caught against the wall strip, he is cut apart and the top piece moves away from the wall.
func _by_a_wall_the_top_piece_flies_away_from_it() -> bool:
	var player: Player = spawn_player(BY_THE_WALL)
	var death: Node = player.get_node(^"BrambleDeath")
	for frame: int in 10:
		await process_frame
		if player.is_dead():
			break
	var died: bool = player.is_dead()
	for frame: int in RUN_FRAMES:
		if not death.is_frozen():
			break
		await process_frame
	var pieces: Array[Polygon2D] = _shown(death.get_pieces())
	var start_x: float = pieces[0].position.x if not pieces.is_empty() else 0.0
	await wait_frames(12)
	var away: bool = not pieces.is_empty() and pieces[0].position.x < start_x
	await remove_player(player)
	return report(died and not pieces.is_empty() and away,
			"Wall: died %s, %d pieces, the top one away from the wall %s" % [died, pieces.size(), away])


func _a_death_by_something_else_cuts_nothing() -> bool:
	var player: Player = await spawn_on_floor(ELSEWHERE)
	if player == null:
		return report(false, "Other death: the player never landed")
	var death: Node = player.get_node(^"BrambleDeath")
	var drawing: CanvasItem = player.get_node(^"Sprite") as CanvasItem
	player.die(&"dog")
	await wait_frames(20)
	var none: bool = _shown(death.get_pieces()).is_empty() and death.get_slashes() == null
	var drawn: bool = drawing.visible
	await remove_player(player)
	return report(none and drawn, "A death by a dog: no pieces nor slashes %s, his drawing shows %s"
			% [none, drawn])


## The pieces' box of the man's frame, in the sprite's px, as BrambleDeath makes it.
func _box(stats: BrambleDeathStats) -> PackedVector2Array:
	var half: Vector2 = Vector2(FRAME_SIZE.x * stats.cut_box_share, FRAME_SIZE.y) / 2.0
	return PackedVector2Array([OFFSET - half, OFFSET + Vector2(half.x, -half.y), OFFSET + half,
			OFFSET + Vector2(-half.x, half.y)])


func _is_convex(polygon: PackedVector2Array) -> bool:
	var turn: float = 0.0
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var c: Vector2 = polygon[(i + 2) % polygon.size()]
		var cross: float = (b - a).cross(c - b)
		if absf(cross) < 0.0001:
			continue
		if turn != 0.0 and signf(cross) != turn:
			return false
		turn = signf(cross)
	return true


func _shown(pieces: Array) -> Array[Polygon2D]:
	var shown: Array[Polygon2D] = []
	for piece: Polygon2D in pieces:
		if piece.visible:
			shown.append(piece)
	return shown


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
