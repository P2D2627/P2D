@tool
class_name StoneRim
extends Node2D
## Lines the rock's outline with stones: each straight run of floor, ceiling or wall as one repeating strip, and a
## corner piece where two runs meet, turned to face the open side. It reads the tiles when the level opens (and in
## the editor), so the map stays the only source and the rim follows it when the map changes. Only rock gets a
## rim: the one-way platforms keep their own look.
##
## To edit the stones by hand, press Bake in the Inspector and save the scene: the stones become ordinary nodes of
## the scene and stop being laid again. Turning Auto Build back on lays them again from the tiles and throws the
## hand edits away.

## In drawing order: walls, then ceilings, then floors, so the floor the man walks on is drawn on top.
enum Side { LEFT_WALL, RIGHT_WALL, CEILING, FLOOR }

## The tile that is rock: source 0, atlas cell (0, 0), first alternative. The second alternative is a one-way
## platform.
const ROCK_SOURCE: int = 0
const ROCK_ATLAS: Vector2i = Vector2i(0, 0)
const ROCK_ALTERNATIVE: int = 0
## The four ways from a tiles' corner into the cells around it, clockwise from up-left.
const WAYS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
## Darkens each piece from the rock's surface inwards.
const FADE_SHADER: Shader = preload("res://scenes/levels/rim_fade.gdshader")

## The rock it lines.
@export var tiles: TileMapLayer
## On: the stones are laid from the tiles each time the level opens, and hand edits are lost. Off: the stones saved
## in the scene stay as they are. Bake turns it off; turning it on lays the stones again at once.
@export var auto_build: bool = true:
	set(value):
		auto_build = value
		if auto_build and is_node_ready():
			rebuild()
## Lays the stones again from the tiles, to see a change to the values below. Only while Auto Build is on.
@export_tool_button("Build", "Reload") var build_button: Callable = _build_pressed
## Keeps the stones in the scene as ordinary nodes, to edit by hand, and turns Auto Build off. Save the scene after.
@export_tool_button("Bake", "Save") var bake_button: Callable = bake

@export_group("Strip")
## A strip whose left and right edges meet, so it repeats with no seam (cut from chao_sprite, columns 65 to 376).
@export var strip: Texture2D = preload("res://assets/sprites/environment/floor_strip.png")
## Size of the strip on screen: 1 is the drawing's own size.
@export_range(0.1, 2.0, 0.05) var strip_scale: float = 0.6
## Rows of the strip that stick out of the rock into the open; the rest sinks into the rock.
@export_range(0.0, 118.0, 1.0) var surface_row: float = 34.0

@export_group("Corners")
## The corner of a wall's end (rock on one side of the corner only), drawn with the open side up and left.
@export var outer_corner: Texture2D = preload("res://assets/sprites/environment/extern_angle.png")
## The corner where a floor meets a wall (rock on three sides), drawn with the open side up and left.
@export var inner_corner: Texture2D = preload("res://assets/sprites/environment/intern_angle.png")
## The stones in each drawing, in its own pixels: the piece is fitted by this box.
@export var outer_corner_rect: Rect2 = Rect2(241.0, 211.0, 217.0, 228.0)
@export var inner_corner_rect: Rect2 = Rect2(316.0, 249.0, 180.0, 224.0)
## Size of a corner piece against the strip's thickness: at 1 it reaches from the strip's outer edge, in the open,
## to the strip's bottom edge, in the rock, so no stone sticks out further than the strip's.
@export_range(0.3, 2.0, 0.05) var corner_fit: float = 1.0
## Where another corner is closer than the strip's thickness, both shrink to this share of the gap between them,
## so steps and narrow walls are not piled with stones.
@export_range(0.3, 2.0, 0.05) var crowded_fit: float = 1.0

@export_group("Sinking")
## How far into the rock, in px, the stones take to darken fully, from the rock's surface.
@export_range(1.0, 200.0, 1.0, "suffix:px") var fade_length: float = 30.0
## Brightness of the stones deepest in the rock: 0 is black, 1 turns the darkening off.
@export_range(0.0, 1.0, 0.01) var fade_brightness: float = 0.12

@export_group("")
## Render layers for 2D lights, as the old stones had.
@export_flags_2d_render var strip_light_mask: int = 3

## One fade material per kind and size of piece, shared by the pieces alike, so a baked scene keeps few of them.
var _materials: Dictionary[String, ShaderMaterial] = {}


func _ready() -> void:
	if auto_build:
		rebuild()


