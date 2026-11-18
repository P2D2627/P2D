# Checks what lethal spikes with Catches on (off in the game) do to the man through his Snag
# (ADR 0067). Caught, he keeps Speed
# Multiplier of his run, cannot jump and loses SP Per Second, and sinks as it goes, which his drawing
# hears. In the middle of a wide strip he dies, once, when his SP runs out, put down to the spikes and
# to that strip, stopped where he is and with no more hits landing. Caught at an edge and walking out,
# he lives with what is left, runs and jumps in full again and stands up. Two strips over each other
# catch him once and take his SP once, and out of one of them he is still caught.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_snag.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
## The strip's name, which a death in it is put down to.
const SPIKES_NAME: StringName = &"Spikes2"
const SECOND_NAME: StringName = &"Spikes3"
const TILE: float = 48.0
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## The strip, from its middle at x = 0: wide enough that nobody walks out of its middle in time.
const WIDTH_TILES: int = 8
## Where the man starts his run in, to the left of the strip, with the floor's top at y = 0.
const RUN_START: Vector2 = Vector2(-500.0, -2.0)
## The middle of the strip, where he is put down.
const MIDDLE: Vector2 = Vector2(0.0, -2.0)
## How far into the part that kills his body is put down at its left end, in px.
const EDGE_DEPTH: float = 8.0
## Frames for him to reach the strip at a run, and more.
const RUN_FRAMES: int = 90
## Frames for a body put down on the strip to be caught.
const SETTLE_FRAMES: int = 3
## Frames he is watched while caught.
const CAUGHT_FRAMES: int = 10
## Frames to watch him after he dies.
const AFTER_DEATH_FRAMES: int = 30
## How far he may slide after dying, in px.
const STOPPED_TOLERANCE: float = 1.0
## How many frames off the time to die may be: the SP lost each frame is a float, so the last bit of
## it can need one frame more.
const DEATH_FRAME_TOLERANCE: int = 1


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var spikes: LethalSpikes = _make_spikes(SPIKES_NAME)
	await physics_frame
	var results: Array[bool] = []
	results.append(await _caught_he_is_slow_cannot_jump_and_sinks_as_his_sp_goes())
	results.append(await _in_the_middle_he_dies_once_when_his_sp_runs_out())
	results.append(await _out_of_them_in_time_he_lives_with_what_is_left(spikes))
	results.append(await _out_of_one_of_two_strips_he_is_still_caught(spikes))
	finish(results)


func _caught_he_is_slow_cannot_jump_and_sinks_as_his_sp_goes() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Caught: the player never landed")
	var snag: Player.Snag = player.snag
	var to_drawing: bool = snag.sink_changed.get_connections().any(func(connection: Dictionary) -> bool:
		return (connection["callable"] as Callable).get_object() is SinkingDrawing)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var caught: bool = await wait_until(snag.is_caught, RUN_FRAMES)
	await wait_frames(CAUGHT_FRAMES)
	var speed_share: float = player.get_speed_multiplier()
	var no_jump: bool = player.is_jump_blocked()
	var sp: float = player.soul_points.get_sp()
	var full: float = player.soul_points.get_max_sp()
	var lost: float = full - sp
	var expected_lost: float = snag.sp_per_second / Engine.physics_ticks_per_second * CAUGHT_FRAMES
	var sink: float = snag.get_sink()
	var alive: bool = not player.is_dead()
	var expected_share: float = snag.speed_multiplier
	await remove_player(player)
	return report(caught and alive and is_equal_approx(speed_share, expected_share) and no_jump
			and is_equal_approx(lost, expected_lost) and is_equal_approx(sink, lost / full) and to_drawing,
			"Caught %s, alive %s: speed share %.2f (expected %.2f), jump blocked %s, lost %.2f SP in %d frames (expected %.2f), sunk %.3f, the drawing hears it %s"
			% [caught, alive, speed_share, expected_share, no_jump, lost, CAUGHT_FRAMES, expected_lost, sink,
			to_drawing])


