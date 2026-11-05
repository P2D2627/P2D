# Builds Lust phase 2's scene from its text map, lust_phase_2.txt (decision F of docs/nivel1_desenho.md):
# rock and platform tiles, the man at P, a dog at d and a big dog at D, spikes at ^, collapsing platforms at
# =, gates at A and B and their unlockers at a and b, the way out at F, a camera zone for each zone line, the
# camera and the debug views. It overwrites the scene, so the text stays the map's only source: change the
# text and build again. From the repository root, with the editor closed:
# godot --headless --path Projeto --script res://levels/lust/build_lust_phase_2.gd
# The exit code is 0 when the scene was saved.
extends SceneTree

const MAP_PATH: String = "res://levels/lust/lust_phase_2.txt"
const SCENE_PATH: String = "res://levels/lust/lust_phase_2.tscn"
const LEVEL_SCRIPT: Script = preload("res://levels/level.gd")
const CAMERA_ZONE_SCRIPT: Script = preload("res://camera/camera_zone.gd")
const PHASE_EXIT_SCRIPT: Script = preload("res://levels/phase_exit.gd")
const DEMON_DEBUG_VIEW_SCRIPT: Script = preload("res://debug/demon_debug_view.gd")
const TILE_SET: TileSet = preload("res://scenes/levels/Lust/cave_placeholder_tiles.tres")
const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const DOG_SCENE: PackedScene = preload("res://demon/demon.tscn")
const BIG_DOG_SCENE: PackedScene = preload("res://demon/big_demon.tscn")
const GAME_CAMERA_SCENE: PackedScene = preload("res://camera/game_camera.tscn")
const DEBUG_OVERLAY_SCENE: PackedScene = preload("res://debug/debug_overlay.tscn")
const GATE_SCENE: PackedScene = preload("res://gates/gate.tscn")
const UNLOCKER_SCENE: PackedScene = preload("res://gates/gate_unlocker.tscn")
const SPIKES_SCENE: PackedScene = preload("res://traps/lethal_spikes.tscn")
const COLLAPSING_SCENE: PackedScene = preload("res://platforms/collapsing_platform.tscn")

## Scenes put in the map keep their edit state, as in the editor, so the saved map holds only what
## differs from them, and none of their own signal connections twice.
const EDIT_STATE: PackedScene.GenEditState = PackedScene.GEN_EDIT_STATE_INSTANCE
const TILE: float = 48.0
const ROCK: String = "#"
const AIR: String = "."
const START: String = "P"
const FINISH: String = "F"
const PLATFORM: String = "-"
const COLLAPSING: String = "="
const SPIKES: String = "^"
const DOG: String = "d"
const BIG_DOG: String = "D"
const LEGEND: String = "#.PF-=^dDABab"
## Each gate's letter, with its unlocker's letter next to it in the map.
const GATE_LETTERS: Dictionary[String, String] = {"A": "a", "B": "b"}
const GRID_START: String = "---"
## The rock tile of the placeholder tile set: source 0, atlas cell (0, 0), first alternative.
const TILE_SOURCE: int = 0
const TILE_ATLAS: Vector2i = Vector2i.ZERO
const ROCK_ALTERNATIVE: int = 0
const ONE_WAY_ALTERNATIVE: int = 1
## Camera zones sit on layer 10, CameraZones, and monitor nothing (README, collision layers).
const CAMERA_ZONE_LAYER: int = 1 << 9
## The exit looks for the man, on layer 2.
const PLAYER_LAYER: int = 2
const EXIT_SIZE: Vector2 = Vector2(96.0, 144.0)
const EXIT_COLOR: Color = Color(0.95, 0.4, 0.1, 0.6)
const BACKGROUND_COLOR: Color = Color(0.34, 0.29, 0.33)

## The map read and the scene saved: a builder that extends this one changes them in _init().
var _map_path: String = MAP_PATH
var _scene_path: String = SCENE_PATH
var _root_name: String = "LustPhase2"
var _rows: PackedStringArray = PackedStringArray()
var _width: int = 0
var _height: int = 0
## The "key: value" lines before the grid, in their order, as [key, value] pairs.
var _entries: Array[PackedStringArray] = []


func _initialize() -> void:
	if not _load_map():
		quit(1)
		return
	var saved: Error = _build()
	if saved == OK:
		print("Built %s: %d x %d tiles" % [_scene_path, _width, _height])
	else:
		printerr("build_lust_phase_2.gd: not built (%s)" % error_string(saved))
	quit(0 if saved == OK else 1)


func _load_map() -> bool:
	if not FileAccess.file_exists(_map_path):
		printerr("build_lust_phase_2.gd: no file at %s" % _map_path)
		return false
	var in_grid: bool = false
	for line: String in FileAccess.get_file_as_string(_map_path).split("\n"):
		line = line.strip_edges(false, true)
		if not in_grid:
			if line.strip_edges() == GRID_START:
				in_grid = true
			elif line.contains(":") and not line.get_slice(":", 0).contains(" "):
				_entries.append(PackedStringArray([line.get_slice(":", 0).strip_edges(),
						line.substr(line.find(":") + 1).strip_edges()]))
		elif not line.is_empty():
			for character: String in line:
				if not LEGEND.contains(character):
					printerr("build_lust_phase_2.gd: '%s' is not in the legend %s" % [character, LEGEND])
					return false
			_rows.append(line)
			_width = maxi(_width, line.length())
	_height = _rows.size()
	if _height == 0:
		printerr("build_lust_phase_2.gd: no grid after a %s line" % GRID_START)
		return false
	return true


