class_name ShelterField
extends Resource

## How enclosed each spot of a level is, baked once from the level's tile map, for the level's
## AmbienceShelter to muffle the wind with as the man goes into closed places. bake_shelter.gd bakes
## it (its header has the command): bake again after moving the level's tiles.
## Openness: from each air tile, 9 rays, from the horizon up, run until the first rock or Reach, and
## openness is the share of Reach they travel: 1 with every ray free, near 0 under a low roof between
## walls. A roof and walls on both sides shelter the man from the wind, but neither the floor nor a
## single wall does. So no ray looks down, as he nearly always stands on a floor (with rays down too,
## the floor of an open cavern read 0.40 at the median, against 0.90 now); and each ray to the right
## counts with its mirror to the left as twice the more open of the two, so a wall on one side does
## not close him in (beside the wall of a cavern, in the air, the median was 0.37, as closed as a
## corridor, against 0.63 now). A tile stops the rays if any of its collision polygons is solid;
## one-way platforms, which are thin, let them through, and outside the map is rock, so a level open
## to the sky above its map would read closed up there.
## Openness alone closes a tunnel within about 3 tiles of its mouth, too sudden: so the closing also
## grows with the depth into the closed place, the walk through air from the nearest open tile (one
## whose openness is at least Depth Open At), to be whole Closed Ramp tiles in.
## Width: the run of air left and right through a tile. Chimney depth: in an upright stretch of tiles
## at most Chimney Max Width wide and at least Chimney Min Length tall, how far a tile is from the
## nearer open end of it; an end against rock is no mouth, so the top of a chimney closed above is
## its deepest part.
## What the shelter hears, closed_amount() and chimney_amount(), comes from these with values it
## tunes live, so only the Bake values need a new bake.

## Where the shelter's closing starts, and where it is whole, in openness; how far into a closed
## place it is whole, in tiles; how wide a chimney is whole, and how far in, in tiles. The shelter's
## defaults, and the preview's.
## In level 1 these split the open from the closed. At the median, the floor of a cavern 12 tiles
## tall or more reads 0.90 and the air beside its wall 0.63, both open; a corridor's floor 0.49 when
## 4 to 5 tiles tall and 0.42 when 3 or less, and a chimney 0.27, all closed.
const DEFAULT_OPEN_AT: float = 0.65
const DEFAULT_SHUT_AT: float = 0.40
const DEFAULT_CLOSED_RAMP: float = 8.0
const DEFAULT_TIGHT_WIDTH: float = 3.0
const DEFAULT_CHIMNEY_RAMP: float = 6.0
## The rays, one step each in tiles. The one straight up counts once; each to the right counts with
## its mirror to the left, as twice the more open of the two: right, up and right, and the two
## knight's moves between them.
const UP_RAY: Vector2i = Vector2i(0, -1)
const PAIRED_RAYS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(2, -1),
		Vector2i(1, -2)]
## The steps of the walk into a closed place: to a side, up and down.
const WALK_STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
		Vector2i(0, -1)]
## Rock round the grid while baking, in tiles: as far as one step of a ray reaches.
const BORDER: int = 2
## The most a byte of the grid holds.
const BYTE_MAX: int = 255

@export_group("Bake")
## The tile map layer to bake, as a path from the level's root.
@export var tiles_path: NodePath = ^"Tiles"
## How far a ray looks, in px of the world. Further, a room still counts as open from deeper inside
## a tunnel, and the closing comes later.
@export_range(96.0, 4800.0, 48.0, "suffix:px") var reach: float = 960.0
## The openness from which a tile counts as open, where the depth into a closed place starts: best
## kept at the shelter's Open At.
@export_range(0.0, 1.0, 0.01) var depth_open_at: float = DEFAULT_OPEN_AT
## The widest an upright stretch can be and still be a chimney, in tiles.
@export_range(1, 30, 1, "suffix:tiles") var chimney_max_width: int = 6
## The shortest an upright stretch can be and still be a chimney, in tiles.
@export_range(2, 200, 1, "suffix:tiles") var chimney_min_length: int = 8

