# Checks the shelter field, how enclosed each spot of a level is. On a small map made here
# (tests/support/small_shelter_map.gd), the bake gives the values of the measure that drew the
# approved map of level 1 (the reference values below, from it): the cavern is open, the corridor
# fully closed and no chimney, the chimney whole in its middle and closing in from its mouth, and
# the 5-wide shaft half a chimney. Into the tunnel from the cavern, the closing grows bit by bit as
# the reference says, none for the first tiles, half about 6 tiles in and whole about 10 in; in the
# shaft, closed above, the top is as deep a chimney as the middle. Neither the floor nor a single
# wall shelters: the cavern's floor in its corner and the air beside its wall are open. A row of
# one-way platforms across the cavern changes no openness; read on a wall, openness is the air
# tile's beside it, not lowered by the rock; two bakes are the same. Level 1's saved field is a bake
# of its current tiles with its own settings (if not, the failure gives the command that bakes it
# again), and the man starts in the open.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_shelter_field.gd
extends "res://tests/support/base_test.gd"

const LEVEL1_PATH: String = "res://scenes/levels/lust/level1.tscn"
const LEVEL1_FIELD_PATH: String = "res://scenes/levels/lust/level1_shelter.res"
const SmallMap = preload("res://tests/support/small_shelter_map.gd")
## Reference openness from the approved measure, at tiles of the small map, and how far the bake may
## be from it: a byte holds openness to 1/255.
const REFERENCE_OPENNESS: Dictionary[Vector2i, float] = {Vector2i(16, 11): 0.6724,
		Vector2i(38, 43): 0.2871, Vector2i(21, 31): 0.2010, Vector2i(53, 31): 0.2303,
		Vector2i(2, 11): 0.7583, Vector2i(2, 21): 0.9972}
## The cavern's floor in its corner, and the air beside its left wall halfway up.
const FLOOR_CORNER: Vector2i = Vector2i(2, 21)
const BESIDE_THE_WALL: Vector2i = Vector2i(2, 11)
const OPENNESS_TOLERANCE: float = 0.006
## The chimney's amount from its mouth down, rows 22 to 29 of column 21, from the approved measure.
const CHIMNEY_COLUMN: int = 21
const REFERENCE_RAMP: Array[float] = [0.020, 0.156, 0.376, 0.624, 0.844, 0.980, 1.0, 1.0]
const AMOUNT_TOLERANCE: float = 0.002
## The 5-wide shaft is half a chimney in its middle: smoothstep of (7 - 5) / (7 - 3).
const SHAFT_MIDDLE: Vector2i = Vector2i(53, 31)
const SHAFT_AMOUNT: float = 0.5
## The top tile of the shaft, which is closed above.
const SHAFT_TOP: Vector2i = Vector2i(53, 20)
## The closing along the tunnel's floor, row 17, from column 30 in the cavern to 45 at its far end,
## from the approved measure; the tunnel starts at column 32.
const TUNNEL_FLOOR_ROW: int = 17
const TUNNEL_FROM_COLUMN: int = 30
const REFERENCE_TUNNEL: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.019, 0.069, 0.316, 0.5, 0.684,
		0.844, 0.957, 1.0, 1.0, 1.0, 1.0]
## A whole closing, and none, read from openness through the smooth ramp, which turns a byte's
## rounding into up to about 0.02 of amount.
const CLOSED_TOLERANCE: float = 0.03
## The command that bakes level 1's field again.
const LEVEL1_BAKE: String = ("godot --headless --path Projeto --script "
		+ "res://scenes/others/ambience/bake_shelter.gd -- " + LEVEL1_PATH + " " + LEVEL1_FIELD_PATH)


func _initialize() -> void:
	var results: Array[bool] = []
	var field: ShelterField = SmallMap.bake()
	results.append(_the_bake_matches_the_approved_measure(field))
	results.append(_open_closed_and_chimney_are_told_apart(field))
	results.append(_a_chimney_closes_in_from_its_mouth(field))
	results.append(_a_tunnel_closes_in_bit_by_bit(field))
	results.append(_a_chimney_closed_above_is_deep_at_its_top(field))
	results.append(_neither_the_floor_nor_one_wall_shelters(field))
	results.append(_one_way_platforms_let_the_rays_through(field))
	results.append(_read_on_a_wall_openness_is_the_air_tiles(field))
	results.append(_two_bakes_are_the_same(field))
	results.append(_level1s_field_is_a_bake_of_its_current_tiles())
	quit(1 if results.has(false) else 0)


