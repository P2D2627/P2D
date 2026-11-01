# Test of the camera's zoom. Standing still on a floor, the camera keeps its zoom and its look ahead
# until Idle Delay has passed; then it closes in to Idle Zoom and the look ahead goes back to nothing,
# so the camera settles on the player; running again takes it back out and the look ahead returns.
# Moving into a zone with its own Zoom, the camera eases to it, with no step bigger than 0.02, and
# back out of it to 1. A closer zoom shortens the look ahead in the same proportion. Standing still
# in a zone with its own Zoom, the two zooms multiply. A zone with Fit Height closes the camera in
# until the zone, its Bottom Margin and Fit Headroom fill the screen's height, and a zone too low for
# that stops at Max Zone Zoom with its bottom still on the screen's bottom. With Auto Zoom and the
# level's tiles, a corridor with another passage above it, behind rock, closes the camera in until
# the screen's top edge is on that passage's bottom; a corridor whose air goes straight up, an opening
# and not another passage, keeps the normal view. The screen size comes from the camera itself, as
# the engine takes it: in headless runs the window is 64 × 64 and the stretch would make the screen
# 1920 × 1920, so the test first gives the window the game's screen size.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_zoom.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://camera/game_camera.tscn")
const CAVE_TILES: TileSet = preload("res://scenes/levels/Lust/cave_placeholder_tiles.tres")
## The Auto Zoom case, in tiles: the columns of the corridor and the passage, the passage's rows, the
## corridor's rows and its floor's row; rock fills the rest of the rows from 0 to 20.
const AUTO_COLUMNS: int = 40
const PASSAGE_ROWS: Vector2i = Vector2i(2, 5)
const CORRIDOR_ROWS: Vector2i = Vector2i(10, 16)
const FLOOR_ROW: int = 17
const LAST_ROW: int = 20
## A smoothing so fast that one step closes the whole distance, to see where the camera heads.
const INSTANT_SHARPNESS: float = 1.0e6
## Steps for the camera to settle when called by hand: 4 s.
const SETTLE_STEPS: int = 240
## How close two zooms must be to count as the same.
const SAME_ZOOM: float = 0.01
## The largest change of zoom one step may make, for the change to count as smooth.
const LARGEST_ZOOM_STEP: float = 0.02
## How close two distances must be to count as the same, in px.
const SAME_DISTANCE: float = 1.0
## The zone zoom of the cases.
const ZONE_ZOOM: float = 1.4
## Physics frames the player runs before stopping: 1 s.
const RUN_FRAMES: int = 60
## How long before Idle Delay the case checks that nothing has changed yet, in s.
const EARLY: float = 0.5
## How long after Idle Delay the cases wait for the zoom to settle, in s.
const ZOOM_SETTLE_TIME: float = 3.5
## How far right the look-ahead case moves the player, past Turn Threshold, in px.
const COMMIT_MOVE: float = 400.0
## The Fit Height case: a zone this tall fills the screen below Max Zone Zoom, one this tall would
## need more; both with this Bottom Margin, in px.
const FIT_ZONE_HEIGHT: float = 400.0
const LOW_FIT_ZONE_HEIGHT: float = 200.0
const FIT_MARGIN: float = 96.0


func _initialize() -> void:
	# Nodes added before the first frame only get _ready on it, and the cases need the camera ready
	# as soon as it is added.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(await _standing_still_the_camera_settles_on_the_player_and_closes_in())
	results.append(await _in_a_zone_with_zoom_the_camera_eases_to_it_and_back())
	results.append(await _a_closer_zoom_shortens_the_look_ahead())
	results.append(await _standing_still_in_a_zone_with_zoom_multiplies_the_zooms())
	results.append(await _a_zone_with_fit_height_fills_the_screen_s_height())
	results.append(await _auto_zoom_hides_a_passage_behind_rock_but_not_an_opening())
	finish(results)


