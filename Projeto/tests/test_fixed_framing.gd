# Checks FixedFraming, the camera's way of framing the man with one zoom, on small maps of rock tiles built here.
# The camera scene comes with it, as Fixed. The switch to it glides from where the screen was, no faster than Max
# Speed, and eases the zoom in. Standing, he is centred across and Below Centre under the middle, at Zoom Level,
# which stays the same in a room, a corridor with a zone of another zoom and a chimney. Inside the dead zone he
# moves and the screen does not; past it, the screen keeps him at its edge. Running, the screen leads to his side,
# and once he stops he is within the dead zone of the middle again. A jump does not move the screen; a long fall
# looks down, his body stays inside the Edge Margin all the way, and landed he is framed as standing. The margin
# holds him even with a follow far too slow for the fall. Put far away on a run, he is framed on the next step,
# with no lead left, and the brain says it cut. In a chimney Chimney Width wide the screen holds the chimney's axis
# wherever he is across it; in a shaft a tile wider, or a niche lower than Chimney Height, it frames him. Sliding
# down a wall is no fall: the screen does not look down. By the level's outline the screen stops Map Margin tiles
# past the outermost open cell, on all four sides; the camera's own limits stop it first, by the outline, on a
# map open to the outside and with no tiles. A step of no time moves nothing. A new copy of the level given Fixed
# by the overlay starts framed that way, inside the outline from its first frame. Without tiles, with the map open
# to the outside, the map gives no limits, and starting in rock they wait until he is out. On another map the
# limits come from it. What is rock and where a chimney is are checked on their own in test_rock_map.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_fixed_framing.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const OVERLAY_SCENE: PackedScene = preload("res://scenes/others/debug/debug_overlay.tscn")
const TILE_SET: TileSet = preload("res://scenes/others/tilesets/cave_placeholder_tiles.tres")
const STATS: FixedFramingStats = preload("res://scenes/others/camera/fixed_framing_stats.tres")
## The name of the FixedFraming the camera scene comes with: the name F10 shows.
const SHIPPED_NAME: String = "Fixed"
const TILE: float = 48.0
## The first map, in cells: rock all over, with open spaces carved in it. A room taller and wider than the screen,
## a well under its floor (so the floor is not the lowest open cell), a corridor four tiles high out of it, and up
## from the corridor a chimney Chimney Width wide, a shaft one tile wider and a niche lower than Chimney Height.
const ROCK: Rect2i = Rect2i(0, 0, 140, 66)
const ROOM: Rect2i = Rect2i(4, 4, 76, 46)
const WELL: Rect2i = Rect2i(10, 50, 4, 10)
const CORRIDOR: Rect2i = Rect2i(80, 46, 50, 4)
const CHIMNEY: Rect2i = Rect2i(100, 10, 6, 36)
const WIDE_SHAFT: Rect2i = Rect2i(112, 10, 7, 36)
const NICHE: Rect2i = Rect2i(84, 43, 4, 3)
const FIRST_MAP: Array[Rect2i] = [ROOM, WELL, CORRIDOR, CHIMNEY, WIDE_SHAFT, NICHE]
## The same with the room reaching the rock's left edge, so the open space reaches past the map.
const OPEN_ROOM: Rect2i = Rect2i(0, 4, 80, 46)
const OPEN_MAP: Array[Rect2i] = [OPEN_ROOM, WELL, CORRIDOR, CHIMNEY, WIDE_SHAFT, NICHE]
## The second map: the same, with the room and its well further right.
const OTHER_ROOM: Rect2i = Rect2i(20, 4, 60, 46)
const OTHER_WELL: Rect2i = Rect2i(26, 50, 4, 10)
const OTHER_MAP: Array[Rect2i] = [OTHER_ROOM, OTHER_WELL, CORRIDOR, CHIMNEY, WIDE_SHAFT, NICHE]
## A camera zone over the corridor, at a zoom the camera's own way would take there.
const CORRIDOR_ZOOM: float = 2.0
## Cells he is put in: on the room's floor in its middle, at its left end and far along it; on the corridor's
## floor and at its right end; at the well's bottom; high in the room; in the air at both sides of the chimney, at
## the wide shaft's left side and in the niche; in the rock left of the room; at the open map's room's left end;
## at the second map's room's left end.
const ROOM_SPOT: Vector2i = Vector2i(40, 49)
const ROOM_LEFT_SPOT: Vector2i = Vector2i(5, 49)
const ROOM_FAR_SPOT: Vector2i = Vector2i(72, 49)
const CORRIDOR_SPOT: Vector2i = Vector2i(90, 49)
const CORRIDOR_END_SPOT: Vector2i = Vector2i(129, 49)
const WELL_SPOT: Vector2i = Vector2i(11, 59)
const HIGH_SPOT: Vector2i = Vector2i(40, 8)
const CHIMNEY_LEFT: Vector2i = Vector2i(100, 14)
const CHIMNEY_RIGHT: Vector2i = Vector2i(105, 14)
const WIDE_SPOT: Vector2i = Vector2i(112, 14)
const NICHE_SPOT: Vector2i = Vector2i(84, 45)
const ROCK_SPOT: Vector2i = Vector2i(2, 30)
const OPEN_LEFT_SPOT: Vector2i = Vector2i(1, 49)
const OTHER_LEFT_SPOT: Vector2i = Vector2i(21, 49)
## How far the screen may be from where it should be, in px; how much faster than Max Speed a step may go, in px;
## how far the zoom may be from Zoom Level, and how much it may change in a step of the switch.
const PLACE_TOLERANCE: float = 0.5
const SPEED_TOLERANCE: float = 1.0
const ZOOM_TOLERANCE: float = 0.001
## The camera's own way eases its zoom slower: after SETTLE_FRAMES in the corridor's zone it is this close.
const OWN_ZOOM_TOLERANCE: float = 0.01
const ZOOM_STEP: float = 0.02
## Frames for the screen to settle, and for the switch's glide.
const SETTLE_FRAMES: int = 300
const GLIDE_FRAMES: int = 360
## Where the switch starts from: this far from where the screen framed him, at this zoom.
const AWAY: Vector2 = Vector2(3000.0, 0.0)
const AWAY_ZOOM: float = 1.0
## Steps inside and past the dead zone, in px.
const SMALL_STEP: float = 20.0
const BIG_STEP: float = 100.0
## How long he runs, and how far the lead may be from Look Ahead less the dead zone, in px: the lead eases in and
## the spring settles, so a little is left of both after 1.5 s.
const RUN_FRAMES: int = 90
const LEAD_TOLERANCE: float = 8.0
## How long he runs before he is put far away: long enough for the screen to lead him.
const PLACING_RUN_FRAMES: int = 45
## Frames a jump gets to come back down and settle, and how high it must go to count as a whole jump, in px: a
## whole jump goes 240 px up.
const JUMP_FRAMES: int = 90
const WHOLE_JUMP: float = 200.0
## How long into the fall from high in the room the look down is read, and how much more must show under his
## feet then than standing, in px. At 1 s he is still falling, with about 700 px to go, and the look down, which
## eases in and has the spring easing after it, is nearly all in.
const FALL_FRAMES: int = 60
const MORE_UNDER: float = 200.0
## Frames he stays in the air in the chimney: he falls, but not out of it.
const CHIMNEY_FRAMES: int = 10
## How far from the chimney's left wall his body is put to slide down it, in px: off it, so he is in the air and
## not pushed out of the rock, and close enough to reach it in a frame.
const WALL_GAP: float = 1.0
## The camera's own right limit for one case, in px: in the room, 3.5 tiles right of his middle at ROOM_FAR_SPOT
## and well short of the map's outline.
const CAMERA_LIMIT_RIGHT: int = 3648
## A follow far too slow to keep up with a fall, per second: only the Edge Margin keeps him on the screen.
const SLOW_FOLLOW: float = 0.5

