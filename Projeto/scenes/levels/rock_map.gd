class_name RockMap
extends RefCounted
## Which cells of a level's tiles are rock, read once: a tile with a collision polygon that is not one-way is rock,
## so the rock and its ramps are, flipped or turned too, and an empty cell or a one-way platform is open. It covers
## the tiles' used rectangle and a cell around it, which is open. From a cell it finds the open space joined to it,
## and around a point it finds a chimney. Both the camera that frames the man with one zoom and the measure of how
## much rock the screen shows read the level through it, so they agree on what rock is.

## In OpenSpace.cells: rock, an open cell not joined to the space, and a cell of the space.
const ROCK: int = 1
const OPEN: int = 0
const REACHED: int = 2
## The bits of a cell's alternative id that say how it was flipped and turned, as the TileMap editor's Z and X
## keys paint it.
const TRANSFORM_BITS: int = (TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		| TileSetAtlasSource.TRANSFORM_TRANSPOSE)

## The open space joined to a cell.
class OpenSpace:
	extends RefCounted
	## ROCK, OPEN or REACHED for each cell, by grid index (RockMap.index_of()).
	var cells: PackedByteArray = PackedByteArray()
	## The first and last cell of the box around the space, in the tiles' cells.
	var first: Vector2i = Vector2i.ZERO
	var last: Vector2i = Vector2i.ZERO
	## Whether the space reaches the cell around the used rectangle: the map is open to the outside.
	var reaches_edge: bool = false

var tiles: TileMapLayer
## The grid's first cell, in the tiles' cells, and how many cells it has across and down.
var origin: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i.ZERO
## ROCK or OPEN for each cell, by grid index.
var _rock: PackedByteArray = PackedByteArray()


## Reads level_tiles: each kind of tile of its tile set at once, flipped and turned cells included. A kind whose
## alternatives are all solid marks all its cells rock; only a kind with solid and open alternatives, as the rock
## with its one-way platform, looks at each cell's alternative, without the bits of its flips and turn. One call
## per kind: each call goes through every cell of the map.
func _init(level_tiles: TileMapLayer) -> void:
	tiles = level_tiles
	var used: Rect2i = tiles.get_used_rect().grow(1)
	origin = used.position
	size = used.size
	_rock.resize(size.x * size.y)
	var tile_set: TileSet = tiles.tile_set
	if tile_set == null:
		return
	for source_index: int in tile_set.get_source_count():
		var source_id: int = tile_set.get_source_id(source_index)
		var atlas: TileSetAtlasSource = tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas == null:
			continue
		for tile_index: int in atlas.get_tiles_count():
			var coords: Vector2i = atlas.get_tile_id(tile_index)
			var count: int = atlas.get_alternative_tiles_count(coords)
			var solid: PackedInt32Array = PackedInt32Array()
			for alternative_index: int in count:
				var alternative: int = atlas.get_alternative_tile_id(coords, alternative_index)
				if _is_solid(atlas.get_tile_data(coords, alternative), tile_set):
					solid.append(alternative)
			if solid.is_empty():
				continue
			var cells: Array[Vector2i] = tiles.get_used_cells_by_id(source_id, coords)
			if solid.size() == count:
				_mark_rock(cells)
			else:
				_mark_rock_of(cells, solid)


func is_rock(cell: Vector2i) -> bool:
	return _in_grid(cell) and _rock[index_of(cell)] == ROCK


## Open: inside the grid and not rock.
func is_open(cell: Vector2i) -> bool:
	return _in_grid(cell) and _rock[index_of(cell)] == OPEN


## The cell under point, in the world.
func cell_at(point: Vector2) -> Vector2i:
	return tiles.local_to_map(tiles.to_local(point))


## The grid index of cell, in the tiles' cells.
func index_of(cell: Vector2i) -> int:
	return (cell.y - origin.y) * size.x + cell.x - origin.x


