# Checks the traps of the levels. Spikes hit the player who walks onto them with their share of
# health, and again every Rehit Interval while the player stays; the half-life trap takes half. A
# falling rock hangs while the player is away, shakes for Warn Time once the player is below it,
# then falls, breaks on the floor and hangs again after Respawn Time; falling on a player who stands
# below, it hits once and breaks.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_traps.gd
extends "res://tests/support/player_test.gd"

const SPIKES_SCENE: PackedScene = preload("res://traps/spikes.tscn")
const HALF_LIFE_SCENE: PackedScene = preload("res://traps/half_life_trap.tscn")
const ROCK_SCENE: PackedScene = preload("res://traps/falling_rock.tscn")

## The floor runs along y = 0; the ceiling's underside is CEILING_Y.
const FLOOR_LEFT: float = -3000.0
const FLOOR_RIGHT: float = 3000.0
const CEILING_Y: float = -600.0
## Where a case starts the player: standing on the floor.
const START: Vector2 = Vector2(-600.0, -2.0)
## Where a hazard sits on the floor, and where a rock hangs from the ceiling.
const HAZARD_X: float = 0.0
## Frames for the player to walk onto something and for a check to settle.
const WALK_FRAMES: int = 90
const SETTLE_FRAMES: int = 5
## Room for frame rounding when timing a warn or a respawn.
const TIME_TOLERANCE: float = 2.0 / 60.0
## Room for the fall: the rock's tip ends on the floor.
const FLOOR_TOLERANCE: float = 1.0


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	make_platform(FLOOR_LEFT, FLOOR_RIGHT, CEILING_Y - PLATFORM_THICKNESS)
	var results: Array[bool] = []
	results.append(await _spikes_hit_on_touch_and_again_while_standing_on_them())
	results.append(await _half_life_trap_takes_half())
	results.append(await _rock_hangs_while_the_player_is_away())
	results.append(await _rock_warns_falls_breaks_and_grows_back())
	results.append(await _rock_hits_a_player_below_once_and_breaks())
	finish(results)


func _spikes_hit_on_touch_and_again_while_standing_on_them() -> bool:
	var spikes: Hazard = _add(SPIKES_SCENE, Vector2(HAZARD_X, 0.0)) as Hazard
	var hits: Array[float] = []
	spikes.player_hit.connect(func(_player: Node2D, fraction: float) -> void: hits.append(fraction))
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the player never landed for the spikes")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var reached: bool = await wait_until(func() -> bool: return not hits.is_empty(), WALK_FRAMES)
	stand_in.run_direction = 0.0
	player.position.x = HAZARD_X
	var first_hit_frames: int = Engine.get_physics_frames()
	var again: bool = await wait_until(func() -> bool: return hits.size() >= 2)
	var waited: float = float(Engine.get_physics_frames() - first_hit_frames) / 60.0
	await remove_player(player)
	spikes.queue_free()
	var on_time: bool = absf(waited - spikes.rehit_interval) <= spikes.rehit_interval
	return report(reached and again and hits[0] == spikes.health_fraction and on_time,
			"Spikes: hit on touch %s with %.2f of health, hit again while standing %s after %.2f s"
			% [reached, hits[0] if reached else 0.0, again, waited])


func _half_life_trap_takes_half() -> bool:
	var trap: Hazard = _add(HALF_LIFE_SCENE, Vector2(HAZARD_X, 0.0)) as Hazard
	var hits: Array[float] = []
	trap.player_hit.connect(func(_player: Node2D, fraction: float) -> void: hits.append(fraction))
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the player never landed for the trap")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var reached: bool = await wait_until(func() -> bool: return not hits.is_empty(), WALK_FRAMES)
	await remove_player(player)
	trap.queue_free()
	return report(reached and hits[0] == 0.5,
			"Half-life trap: hit %s with %.2f of health, expected 0.50"
			% [reached, hits[0] if reached else 0.0])


func _rock_hangs_while_the_player_is_away() -> bool:
	var rock: FallingRock = _add(ROCK_SCENE, Vector2(HAZARD_X, CEILING_Y)) as FallingRock
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the player never landed by the rock")
	await wait_frames(WALK_FRAMES)
	var state: FallingRock.State = rock.get_state()
	await remove_player(player)
	rock.queue_free()
	return report(state == FallingRock.State.HANGING,
			"Rock with the player %.0f px away: state %s, expected HANGING"
			% [absf(START.x - HAZARD_X), FallingRock.State.keys()[state]])


## The player runs under the rock and on; the rock shakes for Warn Time before falling, its tip
## stops on the floor, and it hangs again Respawn Time after breaking.
func _rock_warns_falls_breaks_and_grows_back() -> bool:
	var rock: FallingRock = _add(ROCK_SCENE, Vector2(HAZARD_X, CEILING_Y)) as FallingRock
	var shake_frame: Array[int] = [-1]
	var fall_frame: Array[int] = [-1]
	var break_frame: Array[int] = [-1]
	rock.fell.connect(func() -> void: fall_frame[0] = Engine.get_physics_frames())
	rock.broke.connect(func() -> void: break_frame[0] = Engine.get_physics_frames())
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the player never landed to run under the rock")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	await wait_until(func() -> bool:
		if shake_frame[0] < 0 and rock.get_state() == FallingRock.State.SHAKING:
			shake_frame[0] = Engine.get_physics_frames()
		return break_frame[0] >= 0)
	var tip_on_floor: bool = absf(CEILING_Y + rock.get_fall_distance()
			+ (rock.get_node(^"%Tip") as Node2D).position.y) <= FLOOR_TOLERANCE
	var hung_again: bool = await wait_until(func() -> bool:
		return rock.get_state() == FallingRock.State.HANGING)
	var respawned_after: float = float(Engine.get_physics_frames() - break_frame[0]) / 60.0
	await remove_player(player)
	rock.queue_free()
	var warned: float = float(fall_frame[0] - shake_frame[0]) / 60.0
	return report(shake_frame[0] >= 0 and absf(warned - rock.warn_time) <= TIME_TOLERANCE
			and tip_on_floor and hung_again
			and absf(respawned_after - rock.respawn_time) <= TIME_TOLERANCE,
			"Rock: shook %.2f s before falling (Warn Time %.2f), tip on the floor %s, hung again %.2f s after breaking (Respawn Time %.2f)"
			% [warned, rock.warn_time, tip_on_floor, respawned_after, rock.respawn_time])


func _rock_hits_a_player_below_once_and_breaks() -> bool:
	var rock: FallingRock = _add(ROCK_SCENE, Vector2(HAZARD_X, CEILING_Y)) as FallingRock
	var hazard: Hazard = rock.get_node(^"%Hazard") as Hazard
	var hits: Array[int] = [0]
	hazard.player_hit.connect(func(_player: Node2D, _fraction: float) -> void: hits[0] += 1)
	var player: Player = await spawn_on_floor(Vector2(HAZARD_X, -2.0))
	if player == null:
		return report(false, "the player never landed under the rock")
	var broke: bool = await wait_until(func() -> bool:
		return rock.get_state() == FallingRock.State.BROKEN)
	await wait_frames(SETTLE_FRAMES)
	await remove_player(player)
	rock.queue_free()
	return report(broke and hits[0] == 1,
			"Rock on a player standing below: broke %s, %d hit(s), expected 1" % [broke, hits[0]])


func _add(scene: PackedScene, at: Vector2) -> Node2D:
	var node: Node2D = scene.instantiate() as Node2D
	node.position = at
	root.add_child(node)
	return node