func _in_the_middle_he_dies_once_when_his_sp_runs_out() -> bool:
	var player: Player = spawn_player(MIDDLE)
	var caught_frame: Array[int] = [NEVER_REACHED]
	var death_frames: Array[int] = []
	player.snag.caught.connect(func() -> void: caught_frame[0] = Engine.get_physics_frames())
	player.died.connect(func() -> void: death_frames.append(Engine.get_physics_frames()))
	var sp_at_start: float = player.soul_points.get_sp()
	var per_frame: float = player.snag.sp_per_second / Engine.physics_ticks_per_second
	var died: bool = await wait_until(player.is_dead)
	var stopped_at: float = player.position.x
	var sink: float = player.snag.get_sink()
	await wait_frames(AFTER_DEATH_FRAMES)
	var moved: float = absf(player.position.x - stopped_at)
	var closed: bool = not (player.get_node(^"Hurtbox") as Hurtbox).takes_hits()
	var cause: StringName = player.get_death_cause()
	var source: StringName = player.get_death_source()
	await remove_player(player)
	# Caught on a frame, he loses SP on it and on each one after, up to the one he dies on.
	var frames_in: int = death_frames[0] - caught_frame[0] + 1 if death_frames.size() == 1 else NEVER_REACHED
	var expected_frames: int = ceili(sp_at_start / per_frame)
	return report(died and death_frames.size() == 1 and absi(frames_in - expected_frames) <= DEATH_FRAME_TOLERANCE
			and is_equal_approx(sink, 1.0) and moved <= STOPPED_TOLERANCE and closed
			and cause == LethalSpikes.CAUSE and source == SPIKES_NAME,
			"In the middle: died %s, %d death(s), after %d frames caught (expected %d with %.0f SP), sunk %.2f, moved %.1f px after, hits closed %s, died of %s on %s"
			% [died, death_frames.size(), frames_in, expected_frames, sp_at_start, sink, moved, closed, cause,
			source])


func _out_of_them_in_time_he_lives_with_what_is_left(spikes: LethalSpikes) -> bool:
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	var half_width: float = body_size(probe).x / 2.0
	probe.queue_free()
	var left_end: float = -(WIDTH_TILES * TILE / 2.0 - spikes.side_inset)
	var player: Player = spawn_player(Vector2(left_end - half_width + EDGE_DEPTH, MIDDLE.y))
	var freed: Array[int] = [0]
	var last_sink: Array[float] = [-1.0]
	player.snag.freed.connect(func() -> void: freed[0] += 1)
	player.snag.sink_changed.connect(func(sink: float) -> void: last_sink[0] = sink)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = -1.0
	var caught: bool = await wait_until(player.snag.is_caught, SETTLE_FRAMES)
	var out: bool = await wait_until(func() -> bool: return not player.snag.is_caught())
	await physics_frame
	var sp: float = player.soul_points.get_sp()
	var full: float = player.soul_points.get_max_sp()
	var alive: bool = not player.is_dead()
	var speed_share: float = player.get_speed_multiplier()
	var no_jump: bool = player.is_jump_blocked()
	await remove_player(player)
	return report(caught and out and alive and freed[0] == 1 and sp > 0.0 and sp < full
			and is_equal_approx(speed_share, 1.0) and not no_jump and last_sink[0] == 0.0,
			"At the edge: caught %s, out %s, alive %s with %.1f of %.0f SP, freed said %d time(s), speed share %.2f, jump blocked %s, the drawing last told to sink %.2f"
			% [caught, out, alive, sp, full, freed[0], speed_share, no_jump, last_sink[0]])


## Two strips over each other catch him once and take his SP once; let go by the first, the second
## still holds him, slow; let go by both, he is free.
func _out_of_one_of_two_strips_he_is_still_caught(first: LethalSpikes) -> bool:
	var second: LethalSpikes = _make_spikes(SECOND_NAME)
	var player: Player = spawn_player(MIDDLE)
	var catches_said: Array[int] = [0]
	var freed: Array[int] = [0]
	player.snag.caught.connect(func() -> void: catches_said[0] += 1)
	player.snag.freed.connect(func() -> void: freed[0] += 1)
	var caught: bool = await wait_until(player.snag.is_caught, SETTLE_FRAMES)
	var sp_before: float = player.soul_points.get_sp()
	await wait_frames(CAUGHT_FRAMES)
	var lost: float = sp_before - player.soul_points.get_sp()
	var expected_lost: float = player.snag.sp_per_second / Engine.physics_ticks_per_second * CAUGHT_FRAMES
	player.snag.release(first)
	var held_by_the_second: bool = player.snag.is_caught()
	var speed_share: float = player.get_speed_multiplier()
	var expected_share: float = player.snag.speed_multiplier
	var freed_by_one: int = freed[0]
	player.snag.release(second)
	var free_of_both: bool = not player.snag.is_caught() and freed[0] == 1
	await remove_player(player)
	second.queue_free()
	await physics_frame
	return report(caught and catches_said[0] == 1 and is_equal_approx(lost, expected_lost)
			and held_by_the_second and freed_by_one == 0 and is_equal_approx(speed_share, expected_share)
			and free_of_both,
			"Two strips: caught said %d time(s), lost %.2f SP in %d frames (one strip's %.2f); out of the first, still held %s, freed said %d, speed share %.2f (expected %.2f); out of both, free %s"
			% [catches_said[0], lost, CAUGHT_FRAMES, expected_lost, held_by_the_second, freed_by_one,
			speed_share, expected_share, free_of_both])


## A strip WIDTH_TILES wide with its middle at x = 0, on the floor, with Catches on, already in the
## scene.
func _make_spikes(strip_name: StringName) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.catches = true
	spikes.width_tiles = WIDTH_TILES
	spikes.name = strip_name
	root.add_child(spikes)
	return spikes
