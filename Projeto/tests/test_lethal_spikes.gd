# Checks the spikes that kill: a touch kills the man at once with his SP full, and says so once; he stops
# where he is and no more hits land on him; a jump over them does nothing; the width sets the part that
# kills, each instance on its own; and only the man is on their mask, so demons walk over them.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lethal_spikes.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const TILE: float = 48.0
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## Where the man starts, to the left of the spikes, with the floor's top at y = 0.
const START: Vector2 = Vector2(-300.0, -2.0)
## The spikes' strip: from its middle at x = 0, in tiles.
const WIDTH_TILES: int = 3
## Frames to reach the spikes at a run, and more.
const RUN_FRAMES: int = 60
## Frames to watch him after he dies.
const AFTER_DEATH_FRAMES: int = 30
## How far he may slide after dying, in px.
const STOPPED_TOLERANCE: float = 1.0
## Physics layer of the player, on the spikes' mask.
const PLAYER_LAYER: int = 2


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.width_tiles = WIDTH_TILES
	root.add_child(spikes)
	await physics_frame
	var results: Array[bool] = []
	results.append(await _a_touch_kills_at_once_with_full_sp())
	results.append(await _a_jump_over_them_does_nothing())
	results.append(_the_width_sets_the_part_that_kills_on_each_instance_alone(spikes))
	results.append(_only_the_man_is_on_their_mask(spikes))
	finish(results)


func _a_touch_kills_at_once_with_full_sp() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Touch: the player never landed")
	var deaths: Array[int] = [0]
	player.died.connect(func() -> void: deaths[0] += 1)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var sp_before: float = player.soul_points.get_sp()
	var died: bool = await wait_until(player.is_dead, RUN_FRAMES)
	var stopped_at: float = player.position.x
	await wait_frames(AFTER_DEATH_FRAMES)
	var moved: float = absf(player.position.x - stopped_at)
	var closed: bool = not (player.get_node(^"Hurtbox") as Hurtbox).takes_hits()
	var inside_strip: bool = stopped_at < WIDTH_TILES * TILE / 2.0
	await remove_player(player)
	return report(died and deaths[0] == 1 and is_equal_approx(sp_before, player_full_sp()) and moved <= STOPPED_TOLERANCE
			and closed and inside_strip,
			"Touch: died %s, %d death(s), SP was %.0f, moved %.1f px after, hits closed %s, stopped at x %.1f"
			% [died, deaths[0], sp_before, moved, closed, stopped_at])


func _a_jump_over_them_does_nothing() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Jump: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	stand_in.hold_jump = true
	# Take off about two tiles before the strip, so the jump's middle passes over it.
	await wait_until(func() -> bool: return player.position.x > -WIDTH_TILES * TILE / 2.0 - 2.0 * TILE, RUN_FRAMES)
	stand_in.press_jump()
	await wait_until(func() -> bool: return player.position.x > WIDTH_TILES * TILE, RUN_FRAMES)
	var died: bool = player.is_dead()
	var passed_at: float = player.position.x
	await remove_player(player)
	return report(not died, "Jump: passed to x %.1f, dead %s" % [passed_at, died])


func _the_width_sets_the_part_that_kills_on_each_instance_alone(spikes: LethalSpikes) -> bool:
	var other: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	other.width_tiles = 1
	root.add_child(other)
	var wide: float = (spikes.get_node(^"%Shape").shape as RectangleShape2D).size.x
	var narrow: float = (other.get_node(^"%Shape").shape as RectangleShape2D).size.x
	var expected_wide: float = WIDTH_TILES * TILE - 2.0 * spikes.side_inset
	var expected_narrow: float = TILE - 2.0 * other.side_inset
	other.queue_free()
	return report(is_equal_approx(wide, expected_wide) and is_equal_approx(narrow, expected_narrow),
			"Width: %.0f px at %d tiles (%.0f expected), %.0f px at 1 tile (%.0f expected)"
			% [wide, WIDTH_TILES, expected_wide, narrow, expected_narrow])


func _only_the_man_is_on_their_mask(spikes: LethalSpikes) -> bool:
	return report(spikes.collision_mask == PLAYER_LAYER and spikes.collision_layer == 0,
			"Mask: %d, layer %d" % [spikes.collision_mask, spikes.collision_layer])


func player_full_sp() -> float:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var full: float = player.soul_points.stats.max_sp
	player.free()
	return full
