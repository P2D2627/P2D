extends Node2D
## PROTOTYPE (#261): depth for the rock. A copy of the rock is drawn behind the man, the dogs and the
## spikes, nudged out of each face into the open: floors up, ceilings down, walls sideways and outer
## corners on the diagonal; along floors, ceilings and walls its stones are slid so they do not
## repeat the ones in front. The rig then draws the rock itself in front of them, so they stand between
## the two. Only the faces get a copy, since the rock in front hides the rest. The copy has no
## collision, light occluders or navigation, so physics, the line of sight and the camera never see
## it. Darker and pulled towards the level's dark red, it reads as the far edge of the same rock.

## Px the copy is nudged out of each face: a quarter of a 48 px tile, in whole pixels so the pixel art
## stays on its grid.
const OFFSET: float = 12.0
## The copy's tint: about 60 % of the rock's value, pulled towards the level's dark red.
const TINT := Color(0.6, 0.48, 0.54)
## Along each straight run of the rim, the copy's stones slide this share of the strip's drawing, so
## they do not repeat the stones in front. Corner pieces stay as they are.
const PATTERN_SHIFT: float = 0.5
## A face opens onto the air on one of these sides.
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## The diagonals, clockwise from up-left. An outer corner opens onto one of them; the stone rim turns
## each corner piece a quarter right per step from up-left to its open side (stone_rim.gd).
const DIAGONALS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]

var _tiles: TileMapLayer
var _rock_mask: int
## One copy of the tiles per way out, each nudged that way.
var _layers: Dictionary[Vector2i, TileMapLayer] = {}


## Builds the copy from the level's tiles and stone rim; call it once this node is in the tree. Rock
## is a tile's first alternative; the second is a one-way platform, which keeps its own look and gets
## no copy, as it gets no rim.
func setup(tiles: TileMapLayer, rim: Node2D, rock_mask: int) -> void:
	var start: int = Time.get_ticks_msec()
	_tiles = tiles
	_rock_mask = rock_mask
	modulate = TINT
	var faces: int = 0
	for cell: Vector2i in tiles.get_used_cells():
		if not _is_rock(cell):
			continue
		for way: Vector2i in SIDES:
			if not _is_rock(cell + way):
				_copy_cell(cell, way)
				faces += 1
		for way: Vector2i in DIAGONALS:
			if not _is_rock(cell + Vector2i(way.x, 0)) and not _is_rock(cell + Vector2i(0, way.y)):
				_copy_cell(cell, way)
	var pieces: int = 0
	if rim != null:
		pieces = _copy_rim(rim)
	print("ProtoDepth: %d tile faces in %d copies, %d rim pieces, built in %d ms"
			% [faces, _layers.size(), pieces, Time.get_ticks_msec() - start])


func _is_rock(cell: Vector2i) -> bool:
	return _tiles.get_cell_source_id(cell) != -1 and _tiles.get_cell_alternative_tile(cell) == 0


func _copy_cell(cell: Vector2i, way: Vector2i) -> void:
	if not _layers.has(way):
		var layer := TileMapLayer.new()
		layer.name = "Tiles%d_%d" % [way.x, way.y]
		layer.tile_set = _tiles.tile_set
		layer.material = _tiles.material
		layer.texture_filter = _tiles.texture_filter
		layer.light_mask = _rock_mask
		layer.collision_enabled = false
		layer.occlusion_enabled = false
		layer.navigation_enabled = false
		layer.transform = _tiles.transform
		layer.position += Vector2(way) * OFFSET
		add_child(layer)
		_layers[way] = layer
	_layers[way].set_cell(cell, _tiles.get_cell_source_id(cell), _tiles.get_cell_atlas_coords(cell), 0)


## Copies each rim piece, nudged the way its face opens, and returns how many.
func _copy_rim(rim: Node2D) -> int:
	var copy := Node2D.new()
	copy.name = "Rim"
	add_child(copy)
	copy.global_transform = rim.global_transform
	for child: Node in rim.get_children():
		var piece := child as Sprite2D
		if piece == null:
			continue
		var twin := piece.duplicate(0) as Sprite2D
		twin.position = piece.position + Vector2(_rim_way(piece)) * OFFSET
		if twin.region_enabled and twin.texture != null:
			twin.region_rect.position.x += twin.texture.get_width() * PATTERN_SHIFT
		copy.add_child(twin)
	return copy.get_child_count()


## The way a rim piece faces the open, from what stone_rim.gd names and turns it: a floor faces up, a
## ceiling down, a left wall left and a right wall right; a corner piece by its quarter turns.
func _rim_way(piece: Sprite2D) -> Vector2i:
	var piece_name := String(piece.name)
	if piece_name.contains("Corner"):
		return DIAGONALS[posmod(roundi(piece.rotation / (PI / 2.0)), DIAGONALS.size())]
	if piece_name.contains("Floor"):
		return Vector2i.UP
	if piece_name.contains("Ceiling"):
		return Vector2i.DOWN
	if piece_name.contains("LeftWall"):
		return Vector2i.LEFT
	if piece_name.contains("RightWall"):
		return Vector2i.RIGHT
	return Vector2i.ZERO
