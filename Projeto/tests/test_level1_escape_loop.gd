# Checks the way back round from the last hall of level 1's phase 3 (#271): the man meets the biggest dog in the
# hall, turns back west, climbs the column up to gate 3, which the dog's ring opened, runs along the corridor
# behind it and drops down its chimney into the hall again, past where the dog stood, with the dog after him all
# the way. On level1.tscn: the hall's west end climbs in steps no higher than MOST_STEP, which he always reaches
# without a wall and the dog jumps; the column's way up to gate 3 has its platforms fixed, none left to collapse,
# so the dog behind him finds each one he stood on; the biggest dog's body fits down the chimney, from the
# corridor's floor to the hall's; and its Max Drop is as deep as the chimney. Whether the dog goes that way after
# him is not checked here.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_escape_loop.gd
extends "res://tests/support/player_test.gd"

const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
const DOG_PATH: NodePath = ^"Dogs/P3BiggestDog"
const GATE_PATH: NodePath = ^"Gates/P3Gate3"
const CHIMNEY_ZONE_PATH: NodePath = ^"CameraZones/ZoneP3Gate3Shaft/CollisionShape2D"
const TILE: float = 48.0
## The world's physics layer, the rock's.
const WORLD_LAYER: int = 1
## The highest step, in px, on the way up from the hall: the highest platform the man always reaches
## without a wall (docs/nivel1_desenho.md, section 11, item 16), within the biggest dog's Jump Height.
const MOST_STEP: float = 192.0
## The hall's west end, in tile columns: from the bottom-left room's floor to the hall's floor.
const WEST_END_FROM_COLUMN: int = 74
const WEST_END_TO_COLUMN: int = 104
## Where the rays that find the floors of the west end start: in the air above all of them, the row
## below the hall's ceiling.
const WEST_END_AIR_Y: float = 9432.0
## How far down, in px, those rays look.
const RAY_DEPTH: float = 2000.0
## The column the man climbs, west of gate 3, in tile columns.
const COLUMN_FROM_COLUMN: int = 65
## The levels' TileSet: the one-way platform is the rock tile's alternative 1.
const ONE_WAY_ALTERNATIVE: int = 1
## The one-way platform tiles in the column: the 8 platforms that collapsed before (#271).
const FIXED_PLATFORM_TILES: int = 28
## How far apart, in px, the dog's body is tried down the chimney.
const CHIMNEY_STEP: float = 12.0
## Heights in px: one in the corridor behind gate 3, above its floor, from where a ray finds that floor,
## the top of the chimney; one halfway down the chimney, where rays find its walls.
const CORRIDOR_AIR_Y: float = 8712.0
const CHIMNEY_HALFWAY_Y: float = 9120.0
## How far, in px, the rays that find the chimney's walls look to each side.
const WALL_RAY: float = 400.0
## A body is tried this far, in px, off the floor or wall it would touch, so touching is no overlap.
const CLEARANCE: float = 2.0


func _initialize() -> void:
	var level: Node2D = (load(LEVEL_PATH) as PackedScene).instantiate() as Node2D
	root.add_child(level)
	await physics_frame
	await physics_frame
	var results: Array[bool] = []
	results.append(_the_hall_s_west_end_climbs_in_steps_the_man_and_the_dog_take(level))
	results.append(_the_way_up_to_gate_3_has_fixed_platforms_only(level))
	results.append(_the_biggest_dog_fits_down_the_chimney(level))
	results.append(_the_biggest_dog_drops_as_deep_as_the_chimney(level))
	level.queue_free()
	await physics_frame
	finish(results)


## Rays straight down at the middle of each column of the hall's west end find each floor; going west,
## from the hall's floor up to the bottom-left room's, no floor is more than MOST_STEP above the one
## before it.
func _the_hall_s_west_end_climbs_in_steps_the_man_and_the_dog_take(level: Node2D) -> bool:
	var space: PhysicsDirectSpaceState2D = level.get_world_2d().direct_space_state
	var floors: Array[float] = []
	for column: int in range(WEST_END_TO_COLUMN, WEST_END_FROM_COLUMN - 1, -1):
		var x: float = (column + 0.5) * TILE
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
				Vector2(x, WEST_END_AIR_Y), Vector2(x, WEST_END_AIR_Y + RAY_DEPTH), WORLD_LAYER)
		var hit: Dictionary = space.intersect_ray(ray)
		floors.append((hit["position"] as Vector2).y if not hit.is_empty() else INF)
	var highest_step: float = 0.0
	for i: int in range(1, floors.size()):
		highest_step = maxf(highest_step, floors[i - 1] - floors[i])
	var dog_floor: float = (level.get_node(DOG_PATH) as Node2D).global_position.y
	var from_the_hall: bool = is_equal_approx(floors[0], dog_floor)
	return report(from_the_hall and highest_step <= MOST_STEP,
			("Hall's west end, columns %d to %d: starts on the dog's floor %s; highest step %.0f px (at most "
			+ "%.0f); floors %s") % [WEST_END_TO_COLUMN, WEST_END_FROM_COLUMN, from_the_hall, highest_step,
			MOST_STEP, floors])