## The open space joined to cell through open cells across and up and down, or null if cell is not open. It works
## on grid indices, so a level of 373 x 381 cells takes a few milliseconds.
func open_space(cell: Vector2i) -> OpenSpace:
	if not is_open(cell):
		return null
	var width: int = size.x
	var space: OpenSpace = OpenSpace.new()
	space.cells = _rock.duplicate()
	var start: int = index_of(cell)
	space.cells[start] = REACHED
	var to_visit: PackedInt32Array = PackedInt32Array([start])
	var ways: PackedInt32Array = PackedInt32Array([-1, 1, -width, width])
	var low: Vector2i = cell - origin
	var high: Vector2i = low
	while not to_visit.is_empty():
		var at: int = to_visit[to_visit.size() - 1]
		to_visit.resize(to_visit.size() - 1)
		var x: int = at % width
		@warning_ignore("integer_division")
		var y: int = at / width
		low = Vector2i(mini(low.x, x), mini(low.y, y))
		high = Vector2i(maxi(high.x, x), maxi(high.y, y))
		if x == 0 or y == 0 or x == width - 1 or y == size.y - 1:
			space.reaches_edge = true
			continue
		for way: int in ways:
			if space.cells[at + way] == OPEN:
				space.cells[at + way] = REACHED
				to_visit.append(at + way)
	space.first = origin + low
	space.last = origin + high
	return space


## The x, in the world, of the middle of the chimney around point, or NAN if point is in none: the row of open
## cells across it, between rock on both sides, is at most max_width cells, and so are the rows above and below it
## for min_height rows in all. A narrow niche or pit is not a chimney.
func chimney_axis(point: Vector2, max_width: int, min_height: int) -> float:
	var cell: Vector2i = cell_at(point)
	var span: Vector2i = _narrow_span(cell, max_width)
	if span.x > span.y:
		return NAN
	var rows: int = 1
	for way: int in [-1, 1]:
		var row: Vector2i = cell + Vector2i(0, way)
		while rows < min_height:
			var other: Vector2i = _narrow_span(row, max_width)
			if other.x > other.y:
				break
			rows += 1
			row.y += way
	if rows < min_height:
		return NAN
	var tile: Vector2 = Vector2(tiles.tile_set.tile_size)
	var left_edge: float = tiles.to_global(tiles.map_to_local(Vector2i(span.x, cell.y))).x - tile.x / 2.0
	return left_edge + (span.y - span.x + 1) * tile.x / 2.0


## The first and last x of the open cells across cell, if they lie between rock on both sides and are at most
## max_width; otherwise a span with its first after its last.
func _narrow_span(cell: Vector2i, max_width: int) -> Vector2i:
	if not is_open(cell):
		return Vector2i(1, 0)
	var first: int = cell.x
	while cell.x - first < max_width and is_open(Vector2i(first - 1, cell.y)):
		first -= 1
	var last: int = cell.x
	while last - first + 1 <= max_width and is_open(Vector2i(last + 1, cell.y)):
		last += 1
	var walled: bool = is_rock(Vector2i(first - 1, cell.y)) and is_rock(Vector2i(last + 1, cell.y))
	if not walled or last - first + 1 > max_width:
		return Vector2i(1, 0)
	return Vector2i(first, last)


func _mark_rock(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		_rock[index_of(cell)] = ROCK


## Marks rock the cells whose alternative, without its flips and turn, is one of solid.
func _mark_rock_of(cells: Array[Vector2i], solid: PackedInt32Array) -> void:
	for cell: Vector2i in cells:
		if solid.has(tiles.get_cell_alternative_tile(cell) & ~TRANSFORM_BITS):
			_rock[index_of(cell)] = ROCK


func _in_grid(cell: Vector2i) -> bool:
	var at: Vector2i = cell - origin
	return at.x >= 0 and at.y >= 0 and at.x < size.x and at.y < size.y


## A tile with a collision polygon that is not one-way, on any of the tile set's physics layers.
static func _is_solid(data: TileData, tile_set: TileSet) -> bool:
	for layer: int in tile_set.get_physics_layers_count():
		for polygon: int in data.get_collision_polygons_count(layer):
			if not data.is_collision_polygon_one_way(layer, polygon):
				return true
	return false
