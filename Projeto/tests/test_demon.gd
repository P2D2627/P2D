# Checks the demon's chase. It sees the man inside Sight Distance with no wall in between and chases
# him along its own floor; it does not see him further away or through a wall. It stops at an edge
# and against a step of one tile, so the level's own shape keeps it where it was placed. Once it
# chases, it stands still on the man's spot instead of shaking, keeps on past Sight Distance, loses
# him past Lose Distance and does not chase him again, gives up after Give Up Time with a wall
# between them, starts that count over when it sees him again, and lets go of a man who is freed,
# as on a respawn. Inside Lunge Range it warns, still, for Warning Time, with the stand-in rectangle
# crouched and recoloured, and then lunges the way it warned, Lunge Height up, and stays where it
# lands for Recover Time. The lunge lands where the man will be: on one standing still, where one
# walking away will be, nowhere at one coming at it so fast that he is behind it before its warning
# is over, and never further than Lunge Distance nor nearer than Lunge Min Distance. With Lunge Min
# Distance at Lunge Distance, it lunges that far, also when the lunge is quick, and past a man
# standing still it turns and warns as long again; a lunge of half Lunge Distance rises half as
# high, in less time. It never lunges at a man above its floor, at one it cannot see, over a hole,
# or where a quick lunge would land past the end of its floor. The man's raised crucifix pushes it
# out of its radius, also from right on his spot and out of a lunge, never higher than Lunge
# Height, and it then stays still for Repelled Time after the last push, not counting a pause, and
# goes back to chasing, or to standing if it had never seen him; near a ledge, the push throws it
# onto the floor below. Its sight grows at once when Sight Distance changes while the game runs,
# and it is on the enemy layer, collides only with the world and looks only for the player. With a
# bite before the lunge, it bites a man right by it on the run, with the bite's own warning and
# shape, with no pounce and never past him, and still lunges at one past Bite Range; with no chance
# for the lunge, it runs on and bites him instead, then chases on with no attack for the bite's
# Recover Time; and the chance per second comes to the same at any frame rate. The man is the real
# player, standing still or moved at a steady speed. Each demon gets its own DemonStats with the
# values below and its attacks, the lunge, or a bite and then the lunge, so the .tres can be tuned
# without breaking the test; only the last case reads the .tres, to check that its values keep what
# the levels count on.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## The values that go into the game, which only the case of the level's values reads.
const LUST_DEMON_STATS: String = "res://demon/lust_demon_stats.tres"
const PLAYER_MOVEMENT_STATS: String = "res://player/player_movement_stats.tres"
## The values every case's demon gets. Give Up Time is short, so the case does not wait long.
const SIGHT_DISTANCE: float = 480.0
const LOSE_DISTANCE: float = 720.0
const GIVE_UP_TIME: float = 0.5
const CHASE_SPEED: float = 300.0
const LUNGE_RANGE: float = 240.0
const MAX_HEIGHT_DIFFERENCE: float = 24.0
const WARNING_TIME: float = 0.4
const LUNGE_DISTANCE: float = 300.0
## The cases' lunges land on the man however near he is, unless a case says otherwise.
const LUNGE_MIN_DISTANCE: float = 0.0
## The Lead of a lunge that aims where the man will be, as the cases' lunges do, and of one that
## aims where he is.
const FULL_LEAD: float = 1.0
const NO_LEAD: float = 0.0
const LUNGE_HEIGHT: float = 40.0
## About what the world's gravity gives a 40 px lunge, so the other cases keep the timing they were
## written for; the case of the quick lunge uses QUICK_LUNGE_TIME_TO_PEAK.
const LUNGE_TIME_TO_PEAK: float = 0.29
const QUICK_LUNGE_TIME_TO_PEAK: float = 0.15
## The case of a shorter lunge: half Lunge Distance, and a Lunge Range nearer than it, so the demon
## warns with the man nearer than that half and lunges just that far.
const HALF_LUNGE_DISTANCE: float = 150.0
const NEAR_LUNGE_RANGE: float = 100.0
const RECOVER_TIME: float = 0.6
const REPELLED_TIME: float = 0.8
## The bite of a case's demon with a bite, before its lunge: a bite on the run, with a shorter range
## and warning than the lunge, so each case can tell which of the two the demon used. While it
## warns, the demon chases on 60 px at Chase Speed.
const BITE_RANGE: float = 100.0
const BITE_WARNING_TIME: float = 0.2
const BITE_RECOVER_TIME: float = 0.3
## Where the man stands for a bite: inside Bite Range, and so inside Lunge Range too, and near
## enough for the demon to get to him while it warns.
const BITE_X: float = 60.0
## Speeds, in px/s, the man is moved at in the cases of the lunge's aim: away from the demon, slower
## than it chases, so it catches him up and aims where he will be inside Lunge Distance; and at it,
## at his Max Run Speed, so fast that he is behind it before its warning is over, where no lunge,
## however short, could land on him.
const WALK_SPEED: float = 50.0
const COMING_SPEED: float = -720.0
## In the case that works the aim out with no physics: a Lunge Min Distance, and how far ahead of
## the demon the man is, nearer than it and between it and Lunge Distance.
const AIM_MIN_DISTANCE: float = 100.0
const AIM_NEAR: float = 50.0
const AIM_FAR: float = 150.0
## How near, in px, the man coming at the demon gets before that case stops watching: inside it, he
## would be behind the demon a frame later, where it could lunge back at him.
const COMING_STOP: float = 20.0
## The Chance Per Second of a lunge that never comes up; the cases' attacks have 1 otherwise.
const NO_CHANCE: float = 0.0
## A Chance Per Second between never and at once, and the frame rates it is checked at.
const HALF_CHANCE: float = 0.5
const FRAME_RATES: Array[int] = [60, 120]
const CHANCE_TOLERANCE: float = 0.0001
## The demon's own roll: the seed it starts from, the seconds rolled at each frame rate, and how far
## the share of them the attack starts in may be from Chance Per Second, some three times the spread
## of that many seconds.
const ROLL_SEED: int = 67
const ROLLED_SECONDS: int = 1000
const ROLL_TOLERANCE: float = 0.05
## A Lunge Min Distance past Lunge Distance, as a slip in the Inspector could leave it.
const MIN_PAST_LUNGE_DISTANCE: float = 500.0
## A Warning Time of 0, and the one physics frame the demon still warns for then.
const NO_WARNING_TIME: float = 0.0
const ONE_FRAME: int = 1
## How far ahead of the demon a man stands still in the case of a new attack's values: so near that
## a lunge of that distance would not leave the floor.
const RIGHT_AHEAD: float = 1.0
## The Lunge Range of a case that is not about the lunge, so the demon never lunges in it.
const NO_LUNGE: float = 0.0
## The floor's top is at y = 0, from x = FLOOR_LEFT to x = FLOOR_RIGHT; the demon starts at x = 0.
const FLOOR_LEFT: float = -1000.0
const FLOOR_RIGHT: float = 2000.0
## Bodies start just above the floor, as in the player tests.
const SPAWN_Y: float = -2.0
## Where the man stands for the demon to see him: inside Sight Distance.
const SEEN_X: float = 300.0
## Past Sight Distance and inside Lose Distance.
const UNSEEN_X: float = 600.0
## Past Lose Distance.
const LOST_X: float = 1000.0
## The tiles' size, and the height of the step that stops a demon.
const TILE: float = 48.0
## In the case of the edge, the demon's platform ends at x = EDGE_X, and the man's starts GAP px on.
const EDGE_X: float = 100.0
const GAP: float = 200.0
## In the case of the step, the floor rises one tile at x = STEP_X.
const STEP_X: float = 150.0
## The wall that hides the man: its left face, its thickness and its top.
const WALL_X: float = 150.0
const WALL_THICKNESS: float = 50.0
const WALL_TOP: float = -400.0
## The gap under the wall in the case of giving up, so the floor runs on below it and only the sight
## keeps the demon from lunging.
const WALL_GAP: float = 10.0
## In the case of the hole, the gap between the two platforms: two tiles.
const HOLE_WIDTH: float = 96.0
## In the case of the floor that ends past Lunge Distance, a long lunge at the least Lunge Time To
## Peak the Inspector allows, so the floor stops the demon up to half a frame's move (32 px) further
## on, and a Lunge Range over SEEN_X, so it warns where it stands. Its floor ends FLOOR_PAST_LUNGE
## px past Lunge Distance: short of where the lunge lands, by more than half the demon's width.
const LONG_LUNGE_DISTANCE: float = 420.0
const SHORTEST_LUNGE_TIME_TO_PEAK: float = 0.05
const WIDE_LUNGE_RANGE: float = 400.0
const FLOOR_PAST_LUNGE: float = 4.0
## How far behind the demon the man goes while it warns, in the case of the lunge's direction.
const BEHIND: float = 150.0
## How high above the man's floor the demon is put, in the case of warning only on the floor.
const FALL_HEIGHT: float = 200.0
## How far from the man it is put there: past Lunge Range by about what it goes towards him in the
## air, some 190 px in its fall, so it comes inside Lunge Range in the air and lands short of him.
const DROP_GAP: float = 340.0
## In the crucifix cases the man stands at x = 0, and a demon at REPEL_START_X is inside the
## crucifix's radius.
const REPEL_START_X: float = 100.0
## In the case of the demon that never saw the man, the wall that hides him starts at x =
## HIDING_REPEL_WALL_X, between him and the demon, inside the crucifix's radius.
const HIDING_REPEL_WALL_X: float = 40.0
## In the case of the ledge, the man's floor ends at x = LEDGE_X, inside the crucifix's radius, and
## the floor below is LEDGE_DROP px lower.
const LEDGE_X: float = 150.0
const LEDGE_DROP: float = 200.0
## In the case of the pause, the game pauses PUSHED_BEFORE_PAUSE frames after the last push, well
## inside Repelled Time, and stays paused for PAUSE_FRAMES.
const PUSHED_BEFORE_PAUSE: int = 10
const PAUSE_FRAMES: int = 200
## The name of the man's crucifix node in his scene.
const CRUCIFIX_NODE: NodePath = ^"Crucifix"
## How far, in px, the lunge's peak may be from Lunge Height.
const HEIGHT_TOLERANCE: float = 1.0
## Frames to watch a demon that must stay put or must not get past something: two seconds.
const FRAMES_TO_WATCH: int = 120
## Frames for something the demon reacts to on the next frame to have surely happened.
const SETTLE_FRAMES: int = 3
## The smallest move, in px, that counts as the demon going towards the man.
const MOVED: float = 20.0
## How far, in px, a demon may be from where it must be: it may settle on the floor or stop up to a
## frame's move short of an edge.
const TOLERANCE: float = 6.0
## How far, in px, a demon standing on the man's spot may stray from him.
const STILL_TOLERANCE: float = 1.0
## How far from the demon the man starts in that case, in px: less than its move in a frame (5 px).
const STILL_OFFSET: float = 2.0
## In the case of hiding twice, the man goes between SEEN_X and HIDDEN_X, behind a wall at
## HIDING_WALL_X, so the demon cannot reach the wall while the case lasts.
const HIDING_WALL_X: float = 400.0
const HIDDEN_X: float = 500.0
## The Sight Distance the case that tunes it while the game runs changes to.
const TUNED_SIGHT_DISTANCE: float = 700.0
## The names the project gives the physics layers.
const WORLD_LAYER_NAME: String = "world"
const ONE_WAY_LAYER_NAME: String = "one_way_platform"
const ENEMY_LAYER_NAME: String = "enemy"
const PLAYER_LAYER_NAME: String = "player"
## The number of named 2D physics layers the project settings can hold.
const PHYSICS_LAYERS: int = 32


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _sees_and_chases_the_man())
	results.append(await _stands_still_on_the_man_s_spot())
	results.append(await _does_not_see_past_sight_distance())
	results.append(await _does_not_see_through_a_wall())
	results.append(await _stops_at_an_edge())
	results.append(await _does_not_climb_nor_lunge_up_a_step_of_one_tile())
	results.append(await _keeps_chasing_past_sight_distance_and_loses_him_past_lose_distance())
	results.append(await _gives_up_when_a_wall_hides_the_man())
	results.append(await _seeing_the_man_again_starts_give_up_time_over())
	results.append(await _lets_go_of_a_man_who_is_freed())
	results.append(await _warns_inside_lunge_range_then_lunges())
	results.append(await _lunge_rises_lunge_height_and_lands_lunge_distance_away())
	results.append(await _a_quick_lunge_keeps_its_height_and_distance_in_less_time())
	results.append(await _a_shorter_lunge_is_lower_and_quicker_at_the_same_angle())
	results.append(await _stays_put_for_recover_time_after_landing())
	results.append(await _warns_for_warning_time_again_after_a_lunge())
	results.append(await _lunge_keeps_the_direction_of_the_warning())
	results.append(await _does_not_lunge_across_a_hole())
	results.append(await _does_not_lunge_when_it_could_land_past_the_end_of_its_floor())
	results.append(await _lunges_onto_a_man_standing_still())
	results.append(await _lunges_where_a_walking_man_will_be())
	results.append(await _does_not_lunge_at_a_man_who_will_be_behind_it())
	results.append(_the_lunge_aims_where_the_man_will_be_within_its_distances())
	results.append(_the_aim_finds_no_lunge_at_a_man_coming_too_fast_for_any())
	results.append(_the_lunge_never_goes_past_lunge_distance_whatever_its_min_distance())
	results.append(_with_no_warning_time_the_aim_counts_the_one_frame_it_warns())
	results.append(_a_new_attack_s_lunge_always_leaves_the_floor())
	results.append(await _bites_a_man_right_by_it_on_the_run_rather_than_lunging())
	results.append(await _the_first_attack_in_the_list_wins_over_one_with_a_shorter_range())
	results.append(await _lunges_at_a_man_past_bite_range())
	results.append(await _with_no_chance_it_never_lunges_and_bites_instead())
	results.append(await _chases_on_after_a_bite_and_bites_again_after_recover_time())
	results.append(_the_chance_per_second_comes_to_the_same_at_any_frame_rate())
	results.append(_the_demon_s_roll_comes_up_in_chance_per_second_of_the_seconds())
	results.append(await _warns_only_once_it_has_landed())
	results.append(await _the_raised_crucifix_pushes_it_out_and_it_stays_still_for_repelled_time())
	results.append(await _the_raised_crucifix_pushes_it_off_the_man_s_spot())
	results.append(await _a_pause_while_it_is_repelled_does_not_count())
	results.append(await _a_lunge_into_the_raised_crucifix_ends_repelled())
	results.append(await _repelled_in_a_quick_lunge_it_goes_no_higher_than_lunge_height())
	results.append(await _repelled_before_it_saw_the_man_it_goes_back_to_standing())
	results.append(await _the_raised_crucifix_pushes_it_off_a_ledge_onto_the_floor_below())
	results.append(await _sight_follows_sight_distance_while_the_game_runs())
	results.append(_is_on_the_enemy_layer_and_looks_only_for_the_player())
	results.append(_the_level_s_values_keep_what_the_levels_count_on())
	finish(results)