## A fingerprint (SHA-256, in hex) of the tiles the field was baked from, to tell a stale bake.
@export_storage var source_sha256: String = ""
## The world position of the top-left corner of the grid's first tile, and a tile's size there.
@export_storage var origin: Vector2 = Vector2.ZERO
@export_storage var tile_size: Vector2 = Vector2.ONE
## The grid's size, in tiles: the tile map's used rectangle.
@export_storage var size: Vector2i = Vector2i.ZERO
## Per tile, row by row from the top-left: openness, from 0 to 255 for 0 to 1; width, in tiles, 0 on
## rock; depth into a closed place, in tiles, 0 where open and BYTE_MAX where nothing open is
## reachable; chimney depth, in half tiles, 0 outside a chimney.
@export_storage var openness: PackedByteArray = PackedByteArray()
@export_storage var widths: PackedByteArray = PackedByteArray()
@export_storage var closed_depths: PackedByteArray = PackedByteArray()
@export_storage var chimney_depths: PackedByteArray = PackedByteArray()


## How closed a place is, from 0, with the wind as it is, to 1. By its openness open: 0 at Open At and
## above, 1 at Shut At and below, smoothly in between; and by its depth into the closed place, in
## tiles: none at its edge, whole Ramp tiles in, smoothly in between.
static func closed_amount(open: float, depth: float, open_at: float = DEFAULT_OPEN_AT,
		shut_at: float = DEFAULT_SHUT_AT, ramp: float = DEFAULT_CLOSED_RAMP) -> float:
	var enclosed: float = 0.0 if open >= open_at else 1.0
	if open_at > shut_at:
		enclosed = smoothstep(0.0, 1.0, (open_at - open) / (open_at - shut_at))
	var deep: float = 1.0 if ramp <= 0.0 else smoothstep(0.0, 1.0, depth / ramp)
	return enclosed * deep


## The node's transform to the world, from its own and its parents': its global transform in the
## tree, and also outside it, as when a command bakes a scene it never runs.
static func world_transform(node: Node) -> Transform2D:
	var xform := Transform2D.IDENTITY
	var at: Node = node
	while at != null:
		if at is Node2D:
			xform = (at as Node2D).transform * xform
		at = at.get_parent()
	return xform


## The SHA-256 of the tiles' cells, in hex; empty without cells.
static func fingerprint(tiles: TileMapLayer) -> String:
	var cells: PackedByteArray = tiles.tile_map_data
	if cells.is_empty():
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(cells)
	return context.finish().hex_encode()


## How much of a chimney a place is, from 0 to 1: whole at Tight Width tiles wide and narrower,
## nothing past Chimney Max Width; and, along it, from 0 at its mouth to whole Ramp tiles in.
func chimney_amount(width: float, depth: float, tight_width: float = DEFAULT_TIGHT_WIDTH,
		ramp: float = DEFAULT_CHIMNEY_RAMP) -> float:
	if depth <= 0.0:
		return 0.0
	var loose: float = chimney_max_width + 1.0
	var tight: float = 1.0
	if tight_width < loose:
		tight = smoothstep(0.0, 1.0, (loose - width) / (loose - tight_width))
	var deep: float = 1.0 if ramp <= 0.0 else smoothstep(0.0, 1.0, depth / ramp)
	return tight * deep


## Whether it holds a bake, of this version of the field.
func is_baked() -> bool:
	var count: int = size.x * size.y
	return (count > 0 and openness.size() == count and widths.size() == count
			and closed_depths.size() == count and chimney_depths.size() == count)


