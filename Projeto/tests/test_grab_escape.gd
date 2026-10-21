# Checks the grab on the man in his own scene (ADR 0021). At low SP, a bite grabs him: he stops at
# once, also at a run, and can't run or jump; grabbed in the air, going up in a jump, against a wall
# or thrown by a hit, he goes no higher and falls straight down as in the air, and nothing he lands
# on shoves him off until he breaks free. The crucifix goes down and stays down, and another bite
# while he is held changes nothing, also with his SP back above Low Threshold. The bite that grabbed
# him hears that it holds him, once, and that he is free when he breaks free; another demon's bite
# joins and asks for more presses, and a third's joins nothing: with the most holding him, his
# Hurtbox takes no hits, with no blink, until he is free (ADR 0029). Presses of Jump free him on
# Presses To Escape, with no jump on that frame or after; free, he runs again, the crucifix can go
# up and he is invulnerable for a moment, after which a bite grabs him again and asks for every
# press again. With no presses he dies on Time To Die and stays held, and takes no more hits, since
# the room starts over. With Hold To Escape on, Jump held from before the grab gives nothing, and
# from a press on, holding frees him on Hold Time To Escape. The pause stops the grab's clock. The
# stand-in prompt shows while he is held, with the grab's progress in its bar, and says he died when
# the time runs out, so a man who can't move never looks free. Held, his drawing sinks at the pace
# of Time To Die while he stays where he is, is all the way down when he dies, and is back up on the
# frame he breaks free (ADR 0026); the demons holding him hear how far he sank, one that joins from
# where he is, and 0 before they let go. The timing cases give the grab its own copy of Grab Stats
# with a short Time To Die, so they do not wait 3 s each.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_escape.gd
extends "res://tests/support/player_test.gd"

const HITBOX_SCENE: PackedScene = preload("res://components/hitbox.tscn")
## The floor runs from FLOOR_LEFT to FLOOR_RIGHT with its top at y = 0; the man starts on it.
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const START: Vector2 = Vector2(0.0, -2.0)
## SP a case takes from the man's 100 before the bite, to put him below Low Threshold.
const DAMAGE_TO_LOW: float = 80.0
## SP given back to a held man, as the regeneration would, to take him above Low Threshold again.
const SP_BACK_ABOVE_LOW: float = 20.0
## The bite: SP it would take, how far and how high it would throw, and where it is, on the man's
## left.
const BITE_DAMAGE: float = 10.0
const BITE_DISTANCE: float = 150.0
const BITE_HEIGHT: float = 40.0
const BITE_SIZE: Vector2 = Vector2(96.0, 96.0)
const BITE_OFFSET: float = 30.0
## Physics frames for a bite to land, or for a press or a block to take effect.
const HIT_FRAMES: int = 10
const SETTLE_FRAMES: int = 3
## Physics frames the man is watched running or not jumping.
const WATCH_FRAMES: int = 30
## Most px the man may move while held, and least he runs in WATCH_FRAMES once free.
const HELD_DRIFT: float = 1.0
const MIN_RUN_DISTANCE: float = 50.0
## Physics frames from a press of Jump to the bite, with the man still going up.
const RISE_FRAMES: int = 4
## A stand-in for a demon's body, centred under START, and how far above it the man drops.
const BODY_SIZE: Vector2 = Vector2(120.0, 48.0)
const DROP_HEIGHT: float = 40.0
## A wall right of START, from WALL_LEFT to WALL_RIGHT, and WALL_HEIGHT high.
const WALL_LEFT: float = 80.0
const WALL_RIGHT: float = 180.0
const WALL_HEIGHT: float = 600.0
## Time To Die in the timing cases, and the physics frames the pause case stays paused: longer.
const SHORT_TIME_TO_DIE: float = 0.5
const PAUSE_FRAMES: int = 60
## Presses before the prompt's bar is read.
const PROMPT_PRESSES: int = 3
## Presses, or frames, to give up after.
const MOST_FRAMES: int = 600
## Share of the full depth the drawing may be off at half Time To Die: a few frames' worth.
const SINK_TOLERANCE: float = 0.1


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _a_bite_at_low_sp_holds_him_and_keeps_the_crucifix_down())
	results.append(await _grabbed_at_a_run_he_stops_at_once())
	results.append(await _grabbed_going_up_he_falls_straight_down())
	results.append(await _grabbed_on_a_wall_he_falls_as_in_the_air())
	results.append(await _grabbed_in_a_knockback_he_falls_straight_down())
	results.append(await _held_he_is_not_shoved_off_until_he_breaks_free())
	results.append(await _held_with_sp_back_up_a_bite_still_hurts_nothing())
	results.append(await _the_bite_that_grabs_holds_him_until_he_breaks_free())
	results.append(await _a_second_demon_joins_the_grab_and_a_third_does_not())
	results.append(await _held_by_the_most_demons_he_takes_no_hits_until_he_is_free())
	results.append(await _presses_free_him_with_no_jump_and_he_moves_again())
	results.append(await _free_he_is_grabbed_again_only_after_the_invulnerability())
	results.append(await _with_no_presses_he_dies_and_stays_held())
	results.append(await _dead_he_takes_no_more_hits())
	results.append(await _holding_frees_him_only_from_a_press_in_the_grab())
	results.append(await _the_pause_stops_the_grabs_clock())
	results.append(await _the_prompt_shows_while_held_with_the_progress())
	results.append(await _the_prompt_says_he_died())
	results.append(await _his_drawing_sinks_with_the_time_and_is_back_as_he_breaks_free())
	results.append(await _dead_his_drawing_is_all_the_way_down())
	results.append(await _the_demons_holding_him_sink_with_him_and_come_back_up())
	finish(results)