## Makes the stones part of the scene being edited, so they are saved with it and can be edited by hand.
func bake() -> void:
	var scene_root: Node = get_tree().edited_scene_root if Engine.is_editor_hint() else owner
	if scene_root == null:
		push_warning("StoneRim: no scene to bake the stones into.")
		return
	auto_build = false
	for child: Node in get_children():
		child.owner = scene_root
	notify_property_list_changed()


func _build_pressed() -> void:
	if not auto_build:
		push_warning("StoneRim: the stones are baked. Turn Auto Build on to lay them again (hand edits are lost).")
		return
	rebuild()


## Throws away the stones, hand edits included, and lays them again from the tiles.
func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if tiles == null or tiles.tile_set == null or strip == null:
		return
	var cell: float = float(tiles.tile_set.tile_size.x)
	_materials.clear()
	var bounds: Rect2i = tiles.get_used_rect()
	var rock: Dictionary[Vector2i, bool] = {}
	for coords: Vector2i in tiles.get_used_cells():
		if tiles.get_cell_source_id(coords) == ROCK_SOURCE and tiles.get_cell_atlas_coords(coords) == ROCK_ATLAS \
				and tiles.get_cell_alternative_tile(coords) == ROCK_ALTERNATIVE:
			rock[coords] = true
	for side: Side in Side.values():
		var side_name: String = String(Side.find_key(side)).to_pascal_case()
		for run: Vector3i in _runs(rock, bounds, side):
			var piece: Sprite2D = _strip_for(run, side, cell)
			piece.name = "%s%d" % [side_name, get_child_count() + 1]
			add_child(piece)
	_add_corners(rock, bounds, cell)


## Straight runs of open edges on one side: (line, first, last) in cells, where line is the row for floors and
## ceilings and the column for walls. Edges that face out of the map are left bare: nobody sees them.
func _runs(rock: Dictionary[Vector2i, bool], bounds: Rect2i, side: Side) -> Array[Vector3i]:
	var open: Vector2i = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP][side]
	var horizontal: bool = side == Side.FLOOR or side == Side.CEILING
	var by_line: Dictionary[int, Array] = {}
	for coords: Vector2i in rock:
		var next: Vector2i = coords + open
		if rock.has(next) or not bounds.has_point(next):
			continue
		var line: int = coords.y if horizontal else coords.x
		if not by_line.has(line):
			by_line[line] = []
		by_line[line].append(coords.x if horizontal else coords.y)
	var runs: Array[Vector3i] = []
	for line: int in by_line:
		var steps: Array = by_line[line]
		steps.sort()
		var first: int = steps[0]
		for i: int in range(1, steps.size() + 1):
			if i == steps.size() or steps[i] != steps[i - 1] + 1:
				runs.append(Vector3i(line, first, steps[i - 1]))
				if i < steps.size():
					first = steps[i]
	return runs


func _strip_for(run: Vector3i, side: Side, cell: float) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = strip
	sprite.centered = false
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.scale = Vector2(strip_scale, strip_scale)
	sprite.light_mask = strip_light_mask
	var height: float = float(strip.get_height())
	var out: float = surface_row * strip_scale
	var inside: float = (height - surface_row) * strip_scale
	var start: float = run.y * cell
	var end: float = (run.z + 1) * cell
	var line: float = run.x * cell
	var along: float = start  # world coordinate the pattern is pinned to, so separate runs line up
	match side:
		Side.FLOOR:
			sprite.position = Vector2(start, line - out)
		Side.CEILING:
			sprite.flip_v = true
			sprite.position = Vector2(start, line + cell - inside)
		Side.LEFT_WALL:
			# Turned a quarter left: the strip's top faces left, into the open, and it runs upwards.
			sprite.rotation = -PI / 2.0
			sprite.position = Vector2(line - out, end)
			along = -end
		Side.RIGHT_WALL:
			# Turned a quarter right: the strip's top faces right and it runs downwards.
			sprite.rotation = PI / 2.0
			sprite.position = Vector2(line + cell + out, start)
	var offset: float = fposmod(along / strip_scale, float(strip.get_width()))
	sprite.region_rect = Rect2(offset, 0.0, (end - start) / strip_scale, height)
	sprite.material = _fade_material("strip", 0, Vector2.ZERO, strip_scale)
	return sprite


