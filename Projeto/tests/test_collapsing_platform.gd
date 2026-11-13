# Checks the collapsing platform. It is the levels' one-way tile, so a jump from under it goes through it
# and lands on top, and that jump through it does not set it off. Landing on it sets it off: it blinks for
# Collapse Time, 0.6 s, holds him meanwhile, then he falls through. It comes back after Come Back Time and
# holds him again; at 0 it stays gone.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_collapsing_platform.gd
extends "res://tests/support/player_test.gd"

const PLATFORM_SCENE: PackedScene = preload("res://scenes/objects/platforms/collapsing_platform.tscn")
const TILE: float = 48.0
const FLOOR_HALF_WIDTH: float = 1000.0
## The platform's top edge above the floor (y = 0): under a full jump, over the man's head.
const PLATFORM_TOP: float = -144.0
const PLATFORM_LEFT: float = -96.0
const WIDTH_TILES: int = 4
## Where he starts, on the floor under it.
const UNDER_IT: Vector2 = Vector2(0.0, -2.0)
## Where he is dropped from to land on it.
const OVER_IT: Vector2 = Vector2(0.0, -300.0)
## How far from a top edge the feet may be and still stand on it, in px.
const ON_TOP: float = 1.0
## A second of frames, to wait for what should have happened by then.
const WATCH_FRAMES: int = 60
## How much the collapse may differ from Collapse Time, in frames.
const TIMING_TOLERANCE_FRAMES: int = 2
const COME_BACK_TIME: float = 0.5


func _initialize() -> void:
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var results: Array[bool] = []
	results.append(await _a_jump_up_through_it_lands_on_top_and_sets_it_off_only_then())
	results.append(await _landed_on_it_blinks_for_collapse_time_then_he_falls_through())
	results.append(await _it_comes_back_and_holds_him_again())
	results.append(await _at_zero_it_stays_gone())
	finish(results)


func _make_platform(come_back: float) -> CollapsingPlatform:
	var platform: CollapsingPlatform = PLATFORM_SCENE.instantiate() as CollapsingPlatform
	platform.position = Vector2(PLATFORM_LEFT, PLATFORM_TOP)
	platform.width_tiles = WIDTH_TILES
	platform.come_back_time = come_back
	root.add_child(platform)
	return platform


func _a_jump_up_through_it_lands_on_top_and_sets_it_off_only_then() -> bool:
	var platform: CollapsingPlatform = _make_platform(0.0)
	var player: Player = await spawn_on_floor(UNDER_IT)
	if player == null:
		return report(false, "Through: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var still_while_rising: bool = true
	var landed_on_top: bool = false
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		if player.velocity.y < 0.0 and platform.get_phase() != CollapsingPlatform.Phase.STILL:
			still_while_rising = false
		if player.is_on_floor() and absf(player.position.y - PLATFORM_TOP) <= ON_TOP:
			landed_on_top = true
			break
	await physics_frame
	await physics_frame
	var blinking: bool = platform.get_phase() == CollapsingPlatform.Phase.BLINKING
	await remove_player(player)
	platform.queue_free()
	await physics_frame
	return report(still_while_rising and landed_on_top and blinking,
			"Through: still while rising %s, landed on top %s, then blinking %s" % [still_while_rising, landed_on_top, blinking])


func _landed_on_it_blinks_for_collapse_time_then_he_falls_through() -> bool:
	var platform: CollapsingPlatform = _make_platform(0.0)
	var frames: Array[int] = [-1, -1]
	platform.collapsing.connect(func() -> void: frames[0] = Engine.get_physics_frames())
	platform.collapsed.connect(func() -> void: frames[1] = Engine.get_physics_frames())
	var player: Player = spawn_player(OVER_IT)
	await wait_until(func() -> bool: return frames[0] >= 0, WATCH_FRAMES * 2)
	var blinks: int = 0
	var was_visible: bool = true
	var held: bool = true
	var tiles: TileMapLayer = platform.get_node(^"%Tiles") as TileMapLayer
	while frames[1] < 0 and Engine.get_physics_frames() - frames[0] < WATCH_FRAMES * 2:
		await physics_frame
		if tiles.visible != was_visible:
			blinks += 1
			was_visible = tiles.visible
		if frames[1] < 0 and absf(player.position.y - PLATFORM_TOP) > ON_TOP:
			held = false
	var took: int = frames[1] - frames[0]
	var expected: int = roundi(platform.collapse_time * Engine.physics_ticks_per_second)
	await wait_until(player.is_on_floor, WATCH_FRAMES)
	await wait_frames(2)
	var fell_to_the_floor: bool = absf(player.position.y) <= ON_TOP
	await remove_player(player)
	platform.queue_free()
	await physics_frame
	return report(absi(took - expected) <= TIMING_TOLERANCE_FRAMES and blinks >= 2 and held and fell_to_the_floor,
			"Collapse: took %d frames (%d expected), %d blink changes, held meanwhile %s, then fell to the floor %s"
			% [took, expected, blinks, held, fell_to_the_floor])


func _it_comes_back_and_holds_him_again() -> bool:
	var platform: CollapsingPlatform = _make_platform(COME_BACK_TIME)
	var player: Player = spawn_player(OVER_IT)
	var gone: bool = await wait_until(func() -> bool: return platform.get_phase() == CollapsingPlatform.Phase.GONE, WATCH_FRAMES * 3)
	var back: bool = await wait_until(func() -> bool: return platform.get_phase() == CollapsingPlatform.Phase.STILL, WATCH_FRAMES * 2)
	# Dropped again from above, it holds him once more.
	player.position = OVER_IT
	player.velocity = Vector2.ZERO
	var held: bool = await wait_until(
			func() -> bool: return player.is_on_floor() and absf(player.position.y - PLATFORM_TOP) <= ON_TOP, WATCH_FRAMES * 2)
	await remove_player(player)
	platform.queue_free()
	await physics_frame
	return report(gone and back and held, "Back: gone %s, back %s, held him again %s" % [gone, back, held])


func _at_zero_it_stays_gone() -> bool:
	var platform: CollapsingPlatform = _make_platform(0.0)
	var player: Player = spawn_player(OVER_IT)
	await wait_until(func() -> bool: return platform.get_phase() == CollapsingPlatform.Phase.GONE, WATCH_FRAMES * 3)
	await wait_frames(WATCH_FRAMES)
	var phase: CollapsingPlatform.Phase = platform.get_phase()
	await remove_player(player)
	platform.queue_free()
	await physics_frame
	return report(phase == CollapsingPlatform.Phase.GONE, "Stays: phase %d after a second gone" % phase)