## The crucifix is up when the bite lands. Held, running and a press of Jump move him by no more
## than HELD_DRIFT, and a second bite while he is held grabs nothing.
func _a_bite_at_low_sp_holds_him_and_keeps_the_crucifix_down() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Bite at low SP: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	var crucifix: Crucifix = _crucifix_of(man)
	var heard: Array[StringName] = _signals_of(escape)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_before: bool = crucifix.is_raised()
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var landings: Array[int] = _landings_of(bite)
	var crucifix_down: bool = not crucifix.is_raised() and crucifix.is_blocked()
	var start: Vector2 = man.position
	stand_in.run_direction = 1.0
	await wait_frames(WATCH_FRAMES)
	stand_in.run_direction = 0.0
	await physics_frame
	stand_in.press_jump()
	await wait_frames(WATCH_FRAMES)
	var moved: float = man.position.distance_to(start)
	_bite_again(bite)
	await wait_frames(HIT_FRAMES)
	var passed: bool = (up_before and escape.is_held() and crucifix_down and moved <= HELD_DRIFT
			and landings.size() == 1 and heard == [&"grabbed"])
	var verdict: bool = report(passed,
			("Crucifix up %s, bitten: held %s, crucifix down and blocked %s, moved %.2f px running "
			+ "and jumping; a second bite landed %d times, signals %s") % [up_before,
			escape.is_held(), crucifix_down, moved, landings.size(), heard])
	bite.queue_free()
	await remove_player(man)
	return verdict


## Grabbed at full run, left into the bite, the man stops on the frame he is held: with the run
## still held, he moves by no more than HELD_DRIFT.
func _grabbed_at_a_run_he_stops_at_once() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Grabbed at a run: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	stand_in.run_direction = -1.0
	await wait_frames(WATCH_FRAMES)
	var speed: float = absf(man.velocity.x)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var start: Vector2 = man.position
	await wait_frames(WATCH_FRAMES)
	var moved: float = man.position.distance_to(start)
	var passed: bool = speed > 0.0 and escape.is_held() and moved <= HELD_DRIFT
	var verdict: bool = report(passed,
			"Grabbed running at %.0f px/s: held %s, moved %.2f px in %d frames with the run held"
			% [speed, escape.is_held(), moved, WATCH_FRAMES])
	bite.queue_free()
	await remove_player(man)
	return verdict


## Grabbed going up in a jump at a run, the man goes no higher and falls straight down: from the
## frame he is held until he lands, still held, he rises and moves across by HELD_DRIFT at most.
func _grabbed_going_up_he_falls_straight_down() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Grabbed going up: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	stand_in.run_direction = -1.0
	await wait_frames(WATCH_FRAMES)
	stand_in.hold_jump = true
	stand_in.press_jump()
	await wait_frames(RISE_FRAMES)
	var rising: bool = man.velocity.y < 0.0
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var start: Vector2 = man.position
	var rose: float = 0.0
	var landed: bool = false
	for _frame: int in MOST_FRAMES:
		await physics_frame
		rose = maxf(rose, start.y - man.position.y)
		if man.is_on_floor():
			landed = true
			break
	var across: float = absf(man.position.x - start.x)
	var passed: bool = (rising and landed and escape.is_held() and rose <= HELD_DRIFT
			and across <= HELD_DRIFT)
	var verdict: bool = report(passed,
			("Grabbed going up %s: rose %.2f px more and moved %.2f px across before landing %s, "
			+ "held %s") % [rising, rose, across, landed, escape.is_held()])
	bite.queue_free()
	await remove_player(man)
	return verdict