## A piece on every tiles' corner where the outline turns: an outer piece where one of the four cells around the
## corner is rock, an inner piece where three are.
func _add_corners(rock: Dictionary[Vector2i, bool], bounds: Rect2i, cell: float) -> void:
	var opens: Dictionary[Vector2i, Vector2i] = {}  # corner -> way into the open
	var outer: Dictionary[Vector2i, bool] = {}
	var checked: Dictionary[Vector2i, bool] = {}
	for coords: Vector2i in rock:
		for corner: Vector2i in [coords, coords + Vector2i.RIGHT, coords + Vector2i.DOWN, coords + Vector2i.ONE]:
			if checked.has(corner):
				continue
			checked[corner] = true
			_classify(rock, bounds, corner, opens, outer)
	var thickness: float = float(strip.get_height()) * strip_scale
	var reach: int = ceili(thickness / cell)
	for corner: Vector2i in opens:
		var size: float = thickness * corner_fit
		var gap: float = _gap_to_nearest(corner, opens, reach) * cell
		if gap < thickness:
			size = minf(size, gap * crowded_fit)
		var piece: Sprite2D = _corner_piece(corner, opens[corner], outer[corner], size, cell)
		piece.name = "%s%d" % ["OuterCorner" if outer[corner] else "InnerCorner", get_child_count() + 1]
		add_child(piece)


## Records the corner's way into the open, and whether it is an outer corner, when the outline turns there.
func _classify(rock: Dictionary[Vector2i, bool], bounds: Rect2i, corner: Vector2i,
		opens: Dictionary[Vector2i, Vector2i], outer: Dictionary[Vector2i, bool]) -> void:
	var rock_ways: Array[Vector2i] = []
	var air_ways: Array[Vector2i] = []
	for way: Vector2i in WAYS:
		var coords: Vector2i = corner + Vector2i(mini(way.x, 0), mini(way.y, 0))
		if rock.has(coords):
			rock_ways.append(way)
		elif bounds.has_point(coords):
			air_ways.append(way)
	if rock_ways.size() == 1 and air_ways.size() == 3:
		opens[corner] = -rock_ways[0]
		outer[corner] = true
	elif rock_ways.size() == 3 and air_ways.size() == 1:
		opens[corner] = air_ways[0]
		outer[corner] = false


## Distance, in cells, to the nearest other corner within reach; reach + 1 when there is none.
func _gap_to_nearest(corner: Vector2i, opens: Dictionary[Vector2i, Vector2i], reach: int) -> float:
	var nearest: float = reach + 1.0
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			if (dx != 0 or dy != 0) and opens.has(corner + Vector2i(dx, dy)):
				nearest = minf(nearest, Vector2(dx, dy).length())
	return nearest


## The piece fills a square of the given size whose outer corner sits on the strip's outer edge, in the open.
func _corner_piece(corner: Vector2i, open: Vector2i, is_outer: bool, size: float, cell: float) -> Sprite2D:
	var texture: Texture2D = outer_corner if is_outer else inner_corner
	var rect: Rect2 = outer_corner_rect if is_outer else inner_corner_rect
	var piece_scale: float = size / maxf(rect.size.x, rect.size.y)
	var out: float = surface_row * strip_scale
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	# Drawn open up and left, so the drawing's top-left stone goes out to (-out, -out) from the tiles' corner.
	sprite.offset = -rect.position - Vector2(out, out) / piece_scale
	sprite.scale = Vector2(piece_scale, piece_scale)
	sprite.light_mask = strip_light_mask
	# A quarter turn to the right for each step round from up-left to the open side.
	sprite.rotation = WAYS.find(open) * PI / 2.0
	sprite.position = Vector2(corner) * cell
	sprite.material = _fade_material("%s %.2f" % ["outer" if is_outer else "inner", size], 1 if is_outer else 2,
			-sprite.offset, piece_scale)
	return sprite


func _fade_material(key: String, mode: int, corner_point: Vector2, piece_scale: float) -> ShaderMaterial:
	if _materials.has(key):
		return _materials[key]
	var fade: ShaderMaterial = ShaderMaterial.new()
	fade.shader = FADE_SHADER
	fade.set_shader_parameter(&"mode", mode)
	fade.set_shader_parameter(&"surface_row", surface_row)
	fade.set_shader_parameter(&"corner_point", corner_point)
	# The shader counts in the drawing's pixels, so the world length is divided by the piece's scale.
	fade.set_shader_parameter(&"fade_length", fade_length / piece_scale)
	fade.set_shader_parameter(&"min_brightness", fade_brightness)
	_materials[key] = fade
	return fade