var _camera: GameCamera
var _player: Player
var _fixed: FixedFraming
var _tiles: TileMapLayer


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = [_check_the_scene_has_it()]
	_tiles = _build_map(FIRST_MAP)
	root.add_child(_tiles)
	root.add_child(_corridor_zone())
	_player = spawn_player(_feet(ROOM_SPOT))
	if not await wait_until_on_floor(_player):
		results.append(report(false, "The player never landed"))
		finish(results)
		return
	var stand_in: StandInInput = put_a_stand_in(_player)
	_fixed = FixedFraming.new()
	_fixed.name = "FixedUnderTest"
	_fixed.stats = STATS
	_camera = CAMERA_SCENE.instantiate() as GameCamera
	_camera.player = _player
	_camera.level_tiles = _tiles
	_camera.add_child(_fixed)
	root.add_child(_camera)
	await wait_frames(SETTLE_FRAMES)
	results.append(await _check_the_switch_glides())
	results.append(await _check_standing_frames_him())
	results.append(await _check_the_dead_zone())
	results.append(await _check_running_leads(stand_in))
	results.append(await _check_a_jump_keeps_the_screen(stand_in))
	results.append(await _check_a_fall_looks_down())
	results.append(await _check_the_margin_holds_him())
	results.append(await _check_placing_cuts_to_him(stand_in))
	results.append(await _check_one_zoom_everywhere())
	results.append(await _check_the_chimney_axis())
	results.append(await _check_a_wide_shaft_is_no_chimney())
	results.append(await _check_a_niche_is_no_chimney())
	results.append(await _check_a_wall_slide_does_not_look_down(stand_in))
	results.append(await _check_the_outline_limits())
	results.append(await _check_the_camera_limits())
	results.append(await _check_a_step_without_time())
	results.append(await _check_a_new_copy_starts_framed())
	results.append(await _check_no_outline_no_limits())
	results.append(await _check_another_map())
	finish(results)