## Grabbed against a wall, pushing into it after a jump up it, the man leaves the wall and falls as
## in the air: from the frame after the grab until he lands, still held, he is never on the wall and
## moves across by HELD_DRIFT at most.
func _grabbed_on_a_wall_he_falls_as_in_the_air() -> bool:
	var wall: StaticBody2D = make_wall(WALL_LEFT, WALL_RIGHT, -WALL_HEIGHT)
	var man: Player = await _low_sp_man()
	if man == null:
		wall.queue_free()
		return report(false, "Grabbed on a wall: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	stand_in.run_direction = 1.0
	await wait_frames(WATCH_FRAMES)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var on_wall: bool = await wait_until(
			func() -> bool: return man.get_state() == Player.State.ON_WALL, MOST_FRAMES)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	await physics_frame
	var start: Vector2 = man.position
	var wall_frames: int = 0
	var landed: bool = false
	for _frame: int in MOST_FRAMES:
		if man.get_state() == Player.State.ON_WALL:
			wall_frames += 1
		if man.is_on_floor():
			landed = true
			break
		await physics_frame
	var across: float = absf(man.position.x - start.x)
	var passed: bool = (on_wall and landed and escape.is_held() and wall_frames == 0
			and across <= HELD_DRIFT)
	var verdict: bool = report(passed,
			("Grabbed on a wall %s: on the wall %d frames after, moved %.2f px across before "
			+ "landing %s, held %s") % [on_wall, wall_frames, across, landed, escape.is_held()])
	bite.queue_free()
	wall.queue_free()
	await remove_player(man)
	return verdict


## Thrown by a hit and grabbed in the air, the man is no longer thrown: from the frame he is held
## until he lands, still held, the knockback is over and he moves across by HELD_DRIFT at most.
func _grabbed_in_a_knockback_he_falls_straight_down() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Grabbed in a knockback: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	man.knock_back(-1.0, BITE_DISTANCE, BITE_HEIGHT)
	await wait_frames(RISE_FRAMES)
	var thrown: bool = man.is_knocked_back() and not man.is_on_floor()
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var start: Vector2 = man.position
	var knocked_back: bool = false
	var landed: bool = false
	for _frame: int in MOST_FRAMES:
		knocked_back = knocked_back or man.is_knocked_back()
		if man.is_on_floor():
			landed = true
			break
		await physics_frame
	var across: float = absf(man.position.x - start.x)
	var passed: bool = (thrown and landed and escape.is_held() and not knocked_back
			and across <= HELD_DRIFT)
	var verdict: bool = report(passed,
			("Grabbed thrown by a hit %s: still thrown %s, moved %.2f px across before landing %s, "
			+ "held %s") % [thrown, knocked_back, across, landed, escape.is_held()])
	bite.queue_free()
	await remove_player(man)
	return verdict


## Held, the man drops onto a body he can't stand on, a stand-in for a demon's on Knock Off Layers:
## it does not shove him off, and he stays on it, held, moving by no more than HELD_DRIFT. Free, it
## shoves him off again, down onto the floor (ADR 0022).
func _held_he_is_not_shoved_off_until_he_breaks_free() -> bool:
	var body: StaticBody2D = make_wall(-BODY_SIZE.x / 2.0, BODY_SIZE.x / 2.0, -BODY_SIZE.y)
	var man: Player = spawn_player(Vector2(0.0, -BODY_SIZE.y - DROP_HEIGHT))
	body.collision_layer = man.knock_off_layers
	var stand_in: StandInInput = put_a_stand_in(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	var escape: GrabEscape = _escape_of(man)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var landed: bool = await wait_until(man.is_on_floor, MOST_FRAMES)
	var start: Vector2 = man.position
	await wait_frames(WATCH_FRAMES)
	var moved: float = man.position.distance_to(start)
	var on_it: bool = man.is_on_floor() and man.position.y < -BODY_SIZE.y / 2.0
	var held: bool = escape.is_held()
	await _press_until_free(escape, stand_in)
	var shoved_off: bool = await wait_until(
			func() -> bool: return man.is_on_floor() and man.position.y > -BODY_SIZE.y / 2.0,
			WATCH_FRAMES)
	var passed: bool = landed and on_it and held and moved <= HELD_DRIFT and shoved_off
	var verdict: bool = report(passed,
			("Held, dropped on a body he can't stand on: landed %s, still on it %s, held %s, moved "
			+ "%.2f px in %d frames; free, shoved off onto the floor %s") % [landed, on_it, held,
			moved, WATCH_FRAMES, shoved_off])
	bite.queue_free()
	body.queue_free()
	await remove_player(man)
	return verdict


## Held, with his SP back above Low Threshold: a second bite lands, but takes no SP, throws him
## nowhere and leaves him held, with no new grab.
func _held_with_sp_back_up_a_bite_still_hurts_nothing() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Held with SP back up: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	man.soul_points.heal(SP_BACK_ABOVE_LOW)
	var low: bool = man.soul_points.is_low()
	var sp_before: float = man.soul_points.get_sp()
	var start: Vector2 = man.position
	var landings: Array[int] = _landings_of(bite)
	_bite_again(bite)
	var thrown: bool = false
	for _frame: int in HIT_FRAMES:
		await physics_frame
		thrown = thrown or man.is_knocked_back()
	var moved: float = man.position.distance_to(start)
	var passed: bool = (not low and landings.size() == 1 and man.soul_points.get_sp() >= sp_before
			and not thrown and moved <= HELD_DRIFT and escape.is_held() and heard == [&"grabbed"])
	var verdict: bool = report(passed,
			("Held with SP %.1f, low %s: a bite landed %d times, SP after %.1f, thrown %s, moved "
			+ "%.2f px, held %s, signals %s") % [sp_before, low, landings.size(),
			man.soul_points.get_sp(), thrown, moved, escape.is_held(), heard])
	bite.queue_free()
	await remove_player(man)
	return verdict


## The bite that grabs hears that it holds the man's Hurtbox, once, and not again when it lands a
## second time while he is held; it hears that he is free once, when he breaks free.
func _the_bite_that_grabs_holds_him_until_he_breaks_free() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Hold on the bite: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	var hurtbox: Hurtbox = _hurtbox_of(man)
	var bite: Hitbox = _make_bite_by(man)
	var heard: Array[StringName] = []
	bite.hold_started.connect(func(held: Hurtbox) -> void:
			heard.append(&"hold_started" if held == hurtbox else &"hold_started on another"))
	bite.hold_ended.connect(func(freed: Hurtbox) -> void:
			heard.append(&"hold_ended" if freed == hurtbox else &"hold_ended on another"))
	bite.activate()
	await wait_until(escape.is_held, HIT_FRAMES)
	_bite_again(bite)
	await wait_frames(HIT_FRAMES)
	var while_held: Array[StringName] = heard.duplicate()
	await _press_until_free(escape, man.input as StandInInput)
	var passed: bool = while_held == [&"hold_started"] and heard == [&"hold_started", &"hold_ended"]
	var verdict: bool = report(passed,
			"The bite that grabbed heard %s while he was held, and %s once he broke free"
			% [while_held, heard])
	bite.queue_free()
	await remove_player(man)
	return verdict


## Two more bites, from other demons, while the man is held: the first of them joins the grab and
## hears that it holds him, and he needs Extra Presses Per Demon more; the second finds
## GrabRules.MAX_DEMONS holding him and joins nothing. Free, the two that held him hear it, and the
## third does not.
func _a_second_demon_joins_the_grab_and_a_third_does_not() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Second demon: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	var first: Hitbox = await _bite_and_wait_for_the_grab(man)
	var second: Hitbox = _make_bite_by(man)
	var third: Hitbox = _make_bite_by(man)
	var bites: Array[Hitbox] = [first, second, third]
	var started: Array[Hitbox] = []
	var ended: Array[Hitbox] = []
	for bite: Hitbox in bites:
		bite.hold_started.connect(func(_held: Hurtbox) -> void: started.append(bite))
		bite.hold_ended.connect(func(_freed: Hurtbox) -> void: ended.append(bite))
	second.activate()
	await wait_frames(HIT_FRAMES)
	third.activate()
	await wait_frames(HIT_FRAMES)
	var presses: int = await _press_until_free(escape, man.input as StandInInput)
	var needed: int = escape.stats.presses_to_escape + escape.stats.extra_presses_per_demon
	var passed: bool = (started == [second] and presses == needed and ended.size() == 2
			and ended.has(first) and ended.has(second))
	var verdict: bool = report(passed,
			("Held, two more bites: second joined %s, third joined %s; free after %d presses of %d; "
			+ "let go: first %s, second %s, third %s") % [started.has(second), started.has(third),
			presses, needed, ended.has(first), ended.has(second), ended.has(third)])
	for bite: Hitbox in bites:
		bite.queue_free()
	await remove_player(man)
	return verdict


## Held by one demon, the man still takes hits, so another can join; held by GrabRules.MAX_DEMONS,
## he takes none: a third bite lands nothing, and he is not invulnerable, so he does not blink.
## Free, he is invulnerable, and takes hits again once that is over (ADR 0029).
func _held_by_the_most_demons_he_takes_no_hits_until_he_is_free() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Held by the most: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	var hurtbox: Hurtbox = _hurtbox_of(man)
	var first: Hitbox = await _bite_and_wait_for_the_grab(man)
	var with_one: bool = hurtbox.takes_hits()
	var second: Hitbox = _make_bite_by(man)
	second.activate()
	await wait_frames(HIT_FRAMES)
	var with_two: bool = hurtbox.takes_hits()
	var blinks: bool = hurtbox.is_invulnerable()
	var third: Hitbox = _make_bite_by(man)
	var bites: Array[Hitbox] = [first, second, third]
	var third_landings: Array[int] = _landings_of(third)
	third.activate()
	await wait_frames(HIT_FRAMES)
	await _press_until_free(escape, man.input as StandInInput)
	third.deactivate()
	var invulnerable: bool = hurtbox.is_invulnerable()
	await wait_until(func() -> bool: return not hurtbox.is_invulnerable(), MOST_FRAMES)
	var after: bool = hurtbox.takes_hits()
	var verdict: bool = report(with_one and not with_two and not blinks
			and third_landings.is_empty() and invulnerable and after,
			("Held by one demon: takes hits %s; by two: takes hits %s, invulnerable %s; a third bite "
			+ "landed %d times; free: invulnerable %s, then takes hits %s") % [with_one, with_two,
			blinks, third_landings.size(), invulnerable, after])
	for bite: Hitbox in bites:
		bite.queue_free()
	await remove_player(man)
	return verdict


## A press on each frame: free on the press Presses To Escape asks for, not jumping on that frame
## or after it, invulnerable, with the crucifix no longer blocked, and running again.
func _presses_free_him_with_no_jump_and_he_moves_again() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Pressing free: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var presses: int = await _press_until_free(escape, stand_in)
	var invulnerable: bool = _hurtbox_of(man).is_invulnerable()
	var blocked: bool = _crucifix_of(man).is_blocked()
	var jumped: bool = false
	for _frame: int in WATCH_FRAMES:
		await physics_frame
		jumped = jumped or not man.is_on_floor() or man.velocity.y < 0.0
	var start_x: float = man.position.x
	stand_in.run_direction = 1.0
	await wait_frames(WATCH_FRAMES)
	var ran: float = man.position.x - start_x
	var passed: bool = (presses == escape.stats.presses_to_escape and not escape.is_held()
			and not jumped and invulnerable and not blocked and ran >= MIN_RUN_DISTANCE
			and heard == [&"grabbed", &"broke_free"])
	var verdict: bool = report(passed,
			("Free after %d presses of %d: jumped %s, invulnerable %s, crucifix blocked %s, ran "
			+ "%.1f px, signals %s") % [presses, escape.stats.presses_to_escape, jumped,
			invulnerable, blocked, ran, heard])
	bite.queue_free()
	await remove_player(man)
	return verdict


## A bite on again as he breaks free lands only when Invulnerable Time ends, and the new grab asks
## for every press again.
func _free_he_is_grabbed_again_only_after_the_invulnerability() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Grabbed again: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	await _press_until_free(escape, stand_in)
	var landings: Array[int] = _landings_of(bite)
	_bite_again(bite)
	var invulnerable_frames: int = roundi(escape.invulnerable_time * Engine.physics_ticks_per_second)
	await wait_frames(invulnerable_frames - SETTLE_FRAMES)
	var held_too_soon: bool = escape.is_held() or not landings.is_empty()
	var held_again: bool = await wait_until(escape.is_held, SETTLE_FRAMES + HIT_FRAMES)
	for _press: int in escape.stats.presses_to_escape - 1:
		await physics_frame
		stand_in.press_jump()
	await physics_frame
	var held_one_short: bool = escape.is_held()
	var passed: bool = (not held_too_soon and held_again and held_one_short
			and heard == [&"grabbed", &"broke_free", &"grabbed"])
	var verdict: bool = report(passed,
			("Bitten again as he broke free: held before Invulnerable Time %s, after it %s; one "
			+ "press short of the new grab, held %s; signals %s") % [held_too_soon, held_again,
			held_one_short, heard])
	bite.queue_free()
	await remove_player(man)
	return verdict


## With SHORT_TIME_TO_DIE and no presses: died once, never broke free, and still can't move, with
## the crucifix down.
func _with_no_presses_he_dies_and_stays_held() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Dying held: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var death_frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second)
	var died: bool = await wait_until(func() -> bool: return &"died" in heard,
			death_frames + SETTLE_FRAMES)
	var start: Vector2 = man.position
	stand_in.run_direction = 1.0
	await wait_frames(WATCH_FRAMES)
	var moved: float = man.position.distance_to(start)
	var blocked: bool = _crucifix_of(man).is_blocked()
	var passed: bool = (died and moved <= HELD_DRIFT and blocked
			and heard == [&"grabbed", &"died"])
	var verdict: bool = report(passed,
			("No presses, Time To Die %.1f s: died %s, moved %.2f px after, crucifix blocked %s, "
			+ "signals %s") % [SHORT_TIME_TO_DIE, died, moved, blocked, heard])
	bite.queue_free()
	await remove_player(man)
	return verdict


## With SHORT_TIME_TO_DIE, no presses and one demon holding him, the man takes no more hits once he
## dies, since the room starts over: another demon's bite lands nothing (ADR 0029).
func _dead_he_takes_no_more_hits() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Hits after death: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var first: Hitbox = await _bite_and_wait_for_the_grab(man)
	var death_frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second)
	var died: bool = await wait_until(func() -> bool: return &"died" in heard,
			death_frames + SETTLE_FRAMES)
	var takes_hits: bool = _hurtbox_of(man).takes_hits()
	var second: Hitbox = _make_bite_by(man)
	var landings: Array[int] = _landings_of(second)
	second.activate()
	await wait_frames(HIT_FRAMES)
	var passed: bool = died and not takes_hits and landings.is_empty()
	var verdict: bool = report(passed,
			"Dead with one demon holding him: died %s, takes hits %s, another bite landed %d times"
			% [died, takes_hits, landings.size()])
	for bite: Hitbox in [first, second]:
		bite.queue_free()
	await remove_player(man)
	return verdict


