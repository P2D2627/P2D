extends RefCounted
## A small map for the shelter's tests, made in memory with the cave tile set: rock all over but a
## cavern, a chimney 3 tiles wide under it, a corridor 3 tiles tall from the chimney's foot, a
## shaft 5 tiles wide at the corridor's far end, closed above, and a tunnel 3 tiles tall into the
## cavern's right wall, closed at its far end. It sits at the origin, one tile 48 px.

const TILE_SET_PATH: String = "res://scenes/others/tilesets/cave_placeholder_tiles.tres"
## The tile set's rock and its one-way platform: source 0, atlas (0, 0), alternatives 0 and 1.
const ROCK_ALTERNATIVE: int = 0
const ONE_WAY_ALTERNATIVE: int = 1
## The tile set's tiles, in px.
const TILE_SIZE: float = 48.0
## The map's size and the air carved out of its rock, in tiles.
const MAP_SIZE: Vector2i = Vector2i(60, 50)
const CAVERN: Rect2i = Rect2i(2, 2, 30, 20)
const CHIMNEY: Rect2i = Rect2i(20, 22, 3, 20)
const CORRIDOR: Rect2i = Rect2i(20, 42, 36, 3)
const SHAFT: Rect2i = Rect2i(51, 20, 5, 22)
const TUNNEL: Rect2i = Rect2i(32, 15, 14, 3)
## The row the one-way platforms cross the cavern on, with platforms.
const ONE_WAY_ROW: int = 12


## The map as a tile map layer, not in the tree; with platforms, a row of one-way platforms across
## the cavern.
static func build(platforms: bool = false) -> TileMapLayer:
	var tiles := TileMapLayer.new()
	tiles.tile_set = load(TILE_SET_PATH) as TileSet
	for y: int in MAP_SIZE.y:
		for x: int in MAP_SIZE.x:
			var cell := Vector2i(x, y)
			if not (CAVERN.has_point(cell) or CHIMNEY.has_point(cell) or CORRIDOR.has_point(cell)
					or SHAFT.has_point(cell) or TUNNEL.has_point(cell)):
				tiles.set_cell(cell, 0, Vector2i.ZERO, ROCK_ALTERNATIVE)
	if platforms:
		for x: int in range(CAVERN.position.x, CAVERN.end.x):
			tiles.set_cell(Vector2i(x, ONE_WAY_ROW), 0, Vector2i.ZERO, ONE_WAY_ALTERNATIVE)
	return tiles


## A field with the default settings baked from the map, with platforms or not.
static func bake(platforms: bool = false) -> ShelterField:
	var tiles: TileMapLayer = build(platforms)
	var field := ShelterField.new()
	field.bake(tiles)
	tiles.free()
	return field


## The world position of a tile's centre.
static func centre(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE_SIZE
