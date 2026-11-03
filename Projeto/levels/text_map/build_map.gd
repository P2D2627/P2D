# Builds a level's scene from its text map (decision F of docs/nivel1_desenho.md): rock tiles, the
# man at P, the dogs at their posts, a camera zone over each section and each shaft, a marker where
# the map ends (F), the camera and the debug views. It overwrites the scene, so the text stays the
# map's only source: change the text and build again. Each text file given after -- is saved as a
# .tscn of the same name next to it. From the repository root, with the editor closed:
# godot --headless --path Projeto --script res://levels/text_map/build_map.gd -- res://levels/lust/lust_phase_1.txt
# The exit code is 0 when every map was saved.
extends SceneTree

const MapText = preload("res://levels/text_map/map_text.gd")
const LEVEL_SCRIPT: Script = preload("res://levels/level.gd")
const CAMERA_ZONE_SCRIPT: Script = preload("res://camera/camera_zone.gd")
const DEMON_DEBUG_VIEW_SCRIPT: Script = preload("res://debug/demon_debug_view.gd")
const TILE_SET: TileSet = preload("res://scenes/levels/Lust/cave_placeholder_tiles.tres")
const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
const GAME_CAMERA_SCENE: PackedScene = preload("res://camera/game_camera.tscn")
const DEBUG_OVERLAY_SCENE: PackedScene = preload("res://debug/debug_overlay.tscn")

## Scenes put in the map keep their edit state, as in the editor, so the saved map holds only what
## differs from them, and none of their own signal connections twice.
const EDIT_STATE: PackedScene.GenEditState = PackedScene.GEN_EDIT_STATE_INSTANCE
const TILE: float = 48.0
## The rock tile of the placeholder tile set: source 0, atlas cell (0, 0), first alternative.
const ROCK_SOURCE: int = 0
const ROCK_ATLAS: Vector2i = Vector2i.ZERO
## Camera zones sit on layer 10, CameraZones, and monitor nothing (README, collision layers).
const CAMERA_ZONE_LAYER: int = 1 << 9
## A section's zone as the cave's rooms (README, Câmara): the screen's bottom on the zone's, with two
## more tiles below it; its zoom comes from the text's zone_zoom.
const SECTION_VERTICAL_ANCHOR: float = 1.0
const SECTION_BOTTOM_MARGIN: float = 96.0
## A shaft's zone as the cave's: two tiles of rock on each side, held still sideways, close in, with
## the screen's edge on the side of the level's inside so its excess shows the outer wall.
const SHAFT_SIDE_ROCK: int = 2
const SHAFT_ZOOM: float = 2.0
const SHAFT_BOTTOM_MARGIN: float = 200.0
const BACKGROUND_COLOR: Color = Color(0.34, 0.29, 0.33)
const MURAL_COLOR: Color = Color(0.85, 0.78, 0.55)
## The mural's cross: bar width and where the crossbar sits, as shares of the mural's box.
const MURAL_BAR: float = 0.3
const MURAL_CROSSBAR_TOP: float = 0.2


func _initialize() -> void:
	var paths: PackedStringArray = OS.get_cmdline_user_args()
	if paths.is_empty():
		printerr("build_map.gd: give the map's text after --, e.g. -- res://levels/lust/lust_phase_1.txt")
		quit(1)
		return
	var failed: bool = false
	for path: String in paths:
		var saved: Error = _build(path)
		if saved == OK:
			print("Built %s" % path.get_basename() + ".tscn")
		else:
			printerr("build_map.gd: %s not built (%s)" % [path, error_string(saved)])
			failed = true
	quit(1 if failed else 0)