## Jump held from before the grab, for longer than Hold Time To Escape, gives nothing. A press, with
## Jump still held, starts the hold: free on the frame Hold Time To Escape is reached, counting the
## press's.
func _holding_frees_him_only_from_a_press_in_the_grab() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Holding free: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	escape.hold_to_escape = true
	var hold_frames: int = roundi(escape.stats.hold_time_to_escape * Engine.physics_ticks_per_second)
	stand_in.hold_jump = true
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	await wait_frames(hold_frames + HIT_FRAMES)
	var held_with_old_hold: bool = escape.is_held()
	await physics_frame
	stand_in.press_jump()
	var frames: int = 0
	while frames < MOST_FRAMES:
		frames += 1
		await physics_frame
		if not escape.is_held():
			break
	var passed: bool = held_with_old_hold and frames == hold_frames
	var verdict: bool = report(passed,
			("Hold To Escape: held from before, still held after %d frames %s; from a press, free "
			+ "after %d frames of %d") % [hold_frames + HIT_FRAMES, held_with_old_hold, frames,
			hold_frames])
	bite.queue_free()
	await remove_player(man)
	return verdict


## With SHORT_TIME_TO_DIE, PAUSE_FRAMES of pause, longer than it, kill nothing: after it, he is
## still held, and dies within Time To Die.
func _the_pause_stops_the_grabs_clock() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Pause in a grab: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	paused = true
	await wait_frames(PAUSE_FRAMES)
	paused = false
	var held_after_pause: bool = escape.is_held()
	var death_frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second)
	var died: bool = await wait_until(func() -> bool: return &"died" in heard,
			death_frames + SETTLE_FRAMES)
	var verdict: bool = report(held_after_pause and died,
			("Paused %d frames in a grab of %.1f s: held after %s, died within Time To Die after "
			+ "%s") % [PAUSE_FRAMES, SHORT_TIME_TO_DIE, held_after_pause, died])
	bite.queue_free()
	await remove_player(man)
	return verdict


