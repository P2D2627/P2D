# Test of the one-way platforms: the One Way tile of the levels' TileSet. The tile collides only by
# its top edge, on a layer in the player's mask, and nothing else of it collides. A jump from under
# a platform goes through it and lands on top.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_one_way_platform.gd
extends "res://tests/support/player_test.gd"

const TILE_SET: TileSet = preload("res://scenes/levels/Lust/cave_placeholder_tiles.tres")
## The One Way tile: an alternative of the solid block, with its polygon on its own physics layer.
const ONE_WAY_SOURCE: int = 0
const ONE_WAY_ATLAS: Vector2i = Vector2i(0, 0)
const ONE_WAY_ALTERNATIVE: int = 1
const SOLID_PHYSICS_LAYER: int = 0
const ONE_WAY_PHYSICS_LAYER: int = 1
## The platform's row of cells and its columns: its top edge is the row's top, at y = -144, lower
## than a full jump (240 px) and high enough for the player (96 px) to stand under it.
const PLATFORM_ROW: int = -3
const PLATFORM_COLUMNS: Array[int] = [-3, -2, -1, 0, 1, 2]
const TILE_SIZE: float = 48.0
const PLATFORM_TOP: float = PLATFORM_ROW * TILE_SIZE
## The solid floor runs from x = -FLOOR_HALF_WIDTH to x = FLOOR_HALF_WIDTH, with its top at y = 0.
const FLOOR_HALF_WIDTH: float = 1000.0
## Where the player starts, on the floor under the platform.
const UNDER_THE_PLATFORM: Vector2 = Vector2(0.0, -2.0)
## How far from a floor's top the feet may be and still stand on it, in px.
const ON_TOP: float = 1.0
## Frames to watch a jump: more than a full jump up and down (36).
const WATCH_FRAMES: int = 90


func _initialize() -> void:
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = TILE_SET
	for column: int in PLATFORM_COLUMNS:
		tiles.set_cell(Vector2i(column, PLATFORM_ROW), ONE_WAY_SOURCE, ONE_WAY_ATLAS,
				ONE_WAY_ALTERNATIVE)
	root.add_child(tiles)
	await physics_frame
	var results: Array[bool] = []
	results.append(_the_tile_is_one_way_on_a_layer_the_player_sees())
	results.append(await _a_jump_from_below_goes_through_and_lands_on_top())
	finish(results)


func _the_tile_is_one_way_on_a_layer_the_player_sees() -> bool:
	var source: TileSetAtlasSource = TILE_SET.get_source(ONE_WAY_SOURCE) as TileSetAtlasSource
	var tile: TileData = null
	if source.has_alternative_tile(ONE_WAY_ATLAS, ONE_WAY_ALTERNATIVE):
		tile = source.get_tile_data(ONE_WAY_ATLAS, ONE_WAY_ALTERNATIVE)
	var has_its_layer: bool = TILE_SET.get_physics_layers_count() > ONE_WAY_PHYSICS_LAYER
	var one_way: bool = tile != null and has_its_layer \
			and tile.get_collision_polygons_count(ONE_WAY_PHYSICS_LAYER) == 1 \
			and tile.is_collision_polygon_one_way(ONE_WAY_PHYSICS_LAYER, 0)
	var not_solid: bool = tile != null \
			and tile.get_collision_polygons_count(SOLID_PHYSICS_LAYER) == 0
	var layers: int = TILE_SET.get_physics_layer_collision_layer(ONE_WAY_PHYSICS_LAYER) \
			if has_its_layer else 0
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var player_sees_it: bool = layers != 0 and player.collision_mask & layers == layers
	player.free()
	return report(one_way and not_solid and player_sees_it, ("the One Way tile collides by its "
			+ "top edge only: %s; not on the solid layer: %s; on a layer in the player's mask: %s")
			% [one_way, not_solid, player_sees_it])


func _a_jump_from_below_goes_through_and_lands_on_top() -> bool:
	var player: Player = await spawn_on_floor(UNDER_THE_PLATFORM)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var highest_feet: float = player.position.y
	var left_the_floor: bool = false
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		highest_feet = minf(highest_feet, player.position.y)
		left_the_floor = left_the_floor or not player.is_on_floor()
		if left_the_floor and player.is_on_floor():
			break
	var went_through: bool = highest_feet < PLATFORM_TOP
	var on_top: bool = player.is_on_floor() and absf(player.position.y - PLATFORM_TOP) <= ON_TOP
	await remove_player(player)
	return report(went_through and on_top, ("a jump from under the platform: the feet rise to "
			+ "%.0f, above its top at %.0f: %s; lands on top: %s") % [highest_feet, PLATFORM_TOP,
			went_through, on_top])