## A camera zone over the corridor that zooms the camera's own way to CORRIDOR_ZOOM, set by hand.
func _corridor_zone() -> CameraZone:
	var zone: CameraZone = CameraZone.new()
	zone.auto_zoom = false
	zone.zoom = CORRIDOR_ZOOM
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(CORRIDOR.size) * TILE
	shape.shape = rectangle
	shape.position = (Vector2(CORRIDOR.position) + Vector2(CORRIDOR.size) / 2.0) * TILE
	zone.add_child(shape)
	return zone


## Takes the map away and puts one with each of open carved out in its place, for the camera too.
func _swap_map(open: Array[Rect2i]) -> void:
	_tiles.queue_free()
	_tiles = _build_map(open)
	root.add_child(_tiles)
	_camera.level_tiles = _tiles


## Rock over ROCK, with each of open carved out.
func _build_map(open: Array[Rect2i]) -> TileMapLayer:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = TILE_SET
	for y: int in range(ROCK.position.y, ROCK.end.y):
		for x: int in range(ROCK.position.x, ROCK.end.x):
			tiles.set_cell(Vector2i(x, y), StoneRim.ROCK_SOURCE, StoneRim.ROCK_ATLAS, StoneRim.ROCK_ALTERNATIVE)
	for rect: Rect2i in open:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				tiles.erase_cell(Vector2i(x, y))
	return tiles


## The camera scene comes with this way of framing, a child named SHIPPED_NAME with these Stats, so every level's
## camera has it.
func _check_the_scene_has_it() -> bool:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	var shipped: FixedFraming = camera.get_node_or_null(SHIPPED_NAME) as FixedFraming
	var found: bool = shipped != null
	var with_stats: bool = found and shipped.stats == STATS
	camera.free()
	return report(found and with_stats, "The camera scene has a FixedFraming named %s: %s, with its Stats: %s"
			% [SHIPPED_NAME, found, with_stats])


## The switch starts from a screen AWAY from him at AWAY_ZOOM, left there by a cutscene: no step is faster than
## Max Speed, the zoom never jumps, and the screen ends framing him at Zoom Level.
func _check_the_switch_glides() -> bool:
	_camera.use_brain(_fixed)
	await wait_frames(SETTLE_FRAMES)
	var framed: Vector2 = _camera.global_position
	_camera.direct()
	_camera.global_position = framed + AWAY
	_camera.zoom = Vector2.ONE * AWAY_ZOOM
	_camera.release()
	var previous: Vector2 = _camera.global_position
	var previous_zoom: float = _camera.zoom.x
	var fastest: float = 0.0
	var biggest_zoom_step: float = 0.0
	for _frame: int in GLIDE_FRAMES:
		await physics_frame
		fastest = maxf(fastest, _camera.global_position.distance_to(previous))
		biggest_zoom_step = maxf(biggest_zoom_step, absf(_camera.zoom.x - previous_zoom))
		previous = _camera.global_position
		previous_zoom = _camera.zoom.x
	var most: float = STATS.max_speed / Engine.physics_ticks_per_second + SPEED_TOLERANCE
	var back: float = _camera.global_position.distance_to(framed)
	return report(fastest <= most and biggest_zoom_step <= ZOOM_STEP and back <= PLACE_TOLERANCE
			and absf(_camera.zoom.x - STATS.zoom_level) <= ZOOM_TOLERANCE,
			("The switch from %.0f px away at zoom %.1f: fastest step %.1f px (at most %.1f), biggest zoom step "
			+ "%.4f (at most %.2f), ends %.2f px from framing him, at zoom %.3f (expected %.2f)")
			% [AWAY.length(), AWAY_ZOOM, fastest, most, biggest_zoom_step, ZOOM_STEP, back, _camera.zoom.x,
			STATS.zoom_level])


