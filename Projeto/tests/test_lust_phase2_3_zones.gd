# Checks the camera zones and lookouts of Lust phases 2 and 3, drawn with the rules of phase 1, with
# the checks every level shares (see support/level_camera_checks.gd), that no zone shows another path
# nor the level below its floor, that a zone limited across shows wall past its sides rather than the
# level's inside, and that the player starts in a zone anchored at the bottom. In phase 3 a lookout
# may be boarded from a moving platform instead of a floor.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase2_3_zones.gd
extends "res://tests/support/player_test.gd"

const Checks = preload("res://tests/support/level_camera_checks.gd")
const LEVELS: Array[String] = [
	"res://scenes/levels/Lust/LustLevel_Phase2.tscn",
	"res://scenes/levels/Lust/LustLevel_Phase3.tscn",
]


func _initialize() -> void:
	# The headless window is 64 × 64, which the stretch makes a 1920 × 1920 screen.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	for path: String in LEVELS:
		var level: Node = (load(path) as PackedScene).instantiate()
		root.add_child(level)
		var tiles: TileMapLayer = level.get_node("Cave") as TileMapLayer
		var zones: Array[CameraZone] = Checks.zones_of(level)
		var platforms: Array[Node2D] = []
		for node: Node in level.find_children("*", "AnimatableBody2D", true, false):
			if node is CyclePlatform:
				platforms.append(node as Node2D)
		for check: Array in [Checks.overlapping_zones_differ_in_area(zones),
				Checks.every_floor_is_in_a_zone(tiles, zones),
				Checks.every_lookout_has_a_floor_and_shows_only_its_way(tiles, Checks.lookouts_of(level),
						platforms)]:
			results.append(report(check[0], "%s: %s" % [level.name, check[1]]))
		var camera: GameCamera = level.get_node("GameCamera") as GameCamera
		var others: Array = Checks.no_zone_shows_another_path(tiles, zones, camera)
		results.append(report(others[0], "%s: %s" % [level.name, others[1]]))
		var walls: Array = Checks.every_zone_shows_wall_past_its_sides(tiles, zones, camera)
		results.append(report(walls[0], "%s: %s" % [level.name, walls[1]]))
		var floors: Array = Checks.every_floor_is_the_lower_limit(tiles, zones)
		results.append(report(floors[0], "%s: %s" % [level.name, floors[1]]))
		results.append(_the_player_starts_in_a_zone_anchored_at_the_bottom(level, zones))
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
			"%s: start %s in zone %s" % [level.name, start, found.name if found != null else "none"])
