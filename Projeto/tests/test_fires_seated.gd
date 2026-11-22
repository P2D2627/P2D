# Checks that the fires of the lit level 1 burn in the rock's stones and not on top of them (#284). Each
# flame's drawing thins out at its base: on the sheets, the bonfire's flame takes 24 rows to reach its
# full width, 10.8 px at its 0.45, the most of the four kinds. The rim's stones stick 20.4 px out of the
# rock (Surface Row 34 at Strip Scale 0.6) and are drawn in front of the fires. So each fire stands on
# rock with open air above it, its base at least 10.8 px below the rock's top, where the stones hide the
# thin part, and no deeper than the stones reach, so they never hide more of the flame than its base.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_fires_seated.gd
extends "res://tests/support/base_test.gd"

const LIT_SCENE: String = "res://scenes/levels/lust/level1_lit.tscn"
## Frames the rig gets to set itself up, which it does once the level is in the tree.
const SETUP_FRAMES: int = 120
## The most a flame's drawing thins out at its base, on screen (see the top).
const THIN_BASE: float = 10.8

var _failed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = (load(LIT_SCENE) as PackedScene).instantiate()
	root.add_child(level)
	for i: int in SETUP_FRAMES:
		await physics_frame
	var tiles := level.get_node(^"Tiles") as TileMapLayer
	var rim := level.get_node(^"Art/StoneRim") as StoneRim
	var fires: Node = level.get_node_or_null(^"ProtoFires")
	_check(fires != null and fires.get_child_count() > 0, "The lit level has fires: %s"
			% [fires.get_child_count() if fires != null else 0])
	if fires != null:
		_each_fire_sits_in_the_stones(fires, tiles, rim.surface_row * rim.strip_scale)
	level.queue_free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _each_fire_sits_in_the_stones(fires: Node, tiles: TileMapLayer, stones_out: float) -> void:
	var tile_height: float = float(tiles.tile_set.tile_size.y) * tiles.global_scale.y
	var wrong: Array[String] = []
	var least: float = INF
	var most: float = -INF
	for fire: Node in fires.get_children():
		var base: Vector2 = (fire as Node2D).global_position
		var cell: Vector2i = tiles.local_to_map(tiles.to_local(base))
		var on_rock: bool = _is_rock(tiles, cell) and not _is_rock(tiles, cell + Vector2i.UP)
		var rock_top: float = tiles.to_global(tiles.map_to_local(cell)).y - tile_height * 0.5
		var sunk: float = base.y - rock_top
		least = minf(least, sunk)
		most = maxf(most, sunk)
		if not on_rock or sunk < THIN_BASE or sunk > stones_out:
			wrong.append("%s (cell %s, on rock %s, %.1f px below its top)" % [base, cell, on_rock, sunk])
	_check(wrong.is_empty(), "Each of %d fires stands on rock, its base %.1f to %.1f px below the top"
			% [fires.get_child_count(), THIN_BASE, stones_out]
			+ " (measured %.1f to %.1f)%s" % [least, most, "" if wrong.is_empty() else "; wrong: %s" % [wrong]])


func _is_rock(tiles: TileMapLayer, cell: Vector2i) -> bool:
	return tiles.get_cell_source_id(cell) != -1 and tiles.get_cell_alternative_tile(cell) == 0


func _check(passed: bool, what: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL", what])
	_failed = _failed or not passed