## Standing in the room's middle, he is centred across and Below Centre of the screen's height under its middle.
func _check_standing_frames_him() -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var off: Vector2 = _man() - _camera.global_position
	var below: float = STATS.below_centre * _view().y
	return report(absf(off.x) <= PLACE_TOLERANCE and absf(off.y - below) <= PLACE_TOLERANCE
			and absf(_camera.zoom.x - STATS.zoom_level) <= ZOOM_TOLERANCE,
			"Standing: %+.2f px across from the middle (expected 0), %+.2f px under it (expected %.2f), zoom %.3f"
			% [off.x, off.y, below, _camera.zoom.x])


## A step inside the dead zone leaves the screen where it was; one past it moves the screen until he is at the
## dead zone's edge.
func _check_the_dead_zone() -> bool:
	var before: Vector2 = _camera.global_position
	_put_at(_player.global_position + Vector2(SMALL_STEP, 0.0))
	await wait_frames(SETTLE_FRAMES)
	var moved: float = _camera.global_position.distance_to(before)
	_put_at(_player.global_position + Vector2(BIG_STEP, 0.0))
	await wait_frames(SETTLE_FRAMES)
	var edge: float = STATS.dead_zone_across
	var off: float = _man().x - _camera.global_position.x
	return report(moved <= PLACE_TOLERANCE and absf(off - edge) <= PLACE_TOLERANCE,
			("A %.0f px step moves the screen %.2f px (at most %.1f); after a %.0f px step he is %.2f px right of "
			+ "the middle (expected the dead zone's edge, %.2f)")
			% [SMALL_STEP, moved, PLACE_TOLERANCE, BIG_STEP, off, edge])


## Running right, the screen leads him by Look Ahead less the dead zone; stopped, he is within the dead zone of the
## middle again.
func _check_running_leads(stand_in: StandInInput) -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	var lead: float = _camera.global_position.x - _man().x
	stand_in.run_direction = 0.0
	await wait_frames(SETTLE_FRAMES)
	var expected: float = STATS.look_ahead * _view().x - STATS.dead_zone_across
	var stopped: float = absf(_man().x - _camera.global_position.x)
	var edge: float = STATS.dead_zone_across
	return report(absf(lead - expected) <= LEAD_TOLERANCE and stopped <= edge + PLACE_TOLERANCE,
			("Running right the screen leads him by %.1f px (expected %.1f); stopped, he is %.2f px from the "
			+ "middle (at most the dead zone, %.2f)") % [lead, expected, stopped, edge])


## A whole jump from the room's floor and the landing leave the screen where it was, up and down.
func _check_a_jump_keeps_the_screen(stand_in: StandInInput) -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var level: float = _camera.global_position.y
	var floor_y: float = _player.global_position.y
	stand_in.hold_jump = true
	stand_in.press_jump()
	var highest: float = floor_y
	var furthest: float = 0.0
	for _frame: int in JUMP_FRAMES:
		await physics_frame
		highest = minf(highest, _player.global_position.y)
		furthest = maxf(furthest, absf(_camera.global_position.y - level))
	stand_in.hold_jump = false
	return report(floor_y - highest >= WHOLE_JUMP and furthest <= PLACE_TOLERANCE,
			"A jump %.0f px high moves the screen up or down at most %.2f px (at most %.1f)"
			% [floor_y - highest, furthest, PLACE_TOLERANCE])