func _build() -> Error:
	var starts: Array[Vector2i] = _find(START)
	var finishes: Array[Vector2i] = _find(FINISH)
	if starts.size() != 1 or finishes.size() != 1:
		printerr("build_lust_phase_2.gd: needs one %s and one %s, has %d and %d"
				% [START, FINISH, starts.size(), finishes.size()])
		return ERR_INVALID_DATA

	var root: Node2D = Node2D.new()
	root.name = _root_name
	root.set_script(LEVEL_SCRIPT)
	var size: Vector2 = Vector2(_width, _height) * TILE

	var background: Polygon2D = Polygon2D.new()
	background.name = "Background"
	background.color = BACKGROUND_COLOR
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)])
	root.add_child(background)

	# Before the tiles, so an open gate slides up behind the rock.
	var gates: Dictionary[String, Gate] = {}
	var gates_node: Node2D = _group("Gates", root)
	for letter: String in GATE_LETTERS:
		var gate: Gate = _gate(letter)
		gates_node.add_child(gate)
		gates[letter] = gate

	root.add_child(_tiles())

	var collapsing_node: Node2D = _group("CollapsingPlatforms", root)
	for run: Rect2i in _runs(COLLAPSING):
		var platform: CollapsingPlatform = COLLAPSING_SCENE.instantiate(EDIT_STATE) as CollapsingPlatform
		platform.name = "Collapsing%d" % (collapsing_node.get_child_count() + 1)
		platform.position = Vector2(run.position) * TILE
		platform.width_tiles = run.size.x
		collapsing_node.add_child(platform)

	var spikes_node: Node2D = _group("Spikes", root)
	for run: Rect2i in _runs(SPIKES):
		var spikes: LethalSpikes = SPIKES_SCENE.instantiate(EDIT_STATE) as LethalSpikes
		spikes.name = "Spikes%d" % (spikes_node.get_child_count() + 1)
		spikes.position = Vector2((run.position.x + run.size.x / 2.0) * TILE, (run.position.y + 1) * TILE)
		spikes.width_tiles = run.size.x
		spikes_node.add_child(spikes)

	var unlockers_node: Node2D = _group("GateUnlockers", root)
	for letter: String in GATE_LETTERS:
		var cells: Array[Vector2i] = _find(GATE_LETTERS[letter])
		if cells.size() != 1:
			printerr("build_lust_phase_2.gd: needs one %s, has %d" % [GATE_LETTERS[letter], cells.size()])
			root.free()
			return ERR_INVALID_DATA
		var unlocker: GateUnlocker = UNLOCKER_SCENE.instantiate(EDIT_STATE) as GateUnlocker
		unlocker.name = "Unlocker%s" % letter
		unlocker.position = _feet(cells[0])
		var opens: Array[Gate] = [gates[letter]]
		unlocker.gates = opens
		unlockers_node.add_child(unlocker)

	var zones: Node2D = _group("CameraZones", root)
	for value: String in _values_of("zone"):
		zones.add_child(_zone(value))

	var dogs: Array[Demon] = []
	var dogs_node: Node2D = _group("Dogs", root)
	for post: Vector2i in _find(DOG + BIG_DOG):
		var is_big: bool = _rows[post.y][post.x] == BIG_DOG
		var scene: PackedScene = BIG_DOG_SCENE if is_big else DOG_SCENE
		var dog: Demon = scene.instantiate(EDIT_STATE) as Demon
		dog.name = "%s%d" % ["BigDog" if is_big else "Dog", dogs_node.get_child_count() + 1]
		dog.position = _feet(post)
		# Each faces the map's middle, so they do not all look the same way.
		dog.faces_left = post.x > _width / 2
		dogs_node.add_child(dog)
		dogs.append(dog)

	root.add_child(_exit(finishes[0]))

	var player: Player = PLAYER_SCENE.instantiate(EDIT_STATE) as Player
	player.name = "Player"
	player.position = _feet(starts[0])
	root.add_child(player)
	root.set("player", player)

	var camera: GameCamera = GAME_CAMERA_SCENE.instantiate(EDIT_STATE) as GameCamera
	camera.name = "GameCamera"
	camera.position = player.position
	camera.player = player
	camera.level_tiles = root.get_node(^"Tiles") as TileMapLayer
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
	_add_level_parts(root, player)
	root.add_child(camera)

	for child: Node in root.get_children():
		_own(child, root)
	var scene_out: PackedScene = PackedScene.new()
	var packed: Error = scene_out.pack(root)
	if packed != OK:
		root.free()
		return packed
	var saved: Error = ResourceSaver.save(scene_out, _scene_path)
	root.free()
	return saved