## The man inside Sight Distance on the same floor: the demon chases him and comes nearer.
func _sees_and_chases_the_man() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var start_x: float = demon.position.x
	var came_nearer: bool = await wait_until(
			func() -> bool: return demon.position.x > start_x + MOVED)
	var state: Demon.State = demon.get_state()
	var moved: float = demon.position.x - start_x
	await _clear([ground, man, demon])
	return report(came_nearer and state == Demon.State.CHASE,
			"Seen at %d px: %s, %.1f px nearer" % [SEEN_X, _name_of(state), moved])


## The man less than a frame's move from the demon: the demon steps onto his spot and stands still
## there, instead of going past him and back every frame.
func _stands_still_on_the_man_s_spot() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(STILL_OFFSET, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	await wait_frames(SETTLE_FRAMES)
	var farthest: float = 0.0
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		farthest = maxf(farthest, absf(demon.position.x - man.position.x))
	await _clear([ground, man, demon])
	return report(chased and farthest < STILL_TOLERANCE,
			"On the man's spot: chased %s, at most %.2f px from him" % [chased, farthest])


## The man past Sight Distance: the demon does not see him and stays put.
func _does_not_see_past_sight_distance() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(UNSEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var start_x: float = demon.position.x
	var ever_chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	var moved: float = absf(demon.position.x - start_x)
	await _clear([ground, man, demon])
	return report(not ever_chased and moved < TOLERANCE,
			"At %d px, past Sight Distance: chased %s, moved %.1f px" % [UNSEEN_X, ever_chased, moved])


## The man inside Sight Distance behind a wall: the demon does not see him and stays put.
func _does_not_see_through_a_wall() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(WALL_X, WALL_X + WALL_THICKNESS, WALL_TOP)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var start_x: float = demon.position.x
	var ever_chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	var moved: float = absf(demon.position.x - start_x)
	await _clear([ground, wall, man, demon])
	return report(not ever_chased and moved < TOLERANCE,
			"Behind a wall at %d px: chased %s, moved %.1f px" % [SEEN_X, ever_chased, moved])


## The man on another platform across a gap: the demon chases him up to its edge and stays on its
## floor, still chasing.
func _stops_at_an_edge() -> bool:
	var near_side: StaticBody2D = make_platform(FLOOR_LEFT, EDGE_X)
	var far_side: StaticBody2D = make_platform(EDGE_X + GAP, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(EDGE_X + GAP + 2.0 * TILE, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	await wait_frames(FRAMES_TO_WATCH)
	var front: float = demon.position.x + _half_width(demon)
	var feet: float = demon.position.y
	var state: Demon.State = demon.get_state()
	await _clear([near_side, far_side, man, demon])
	var at_the_edge: bool = front <= EDGE_X and front > EDGE_X - TOLERANCE
	return report(at_the_edge and absf(feet) < TOLERANCE and state == Demon.State.CHASE,
			"Edge at x = %d: front at %.1f, feet at y = %.1f, %s"
			% [EDGE_X, front, feet, _name_of(state)])


## The man on a step one tile high, inside Lunge Range once the demon gets there: the demon chases
## him up to the step and stays below it, and never warns, since he is above its floor.
func _does_not_climb_nor_lunge_up_a_step_of_one_tile() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(STEP_X, FLOOR_RIGHT, -TILE)
	var man: Player = await spawn_on_floor(Vector2(STEP_X + 4.0 * TILE, SPAWN_Y - TILE))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	await wait_frames(FRAMES_TO_WATCH)
	var front: float = demon.position.x + _half_width(demon)
	var feet: float = demon.position.y
	var state: Demon.State = demon.get_state()
	var gap: float = man.position.x - demon.position.x
	await _clear([ground, step, man, demon])
	var at_the_step: bool = front <= STEP_X + TOLERANCE and front > STEP_X - TOLERANCE
	return report(at_the_step and absf(feet) < TOLERANCE and state == Demon.State.CHASE
			and gap < LUNGE_RANGE and not _warned(changes),
			"Step at x = %d: front at %.1f, feet at y = %.1f, %s, %.1f px from the man, warned %s"
			% [STEP_X, front, feet, _name_of(state), gap, _warned(changes)])


## Once chasing, the demon keeps on with the man past Sight Distance, and stops past Lose Distance.
func _keeps_chasing_past_sight_distance_and_loses_him_past_lose_distance() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	man.position.x = demon.position.x + UNSEEN_X
	await wait_frames(SETTLE_FRAMES)
	var past_sight: Demon.State = demon.get_state()
	man.position.x = demon.position.x + LOST_X
	var lost: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.IDLE, SETTLE_FRAMES)
	var chased_again: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, man, demon])
	return report(chased and past_sight == Demon.State.CHASE and lost and not chased_again,
			"Chasing, then %d px away: %s; %d px away: lost him %s, chased again %s"
			% [UNSEEN_X, _name_of(past_sight), LOST_X, lost, chased_again])


## Once chasing, a wall between them: the demon still chases halfway through Give Up Time, and has
## given up by its end.
func _gives_up_when_a_wall_hides_the_man() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var wall: StaticBody2D = make_wall(SEEN_X - 2.0 * TILE, SEEN_X - TILE, WALL_TOP, -WALL_GAP)
	var give_up_frames: int = demon.stats.get_give_up_frames()
	await wait_frames(give_up_frames / 2)
	var halfway: Demon.State = demon.get_state()
	var gave_up: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.IDLE,
			give_up_frames / 2 + SETTLE_FRAMES)
	await _clear([ground, wall, man, demon])
	return report(chased and halfway == Demon.State.CHASE and gave_up,
			"Hidden by a wall: halfway through %d frames %s, gave up by the end %s"
			% [give_up_frames, _name_of(halfway), gave_up])


