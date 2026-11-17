# Checks Velvet's stroll, in the tutorial of level 1. With the man away, she walks to each end of
# her Walk Reach and back, never past it, turned the way she walks and on her standing frame while
# she waits at an end; her key goes with her body and her Talk Area stays where she stands in the
# level. While the man is in her Talk Area she stands still, turned to his side, also when he
# crosses to her other side; while she talks she stands still even with him away. Once he goes, she
# walks again.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_velvet_walk.gd
extends "res://tests/support/player_test.gd"

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/lust/level1.tscn")
## Frames to watch her stroll: from her first pause, to both ends and back, at the values in the
## scene (about 7.4 s).
const STROLL_FRAMES: int = 600
## Where the man waits away from her, in px from where she stands: just left of her Talk Area, on
## the floor she walks on.
const AWAY: float = -272.0
## Where the man stands near her, in px from where she stands, on either side: inside her Talk
## Area, and past her body at the end of her reach.
const NEAR: float = 200.0
## Frames he stays near her while she has to stand still.
const NEAR_FRAMES: int = 90
## How far above the floor the man is dropped to land on her back, in px: over her trunk's 54.
const ON_HER_BACK: float = 70.0
## How far her body may move while she has to stand still, in px.
const STILL: float = 0.01
## How close to an end of her reach counts as reaching it, in px.
const AT_END: float = 0.5


func _initialize() -> void:
	# The DialogueManager autoload joins the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(await _she_strolls_both_ways_within_her_reach())
	results.append(await _near_her_she_stands_turned_to_the_man())
	results.append(await _once_he_goes_she_walks_again())
	results.append(await _while_she_talks_she_stands_still())
	_progress().reset()
	finish(results)


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


## The level, with the first talk already over when met is true, so the man coming near does not
## open the balloon.
func _new_level(met: bool) -> Node2D:
	_progress().reset()
	if met:
		_progress().mark_event(TutorialDemon.MET_EVENT)
	var level: Node2D = LEVEL_SCENE.instantiate() as Node2D
	root.add_child(level)
	await physics_frame
	return level


func _remove_level(level: Node2D) -> void:
	level.queue_free()
	await physics_frame


func _velvet(level: Node2D) -> TutorialDemon:
	return level.get_node(^"Tutorial/TutorialDemon") as TutorialDemon


func _body(velvet: TutorialDemon) -> Node2D:
	return velvet.get_node(^"%Body") as Node2D


func _sprite(velvet: TutorialDemon) -> Sprite2D:
	return velvet.get_node(^"%Sprite") as Sprite2D


## 1.0 when her art faces right, -1.0 when it faces left.
func _facing(velvet: TutorialDemon) -> float:
	return signf(_sprite(velvet).scale.x)


func _place_man(level: Node2D, velvet: TutorialDemon, dx: float) -> void:
	(level.get_node(^"Player") as Player).global_position = velvet.global_position + Vector2(dx, 0.0)


func _she_strolls_both_ways_within_her_reach() -> bool:
	var level: Node2D = await _new_level(true)
	var velvet: TutorialDemon = _velvet(level)
	var body: Node2D = _body(velvet)
	var sprite: Sprite2D = _sprite(velvet)
	var key: Node2D = velvet.get_node(^"%TalkKey") as Node2D
	var area: Node2D = velvet.get_node(^"%TalkArea") as Node2D
	var area_x: float = area.global_position.x
	var home: float = velvet.global_position.x
	_place_man(level, velvet, AWAY)
	var lowest: float = 0.0
	var highest: float = 0.0
	var turned_wrong: int = 0
	var off_frame: int = 0
	var jumped_in: int = 0
	var key_apart: int = 0
	var longest_rest_at_end: int = 0
	var rest: int = 0
	var frames_seen: Dictionary[int, bool] = {}
	var last: float = body.global_position.x
	var was_still: bool = true
	for i: int in STROLL_FRAMES:
		await physics_frame
		var x: float = body.global_position.x
		lowest = minf(lowest, x - home)
		highest = maxf(highest, x - home)
		if x != last and signf(x - last) != _facing(velvet):
			turned_wrong += 1
		if x == last and sprite.frame != velvet.stand_frame:
			off_frame += 1
		if x != last and was_still and sprite.frame != velvet.stand_frame:
			jumped_in += 1
		if not is_equal_approx(key.position.x, body.position.x):
			key_apart += 1
		if x != last:
			frames_seen[sprite.frame] = true
		rest = rest + 1 if x == last and absf(x - home) >= velvet.walk_reach - AT_END else 0
		longest_rest_at_end = maxi(longest_rest_at_end, rest)
		was_still = x == last
		last = x
	var reach: float = velvet.walk_reach
	var both_ends: bool = highest >= reach - AT_END and lowest <= -reach + AT_END
	var within: bool = highest <= reach + AT_END and lowest >= -reach - AT_END
	var area_put: bool = is_equal_approx(area.global_position.x, area_x)
	var walk_frames: int = sprite.hframes
	var steps: bool = frames_seen.size() == walk_frames
	# Walk Pause counted down in steps of 1/60 s may end a frame early.
	var rests: bool = longest_rest_at_end >= roundi(velvet.walk_pause * 60.0) - 1
	await _remove_level(level)
	return report(both_ends and within and rests and turned_wrong == 0 and off_frame == 0
			and jumped_in == 0 and key_apart == 0 and area_put and steps,
			("Velvet strolls from %.1f to %.1f px of where she stands (reach %.0f): both ends %s, "
			+ "within %s, rests %d frames at an end; %d frame(s) turned against her way, %d "
			+ "standing off her standing frame, %d walks not starting on it, %d with her key apart; "
			+ "Talk Area in place %s; %d of %d walk frames shown")
			% [lowest, highest, reach, both_ends, within, longest_rest_at_end, turned_wrong,
			off_frame, jumped_in, key_apart, area_put, frames_seen.size(), walk_frames])