## Bakes the field from tiles, with its settings. Tiles need not be in the tree.
func bake(tiles: TileMapLayer) -> void:
	var rect: Rect2i = tiles.get_used_rect()
	size = rect.size
	var world: Transform2D = world_transform(tiles)
	var map_tile := Vector2(tiles.tile_set.tile_size)
	tile_size = map_tile * world.get_scale()
	origin = world * (tiles.map_to_local(rect.position) - map_tile * 0.5)
	source_sha256 = fingerprint(tiles)
	var solid: PackedByteArray = _solid_grid(tiles, rect)
	var open: PackedFloat32Array = _bake_openness(solid)
	openness = PackedByteArray()
	openness.resize(open.size())
	for i: int in open.size():
		openness[i] = clampi(roundi(open[i] * BYTE_MAX), 0, BYTE_MAX)
	widths = _bake_widths(solid)
	closed_depths = _bake_closed_depths(open)
	chimney_depths = _bake_chimney_depths()


## Openness at a world position, from 0 to 1, read between the four nearest tiles from the air ones
## alone, so a wall beside the man does not close him in; 0 inside rock and off the grid.
func openness_at(world_position: Vector2) -> float:
	return _sample(openness, world_position) / BYTE_MAX


## The width of the air at a world position, in tiles, read as openness_at() reads.
func width_at(world_position: Vector2) -> float:
	return _sample(widths, world_position)


## How far into a closed place a world position is, in tiles, read as openness_at() reads.
func closed_depth_at(world_position: Vector2) -> float:
	return _sample(closed_depths, world_position)


## How far into a chimney a world position is, in tiles, read as openness_at() reads; 0 outside.
func chimney_depth_at(world_position: Vector2) -> float:
	return _sample(chimney_depths, world_position) * 0.5


## The amounts at a world position with the default values: x closed, y chimney. For the tests; the
## shelter uses its own values.
func default_amounts_at(world_position: Vector2) -> Vector2:
	return Vector2(closed_amount(openness_at(world_position), closed_depth_at(world_position)),
			chimney_amount(width_at(world_position), chimney_depth_at(world_position)))


## The amounts of the tile at x, y with the default values, from its own values alone: x closed, y
## chimney; x below 0 on rock. For the bake's preview and sums.
func default_amounts_of_tile(x: int, y: int) -> Vector2:
	var i: int = y * size.x + x
	if widths[i] == 0:
		return Vector2(-1.0, 0.0)
	return Vector2(closed_amount(openness[i] / float(BYTE_MAX), closed_depths[i]),
			chimney_amount(widths[i], chimney_depths[i] * 0.5))


## The grid with BORDER tiles of rock round it, 1 for rock and 0 for air, row by row.
func _solid_grid(tiles: TileMapLayer, rect: Rect2i) -> PackedByteArray:
	var padded_width: int = size.x + 2 * BORDER
	var solid := PackedByteArray()
	solid.resize(padded_width * (size.y + 2 * BORDER))
	solid.fill(1)
	# Inside the used rectangle, a cell with no tile is air.
	for y: int in size.y:
		var row: int = (y + BORDER) * padded_width + BORDER
		for x: int in size.x:
			solid[row + x] = 0
	var layers: int = tiles.tile_set.get_physics_layers_count()
	var blocks: Dictionary[Vector4i, bool] = {}
	for cell: Vector2i in tiles.get_used_cells():
		var atlas: Vector2i = tiles.get_cell_atlas_coords(cell)
		var key := Vector4i(tiles.get_cell_source_id(cell), atlas.x, atlas.y,
				tiles.get_cell_alternative_tile(cell))
		if not blocks.has(key):
			blocks[key] = _blocks(tiles.get_cell_tile_data(cell), layers)
		if blocks[key]:
			var at: Vector2i = cell - rect.position
			solid[(at.y + BORDER) * padded_width + at.x + BORDER] = 1
	return solid


## Whether a tile stops the rays: any collision polygon that is not one-way.
func _blocks(data: TileData, layers: int) -> bool:
	if data == null:
		return false
	for layer: int in layers:
		for polygon: int in data.get_collision_polygons_count(layer):
			if not data.is_collision_polygon_one_way(layer, polygon):
				return true
	return false