## Once chasing, the man hides behind a wall for two thirds of Give Up Time, shows himself, and
## hides as long again: the demon still chases, since seeing him again started the count over.
func _seeing_the_man_again_starts_give_up_time_over() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_WALL_X, HIDING_WALL_X + WALL_THICKNESS, WALL_TOP)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var hidden_frames: int = demon.stats.get_give_up_frames() * 2 / 3
	man.position.x = HIDDEN_X
	await wait_frames(hidden_frames)
	man.position.x = SEEN_X
	await wait_frames(SETTLE_FRAMES)
	man.position.x = HIDDEN_X
	await wait_frames(hidden_frames)
	var state: Demon.State = demon.get_state()
	await _clear([ground, wall, man, demon])
	return report(chased and state == Demon.State.CHASE,
			"Hidden %d frames twice, seen in between: %s" % [hidden_frames, _name_of(state)])


## Once chasing, the man is freed, as on a respawn: the demon stops chasing.
func _lets_go_of_a_man_who_is_freed() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	await remove_player(man)
	await wait_frames(SETTLE_FRAMES)
	var state: Demon.State = demon.get_state()
	await _clear([ground, demon])
	return report(chased and state == Demon.State.IDLE,
			"Chasing, then the man is freed: %s" % _name_of(state))


## The man on the same floor: once he is inside Lunge Range, the demon stops and warns, crouched and
## recoloured, for Warning Time, and then lunges, back in its own shape and colour.
func _warns_inside_lunge_range_then_lunges() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var rest_color: Color = placeholder.color
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var gap: float = man.position.x - demon.position.x
	var crouched: bool = placeholder.scale.y < 1.0 and placeholder.color != rest_color
	var warning_x: float = demon.position.x
	var drift: float = 0.0
	for _frame: int in FRAMES_TO_WATCH:
		if demon.get_state() != Demon.State.WARNING:
			break
		drift = maxf(drift, absf(demon.position.x - warning_x))
		await physics_frame
	var restored: bool = placeholder.scale == Vector2.ONE and placeholder.color == rest_color
	var warning_frames: int = _lunge_of(demon).get_warning_frames()
	await _clear([ground, man, demon])
	var in_order: bool = changes.size() >= 3 and changes[0].x == Demon.State.CHASE \
			and changes[1].x == Demon.State.WARNING and changes[2].x == Demon.State.LUNGE
	var warned_for: int = changes[2].y - changes[1].y if in_order else NEVER_REACHED
	var in_range: bool = gap < LUNGE_RANGE and gap > LUNGE_RANGE - TOLERANCE
	return report(warned and in_range and in_order and warned_for == warning_frames
			and drift < STILL_TOLERANCE and crouched and restored,
			"Warned %.1f px from the man, %s, for %d frames of %d, moved %.2f px; crouched %s, restored %s"
			% [gap, _names_of(changes), warned_for, warning_frames, drift, crouched, restored])


## On flat floor, a lunge with Lunge Min Distance at Lunge Distance peaks Lunge Height above where
## the demon took off, and lands Lunge Distance away, give or take a frame's move, past the man.
func _lunge_rises_lunge_height_and_lands_lunge_distance_away() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	_lunge_of(demon).lunge_min_distance = LUNGE_DISTANCE
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var take_off: Vector2 = demon.position
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, FRAMES_TO_WATCH)
	var peak_y: float = demon.position.y
	for _frame: int in FRAMES_TO_WATCH:
		if demon.is_on_floor():
			break
		peak_y = minf(peak_y, demon.position.y)
		await physics_frame
	var landed: bool = demon.is_on_floor()
	var height: float = take_off.y - peak_y
	var distance: float = demon.position.x - take_off.x
	var frame_move: float = _lunge_of(demon).get_lunge_velocity(LUNGE_DISTANCE).x \
			/ Engine.physics_ticks_per_second
	await _clear([ground, man, demon])
	return report(warned and lunged and landed and absf(height - LUNGE_HEIGHT) <= HEIGHT_TOLERANCE
			and absf(distance - LUNGE_DISTANCE) <= frame_move,
			"Lunge of %d px up and %d across: %.2f px up, landed %s %.1f px away (a frame moves %.1f)"
			% [LUNGE_HEIGHT, LUNGE_DISTANCE, height, landed, distance, frame_move])


## A quick lunge, with Lunge Time To Peak about half the usual and Lunge Min Distance at Lunge
## Distance: it still peaks at Lunge Height and lands within half a frame's move of Lunge Distance,
## and it is in the air for twice Lunge Time To Peak, give or take a frame. The lunge has its own
## gravity, so its height and its speed are tuned apart.
func _a_quick_lunge_keeps_its_height_and_distance_in_less_time() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	_lunge_of(demon).lunge_time_to_peak = QUICK_LUNGE_TIME_TO_PEAK
	_lunge_of(demon).lunge_min_distance = LUNGE_DISTANCE
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var take_off: Vector2 = demon.position
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, FRAMES_TO_WATCH)
	var peak_y: float = demon.position.y
	for _frame: int in FRAMES_TO_WATCH:
		if demon.is_on_floor():
			break
		peak_y = minf(peak_y, demon.position.y)
		await physics_frame
	var landed_frame: int = Engine.get_physics_frames()
	var landed: bool = demon.is_on_floor()
	var height: float = take_off.y - peak_y
	var distance: float = demon.position.x - take_off.x
	await _clear([ground, man, demon])
	var lunge: int = _index_after(changes, Demon.State.WARNING)
	var in_air: int = landed_frame - changes[lunge].y if lunge != NEVER_REACHED else NEVER_REACHED
	var expected_in_air: int = roundi(2.0 * QUICK_LUNGE_TIME_TO_PEAK
			* Engine.physics_ticks_per_second)
	var frame_move: float = LUNGE_DISTANCE / expected_in_air
	return report(warned and lunged and landed and absf(height - LUNGE_HEIGHT) <= HEIGHT_TOLERANCE
			and absf(distance - LUNGE_DISTANCE) <= frame_move / 2.0
			and absi(in_air - expected_in_air) <= 1,
			"Quick lunge, %.2f s to its peak: %.2f px up (of %d), landed %s %.1f px away (of %d, give or take half of %.1f), %d frames in the air (of %d)"
			% [QUICK_LUNGE_TIME_TO_PEAK, height, LUNGE_HEIGHT, landed, distance, LUNGE_DISTANCE,
					frame_move, in_air, expected_in_air])