## The player runs right, so the camera leads to the right, and stops. Half a second before Idle
## Delay, the zoom is still 1 and the camera still leads. Once the zoom settles, it is Idle Zoom and
## the lead is gone. Running again, the zoom goes back to 1 and the lead comes back.
func _standing_still_the_camera_settles_on_the_player_and_closes_in() -> bool:
	var platform: StaticBody2D = make_platform(-2000.0, 40000.0)
	var player: Player = await spawn_on_floor(Vector2(0.0, -2.0))
	if player == null:
		platform.queue_free()
		return report(false, "Standing still: the player never landed")
	var input: StandInInput = put_a_stand_in(player)
	var camera: GameCamera = _spawn_camera(player)
	var stats: CameraStats = camera.stats
	input.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	input.run_direction = 0.0
	await wait_until(func() -> bool: return player.velocity.length() < GameCamera.IDLE_SPEED)
	await wait_frames(_frames(stats.idle_delay - EARLY))
	var early_zoom: float = camera.zoom.x
	var early_lead: float = camera.get_look_ahead()
	await wait_frames(_frames(EARLY + ZOOM_SETTLE_TIME))
	var idle_zoom: float = camera.zoom.x
	var idle_lead: float = camera.get_look_ahead()
	input.run_direction = 1.0
	await wait_frames(_frames(ZOOM_SETTLE_TIME))
	var moving_zoom: float = camera.zoom.x
	var moving_lead: float = camera.get_look_ahead()
	await _remove_all([camera, player, platform])
	return report(absf(early_zoom - 1.0) < SAME_ZOOM and early_lead > SAME_DISTANCE
			and absf(idle_zoom - stats.idle_zoom) < SAME_ZOOM and absf(idle_lead) < SAME_DISTANCE
			and absf(moving_zoom - 1.0) < SAME_ZOOM and moving_lead > SAME_DISTANCE,
			"Standing still: %.1f s in, zoom %.3f and lead %.0f px; settled, zoom %.3f (Idle Zoom %.2f) and lead %.1f px; running again, zoom %.3f and lead %.0f px"
			% [stats.idle_delay - EARLY, early_zoom, early_lead, idle_zoom, stats.idle_zoom, idle_lead,
			moving_zoom, moving_lead])


## Moving from a zone with the normal zoom into one with Zoom 1.4 and back, by hand: the zoom gets
## there with no step bigger than 0.02, and back to 1 the same way.
func _in_a_zone_with_zoom_the_camera_eases_to_it_and_back() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var normal: CameraZone = _make_zone(Rect2(Vector2.ZERO, Vector2(4.0, 1.0) * screen), 1.0)
	var close: CameraZone = _make_zone(Rect2(Vector2(4.0, 0.0) * screen, Vector2(4.0, 1.0) * screen), ZONE_ZOOM)
	var player: Player = _spawn_still_player(Vector2(2.0, 0.5) * screen)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	player.global_position = Vector2(6.0, 0.5) * screen
	var largest_in: float = _settle_by_hand(camera)
	var zoom_in: float = camera.zoom.x
	player.global_position = Vector2(2.0, 0.5) * screen
	var largest_out: float = _settle_by_hand(camera)
	var zoom_out: float = camera.zoom.x
	await _remove_all([camera, player, normal, close])
	return report(absf(zoom_in - ZONE_ZOOM) < SAME_ZOOM and absf(zoom_out - 1.0) < SAME_ZOOM
			and largest_in < LARGEST_ZOOM_STEP and largest_out < LARGEST_ZOOM_STEP,
			"Into a zone with Zoom %.1f: reached %.4f, largest step %.4f; back out: reached %.4f, largest step %.4f"
			% [ZONE_ZOOM, zoom_in, largest_in, zoom_out, largest_out])


## In a big zone with Zoom 1.4, once the player commits to the right, the lead settles at Look Ahead
## Distance divided by the zoom.
func _a_closer_zoom_shortens_the_look_ahead() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone: CameraZone = _make_zone(Rect2(Vector2.ZERO, 8.0 * screen), ZONE_ZOOM)
	var start: Vector2 = 4.0 * screen
	var player: Player = _spawn_still_player(start)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	player.global_position = start + Vector2(COMMIT_MOVE, 0.0)
	_settle_by_hand(camera)
	var lead: float = camera.get_look_ahead()
	var expected: float = camera.stats.look_ahead_distance / ZONE_ZOOM
	await _remove_all([camera, player, zone])
	return report(absf(lead - expected) < SAME_DISTANCE,
			"Look ahead at Zoom %.1f: %.1f px, expected %.1f" % [ZONE_ZOOM, lead, expected])


