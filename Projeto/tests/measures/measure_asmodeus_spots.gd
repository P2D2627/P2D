# Looks at every floor of level 1 the man can stand on, out of the brambles and hazards, a column
# every COLUMN px, and asks
# Asmodeus's find_spot() where she would stand to talk to him there, facing right and facing left.
# Prints, per camera zone (the one zone_at() gives, as the offers for his deaths count them), how
# many floors it has, how often she stands in front of him and behind him, and where she finds no
# spot and so falls back to standing in front of him at his height: those floors are the map's to
# fix. Writes a few of each case to OUT_PATH for screenshots. It checks nothing: the exit code is 1
# only if the level has no Asmodeus or no camera zones.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_asmodeus_spots.gd
extends "res://tests/support/base_test.gd"

const SCENE_PATH: String = "res://scenes/levels/lust/level1.tscn"
## With this event, Velvet does not stop the man to talk.
const VELVET_MET: StringName = &"velvet_met"
## Every how many px a column of floors is looked at: half a tile.
const COLUMN: float = 24.0
## Every how many px down a column it looks for where the solid starts.
const ROW: float = 8.0
## How far apart, in px, two floors with no spot may be and still print as one stretch.
const STRETCH_GAP: float = COLUMN * 1.5
## How many of each case go to OUT_PATH, each from a different zone where it can.
const EXAMPLES: int = 3
const OUT_PATH: String = "user://asmodeus_spots.json"

var _floor_layers: int = 0
var _wall_layers: int = 0
var _man: Vector2 = Vector2.ZERO
var _dangers: Array[Rect2] = []


func _initialize() -> void:
	await process_frame
	(root.get_node(^"GameState") as GameProgress).mark_event(VELVET_MET)
	var level: Level = (load(SCENE_PATH) as PackedScene).instantiate() as Level
	root.add_child(level)
	for i: int in 3:
		await physics_frame
	var asmodeus: Asmodeus = level.get_node_or_null(^"Asmodeus") as Asmodeus
	if asmodeus == null:
		printerr("Level 1 has no Asmodeus.")
		quit(1)
		return
	_floor_layers = asmodeus.floor_layers
	_wall_layers = asmodeus.wall_layers
	_find_dangers(asmodeus)
	var collision: CollisionShape2D = level.player.get_node(^"CollisionShape2D") as CollisionShape2D
	_man = (collision.shape as RectangleShape2D).size
	var bounds: Rect2 = Rect2()
	var zone_count: int = 0
	for node: Node in get_nodes_in_group(CameraZone.GROUP):
		var zone: CameraZone = node as CameraZone
		if zone == null or not level.is_ancestor_of(zone):
			continue
		bounds = zone.get_limits() if zone_count == 0 else bounds.merge(zone.get_limits())
		zone_count += 1
	if zone_count == 0:
		printerr("Level 1 has no camera zones.")
		quit(1)
		return
	var space: PhysicsDirectSpaceState2D = level.get_world_2d().direct_space_state
	# zone -> {"floors": int, "front": int, "behind": int, "none": Array[Vector2]}
	var by_zone: Dictionary = {}
	var cases: Dictionary = {"front_right": [], "front_left": [], "behind": [], "none": []}
	var x: float = bounds.position.x + COLUMN / 2.0
	while x < bounds.end.x:
		for feet: Vector2 in _floors_in_column(space, x, bounds.position.y, bounds.end.y):
			var zone_name: String = String(level.zone_at(feet - Vector2(0.0, 1.0)))
			if not by_zone.has(zone_name):
				by_zone[zone_name] = {"floors": 0, "front": 0, "behind": 0, "none": []}
			var tally: Dictionary = by_zone[zone_name]
			tally["floors"] += 1
			for facing: float in [1.0, -1.0]:
				var spot: Vector2 = asmodeus.find_spot(space, feet, facing)
				var case: String
				if not spot.is_finite():
					case = "none"
				elif signf(spot.x - feet.x) == facing:
					case = "front_right" if facing > 0.0 else "front_left"
					tally["front"] += 1
				else:
					case = "behind"
					tally["behind"] += 1
				if case == "none":
					if facing > 0.0:
						(tally["none"] as Array).append(feet)
				(cases[case] as Array).append({"zone": zone_name, "x": feet.x, "y": feet.y,
						"facing": facing})
		x += COLUMN
	_print(by_zone)
	_print_save_points(level, asmodeus, space)
	_write_examples(cases)
	quit(0)


## The floors the man fits on in the column at x, between top and bottom: where the solid starts
## below empty room, at its exact height.
func _floors_in_column(space: PhysicsDirectSpaceState2D, x: float, top: float,
		bottom: float) -> Array[Vector2]:
	var floors: Array[Vector2] = []
	var was_solid: bool = true
	var y: float = top
	while y < bottom:
		var solid: bool = _is_solid(space, Vector2(x, y))
		if solid and not was_solid:
			var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
					Vector2(x, y - ROW), Vector2(x, y + 1.0), _floor_layers)
			var hit: Dictionary = space.intersect_ray(ray)
			if not hit.is_empty():
				var feet: Vector2 = Vector2(x, (hit["position"] as Vector2).y)
				if _man_fits(space, feet):
					floors.append(feet)
		was_solid = solid
		y += ROW
	return floors