## The stand-in prompt: hidden before the grab, shown from it with the press text, its bar at the
## grab's progress after PROMPT_PRESSES presses, and hidden once the man is free.
func _the_prompt_shows_while_held_with_the_progress() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Prompt: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	var prompt: GrabPrompt = man.get_node(^"GrabPrompt") as GrabPrompt
	var label: Label = prompt.get_node(^"%Label") as Label
	var bar: ProgressBar = prompt.get_node(^"%Bar") as ProgressBar
	var hidden_before: bool = not prompt.visible
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var shown: bool = prompt.visible and label.text == GrabPrompt.PRESS_TEXT
	for _press: int in PROMPT_PRESSES:
		await physics_frame
		stand_in.press_jump()
	await physics_frame
	await process_frame
	var expected: float = float(PROMPT_PRESSES) / escape.stats.presses_to_escape
	var bar_value: float = bar.value
	await _press_until_free(escape, stand_in)
	var hidden_after: bool = not prompt.visible
	var passed: bool = (hidden_before and shown and is_equal_approx(bar_value, expected)
			and hidden_after)
	var verdict: bool = report(passed,
			("Prompt hidden before %s, shown with \"%s\" %s, bar %.3f of %.3f after %d presses, "
			+ "hidden once free %s") % [hidden_before, label.text, shown, bar_value, expected,
			PROMPT_PRESSES, hidden_after])
	bite.queue_free()
	await remove_player(man)
	return verdict


