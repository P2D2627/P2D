# Checks Lust phase 2, built from its text map. The scene holds what the map says: its dogs and big dogs,
# the big ones painted black; spikes, collapsing platforms, and each gate with its own unlocker. With the
# gates shut, the air splits so that each gate can only be reached with its unlocker already reached: the
# start joins unlocker B and gate B's near side, and gate B's far side joins unlocker A and gate A's near
# side, and only gate A's far side joins the finish. The camera zones pass the checks every level shares,
# and none shows another path.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase_2.gd
extends "res://tests/support/player_test.gd"

const Checks = preload("res://tests/support/level_camera_checks.gd")
const SCENE_PATH: String = "res://scenes/levels/lust/lust_phase_2.tscn"
const MAP_PATH: String = "res://scenes/levels/lust/builders/lust_phase_2.txt"
const TILE: float = 48.0


func _initialize() -> void:
	# The headless window is 64 × 64, which the stretch makes a 1920 × 1920 screen.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var level: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var results: Array[bool] = []
	var map: String = FileAccess.get_file_as_string(MAP_PATH).split("---", true, 1)[1]
	results.append(_the_scene_holds_what_the_map_says(level, map))
	results.append(_big_dogs_are_black_and_dogs_are_not(level))
	results.append(_each_gate_has_its_own_unlocker(level))
	results.append(_the_gates_cannot_be_skipped(level))
	var tiles: TileMapLayer = level.get_node("Tiles") as TileMapLayer
	var zones: Array[CameraZone] = Checks.zones_of(level)
	var camera: GameCamera = level.get_node("GameCamera") as GameCamera
	for check: Array in [Checks.overlapping_zones_differ_in_area(zones),
			Checks.every_floor_is_in_a_zone(tiles, zones),
			Checks.no_zone_shows_another_path(tiles, zones, camera),
			Checks.every_zone_shows_wall_past_its_sides(tiles, zones, camera),
			Checks.every_floor_is_the_lower_limit(tiles, zones)]:
		results.append(report(check[0], check[1]))
	results.append(_the_player_starts_in_a_zone_anchored_at_the_bottom(level, zones))
	level.queue_free()
	await process_frame
	finish(results)


func _the_scene_holds_what_the_map_says(level: Node, map: String) -> bool:
	var dogs: int = 0
	var big_dogs: int = 0
	for node: Node in level.get_node("Dogs").get_children():
		if String(node.name).begins_with("BigDog"):
			big_dogs += 1
		else:
			dogs += 1
	var spike_tiles: int = 0
	for node: Node in level.get_node("Spikes").get_children():
		spike_tiles += (node as LethalSpikes).width_tiles
	var collapsing_tiles: int = 0
	for node: Node in level.get_node("CollapsingPlatforms").get_children():
		collapsing_tiles += (node as CollapsingPlatform).width_tiles
	var expected: Array[int] = [map.count("d"), map.count("D"), map.count("^"), map.count("=")]
	var found: Array[int] = [dogs, big_dogs, spike_tiles, collapsing_tiles]
	return report(found == expected and not expected.has(0),
			"Contents: dogs, big dogs, spike tiles, collapsing tiles %s, the map says %s" % [found, expected])


func _big_dogs_are_black_and_dogs_are_not(level: Node) -> bool:
	var wrong: Array[String] = []
	for node: Node in level.get_node("Dogs").get_children():
		var drawing: Polygon2D = node.get_node("Placeholder") as Polygon2D
		var is_black: bool = drawing.color.is_equal_approx(Color.BLACK)
		if is_black != String(node.name).begins_with("BigDog"):
			wrong.append(String(node.name))
	return report(wrong.is_empty(), "Colours: wrong on %s" % [wrong])


func _each_gate_has_its_own_unlocker(level: Node) -> bool:
	var unlocker_a: GateUnlocker = level.get_node("GateUnlockers/UnlockerA") as GateUnlocker
	var unlocker_b: GateUnlocker = level.get_node("GateUnlockers/UnlockerB") as GateUnlocker
	var gate_a: Gate = level.get_node("Gates/GateA") as Gate
	var gate_b: Gate = level.get_node("Gates/GateB") as Gate
	var paired: bool = unlocker_a.gates == [gate_a] and unlocker_b.gates == [gate_b]
	return report(paired, "Gates: A opens %s, B opens %s" % [unlocker_a.gates, unlocker_b.gates])