## A lunge of half Lunge Distance, at a man standing still nearer than that, with Lunge Min Distance
## at that half: it peaks at half Lunge Height and is in the air for twice Lunge Time To Peak times
## the square root of a half, give or take a frame, and lands within half a frame's move of that
## half. With the same gravity and angle as a lunge of Lunge Distance, it is lower and quicker, so a
## short lunge is no slow hop.
func _a_shorter_lunge_is_lower_and_quicker_at_the_same_angle() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NEAR_LUNGE_RANGE, changes)
	_lunge_of(demon).lunge_min_distance = HALF_LUNGE_DISTANCE
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var take_off: Vector2 = demon.position
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, FRAMES_TO_WATCH)
	var peak_y: float = demon.position.y
	for _frame: int in FRAMES_TO_WATCH:
		if demon.is_on_floor():
			break
		peak_y = minf(peak_y, demon.position.y)
		await physics_frame
	var landed_frame: int = Engine.get_physics_frames()
	var landed: bool = demon.is_on_floor()
	var height: float = take_off.y - peak_y
	var distance: float = demon.position.x - take_off.x
	await _clear([ground, man, demon])
	var share: float = HALF_LUNGE_DISTANCE / LUNGE_DISTANCE
	var expected_height: float = LUNGE_HEIGHT * share
	var lunge: int = _index_after(changes, Demon.State.WARNING)
	var in_air: int = landed_frame - changes[lunge].y if lunge != NEVER_REACHED else NEVER_REACHED
	var expected_in_air: int = roundi(2.0 * LUNGE_TIME_TO_PEAK * sqrt(share)
			* Engine.physics_ticks_per_second)
	var frame_move: float = HALF_LUNGE_DISTANCE / expected_in_air
	return report(warned and lunged and landed
			and absf(height - expected_height) <= HEIGHT_TOLERANCE
			and absf(distance - HALF_LUNGE_DISTANCE) <= frame_move / 2.0
			and absi(in_air - expected_in_air) <= 1,
			"Lunge of half its distance: %.2f px up (of %.0f), landed %s %.1f px away (of %d, give or take half of %.1f), %d frames in the air (of %d)"
			% [height, expected_height, landed, distance, HALF_LUNGE_DISTANCE, frame_move, in_air,
					expected_in_air])


## After landing a lunge, the demon stays where it landed for Recover Time, and then chases again.
## The man goes further on as it takes off, past Lunge Range from where it lands, so it chases him
## instead of warning again.
func _stays_put_for_recover_time_after_landing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, MAX_FRAMES)
	man.position.x = demon.position.x + LUNGE_DISTANCE + SEEN_X
	var landed: bool = await wait_until(demon.is_on_floor)
	var landing_x: float = demon.position.x
	var still_frames: int = 0
	var drift: float = 0.0
	while demon.get_state() == Demon.State.LUNGE and still_frames <= FRAMES_TO_WATCH:
		await physics_frame
		still_frames += 1
		drift = maxf(drift, absf(demon.position.x - landing_x))
	var state: Demon.State = demon.get_state()
	var came_nearer: bool = await wait_until(
			func() -> bool: return demon.position.x > landing_x + MOVED, FRAMES_TO_WATCH)
	var recover_frames: int = _lunge_of(demon).get_recover_frames()
	await _clear([ground, man, demon])
	return report(lunged and landed and still_frames == recover_frames and drift < STILL_TOLERANCE
			and state == Demon.State.CHASE and came_nearer,
			"Landed, then still for %d frames of %d, moved %.2f px; then %s, came nearer %s"
			% [still_frames, recover_frames, drift, _name_of(state), came_nearer])


## A man standing still, and a lunge with Lunge Min Distance at Lunge Distance: the demon lunges
## past him, stays put for Recover Time, turns, and warns again for Warning Time before it lunges
## back at him.
func _warns_for_warning_time_again_after_a_lunge() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	_lunge_of(demon).lunge_min_distance = LUNGE_DISTANCE
	await wait_until(func() -> bool: return changes.size() >= 4)
	var first_landing_x: float = demon.position.x
	var lunged_back: bool = await wait_until(
			func() -> bool: return changes.size() >= 6, FRAMES_TO_WATCH)
	await wait_until(demon.is_on_floor)
	var travelled_back: float = demon.position.x - first_landing_x
	var warning_frames: int = _lunge_of(demon).get_warning_frames()
	await _clear([ground, man, demon])
	var warned_for: int = changes[5].y - changes[4].y if lunged_back else NEVER_REACHED
	var in_order: bool = lunged_back and changes[3].x == Demon.State.CHASE \
			and changes[4].x == Demon.State.WARNING and changes[5].x == Demon.State.LUNGE
	return report(in_order and warned_for == warning_frames
			and travelled_back < -LUNGE_DISTANCE / 2.0,
			"%s; second warning for %d frames of %d; lunged back %.1f px"
			% [_names_of(changes), warned_for, warning_frames, travelled_back])


## The man to the left; while the demon warns, he goes behind it: it lunges the way it warned, left,
## away from him, so jumping over a warning demon is a way out.
func _lunge_keeps_the_direction_of_the_warning() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(-SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var warning_x: float = demon.position.x
	man.position.x = warning_x + BEHIND
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, FRAMES_TO_WATCH)
	var landed: bool = await wait_until(demon.is_on_floor)
	var travelled: float = demon.position.x - warning_x
	await _clear([ground, man, demon])
	return report(warned and lunged and landed and travelled < -LUNGE_DISTANCE / 2.0,
			"Warned left at the man, who then went %d px behind: lunged %.1f px"
			% [BEHIND, travelled])


## The man to the left, across a hole two tiles wide, inside Lunge Range from the edge, with floor
## on the right: the demon chases him up to its edge and never warns, since a lunge towards him
## would not have floor all along.
func _does_not_lunge_across_a_hole() -> bool:
	var near_side: StaticBody2D = make_platform(-EDGE_X, FLOOR_RIGHT)
	var far_side: StaticBody2D = make_platform(FLOOR_LEFT, -EDGE_X - HOLE_WIDTH)
	var man: Player = await spawn_on_floor(Vector2(-EDGE_X - HOLE_WIDTH - TILE, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	await wait_frames(FRAMES_TO_WATCH)
	var front: float = demon.position.x - _half_width(demon)
	var state: Demon.State = demon.get_state()
	var gap: float = demon.position.x - man.position.x
	await _clear([near_side, far_side, man, demon])
	var at_the_edge: bool = front >= -EDGE_X and front < -EDGE_X + TOLERANCE
	return report(at_the_edge and state == Demon.State.CHASE and gap < LUNGE_RANGE
			and not _warned(changes),
			"Hole of %d px on the left: front at %.1f, %s, %.1f px from the man, warned %s"
			% [HOLE_WIDTH, front, _name_of(state), gap, _warned(changes)])


## The man inside Lunge Range, a lunge with Lunge Min Distance at Lunge Distance, and the demon's
## floor ends just past Lunge Distance, short of where a quick lunge would land: the demon never
## warns, and stays on its floor, since the floor stops a lunge up to half a frame's move past Lunge
## Distance. The demon settles at x = 0 before the man comes, so it would take off from there.
func _does_not_lunge_when_it_could_land_past_the_end_of_its_floor() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, LONG_LUNGE_DISTANCE + FLOOR_PAST_LUNGE)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, WIDE_LUNGE_RANGE, changes)
	_lunge_of(demon).lunge_distance = LONG_LUNGE_DISTANCE
	_lunge_of(demon).lunge_min_distance = LONG_LUNGE_DISTANCE
	_lunge_of(demon).lunge_time_to_peak = SHORTEST_LUNGE_TIME_TO_PEAK
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	await wait_frames(FRAMES_TO_WATCH)
	var on_its_floor: bool = demon.is_on_floor() and absf(demon.position.y) < TOLERANCE
	var at: Vector2 = demon.position
	await _clear([ground, man, demon])
	return report(on_its_floor and not _warned(changes),
			"Floor ends %d px past a lunge of %d px in %.2f s: warned %s, on its floor %s at (%.1f, %.1f)"
			% [FLOOR_PAST_LUNGE, LONG_LUNGE_DISTANCE, SHORTEST_LUNGE_TIME_TO_PEAK, _warned(changes),
					on_its_floor, at.x, at.y])


## A man standing still inside Lunge Range: the lunge lands on his spot, give or take a frame's
## move, instead of Lunge Distance away.
func _lunges_onto_a_man_standing_still() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, MAX_FRAMES)
	var landed: bool = await wait_until(demon.is_on_floor)
	var off: float = demon.position.x - man.position.x
	var frame_move: float = _lunge_of(demon).get_lunge_velocity(LUNGE_DISTANCE).x \
			/ Engine.physics_ticks_per_second
	await _clear([ground, man, demon])
	return report(lunged and landed and absf(off) <= frame_move,
			"Man standing still: landed %.1f px from him (Lunge Distance %d, a frame moves %.1f at the most)"
			% [off, LUNGE_DISTANCE, frame_move])