func _is_solid(space: PhysicsDirectSpaceState2D, point: Vector2) -> bool:
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = _floor_layers
	return not space.intersect_point(query, 1).is_empty()


func _man_fits(space: PhysicsDirectSpaceState2D, feet: Vector2) -> bool:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = _man
	query.shape = shape
	query.transform = Transform2D(0.0, feet - Vector2(0.0, _man.y / 2.0 + 1.0))
	query.collision_mask = _wall_layers
	if not space.intersect_shape(query, 1).is_empty():
		return false
	# Not where he stands in brambles or a hazard: he would be dead there.
	var body: Rect2 = Rect2(feet - Vector2(_man.x / 2.0, _man.y), _man)
	for danger: Rect2 in _dangers:
		if danger.intersects(body):
			return false
	return true


## The boxes of the shapes of the areas in Asmodeus's Danger Groups.
func _find_dangers(asmodeus: Asmodeus) -> void:
	for group: StringName in asmodeus.danger_groups:
		for node: Node in get_nodes_in_group(group):
			for child: Node in node.get_children():
				var collision: CollisionShape2D = child as CollisionShape2D
				if collision != null and not collision.disabled and collision.shape != null:
					_dangers.append(collision.global_transform * collision.shape.get_rect())


func _print(by_zone: Dictionary) -> void:
	var names: Array = by_zone.keys()
	names.sort()
	var floors: int = 0
	var nones: int = 0
	print("Zone: floors | she in front / behind (of both facings) | no spot")
	for zone_name: String in names:
		var tally: Dictionary = by_zone[zone_name]
		var none: Array = tally["none"]
		var both: int = int(tally["floors"]) * 2
		floors += int(tally["floors"])
		nones += none.size()
		print("%s: %d | %d%% / %d%% | %d%s" % [zone_name, tally["floors"],
				roundi(100.0 * tally["front"] / both), roundi(100.0 * tally["behind"] / both),
				none.size(), "" if none.is_empty() else "  " + _stretches(none)])
	print("All: %d floors, %d with no spot" % [floors, nones])


## Where she stands at each save point that starts a phase, where her phase talks come: on the
## floor under it, facing right and facing left.
func _print_save_points(level: Level, asmodeus: Asmodeus, space: PhysicsDirectSpaceState2D) -> void:
	print("Phase save points: where the man stands -> facing right / facing left")
	for node: Node in get_nodes_in_group(SavePoint.GROUP):
		var save_point: SavePoint = node as SavePoint
		if save_point == null or not level.is_ancestor_of(save_point) or save_point.starts_phase == 0:
			continue
		var from: Vector2 = save_point.global_position
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from,
				from + Vector2(0.0, 1000.0), _floor_layers)
		var hit: Dictionary = space.intersect_ray(ray)
		if hit.is_empty():
			print("  %s (phase %d): no floor under it" % [save_point.name, save_point.starts_phase])
			continue
		var feet: Vector2 = Vector2(from.x, (hit["position"] as Vector2).y)
		var sides: PackedStringArray = []
		for facing: float in [1.0, -1.0]:
			var spot: Vector2 = asmodeus.find_spot(space, feet, facing)
			if not spot.is_finite():
				sides.append("NO SPOT")
			else:
				sides.append("%s %d px" % ["front" if signf(spot.x - feet.x) == facing else "behind",
						roundi(absf(spot.x - feet.x))])
		print("  %s (phase %d) at %s, %s -> %s" % [save_point.name, save_point.starts_phase, feet,
				String(level.zone_at(feet - Vector2(0.0, 1.0))), " / ".join(sides)])


## The floors with no spot as stretches along the same height: "y=-480 x=1200..1296".
func _stretches(points: Array) -> String:
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	var parts: PackedStringArray = []
	var start: Vector2 = points[0]
	var last: Vector2 = points[0]
	for i: int in range(1, points.size() + 1):
		var point: Vector2 = points[i] if i < points.size() else Vector2.INF
		if point.is_finite() and is_equal_approx(point.y, last.y) and point.x - last.x <= STRETCH_GAP:
			last = point
			continue
		parts.append("y=%d x=%d..%d" % [roundi(start.y), roundi(start.x), roundi(last.x)])
		if point.is_finite():
			start = point
			last = point
	return "; ".join(parts)


## EXAMPLES of each case, from different zones where it can, spread along the level.
func _write_examples(cases: Dictionary) -> void:
	var chosen: Dictionary = {}
	for case: String in cases:
		var all: Array = cases[case]
		var picked: Array = []
		var zones_used: Array[String] = []
		if not all.is_empty():
			var stride: int = maxi(1, all.size() / (EXAMPLES * 4))
			var i: int = stride / 2
			while i < all.size() and picked.size() < EXAMPLES:
				var entry: Dictionary = all[i]
				if not zones_used.has(entry["zone"]):
					picked.append(entry)
					zones_used.append(entry["zone"])
				i += stride
		chosen[case] = picked
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(chosen, "  "))
	print("Examples in %s" % ProjectSettings.globalize_path(OUT_PATH))