## In the column between gate 3's floor and the hall's, west of the gate, no collapsing platform is left,
## one nudged by hand up to half a tile above the gate's floor counting as on it, and the one-way platform
## tiles are FIXED_PLATFORM_TILES, the platforms that collapsed before, so none was just taken away.
func _the_way_up_to_gate_3_has_fixed_platforms_only(level: Node2D) -> bool:
	var gate: Node2D = level.get_node(GATE_PATH) as Node2D
	var hall_floor: float = (level.get_node(DOG_PATH) as Node2D).global_position.y
	var top: float = gate.global_position.y - TILE / 2.0
	var way_up: Rect2 = Rect2(COLUMN_FROM_COLUMN * TILE, top, gate.global_position.x - COLUMN_FROM_COLUMN * TILE,
			hall_floor - top)
	var collapsing: Array[String] = []
	for platform: Node in level.find_children("*", "CollapsingPlatform", true, false):
		if way_up.has_point((platform as Node2D).global_position):
			collapsing.append(String(platform.name))
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var fixed: int = 0
	for row: int in range(floori(way_up.position.y / TILE), ceili(way_up.end.y / TILE)):
		for column: int in range(floori(way_up.position.x / TILE), ceili(way_up.end.x / TILE)):
			var cell: Vector2i = Vector2i(column, row)
			if tiles.get_cell_source_id(cell) != -1 \
					and tiles.get_cell_alternative_tile(cell) == ONE_WAY_ALTERNATIVE:
				fixed += 1
	return report(collapsing.is_empty() and fixed == FIXED_PLATFORM_TILES,
			("The way up to gate 3 (%s): collapsing platforms %s (none), one-way platform tiles %d (%d)")
			% [way_up, collapsing, fixed, FIXED_PLATFORM_TILES])


## The biggest dog's body, tried down the chimney's middle, between the walls rays find halfway down it,
## from just under the corridor's floor to just over the hall's, CHIMNEY_STEP px at a time, overlaps no
## rock anywhere.
func _the_biggest_dog_fits_down_the_chimney(level: Node2D) -> bool:
	var dog: Demon = BIGGEST_SCENE.instantiate() as Demon
	var box: CollisionShape2D = dog.get_node(^"CollisionShape2D") as CollisionShape2D
	var body: RectangleShape2D = box.shape as RectangleShape2D
	var half: Vector2 = body.size / 2.0
	dog.free()
	var space: PhysicsDirectSpaceState2D = level.get_world_2d().direct_space_state
	var walls: Array[float] = _chimney_walls(level)
	var middle: float = (walls[0] + walls[1]) / 2.0
	var hall_floor: float = (level.get_node(DOG_PATH) as Node2D).global_position.y
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = body
	query.collision_mask = WORLD_LAYER
	var stuck_at: float = NAN
	var y: float = _corridor_floor(level, walls) + half.y + CLEARANCE
	while y <= hall_floor - half.y - CLEARANCE:
		query.transform = Transform2D(0.0, Vector2(middle, y))
		if not space.intersect_shape(query, 1).is_empty():
			stuck_at = y
			break
		y += CHIMNEY_STEP
	return report(is_nan(stuck_at), ("Biggest dog's body, %.0f px wide, down the chimney %.0f px wide at x = "
			+ "%.0f: overlaps rock at y = %s (nowhere)") % [body.size.x, walls[1] - walls[0], middle, stuck_at])


## From the corridor's floor at the chimney's lip, as rays find it, down to the hall's floor, the dog's,
## is no deeper than the biggest dog's Max Drop.
func _the_biggest_dog_drops_as_deep_as_the_chimney(level: Node2D) -> bool:
	var dog: Demon = BIGGEST_SCENE.instantiate() as Demon
	var max_drop: float = dog.stats.max_drop
	dog.free()
	var depth: float = (level.get_node(DOG_PATH) as Node2D).global_position.y \
			- _corridor_floor(level, _chimney_walls(level))
	return report(depth <= max_drop, "Chimney %.0f px deep; the biggest dog's Max Drop %.0f px"
			% [depth, max_drop])


## The x of the chimney's west and east walls, as rays from inside it find them halfway down.
func _chimney_walls(level: Node2D) -> Array[float]:
	var space: PhysicsDirectSpaceState2D = level.get_world_2d().direct_space_state
	var inside: Vector2 = Vector2((level.get_node(CHIMNEY_ZONE_PATH) as Node2D).global_position.x,
			CHIMNEY_HALFWAY_Y)
	var walls: Array[float] = []
	for way: float in [-1.0, 1.0]:
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(
				inside, inside + Vector2(way * WALL_RAY, 0.0), WORLD_LAYER))
		walls.append((hit["position"] as Vector2).x if not hit.is_empty() else inside.x + way * WALL_RAY)
	return walls


## The y of the corridor's floor just west of the chimney, walls its walls, as a ray straight down finds it.
func _corridor_floor(level: Node2D, walls: Array[float]) -> float:
	var space: PhysicsDirectSpaceState2D = level.get_world_2d().direct_space_state
	var above: Vector2 = Vector2(walls[0] - TILE / 2.0, CORRIDOR_AIR_Y)
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(
			above, above + Vector2(0.0, RAY_DEPTH), WORLD_LAYER))
	return (hit["position"] as Vector2).y if not hit.is_empty() else INF