## The openness of each tile of the grid, row by row, 0 on rock: the run up, plus twice the longer
## of each mirrored pair's runs, as a share of Reach on every ray.
func _bake_openness(solid: PackedByteArray) -> PackedFloat32Array:
	var padded_width: int = size.x + 2 * BORDER
	var cap: float = reach / tile_size.x
	var total: PackedFloat32Array = _ray_runs(solid, UP_RAY, cap)
	for ray: Vector2i in PAIRED_RAYS:
		var right: PackedFloat32Array = _ray_runs(solid, ray, cap)
		var left: PackedFloat32Array = _ray_runs(solid, Vector2i(-ray.x, ray.y), cap)
		for i: int in total.size():
			total[i] += 2.0 * maxf(right[i], left[i])
	var open := PackedFloat32Array()
	open.resize(size.x * size.y)
	var full: float = cap * (1 + 2 * PAIRED_RAYS.size())
	for y: int in size.y:
		var row: int = (y + BORDER) * padded_width + BORDER
		for x: int in size.x:
			if solid[row + x] == 0:
				open[y * size.x + x] = total[row + x] / full
	return open


## How far a ray along direction runs from each tile of the padded grid, in tiles, up to cap. A
## ray's run from a tile is the step to the next tile and that tile's run, so it is one pass, the
## tile ahead first. A ray stopped at once has gone half a tile, to the wall. A knight's move also
## crosses the two tiles beside its way, which must be air; a diagonal does not slip between two
## rocks that touch at a corner.
func _ray_runs(solid: PackedByteArray, direction: Vector2i, cap: float) -> PackedFloat32Array:
	var padded_width: int = size.x + 2 * BORDER
	var run := PackedFloat32Array()
	run.resize(solid.size())
	var step: float = Vector2(direction).length()
	var ahead: int = direction.y * padded_width + direction.x
	var side_a: int = 0
	var side_b: int = 0
	var knight: bool = absi(direction.x) == 2 or absi(direction.y) == 2
	var diagonal: bool = not knight and direction.x != 0 and direction.y != 0
	# Half of a knight's long side is one tile that way.
	if absi(direction.x) == 2:
		side_a = signi(direction.x)
		side_b = direction.y * padded_width + signi(direction.x)
	elif absi(direction.y) == 2:
		side_a = signi(direction.y) * padded_width
		side_b = signi(direction.y) * padded_width + direction.x
	elif diagonal:
		side_a = direction.x
		side_b = direction.y * padded_width
	var rows: Array[int] = []
	rows.assign(range(size.y - 1, -1, -1) if direction.y > 0 else range(size.y))
	var columns: Array[int] = []
	columns.assign(range(size.x - 1, -1, -1) if direction.x > 0 else range(size.x))
	for y: int in rows:
		var row: int = (y + BORDER) * padded_width + BORDER
		for x: int in columns:
			var i: int = row + x
			if solid[i] == 1:
				continue
			var blocked: bool = solid[i + ahead] == 1
			if not blocked and knight:
				blocked = solid[i + side_a] == 1 or solid[i + side_b] == 1
			elif not blocked and diagonal:
				blocked = solid[i + side_a] == 1 and solid[i + side_b] == 1
			run[i] = 0.5 * step if blocked else minf(cap, step + run[i + ahead])
	return run


## The width of the air through each tile: its run left and right, inside the grid.
func _bake_widths(solid: PackedByteArray) -> PackedByteArray:
	var padded_width: int = size.x + 2 * BORDER
	var bytes := PackedByteArray()
	bytes.resize(size.x * size.y)
	for y: int in size.y:
		var row: int = (y + BORDER) * padded_width + BORDER
		var x: int = 0
		while x < size.x:
			if solid[row + x] == 1:
				x += 1
				continue
			var start: int = x
			while x < size.x and solid[row + x] == 0:
				x += 1
			var width: int = mini(x - start, BYTE_MAX)
			for i: int in range(start, x):
				bytes[y * size.x + i] = width
	return bytes