func _near_her_she_stands_turned_to_the_man() -> bool:
	var level: Node2D = await _new_level(true)
	var velvet: TutorialDemon = _velvet(level)
	var body: Node2D = _body(velvet)
	var sprite: Sprite2D = _sprite(velvet)
	var home: float = velvet.global_position.x
	_place_man(level, velvet, AWAY)
	# Walking right, so a man on her left is behind her.
	var walking_right: bool = await wait_until(
			func() -> bool: return body.global_position.x - home > velvet.walk_reach * 0.5)
	_place_man(level, velvet, -NEAR)
	await wait_frames(2)
	var stopped_at: float = body.global_position.x
	await wait_frames(NEAR_FRAMES)
	var still_left: bool = absf(body.global_position.x - stopped_at) <= STILL
	var turned_left: bool = _facing(velvet) < 0.0
	var standing: bool = sprite.frame == velvet.stand_frame
	_place_man(level, velvet, NEAR)
	await wait_frames(NEAR_FRAMES)
	var still_right: bool = absf(body.global_position.x - stopped_at) <= STILL
	var turned_right: bool = _facing(velvet) > 0.0
	# Right over her, on her back: no side to turn to, so she stays as she was, and shown.
	(level.get_node(^"Player") as Player).global_position = body.global_position \
			- Vector2(0.0, ON_HER_BACK)
	await wait_frames(NEAR_FRAMES)
	# A scale of 0 is kept as 0.00001, which still faces right: her size tells she is shown.
	var kept: bool = _facing(velvet) > 0.0 and sprite.scale.x == sprite.scale.y
	await _remove_level(level)
	return report(walking_right and still_left and turned_left and standing and still_right
			and turned_right and kept,
			("Velvet with the man near: was walking right %s; with him on her left, still %s, "
			+ "turned to him %s, on her standing frame %s; with him then on her right, still %s, "
			+ "turned to him %s; with him right over her, still turned and shown %s")
			% [walking_right, still_left, turned_left, standing, still_right, turned_right, kept])


func _once_he_goes_she_walks_again() -> bool:
	var level: Node2D = await _new_level(true)
	var velvet: TutorialDemon = _velvet(level)
	var body: Node2D = _body(velvet)
	var sprite: Sprite2D = _sprite(velvet)
	_place_man(level, velvet, NEAR)
	await wait_frames(NEAR_FRAMES)
	var stopped_at: float = body.global_position.x
	_place_man(level, velvet, AWAY)
	var walks: bool = await wait_until(
			func() -> bool: return absf(body.global_position.x - stopped_at) > 1.0)
	var steps: bool = await wait_until(
			func() -> bool: return sprite.frame != velvet.stand_frame)
	await _remove_level(level)
	return report(walks and steps,
			"Velvet once the man goes: walks again %s, steps through her walk frames %s"
			% [walks, steps])


func _while_she_talks_she_stands_still() -> bool:
	var level: Node2D = await _new_level(false)
	var velvet: TutorialDemon = _velvet(level)
	var body: Node2D = _body(velvet)
	_place_man(level, velvet, -NEAR)
	var talks: bool = await wait_until(
			func() -> bool: return velvet.get_state() == TutorialDemon.State.TALKING)
	# Out of her Talk Area by hand: only her talking keeps her still now.
	_place_man(level, velvet, AWAY)
	await wait_frames(2)
	var stopped_at: float = body.global_position.x
	await wait_frames(NEAR_FRAMES)
	var still: bool = velvet.get_state() == TutorialDemon.State.TALKING \
			and absf(body.global_position.x - stopped_at) <= STILL
	await _remove_level(level)
	return report(talks and still,
			"Velvet talking with the man moved away: talks %s, stands still %s" % [talks, still])
