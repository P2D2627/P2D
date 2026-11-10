# Builds level 1 as one scene from its text map, level1.txt: the tutorial, phase 1 and phase 2 on one grid,
# with no load between them. The map's rock, platforms, dogs and the rest go in as in phase 2's builder. The
# tutorial's prompts, Velvet and the corridor's demon come from the scene they were made in, which stays as it
# is. Two save points hold where a death starts over: past the tutorial, at phase 1's start; inside phase 2,
# at phase 2's start. The camera's zones and lookouts come from their own file, level1_camera.txt, so a map made
# again elsewhere keeps them.
#
# The text makes the level's first version; from then on the scene is the level: tiles, dogs, spikes, platforms and
# zones are edited by hand in the editor, tile by tile and piece by piece. So it never overwrites a scene that is
# already there, unless asked with --force, which throws the hand edits to the scene away (the Art and the Backdrop
# are carried over even then). From the repository root, with the editor closed:
# godot --headless --path Projeto --script res://levels/lust/build_level1.gd
# godot --headless --path Projeto --script res://levels/lust/build_level1.gd -- --force
# The exit code is 0 when the scene was saved, and 1 when it was not, a scene already there included.
extends "res://levels/lust/build_lust_phase_2.gd"

## Passed after -- to build over a scene that is already there.
const FORCE_ARGUMENT: String = "--force"

const TUTORIAL_SCENE: PackedScene = preload("res://scenes/levels/Lust/LustLevel_Phase1_Cave.tscn")
const SAVE_POINT_SCRIPT: Script = preload("res://levels/save_point.gd")
## Where the tutorial's node goes, so that its floor stays on the map's tutorial floor.
const TUTORIAL_POSITION: Vector2 = Vector2(0.0, 16608.0)
## Between the tutorial and phase 1, across the walk's whole height: the tile and the height, in tiles.
const TUTORIAL_SAVE_CELL: Vector2i = Vector2i(98, 360)
const TUTORIAL_SAVE_TILES: Vector2i = Vector2i(1, 6)
## Where the man starts once past the tutorial: the tile he stands over, at S.
const PHASE_1_START_CELL: Vector2i = Vector2i(112, 365)
## At the top of the chimney into phase 2, across its whole width.
const PHASE_2_SAVE_CELL: Vector2i = Vector2i(352, 247)
const PHASE_2_SAVE_TILES: Vector2i = Vector2i(3, 2)
## Where the man starts once inside phase 2: phase 2's own start.
const PHASE_2_START_CELL: Vector2i = Vector2i(351, 246)
## The man's event in the tutorial's save, as in the old scene, so a game already past it stays past it.
const TUTORIAL_DONE_EVENT: StringName = &"tutorial_done"
const PHASE_2_REACHED_EVENT: StringName = &"lust_phase_2_reached"
## The node with the level's painted pieces, placed by hand in the editor right over the rock tiles. The map
## does not know them, so building again carries this node over from the scene it overwrites.
const ART_NODE: NodePath = ^"Art"
## The node with the rocks in the distance, also placed by hand and carried over the same way. It goes right over
## the background and under the rock tiles, so the rock hides them.
const BACKDROP_NODE: NodePath = ^"Backdrop"


func _init() -> void:
	_map_path = "res://levels/lust/level1.txt"
	_scene_path = "res://levels/lust/level1.tscn"
	_camera_path = "res://levels/lust/level1_camera.txt"
	_root_name = "Level1"


func _initialize() -> void:
	if ResourceLoader.exists(_scene_path) and not OS.get_cmdline_user_args().has(FORCE_ARGUMENT):
		printerr("build_level1.gd: %s is already there and is edited by hand, so it was not built. Build over it, "
				% _scene_path + "throwing the hand edits away, with -- %s." % FORCE_ARGUMENT)
		quit(1)
		return
	super._initialize()


