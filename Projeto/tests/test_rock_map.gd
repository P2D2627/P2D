# Checks RockMap, the reading of a level's tiles that the camera with one zoom and the measure of the screen's rock
# share, on a small map of rock tiles built here. A rock tile and a ramp are rock, also flipped or turned; an
# empty cell and a one-way platform, also flipped, are open, and so is the cell around the tiles, which the grid
# takes in. The open space joined to a cell
# in a room is the room, its platform included, but not an open cell that touches its corner only on the diagonal,
# with the box around the room, and it does not reach past the map; from rock there is none, and from a tunnel to
# the map's edge it reaches past it. In a shaft between rock, with a platform across it, the chimney's axis is its
# middle, also with the rule at exactly the shaft's width and height; a rule a tile narrower or a row taller finds
# none, nor does a row open to the outside.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --path Projeto --script res://tests/test_rock_map.gd
extends "res://tests/support/player_test.gd"

const TILE_SET: TileSet = preload("res://scenes/others/tilesets/cave_placeholder_tiles.tres")
const TILE: float = 48.0
## The tile set's one-way platform, the rock tile's other alternative, and one of its ramps.
const ONE_WAY_ALTERNATIVE: int = 1
const RAMP_ATLAS: Vector2i = Vector2i(1, 0)
## The map, in cells: rock all over, with a room, a shaft and a tunnel to the left edge carved in it, and an open
## cell that touches the room's lower right corner only on the diagonal.
const ROCK: Rect2i = Rect2i(0, 0, 30, 20)
const ROOM: Rect2i = Rect2i(2, 2, 10, 8)
const SHAFT: Rect2i = Rect2i(14, 2, 4, 14)
const TUNNEL: Rect2i = Rect2i(0, 12, 6, 2)
const CORNER_CELL: Vector2i = Vector2i(12, 10)
## A ramp in the room's lower left corner, a one-way platform across the room and one across the shaft.
const RAMP_CELL: Vector2i = Vector2i(2, 9)
const ROOM_PLATFORM: Rect2i = Rect2i(4, 6, 4, 1)
const SHAFT_PLATFORM: Rect2i = Rect2i(14, 10, 4, 1)
## In the room's top row, painted flipped or turned as the TileMap editor's Z and X keys paint them: a rock tile,
## a ramp and a one-way platform.
const FLIPPED_ROCK: Vector2i = Vector2i(8, 2)
const TURNED_RAMP: Vector2i = Vector2i(9, 2)
const FLIPPED_PLATFORM: Vector2i = Vector2i(10, 2)
const FLIP_H: int = TileSetAtlasSource.TRANSFORM_FLIP_H
const TURN: int = TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE
## Cells looked at: in the room above and below its platform, in the shaft, in the tunnel and in the rock.
const ABOVE_PLATFORM: Vector2i = Vector2i(5, 3)
const BELOW_PLATFORM: Vector2i = Vector2i(5, 8)
const SHAFT_CELL: Vector2i = Vector2i(15, 8)
const TUNNEL_CELL: Vector2i = Vector2i(3, 12)
const ROCK_CELL: Vector2i = Vector2i(0, 0)
## The chimney rule as the camera's Stats have it, in cells.
const CHIMNEY_WIDTH: int = 6
const CHIMNEY_HEIGHT: int = 6

var _tiles: TileMapLayer
var _rocks: RockMap


func _initialize() -> void:
	_tiles = _build_map()
	root.add_child(_tiles)
	_rocks = RockMap.new(_tiles)
	var results: Array[bool] = [_check_what_is_rock(), _check_the_open_space(), _check_the_chimneys()]
	finish(results)


## A rock tile and a ramp are rock, also flipped or turned; an empty cell and a one-way platform, also flipped,
## are open, and so is the cell around the tiles, where the grid starts.
func _check_what_is_rock() -> bool:
	var platform: Vector2i = ROOM_PLATFORM.position
	var around: Vector2i = ROCK.position - Vector2i.ONE
	var grid: Vector2i = ROCK.size + Vector2i.ONE * 2
	var rock: Array[bool] = [_rocks.is_rock(ROCK_CELL), _rocks.is_rock(RAMP_CELL), _rocks.is_rock(FLIPPED_ROCK),
			_rocks.is_rock(TURNED_RAMP)]
	var open: Array[bool] = [_rocks.is_open(ABOVE_PLATFORM), _rocks.is_open(platform),
			_rocks.is_open(FLIPPED_PLATFORM), _rocks.is_open(around)]
	var passed: bool = (not rock.has(false) and not open.has(false) and _rocks.origin == around
			and _rocks.size == grid)
	return report(passed, ("Rock: a rock tile, a ramp, a flipped rock tile, a turned ramp %s; open: an empty cell, a "
			+ "one-way platform, a flipped one, the cell around the tiles %s (expected all true); the grid from %s, %s "
			+ "cells (expected %s, %s)") % [rock, open, _rocks.origin, _rocks.size, around, grid])