func _the_bake_matches_the_approved_measure(field: ShelterField) -> bool:
	var off: Array[String] = []
	for tile: Vector2i in REFERENCE_OPENNESS:
		var open: float = field.openness_at(SmallMap.centre(tile))
		if absf(open - REFERENCE_OPENNESS[tile]) > OPENNESS_TOLERANCE:
			off.append("%s: %.3f for %.3f" % [tile, open, REFERENCE_OPENNESS[tile]])
	return _report(off.is_empty(), "The bake's openness is the approved measure's, within %.3f, "
			% OPENNESS_TOLERANCE + "at %d tiles of the small map (off: %s)"
			% [REFERENCE_OPENNESS.size(), "; ".join(off)])


func _open_closed_and_chimney_are_told_apart(field: ShelterField) -> bool:
	var cavern: Vector2 = field.default_amounts_at(SmallMap.centre(SmallMap.CAVERN.get_center()))
	var corridor: Vector2 = field.default_amounts_at(SmallMap.centre(SmallMap.CORRIDOR.get_center()))
	var chimney: Vector2 = field.default_amounts_at(SmallMap.centre(SmallMap.CHIMNEY.get_center()))
	var shaft: Vector2 = field.default_amounts_at(SmallMap.centre(SHAFT_MIDDLE))
	var passed: bool = (cavern.x < CLOSED_TOLERANCE and is_zero_approx(cavern.y)
			and corridor.x > 1.0 - CLOSED_TOLERANCE and is_zero_approx(corridor.y)
			and chimney.x > 1.0 - CLOSED_TOLERANCE and absf(chimney.y - 1.0) < AMOUNT_TOLERANCE
			and absf(shaft.y - SHAFT_AMOUNT) < AMOUNT_TOLERANCE)
	return _report(passed, "Closed and chimney amounts: cavern %s (open, no chimney), corridor %s "
			% [cavern, corridor] + "(closed, no chimney), 3-wide chimney %s (closed, whole), " % chimney
			+ "5-wide shaft %s (half a chimney)" % shaft)


func _a_chimney_closes_in_from_its_mouth(field: ShelterField) -> bool:
	var amounts: Array[float] = []
	var matches: bool = true
	for row: int in REFERENCE_RAMP.size():
		var tile := Vector2i(CHIMNEY_COLUMN, SmallMap.CHIMNEY.position.y + row)
		var amount: float = field.default_amounts_at(SmallMap.centre(tile)).y
		amounts.append(snappedf(amount, 0.001))
		matches = matches and absf(amount - REFERENCE_RAMP[row]) < AMOUNT_TOLERANCE
	return _report(matches, "From the chimney's mouth down, its amount rises bit by bit: %s for %s"
			% [amounts, REFERENCE_RAMP])


func _a_tunnel_closes_in_bit_by_bit(field: ShelterField) -> bool:
	var closing: Array[float] = []
	var matches: bool = true
	var rising: bool = true
	for step: int in REFERENCE_TUNNEL.size():
		var tile := Vector2i(TUNNEL_FROM_COLUMN + step, TUNNEL_FLOOR_ROW)
		var amount: float = field.default_amounts_at(SmallMap.centre(tile)).x
		rising = rising and (closing.is_empty() or amount >= closing[-1] - 0.0005)
		closing.append(snappedf(amount, 0.001))
		matches = matches and absf(amount - REFERENCE_TUNNEL[step]) < CLOSED_TOLERANCE
	return _report(matches and rising, "Along the tunnel's floor from the cavern, the closing grows "
			+ "bit by bit (%s), as the approved measure: %s for %s" % [rising, closing,
			REFERENCE_TUNNEL])


