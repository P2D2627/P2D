# Checks the way into phase 2 of level 1, up the shaft from the corridor below: phase 2's save point is reached
# however the man comes out of the shaft's mouth, and Asmodeus says phase 2's offer only once he stands. Out of
# the mouth onto the floor's edge left of it, or standing on the ledge right of it, the save marks its event and
# she talks; in the mouth, in the air, the save marks its event at once, she does not talk while he is in the
# air, and talks once he stands. Put at the respawn, by the mouth, he is not in the save (as the cutscene test
# puts him there).
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_phase2_save_entry.gd
extends "res://tests/support/player_test.gd"

const LEVEL1: String = "res://scenes/levels/lust/level1.tscn"
const EVENT: StringName = &"lust_phase_2_reached"
## Where the man is put, his feet, in the level: out of the shaft's mouth over the edge of the floor left of it,
## a tile up, so he lands on that edge; on the ledge right of the mouth; in the middle of the mouth, a tile up,
## in the air; and at phase 2's respawn, by the mouth.
const OVER_THE_LEFT_EDGE: Vector2 = Vector2(16900.0, 11812.0)
const ON_THE_LEDGE: Vector2 = Vector2(17088.0, 11858.0)
const IN_THE_MOUTH: Vector2 = Vector2(16968.0, 11812.0)
const AT_THE_RESPAWN: Vector2 = Vector2(16872.0, 11856.0)
## Frames given for the save to see him, and for her to start talking.
const SEE_FRAMES: int = 10
const TALK_FRAMES: int = 240


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(await _reached_standing(OVER_THE_LEFT_EDGE, "out of the mouth onto the left edge"))
	results.append(await _reached_standing(ON_THE_LEDGE, "on the ledge right of the mouth"))
	results.append(await _reached_in_the_air_she_waits_for_the_floor())
	results.append(await _not_reached_at_the_respawn())
	finish(results)


func _not_reached_at_the_respawn() -> bool:
	var level: Level = await _new_level()
	_put(level, AT_THE_RESPAWN)
	await wait_frames(SEE_FRAMES)
	var reached: bool = _progress().has_event(EVENT)
	await _remove(level)
	return report(not reached, "Put at the respawn, by the mouth: phase 2 reached %s (false)" % reached)


func _reached_standing(feet: Vector2, where: String) -> bool:
	var level: Level = await _new_level()
	_put(level, feet)
	await wait_frames(SEE_FRAMES)
	var reached: bool = _progress().has_event(EVENT)
	var talked: bool = await wait_until(_talking.bind(level), TALK_FRAMES)
	await _remove(level)
	return report(reached and talked, "Standing %s: phase 2 reached %s, she talks %s" % [where, reached, talked])


func _reached_in_the_air_she_waits_for_the_floor() -> bool:
	var level: Level = await _new_level()
	_put(level, IN_THE_MOUTH)
	await wait_frames(2)
	var reached: bool = _progress().has_event(EVENT)
	var talked_in_the_air: Array[bool] = [false]
	var watch: Callable = func() -> void:
		if not level.player.is_on_floor() and _talking(level):
			talked_in_the_air[0] = true
	physics_frame.connect(watch)
	var talked: bool = await wait_until(_talking.bind(level), TALK_FRAMES)
	physics_frame.disconnect(watch)
	var standing: bool = level.player.is_on_floor()
	await _remove(level)
	return report(reached and not talked_in_the_air[0] and talked and standing,
			"In the mouth, in the air: phase 2 reached %s, she talked in the air %s, then talks %s with him standing %s"
			% [reached, talked_in_the_air[0], talked, standing])


func _new_level() -> Level:
	_progress().reset()
	var level: Level = (load(LEVEL1) as PackedScene).instantiate() as Level
	root.add_child(level)
	await physics_frame
	return level


func _put(level: Level, feet: Vector2) -> void:
	level.player.global_position = feet
	level.player.velocity = Vector2.ZERO
	level.player.reset_physics_interpolation()


func _talking(level: Level) -> bool:
	return (level.get_node(^"Asmodeus") as Asmodeus).is_talking()


func _remove(level: Level) -> void:
	level.queue_free()
	await physics_frame
	await physics_frame


func _progress() -> GameProgress:
	return root.get_node(^"/root/GameState") as GameProgress