## Each air tile's depth into a closed place, in tiles: a walk through air, one tile to a side, up or
## down at a time, from the nearest tile whose openness open is at least Depth Open At; 0 there and on
## rock, and BYTE_MAX where no such tile is reachable.
func _bake_closed_depths(open: PackedFloat32Array) -> PackedByteArray:
	var count: int = size.x * size.y
	var depths := PackedByteArray()
	depths.resize(count)
	depths.fill(BYTE_MAX)
	var reached := PackedByteArray()
	reached.resize(count)
	var queue := PackedInt32Array()
	queue.resize(count)
	var tail: int = 0
	for i: int in count:
		if widths[i] == 0:
			depths[i] = 0
			reached[i] = 1
		elif open[i] >= depth_open_at:
			depths[i] = 0
			reached[i] = 1
			queue[tail] = i
			tail += 1
	var head: int = 0
	while head < tail:
		var i: int = queue[head]
		head += 1
		var x: int = i % size.x
		@warning_ignore("integer_division")
		var y: int = i / size.x
		for step: Vector2i in WALK_STEPS:
			var to := Vector2i(x + step.x, y + step.y)
			if to.x < 0 or to.y < 0 or to.x >= size.x or to.y >= size.y:
				continue
			var j: int = to.y * size.x + to.x
			if reached[j] == 1:
				continue
			reached[j] = 1
			depths[j] = mini(depths[i] + 1, BYTE_MAX)
			queue[tail] = j
			tail += 1
	return depths


## Each chimney tile's depth, in half tiles: in each column, an upright stretch of air at most
## Chimney Max Width wide and at least Chimney Min Length tall is a chimney, and its tiles are as
## deep as the nearer of its open ends, plus half a tile. An end against rock or the grid's edge is
## no mouth; a chimney closed at both ends is deep all along.
func _bake_chimney_depths() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size.x * size.y)
	for x: int in size.x:
		var y: int = 0
		while y < size.y:
			if not _narrow(x, y):
				y += 1
				continue
			var start: int = y
			while y < size.y and _narrow(x, y):
				y += 1
			if y - start < chimney_min_length:
				continue
			var open_above: bool = start > 0 and widths[(start - 1) * size.x + x] > 0
			var open_below: bool = y < size.y and widths[y * size.x + x] > 0
			for i: int in range(start, y):
				var depth: int = BYTE_MAX
				if open_above:
					depth = mini(depth, 2 * (i - start) + 1)
				if open_below:
					depth = mini(depth, 2 * (y - 1 - i) + 1)
				bytes[i * size.x + x] = depth
	return bytes


func _narrow(x: int, y: int) -> bool:
	var width: int = widths[y * size.x + x]
	return width > 0 and width <= chimney_max_width


## A value of data at a world position, between the centres of the four nearest tiles, weighted by
## nearness and from the air tiles alone; 0 if none of them is air.
func _sample(data: PackedByteArray, world_position: Vector2) -> float:
	if not is_baked():
		return 0.0
	var at: Vector2 = (world_position - origin) / tile_size - Vector2(0.5, 0.5)
	var left: int = floori(at.x)
	var top: int = floori(at.y)
	var across: float = at.x - left
	var down: float = at.y - top
	var sum: float = 0.0
	var weight: float = 0.0
	for dy: int in 2:
		for dx: int in 2:
			var x: int = left + dx
			var y: int = top + dy
			if x < 0 or y < 0 or x >= size.x or y >= size.y:
				continue
			var i: int = y * size.x + x
			if widths[i] == 0:
				continue
			var share: float = ((across if dx == 1 else 1.0 - across)
					* (down if dy == 1 else 1.0 - down))
			sum += data[i] * share
			weight += share
	return sum / weight if weight > 0.0 else 0.0