## A man walking away at a steady speed, slower than the demon chases: it catches him up and, with
## Lead 1, lands where he is when it lands, give or take a frame's move, not where he was when it
## warned.
func _lunges_where_a_walking_man_will_be() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var walk: Callable = _walk(man, WALK_SPEED)
	var demon: Demon = await _spawn_demon(0.0)
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var warned_x: float = man.position.x
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, FRAMES_TO_WATCH)
	var landed: bool = await wait_until(demon.is_on_floor)
	var off: float = demon.position.x - man.position.x
	var walked: float = man.position.x - warned_x
	physics_frame.disconnect(walk)
	var frame_move: float = _lunge_of(demon).get_lunge_velocity(LUNGE_DISTANCE).x \
			/ Engine.physics_ticks_per_second
	await _clear([ground, man, demon])
	return report(warned and lunged and landed and absf(off) <= frame_move and walked > frame_move,
			"Man walking away at %d px/s: walked %.1f px from the warning to the landing, landed %.1f px from him (a frame moves %.1f at the most)"
			% [WALK_SPEED, walked, off, frame_move])


## A man coming at the demon so fast that he is behind it before its warning is over: no lunge could
## land on him, so it never warns, however near he gets, and keeps on chasing him.
func _does_not_lunge_at_a_man_who_will_be_behind_it() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	var walk: Callable = _walk(man, COMING_SPEED)
	var came: bool = await wait_until(
			func() -> bool: return man.position.x - demon.position.x < COMING_STOP, FRAMES_TO_WATCH)
	var gap: float = man.position.x - demon.position.x
	var state: Demon.State = demon.get_state()
	physics_frame.disconnect(walk)
	await _clear([ground, man, demon])
	return report(came and state == Demon.State.CHASE and not _warned(changes),
			"Man coming at %d px/s: came to %.1f px from it, %s, warned %s"
			% [-COMING_SPEED, gap, _name_of(state), _warned(changes)])


## The lunge's aim, worked out with no physics: with Lead 1, where the man will be after the warning
## and the time in the air of the lunge it finds; with Lead 0, where he is; never further than Lunge
## Distance nor nearer than Lunge Min Distance; and nowhere when he will be behind the demon.
func _the_lunge_aims_where_the_man_will_be_within_its_distances() -> bool:
	var attack: DemonAttack = DemonAttack.new()
	attack.warning_time = WARNING_TIME
	attack.lunge_distance = LUNGE_DISTANCE
	attack.lunge_min_distance = AIM_MIN_DISTANCE
	attack.lunge_time_to_peak = LUNGE_TIME_TO_PEAK
	attack.lead = FULL_LEAD
	var walking: float = attack.get_lunge_distance_to(AIM_FAR, WALK_SPEED)
	var time: float = attack.get_time_to_landing(walking)
	var far_off: float = attack.get_lunge_distance_to(LUNGE_DISTANCE, WALK_SPEED)
	var near: float = attack.get_lunge_distance_to(AIM_NEAR, 0.0)
	var coming: float = attack.get_lunge_distance_to(AIM_FAR, COMING_SPEED)
	attack.lead = NO_LEAD
	var no_lead: float = attack.get_lunge_distance_to(AIM_FAR, WALK_SPEED)
	return report(is_equal_approx(walking, AIM_FAR + WALK_SPEED * time)
			and is_equal_approx(no_lead, AIM_FAR) and is_equal_approx(far_off, LUNGE_DISTANCE)
			and is_equal_approx(near, AIM_MIN_DISTANCE) and coming == 0.0,
			"Aim at a man %d px ahead going away at %d px/s, %.3f s to landing: Lead 1 %.1f px, Lead 0 %.1f; %d px ahead, %.1f (Lunge Distance %d); %d px ahead and still, %.1f (Lunge Min Distance %d); coming at %d px/s, %.1f"
			% [AIM_FAR, WALK_SPEED, time, walking, no_lead, LUNGE_DISTANCE, far_off,
					LUNGE_DISTANCE, AIM_NEAR, near, AIM_MIN_DISTANCE, -COMING_SPEED, coming])


## A man so near and coming so fast that every lunge, however short, would land behind him: the
## aim's equation has no root at all, and the demon does not lunge.
func _the_aim_finds_no_lunge_at_a_man_coming_too_fast_for_any() -> bool:
	var attack: DemonAttack = DemonAttack.new()
	attack.warning_time = WARNING_TIME
	attack.lunge_distance = LUNGE_DISTANCE
	attack.lunge_min_distance = LUNGE_MIN_DISTANCE
	attack.lunge_time_to_peak = LUNGE_TIME_TO_PEAK
	attack.lead = FULL_LEAD
	var distance: float = attack.get_lunge_distance_to(AIM_NEAR, COMING_SPEED)
	return report(distance == 0.0,
			"Aim at a man %d px ahead coming at %d px/s: lunge of %.1f px"
			% [AIM_NEAR, -COMING_SPEED, distance])


## A Lunge Min Distance past Lunge Distance, as a slip in the Inspector could leave: the lunge still
## goes no further than Lunge Distance nor higher than Lunge Height, so a step still stops it.
func _the_lunge_never_goes_past_lunge_distance_whatever_its_min_distance() -> bool:
	var attack: DemonAttack = DemonAttack.new()
	attack.warning_time = WARNING_TIME
	attack.lunge_distance = LUNGE_DISTANCE
	attack.lunge_min_distance = MIN_PAST_LUNGE_DISTANCE
	attack.lunge_height = LUNGE_HEIGHT
	attack.lunge_time_to_peak = LUNGE_TIME_TO_PEAK
	var distance: float = attack.get_lunge_distance_to(AIM_NEAR, 0.0)
	var height: float = attack.get_lunge_height(distance)
	return report(is_equal_approx(distance, LUNGE_DISTANCE) and height <= LUNGE_HEIGHT,
			"Lunge Min Distance %d past Lunge Distance %d, the man %d px ahead and still: lunge of %.1f px, %.1f px up (Lunge Height %d)"
			% [MIN_PAST_LUNGE_DISTANCE, LUNGE_DISTANCE, AIM_NEAR, distance, height, LUNGE_HEIGHT])


## With Warning Time at 0, the demon still warns for one physics frame, and the aim counts that
## frame, so a lunge at a man who moves does not land a frame's going short of where it aimed.
func _with_no_warning_time_the_aim_counts_the_one_frame_it_warns() -> bool:
	var attack: DemonAttack = DemonAttack.new()
	attack.warning_time = NO_WARNING_TIME
	var frame_time: float = 1.0 / Engine.physics_ticks_per_second
	var counted: float = attack.get_time_to_landing(0.0) - attack.get_lunge_time(0.0)
	return report(attack.get_warning_frames() == ONE_FRAME and is_equal_approx(counted, frame_time),
			"Warning Time 0: warns for %d frames, and the aim counts %.4f s of warning (a frame is %.4f s)"
			% [attack.get_warning_frames(), counted, frame_time])


## A new attack, with the values it comes with, at a man standing right ahead of the demon: its
## lunge leaves the floor, and is never a little hop that rises nothing and then keeps the demon
## still for its Recover Time, over and over.
func _a_new_attack_s_lunge_always_leaves_the_floor() -> bool:
	var attack: DemonAttack = DemonAttack.new()
	var distance: float = attack.get_lunge_distance_to(RIGHT_AHEAD, 0.0)
	var velocity: Vector2 = attack.get_lunge_velocity(distance)
	return report(distance > 0.0 and velocity.y < 0.0,
			"New attack, the man %d px ahead and still: lunge of %.1f px, %.2f px up, taking off at %.1f px/s up"
			% [RIGHT_AHEAD, distance, attack.get_lunge_height(distance), -velocity.y])


## A demon with a bite before its lunge, and the man right by it, inside both ranges: the first in
## the list wins, so it warns of the bite, wider and lower than for a lunge, for the bite's Warning
## Time, chasing on all the while, and bites on his spot. Watched for two seconds, it only bites,
## never leaves the floor and never goes past him, so it no longer goes back and forth over him.
func _bites_a_man_right_by_it_on_the_run_rather_than_lunging() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var look: Vector2 = placeholder.scale
	var floor_y: float = demon.position.y
	var highest_y: float = floor_y
	var farthest_x: float = demon.position.x
	var bit_at: float = NAN
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		highest_y = minf(highest_y, demon.position.y)
		farthest_x = maxf(farthest_x, demon.position.x)
		if is_nan(bit_at) and demon.get_state() != Demon.State.WARNING:
			bit_at = demon.position.x
	var man_x: float = man.position.x
	var bite: DemonAttack = _bite_of(demon)
	await _clear([ground, man, demon])
	var index: int = _index_after(changes, Demon.State.WARNING)
	var chased_on: bool = index != NEVER_REACHED and changes[index].x == Demon.State.CHASE
	var warned_for: int = changes[index].y - changes[index - 1].y if chased_on else NEVER_REACHED
	var lunged: bool = changes.any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.LUNGE)
	var only_bites: bool = warned_of.all(func(attack: DemonAttack) -> bool: return attack == bite)
	var wider_and_lower: bool = look.x > 1.0 and look.y < 1.0
	return report(warned and chased_on and not lunged and only_bites
			and warned_for == bite.get_warning_frames() and wider_and_lower
			and absf(man_x - bit_at) <= STILL_TOLERANCE and floor_y - highest_y <= HEIGHT_TOLERANCE
			and farthest_x <= man_x + STILL_TOLERANCE,
			"Man %d px away, inside both ranges: warned of %s in %d frames, the first for %d frames of %d, %.2f wide and %.2f high, then %s; bit %.1f px from him, at most %.2f px off the floor, at most %.1f px past him"
			% [BITE_X, _animations_of(warned_of), FRAMES_TO_WATCH, warned_for,
					bite.get_warning_frames(), look.x, look.y,
					_name_of(changes[index].x as Demon.State) if chased_on else "nothing",
					man_x - bit_at, floor_y - highest_y, farthest_x - man_x])


