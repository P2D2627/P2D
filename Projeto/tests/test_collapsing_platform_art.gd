# Checks the collapsing platform's art. The crack cell follows the countdown, from the first cell at the
# landing to the last crack cell before it goes. The slabs span the platform end to end at one scale,
# with the stones' mean top on the tiles' top; a platform wider than Max Tiles takes one slab per Max
# Tiles, side by side, every other one mirrored. Landed on, the slab cracks in order while the platform
# holds; as it goes, the breaking cells play and the pieces fade out; when it comes back, the whole
# slab fades back in.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_collapsing_platform_art.gd
extends "res://tests/support/player_test.gd"

const PLATFORM_SCENE: PackedScene = preload("res://scenes/objects/platforms/collapsing_platform.tscn")
const TILE: float = 48.0
const FLOOR_HALF_WIDTH: float = 1000.0
const PLATFORM_TOP: float = -144.0
const PLATFORM_LEFT: float = -96.0
const OVER_IT: Vector2 = Vector2(0.0, -300.0)
## How far a drawn edge may sit from where it belongs, in px.
const EDGE_TOLERANCE: float = 0.5
const WATCH_FRAMES: int = 60
const COME_BACK_TIME: float = 0.5
## Frames of slack on the break and fade timings.
const TIMING_SLACK_FRAMES: int = 6


func _initialize() -> void:
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var results: Array[bool] = []
	results.append(_crack_cell_follows_the_countdown())
	results.append(await _slabs_span_the_platform(2, 1))
	results.append(await _slabs_span_the_platform(4, 1))
	results.append(await _slabs_span_the_platform(6, 2))
	results.append(await _it_cracks_breaks_and_comes_back())
	finish(results)


func _crack_cell_follows_the_countdown() -> bool:
	# Progress, then the cell expected out of 5 crack cells.
	var cases: Array[Vector2] = [Vector2(-0.5, 0), Vector2(0.0, 0), Vector2(0.19, 0), Vector2(0.2, 1),
			Vector2(0.59, 2), Vector2(0.99, 4), Vector2(1.0, 4), Vector2(1.5, 4)]
	var wrong: Array[String] = []
	for case: Vector2 in cases:
		var cell: int = CollapsingPlatformArt.crack_frame(case.x, 5)
		if cell != int(case.y):
			wrong.append("%.2f gave %d" % [case.x, cell])
	return report(wrong.is_empty(), "Crack cell over the countdown: %s"
			% ("as expected" if wrong.is_empty() else ", ".join(wrong)))


func _slabs_span_the_platform(width_tiles: int, expected_slabs: int) -> bool:
	var platform: CollapsingPlatform = _make_platform(width_tiles, 0.0)
	await physics_frame
	var art: CollapsingPlatformArt = platform.get_node(^"%Art") as CollapsingPlatformArt
	var slabs: Array[Sprite2D] = art.get_slabs()
	var cell := Vector2(art.sheet.get_width() / float(art.frames), art.sheet.get_height())
	var problems: Array[String] = []
	if slabs.size() != expected_slabs:
		problems.append("%d slabs" % slabs.size())
	var expected_right: float = 0.0
	for k: int in slabs.size():
		var slab: Sprite2D = slabs[k]
		if not is_equal_approx(slab.scale.x, slab.scale.y):
			problems.append("slab %d stretched %s" % [k, slab.scale])
		if slab.flip_h != (k % 2 == 1):
			problems.append("slab %d mirrored %s" % [k, slab.flip_h])
		var margin: float = art.right_margin if slab.flip_h else art.left_margin
		var left: float = slab.position.x + margin * cell.x * slab.scale.x
		var right: float = left + (1.0 - art.left_margin - art.right_margin) * cell.x * slab.scale.x
		var top: float = slab.position.y + art.top_in_cell * cell.y * slab.scale.y
		if absf(left - expected_right) > EDGE_TOLERANCE:
			problems.append("slab %d starts at %.1f, not %.1f" % [k, left, expected_right])
		if absf(top) > EDGE_TOLERANCE:
			problems.append("slab %d stones' top at %.1f" % [k, top])
		expected_right = right
	if absf(expected_right - width_tiles * TILE) > EDGE_TOLERANCE:
		problems.append("ends at %.1f, not %.1f" % [expected_right, width_tiles * TILE])
	platform.queue_free()
	await physics_frame
	return report(problems.is_empty(), "%d tiles wide: %s" % [width_tiles,
			"%d slabs end to end" % slabs.size() if problems.is_empty() else ", ".join(problems)])