## Standing still on a floor inside a zone with Zoom 1.4, the zoom settles at 1.4 times Idle Zoom.
func _standing_still_in_a_zone_with_zoom_multiplies_the_zooms() -> bool:
	var platform: StaticBody2D = make_platform(-2000.0, 2000.0)
	var zone: CameraZone = _make_zone(Rect2(-2000.0, -2000.0, 4000.0, 2100.0), ZONE_ZOOM)
	var player: Player = await spawn_on_floor(Vector2(0.0, -2.0))
	if player == null:
		await _remove_all([platform, zone])
		return report(false, "Standing still in a zone: the player never landed")
	put_a_stand_in(player)
	var camera: GameCamera = _spawn_camera(player)
	await wait_frames(_frames(camera.stats.idle_delay + ZOOM_SETTLE_TIME))
	var zoom: float = camera.zoom.x
	var expected: float = ZONE_ZOOM * camera.stats.idle_zoom
	await _remove_all([camera, player, zone, platform])
	return report(absf(zoom - expected) < SAME_ZOOM,
			"Standing still in a zone with Zoom %.1f: zoom %.3f, expected %.3f" % [ZONE_ZOOM, zoom, expected])


## A zone 400 px tall with Fit Height, anchored at the bottom with Bottom Margin 96: the zoom settles
## where its 400 px, the 96 under it and the 96 of Fit Headroom over it fill the screen's height,
## with the screen's bottom edge on the margin's bottom and its top edge Fit Headroom over the zone.
## A zone 200 px tall would need more than Max Zone Zoom: the zoom stops there, with the screen's
## bottom edge still on the margin's bottom.
func _a_zone_with_fit_height_fills_the_screen_s_height() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var found: Array[String] = []
	var right: bool = true
	for height: float in [FIT_ZONE_HEIGHT, LOW_FIT_ZONE_HEIGHT]:
		var zone: CameraZone = _make_zone(Rect2(0.0, 0.0, 3.0 * screen.x, height), 1.0)
		zone.fit_height = true
		zone.vertical_anchor = 1.0
		zone.bottom_margin = FIT_MARGIN
		var player: Player = _spawn_still_player(Vector2(1.5 * screen.x, height / 2.0))
		var camera: GameCamera = _spawn_camera_by_hand(player)
		_settle_by_hand(camera)
		var stats: CameraStats = camera.stats
		var filled: float = height + FIT_MARGIN + stats.fit_headroom
		var expected_zoom: float = clampf(screen.y / filled, 1.0, stats.max_zone_zoom)
		var half_height: float = screen.y / (2.0 * camera.zoom.y)
		var bottom_edge: float = camera.global_position.y + half_height
		var top_edge: float = camera.global_position.y - half_height
		right = right and absf(camera.zoom.x - expected_zoom) < SAME_ZOOM
		right = right and absf(bottom_edge - (height + FIT_MARGIN)) < SAME_DISTANCE
		if expected_zoom < stats.max_zone_zoom:
			right = right and absf(top_edge + stats.fit_headroom) < SAME_DISTANCE
		found.append("zone %.0f px tall: zoom %.3f (expected %.3f), screen from y %.1f to %.1f"
				% [height, camera.zoom.x, expected_zoom, top_edge, bottom_edge])
		await _remove_all([camera, player, zone])
	return report(right, "Fit Height: %s" % "; ".join(found))