## What a builder that extends this one puts in the level besides the map, before the camera.
func _add_level_parts(_root: Node2D, _player: Player) -> void:
	pass


func _group(group_name: String, root: Node) -> Node2D:
	var group: Node2D = Node2D.new()
	group.name = group_name
	root.add_child(group)
	return group


## The rock and the regular platforms.
func _tiles() -> TileMapLayer:
	var tiles: TileMapLayer = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = TILE_SET
	for row: int in _height:
		var line: String = _rows[row]
		for column: int in _width:
			var character: String = line[column] if column < line.length() else ROCK
			if character == ROCK:
				tiles.set_cell(Vector2i(column, row), TILE_SOURCE, TILE_ATLAS, ROCK_ALTERNATIVE)
			elif character == PLATFORM:
				tiles.set_cell(Vector2i(column, row), TILE_SOURCE, TILE_ATLAS, ONE_WAY_ALTERNATIVE)
	return tiles


## The gate over the box of letter's cells, standing on the row under them.
func _gate(letter: String) -> Gate:
	var cells: Array[Vector2i] = _find(letter)
	var box: Rect2i = Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		box = box.expand(cell).expand(cell + Vector2i.ONE)
	var gate: Gate = GATE_SCENE.instantiate(EDIT_STATE) as Gate
	gate.name = "Gate%s" % letter
	gate.position = Vector2((box.position.x + box.size.x / 2.0) * TILE, box.end.y * TILE)
	gate.width_tiles = box.size.x
	gate.height_tiles = box.size.y
	return gate


func _exit(cell: Vector2i) -> Area2D:
	var exit: Area2D = Area2D.new()
	exit.name = "PhaseExit"
	exit.set_script(PHASE_EXIT_SCRIPT)
	exit.collision_layer = 0
	exit.collision_mask = PLAYER_LAYER
	exit.monitorable = false
	exit.position = _feet(cell)
	exit.set("next_scene_path", _value_of("next_scene"))
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = EXIT_SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -EXIT_SIZE.y / 2.0)
	exit.add_child(shape)
	var drawing: Polygon2D = Polygon2D.new()
	drawing.name = "Placeholder"
	drawing.color = EXIT_COLOR
	var half: float = EXIT_SIZE.x / 2.0
	drawing.polygon = PackedVector2Array([Vector2(-half, -EXIT_SIZE.y), Vector2(half, -EXIT_SIZE.y),
			Vector2(half, 0.0), Vector2(-half, 0.0)])
	exit.add_child(drawing)
	return exit


## A camera zone from a line "name first_column first_row last_column last_row key=value ...". The keys
## are the zone's own properties.
func _zone(value: String) -> Area2D:
	var words: PackedStringArray = value.split(" ", false)
	var first: Vector2i = Vector2i(words[1].to_int(), words[2].to_int())
	var last: Vector2i = Vector2i(words[3].to_int(), words[4].to_int())
	var cells: Rect2i = Rect2i(first, last - first + Vector2i.ONE)
	var zone: Area2D = Area2D.new()
	zone.name = "Zone%s" % words[0]
	zone.set_script(CAMERA_ZONE_SCRIPT)
	zone.collision_layer = CAMERA_ZONE_LAYER
	zone.collision_mask = 0
	zone.monitoring = false
	zone.monitorable = false
	for word: String in words.slice(5):
		var key: String = word.get_slice("=", 0)
		var text: String = word.get_slice("=", 1)
		zone.set(key, text == "true" if text == "true" or text == "false" else text.to_float())
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(cells.size) * TILE
	shape.shape = rectangle
	shape.position = (Vector2(cells.position) + Vector2(cells.size) / 2.0) * TILE
	zone.add_child(shape)
	return zone


## Where something standing on the tile under cell has its feet: its origin, as for the man and the dogs.
func _feet(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)


## Every cell holding one of characters, top row first.
func _find(characters: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row: int in _height:
		var line: String = _rows[row]
		for column: int in line.length():
			if characters.contains(line[column]):
				cells.append(Vector2i(column, row))
	return cells


## The runs of character along each row, one tile high.
func _runs(character: String) -> Array[Rect2i]:
	var runs: Array[Rect2i] = []
	for row: int in _height:
		var line: String = _rows[row]
		var column: int = 0
		while column < line.length():
			if line[column] != character:
				column += 1
				continue
			var first: int = column
			while column < line.length() and line[column] == character:
				column += 1
			runs.append(Rect2i(first, row, column - first, 1))
	return runs


func _value_of(key: String) -> String:
	for entry: PackedStringArray in _entries:
		if entry[0] == key:
			return entry[1]
	return ""


func _values_of(key: String) -> PackedStringArray:
	var values: PackedStringArray = PackedStringArray()
	for entry: PackedStringArray in _entries:
		if entry[0] == key:
			values.append(entry[1])
	return values


## Makes root own node and what it holds, so the scene keeps them, but not the inside of another scene put
## in it: that scene keeps its own.
func _own(node: Node, root: Node) -> void:
	node.owner = root
	if not node.scene_file_path.is_empty():
		return
	for child: Node in node.get_children():
		_own(child, root)