## Floods the air from the start with the gates shut, then again past each gate in the order of the game.
func _the_gates_cannot_be_skipped(level: Node) -> bool:
	var tiles: TileMapLayer = level.get_node("Tiles") as TileMapLayer
	var gate_a: Gate = level.get_node("Gates/GateA") as Gate
	var gate_b: Gate = level.get_node("Gates/GateB") as Gate
	var shut: Dictionary[Vector2i, bool] = {}
	for gate: Gate in [gate_a, gate_b]:
		for cell: Vector2i in _cells_of_gate(tiles, gate):
			shut[cell] = true
	var player: Node2D = level.get_node("Player") as Node2D
	var start: Dictionary[Vector2i, bool] = _flood(tiles, shut, _standing_cell(tiles, player.global_position))
	var finish_cell: Vector2i = _standing_cell(tiles, (level.get_node("PhaseExit") as Node2D).global_position)
	var unlocker_a: Vector2i = _standing_cell(tiles, (level.get_node("GateUnlockers/UnlockerA") as Node2D).global_position)
	var unlocker_b: Vector2i = _standing_cell(tiles, (level.get_node("GateUnlockers/UnlockerB") as Node2D).global_position)
	var gate_b_near: bool = _touches(start, _cells_of_gate(tiles, gate_b))
	# Past gate B: the air the far side of it joins.
	var past_b: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in _cells_of_gate(tiles, gate_b):
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + side
			if not shut.has(next) and tiles.get_cell_source_id(next) == -1 and not start.has(next):
				past_b.merge(_flood(tiles, shut, next))
	var gate_a_near: bool = _touches(past_b, _cells_of_gate(tiles, gate_a))
	var ok: bool = (start.has(unlocker_b) and gate_b_near and not start.has(unlocker_a) and not start.has(finish_cell)
			and past_b.has(unlocker_a) and gate_a_near and not past_b.has(finish_cell))
	return report(ok, "Order: start joins unlocker B %s, gate B %s, unlocker A %s, finish %s; past gate B joins unlocker A %s, gate A %s, finish %s"
			% [start.has(unlocker_b), gate_b_near, start.has(unlocker_a), start.has(finish_cell), past_b.has(unlocker_a),
			gate_a_near, past_b.has(finish_cell)])


func _cells_of_gate(tiles: TileMapLayer, gate: Gate) -> Array[Vector2i]:
	var left: Vector2 = gate.global_position - Vector2(gate.width_tiles * TILE / 2.0, gate.height_tiles * TILE)
	var first: Vector2i = tiles.local_to_map(tiles.to_local(left + Vector2.ONE))
	var cells: Array[Vector2i] = []
	for y: int in gate.height_tiles:
		for x: int in gate.width_tiles:
			cells.append(first + Vector2i(x, y))
	return cells


func _standing_cell(tiles: TileMapLayer, feet: Vector2) -> Vector2i:
	return tiles.local_to_map(tiles.to_local(feet - Vector2(0.0, TILE / 2.0)))


func _flood(tiles: TileMapLayer, shut: Dictionary[Vector2i, bool], from: Vector2i) -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {}
	var used: Rect2i = tiles.get_used_rect()
	var stack: Array[Vector2i] = [from]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		if seen.has(cell) or shut.has(cell) or not used.has_point(cell):
			continue
		# One-way platforms are not rock: the man goes up through them.
		var is_rock: bool = tiles.get_cell_source_id(cell) != -1 and tiles.get_cell_alternative_tile(cell) == 0
		if is_rock:
			continue
		seen[cell] = true
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			stack.append(cell + step)
	return seen


func _touches(air: Dictionary[Vector2i, bool], cells: Array[Vector2i]) -> bool:
	for cell: Vector2i in cells:
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			if air.has(cell + step):
				return true
	return false


func _the_player_starts_in_a_zone_anchored_at_the_bottom(level: Node, zones: Array[CameraZone]) -> bool:
	var start: Vector2 = (level.get_node("Player") as Node2D).global_position
	var found: CameraZone = null
	for zone: CameraZone in zones:
		if zone.has_point(start):
			found = zone
	return report(found != null and is_equal_approx(found.vertical_anchor, 1.0),
			"Start: at %s in zone %s" % [start, found.name if found != null else &"none"])