## A corridor zone, its floor's row included, anchored at the bottom with Bottom Margin 96, in tiles
## where another passage lies above it behind four rows of rock: the camera closes in until the
## screen's top edge is on the passage's bottom, given the tiles or, with Level Tiles left empty,
## finding them beside it. With the rock between them taken away, the air goes straight up from the
## corridor, and the camera keeps the normal view.
func _auto_zoom_hides_a_passage_behind_rock_but_not_an_opening() -> bool:
	var tile: float = CAVE_TILES.tile_size.y
	var found: Array[String] = []
	var right: bool = true
	for setup: Array in [[false, true], [false, false], [true, true]]:
		var open: bool = setup[0]
		var given: bool = setup[1]
		var tiles: TileMapLayer = _make_tiles(open)
		var zone_rect: Rect2 = Rect2(0.0, CORRIDOR_ROWS.x * tile, AUTO_COLUMNS * tile,
				(FLOOR_ROW + 1 - CORRIDOR_ROWS.x) * tile)
		var zone: CameraZone = _make_zone(zone_rect, 1.0)
		zone.vertical_anchor = 1.0
		zone.bottom_margin = FIT_MARGIN
		var player: Player = _spawn_still_player(Vector2(zone_rect.get_center().x, FLOOR_ROW * tile))
		var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
		camera.player = player
		if given:
			camera.level_tiles = tiles
		camera.stats = camera.stats.duplicate() as CameraStats
		camera.stats.follow_sharpness = INSTANT_SHARPNESS
		root.add_child(camera)
		camera.set_physics_process(false)
		_settle_by_hand(camera)
		var screen_height: float = camera.get_viewport_rect().size.y
		var top_edge: float = camera.global_position.y - screen_height / (2.0 * camera.zoom.y)
		var passage_bottom: float = (PASSAGE_ROWS.y + 1) * tile
		var expected_zoom: float = 1.0
		if not open:
			expected_zoom = screen_height / (zone_rect.end.y + FIT_MARGIN - passage_bottom)
			right = right and absf(top_edge - passage_bottom) < SAME_DISTANCE
		right = right and absf(camera.zoom.x - expected_zoom) < SAME_ZOOM
		found.append("%s, tiles %s: zoom %.3f (expected %.3f), screen's top edge at y %.1f"
				% ["opening" if open else "passage behind rock", "given" if given else "found",
				camera.zoom.x, expected_zoom, top_edge])
		await _remove_all([camera, player, zone, tiles])
	return report(right, "Auto Zoom, the passage's bottom at y %.0f: %s"
			% [(PASSAGE_ROWS.y + 1) * tile, "; ".join(found)])


## Rock from row 0 to LAST_ROW across AUTO_COLUMNS, with the corridor's and the passage's rows air;
## if open, the rows between them are air too.
func _make_tiles(open: bool) -> TileMapLayer:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = CAVE_TILES
	for y: int in LAST_ROW + 1:
		var corridor: bool = y >= CORRIDOR_ROWS.x and y <= CORRIDOR_ROWS.y
		var passage: bool = y >= PASSAGE_ROWS.x and y <= PASSAGE_ROWS.y
		var between: bool = y > PASSAGE_ROWS.y and y < CORRIDOR_ROWS.x
		if corridor or passage or (open and between):
			continue
		for x: int in AUTO_COLUMNS:
			tiles.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	root.add_child(tiles)
	return tiles


## A zone with one rectangle and the given zoom, under the root.
func _make_zone(rect: Rect2, zone_zoom: float) -> CameraZone:
	var zone: CameraZone = CameraZone.new()
	zone.zoom = zone_zoom
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	zone.add_child(collision)
	root.add_child(zone)
	return zone


## A player that does not move on its own: its physics step is off, so only the case moves it, and
## it never stands on a floor, so the camera never closes in on it.
func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


## An instant camera following player with its own copy of Stats, physics step off so that the case
## calls it by hand.
func _spawn_camera_by_hand(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.follow_sharpness = INSTANT_SHARPNESS
	root.add_child(camera)
	camera.set_physics_process(false)
	return camera


func _spawn_camera(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	root.add_child(camera)
	return camera


## Steps the camera by hand for 4 s and returns the largest change of zoom in one step.
func _settle_by_hand(camera: GameCamera) -> float:
	var largest: float = 0.0
	for _step_index: int in SETTLE_STEPS:
		var before: float = camera.zoom.x
		camera._physics_process(_step())
		largest = maxf(largest, absf(camera.zoom.x - before))
	return largest


## The number of physics frames in seconds.
func _frames(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)


## The length of one physics step, in seconds.
func _step() -> float:
	return 1.0 / Engine.physics_ticks_per_second


func _remove_all(nodes: Array) -> void:
	for node: Node in nodes:
		node.queue_free()
	await physics_frame
