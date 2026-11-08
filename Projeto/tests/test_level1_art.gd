# Checks level 1's painted pieces: they sit in level 1 itself, under a plain node Art right over the rock tiles,
# so they are placed by hand with the tiles in view; they are only drawings, with nothing that collides, so the
# tiles stay the only rock the man stands on; and building the map again carries them over.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_art.gd
extends SceneTree

const LEVEL_PATH: String = "res://levels/lust/level1.tscn"
const BUILDER_PATH: String = "res://levels/lust/build_level1.gd"


func _initialize() -> void:
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	var results: Array[bool] = []
	results.append(_the_art_is_in_level1_right_over_the_tiles(level))
	results.append(_the_art_is_drawings_only(level))
	results.append(_building_again_carries_the_art_over(level))
	level.free()
	quit(0 if not results.has(false) else 1)


func _the_art_is_in_level1_right_over_the_tiles(level: Node) -> bool:
	var art: Node = level.get_node_or_null(^"Art")
	var tiles: Node = level.get_node_or_null(^"Tiles")
	var ok: bool = art is Node2D and tiles != null and art.scene_file_path.is_empty() \
			and art.get_index() == tiles.get_index() + 1
	var detail: String = "no Art node" if art == null else "Art from '%s' at %d, Tiles at %d" % [
			art.scene_file_path, art.get_index(), tiles.get_index() if tiles != null else -1]
	return _report(ok, "the art is a plain node of level 1, right over the tiles (%s)" % detail)


func _the_art_is_drawings_only(level: Node) -> bool:
	var art: Node = level.get_node_or_null(^"Art")
	if art == null:
		return _report(false, "the art is drawings only (no Art node)")
	var colliding: Array[Node] = art.find_children("*", "CollisionObject2D", true, false)
	var tiles: Array[Node] = art.find_children("*", "TileMapLayer", true, false)
	var sprites: Array[Node] = art.find_children("*", "Sprite2D", true, false)
	var ok: bool = colliding.is_empty() and tiles.is_empty() and not sprites.is_empty()
	return _report(ok, "the art is drawings only (%d sprites, %d colliding nodes, %d tile layers)" % [
			sprites.size(), colliding.size(), tiles.size()])


func _building_again_carries_the_art_over(level: Node) -> bool:
	var builder: Object = (load(BUILDER_PATH) as GDScript).new()
	var carried: Node2D = builder.call(&"art_from_old_scene") as Node2D
	builder.free()
	var placed: Array[String] = _pieces_of(level.get_node_or_null(^"Art"))
	var kept: Array[String] = _pieces_of(carried)
	carried.free()
	var ok: bool = not placed.is_empty() and kept == placed
	return _report(ok, "building again keeps the art's %d pieces where they were placed (%d carried)" % [
			placed.size(), kept.size()])


## Each sprite under art, by its path from art, with its position and texture, in tree order.
func _pieces_of(art: Node) -> Array[String]:
	var pieces: Array[String] = []
	if art == null:
		return pieces
	for node: Node in art.find_children("*", "Sprite2D", true, false):
		var sprite: Sprite2D = node as Sprite2D
		pieces.append("%s %s %s" % [art.get_path_to(sprite), sprite.position,
				sprite.texture.resource_path if sprite.texture != null else "none"])
	return pieces


func _report(ok: bool, what: String) -> bool:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	return ok
