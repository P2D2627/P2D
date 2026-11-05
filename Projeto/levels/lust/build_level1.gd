# Builds level 1 as one scene from its text map, level1.txt: the tutorial, phase 1 and phase 2 on one grid,
# with no load between them. The map's rock, platforms, dogs and the rest go in as in phase 2's builder. The
# tutorial's prompts, Velvet and the corridor's demon come from the scene they were made in, which stays as it
# is. Two save points hold where a death starts over: past the tutorial, at phase 1's start; inside phase 2,
# at phase 2's start. It overwrites the scene, so the text stays the map's only source. From the repository
# root, with the editor closed:
# godot --headless --path Projeto --script res://levels/lust/build_level1.gd
# The exit code is 0 when the scene was saved.
extends "res://levels/lust/build_lust_phase_2.gd"

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


func _init() -> void:
	_map_path = "res://levels/lust/level1.txt"
	_scene_path = "res://levels/lust/level1.tscn"
	_root_name = "Level1"


func _add_level_parts(root: Node2D, player: Player) -> void:
	var tutorial: Node2D = _tutorial(player)
	root.add_child(tutorial)
	# Behind the man, as in its old scene, so he walks in front of the prompts.
	root.move_child(tutorial, player.get_index())
	root.add_child(_save_point("TutorialSave", TUTORIAL_DONE_EVENT, TUTORIAL_SAVE_CELL, TUTORIAL_SAVE_TILES,
			PHASE_1_START_CELL, player))
	root.add_child(_save_point("Phase2Save", PHASE_2_REACHED_EVENT, PHASE_2_SAVE_CELL, PHASE_2_SAVE_TILES,
			PHASE_2_START_CELL, player))


func _tutorial(player: Player) -> Node2D:
	var source: Node = TUTORIAL_SCENE.instantiate(EDIT_STATE)
	var tutorial: Node2D = source.get_node(^"Tutorial") as Node2D
	source.remove_child(tutorial)
	source.free()
	tutorial.position = TUTORIAL_POSITION
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