func _it_cracks_breaks_and_comes_back() -> bool:
	var platform: CollapsingPlatform = _make_platform(4, COME_BACK_TIME)
	await physics_frame
	var art: CollapsingPlatformArt = platform.get_node(^"%Art") as CollapsingPlatformArt
	var state: Dictionary = {"collapsing": -1, "collapsed": -1, "back": -1}
	platform.collapsing.connect(func() -> void: state["collapsing"] = Engine.get_physics_frames())
	platform.collapsed.connect(func() -> void: state["collapsed"] = Engine.get_physics_frames())
	platform.came_back.connect(func() -> void: state["back"] = Engine.get_physics_frames())
	var player: Player = spawn_player(OVER_IT)
	await wait_until(func() -> bool: return state["collapsing"] >= 0, WATCH_FRAMES * 2)
	# While it counts down: crack cells only, never going back, up to the last one.
	var cracks: Array[int] = []
	while state["collapsed"] < 0 and Engine.get_physics_frames() - state["collapsing"] < WATCH_FRAMES * 2:
		cracks.append(art.get_frame())
		await physics_frame
	var in_order: bool = true
	for k: int in range(1, cracks.size()):
		in_order = in_order and cracks[k] >= cracks[k - 1]
	var cracked: bool = not cracks.is_empty() and cracks[0] == 0 and in_order \
			and cracks.max() == art.crack_frames - 1 and art.modulate.a > 0.99
	# As it goes, until it comes back: the breaking cells in turn, then the pieces fade out.
	var breaking: Array[int] = []
	var lowest_alpha: float = 1.0
	var break_frames: int = roundi(((art.frames - art.crack_frames) * art.break_frame_time
			+ art.fade_out_time) * Engine.physics_ticks_per_second) + TIMING_SLACK_FRAMES
	for _step: int in break_frames:
		if state["back"] >= 0:
			break
		if breaking.is_empty() or breaking.back() != art.get_frame():
			breaking.append(art.get_frame())
		lowest_alpha = minf(lowest_alpha, art.modulate.a)
		await physics_frame
	var expected_breaking: Array[int] = []
	for cell: int in range(art.crack_frames, art.frames):
		expected_breaking.append(cell)
	var broke: bool = breaking == expected_breaking and is_zero_approx(lowest_alpha)
	# Back: the whole slab, faded in.
	await wait_until(func() -> bool: return state["back"] >= 0, WATCH_FRAMES * 2)
	var fade_in_frames: int = roundi(art.fade_in_time * Engine.physics_ticks_per_second)
	await wait_frames(fade_in_frames + TIMING_SLACK_FRAMES)
	var last_cell: int = art.get_frame()
	var last_alpha: float = art.modulate.a
	var came_back: bool = last_cell == 0 and is_equal_approx(last_alpha, 1.0)
	await remove_player(player)
	platform.queue_free()
	await physics_frame
	return report(cracked and broke and came_back,
			"Cracked in order %s (%s), broke %s (%s), came back whole %s (cell %d, alpha %.2f)"
			% [cracked, cracks, broke, breaking, came_back, last_cell, last_alpha])


func _make_platform(width_tiles: int, come_back: float) -> CollapsingPlatform:
	var platform: CollapsingPlatform = PLATFORM_SCENE.instantiate() as CollapsingPlatform
	platform.position = Vector2(PLATFORM_LEFT, PLATFORM_TOP)
	platform.width_tiles = width_tiles
	platform.come_back_time = come_back
	root.add_child(platform)
	return platform