func _a_chimney_closed_above_is_deep_at_its_top(field: ShelterField) -> bool:
	var top: float = field.default_amounts_at(SmallMap.centre(SHAFT_TOP)).y
	var middle: float = field.default_amounts_at(SmallMap.centre(SHAFT_MIDDLE)).y
	return _report(absf(top - middle) < AMOUNT_TOLERANCE and absf(top - SHAFT_AMOUNT)
			< AMOUNT_TOLERANCE, "In the shaft, closed above, the top tile is as much a chimney as the "
			+ "middle, its rock end no mouth: %.3f and %.3f" % [top, middle])


func _neither_the_floor_nor_one_wall_shelters(field: ShelterField) -> bool:
	var corner: Vector2 = field.default_amounts_at(SmallMap.centre(FLOOR_CORNER))
	var beside: Vector2 = field.default_amounts_at(SmallMap.centre(BESIDE_THE_WALL))
	return _report(corner.x < CLOSED_TOLERANCE and beside.x < CLOSED_TOLERANCE, "Neither the floor "
			+ "nor a single wall shelters: the cavern's floor in its corner %s and the air beside its "
			% corner + "wall %s are open" % beside)


func _one_way_platforms_let_the_rays_through(field: ShelterField) -> bool:
	var with_platforms: ShelterField = SmallMap.bake(true)
	var same: bool = with_platforms.openness == field.openness
	return _report(same, "A row of one-way platforms across the cavern leaves every openness as it "
			+ "was: %s" % same)


func _read_on_a_wall_openness_is_the_air_tiles(field: ShelterField) -> bool:
	# On the line between the cavern's first column of air and the rock to its left.
	var tile: Vector2i = BESIDE_THE_WALL
	var on_the_wall := Vector2(tile.x * field.tile_size.x, SmallMap.centre(tile).y)
	var own: float = field.openness[tile.y * field.size.x + tile.x] / float(ShelterField.BYTE_MAX)
	var read: float = field.openness_at(on_the_wall)
	return _report(is_equal_approx(read, own), "Read on the wall, beside its tile, openness is the "
			+ "tile's own, %.3f, not lowered by the rock: %.3f" % [own, read])


func _two_bakes_are_the_same(field: ShelterField) -> bool:
	var again: ShelterField = SmallMap.bake()
	var same: bool = (again.openness == field.openness and again.widths == field.widths
			and again.chimney_depths == field.chimney_depths and again.origin == field.origin
			and again.source_sha256 == field.source_sha256)
	return _report(same, "Two bakes of the same tiles are the same: %s" % same)


func _level1s_field_is_a_bake_of_its_current_tiles() -> bool:
	var saved := load(LEVEL1_FIELD_PATH) as ShelterField
	if saved == null or not saved.is_baked():
		return _report(false, "Level 1 has a baked shelter field at %s" % LEVEL1_FIELD_PATH)
	var level: Node = (load(LEVEL1_PATH) as PackedScene).instantiate()
	var tiles := level.get_node_or_null(saved.tiles_path) as TileMapLayer
	var player := level.get_node_or_null(^"Player") as Node2D
	if tiles == null or player == null:
		level.free()
		return _report(false, "Level 1 has its Tiles at %s and its Player" % saved.tiles_path)
	var current: bool = saved.source_sha256 == ShelterField.fingerprint(tiles)
	var fresh := ShelterField.new()
	fresh.tiles_path = saved.tiles_path
	fresh.reach = saved.reach
	fresh.chimney_max_width = saved.chimney_max_width
	fresh.chimney_min_length = saved.chimney_min_length
	fresh.depth_open_at = saved.depth_open_at
	fresh.bake(tiles)
	var same: bool = (fresh.openness == saved.openness and fresh.widths == saved.widths
			and fresh.chimney_depths == saved.chimney_depths and fresh.origin == saved.origin
			and fresh.closed_depths == saved.closed_depths
			and fresh.size == saved.size and fresh.tile_size == saved.tile_size)
	var start: Vector2 = saved.default_amounts_at(ShelterField.world_transform(player).origin)
	level.free()
	return _report(current and same and start == Vector2.ZERO, "Level 1's saved field is a bake "
			+ "of its current tiles (fingerprint %s) with its own settings (same values %s); " % [
			current, same] + "if not, bake it again: %s. The man starts in the " % LEVEL1_BAKE
			+ "open, with no closing and no chimney: %s" % start)


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