## The man and the demon of the case above, but with the demon's lunge before its bite in the list:
## the first in the list wins although the bite's range is the shorter, so the order of the list is
## the priority, and not the ranges.
func _the_first_attack_in_the_list_wins_over_one_with_a_shorter_range() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	var lunge: DemonAttack = _lunge_of(demon)
	demon.stats.attacks.reverse()
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var gap: float = man.position.x - demon.position.x
	await _clear([ground, man, demon])
	return report(warned and not warned_of.is_empty() and warned_of[0] == lunge,
			"Lunge first in the list, then the bite; the man %.1f px away, inside both ranges (Bite Range %d, Lunge Range %d): first warned of %s"
			% [gap, BITE_RANGE, LUNGE_RANGE, _animations_of(warned_of)])


## A demon with a bite before its lunge, and the man past Bite Range but inside Lunge Range: it
## warns of the lunge, crouched and no wider, for the lunge's Warning Time, so the two warnings
## differ in shape and not only in colour.
func _lunges_at_a_man_past_bite_range() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var gap: float = man.position.x - demon.position.x
	var look: Vector2 = placeholder.scale
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, FRAMES_TO_WATCH)
	var lunge: DemonAttack = _lunge_of(demon)
	await _clear([ground, man, demon])
	var index: int = _index_after(changes, Demon.State.WARNING)
	var in_order: bool = index != NEVER_REACHED and changes[index].x == Demon.State.LUNGE
	var warned_for: int = changes[index].y - changes[index - 1].y if in_order else NEVER_REACHED
	var crouched: bool = look.x == 1.0 and look.y < 1.0
	return report(warned and lunged and in_order and warned_of.size() == 1
			and warned_of[0] == lunge and gap > BITE_RANGE
			and warned_for == lunge.get_warning_frames() and crouched,
			"Man %.1f px away, past Bite Range %d: warned of %s, %s, for %d frames of %d, %.2f wide and %.2f high"
			% [gap, BITE_RANGE, _animations_of(warned_of), _names_of(changes), warned_for,
					lunge.get_warning_frames(), look.x, look.y])


## A demon with a bite before a lunge whose chance never comes up: it runs on through Lunge Range
## without lunging, and warns of the bite once the man is inside Bite Range.
func _with_no_chance_it_never_lunges_and_bites_instead() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var gap: float = man.position.x - demon.position.x
	var bite: DemonAttack = _bite_of(demon)
	await _clear([ground, man, demon])
	return report(warned and warned_of.size() == 1 and warned_of[0] == bite and gap < BITE_RANGE,
			"Lunge with no chance, the man %d px away: first warned of %s, %.1f px from him (Bite Range %d, Lunge Range %d)"
			% [SEEN_X, _animations_of(warned_of), gap, BITE_RANGE, LUNGE_RANGE])


## The same demon and man: the man is further than the demon goes while it warns, so it bites short
## of him, chases on with no attack for the bite's Recover Time, coming up to him, and only then
## warns of the bite again.
func _chases_on_after_a_bite_and_bites_again_after_recover_time() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	var bit: bool = await wait_until(
			func() -> bool: return _index_after(changes, Demon.State.WARNING) != NEVER_REACHED)
	var bit_from: float = man.position.x - demon.position.x
	var warned_again: bool = await wait_until(
			func() -> bool: return warned_of.size() == 2, FRAMES_TO_WATCH)
	var warned_again_from: float = man.position.x - demon.position.x
	var bite: DemonAttack = _bite_of(demon)
	await _clear([ground, man, demon])
	var index: int = _index_after(changes, Demon.State.WARNING)
	var in_order: bool = bit and warned_again and changes[index].x == Demon.State.CHASE \
			and changes[index + 1].x == Demon.State.WARNING
	var chased_for: int = changes[index + 1].y - changes[index].y if in_order else NEVER_REACHED
	var only_bites: bool = warned_of.all(func(attack: DemonAttack) -> bool: return attack == bite)
	return report(in_order and only_bites and chased_for == bite.get_recover_frames()
			and bit_from > MOVED and bit_from - warned_again_from > MOVED,
			"Man %d px away, lunge with no chance: bit %.1f px from him, %s, chased for %d frames (Recover Time %d) and came up to %.1f px from him, then warned of %s"
			% [SEEN_X, bit_from, _names_of(changes), chased_for, bite.get_recover_frames(),
					warned_again_from, _animations_of(warned_of)])


## Over the physics frames of one second, the chance that an attack never starts comes to 1 - Chance
## Per Second at every frame rate, so a lunge is as likely at 120 Hz as at 60.
func _the_chance_per_second_comes_to_the_same_at_any_frame_rate() -> bool:
	var attack: DemonAttack = DemonAttack.new()
	attack.chance_per_second = HALF_CHANCE
	var never: PackedFloat64Array = []
	var same: bool = true
	for rate: int in FRAME_RATES:
		var never_in_a_second: float = pow(1.0 - attack.get_chance_in(1.0 / rate), rate)
		never.append(never_in_a_second)
		same = same and absf(never_in_a_second - (1.0 - HALF_CHANCE)) < CHANCE_TOLERANCE
	return report(same,
			"Chance Per Second %.2f: never in a second %s at %s Hz (should be %.2f)"
			% [HALF_CHANCE, never, FRAME_RATES, 1.0 - HALF_CHANCE])


## The demon's own roll, from a fixed seed, at each frame rate: over many seconds, an attack of
## Chance Per Second 0.5 starts in about half of them, at 120 Hz as at 60, so the roll takes each
## frame's length in, and not only the formula does.
func _the_demon_s_roll_comes_up_in_chance_per_second_of_the_seconds() -> bool:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	var attack: DemonAttack = DemonAttack.new()
	attack.chance_per_second = HALF_CHANCE
	var shares: PackedFloat64Array = []
	var near: bool = true
	for rate: int in FRAME_RATES:
		demon._rng.seed = ROLL_SEED
		var came_up: int = 0
		for _second: int in ROLLED_SECONDS:
			for _frame: int in rate:
				if demon._rolls(attack, 1.0 / rate):
					came_up += 1
					break
		var share: float = float(came_up) / ROLLED_SECONDS
		shares.append(share)
		near = near and absf(share - HALF_CHANCE) < ROLL_TOLERANCE
	demon.free()
	return report(near,
			"Demon's roll, Chance Per Second %.2f: started in %s of %d seconds at %s Hz"
			% [HALF_CHANCE, shares, ROLLED_SECONDS, FRAME_RATES])


## The demon falls towards the man onto his floor, inside Lunge Range for the end of its fall, as
## when the crucifix pushes it off a ledge: it warns only once it has landed.
func _warns_only_once_it_has_landed() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var warned_in_the_air: Array[bool] = []
	demon.state_changed.connect(
			func(_previous: Demon.State, current: Demon.State) -> void:
				if current == Demon.State.WARNING:
					warned_in_the_air.append(not demon.is_on_floor()))
	demon.position = Vector2(SEEN_X - DROP_GAP, -FALL_HEIGHT)
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, FRAMES_TO_WATCH)
	await _clear([ground, man, demon])
	return report(warned and warned_in_the_air == [false],
			"Dropped from %d px inside Lunge Range: warned %s, in the air %s"
			% [FALL_HEIGHT, warned, warned_in_the_air])