## From a cell in the room the open space is the room, its platform and the cells under it included, but not the
## open cell past its corner, with the box from its first cell to its last, and it does not reach past the map.
## From rock there is none; from the tunnel it reaches past the map.
func _check_the_open_space() -> bool:
	var space: RockMap.OpenSpace = _rocks.open_space(ABOVE_PLATFORM)
	var platform_reached: bool = (space.cells[_rocks.index_of(ROOM_PLATFORM.position)] == RockMap.REACHED
			and space.cells[_rocks.index_of(BELOW_PLATFORM)] == RockMap.REACHED)
	var corner: int = space.cells[_rocks.index_of(CORNER_CELL)]
	var last: Vector2i = ROOM.end - Vector2i.ONE
	var from_rock: RockMap.OpenSpace = _rocks.open_space(ROCK_CELL)
	var tunnel: RockMap.OpenSpace = _rocks.open_space(TUNNEL_CELL)
	var passed: bool = (platform_reached and corner == RockMap.OPEN and space.first == ROOM.position
			and space.last == last and not space.reaches_edge and from_rock == null and tunnel.reaches_edge)
	return report(passed, ("From the room: its platform and under it reached %s, the corner cell %d (expected %d, "
			+ "not joined), box %s to %s (expected %s to %s), past the map %s; from rock %s (expected none); from the "
			+ "tunnel past the map %s") % [platform_reached, corner, RockMap.OPEN, space.first, space.last,
			ROOM.position, last, space.reaches_edge, from_rock, tunnel.reaches_edge])


## In the shaft, with the platform across it, the chimney's axis is its middle, with the rule of the camera's
## Stats and with the rule at exactly the shaft's width and height. A rule a tile narrower or a row taller finds
## none, nor does a row open to the outside, however wide the rule.
func _check_the_chimneys() -> bool:
	var point: Vector2 = _point(SHAFT_CELL)
	var axis: float = (SHAFT.position.x + SHAFT.size.x / 2.0) * TILE
	var found: float = _rocks.chimney_axis(point, CHIMNEY_WIDTH, CHIMNEY_HEIGHT)
	var exact: float = _rocks.chimney_axis(point, SHAFT.size.x, SHAFT.size.y)
	var too_wide: float = _rocks.chimney_axis(point, SHAFT.size.x - 1, CHIMNEY_HEIGHT)
	var too_short: float = _rocks.chimney_axis(point, CHIMNEY_WIDTH, SHAFT.size.y + 1)
	var open_row: float = _rocks.chimney_axis(_point(TUNNEL_CELL), TUNNEL.size.x + 2, 1)
	var passed: bool = (is_equal_approx(found, axis) and is_equal_approx(exact, axis) and is_nan(too_wide)
			and is_nan(too_short) and is_nan(open_row))
	return report(passed, ("In the shaft the axis is at x %.1f, with the rule at its width and height %.1f "
			+ "(expected %.1f); a tile too wide %.1f, a row too short %.1f, a row open to the outside %.1f (expected "
			+ "nan)") % [found, exact, axis, too_wide, too_short, open_row])


## Rock over ROCK with the room, the shaft, the tunnel and the corner cell carved out, then the ramp and the
## platforms.
func _build_map() -> TileMapLayer:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.tile_set = TILE_SET
	_fill(tiles, ROCK, StoneRim.ROCK_ALTERNATIVE)
	for open: Rect2i in [ROOM, SHAFT, TUNNEL, Rect2i(CORNER_CELL, Vector2i.ONE)]:
		for y: int in range(open.position.y, open.end.y):
			for x: int in range(open.position.x, open.end.x):
				tiles.erase_cell(Vector2i(x, y))
	tiles.set_cell(RAMP_CELL, StoneRim.ROCK_SOURCE, RAMP_ATLAS)
	_fill(tiles, ROOM_PLATFORM, ONE_WAY_ALTERNATIVE)
	_fill(tiles, SHAFT_PLATFORM, ONE_WAY_ALTERNATIVE)
	tiles.set_cell(FLIPPED_ROCK, StoneRim.ROCK_SOURCE, StoneRim.ROCK_ATLAS, StoneRim.ROCK_ALTERNATIVE | FLIP_H)
	tiles.set_cell(TURNED_RAMP, StoneRim.ROCK_SOURCE, RAMP_ATLAS, TURN)
	tiles.set_cell(FLIPPED_PLATFORM, StoneRim.ROCK_SOURCE, StoneRim.ROCK_ATLAS, ONE_WAY_ALTERNATIVE | FLIP_H)
	return tiles


func _fill(tiles: TileMapLayer, area: Rect2i, alternative: int) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			tiles.set_cell(Vector2i(x, y), StoneRim.ROCK_SOURCE, StoneRim.ROCK_ATLAS, alternative)


## The middle of cell, in the world.
func _point(cell: Vector2i) -> Vector2:
	return _tiles.to_global(_tiles.map_to_local(cell))