## With SHORT_TIME_TO_DIE and no presses, the prompt stays shown once he dies, with the death text
## and no bar, since nothing is left to fill.
func _the_prompt_says_he_died() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Prompt at death: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var prompt: GrabPrompt = man.get_node(^"GrabPrompt") as GrabPrompt
	var label: Label = prompt.get_node(^"%Label") as Label
	var bar: ProgressBar = prompt.get_node(^"%Bar") as ProgressBar
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var death_frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second)
	var died: bool = await wait_until(func() -> bool: return &"died" in heard,
			death_frames + SETTLE_FRAMES)
	await process_frame
	var passed: bool = (died and prompt.visible and label.text == GrabPrompt.DIED_TEXT
			and not bar.visible)
	var verdict: bool = report(passed,
			("Prompt at death: died %s, shown %s with \"%s\", bar shown %s") % [died,
			prompt.visible, label.text, bar.visible])
	bite.queue_free()
	await remove_player(man)
	return verdict


## With SHORT_TIME_TO_DIE, at half of it his drawing is about half Depth down, while he and the
## drawing's node stay where they were: only the shader moves it. On the frame he breaks free, by
## the time broke_free comes, it is back at 0.
func _his_drawing_sinks_with_the_time_and_is_back_as_he_breaks_free() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Sinking: the man never landed")
	var stand_in: StandInInput = man.input as StandInInput
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var full: float = (man.get_node(^"SinkingDrawing") as SinkingDrawing).depth
	var drawing: Node2D = man.get_node(^"Placeholder") as Node2D
	var depth_on_free: Array[float] = []
	escape.broke_free.connect(func() -> void: depth_on_free.append(_sink_depth_of(man)))
	var start: Vector2 = man.position
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	await wait_frames(roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second / 2.0))
	var half_way: float = _sink_depth_of(man) / full
	var moved: float = man.position.distance_to(start)
	var drawing_moved: bool = drawing.position != Vector2.ZERO
	await _press_until_free(escape, stand_in)
	var passed: bool = (absf(half_way - 0.5) <= SINK_TOLERANCE and moved <= HELD_DRIFT
			and not drawing_moved and depth_on_free == [0.0] and _sink_depth_of(man) == 0.0)
	var verdict: bool = report(passed,
			("Sinking: at half Time To Die %.2f of Depth down, man moved %.2f px, drawing's node "
			+ "moved %s; depth as he broke free %s") % [half_way, moved, drawing_moved,
			depth_on_free])
	bite.queue_free()
	await remove_player(man)
	return verdict