func _build(path: String) -> Error:
	var map: MapText = MapText.new()
	if not map.load_file(path):
		printerr("build_map.gd: %s" % map.error)
		return ERR_PARSE_ERROR
	var starts: Array[Vector2i] = map.find(MapText.START)
	if starts.size() != 1:
		printerr("build_map.gd: %s needs one %s, has %d" % [path, MapText.START, starts.size()])
		return ERR_INVALID_DATA

	var root: Node2D = Node2D.new()
	root.name = map.get_value("map", path.get_file().get_basename()).to_pascal_case()
	root.set_script(LEVEL_SCRIPT)
	var size: Vector2 = Vector2(map.width, map.height) * TILE

	var background: Polygon2D = Polygon2D.new()
	background.name = "Background"
	background.color = BACKGROUND_COLOR
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)])
	root.add_child(background)

	var murals: Array[Vector2i] = map.find(MapText.MURAL)
	if not murals.is_empty():
		root.add_child(_mural(murals))

	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = TILE_SET
	for row: int in map.height:
		for column: int in map.width:
			if map.is_rock(column, row):
				tiles.set_cell(Vector2i(column, row), ROCK_SOURCE, ROCK_ATLAS)
	root.add_child(tiles)

	var zones: Node2D = Node2D.new()
	zones.name = "CameraZones"
	root.add_child(zones)
	var zoom: float = float(map.get_value("zone_zoom", "1.0"))
	for value: String in map.values_of("section"):
		var zone: Area2D = _zone("Zone" + MapText.name_of(value).replace(".", "_"), MapText.rect_of(value))
		zone.set("zoom", zoom)
		zone.set("vertical_anchor", SECTION_VERTICAL_ANCHOR)
		zone.set("bottom_margin", SECTION_BOTTOM_MARGIN)
		zones.add_child(zone)
	var shaft_number: int = 0
	for value: String in map.values_of("shaft"):
		shaft_number += 1
		var cells: Rect2i = MapText.rect_of(value).grow_individual(SHAFT_SIDE_ROCK, 0, SHAFT_SIDE_ROCK, 0)
		var zone: Area2D = _zone("Shaft%d" % shaft_number, cells)
		zone.set("limit_horizontally", true)
		# A shaft on the map's left half has the level's inside on its right, and the other way round.
		zone.set("horizontal_anchor", 1.0 if cells.get_center().x < map.width / 2 else 0.0)
		zone.set("zoom", SHAFT_ZOOM)
		zone.set("auto_zoom", false)
		zone.set("bottom_margin", SHAFT_BOTTOM_MARGIN)
		zones.add_child(zone)

	var dogs: Array[Demon] = []
	var dog_number: int = 0
	for post: Vector2i in map.find(MapText.DOG_FACING_LEFT + MapText.DOG_FACING_RIGHT):
		dog_number += 1
		var dog: Demon = DEMON_SCENE.instantiate(EDIT_STATE) as Demon
		dog.name = "Dog%d" % dog_number
		dog.position = _feet(post)
		dog.faces_left = map.at(post.x, post.y) == MapText.DOG_FACING_LEFT
		root.add_child(dog)
		dogs.append(dog)

	var ends: Array[Vector2i] = map.find(MapText.END)
	if not ends.is_empty():
		var end: Marker2D = Marker2D.new()
		end.name = "MapEnd"
		var middle: Vector2 = Vector2.ZERO
		for cell: Vector2i in ends:
			middle += _feet(cell)
		end.position = middle / ends.size()
		root.add_child(end)

	var player: Player = PLAYER_SCENE.instantiate(EDIT_STATE) as Player
	player.name = "Player"
	player.position = _feet(starts[0])
	root.add_child(player)
	root.set("player", player)

	var camera: GameCamera = GAME_CAMERA_SCENE.instantiate(EDIT_STATE) as GameCamera
	camera.name = "GameCamera"
	camera.position = player.position
	camera.player = player
	camera.level_tiles = tiles
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)

	var overlay: DebugOverlay = DEBUG_OVERLAY_SCENE.instantiate(EDIT_STATE) as DebugOverlay
	overlay.name = "DebugOverlay"
	overlay.player = player
	overlay.camera = camera
	root.add_child(overlay)

	var dog_view: Node2D = Node2D.new()
	dog_view.name = "DemonDebugView"
	dog_view.set_script(DEMON_DEBUG_VIEW_SCRIPT)
	dog_view.process_mode = Node.PROCESS_MODE_ALWAYS
	dog_view.set("overlay", overlay)
	dog_view.set("demons", dogs)
	dog_view.set("player", player)
	root.add_child(dog_view)
	root.add_child(camera)

	for child: Node in root.get_children():
		_own(child, root)
	var scene: PackedScene = PackedScene.new()
	var packed: Error = scene.pack(root)
	if packed != OK:
		root.free()
		return packed
	var saved: Error = ResourceSaver.save(scene, path.get_basename() + ".tscn")
	root.free()
	return saved


## A camera zone over cells, in the shape's rectangle; its values are set by the caller.
func _zone(zone_name: String, cells: Rect2i) -> Area2D:
	var zone: Area2D = Area2D.new()
	zone.name = zone_name
	zone.set_script(CAMERA_ZONE_SCRIPT)
	zone.collision_layer = CAMERA_ZONE_LAYER
	zone.collision_mask = 0
	zone.monitoring = false
	zone.monitorable = false
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(cells.size) * TILE
	shape.shape = rectangle
	shape.position = (Vector2(cells.position) + Vector2(cells.size) / 2.0) * TILE
	zone.add_child(shape)
	return zone


## Where something standing on the tile under cell has its feet: its origin, as for the man and
## the dogs.
func _feet(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)


## A cross over the box around the mural cells, drawn behind the rock.
func _mural(cells: Array[Vector2i]) -> Polygon2D:
	var top_left: Vector2i = cells[0]
	var bottom_right: Vector2i = cells[0]
	for cell: Vector2i in cells:
		top_left = top_left.min(cell)
		bottom_right = bottom_right.max(cell)
	var box: Rect2 = Rect2(Vector2(top_left) * TILE, Vector2(bottom_right - top_left + Vector2i.ONE) * TILE)
	var half_bar: float = box.size.x * MURAL_BAR / 2.0
	var middle: float = box.get_center().x
	var bar_top: float = box.position.y + box.size.y * MURAL_CROSSBAR_TOP
	var bar_bottom: float = bar_top + 2.0 * half_bar
	var mural: Polygon2D = Polygon2D.new()
	mural.name = "Mural"
	mural.color = MURAL_COLOR
	mural.polygon = PackedVector2Array([
		Vector2(middle - half_bar, box.position.y), Vector2(middle + half_bar, box.position.y),
		Vector2(middle + half_bar, bar_top), Vector2(box.end.x, bar_top),
		Vector2(box.end.x, bar_bottom), Vector2(middle + half_bar, bar_bottom),
		Vector2(middle + half_bar, box.end.y), Vector2(middle - half_bar, box.end.y),
		Vector2(middle - half_bar, bar_bottom), Vector2(box.position.x, bar_bottom),
		Vector2(box.position.x, bar_top), Vector2(middle - half_bar, bar_top),
	])
	return mural


## Makes root own node and what it holds, so the scene keeps them, but not the inside of another
## scene put in it: that scene keeps its own.
func _own(node: Node, root: Node) -> void:
	node.owner = root
	if not node.scene_file_path.is_empty():
		return
	for child: Node in node.get_children():
		_own(child, root)