## Falling from high in the room, after the look down has eased in, far more shows under his feet than when he
## stands; on every step of the fall his body stays inside the Edge Margin; landed, he is framed as standing.
func _check_a_fall_looks_down() -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var standing_under: float = _under_his_feet()
	_put(HIGH_SPOT)
	var falling_under: float = 0.0
	var worst_inset: float = INF
	for frame: int in FALL_FRAMES:
		await physics_frame
		worst_inset = minf(worst_inset, _body_inset())
		if frame == FALL_FRAMES - 1:
			falling_under = _under_his_feet()
	var inset: float = STATS.edge_margin * _view().y
	await wait_until_on_floor(_player)
	await wait_frames(SETTLE_FRAMES)
	var landed_under: float = _under_his_feet()
	return report(falling_under - standing_under >= MORE_UNDER and worst_inset >= inset - PLACE_TOLERANCE
			and absf(landed_under - standing_under) <= PLACE_TOLERANCE,
			("Standing, %.0f px show under his feet; %.2f s into a fall, %.0f px (at least %.0f more); his body "
			+ "came %.1f px from the screen's edges at the closest (at least the Edge Margin, %.1f); landed, "
			+ "%.1f px") % [standing_under, FALL_FRAMES / float(Engine.physics_ticks_per_second), falling_under,
			MORE_UNDER, worst_inset, inset, landed_under])


## With a follow far too slow for a fall, the screen still keeps his body inside the Edge Margin, and only just:
## the margin, not the follow, holds him.
func _check_the_margin_holds_him() -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var slow: FixedFramingStats = STATS.duplicate() as FixedFramingStats
	slow.follow_sharpness = SLOW_FOLLOW
	_fixed.stats = slow
	_put(HIGH_SPOT)
	var worst_inset: float = INF
	for _frame: int in MAX_FRAMES:
		await physics_frame
		worst_inset = minf(worst_inset, _body_inset())
		if _player.is_on_floor():
			break
	_fixed.stats = STATS
	await wait_frames(SETTLE_FRAMES)
	var inset: float = STATS.edge_margin * _view().y
	return report(absf(worst_inset - inset) <= PLACE_TOLERANCE,
			("With a follow of %.1f/s, in a fall his body came %.2f px from the screen's edges at the closest "
			+ "(expected the Edge Margin, %.2f)") % [SLOW_FOLLOW, worst_inset, inset])


## Put far along the room while the screen leads him on a run, as the debug tools do, he is framed on the next
## step: centred across, with no lead left, and Below Centre under the middle. The brain says it cut on that step,
## and not on the next.
func _check_placing_cuts_to_him(stand_in: StandInInput) -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	stand_in.run_direction = 1.0
	await wait_frames(PLACING_RUN_FRAMES)
	stand_in.run_direction = 0.0
	var lead: float = _camera.global_position.x - _man().x
	var from_x: float = _player.global_position.x
	_put(ROOM_FAR_SPOT)
	await physics_frame
	var off: Vector2 = _man() - _camera.global_position
	var cut: bool = _fixed.has_cut()
	await physics_frame
	var cut_again: bool = _fixed.has_cut()
	var below: float = STATS.below_centre * _view().y
	return report(absf(off.x) <= PLACE_TOLERANCE and absf(off.y - below) <= PLACE_TOLERANCE and cut
			and not cut_again,
			("Put %.0f px away while the screen led him by %.1f px, on the next step he is %+.2f px across from "
			+ "the middle and %+.2f px under it; cut on that step %s, on the next %s")
			% [_player.global_position.x - from_x, lead, off.x, off.y, cut, cut_again])