## With SHORT_TIME_TO_DIE and no presses, his drawing is the whole Depth down once he dies.
func _dead_his_drawing_is_all_the_way_down() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Sunk at death: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var full: float = (man.get_node(^"SinkingDrawing") as SinkingDrawing).depth
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var death_frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second)
	var died: bool = await wait_until(func() -> bool: return &"died" in heard,
			death_frames + SETTLE_FRAMES)
	var depth: float = _sink_depth_of(man)
	var verdict: bool = report(died and depth == full,
			"Sunk at death: died %s, drawing %.1f px down of %.1f" % [died, depth, full])
	bite.queue_free()
	await remove_player(man)
	return verdict


## Two more bites after WATCH_FRAMES held: the first of them joins, the second can't. Each bite that
## holds him hears how far he sank, the one that joins starting where the first one is, not at 0,
## and both hear 0 as he breaks free, before they let go; the bite that can't join hears nothing.
func _the_demons_holding_him_sink_with_him_and_come_back_up() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Demons sinking: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	var first: Hitbox = await _bite_and_wait_for_the_grab(man)
	var first_heard: Array = _hold_log_of(first)
	await wait_frames(WATCH_FRAMES)
	var second: Hitbox = _make_bite_by(man)
	var third: Hitbox = _make_bite_by(man)
	var second_heard: Array = _hold_log_of(second)
	var third_heard: Array = _hold_log_of(third)
	second.activate()
	await wait_frames(HIT_FRAMES)
	third.activate()
	await wait_frames(HIT_FRAMES)
	await _press_until_free(escape, man.input as StandInInput)
	var joined_at: float = second_heard[0] if not second_heard.is_empty() else 0.0
	var joined_where_he_was: bool = joined_at > 0.0 and first_heard.has(joined_at)
	var both_back_up: bool = (first_heard.slice(-2) == [0.0, &"ended"]
			and second_heard.slice(-2) == [0.0, &"ended"])
	var passed: bool = joined_where_he_was and both_back_up and third_heard.is_empty()
	var verdict: bool = report(passed,
			("Demons sinking: second joined at %.3f, where the first was %s; both back at 0 before "
			+ "letting go %s; third heard %d") % [joined_at, joined_where_he_was, both_back_up,
			third_heard.size()])
	for bite: Hitbox in [first, second, third]:
		bite.queue_free()
	await remove_player(man)
	return verdict


