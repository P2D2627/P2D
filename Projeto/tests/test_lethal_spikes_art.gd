# Checks the spikes' brambles (#263): with no Art there are none, and the teeth are drawn; with Art
# there is one per tile, standing on the floor, as tall as the teeth give or take the spread and as
# wide as the drawing's shape makes it; together they cover the part that kills with no gap and
# reach above it; a strip looks the same each time it is built at the same spot, and two strips at
# two spots differ; on a long strip their size and mirroring vary; and the scene's spikes carry the
# bramble drawing.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --path Projeto --script res://tests/test_lethal_spikes_art.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const BRAMBLE_PATH: String = "res://assets/sprites/traps/bramble.png"
const TILE: float = 48.0
## A stand-in drawing with the bramble's shape, so the checks on the layout do not hang on the art.
const ART_SIZE := Vector2i(88, 64)
const WIDTH_TILES: int = 5
## A strip as long as the longest in level 1, for its brambles to show their variety.
const LONG_WIDTH_TILES: int = 26
const SPOT := Vector2(480.0, 960.0)
const OTHER_SPOT := Vector2(1440.0, 960.0)
## How far apart two lengths may be and still count as the same, in px.
const SAME: float = 0.001


func _initialize() -> void:
	var art := ImageTexture.create_from_image(
			Image.create_empty(ART_SIZE.x, ART_SIZE.y, false, Image.FORMAT_RGBA8))
	var results: Array[bool] = []
	results.append(_with_no_art_there_are_no_brambles())
	results.append(_one_per_tile_stands_on_the_floor_as_tall_as_the_teeth(art))
	results.append(_together_they_cover_the_part_that_kills_and_reach_above_it(art))
	results.append(_a_strip_looks_the_same_each_time_and_two_strips_differ(art))
	results.append(_on_a_long_strip_their_size_and_mirroring_vary(art))
	results.append(_the_scene_s_spikes_carry_the_bramble())
	finish(results)


func _with_no_art_there_are_no_brambles() -> bool:
	var spikes: LethalSpikes = _strip(null, WIDTH_TILES, SPOT)
	var count: int = spikes.get_brambles().size()
	spikes.free()
	return report(count == 0, "With no art, %d brambles (the teeth are drawn)" % count)


func _one_per_tile_stands_on_the_floor_as_tall_as_the_teeth(art: Texture2D) -> bool:
	var spikes: LethalSpikes = _strip(art, WIDTH_TILES, SPOT)
	var brambles: Array[LethalSpikes.Bramble] = spikes.get_brambles()
	var lowest: float = spikes.tooth_height * (1.0 - spikes.art_size_spread)
	var highest: float = spikes.tooth_height * (1.0 + spikes.art_size_spread)
	var shape: float = float(ART_SIZE.x) / float(ART_SIZE.y)
	var wrong: Array[String] = []
	for bramble: LethalSpikes.Bramble in brambles:
		var size: Vector2 = bramble.rect.size
		if absf(bramble.rect.end.y) > SAME or size.y < lowest - SAME or size.y > highest + SAME \
				or absf(size.x / size.y - shape) > SAME:
			wrong.append(str(bramble.rect))
	spikes.free()
	return report(brambles.size() == WIDTH_TILES and wrong.is_empty(),
			"%d brambles for %d tiles, %.0f to %.0f px tall; off the floor or the size: %s"
			% [brambles.size(), WIDTH_TILES, lowest, highest, wrong])


func _together_they_cover_the_part_that_kills_and_reach_above_it(art: Texture2D) -> bool:
	var spikes: LethalSpikes = _strip(art, LONG_WIDTH_TILES, SPOT)
	var brambles: Array[LethalSpikes.Bramble] = spikes.get_brambles()
	var kill_right: float = LONG_WIDTH_TILES * TILE / 2.0 - spikes.side_inset
	var gaps: Array[String] = []
	var low: Array[String] = []
	for k: int in brambles.size():
		var rect: Rect2 = brambles[k].rect
		if k > 0 and rect.position.x > brambles[k - 1].rect.end.x:
			gaps.append("%.1f to %.1f" % [brambles[k - 1].rect.end.x, rect.position.x])
		if rect.size.y <= spikes.hit_height:
			low.append(str(rect))
	var from: float = brambles[0].rect.position.x if not brambles.is_empty() else INF
	var to: float = brambles[-1].rect.end.x if not brambles.is_empty() else -INF
	var hit_height: float = spikes.hit_height
	spikes.free()
	return report(from <= -kill_right and to >= kill_right and gaps.is_empty() and low.is_empty(),
			"Drawn from %.1f to %.1f over the part that kills, %.1f to %.1f; gaps %s; no taller than its %.0f px: %s"
			% [from, to, -kill_right, kill_right, gaps, hit_height, low])


func _a_strip_looks_the_same_each_time_and_two_strips_differ(art: Texture2D) -> bool:
	var first: String = _layout_at(art, SPOT)
	var again: String = _layout_at(art, SPOT)
	var other: String = _layout_at(art, OTHER_SPOT)
	return report(first == again and first != other,
			"Same spot: %s; other spot: %s" % [first == again, first != other])


func _on_a_long_strip_their_size_and_mirroring_vary(art: Texture2D) -> bool:
	var spikes: LethalSpikes = _strip(art, LONG_WIDTH_TILES, SPOT)
	var lowest: float = INF
	var highest: float = -INF
	var mirrored: int = 0
	for bramble: LethalSpikes.Bramble in spikes.get_brambles():
		lowest = minf(lowest, bramble.rect.size.y)
		highest = maxf(highest, bramble.rect.size.y)
		mirrored += 1 if bramble.mirrored else 0
	spikes.free()
	return report(highest - lowest > SAME and mirrored > 0 and mirrored < LONG_WIDTH_TILES,
			"Over %d tiles: %.1f to %.1f px tall, %d mirrored" % [LONG_WIDTH_TILES, lowest, highest, mirrored])


func _the_scene_s_spikes_carry_the_bramble() -> bool:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	var path: String = spikes.art.resource_path if spikes.art != null else "none"
	spikes.free()
	return report(path == BRAMBLE_PATH, "The scene's art: %s" % path)


## A strip of Width Tiles with Art at At, in the tree, as a level holds it.
func _strip(art: Texture2D, width_tiles: int, at: Vector2) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.width_tiles = width_tiles
	spikes.art = art
	spikes.position = at
	root.add_child(spikes)
	return spikes


## The brambles of a strip built at At, as text: each one's place, size and mirroring.
func _layout_at(art: Texture2D, at: Vector2) -> String:
	var spikes: LethalSpikes = _strip(art, WIDTH_TILES, at)
	var parts: PackedStringArray = []
	for bramble: LethalSpikes.Bramble in spikes.get_brambles():
		parts.append("%s %s" % [bramble.rect, bramble.mirrored])
	spikes.free()
	return "; ".join(parts)
