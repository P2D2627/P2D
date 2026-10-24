# Checks the camera zones of Lust phase 1, the cave, with the checks every level shares (see
# support/level_camera_checks.gd); and at the start, once the camera settles on the player
# standing still, the screen's bottom edge is three tiles under the hall's floor.
# The headless window is 64 × 64, so the test first gives it the game's screen size.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase1_zones.gd
extends "res://tests/support/player_test.gd"

const Checks = preload("res://tests/support/level_camera_checks.gd")
const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/Lust/LustLevel_Phase1_Cave.tscn")
const TILE: float = 48.0
## The start hall's floor: the top of its rock row.
const HALL_FLOOR: float = 103.0 * TILE
const FLOOR_TILES_SHOWN: float = 3.0
## How long the camera takes to settle once it starts closing in, in s.
const ZOOM_SETTLE_TIME: float = 3.5
const SAME_SPOT: float = 0.5


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var level: Node = LEVEL_SCENE.instantiate()
	root.add_child(level)
	var tiles: TileMapLayer = level.get_node("Cave") as TileMapLayer
	var zones: Array[CameraZone] = Checks.zones_of(level)
	var results: Array[bool] = []
	for check: Array in [Checks.overlapping_zones_differ_in_area(zones),
			Checks.every_floor_is_in_a_zone(tiles, zones),
			Checks.every_lookout_has_a_floor_and_shows_only_its_way(tiles, Checks.lookouts_of(level), [])]:
		results.append(report(check[0], check[1]))
	results.append(_the_player_starts_in_a_zone_anchored_at_the_bottom(level, zones))
	results.append(await _at_the_start_the_floor_is_at_the_bottom_of_the_screen(level))
	level.queue_free()
	await process_frame
	finish(results)


func _the_player_starts_in_a_zone_anchored_at_the_bottom(level: Node, zones: Array[CameraZone]) -> bool:
	var start: Vector2 = (level.get_node("Player") as Node2D).global_position
	var found: CameraZone = null
	for zone: CameraZone in zones:
		if zone.has_point(start):
			found = zone
	return report(found != null and is_equal_approx(found.vertical_anchor, 1.0),
			"Start %s: in zone %s, anchor %s" % [start, found.name if found != null else "none",
			found.vertical_anchor if found != null else -1.0])


func _at_the_start_the_floor_is_at_the_bottom_of_the_screen(level: Node) -> bool:
	var camera: GameCamera = level.get_node("GameCamera") as GameCamera
	await wait_frames(roundi((camera.stats.idle_delay + ZOOM_SETTLE_TIME) * Engine.physics_ticks_per_second))
	var bottom_edge: float = camera.global_position.y + camera.get_viewport_rect().size.y / (2.0 * camera.zoom.y)
	var expected: float = HALL_FLOOR + FLOOR_TILES_SHOWN * TILE
	return report(absf(bottom_edge - expected) < SAME_SPOT,
			"At the start, in zone %s, zoom %.3f: the screen's bottom edge at y %.1f, expected %.1f (%.0f tiles under the floor at %.0f)"
			% [camera.get_zone_name(), camera.zoom.x, bottom_edge, expected, FLOOR_TILES_SHOWN, HALL_FLOOR])