## A man on the floor, with a stand-in input and SP below Low Threshold; null if he never lands.
func _low_sp_man() -> Player:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return null
	put_a_stand_in(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	return man


## A bite on the man's left, on, and waits for it to grab him. The case frees the bite.
func _bite_and_wait_for_the_grab(man: Player) -> Hitbox:
	var bite: Hitbox = _make_bite_by(man)
	bite.activate()
	await wait_until(_escape_of(man).is_held, HIT_FRAMES)
	return bite


## A bite on the man's left, still off. The case frees it.
func _make_bite_by(man: Player) -> Hitbox:
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = BITE_SIZE
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = rectangle
	shape.position = Vector2(0.0, -BITE_SIZE.y / 2.0)
	var bite: Hitbox = HITBOX_SCENE.instantiate() as Hitbox
	bite.add_child(shape)
	bite.position = man.position + Vector2(-BITE_OFFSET, 0.0)
	bite.damage = BITE_DAMAGE
	bite.knockback_distance = BITE_DISTANCE
	bite.knockback_height = BITE_HEIGHT
	root.add_child(bite)
	return bite


## Turns the bite off and on again, so it can land once more.
func _bite_again(bite: Hitbox) -> void:
	bite.deactivate()
	bite.activate()


## The frames the bite lands on from now on, one entry each.
func _landings_of(bite: Hitbox) -> Array[int]:
	var landings: Array[int] = []
	bite.hit_landed.connect(
			func(_hurtbox: Hurtbox) -> void: landings.append(Engine.get_physics_frames()))
	return landings


## Presses Jump on each physics frame until the man is free, and gives the presses that took.
func _press_until_free(escape: GrabEscape, stand_in: StandInInput) -> int:
	var presses: int = 0
	for _frame: int in MOST_FRAMES:
		await physics_frame
		if not escape.is_held():
			break
		stand_in.press_jump()
		presses += 1
	return presses


## Gives the grab its own copy of Stats with SHORT_TIME_TO_DIE, so the .tres stays as it is.
func _use_short_time_to_die(escape: GrabEscape) -> void:
	escape.stats = escape.stats.duplicate() as GrabStats
	escape.stats.time_to_die = SHORT_TIME_TO_DIE


## How far the bite hears the man sink, each time, and &"ended" when it lets him go, in order, from
## now on.
func _hold_log_of(bite: Hitbox) -> Array:
	var heard: Array = []
	bite.hold_sink_changed.connect(func(sink: float) -> void: heard.append(sink))
	bite.hold_ended.connect(func(_freed: Hurtbox) -> void: heard.append(&"ended"))
	return heard


## The names of the grab's signals, in the order they come from now on.
func _signals_of(escape: GrabEscape) -> Array[StringName]:
	var heard: Array[StringName] = []
	escape.grabbed.connect(func() -> void: heard.append(&"grabbed"))
	escape.broke_free.connect(func() -> void: heard.append(&"broke_free"))
	escape.died.connect(func() -> void: heard.append(&"died"))
	return heard


## Px the man's drawing is down now, as its shader has it.
func _sink_depth_of(man: Player) -> float:
	var drawing: CanvasItem = man.get_node(^"Placeholder") as CanvasItem
	return float((drawing.material as ShaderMaterial).get_shader_parameter(
			SinkingDrawing.DEPTH_PARAMETER))


func _escape_of(man: Player) -> GrabEscape:
	return man.get_node(^"GrabEscape") as GrabEscape


func _crucifix_of(man: Player) -> Crucifix:
	return man.get_node(^"Crucifix") as Crucifix


func _hurtbox_of(man: Player) -> Hurtbox:
	return man.get_node(^"Hurtbox") as Hurtbox