## The demon chases the man inside the crucifix's radius, and he holds it up: the crucifix pushes
## the demon out and it is repelled; after the last push it stays still for Repelled Time, and
## then chases again.
func _the_raised_crucifix_pushes_it_out_and_it_stays_still_for_repelled_time() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(REPEL_START_X, NO_LUNGE, changes)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var last_push_frame: Array[int] = [NEVER_REACHED]
	var last_push_x: Array[float] = [NAN]
	(demon.get_node(^"Repellable") as Repellable).repelled.connect(
			func(_origin: Vector2) -> void:
				last_push_frame[0] = Engine.get_physics_frames()
				last_push_x[0] = demon.position.x)
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var repelled: bool = await _is_in_state_within(demon, Demon.State.REPELLED, FRAMES_TO_WATCH)
	var freed: bool = await wait_until(
			func() -> bool: return demon.get_state() != Demon.State.REPELLED, FRAMES_TO_WATCH)
	var out_at: float = demon.position.x - man.position.x
	var drift: float = absf(demon.position.x - last_push_x[0])
	var still_up: bool = crucifix.is_raised()
	var radius: float = crucifix.stats.repel_radius
	var repelled_frames: int = demon.stats.get_repelled_frames()
	await _clear([ground, man, demon])
	var after: int = _index_after(changes, Demon.State.REPELLED)
	var next_state: Demon.State = changes[after].x as Demon.State if after != NEVER_REACHED \
			else Demon.State.REPELLED
	var kept_away: int = changes[after].y - last_push_frame[0] if after != NEVER_REACHED \
			else NEVER_REACHED
	return report(chased and still_up and repelled and freed and out_at >= radius
			and drift < STILL_TOLERANCE and next_state == Demon.State.CHASE
			and kept_away == repelled_frames,
			"Inside the raised crucifix's %d px: repelled %s, pushed out to %.1f px; still for %d frames of %d after the last push, moved %.2f px; then %s"
			% [radius, repelled, out_at, kept_away, repelled_frames, drift, _name_of(next_state)])


## The game pauses while the demon is repelled: the paused frames do not count, so once the game
## goes on, the demon stays still for the rest of Repelled Time, as long as with no pause.
func _a_pause_while_it_is_repelled_does_not_count() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(REPEL_START_X, NO_LUNGE, changes)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var last_push_frame: Array[int] = [NEVER_REACHED]
	(demon.get_node(^"Repellable") as Repellable).repelled.connect(
			func(_origin: Vector2) -> void: last_push_frame[0] = Engine.get_physics_frames())
	await _raise_crucifix_of(man)
	var repelled: bool = await _is_in_state_within(demon, Demon.State.REPELLED, FRAMES_TO_WATCH)
	await wait_until(func() -> bool:
			return Engine.get_physics_frames() - last_push_frame[0] >= PUSHED_BEFORE_PAUSE)
	var repelled_at_pause: bool = demon.get_state() == Demon.State.REPELLED
	paused = true
	var pause_start: int = Engine.get_physics_frames()
	await wait_frames(PAUSE_FRAMES)
	paused = false
	var paused_frames: int = Engine.get_physics_frames() - pause_start
	var freed: bool = await wait_until(
			func() -> bool: return demon.get_state() != Demon.State.REPELLED, FRAMES_TO_WATCH)
	var repelled_frames: int = demon.stats.get_repelled_frames()
	await _clear([ground, man, demon])
	var after: int = _index_after(changes, Demon.State.REPELLED)
	var kept_away: int = changes[after].y - last_push_frame[0] - paused_frames \
			if after != NEVER_REACHED else NEVER_REACHED
	return report(chased and repelled and repelled_at_pause and freed
			and kept_away == repelled_frames,
			"Paused %d frames while repelled (still repelled then %s): still for %d frames of %d after the last push, not counting the pause"
			% [paused_frames, repelled_at_pause, kept_away, repelled_frames])


## The demon stands on the man's spot, as when it has caught up with him, and he then holds up his
## crucifix: it is pushed out along the floor all the same.
func _the_raised_crucifix_pushes_it_off_the_man_s_spot() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var repelled: bool = await _is_in_state_within(demon, Demon.State.REPELLED, FRAMES_TO_WATCH)
	await wait_until(
			func() -> bool: return demon.get_state() != Demon.State.REPELLED, FRAMES_TO_WATCH)
	var out_at: float = absf(demon.position.x - man.position.x)
	var feet: float = demon.position.y
	var radius: float = crucifix.stats.repel_radius
	await _clear([ground, man, demon])
	return report(repelled and out_at >= radius and absf(feet) < TOLERANCE,
			"On the man's spot, then the crucifix goes up: repelled %s, pushed out to %.1f px (radius %d), feet at y = %.1f"
			% [repelled, out_at, radius, feet])


## The demon comes at the man while he holds up his crucifix, warns outside its radius and lunges
## into it: the crucifix stops the lunge, the demon is repelled in the air, and its middle never
## gets inside the radius.
func _a_lunge_into_the_raised_crucifix_ends_repelled() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(SEEN_X, LUNGE_RANGE, changes)
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, MAX_FRAMES)
	var nearest: float = absf(demon.position.x - man.position.x)
	for _frame: int in FRAMES_TO_WATCH:
		if demon.get_state() == Demon.State.REPELLED and demon.is_on_floor():
			break
		nearest = minf(nearest, absf(demon.position.x - man.position.x))
		await physics_frame
	var landed_repelled: bool = demon.get_state() == Demon.State.REPELLED and demon.is_on_floor()
	var radius: float = crucifix.stats.repel_radius
	await _clear([ground, man, demon])
	var in_order: bool = _names_of(changes) == "CHASE > WARNING > LUNGE > REPELLED"
	return report(lunged and in_order and landed_repelled and nearest > radius,
			"Lunging at the raised crucifix: %s; landed repelled %s; nearest %.1f px (radius %d)"
			% [_names_of(changes), landed_repelled, nearest, radius])


## A quick lunge into the raised crucifix, repelled on the way up: the demon goes no higher than
## Lunge Height, so a step of one tile stops it also when the crucifix cuts its lunge short.
func _repelled_in_a_quick_lunge_it_goes_no_higher_than_lunge_height() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	await _raise_crucifix_of(man)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(SEEN_X, LUNGE_RANGE, changes)
	_lunge_of(demon).lunge_time_to_peak = QUICK_LUNGE_TIME_TO_PEAK
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var take_off_y: float = demon.position.y
	var peak_y: float = take_off_y
	var repelled_in_the_air: bool = false
	for _frame: int in FRAMES_TO_WATCH:
		peak_y = minf(peak_y, demon.position.y)
		if demon.get_state() == Demon.State.REPELLED:
			repelled_in_the_air = repelled_in_the_air or not demon.is_on_floor()
			if demon.is_on_floor():
				break
		await physics_frame
	var landed_repelled: bool = demon.get_state() == Demon.State.REPELLED and demon.is_on_floor()
	var height: float = take_off_y - peak_y
	await _clear([ground, man, demon])
	return report(warned and repelled_in_the_air and landed_repelled
			and height <= LUNGE_HEIGHT + HEIGHT_TOLERANCE,
			"Quick lunge repelled in the air (%s): %.2f px up (at most %d), landed repelled %s; %s"
			% [repelled_in_the_air, height, LUNGE_HEIGHT, landed_repelled, _names_of(changes)])


## The values that go into the game, in lust_demon_stats.tres, keep what the levels are drawn for:
## the demon has attacks, each with one of the art's animations, a step of one tile stops every
## lunge and keeps a man on it safe, the demon loses the man only past where it sees him, and it
## chases slower than he runs, so running away works. A tuning that breaks one of these fails here,
## before it gets into a level.
func _the_level_s_values_keep_what_the_levels_count_on() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var man_stats: PlayerMovementStats = load(PLAYER_MOVEMENT_STATS) as PlayerMovementStats
	var highest: float = 0.0
	var most_height_difference: float = 0.0
	var all_known: bool = true
	for attack: DemonAttack in demon_stats.attacks:
		highest = maxf(highest, attack.lunge_height)
		most_height_difference = maxf(most_height_difference, attack.max_height_difference)
		all_known = all_known and attack.animation in DemonAttack.ANIMATIONS
	var below_a_step: bool = not demon_stats.attacks.is_empty() and highest < TILE \
			and most_height_difference < TILE
	var loses_past_sight: bool = demon_stats.lose_distance > demon_stats.sight_distance
	var slower: bool = demon_stats.chase_speed < man_stats.max_run_speed
	return report(below_a_step and all_known and loses_past_sight and slower,
			"Level values: attacks %s (all with known animations %s), lunging at most %d px up, at men up to %d px higher (a step is %d); loses him at %d px, sees him at %d; chases at %d px/s, he runs at %d"
			% [_animations_of(demon_stats.attacks), all_known, highest, most_height_difference,
					TILE, demon_stats.lose_distance, demon_stats.sight_distance,
					demon_stats.chase_speed, man_stats.max_run_speed])


## The man, behind a wall, holds up his crucifix with the demon inside its radius: the demon, which
## never saw him, is repelled, and then goes back to standing instead of chasing.
func _repelled_before_it_saw_the_man_it_goes_back_to_standing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_REPEL_WALL_X, HIDING_REPEL_WALL_X + WALL_THICKNESS,
			WALL_TOP)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(REPEL_START_X + WALL_THICKNESS, LUNGE_RANGE, changes)
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var raised: bool = crucifix.is_raised()
	await wait_until(func() -> bool: return changes.size() >= 2, FRAMES_TO_WATCH)
	await _clear([ground, wall, man, demon])
	return report(raised and _names_of(changes) == "REPELLED > IDLE",
			"Never saw the man behind a wall, then his crucifix goes up (up %s): %s"
			% [raised, _names_of(changes)])