## The camera's own way zooms to the corridor's zone, read with its idle zoom off, as he stands; with this way,
## the zoom is Zoom Level in the room, the corridor and the chimney.
func _check_one_zoom_everywhere() -> bool:
	var own_stats: CameraStats = _camera.stats
	_camera.stats = own_stats.duplicate() as CameraStats
	_camera.stats.idle_zoom = 1.0
	_camera.use_brain(null)
	_put(CORRIDOR_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var own_zoom: float = _camera.zoom.x
	_camera.stats = own_stats
	_camera.use_brain(_fixed)
	await wait_frames(SETTLE_FRAMES)
	var zooms: Array[float] = []
	for spot: Vector2i in [ROOM_SPOT, CORRIDOR_SPOT, CHIMNEY_LEFT]:
		_put(spot)
		await wait_frames(CHIMNEY_FRAMES)
		zooms.append(_camera.zoom.x)
	var same: bool = true
	for zoom_level: float in zooms:
		same = same and absf(zoom_level - STATS.zoom_level) <= ZOOM_TOLERANCE
	await wait_until_on_floor(_player)
	return report(absf(own_zoom - CORRIDOR_ZOOM) <= OWN_ZOOM_TOLERANCE and same,
			("In the corridor's zone the camera's own way zooms to %.3f (expected %.1f); this way's zoom in the "
			+ "room, the corridor and the chimney: %s (expected %.2f)") % [own_zoom, CORRIDOR_ZOOM, zooms,
			STATS.zoom_level])


## In the air in the chimney, at its left side and then at its right, the screen stays on the chimney's axis.
func _check_the_chimney_axis() -> bool:
	var axis: float = (CHIMNEY.position.x + CHIMNEY.end.x) / 2.0 * TILE
	_put(CHIMNEY_LEFT)
	await wait_frames(2)
	var at_left: float = _camera.global_position.x
	_put(CHIMNEY_RIGHT)
	var furthest: float = absf(at_left - axis)
	for _frame: int in CHIMNEY_FRAMES:
		await physics_frame
		furthest = maxf(furthest, absf(_camera.global_position.x - axis))
	await wait_until_on_floor(_player)
	return report(furthest <= PLACE_TOLERANCE,
			"In the chimney, from its left side to its right, the screen is at most %.2f px from its axis at x %.0f"
			% [furthest, axis])


## Put in the air at the left side of a shaft a little wider than Chimney Width, he is framed across, not the
## shaft's axis.
func _check_a_wide_shaft_is_no_chimney() -> bool:
	_put(WIDE_SPOT)
	await physics_frame
	var off: float = _man().x - _camera.global_position.x
	await wait_until_on_floor(_player)
	return report(absf(off) <= PLACE_TOLERANCE,
			"In a shaft %d tiles wide (a chimney is at most %d) he is %+.2f px across from the middle (expected 0)"
			% [WIDE_SHAFT.size.x, STATS.chimney_width, off])


## Put in the air in a niche as narrow as a chimney but lower than Chimney Height, he is framed across, not the
## niche's axis.
func _check_a_niche_is_no_chimney() -> bool:
	_put(NICHE_SPOT)
	await physics_frame
	var off: float = _man().x - _camera.global_position.x
	await wait_until_on_floor(_player)
	return report(absf(off) <= PLACE_TOLERANCE,
			"In a niche %d tiles high (a chimney is at least %d) he is %+.2f px across from the middle (expected 0)"
			% [NICHE.size.y, STATS.chimney_height, off])


## By the level's outline the screen stops Map Margin tiles past the outermost open cell: on the left at the room's
## left end, on the right at the corridor's end, at the top with him high in the room and at the bottom in the well.
func _check_the_outline_limits() -> bool:
	_put(ROOM_LEFT_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var left: float = _camera.global_position.x - _view().x / 2.0
	_put(CORRIDOR_END_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var right: float = _camera.global_position.x + _view().x / 2.0
	_put(HIGH_SPOT)
	await physics_frame
	var top: float = _camera.global_position.y - _view().y / 2.0
	await wait_until_on_floor(_player)
	_put(WELL_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var bottom: float = _camera.global_position.y + _view().y / 2.0
	var found: Rect2 = Rect2(left, top, right - left, bottom - top)
	var open: Rect2i = ROOM.merge(CORRIDOR).merge(WELL)
	var expected: Rect2 = Rect2(Vector2(open.position - Vector2i.ONE * STATS.map_margin) * TILE,
			Vector2(open.size + Vector2i.ONE * 2 * STATS.map_margin) * TILE)
	var close: bool = (absf(left - expected.position.x) <= PLACE_TOLERANCE
			and absf(top - expected.position.y) <= PLACE_TOLERANCE
			and absf(right - expected.end.x) <= PLACE_TOLERANCE
			and absf(bottom - expected.end.y) <= PLACE_TOLERANCE)
	return report(close, "By the outline the screen's edges stop at %s (expected %s)" % [found, expected])


## With the camera's own right limit, as a level sets it, inside the room, the screen stops at it: before the
## map's outline, on a map open to the outside and with no tiles. The first time only the limit changes, not the
## map. The limit and the map are set back after.
func _check_the_camera_limits() -> bool:
	var own_right: int = _camera.limit_right
	_camera.limit_right = CAMERA_LIMIT_RIGHT
	var by_outline: float = await _right_edge_now()
	_swap_map(OPEN_MAP)
	var open_map: float = await _right_edge_now()
	_swap_map(FIRST_MAP)
	_camera.level_tiles = null
	var no_tiles: float = await _right_edge_now()
	_camera.limit_right = own_right
	_camera.level_tiles = _tiles
	await _right_edge_now()
	var stopped: bool = true
	for right: float in [by_outline, open_map, no_tiles]:
		stopped = stopped and absf(right - CAMERA_LIMIT_RIGHT) <= PLACE_TOLERANCE
	return report(stopped, ("With the camera's own right limit at x %d, the screen's right edge is at x %.2f by the "
			+ "map's outline, %.2f on a map open to the outside and %.2f with no tiles (expected %d for each)")
			% [CAMERA_LIMIT_RIGHT, by_outline, open_map, no_tiles, CAMERA_LIMIT_RIGHT])


## Where the screen's right edge settles with him at ROOM_FAR_SPOT, with the brain begun afresh.
func _right_edge_now() -> float:
	_put(ROOM_FAR_SPOT)
	_camera.use_brain(null)
	_camera.use_brain(_fixed)
	await wait_frames(SETTLE_FRAMES)
	return _camera.global_position.x + _view().x / 2.0


## Sliding down the chimney's left wall for longer than Fall Delay, he stays under the screen's middle: the look
## down is for falls, and a slide down a wall is not one, so a climb up a chimney does not swing the screen.
func _check_a_wall_slide_does_not_look_down(stand_in: StandInInput) -> bool:
	var by_the_wall: float = CHIMNEY.position.x * TILE + body_size(_player).x / 2.0 + WALL_GAP
	_put_at(Vector2(by_the_wall, _feet(CHIMNEY_LEFT).y))
	stand_in.run_direction = -1.0
	var on_wall: int = 0
	var highest: float = INF
	for _frame: int in FALL_FRAMES:
		await physics_frame
		if _player.is_on_wall():
			on_wall += 1
		highest = minf(highest, _man().y - _camera.global_position.y)
	stand_in.run_direction = 0.0
	await wait_until_on_floor(_player)
	return report(on_wall * 2 >= FALL_FRAMES and highest > 0.0,
			("Sliding down the chimney's left wall (on it %d of %d frames), he was at least %+.1f px under the "
			+ "screen's middle (expected under it)") % [on_wall, FALL_FRAMES, highest])


## A step that takes no time, standing, leaves the screen and the zoom where they were.
func _check_a_step_without_time() -> bool:
	_put(ROOM_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var centre: Vector2 = _fixed.get_centre()
	var zoom_level: float = _fixed.get_zoom()
	_fixed.advance(0.0)
	var moved: Vector2 = _fixed.get_centre() - centre
	var zoomed: float = _fixed.get_zoom() - zoom_level
	return report(moved.is_finite() and moved.length() <= PLACE_TOLERANCE and absf(zoomed) <= ZOOM_TOLERANCE,
			"A step of no time moves the screen by %s and the zoom by %.4f (expected nothing)" % [moved, zoomed])


## A new copy of the level, with Fixed already chosen with F10, starts framed by it as the overlay gets ready: on
## its first frame, with him at the room's left end, the copy's camera is at Zoom Level, already stopped by the
## map's outline and with him Below Centre under the middle, with no glide from where it began.
func _check_a_new_copy_starts_framed() -> bool:
	_put(ROOM_LEFT_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var copy: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	copy.player = _player
	copy.level_tiles = _tiles
	root.add_child(copy)
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.start_visible = false
	overlay.player = _player
	overlay.camera = copy
	DebugOverlay.camera_mode = SHIPPED_NAME
	root.add_child(overlay)
	await process_frame
	var framing: String = copy.get_framing_name()
	var zoom_level: float = copy.zoom.x
	var left_edge: float = copy.global_position.x - root.get_visible_rect().size.x / zoom_level / 2.0
	var below_middle: float = _man().y - copy.global_position.y
	DebugOverlay.camera_mode = ""
	overlay.queue_free()
	copy.queue_free()
	await process_frame
	var below: float = STATS.below_centre * root.get_visible_rect().size.y / STATS.zoom_level
	var limit: float = (ROOM.position.x - STATS.map_margin) * TILE
	return report(framing == SHIPPED_NAME and absf(zoom_level - STATS.zoom_level) <= ZOOM_TOLERANCE
			and absf(left_edge - limit) <= PLACE_TOLERANCE and absf(below_middle - below) <= PLACE_TOLERANCE,
			("A new copy's camera, given %s, frames with %s on its first frame at zoom %.3f, by the room's left end "
			+ "the screen's left edge at x %.2f (expected the outline's, %.0f) and he %+.2f px under the middle "
			+ "(expected %.2f)") % [SHIPPED_NAME, framing, zoom_level, left_edge, limit, below_middle, below])


## With no outline there are no limits, and the screen centres him at the room's left end: when the camera has no
## tiles, and when the map is open to the outside. Begun with him in rock, the limits wait until he is out of it.
func _check_no_outline_no_limits() -> bool:
	_camera.level_tiles = null
	_put(ROOM_LEFT_SPOT)
	_camera.use_brain(null)
	_camera.use_brain(_fixed)
	await wait_frames(SETTLE_FRAMES)
	var without_tiles: float = _man().x - _camera.global_position.x
	_camera.level_tiles = _tiles
	_put(ROCK_SPOT)
	_camera.use_brain(null)
	_camera.use_brain(_fixed)
	_put(ROOM_LEFT_SPOT)
	await wait_frames(SETTLE_FRAMES)
	var out_of_rock: float = _camera.global_position.x - _view().x / 2.0
	var limit: float = (ROOM.position.x - STATS.map_margin) * TILE
	_swap_map(OPEN_MAP)
	_put(OPEN_LEFT_SPOT)
	_camera.use_brain(null)
	_camera.use_brain(_fixed)
	await wait_frames(SETTLE_FRAMES)
	var open_map: float = _man().x - _camera.global_position.x
	return report(absf(without_tiles) <= PLACE_TOLERANCE and absf(open_map) <= PLACE_TOLERANCE
			and absf(out_of_rock - limit) <= PLACE_TOLERANCE,
			("Without tiles he is %+.2f px across from the middle, on a map open to the outside %+.2f (expected 0 "
			+ "for both); begun in rock, out of it the screen's left edge is at x %.2f (expected %.0f)")
			% [without_tiles, open_map, out_of_rock, limit])


## On a second map, with the room further right, the screen's left edge stops by that map's outline.
func _check_another_map() -> bool:
	_swap_map(OTHER_MAP)
	_put(OTHER_LEFT_SPOT)
	_camera.use_brain(null)
	_camera.use_brain(_fixed)
	await wait_frames(SETTLE_FRAMES)
	var left_edge: float = _camera.global_position.x - _view().x / 2.0
	var expected: float = (OTHER_ROOM.position.x - STATS.map_margin) * TILE
	return report(absf(left_edge - expected) <= PLACE_TOLERANCE,
			"On another map, at its room's left end the screen's left edge is at x %.2f (expected %.0f)"
			% [left_edge, expected])


## Puts him standing in cell, at rest.
func _put(cell: Vector2i) -> void:
	_put_at(_feet(cell))


func _put_at(at: Vector2) -> void:
	_player.velocity = Vector2.ZERO
	_player.global_position = at


## Where his feet go in cell: on its bottom edge.
func _feet(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE - 0.1)


## The middle of his body.
func _man() -> Vector2:
	return _player.global_position + (_player.get_node(^"CollisionShape2D") as CollisionShape2D).position


func _view() -> Vector2:
	return root.get_visible_rect().size / _camera.zoom.x


## How much of the screen shows under his feet, in px of the world.
func _under_his_feet() -> float:
	return _camera.global_position.y + _view().y / 2.0 - _player.global_position.y


## How close his body comes to the screen's top or bottom edge, in px of the world.
func _body_inset() -> float:
	var half: float = body_size(_player).y / 2.0
	var top: float = _man().y - half - (_camera.global_position.y - _view().y / 2.0)
	var bottom: float = _camera.global_position.y + _view().y / 2.0 - (_man().y + half)
	return minf(top, bottom)