func _add_level_parts(root: Node2D, player: Player) -> void:
	var backdrop: Node2D = node_from_old_scene(BACKDROP_NODE)
	root.add_child(backdrop)
	root.move_child(backdrop, root.get_node(^"Background").get_index() + 1)
	var art: Node2D = art_from_old_scene()
	root.add_child(art)
	# Right over the rock, then the man and the dogs, then the art: they walk behind the stones of the rim, and the
	# traps and the rest stay in front.
	var over_tiles: int = root.get_node(^"Tiles").get_index() + 1
	root.move_child(player, over_tiles)
	root.move_child(root.get_node(^"Dogs"), over_tiles + 1)
	root.move_child(art, over_tiles + 2)
	var tutorial: Node2D = _tutorial(player)
	root.add_child(tutorial)
	# Behind the man, as in its old scene, so he walks in front of the prompts.
	root.move_child(tutorial, player.get_index())
	root.add_child(_save_point("TutorialSave", TUTORIAL_DONE_EVENT, TUTORIAL_SAVE_CELL, TUTORIAL_SAVE_TILES,
			PHASE_1_START_CELL, player))
	root.add_child(_save_point("Phase2Save", PHASE_2_REACHED_EVENT, PHASE_2_SAVE_CELL, PHASE_2_SAVE_TILES,
			PHASE_2_START_CELL, player))
	# The debug text starts hidden in level 1; F3 (Toggle Debug Overlay) still shows it.
	(root.get_node(^"DebugOverlay") as DebugOverlay).start_visible = false


## The Art node of the scene about to be overwritten, with its pieces as they were placed, or an empty one when
## there is no scene yet or it has no Art. Public so that a test can check it without building.
func art_from_old_scene() -> Node2D:
	return node_from_old_scene(ART_NODE)


## The node at path in the scene about to be overwritten, with its children as they were placed, or an empty one
## with that name when there is no scene yet or it has no such node.
func node_from_old_scene(path: NodePath) -> Node2D:
	if ResourceLoader.exists(_scene_path):
		# Uncached, so the scene saved over it afterwards is not the one held in memory.
		var old_scene: PackedScene = ResourceLoader.load(_scene_path, "",
				ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		var old: Node = old_scene.instantiate(EDIT_STATE)
		var kept: Node2D = old.get_node_or_null(path) as Node2D
		if kept != null:
			old.remove_child(kept)
		old.free()
		if kept != null:
			return kept
	var empty: Node2D = Node2D.new()
	empty.name = String(path)
	return empty


func _tutorial(player: Player) -> Node2D:
	var source: Node = TUTORIAL_SCENE.instantiate(EDIT_STATE)
	var tutorial: Node2D = source.get_node(^"Tutorial") as Node2D
	source.remove_child(tutorial)
	source.free()
	tutorial.position = TUTORIAL_POSITION
	(tutorial as TutorialHints).player = player
	var velvet: TutorialDemon = tutorial.get_node(^"TutorialDemon") as TutorialDemon
	velvet.player = player
	velvet.crucifix = player.get_node(^"Crucifix") as Crucifix
	return tutorial


## A save point over tiles cells from first_cell, and the marker of where the man starts once it is reached.
func _save_point(point_name: String, event: StringName, first_cell: Vector2i, cells: Vector2i,
		start_cell: Vector2i, player: Player) -> Area2D:
	var point: Area2D = Area2D.new()
	point.name = point_name
	point.set_script(SAVE_POINT_SCRIPT)
	point.collision_layer = 0
	point.collision_mask = PLAYER_LAYER
	point.monitorable = false
	point.position = (Vector2(first_cell) + Vector2(cells) / 2.0) * TILE
	point.set("event", event)
	point.set("player", player)
	var respawn: Marker2D = Marker2D.new()
	respawn.name = "Respawn"
	respawn.top_level = true
	respawn.position = _feet(start_cell)
	point.add_child(respawn)
	point.set("respawn", respawn)
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(cells) * TILE
	shape.shape = rectangle
	point.add_child(shape)
	return point