## The demon chases the man between him and the end of his floor, and he holds up his crucifix: the
## push takes it over the ledge, it falls to the floor below, and it goes on from there once
## Repelled Time is over. A mechanic: the crucifix can throw a demon off the floor where it was
## placed.
func _the_raised_crucifix_pushes_it_off_a_ledge_onto_the_floor_below() -> bool:
	var upper: StaticBody2D = make_platform(FLOOR_LEFT, LEDGE_X)
	var lower: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT, LEDGE_DROP)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var demon: Demon = await _spawn_demon(REPEL_START_X, NO_LUNGE)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var repelled: bool = await _is_in_state_within(demon, Demon.State.REPELLED, FRAMES_TO_WATCH)
	var landed_free: bool = await wait_until(
			func() -> bool: return demon.is_on_floor() and demon.position.y > LEDGE_DROP / 2.0 \
					and demon.get_state() != Demon.State.REPELLED, FRAMES_TO_WATCH)
	var x: float = demon.position.x
	var feet: float = demon.position.y
	var radius: float = crucifix.stats.repel_radius
	await _clear([upper, lower, man, demon])
	return report(chased and repelled and landed_free and x > LEDGE_X
			and absf(feet - LEDGE_DROP) < TOLERANCE,
			"Between the man and a ledge %d px away, then the crucifix (%d px) goes up: repelled %s, landed below and free %s, at x = %.1f, feet at y = %.1f (floor below at %d)"
			% [LEDGE_X, radius, repelled, landed_free, x, feet, LEDGE_DROP])


## The man past Sight Distance; a larger Sight Distance set while the game runs lets the demon see
## him at once.
func _sight_follows_sight_distance_while_the_game_runs() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(UNSEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var before: bool = await _chases_within(demon, SETTLE_FRAMES)
	demon.stats.sight_distance = TUNED_SIGHT_DISTANCE
	var after: bool = await _chases_within(demon, SETTLE_FRAMES)
	await _clear([ground, man, demon])
	return report(not before and after,
			"At %d px: chased with Sight Distance %d %s, with %d %s"
			% [UNSEEN_X, SIGHT_DISTANCE, before, TUNED_SIGHT_DISTANCE, after])


## The demon's body is on the enemy layer and collides with the world and one-way platforms only,
## and its sight area is on no layer and looks only for the player.
func _is_on_the_enemy_layer_and_looks_only_for_the_player() -> bool:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	var sight_area: Area2D = demon.get_node(^"SightArea") as Area2D
	var world_bit: int = _bit_of(WORLD_LAYER_NAME)
	var one_way_bit: int = _bit_of(ONE_WAY_LAYER_NAME)
	var enemy_bit: int = _bit_of(ENEMY_LAYER_NAME)
	var player_bit: int = _bit_of(PLAYER_LAYER_NAME)
	var body_right: bool = demon.collision_layer == enemy_bit \
			and demon.collision_mask == world_bit | one_way_bit
	var sight_right: bool = sight_area.collision_layer == 0 \
			and sight_area.collision_mask == player_bit
	var found_all: bool = world_bit != 0 and one_way_bit != 0 and enemy_bit != 0 and player_bit != 0
	demon.free()
	return report(found_all and body_right and sight_right,
			"Body on the enemy layer, colliding with the world only: %s; sight looking only for the player: %s"
			% [body_right, sight_right])


## A demon of DEMON_SCENE at x, with its own DemonStats of the values above and its attacks, once it
## has landed: a lunge of the values above with lunge_range as its Attack Range and, with bite, a
## bite of the values above before it. Every state it changes to from the start goes into changes,
## with the physics frame it changed in, and every attack it warns of goes into warned_of.
func _spawn_demon(x: float, lunge_range: float = LUNGE_RANGE,
		changes: Array[Vector2i] = [], bite: bool = false,
		warned_of: Array[DemonAttack] = []) -> Demon:
	var lunge: DemonAttack = DemonAttack.new()
	lunge.attack_range = lunge_range
	lunge.max_height_difference = MAX_HEIGHT_DIFFERENCE
	lunge.warning_time = WARNING_TIME
	lunge.lunge_distance = LUNGE_DISTANCE
	lunge.lunge_min_distance = LUNGE_MIN_DISTANCE
	lunge.lead = FULL_LEAD
	lunge.lunge_height = LUNGE_HEIGHT
	lunge.lunge_time_to_peak = LUNGE_TIME_TO_PEAK
	lunge.recover_time = RECOVER_TIME
	var stats: DemonStats = DemonStats.new()
	stats.sight_distance = SIGHT_DISTANCE
	stats.lose_distance = LOSE_DISTANCE
	stats.give_up_time = GIVE_UP_TIME
	stats.chase_speed = CHASE_SPEED
	if bite:
		stats.attacks.append(_make_bite())
	stats.attacks.append(lunge)
	stats.repelled_time = REPELLED_TIME
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.stats = stats
	demon.position = Vector2(x, SPAWN_Y)
	demon.state_changed.connect(
			func(_previous: Demon.State, current: Demon.State) -> void:
				changes.append(Vector2i(current, Engine.get_physics_frames())))
	demon.warning_started.connect(
			func(attack: DemonAttack) -> void: warned_of.append(attack))
	root.add_child(demon)
	await wait_until(demon.is_on_floor)
	return demon


## A bite on the run of the values above.
func _make_bite() -> DemonAttack:
	var bite: DemonAttack = DemonAttack.new()
	bite.animation = &"bite"
	bite.keeps_chasing = true
	bite.attack_range = BITE_RANGE
	bite.max_height_difference = MAX_HEIGHT_DIFFERENCE
	bite.warning_time = BITE_WARNING_TIME
	bite.recover_time = BITE_RECOVER_TIME
	return bite


## Moves the man speed px/s along the floor, + to the right, on every physics frame from now on: a
## walk at a steady speed, slower than he runs, which his own input does not give. Hands back what
## to disconnect from physics_frame to stop him.
func _walk(man: Player, speed: float) -> Callable:
	var step: Callable = func() -> void:
		man.position.x += speed / Engine.physics_ticks_per_second
	physics_frame.connect(step)
	return step


## The lunge of a demon of _spawn_demon: its last attack.
func _lunge_of(demon: Demon) -> DemonAttack:
	return demon.stats.attacks.back()


## The bite of a demon of _spawn_demon with a bite: its first attack.
func _bite_of(demon: Demon) -> DemonAttack:
	return demon.stats.attacks.front()


## The animations of attacks, in order, for a report.
func _animations_of(attacks: Array[DemonAttack]) -> String:
	var names: PackedStringArray = []
	for attack: DemonAttack in attacks:
		names.append(attack.animation)
	return ", ".join(names)


## Whether the demon is chasing on any of the next frames.
func _chases_within(demon: Demon, frames: int) -> bool:
	return await _is_in_state_within(demon, Demon.State.CHASE, frames)


## Whether the demon is in state on any of the next frames.
func _is_in_state_within(demon: Demon, state: Demon.State, frames: int) -> bool:
	return await wait_until(func() -> bool: return demon.get_state() == state, frames)


## Whether the demon ever changed to a warning, by the states _spawn_demon wrote into changes.
func _warned(changes: Array[Vector2i]) -> bool:
	return changes.any(func(change: Vector2i) -> bool: return change.x == Demon.State.WARNING)


## Where in changes the demon changed out of the first time it was in state; NEVER_REACHED if it
## never was, or is still in it.
func _index_after(changes: Array[Vector2i], state: Demon.State) -> int:
	for index: int in range(changes.size() - 1):
		if changes[index].x == state:
			return index + 1
	return NEVER_REACHED


## The man's crucifix, held up by a stand-in input, once it is up.
func _raise_crucifix_of(man: Player) -> Crucifix:
	var crucifix: Crucifix = man.get_node(CRUCIFIX_NODE) as Crucifix
	put_a_stand_in(man).crucifix_held = true
	await wait_until(crucifix.is_raised, SETTLE_FRAMES)
	return crucifix


## The names of the states in changes, in order, for a report.
func _names_of(changes: Array[Vector2i]) -> String:
	var names: PackedStringArray = []
	for change: Vector2i in changes:
		names.append(_name_of(change.x as Demon.State))
	return " > ".join(names)


## Half the width of the demon's collision box, read from its scene.
func _half_width(demon: Demon) -> float:
	var collision: CollisionShape2D = demon.get_node(^"CollisionShape2D") as CollisionShape2D
	return (collision.shape as RectangleShape2D).size.x / 2.0


func _name_of(state: Demon.State) -> String:
	return Demon.State.keys()[state]


## The bit of the physics layer the project gives that name; 0 if none has it.
func _bit_of(layer_name: String) -> int:
	for layer: int in range(1, PHYSICS_LAYERS + 1):
		if ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % layer, "") == layer_name:
			return 1 << (layer - 1)
	return 0


## Takes out what a case made at the end of the frame, and waits for it.
func _clear(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame
