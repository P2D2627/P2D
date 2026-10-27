# Checks the demon's chase. It sees the man inside Sight Distance with no wall in between and chases
# him along its own floor; it does not see him further away or through a wall. It stops at an edge,
# and never climbs nor lunges up a step of one tile, so the level's own shape keeps it where it was
# placed. Once it
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
# or where a quick lunge would land past the end of its floor. The man's raised crucifix throws it
# off and out of its radius, once, at Throw Height, also from right on his spot, and out of a lunge
# only across, never higher than Lunge Height; it then stays still for Repelled Time after landing,
# not counting a pause, and goes back to chasing, or to standing if it had never seen him; near a
# ledge, the throw takes it onto the floor below. Its sight grows at once when Sight Distance
# changes while the game runs, and it is on the enemy layer, collides with the world and the man's
# body, and looks only for the player. It sees the man's head over a wall that hides his middle;
# with Sight Behind Share it sees less behind it, whichever way it was put facing; with Chases Only
# On Screen it starts no chase off the screen and gives up once off it; with Return Speed it walks
# back to its post once it gives up, chases a man it sees ahead on the way, and on another floor or
# against a wall stays where it is stopped (ADR 0032), with its post the same, and patrols around
# there; with the wall gone, it walks home the next time it gives up (ADR 0043). A man on a floor
# or a wall over every attack's Max Height Difference, above it or below its ledge, is out of its
# reach (ADR 0033): it stands facing him wherever he walks, chases him again once he is back down,
# and gives up after Out Of Reach Wait; a man in the air over it does not count, so a jump never
# stops the chase. With Patrol Width it walks to and fro across it
# at Patrol Speed, pausing at each end within Patrol Pause Min and Max, turns back at an edge and at
# a step, stands still off the screen, pauses apart from another demon, chases a man it notices on
# the way, and patrols again once back at its post. With Alert Time it stands turned to a man it
# notices for that long before it chases him, and lets go of one freed meanwhile; with Search Time,
# once a wall hides him, it sniffs where it last saw him and then walks back, is alerted by him
# again if it sees him on the way, and walks back once off the screen; lost any other way, it never
# searches (ADR 0035). Its body and the man's stop each other at the side, also in a lunge. With a bite before the lunge, it bites a man right by it on the run, with the bite's own
# warning and shape, with no pounce and never past him, and still lunges at one past Bite Range;
# with no chance for the lunge, it runs on and bites him instead, then chases on with no attack for
# the bite's Recover Time; and the chance per second comes to the same at any frame rate. Its Hitbox
# is on only while an attack can land: for the bite's Bite Time from the end of its warning, and
# through a lunge from take-off until it lands, never once the crucifix has pushed it; on, it
# carries the attack's damage and knockback, and a bite lands once on the man's Hurtbox and the
# demon says so, with attack_landed. With Retreat Distance, it backs off after each attack instead
# (ADR 0023): after a bite once Bite Time is over, after a lunge once Recover Time is over, facing
# the man, at Retreat Speed, with no attack, until he is Retreat Distance away, and then comes back
# and attacks again; it chases on at once after a lunge that leaves him that far, a man who follows
# it keeps it backing off no longer than Retreat Distance takes, an edge behind it stops it, and
# against a man standing still it is never on him longer than the bite. With Pack Spacing (ADR
# 0024), a demon behind another waits that far behind its body and lunges over it from there, one
# put nearer steps back to that, facing the man, and stops at an edge behind it, two that bite both
# keep biting and cross only while one backs off, one past the man never keeps another from biting
# him, and the area in which it finds the others follows Pack Spacing at once; with Pack Variation,
# each demon chases and backs off at its own pace, within it. While the man is invulnerable it
# starts no attack, a warning under way goes back to the chase, and with Retreat Distance it keeps
# that far from him (ADR 0025); two that his invulnerability's end sets free warn together, and with
# Max Hesitation apart (ADR 0027). A bite that grabs the man at low SP keeps the demon holding on,
# still, with no attack, until he breaks free, and then it is thrown off, Throw Height up and Throw
# Distance away from him, and lies stunned, still and flat, for Stunned Time once it lands (ADR
# 0028); another demon's bite on the held man joins, and both are thrown off, each to its own side
# (ADR 0021); a third, past the most that can hold him, never attacks him while he is held and keeps
# Retreat Distance from him (ADR 0029). The man is the real player, standing still or moved at a
# steady speed, with his Hurtbox off and with his body and the demon's not colliding, so the cases
# see only how the demon chases and aims; the cases where a bite lands and those of his body turn
# them on. Each demon gets its own DemonStats with the values below and its attacks, the lunge, or a
# bite and then the lunge, backs off only in the cases of the retreat, and keeps apart or varies
# only in those of the pack, so the .tres can be tuned without breaking the test; only the last seven
# cases read the .tres, to check that its values keep what the levels count on.
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
## What the bite and the lunge do when they land, set in the cases of the Hitbox, and the bite's
## Bite Time: 6 frames.
const BITE_TIME: float = 0.1
const BITE_DAMAGE: float = 10.0
const BITE_KNOCKBACK_DISTANCE: float = 150.0
const BITE_KNOCKBACK_HEIGHT: float = 40.0
const LUNGE_DAMAGE: float = 20.0
const LUNGE_KNOCKBACK_DISTANCE: float = 250.0
const LUNGE_KNOCKBACK_HEIGHT: float = 70.0
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
## In the case of the pause, the game pauses LANDED_BEFORE_PAUSE frames after the demon lands from
## the crucifix's throw, well inside Repelled Time, and stays paused for PAUSE_FRAMES.
const LANDED_BEFORE_PAUSE: int = 10
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
## How much nearer than touching the man's body and the demon's may come, and how far apart they may
## stay and still count as touching, in px: Godot keeps a body a little apart from what it touches.
const CONTACT_TOLERANCE: float = 1.0
## Where the man starts running at the demon from, in its sight on its left.
const RUN_START_X: float = -240.0
## The cases' demons that back off after their attacks: past Bite Range, slower than Chase Speed.
## Backing off that far takes them 48 frames.
const RETREAT_DISTANCE: float = 160.0
const RETREAT_SPEED: float = 200.0
## In the case of the edge behind it, the demon's floor ends this far behind where it starts.
const EDGE_BEHIND: float = 40.0
## In the case of the man standing still, how long it is watched: some four bites.
const STANDING_STILL_FRAMES: int = 300
## Times the demon has to back off from him in that while: it keeps coming back.
const LEAST_RETREATS: int = 3
## The cases of two demons: the gap they keep between their bodies, in px, and how far behind the
## first, in its sight, the second starts; in the case of the turns, just behind it, so with nothing
## keeping them apart both get to the man together.
const PACK_SPACING: float = 72.0
const SECOND_DEMON_BEHIND: float = 150.0
const SECOND_DEMON_NEAR: float = 60.0
## In the case of a demon put too near the one ahead of it, how far behind that one it starts: its
## body half inside the other's.
const SECOND_DEMON_INSIDE: float = 24.0
## How long two demons that bite and back off are watched at a man standing still, and the bites
## each of them has to warn of in that while: some six bites between them.
const PACK_FRAMES: int = 600
const LEAST_TURNS: int = 3
## The Pack Spacing the area that finds other demons has to follow at once, as when it is changed in
## the Remote tab.
const WIDER_PACK_SPACING: float = 400.0
## The case of Pack Variation: how many demons, the share their values can be off by, and the seed
## the global generator gets first, so the demons draw the same values on every run.
const PACK_SIZE: int = 6
const PACK_VARIATION: float = 0.1
const PACK_SEED: int = 1
## How long the man is invulnerable in the cases of the attacks held back (ADR 0025): as long as after
## a hit in the game. His Hurtbox is off, but it counts the time down all the same.
const INVULNERABLE_TIME: float = 1.0
## The case of Max Hesitation (ADR 0027): the longest wait, and the seed that makes the two demons'
## draws the same on every run.
const MAX_HESITATION: float = 0.5
const HESITATION_SEED: int = 27
## SP taken from the man's 100 to put him below Low Threshold, so the demon's bite grabs him.
const DAMAGE_TO_LOW: float = 80.0
## The throw as the man breaks free, in the case that measures it.
const THROW_DISTANCE: float = 200.0
const THROW_HEIGHT: float = 40.0
const THROW_TIME_TO_PEAK: float = 0.15
## Stunned Time in the case of the stun after the man's throw (ADR 0028): the level's.
const STUNNED_TIME: float = 1.2
## The cases of the sight, the screen and the post (ADR 0032). A wall low enough to hide the man's
## middle from the demon's eyes, both 48 px up, but not his head: SEEN_X away, the line to his head
## passes 68 px up over the wall's near face.
const LOW_WALL_TOP: float = -60.0
## The share of Sight Distance the cases' demons see behind them: 120 px, short of SEEN_X.
const BEHIND_SHARE: float = 0.25
const NO_SIGHT_BEHIND: float = 0.0
## In the case of the screen's edge (ADR 0038): how far off the screen a chase goes on.
const SCREEN_MARGIN: float = 160.0
## Return Speed of the cases' demons that walk back to their post: slower than Chase Speed.
const RETURN_SPEED: float = 150.0
## Physics frames the walk back is measured over, and how far, in px/s, its speed may be from Return
## Speed.
const RETURN_MEASURE_FRAMES: int = 20
const SPEED_TOLERANCE: float = 5.0
## How far from its post the man draws the demon before he goes.
const AWAY_FROM_POST: float = 200.0
## In the case of another floor, the post's floor ends at x = UPPER_FLOOR_RIGHT, and a floor
## LOWER_FLOOR_DROP px lower runs from x = LOWER_FLOOR_LEFT on, where the demon is put at
## LOWER_START_X.
const UPPER_FLOOR_RIGHT: float = 96.0
const LOWER_FLOOR_LEFT: float = 600.0
const LOWER_FLOOR_DROP: float = 200.0
const LOWER_START_X: float = 900.0
## In the case of the wall on the way back, the wall's right face, between the post and where the
## demon gives up.
const RETURN_WALL_X: float = 100.0
## The cases of the man out of reach (ADR 0033): a ledge two tiles up, over every attack's Max Height
## Difference, from x = HIGH_LEDGE_LEFT on. The man stands on it at OUT_OF_REACH_X and then walks
## ALONG_LEDGE px along it, over WALK_FRAMES, while the demon must stand where it is.
const HIGH_LEDGE_HEIGHT: float = 96.0
const HIGH_LEDGE_LEFT: float = 150.0
const OUT_OF_REACH_X: float = 200.0
const ALONG_LEDGE: float = 200.0
const WALK_FRAMES: int = 20
## Out Of Reach Wait of the cases' demons: 48 frames, longer than Give Up Time, so a demon that gave
## up because it lost sight of the man would give up sooner and be caught.
const OUT_OF_REACH_WAIT: float = 0.8
## In the case of the man below, the demon's ledge ends at x = HIGH_LEDGE_RIGHT and the man stands
## on the floor at BELOW_LEDGE_X, inside Sight Distance and in its sight past the ledge's corner.
const HIGH_LEDGE_RIGHT: float = 200.0
const BELOW_LEDGE_X: float = 400.0
## How high above its floor the man is put in the case of the jump: over Max Height Difference.
const JUMP_PEAK: float = 100.0
## How high above the demon's floor the man is held in the air in the case of coming back down:
## within Max Height Difference.
const IN_REACH_HEIGHT: float = 12.0
## The cases of the patrol (ADR 0033): the stretch the demon walks around its post, its speed and the
## shortest and longest pause at each end, short so the cases do not wait long. Walking from one end
## to the other takes some 80 frames, and a pause 12 to 24.
const PATROL_WIDTH: float = 200.0
const PATROL_SPEED: float = 150.0
const PATROL_PAUSE_MIN: float = 0.2
const PATROL_PAUSE_MAX: float = 0.4
## How long a patrol is watched: past three ends at the slowest.
const PATROL_FRAMES: int = 400
## In the case of the edge and the step, both inside the patrol: the floor ends at x =
## -PATROL_EDGE, and rises one tile at x = PATROL_STEP_X.
const PATROL_EDGE: float = 60.0
const PATROL_STEP_X: float = 70.0
## The least number of times a patrolling demon has to set off in that while: both ways at least.
const LEAST_SET_OFFS: int = 3
## In the case of two demons on patrol, how far apart they are put: out of each other's way.
const PATROL_APART: float = 600.0
const PATROL_SEED: int = 33
## The cases of the alert and the search (ADR 0035): how long the demon stands alerted, 18 frames;
## how long it sniffs where it last saw the man, 60 frames, longer than Give Up Time; and how fast
## it walks there, slower than it chases.
const ALERT_TIME: float = 0.3
const SEARCH_TIME: float = 1.0
const SEARCH_SPEED: float = 200.0
## The cases of the demon pacing out of reach (ADR 0039): the stretch it paces around where it
## stopped, at Patrol Speed, some 64 frames from end to end; the shortest and longest pause at each
## end, where it barks, 12 to 18 frames; and an Out Of Reach Wait long enough to watch it pace across
## three times before it gives up.
const PACE_WIDTH: float = 160.0
const PACE_PAUSE_MIN: float = 0.2
const PACE_PAUSE_MAX: float = 0.3
const PACE_WAIT: float = 6.0
## How long the pacing is watched: past three ends at the slowest, inside PACE_WAIT.
const PACE_FRAMES: int = 300
## The least number of barks in that while: one at each end.
const LEAST_BARKS: int = 3
## In the cases of the wall and the edge, how far from them the demon is put: nearer than half
## PACE_WIDTH, so its stretch runs past them.
const PACE_NEAR: float = 60.0
## Frames a bark is watched for its hop in the drawing: past the placeholder's Hop Time.
const HOP_FRAMES: int = 30
## Frames into a hop when the case of the hop cut short changes the demon's state: about its top.
const HOP_CUT_FRAMES: int = 8
## In the case of the thin shelf: its top SHELF_HEIGHT above the floor, SHELF_THICKNESS thick, from
## x = HIGH_LEDGE_LEFT on, with room below it for the demon; the man SHELF_INSET px in from its
## corner, the demon put SHELF_AWAY px out from it. From there it sees his head over the corner, but
## about 33 px nearer the corner it no longer does, and its stretch takes it 80 px nearer.
const SHELF_HEIGHT: float = 200.0
const SHELF_THICKNESS: float = 10.0
const SHELF_INSET: float = 100.0
const SHELF_AWAY: float = 200.0
## The case of two demons pacing as in a level: the level's pauses, with Out Of Reach Wait over
## PAIR_FRAMES, watched with each of PAIR_SEEDS. Two barks nearer than MIN_BARK_GAP frames, a tenth
## of a second, read and sound as one, and two demons that bark together half the time or more are
## in step.
const LEVEL_PAUSE_MIN: float = 0.6
const LEVEL_PAUSE_MAX: float = 1.2
const PAIR_WAIT: float = 10.0
const PAIR_FRAMES: int = 540
const PAIR_SEEDS: Array[int] = [39, 40, 41]
const MIN_BARK_GAP: int = 6


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
	results.append(await _a_man_freed_while_it_warns_waits_or_holds_leaves_it_standing())
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
	results.append(await _the_bite_can_land_only_for_bite_time_from_the_end_of_its_warning())
	results.append(await _the_lunge_can_land_only_while_it_is_in_the_air())
	results.append(await _pushed_in_a_lunge_its_hitbox_goes_off_in_the_same_frame())
	results.append(await _pushed_while_it_bites_its_hitbox_goes_off_for_good())
	results.append(await _a_bite_lands_once_on_the_man_s_hurtbox_and_the_demon_says_so())
	results.append(await _the_man_s_body_stops_its_chase_at_his_side())
	results.append(await _the_man_s_body_stops_its_lunge_and_it_never_passes_him())
	results.append(await _the_man_runs_into_it_and_is_stopped_at_its_side())
	results.append(await _after_a_bite_it_backs_off_facing_the_man_then_comes_back_and_bites())
	results.append(await _after_a_lunge_it_stays_for_recover_time_then_backs_off())
	results.append(await _after_a_lunge_that_leaves_the_man_far_it_chases_on_at_once())
	results.append(await _a_man_who_follows_it_keeps_it_backing_off_no_longer_than_its_distance_takes())
	results.append(await _an_edge_behind_it_stops_it_backing_off())
	results.append(await _against_a_man_standing_still_it_is_never_on_him_longer_than_the_bite())
	results.append(await _a_demon_behind_another_waits_pack_spacing_behind_it())
	results.append(await _a_demon_behind_another_lunges_over_it())
	results.append(await _a_demon_too_near_the_one_ahead_steps_back_to_pack_spacing())
	results.append(await _a_demon_stepping_back_to_pack_spacing_stops_at_an_edge())
	results.append(await _two_demons_that_bite_both_keep_biting_and_cross_only_while_one_backs_off())
	results.append(await _a_demon_past_the_man_never_keeps_another_from_biting_him())
	results.append(await _a_demon_not_after_the_man_never_holds_back_one_that_chases_him())
	results.append(await _the_pack_area_follows_pack_spacing_at_once())
	results.append(await _with_pack_variation_each_demon_has_its_own_speeds_and_retreat_distance())
	results.append(await _warns_of_no_attack_while_the_man_is_invulnerable())
	results.append(await _a_warning_under_way_ends_when_the_man_turns_invulnerable())
	results.append(await _while_the_man_is_invulnerable_it_keeps_retreat_distance_from_him())
	results.append(await _two_demons_set_free_together_warn_apart_with_max_hesitation())
	results.append(await _its_bite_that_grabs_holds_on_with_no_attack_until_the_man_breaks_free())
	results.append(await _a_second_demon_s_bite_joins_the_grab_and_both_are_thrown_off_once_he_is_free())
	results.append(await _a_third_demon_keeps_retreat_distance_from_a_man_held_by_the_most())
	results.append(await _thrown_off_it_peaks_at_throw_height_and_lands_throw_distance_away())
	results.append(await _thrown_off_by_the_man_it_lies_stunned_for_stunned_time())
	results.append(_the_chance_per_second_comes_to_the_same_at_any_frame_rate())
	results.append(_the_demon_s_roll_comes_up_in_chance_per_second_of_the_seconds())
	results.append(await _warns_only_once_it_has_landed())
	results.append(await _the_raised_crucifix_throws_it_off_and_on_landing_it_stays_still_for_repelled_time())
	results.append(await _the_raised_crucifix_pushes_it_off_the_man_s_spot())
	results.append(await _a_pause_while_it_is_repelled_does_not_count())
	results.append(await _a_lunge_into_the_raised_crucifix_ends_repelled())
	results.append(await _thrown_off_in_a_quick_lunge_it_goes_no_higher_than_lunge_height())
	results.append(await _repelled_before_it_saw_the_man_it_goes_back_to_standing())
	results.append(await _the_raised_crucifix_pushes_it_off_a_ledge_onto_the_floor_below())
	results.append(await _sight_follows_sight_distance_while_the_game_runs())
	results.append(await _sees_the_man_s_head_over_a_low_wall())
	results.append(await _sees_behind_it_only_its_behind_share())
	results.append(await _starts_no_chase_off_the_screen())
	results.append(await _gives_up_once_it_is_off_the_screen())
	results.append(await _keeps_chasing_inside_screen_margin_and_starts_only_on_the_screen())
	results.append(await _walks_back_to_its_post_at_return_speed_once_it_gives_up())
	results.append(await _walking_back_it_chases_a_man_it_sees_ahead())
	results.append(await _on_another_floor_it_stays_where_its_floor_stops_it_and_keeps_its_post())
	results.append(await _a_wall_on_the_way_back_stops_it_there_and_it_keeps_its_post())
	results.append(await _with_the_wall_gone_it_walks_home_the_next_time_it_gives_up())
	results.append(await _kept_off_its_post_it_patrols_around_where_it_stopped())
	results.append(await _stands_facing_a_man_out_of_its_reach_wherever_he_walks())
	results.append(await _stands_facing_a_man_out_of_its_reach_below_it())
	results.append(await _out_of_reach_it_chases_again_once_the_man_comes_back_down())
	results.append(await _out_of_reach_for_out_of_reach_wait_it_gives_up_and_walks_back())
	results.append(await _keeps_chasing_a_man_who_jumps_on_its_floor())
	results.append(await _having_given_up_it_leaves_a_man_out_of_reach_alone_until_he_comes_down())
	results.append(await _never_warns_of_an_attack_at_a_man_in_the_air_over_its_reach())
	results.append(await _with_patrol_width_it_walks_to_and_fro_and_pauses_at_each_end())
	results.append(await _patrolling_it_turns_at_an_edge_and_at_a_step())
	results.append(await _patrolling_off_the_screen_it_stands_still())
	results.append(await _two_demons_on_patrol_never_set_off_together())
	results.append(await _patrolling_it_chases_a_man_it_sees_ahead())
	results.append(await _back_at_its_post_it_patrols_again())
	results.append(await _with_alert_time_it_stands_turned_to_the_man_then_chases())
	results.append(await _alerted_it_lets_go_of_a_man_who_is_freed())
	results.append(await _with_search_time_it_sniffs_where_it_last_saw_the_man_then_walks_back())
	results.append(await _with_search_time_only_a_wall_makes_it_search())
	results.append(await _searching_it_is_alerted_by_a_man_it_sees_again())
	results.append(await _searching_off_the_screen_it_walks_back())
	results.append(await _two_demons_searching_one_spot_sniff_pack_spacing_apart())
	results.append(await _with_pace_width_out_of_reach_it_paces_around_where_it_stopped())
	results.append(await _pacing_out_of_reach_it_barks_facing_the_man_at_each_end())
	results.append(await _pacing_out_of_reach_it_hops_where_a_wall_stops_it_on_the_man_s_side())
	results.append(await _pacing_out_of_reach_it_hops_where_its_floor_ends_on_the_man_s_side())
	results.append(await _pacing_out_of_reach_it_still_gives_up_after_out_of_reach_wait())
	results.append(await _pacing_out_of_reach_it_keeps_on_below_a_shelf_that_hides_the_man())
	results.append(await _with_no_pace_width_out_of_reach_it_never_barks())
	results.append(await _two_demons_pacing_out_of_reach_never_bark_in_step())
	results.append(await _a_bark_hops_only_the_drawing_and_higher_at_a_wall())
	results.append(await _a_new_state_ends_a_hop_with_the_drawing_at_rest())
	results.append(_is_on_the_enemy_layer_and_looks_only_for_the_player())
	results.append(_the_level_s_values_keep_what_the_levels_count_on())
	results.append(_the_level_s_demons_back_off_past_bite_range_slower_than_they_chase())
	results.append(_the_level_s_demons_keep_it_at_both_ends_of_pack_variation())
	results.append(_the_level_s_throw_never_lands_a_demon_on_a_step())
	results.append(_the_level_s_demons_chase_on_screen_and_walk_back_slower_than_they_chase())
	results.append(_the_level_s_demons_patrol_and_leave_a_man_on_a_step_out_of_reach())
	results.append(_the_level_s_demons_pace_and_bark_out_of_reach_before_they_give_up())
	results.append(_the_level_s_demons_are_alerted_and_search_before_they_give_up())
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


## The man on a step one tile high, over Max Height Difference: out of the demon's reach (ADR 0033),
## so it stops short of the step where it noticed him, on its floor, and never warns.
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
	var stopped: bool = changes.any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.OUT_OF_REACH)
	return report(front <= STEP_X + TOLERANCE and absf(feet) < TOLERANCE and stopped
			and not _warned(changes),
			"Step at x = %d: front at %.1f, feet at y = %.1f, out of reach %s, then %s, %.1f px from the man, warned %s"
			% [STEP_X, front, feet, stopped, _name_of(state), gap, _warned(changes)])


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
## A man freed, as on a respawn, while a demon warns of a lunge at him, waits out of its reach, or
## holds him in its bite: each time the demon lets go of him and stands, with no lunge at where he
## was and no hold on nothing.
func _a_man_freed_while_it_warns_waits_or_holds_leaves_it_standing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var warning_changes: Array[Vector2i] = []
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, warning_changes)
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var from: int = warning_changes.size()
	await remove_player(man)
	var after_warning: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var lunged: bool = warning_changes.slice(from).any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.LUNGE)
	await _clear([demon])
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	demon = await _spawn_demon(0.0, NO_LUNGE)
	man = await spawn_on_floor(Vector2(-SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position = Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT)
	var waiting: bool = await _is_in_state_within(demon, Demon.State.OUT_OF_REACH, MAX_FRAMES)
	await remove_player(man)
	var after_waiting: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	await _clear([ledge, demon])
	man = await _man_a_bite_grabs()
	demon = await _spawn_demon(0.0, LUNGE_RANGE, [], true)
	_make_it_back_off(demon)
	var grabbed: bool = await _is_in_state_within(demon, Demon.State.GRAB, MAX_FRAMES)
	await remove_player(man)
	var after_holding: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var state: Demon.State = demon.get_state()
	await _clear([ground, demon])
	return report(warned and after_warning and not lunged and chased and waiting and after_waiting
			and grabbed and after_holding,
			"The man freed: while it warned %s, stands %s, lunged %s; while it waited out of reach %s, stands %s; while it held him %s, stands %s (in %s)"
			% [warned, after_warning, lunged, waiting, after_waiting, grabbed, after_holding,
					_name_of(state)])


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


## The demon's Hitbox is off while it warns of a bite, on for Bite Time's frames from the frame the
## warning ends, with the bite's damage and knockback, and off again while it chases on.
func _the_bite_can_land_only_for_bite_time_from_the_end_of_its_warning() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true)
	var bite: DemonAttack = _bite_of(demon)
	_give_hit(bite, BITE_DAMAGE, BITE_KNOCKBACK_DISTANCE, BITE_KNOCKBACK_HEIGHT)
	bite.bite_time = BITE_TIME
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var on_frames: Array[int] = await _frames_with_hitbox_on(hitbox,
			bite.get_warning_frames() + bite.get_bite_frames() + SETTLE_FRAMES)
	var carried: bool = _carries(hitbox, bite)
	await _clear([ground, man, demon])
	var index: int = _index_after(changes, Demon.State.WARNING)
	var bit_frame: int = changes[index].y if index != NEVER_REACHED else NEVER_REACHED
	var expected: Array[int] = []
	for i: int in bite.get_bite_frames():
		expected.append(bit_frame + i)
	return report(warned and bit_frame != NEVER_REACHED and on_frames == expected and carried,
			"Bite with %d frames of Bite Time, warning ended on frame %d: Hitbox on in frames %s, expected %s; carries the bite's damage and knockback %s"
			% [bite.get_bite_frames(), bit_frame, on_frames, expected, carried])


## Through a lunge, the Hitbox is on in every frame the demon is in the air, with the lunge's damage
## and knockback, and off in every other: while it warns and while it recovers on the floor.
func _the_lunge_can_land_only_while_it_is_in_the_air() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	var lunge: DemonAttack = _lunge_of(demon)
	_give_hit(lunge, LUNGE_DAMAGE, LUNGE_KNOCKBACK_DISTANCE, LUNGE_KNOCKBACK_HEIGHT)
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var on_in_the_air: int = 0
	var wrong_frames: int = 0
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		var in_the_air: bool = demon.get_state() == Demon.State.LUNGE and not demon.is_on_floor()
		if hitbox.is_active() != in_the_air:
			wrong_frames += 1
		elif in_the_air:
			on_in_the_air += 1
	var carried: bool = _carries(hitbox, lunge)
	await _clear([ground, man, demon])
	return report(on_in_the_air > 0 and wrong_frames == 0 and carried,
			"Lunge at a man %d px away: Hitbox on in %d frames in the air, wrong in %d of %d frames; carries the lunge's damage and knockback %s"
			% [SEEN_X, on_in_the_air, wrong_frames, FRAMES_TO_WATCH, carried])


## The crucifix throws the demon off in the middle of a lunge in the air, and its Hitbox goes off in
## that same frame and stays off while it is thrown and repelled. The demon goes into the tree before
## the man, so its own physics, which also turns the Hitbox off, comes before the crucifix's in each
## frame: only the push itself can turn it off in time.
func _pushed_in_a_lunge_its_hitbox_goes_off_in_the_same_frame() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(SEEN_X, LUNGE_RANGE, changes)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	await _raise_crucifix_of(man)
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var on_in_the_lunge: bool = false
	var on_while_pushed: int = 0
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		var state: Demon.State = demon.get_state()
		on_in_the_lunge = on_in_the_lunge or (state == Demon.State.LUNGE and hitbox.is_active())
		if (state == Demon.State.THROWN or state == Demon.State.REPELLED) and hitbox.is_active():
			on_while_pushed += 1
	await _clear([ground, man, demon])
	var thrown_from_the_lunge: bool = _names_of(changes).contains("LUNGE > THROWN")
	return report(on_in_the_lunge and thrown_from_the_lunge and on_while_pushed == 0,
			"Lunging at the raised crucifix: %s; Hitbox on in the lunge %s, on in %d frames thrown or repelled, expected 0"
			% [_names_of(changes), on_in_the_lunge, on_while_pushed])


## The man raises the crucifix as the demon bites: the push ends the bite, and the Hitbox stays off
## while the demon is thrown and repelled, although Bite Time is not over.
func _pushed_while_it_bites_its_hitbox_goes_off_for_good() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true)
	_bite_of(demon).bite_time = BITE_TIME
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var bit: bool = await wait_until(hitbox.is_active)
	put_a_stand_in(man).crucifix_held = true
	var on_while_pushed: int = 0
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		var state: Demon.State = demon.get_state()
		if (state == Demon.State.THROWN or state == Demon.State.REPELLED) and hitbox.is_active():
			on_while_pushed += 1
	await _clear([ground, man, demon])
	var thrown: bool = _names_of(changes).contains("THROWN > REPELLED")
	return report(bit and thrown and on_while_pushed == 0,
			"Crucifix raised as the demon bites: %s; Hitbox on in %d frames thrown or repelled, expected 0"
			% [_names_of(changes), on_while_pushed])


## With the man's Hurtbox on, one bite lands once, on the frame it bites, with the bite's damage and
## knockback, and the demon says attack_landed with the bite.
func _a_bite_lands_once_on_the_man_s_hurtbox_and_the_demon_says_so() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var hurtbox: Hurtbox = _hurtbox_of(man)
	hurtbox.monitoring = true
	var received: Array[Hitbox] = []
	hurtbox.hit_received.connect(func(hitbox: Hitbox) -> void: received.append(hitbox))
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, [], true)
	var bite: DemonAttack = _bite_of(demon)
	_give_hit(bite, BITE_DAMAGE, BITE_KNOCKBACK_DISTANCE, BITE_KNOCKBACK_HEIGHT)
	bite.bite_time = BITE_TIME
	var landed: Array[DemonAttack] = []
	demon.attack_landed.connect(func(attack: DemonAttack) -> void: landed.append(attack))
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	await _wait_physics_frames(bite.get_warning_frames() + bite.get_bite_frames() + SETTLE_FRAMES)
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var once_from_it: bool = received.size() == 1 and received[0] == hitbox and _carries(hitbox, bite)
	var said_so: bool = landed.size() == 1 and landed[0] == bite
	await _clear([ground, man, demon])
	return report(warned and once_from_it and said_so,
			"One bite at a man with a Hurtbox: %d hits received, from the demon's Hitbox with the bite's values %s; attack_landed %d times with the bite %s"
			% [received.size(), once_from_it, landed.size(), said_so])


## With the man's body in its way, the chase stops the demon at his side, the bodies touching, and
## over a long chase it never comes nearer, so it never gets on his spot.
func _the_man_s_body_stops_its_chase_at_his_side() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_the_bodies_solid(man, demon)
	var contact: float = _contact_distance(man, demon)
	var nearest: float = INF
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		nearest = minf(nearest, man.position.x - demon.position.x)
	var gap: float = man.position.x - demon.position.x - contact
	await _clear([ground, man, demon])
	return report(nearest >= contact - CONTACT_TOLERANCE and gap <= CONTACT_TOLERANCE,
			"Chase with the man's body in the way: at most %.2f px nearer than touching, %.2f px from it at the end"
			% [contact - nearest, gap])


## A man standing still where the lunge would land: his body stops the demon in the air at his side,
## and it lands there, never nearer and never past him.
func _the_man_s_body_stops_its_lunge_and_it_never_passes_him() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0)
	_make_the_bodies_solid(man, demon)
	var contact: float = _contact_distance(man, demon)
	var lunged: bool = await _is_in_state_within(demon, Demon.State.LUNGE, MAX_FRAMES)
	var nearest: float = INF
	var landed: bool = false
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		nearest = minf(nearest, man.position.x - demon.position.x)
		if demon.is_on_floor():
			landed = true
			break
	var gap: float = man.position.x - demon.position.x - contact
	await _clear([ground, man, demon])
	return report(lunged and landed and nearest >= contact - CONTACT_TOLERANCE
			and gap <= CONTACT_TOLERANCE,
			"Lunge at a man standing still, his body in the way: lunged %s, landed %s, at most %.2f px nearer than touching, landed %.2f px from it"
			% [lunged, landed, contact - nearest, gap])


## The man runs at the demon, which chases him: the two bodies stop each other at the side, and his
## running never pushes it on past where it stood. Either of the two can be first in the tree, and
## so move first in a frame.
func _the_man_runs_into_it_and_is_stopped_at_its_side() -> bool:
	var passed: bool = true
	for man_first: bool in [false, true]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var man: Player = null
		if man_first:
			man = await spawn_on_floor(Vector2(RUN_START_X, SPAWN_Y))
		var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
		if not man_first:
			man = await spawn_on_floor(Vector2(RUN_START_X, SPAWN_Y))
		_make_the_bodies_solid(man, demon)
		var stand_in: StandInInput = put_a_stand_in(man)
		stand_in.run_direction = 1.0
		var contact: float = _contact_distance(man, demon)
		var start_x: float = demon.position.x
		var nearest: float = INF
		var pushed: float = 0.0
		for _frame: int in FRAMES_TO_WATCH:
			await physics_frame
			nearest = minf(nearest, demon.position.x - man.position.x)
			pushed = maxf(pushed, demon.position.x - start_x)
		var gap: float = demon.position.x - man.position.x - contact
		await _clear([ground, man, demon])
		passed = report(nearest >= contact - CONTACT_TOLERANCE and gap <= CONTACT_TOLERANCE
				and pushed <= CONTACT_TOLERANCE,
				"The man running at it, %s first: at most %.2f px nearer than touching, %.2f px from it at the end, pushed %.2f px on"
				% ["the man" if man_first else "the demon", contact - nearest, gap, pushed]) and passed
	return passed


## A man standing still right by the demon, the bodies solid, with no chance for the lunge: it bites
## him, and once Bite Time is over backs off at Retreat Speed, facing him, with its Hitbox off and no
## warning, until he is Retreat Distance away; then it chases him and warns of the bite again.
func _after_a_bite_it_backs_off_facing_the_man_then_comes_back_and_bites() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	_make_it_back_off(demon)
	_make_the_bodies_solid(man, demon)
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var farthest: float = 0.0
	var fastest: float = 0.0
	var faced_him: bool = true
	var hitbox_off: bool = true
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if warned_of.size() == 2:
			break
		if demon.get_state() != Demon.State.RETREAT:
			continue
		var gap: float = man.position.x - demon.position.x
		farthest = maxf(farthest, absf(gap))
		fastest = maxf(fastest, absf(demon.velocity.x))
		faced_him = faced_him and demon.get_facing() == signf(gap)
		hitbox_off = hitbox_off and not hitbox.is_active()
	await _clear([ground, man, demon])
	var in_order: bool = _names_of(changes).begins_with(
			"CHASE > WARNING > CHASE > RETREAT > CHASE > WARNING")
	return report(in_order and farthest >= RETREAT_DISTANCE - TOLERANCE
			and is_equal_approx(fastest, RETREAT_SPEED) and faced_him and hitbox_off,
			"Bite at a man standing still: %s; backed off to %.1f px from him (Retreat Distance %d) at %.1f px/s (Retreat Speed %d), facing him %s, Hitbox off %s"
			% [_names_of(changes), farthest, RETREAT_DISTANCE, fastest, RETREAT_SPEED, faced_him,
			hitbox_off])


## A man standing still inside Lunge Range, the bodies solid, with no bite: the demon lunges, stays
## where it lands for Recover Time, and then backs off until he is Retreat Distance away.
func _after_a_lunge_it_stays_for_recover_time_then_backs_off() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	_make_it_back_off(demon)
	_make_the_bodies_solid(man, demon)
	var backed_off: bool = await wait_until(
			func() -> bool: return _index_after(changes, Demon.State.RETREAT) != NEVER_REACHED)
	var gap: float = man.position.x - demon.position.x
	await _clear([ground, man, demon])
	var lunged_at: int = _index_after(changes, Demon.State.WARNING)
	var stayed: int = (changes[lunged_at + 1].y - changes[lunged_at].y
			if backed_off and lunged_at != NEVER_REACHED else NEVER_REACHED)
	return report(backed_off and _names_of(changes).begins_with("CHASE > WARNING > LUNGE > RETREAT > CHASE")
			and stayed > RECOVER_TIME * Engine.physics_ticks_per_second
			and gap >= RETREAT_DISTANCE - TOLERANCE,
			"Lunge at a man standing still: %s; %d frames from take-off to backing off (Recover Time %d after landing); %.1f px from him at the end (Retreat Distance %d)"
			% [_names_of(changes), stayed, roundi(RECOVER_TIME * Engine.physics_ticks_per_second),
			gap, RETREAT_DISTANCE])


## The same, but the man is put past Retreat Distance from where the demon lands, while it recovers:
## it chases on at once, with no backing off.
func _after_a_lunge_that_leaves_the_man_far_it_chases_on_at_once() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	_make_it_back_off(demon)
	var landed: bool = await wait_until(
			func() -> bool: return demon.get_state() == Demon.State.LUNGE and demon.is_on_floor())
	man.position.x = demon.position.x + 2.0 * RETREAT_DISTANCE
	await wait_until(
			func() -> bool: return _index_after(changes, Demon.State.LUNGE) != NEVER_REACHED)
	await _clear([ground, man, demon])
	return report(landed and _names_of(changes).begins_with("CHASE > WARNING > LUNGE > CHASE"),
			"Lunge, then the man put %d px from where it landed: %s" % [2.0 * RETREAT_DISTANCE,
			_names_of(changes)])


## After a bite, the man walks after the demon at its Retreat Speed, so he never gets further away:
## it backs off for the time Retreat Distance takes at Retreat Speed, and then chases him again.
func _a_man_who_follows_it_keeps_it_backing_off_no_longer_than_its_distance_takes() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	_make_it_back_off(demon)
	var backing_off: bool = await _is_in_state_within(demon, Demon.State.RETREAT, MAX_FRAMES)
	var step: Callable = _walk(man, -RETREAT_SPEED)
	await wait_until(
			func() -> bool: return _index_after(changes, Demon.State.RETREAT) != NEVER_REACHED,
			FRAMES_TO_WATCH)
	physics_frame.disconnect(step)
	var most_frames: int = demon.stats.get_retreat_max_frames()
	await _clear([ground, man, demon])
	var index: int = _index_after(changes, Demon.State.RETREAT)
	var frames: int = (changes[index].y - changes[index - 1].y
			if backing_off and index != NEVER_REACHED else NEVER_REACHED)
	return report(frames == most_frames and changes[index].x == Demon.State.CHASE,
			"Followed while it backs off: backed off for %d frames (Retreat Distance at Retreat Speed takes %d), then %s"
			% [frames, most_frames, _name_of(changes[index].x as Demon.State)])


## The demon's floor ends just behind where it starts, and it bites a man ahead of it: it backs off
## to the edge and stops there, never off its floor, and chases him again after the time Retreat
## Distance would take.
func _an_edge_behind_it_stops_it_backing_off() -> bool:
	var ground: StaticBody2D = make_platform(-EDGE_BEHIND, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	_make_it_back_off(demon)
	var backing_off: bool = await _is_in_state_within(demon, Demon.State.RETREAT, MAX_FRAMES)
	var on_floor: bool = true
	var leftmost: float = INF
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		if demon.get_state() != Demon.State.RETREAT:
			break
		on_floor = on_floor and demon.is_on_floor() and absf(demon.position.y) < TOLERANCE
		leftmost = minf(leftmost, demon.position.x)
	var most_frames: int = demon.stats.get_retreat_max_frames()
	await _clear([ground, man, demon])
	var index: int = _index_after(changes, Demon.State.RETREAT)
	var frames: int = (changes[index].y - changes[index - 1].y
			if backing_off and index != NEVER_REACHED else NEVER_REACHED)
	return report(on_floor and leftmost >= -EDGE_BEHIND and frames == most_frames,
			"Backing off towards an edge %d px behind it: on its floor %s, got to x = %.1f, backed off for %d frames (%d)"
			% [EDGE_BEHIND, on_floor, leftmost, frames, most_frames])


## A man standing still, the bodies solid, with no chance for the lunge, watched for some four bites:
## the demon's body touches his only from just before a bite until Bite Time is over, never longer,
## and it keeps coming back.
func _against_a_man_standing_still_it_is_never_on_him_longer_than_the_bite() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	_make_it_back_off(demon)
	_make_the_bodies_solid(man, demon)
	var contact: float = _contact_distance(man, demon)
	var bite: DemonAttack = _bite_of(demon)
	var most_frames: int = bite.get_warning_frames() + bite.get_bite_frames() + SETTLE_FRAMES
	var touching_frames: int = 0
	var longest: int = 0
	for _frame: int in STANDING_STILL_FRAMES:
		await physics_frame
		var touching: bool = man.position.x - demon.position.x <= contact + CONTACT_TOLERANCE
		touching_frames = touching_frames + 1 if touching else 0
		longest = maxi(longest, touching_frames)
	await _clear([ground, man, demon])
	var retreats: int = changes.filter(
			func(change: Vector2i) -> bool: return change.x == Demon.State.RETREAT).size()
	return report(longest <= most_frames and retreats >= LEAST_RETREATS,
			"A man standing still for %d frames: touched for at most %d frames in a row (the bite's warning and Bite Time with room: %d), backed off %d times (at least %d)"
			% [STANDING_STILL_FRAMES, longest, most_frames, retreats, LEAST_RETREATS])


## Two demons, one behind the other, come at a man standing still with no chance to attack, the
## bodies solid: the first stops at his side, the second Pack Spacing behind the first's body, and
## their bodies never overlap on the way (ADR 0024).
func _a_demon_behind_another_waits_pack_spacing_behind_it() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var front: Demon = await _spawn_demon(0.0)
	var back: Demon = await _spawn_demon(-SECOND_DEMON_BEHIND)
	for demon: Demon in [front, back]:
		_lunge_of(demon).chance_per_second = NO_CHANCE
		_make_it_keep_apart(demon)
		_make_the_bodies_solid(man, demon)
	var width: float = _body_width(front)
	var closest: float = INF
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		closest = minf(closest, absf(front.position.x - back.position.x))
	var at_his_side: float = man.position.x - front.position.x
	var behind: float = front.position.x - back.position.x
	var contact: float = _contact_distance(man, front)
	await _clear([ground, man, front, back])
	return report(absf(at_his_side - contact) <= CONTACT_TOLERANCE
			and absf(behind - width - PACK_SPACING) <= CONTACT_TOLERANCE and closest >= width,
			"Two demons at a man standing still: the first %.1f px from him (touching %.1f), the second %.1f px behind it (body %d + Pack Spacing %d), never nearer than %.1f px"
			% [at_his_side, contact, behind, width, PACK_SPACING, closest])


## The same, but the first demon has no attacks and the second has the lunge, with no chance of it
## until it waits Pack Spacing behind the first, with the man inside its Lunge Range: given the
## chance back, it warns and lunges at him over the first, since every demon attacks.
func _a_demon_behind_another_lunges_over_it() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var front: Demon = await _spawn_demon(0.0)
	front.stats.attacks.clear()
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var back: Demon = await _spawn_demon(-SECOND_DEMON_BEHIND, LUNGE_RANGE, changes, false,
			warned_of)
	var chance: float = _lunge_of(back).chance_per_second
	_lunge_of(back).chance_per_second = NO_CHANCE
	for demon: Demon in [front, back]:
		_make_it_keep_apart(demon)
		_make_the_bodies_solid(man, demon)
	await wait_frames(FRAMES_TO_WATCH)
	var width: float = _body_width(front)
	var behind: float = front.position.x - back.position.x
	var waiting: bool = absf(behind - width - PACK_SPACING) <= CONTACT_TOLERANCE
	var back_gap: float = man.position.x - back.position.x
	var lunged_behind_by: Array[float] = []
	back.state_changed.connect(func(_previous: Demon.State, current: Demon.State) -> void:
		if current == Demon.State.LUNGE and lunged_behind_by.is_empty():
			lunged_behind_by.append(front.position.x - back.position.x))
	_lunge_of(back).chance_per_second = chance
	await wait_frames(FRAMES_TO_WATCH)
	await _clear([ground, man, front, back])
	var over_it: bool = not lunged_behind_by.is_empty() and lunged_behind_by[0] > 0.0
	return report(waiting and not warned_of.is_empty() and over_it,
			"A demon with the lunge, first with no chance of it: waited %.1f px behind one with no attacks (body %d + Pack Spacing %d) %s; given the chance, %.1f px from the man (Lunge Range %d), warned %d times (%s), lunged from %s px behind the first %s"
			% [behind, width, PACK_SPACING, waiting, back_gap, LUNGE_RANGE, warned_of.size(),
					_names_of(changes), lunged_behind_by, over_it])


## A demon standing between the man and one that chases him, facing away from him and seeing
## nothing behind it, never notices him: the one that chases him goes past it to his spot, since only
## a demon after the man holds back another.
func _a_demon_not_after_the_man_never_holds_back_one_that_chases_him() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var standing: Demon = await _spawn_demon(0.0, NO_LUNGE, changes, false, [], true)
	standing.stats.sight_behind_share = NO_SIGHT_BEHIND
	var chasing: Demon = await _spawn_demon(-SECOND_DEMON_BEHIND, NO_LUNGE)
	for demon: Demon in [standing, chasing]:
		_make_it_keep_apart(demon)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(chasing, FRAMES_TO_WATCH)
	var got_to_him: bool = await wait_until(
			func() -> bool: return absf(man.position.x - chasing.position.x) <= TOLERANCE,
			FRAMES_TO_WATCH)
	var past: float = chasing.position.x - standing.position.x
	await _clear([ground, man, standing, chasing])
	return report(chased and got_to_him and changes.is_empty(),
			"A demon chasing the man past one that stands facing away: got to his spot %s, %.1f px past it; the one standing changed state %s"
			% [got_to_him, past, _names_of(changes)])


## A demon put with its body inside that of one at a man's side, as after crossing it on the way
## back, neither with attacks: it steps back, facing the man, until it is Pack Spacing behind the
## other's body.
func _a_demon_too_near_the_one_ahead_steps_back_to_pack_spacing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var front: Demon = await _spawn_demon(0.0)
	_make_the_bodies_solid(man, front)
	front.stats.attacks.clear()
	await wait_frames(FRAMES_TO_WATCH)
	var back: Demon = await _spawn_demon(front.position.x - SECOND_DEMON_INSIDE)
	back.stats.attacks.clear()
	for demon: Demon in [front, back]:
		_make_it_keep_apart(demon)
	var facing_him: bool = true
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		facing_him = facing_him and back.get_facing() == signf(man.position.x - back.position.x)
	var behind: float = front.position.x - back.position.x
	var width: float = _body_width(front)
	await _clear([ground, man, front, back])
	return report(absf(behind - width - PACK_SPACING) <= CONTACT_TOLERANCE and facing_him,
			"A demon put %d px behind one at a man's side: %.1f px behind it after %d frames (body %d + Pack Spacing %d), facing the man all along %s"
			% [SECOND_DEMON_INSIDE, behind, FRAMES_TO_WATCH, width, PACK_SPACING, facing_him])


## The same, with the floor ending Edge Behind behind the demon put too near: it stops at the edge,
## on its floor, instead of stepping back off it.
func _a_demon_stepping_back_to_pack_spacing_stops_at_an_edge() -> bool:
	var edge: float = -(SECOND_DEMON_INSIDE + EDGE_BEHIND)
	var ground: StaticBody2D = make_platform(edge, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var front: Demon = await _spawn_demon(0.0)
	_make_the_bodies_solid(man, front)
	front.stats.attacks.clear()
	await wait_frames(FRAMES_TO_WATCH)
	var back: Demon = await _spawn_demon(front.position.x - SECOND_DEMON_INSIDE)
	back.stats.attacks.clear()
	for demon: Demon in [front, back]:
		_make_it_keep_apart(demon)
	var on_floor: bool = true
	var leftmost: float = INF
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		on_floor = on_floor and back.is_on_floor() and absf(back.position.y) < TOLERANCE
		leftmost = minf(leftmost, back.position.x)
	var behind: float = front.position.x - back.position.x
	await _clear([ground, man, front, back])
	return report(on_floor and leftmost >= edge,
			"Stepping back from %d px behind another, the floor ending at x = %.1f: on its floor %s, got to x = %.1f, %.1f px behind the other"
			% [SECOND_DEMON_INSIDE, edge, on_floor, leftmost, behind])


## Two demons that bite and back off, one behind the other, at a man standing still, the bodies
## solid, with no chance for the lunge: both keep biting him, and their bodies overlap only while one
## of them backs off past the other, for no longer than that crossing takes.
func _two_demons_that_bite_both_keep_biting_and_cross_only_while_one_backs_off() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demons: Array[Demon] = []
	var warnings: Array[int] = [0, 0]
	for index: int in 2:
		var changes: Array[Vector2i] = []
		var demon: Demon = await _spawn_demon(-SECOND_DEMON_NEAR * index, LUNGE_RANGE, changes,
				true)
		_lunge_of(demon).chance_per_second = NO_CHANCE
		_make_it_back_off(demon)
		_make_it_keep_apart(demon)
		_make_the_bodies_solid(man, demon)
		demon.warning_started.connect(func(_attack: DemonAttack) -> void: warnings[index] += 1)
		demons.append(demon)
	var width: float = _body_width(demons[0])
	var most_crossing: int = (ceili(2.0 * width / (CHASE_SPEED + RETREAT_SPEED)
			* Engine.physics_ticks_per_second) + SETTLE_FRAMES)
	var overlapping: int = 0
	var longest: int = 0
	var only_backing_off: bool = true
	for _frame: int in PACK_FRAMES:
		await physics_frame
		if absf(demons[0].position.x - demons[1].position.x) >= width:
			overlapping = 0
			continue
		overlapping += 1
		longest = maxi(longest, overlapping)
		only_backing_off = only_backing_off and (demons[0].get_state() == Demon.State.RETREAT
				or demons[1].get_state() == Demon.State.RETREAT)
	await _clear([ground, man, demons[0], demons[1]])
	return report(warnings.min() >= LEAST_TURNS and only_backing_off and longest <= most_crossing,
			"Two demons that back off at a man standing still for %d frames: bites warned of %s (each at least %d); overlapped only while one backed off %s, for at most %d frames in a row (the crossing with room: %d)"
			% [PACK_FRAMES, warnings, LEAST_TURNS, only_backing_off, longest, most_crossing])


## A demon with no attacks at one side of a man standing still, and one that bites and backs off
## coming from the other side, as far from him: the first is past the man, not between him and the
## second, so the second comes up to his side and keeps biting him.
func _a_demon_past_the_man_never_keeps_another_from_biting_him() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var far_side: Demon = await _spawn_demon(0.0)
	far_side.stats.attacks.clear()
	var biter: Demon = await _spawn_demon(2.0 * SEEN_X, LUNGE_RANGE, [], true)
	_lunge_of(biter).chance_per_second = NO_CHANCE
	_make_it_back_off(biter)
	var warnings: Array[int] = [0]
	biter.warning_started.connect(func(_attack: DemonAttack) -> void: warnings[0] += 1)
	for demon: Demon in [far_side, biter]:
		_make_it_keep_apart(demon)
		_make_the_bodies_solid(man, demon)
	var contact: float = _contact_distance(man, biter)
	var closest: float = INF
	for _frame: int in STANDING_STILL_FRAMES:
		await physics_frame
		closest = minf(closest, absf(biter.position.x - man.position.x))
	var far_gap: float = man.position.x - far_side.position.x
	await _clear([ground, man, far_side, biter])
	return report(warnings[0] >= LEAST_RETREATS and closest <= contact + CONTACT_TOLERANCE,
			"A demon that bites, coming at a man standing still from the side away from one with no attacks %.1f px from him, for %d frames: warned %d times (at least %d); came up to %.1f px from him (touching %.1f)"
			% [far_gap, STANDING_STILL_FRAMES, warnings[0], LEAST_RETREATS, closest, contact])


## The area in which a demon finds the others reaches a body and a half and Pack Spacing from its
## middle, and follows Pack Spacing as soon as it changes.
func _the_pack_area_follows_pack_spacing_at_once() -> bool:
	var demon: Demon = await _spawn_demon(0.0)
	_make_it_keep_apart(demon)
	var area: RectangleShape2D = (demon.get_node(^"PackArea/PackShape") as CollisionShape2D).shape
	var body_and_a_half: float = 1.5 * _body_width(demon)
	var reaches: Array[float] = [area.size.x / 2.0]
	demon.stats.pack_spacing = WIDER_PACK_SPACING
	reaches.append(area.size.x / 2.0)
	var expected: Array[float] = [body_and_a_half + PACK_SPACING,
			body_and_a_half + WIDER_PACK_SPACING]
	await _clear([demon])
	return report(reaches == expected,
			"Pack area reach with Pack Spacing %d, then %d: %s px (expected %s)"
			% [PACK_SPACING, WIDER_PACK_SPACING, reaches, expected])


## A pack of demons that bite and back off, with Pack Variation and no Pack Spacing, put in on one
## spot at a man standing still, the bodies solid, so each backs off from his side and stops at its
## own Retreat Distance before its retreat runs out of time: each chases, backs off and stops backing
## off at its own pace, within
## Pack Variation of its DemonStats, and the pack does not do any of it all at one pace. Where they
## stop backing off is spread wider than the last step of a retreat, which the speeds alone give.
func _with_pack_variation_each_demon_has_its_own_speeds_and_retreat_distance() -> bool:
	seed(PACK_SEED)
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demons: Array[Demon] = []
	var chase_speeds: Array[float] = []
	var retreat_speeds: Array[float] = []
	var retreat_ends: Array[float] = []
	for index: int in PACK_SIZE:
		var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, [], true)
		_lunge_of(demon).chance_per_second = NO_CHANCE
		_make_it_back_off(demon)
		_make_the_bodies_solid(man, demon)
		demon.stats.pack_variation = PACK_VARIATION
		demon.state_changed.connect(func(previous: Demon.State, current: Demon.State) -> void:
			if previous == Demon.State.RETREAT and current == Demon.State.CHASE:
				retreat_ends[index] = minf(retreat_ends[index],
						absf(man.position.x - demon.position.x)))
		demons.append(demon)
		chase_speeds.append(0.0)
		retreat_speeds.append(0.0)
		retreat_ends.append(INF)
	for _frame: int in STANDING_STILL_FRAMES:
		await physics_frame
		for index: int in PACK_SIZE:
			var speed: float = absf(demons[index].velocity.x)
			match demons[index].get_state():
				Demon.State.CHASE:
					chase_speeds[index] = maxf(chase_speeds[index], speed)
				Demon.State.RETREAT:
					retreat_speeds[index] = maxf(retreat_speeds[index], speed)
	var last_step: float = (RETREAT_SPEED * (1.0 + PACK_VARIATION)
			/ Engine.physics_ticks_per_second)
	var within: bool = true
	for index: int in PACK_SIZE:
		within = (within and _is_within_pack_variation(chase_speeds[index], CHASE_SPEED)
				and _is_within_pack_variation(retreat_speeds[index], RETREAT_SPEED)
				and _is_within_pack_variation(retreat_ends[index], RETREAT_DISTANCE, last_step))
	var apart: bool = (chase_speeds.max() > chase_speeds.min()
			and retreat_speeds.max() > retreat_speeds.min()
			and retreat_ends.max() - retreat_ends.min() > last_step)
	var cleared: Array[Node] = [ground, man]
	cleared.append_array(demons)
	await _clear(cleared)
	return report(within and apart,
			"%d demons with Pack Variation %.2f: chased at %.1f to %.1f px/s (Chase Speed %d), backed off at %.1f to %.1f px/s (Retreat Speed %d), stopped backing off %.1f to %.1f px from the man (Retreat Distance %d)"
			% [PACK_SIZE, PACK_VARIATION, chase_speeds.min(), chase_speeds.max(), CHASE_SPEED,
			retreat_speeds.min(), retreat_speeds.max(), RETREAT_SPEED, retreat_ends.min(),
			retreat_ends.max(), RETREAT_DISTANCE])


## A man right by the demon, invulnerable, and a bite whose chance always comes up: the demon chases
## him and is in Bite Range, but never warns while he is invulnerable, and warns once he is not
## (ADR 0025).
func _warns_of_no_attack_while_the_man_is_invulnerable() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var hurtbox: Hurtbox = _hurtbox_of(man)
	hurtbox.start_invulnerability(INVULNERABLE_TIME)
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, [], true)
	_lunge_of(demon).chance_per_second = NO_CHANCE
	var in_range: bool = false
	var warned_while_invulnerable: bool = false
	while true:
		await physics_frame
		if not hurtbox.is_invulnerable():
			break
		var state: Demon.State = demon.get_state()
		in_range = in_range or (state == Demon.State.CHASE
				and absf(man.position.x - demon.position.x) < BITE_RANGE)
		warned_while_invulnerable = warned_while_invulnerable or state == Demon.State.WARNING
	var warned_after: bool = (demon.get_state() == Demon.State.WARNING
			or await _is_in_state_within(demon, Demon.State.WARNING, SETTLE_FRAMES))
	await _clear([ground, man, demon])
	return report(in_range and not warned_while_invulnerable and warned_after,
			"Bite at a man invulnerable for %.1f s: chased him into Bite Range %s, warned while he was invulnerable %s, warned within %d frames after %s"
			% [INVULNERABLE_TIME, in_range, warned_while_invulnerable, SETTLE_FRAMES, warned_after])


## Two demons that bite, one on each side of a man invulnerable for INVULNERABLE_TIME, both with him
## in Bite Range when it ends. With no Max Hesitation they warn on the same frame, the pack in step
## of ADR 0027; with MAX_HESITATION each waits its own draw, so they warn on different frames, both
## within MAX_HESITATION of the end.
func _two_demons_set_free_together_warn_apart_with_max_hesitation() -> bool:
	var together: Array[int] = await _first_warnings_after_invulnerability(0.0)
	var apart: Array[int] = await _first_warnings_after_invulnerability(MAX_HESITATION)
	var most: int = roundi(MAX_HESITATION * Engine.physics_ticks_per_second) + SETTLE_FRAMES
	var within: bool = apart.all(func(frames: int) -> bool: return frames >= 0 and frames <= most)
	return report(together[0] != NEVER_REACHED and together[0] == together[1]
			and apart[0] != apart[1] and within,
			("Two demons set free together, frames to warn after the man's blink: with no Max "
			+ "Hesitation %s, with %.2f s %s (at most %d)") % [together, MAX_HESITATION, apart,
			most])


## Frames from the end of the man's invulnerability until each of two demons that bite, one on each
## side of him, with max_hesitation, first warns; NEVER_REACHED for one that does not in
## FRAMES_TO_WATCH. His Hurtbox looks for nothing, so no bite lands and turns him invulnerable again
## before the other demon warns. HESITATION_SEED goes in before the demons, which seed their own
## draws from it.
func _first_warnings_after_invulnerability(max_hesitation: float) -> Array[int]:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	var hurtbox: Hurtbox = _hurtbox_of(man)
	hurtbox.monitoring = false
	hurtbox.start_invulnerability(INVULNERABLE_TIME)
	seed(HESITATION_SEED)
	var demons: Array[Demon] = [await _spawn_demon(0.0, LUNGE_RANGE, [], true),
			await _spawn_demon(2.0 * BITE_X, LUNGE_RANGE, [], true)]
	for demon: Demon in demons:
		_lunge_of(demon).chance_per_second = NO_CHANCE
		demon.stats.max_hesitation = max_hesitation
	await wait_until(func() -> bool: return not hurtbox.is_invulnerable(), FRAMES_TO_WATCH)
	var warned_at: Array[int] = [NEVER_REACHED, NEVER_REACHED]
	for frame: int in FRAMES_TO_WATCH:
		for index: int in demons.size():
			if warned_at[index] == NEVER_REACHED \
					and demons[index].get_state() == Demon.State.WARNING:
				warned_at[index] = frame
		await physics_frame
	await _clear([ground, man, demons[0], demons[1]])
	return warned_at


## A demon warning of a lunge, still, or of a bite, on the run, when the man turns invulnerable, as
## when another demon's attack has just landed on him: it goes back to the chase in that same frame,
## and while he is invulnerable it warns no more and its Hitbox stays off (ADR 0025).
func _a_warning_under_way_ends_when_the_man_turns_invulnerable() -> bool:
	var passed: bool = true
	for bite: bool in [false, true]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var man: Player = await spawn_on_floor(Vector2(BITE_X if bite else SEEN_X, SPAWN_Y))
		var hurtbox: Hurtbox = _hurtbox_of(man)
		var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, [], bite)
		if bite:
			_lunge_of(demon).chance_per_second = NO_CHANCE
		var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
		var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
		hurtbox.start_invulnerability(INVULNERABLE_TIME)
		var chased_on: bool = true
		var hitbox_on: bool = false
		while true:
			await physics_frame
			if not hurtbox.is_invulnerable():
				break
			chased_on = chased_on and demon.get_state() == Demon.State.CHASE
			hitbox_on = hitbox_on or hitbox.is_active()
		await _clear([ground, man, demon])
		passed = report(warned and chased_on and not hitbox_on,
				"Warning of the %s when the man turns invulnerable: warned %s, chased on from that frame until he was not %s, Hitbox on %s"
				% ["bite" if bite else "lunge", warned, chased_on, hitbox_on]) and passed
	return passed


## With Retreat Distance, while the man is invulnerable: a demon coming at him stops that far from
## him, and one nearer steps back to it, no faster than Retreat Speed, both facing him (ADR 0025).
## It gets Retreat Distance once it is on the floor, and so is watched from where it is then.
func _while_the_man_is_invulnerable_it_keeps_retreat_distance_from_him() -> bool:
	var passed: bool = true
	for man_x: float in [SEEN_X, BITE_X]:
		var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
		var man: Player = await spawn_on_floor(Vector2(man_x, SPAWN_Y))
		var hurtbox: Hurtbox = _hurtbox_of(man)
		hurtbox.start_invulnerability(INVULNERABLE_TIME)
		var demon: Demon = await _spawn_demon(0.0)
		_make_it_back_off(demon)
		var gap: float = man.position.x - demon.position.x
		var nearest_allowed: float = minf(gap, RETREAT_DISTANCE)
		var nearest: float = INF
		var fastest_back: float = 0.0
		var faced_him: bool = true
		while true:
			await physics_frame
			if not hurtbox.is_invulnerable():
				break
			gap = man.position.x - demon.position.x
			nearest = minf(nearest, gap)
			fastest_back = maxf(fastest_back, -demon.velocity.x)
			faced_him = faced_him and demon.get_facing() == signf(gap)
		await _clear([ground, man, demon])
		passed = report(nearest >= nearest_allowed - TOLERANCE
				and absf(gap - RETREAT_DISTANCE) <= TOLERANCE
				and fastest_back <= RETREAT_SPEED + TOLERANCE and faced_him,
				"Man invulnerable %.0f px from the demon: at the nearest %.1f px (no nearer than %.0f), %.1f px at the end (Retreat Distance %d), backed off at up to %.1f px/s (Retreat Speed %d), facing him %s"
				% [man_x, nearest, nearest_allowed, gap, RETREAT_DISTANCE, fastest_back,
				RETREAT_SPEED, faced_him]) and passed
	return passed


## With the man's SP low, the bite grabs him. The demon holds on in GRAB while he is held: still,
## with its Hitbox off and no warning, past the bite's Recover Time. Once he presses his way free,
## it is thrown off.
func _its_bite_that_grabs_holds_on_with_no_attack_until_the_man_breaks_free() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await _man_a_bite_grabs()
	var escape: GrabEscape = _escape_of(man)
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	_make_it_back_off(demon)
	var grabbed: bool = await _is_in_state_within(demon, Demon.State.GRAB, MAX_FRAMES)
	var held: bool = escape.is_held()
	var start_x: float = demon.position.x
	var warnings: int = warned_of.size()
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var on_frames: Array[int] = await _frames_with_hitbox_on(hitbox, FRAMES_TO_WATCH)
	var held_on: bool = (demon.get_state() == Demon.State.GRAB and escape.is_held()
			and absf(demon.position.x - start_x) <= STILL_TOLERANCE)
	var attacked: bool = not on_frames.is_empty() or warned_of.size() != warnings
	await _press_until_free(man)
	var after_grab: int = _index_after(changes, Demon.State.GRAB)
	var thrown: bool = (not escape.is_held() and after_grab != NEVER_REACHED
			and changes[after_grab].x == Demon.State.THROWN)
	await _clear([ground, man, demon])
	return report(grabbed and held and held_on and not attacked and thrown,
			"Bite at low SP: demon in GRAB %s, man held %s; %d frames later still holding on, still %s, Hitbox on %d frames, new warnings %d; free, then %s"
			% [grabbed, held, FRAMES_TO_WATCH, held_on, on_frames.size(),
			warned_of.size() - warnings, _names_of(changes)])


## With the man's SP low and a demon on each side of him, the first bite grabs him and the other's,
## landing while he is held, joins the grab, so both hold on in GRAB. Once he presses his way free,
## both are thrown off, each away from him, to its own side.
func _a_second_demon_s_bite_joins_the_grab_and_both_are_thrown_off_once_he_is_free() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await _man_a_bite_grabs()
	var escape: GrabEscape = _escape_of(man)
	var left_changes: Array[Vector2i] = []
	var right_changes: Array[Vector2i] = []
	var left: Demon = await _spawn_demon(0.0, LUNGE_RANGE, left_changes, true)
	var right: Demon = await _spawn_demon(2.0 * BITE_X, LUNGE_RANGE, right_changes, true)
	_make_it_back_off(left)
	_make_it_back_off(right)
	var both_hold_on: bool = await wait_until(func() -> bool:
			return left.get_state() == Demon.State.GRAB and right.get_state() == Demon.State.GRAB,
			MAX_FRAMES)
	var held: bool = escape.is_held()
	var left_held_x: float = left.position.x
	var right_held_x: float = right.position.x
	await _press_until_free(man)
	await wait_until(func() -> bool:
			return left.get_state() != Demon.State.THROWN and right.get_state() != Demon.State.THROWN,
			MAX_FRAMES)
	var left_after: int = _index_after(left_changes, Demon.State.GRAB)
	var right_after: int = _index_after(right_changes, Demon.State.GRAB)
	var both_thrown: bool = (not escape.is_held()
			and left_after != NEVER_REACHED and left_changes[left_after].x == Demon.State.THROWN
			and right_after != NEVER_REACHED and right_changes[right_after].x == Demon.State.THROWN)
	var left_thrown: float = left.position.x - left_held_x
	var right_thrown: float = right.position.x - right_held_x
	await _clear([ground, man, left, right])
	return report(both_hold_on and held and both_thrown and left_thrown < 0.0 and right_thrown > 0.0,
			"A demon on each side of a man at low SP: both in GRAB %s, man held %s; free, the left %s, thrown %.1f px, and the right %s, thrown %.1f px"
			% [both_hold_on, held, _names_of(left_changes), left_thrown, _names_of(right_changes),
			right_thrown])


## With the man's SP low, a demon on each side of him grabs him, so GrabRules.MAX_DEMONS hold him,
## and a third, which only bites, comes from SEEN_X past him. While he is held it never warns nor
## holds him, its Hitbox stays off, and it comes no nearer to him than Retreat Distance and stays
## there, as while he is invulnerable (ADR 0029).
func _a_third_demon_keeps_retreat_distance_from_a_man_held_by_the_most() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await _man_a_bite_grabs()
	var escape: GrabEscape = _escape_of(man)
	var third_changes: Array[Vector2i] = []
	var demons: Array[Demon] = [await _spawn_demon(0.0, LUNGE_RANGE, [], true),
			await _spawn_demon(2.0 * BITE_X, LUNGE_RANGE, [], true),
			await _spawn_demon(BITE_X + SEEN_X, LUNGE_RANGE, third_changes, true)]
	for demon: Demon in demons:
		_make_it_back_off(demon)
	var third: Demon = demons[2]
	_lunge_of(third).chance_per_second = NO_CHANCE
	var full: bool = await wait_until(func() -> bool:
			return (demons[0].get_state() == Demon.State.GRAB
					and demons[1].get_state() == Demon.State.GRAB),
			MAX_FRAMES)
	var changes_when_full: int = third_changes.size()
	var hitbox: Hitbox = third.get_node(^"Hitbox") as Hitbox
	var nearest: float = INF
	var hitbox_on: bool = false
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		nearest = minf(nearest, third.position.x - man.position.x)
		hitbox_on = hitbox_on or hitbox.is_active()
	var held: bool = escape.is_held()
	var gap: float = third.position.x - man.position.x
	var attacked: bool = third_changes.slice(changes_when_full).any(func(change: Vector2i) -> bool:
			return change.x == Demon.State.WARNING or change.x == Demon.State.GRAB)
	await _clear([ground, man, demons[0], demons[1], third])
	return report(full and held and not attacked and not hitbox_on
			and nearest >= RETREAT_DISTANCE - TOLERANCE
			and absf(gap - RETREAT_DISTANCE) <= TOLERANCE,
			"Two demons hold the man, in GRAB %s, held %s; a third, from %.0f px past him, over %d frames: warned or grabbed %s, Hitbox on %s, at the nearest %.1f px, %.1f px at the end (Retreat Distance %d)"
			% [full, held, SEEN_X, FRAMES_TO_WATCH, attacked, hitbox_on, nearest, gap,
			RETREAT_DISTANCE])


## Thrown off as the man breaks free, the demon flies away from him, facing him, with its Hitbox
## off, peaks Throw Height above the floor, lands Throw Distance from where it held him, and from
## there chases him again or backs off.
func _thrown_off_it_peaks_at_throw_height_and_lands_throw_distance_away() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await _man_a_bite_grabs()
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true)
	_make_it_back_off(demon)
	demon.stats.throw_distance = THROW_DISTANCE
	demon.stats.throw_height = THROW_HEIGHT
	demon.stats.throw_time_to_peak = THROW_TIME_TO_PEAK
	var grabbed: bool = await _is_in_state_within(demon, Demon.State.GRAB, MAX_FRAMES)
	var held_x: float = demon.position.x
	var floor_y: float = demon.position.y
	var facing: float = demon.get_facing()
	await _press_until_free(man)
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var highest: float = floor_y
	var hitbox_on: bool = false
	var faced_him: bool = true
	for _frame: int in MAX_FRAMES:
		if demon.get_state() != Demon.State.THROWN:
			break
		await physics_frame
		highest = minf(highest, demon.position.y)
		hitbox_on = hitbox_on or hitbox.is_active()
		faced_him = faced_him and demon.get_facing() == facing
	var height: float = floor_y - highest
	var distance: float = absf(demon.position.x - held_x)
	var away: bool = signf(held_x - demon.position.x) == facing
	var after: int = _index_after(changes, Demon.State.THROWN)
	var then: bool = after != NEVER_REACHED and (changes[after].x == Demon.State.CHASE
			or changes[after].x == Demon.State.RETREAT)
	await _clear([ground, man, demon])
	return report(grabbed and absf(height - THROW_HEIGHT) <= HEIGHT_TOLERANCE
			and absf(distance - THROW_DISTANCE) <= TOLERANCE and away and faced_him
			and not hitbox_on and then,
			"Thrown off: peaked %.2f px up (Throw Height %d), landed %.1f px away (Throw Distance %d), away from the man %s, facing him %s, Hitbox on %s; %s"
			% [height, THROW_HEIGHT, distance, THROW_DISTANCE, away, faced_him, hitbox_on,
			_names_of(changes)])


## Thrown off as the man breaks free, with Stunned Time, the demon lies stunned once it lands, for
## Stunned Time: still, with its Hitbox off and no warning, its drawing flatter than in either
## warning and darker than its own, so the shape tells it apart; then it backs off from him or
## chases him again, back in its own shape (ADR 0028).
func _thrown_off_by_the_man_it_lies_stunned_for_stunned_time() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await _man_a_bite_grabs()
	var changes: Array[Vector2i] = []
	var warned_of: Array[DemonAttack] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes, true, warned_of)
	_make_it_back_off(demon)
	demon.stats.stunned_time = STUNNED_TIME
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var hitbox: Hitbox = demon.get_node(^"Hitbox") as Hitbox
	var grabbed: bool = await _is_in_state_within(demon, Demon.State.GRAB, MAX_FRAMES)
	await _press_until_free(man)
	var stunned: bool = await _is_in_state_within(demon, Demon.State.STUNNED, MAX_FRAMES)
	var on_floor: bool = demon.is_on_floor()
	var landed_x: float = demon.position.x
	var look: Vector2 = placeholder.scale
	var stunned_color: Color = placeholder.color
	var warnings: int = warned_of.size()
	var drift: float = 0.0
	var hitbox_on: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if demon.get_state() != Demon.State.STUNNED:
			break
		drift = maxf(drift, absf(demon.position.x - landed_x))
		hitbox_on = hitbox_on or hitbox.is_active()
	var warned: bool = warned_of.size() != warnings
	var back_in_shape: bool = placeholder.scale == Vector2.ONE
	var darker: bool = stunned_color.get_luminance() < placeholder.color.get_luminance()
	var flatter: bool = (look.x > 1.0 and look.y < (placeholder.get(&"warning_squash") as float)
			and look.y < (placeholder.get(&"bite_warning_scale") as Vector2).y)
	var stunned_frames: int = demon.stats.get_stunned_frames()
	await _clear([ground, man, demon])
	var landing: int = _index_after(changes, Demon.State.THROWN)
	var after: int = _index_after(changes, Demon.State.STUNNED)
	var kept_still: int = changes[after].y - changes[landing].y \
			if landing != NEVER_REACHED and after != NEVER_REACHED else NEVER_REACHED
	var then: bool = after != NEVER_REACHED and (changes[after].x == Demon.State.CHASE
			or changes[after].x == Demon.State.RETREAT)
	return report(grabbed and stunned and on_floor and kept_still == stunned_frames
			and drift < STILL_TOLERANCE and not hitbox_on and not warned and flatter and darker
			and back_in_shape and then,
			"Thrown off by the man with Stunned Time %.1f s: %s; on the floor %s, stunned for %d frames of %d, moved %.2f px, Hitbox on %s, warned %s; %.2f wide and %.2f high, darker %s, back in shape after %s"
			% [STUNNED_TIME, _names_of(changes), on_floor, kept_still, stunned_frames, drift,
			hitbox_on, warned, look.x, look.y, darker, back_in_shape])


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


## The demon chases the man inside the crucifix's radius, and he holds it up: the touch is a hit
## (ADR 0021), so the crucifix throws the demon off, away from it, as the man does when he breaks
## free of a grab. It starts inside the radius, so the crucifix goes on pushing it in the first
## frames of the throw, and that does not start the throw again: it is thrown once and peaks at
## Throw Height. Once it lands, out of the radius, it stays still for Repelled Time and then chases
## again.
func _the_raised_crucifix_throws_it_off_and_on_landing_it_stays_still_for_repelled_time() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(REPEL_START_X, NO_LUNGE, changes)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var floor_y: float = demon.position.y
	var pushes: Array[int] = [0]
	(demon.get_node(^"Repellable") as Repellable).repelled.connect(
			func(_origin: Vector2) -> void: pushes[0] += 1)
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var thrown: bool = await _is_in_state_within(demon, Demon.State.THROWN, FRAMES_TO_WATCH)
	var highest: float = floor_y
	for _frame: int in FRAMES_TO_WATCH:
		if demon.get_state() != Demon.State.THROWN:
			break
		await physics_frame
		highest = minf(highest, demon.position.y)
	var landed: bool = demon.get_state() == Demon.State.REPELLED and demon.is_on_floor()
	var landed_x: float = demon.position.x
	var freed: bool = await wait_until(
			func() -> bool: return demon.get_state() != Demon.State.REPELLED, FRAMES_TO_WATCH)
	var out_at: float = demon.position.x - man.position.x
	var drift: float = absf(demon.position.x - landed_x)
	var height: float = floor_y - highest
	var throw_height: float = demon.stats.throw_height
	var still_up: bool = crucifix.is_raised()
	var radius: float = crucifix.stats.repel_radius
	var repelled_frames: int = demon.stats.get_repelled_frames()
	await _clear([ground, man, demon])
	var landing: int = _index_after(changes, Demon.State.THROWN)
	var after: int = _index_after(changes, Demon.State.REPELLED)
	var kept_still: int = changes[after].y - changes[landing].y \
			if landing != NEVER_REACHED and after != NEVER_REACHED else NEVER_REACHED
	return report(chased and still_up and thrown and landed and freed and out_at >= radius
			and absf(height - throw_height) <= HEIGHT_TOLERANCE
			and drift < STILL_TOLERANCE and kept_still == repelled_frames
			and _names_of(changes) == "CHASE > THROWN > REPELLED > CHASE",
			"Inside the raised crucifix's %d px: %s, pushed %d times; peaked %.2f px up (Throw Height %d), landed %s %.1f px out; still for %d frames of %d after landing, moved %.2f px"
			% [radius, _names_of(changes), pushes[0], height, throw_height, landed, out_at,
			kept_still, repelled_frames, drift])


## The game pauses while the demon is repelled, after the crucifix threw it off: the paused frames
## do not count, so once the game goes on, the demon stays still for the rest of Repelled Time, as
## long as with no pause.
func _a_pause_while_it_is_repelled_does_not_count() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(REPEL_START_X, NO_LUNGE, changes)
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	await _raise_crucifix_of(man)
	var repelled: bool = await _is_in_state_within(demon, Demon.State.REPELLED, FRAMES_TO_WATCH)
	var landed_frame: int = Engine.get_physics_frames()
	await wait_until(func() -> bool:
			return Engine.get_physics_frames() - landed_frame >= LANDED_BEFORE_PAUSE)
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
	var landing: int = _index_after(changes, Demon.State.THROWN)
	var after: int = _index_after(changes, Demon.State.REPELLED)
	var kept_still: int = changes[after].y - changes[landing].y - paused_frames \
			if landing != NEVER_REACHED and after != NEVER_REACHED else NEVER_REACHED
	return report(chased and repelled and repelled_at_pause and freed
			and kept_still == repelled_frames,
			"Paused %d frames while repelled (still repelled then %s): still for %d frames of %d after landing, not counting the pause"
			% [paused_frames, repelled_at_pause, kept_still, repelled_frames])


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
## into it: the crucifix throws it off in the air, it lands repelled, and its middle never gets
## inside the radius.
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
	var in_order: bool = _names_of(changes) == "CHASE > WARNING > LUNGE > THROWN > REPELLED"
	return report(lunged and in_order and landed_repelled and nearest > radius,
			"Lunging at the raised crucifix: %s; landed repelled %s; nearest %.1f px (radius %d)"
			% [_names_of(changes), landed_repelled, nearest, radius])


## A quick lunge into the raised crucifix, thrown off on the way up: in the air the throw only goes
## across, so the demon goes no higher than Lunge Height, and a step of one tile stops it also when
## the crucifix cuts its lunge short.
func _thrown_off_in_a_quick_lunge_it_goes_no_higher_than_lunge_height() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	await _raise_crucifix_of(man)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(SEEN_X, LUNGE_RANGE, changes)
	_lunge_of(demon).lunge_time_to_peak = QUICK_LUNGE_TIME_TO_PEAK
	var warned: bool = await _is_in_state_within(demon, Demon.State.WARNING, MAX_FRAMES)
	var take_off_y: float = demon.position.y
	var peak_y: float = take_off_y
	var thrown_in_the_air: bool = false
	for _frame: int in FRAMES_TO_WATCH:
		peak_y = minf(peak_y, demon.position.y)
		if demon.get_state() == Demon.State.THROWN:
			thrown_in_the_air = thrown_in_the_air or not demon.is_on_floor()
		elif demon.get_state() == Demon.State.REPELLED and demon.is_on_floor():
			break
		await physics_frame
	var landed_repelled: bool = demon.get_state() == Demon.State.REPELLED and demon.is_on_floor()
	var height: float = take_off_y - peak_y
	await _clear([ground, man, demon])
	return report(warned and thrown_in_the_air and landed_repelled
			and height <= LUNGE_HEIGHT + HEIGHT_TOLERANCE,
			"Quick lunge thrown off in the air (%s): %.2f px up (at most %d), landed repelled %s; %s"
			% [thrown_in_the_air, height, LUNGE_HEIGHT, landed_repelled, _names_of(changes)])


## The values that go into the game, in lust_demon_stats.tres, keep what the levels are drawn for:
## the demon has attacks, each with one of the art's animations and a Chance Per Second from 0 to 1
## (the file is not held to the Inspector's range, and past 1 the chance is no number, so the attack
## never comes), a step of one tile stops every lunge and keeps a man on it safe, the demon loses
## the man only past where it sees him, and it chases slower than he runs, so running away works. A
## tuning that breaks one of these fails here, before it gets into a level.
func _the_level_s_values_keep_what_the_levels_count_on() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var man_stats: PlayerMovementStats = load(PLAYER_MOVEMENT_STATS) as PlayerMovementStats
	var highest: float = 0.0
	var most_height_difference: float = 0.0
	var all_known: bool = true
	var all_chances: bool = true
	for attack: DemonAttack in demon_stats.attacks:
		highest = maxf(highest, attack.lunge_height)
		most_height_difference = maxf(most_height_difference, attack.max_height_difference)
		all_known = all_known and attack.animation in DemonAttack.ANIMATIONS
		all_chances = all_chances and attack.chance_per_second >= 0.0 \
				and attack.chance_per_second <= 1.0
	var below_a_step: bool = not demon_stats.attacks.is_empty() and highest < TILE \
			and most_height_difference < TILE
	var loses_past_sight: bool = demon_stats.lose_distance > demon_stats.sight_distance
	var slower: bool = demon_stats.chase_speed < man_stats.max_run_speed
	return report(below_a_step and all_known and all_chances and loses_past_sight and slower,
			"Level values: attacks %s (all with known animations %s, all with chances from 0 to 1 %s), lunging at most %d px up, at men up to %d px higher (a step is %d); loses him at %d px, sees him at %d; chases at %d px/s, he runs at %d"
			% [_animations_of(demon_stats.attacks), all_known, all_chances, highest,
					most_height_difference, TILE, demon_stats.lose_distance,
					demon_stats.sight_distance, demon_stats.chase_speed, man_stats.max_run_speed])


## The level's demons are thrown no higher than a step of one tile, so a throw never lands one on a
## step it could not climb.
func _the_level_s_throw_never_lands_a_demon_on_a_step() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	return report(demon_stats.throw_height < TILE,
			"Level values: thrown %d px up at most (a step is %d)" % [demon_stats.throw_height, TILE])


## The level's demons chase only on the screen, give up only some way off it (ADR 0038), see the man
## from anywhere on it to its middle, see less behind them than ahead, and walk back to their post
## slower than they chase, so a demon going back never reads as one coming at him (ADR 0032).
func _the_level_s_demons_chase_on_screen_and_walk_back_slower_than_they_chase() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var half_screen: float = ProjectSettings.get_setting("display/window/size/viewport_width") / 2.0
	var walks_back: bool = demon_stats.return_speed > 0.0 \
			and demon_stats.return_speed < demon_stats.chase_speed
	return report(demon_stats.chases_only_on_screen and demon_stats.screen_margin > 0.0
			and demon_stats.sight_distance >= half_screen
			and demon_stats.sight_behind_share < 1.0 and walks_back,
			"Level values: only on the screen %s, give up %d px off it, sees %d px (half the screen is %d), %.2f of it behind; walks back at %d px/s, chases at %d"
			% [demon_stats.chases_only_on_screen, demon_stats.screen_margin,
					demon_stats.sight_distance, half_screen, demon_stats.sight_behind_share,
					demon_stats.return_speed, demon_stats.chase_speed])


## The level's demons patrol, slower than they chase, so a demon is never found standing as if
## switched off, and a man on a step of one tile is out of their reach, so the step is a safe spot
## (ADR 0033); they wait for him there a while before they give up.
func _the_level_s_demons_patrol_and_leave_a_man_on_a_step_out_of_reach() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var patrols: bool = demon_stats.patrol_width > 0.0 and demon_stats.patrol_speed > 0.0 \
			and demon_stats.patrol_speed < demon_stats.chase_speed \
			and demon_stats.patrol_pause_min <= demon_stats.patrol_pause_max
	return report(patrols and demon_stats.get_reach_height() < TILE
			and demon_stats.out_of_reach_wait > 0.0,
			"Level values: patrol of %d px at %d px/s (chases at %d), pauses %.1f to %.1f s; reach %d px (a step is %d), waits %.1f s out of reach"
			% [demon_stats.patrol_width, demon_stats.patrol_speed, demon_stats.chase_speed,
					demon_stats.patrol_pause_min, demon_stats.patrol_pause_max,
					demon_stats.get_reach_height(), TILE, demon_stats.out_of_reach_wait])


## The level's demons pace out of reach, with their pauses in order, and bark at least twice before
## they give up, even with the longest first pause (ADR 0039): once as it ends, and again at the end
## of the half of the stretch they walk first.
func _the_level_s_demons_pace_and_bark_out_of_reach_before_they_give_up() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var second_bark: float = demon_stats.out_of_reach_pause_max \
			+ demon_stats.out_of_reach_pace_width / 2.0 / demon_stats.patrol_speed
	return report(demon_stats.out_of_reach_pace_width > 0.0
			and demon_stats.out_of_reach_pause_min <= demon_stats.out_of_reach_pause_max
			and second_bark < demon_stats.out_of_reach_wait,
			"Level values: paces %d px out of reach, pauses %.1f to %.1f s, second bark by %.2f s, waits %.1f s"
			% [demon_stats.out_of_reach_pace_width, demon_stats.out_of_reach_pause_min,
					demon_stats.out_of_reach_pause_max, second_bark,
					demon_stats.out_of_reach_wait])


## The level's demons are alerted before each chase, so the player sees it coming, and once a wall
## hides the man they go where they last saw him sooner than they sniff there, slower than they
## chase, so the hunt for him shows instead of a chase that knows where he is (ADR 0035).
func _the_level_s_demons_are_alerted_and_search_before_they_give_up() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	return report(demon_stats.alert_time > 0.0
			and demon_stats.give_up_time < demon_stats.search_time
			and demon_stats.search_speed < demon_stats.chase_speed,
			"Level values: alerted %.2f s; blind %.1f s, then sniffs %.1f s; searches at %d px/s, chases at %d"
			% [demon_stats.alert_time, demon_stats.give_up_time, demon_stats.search_time,
					demon_stats.search_speed, demon_stats.chase_speed])


## The level's demons back off after each attack (ADR 0023): past the Attack Range of every bite on
## the run, so they have to come back to bite again, and slower than they chase, so it reads as
## backing off.
func _the_level_s_demons_back_off_past_bite_range_slower_than_they_chase() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var farthest_bite: float = 0.0
	for attack: DemonAttack in demon_stats.attacks:
		if attack.keeps_chasing:
			farthest_bite = maxf(farthest_bite, attack.attack_range)
	var past_bites: bool = demon_stats.retreat_distance > farthest_bite
	var slower: bool = demon_stats.retreat_speed < demon_stats.chase_speed
	return report(past_bites and slower,
			"Level values: backs off to %d px (bites reach %d px), at %d px/s (chases at %d)"
			% [demon_stats.retreat_distance, farthest_bite, demon_stats.retreat_speed,
					demon_stats.chase_speed])


## The level's demons keep their distance from each other and are each a little different (ADR
## 0024), and the slowest and fastest of them still keep what the levels count on: the fastest chase
## is slower than the man runs, the shortest retreat goes past every bite's Attack Range, and the
## fastest retreat is slower than the slowest chase.
func _the_level_s_demons_keep_it_at_both_ends_of_pack_variation() -> bool:
	var demon_stats: DemonStats = load(LUST_DEMON_STATS) as DemonStats
	var man_stats: PlayerMovementStats = load(PLAYER_MOVEMENT_STATS) as PlayerMovementStats
	var lowest: float = 1.0 - demon_stats.pack_variation
	var highest: float = 1.0 + demon_stats.pack_variation
	var farthest_bite: float = 0.0
	for attack: DemonAttack in demon_stats.attacks:
		if attack.keeps_chasing:
			farthest_bite = maxf(farthest_bite, attack.attack_range)
	var in_a_pack: bool = demon_stats.pack_spacing > 0.0 and demon_stats.pack_variation > 0.0
	var still_kept: bool = (demon_stats.chase_speed * highest < man_stats.max_run_speed
			and demon_stats.retreat_distance * lowest > farthest_bite
			and demon_stats.retreat_speed * highest < demon_stats.chase_speed * lowest)
	return report(in_a_pack and still_kept,
			"Level values with Pack Spacing %d and Pack Variation %.2f: chases at up to %.0f px/s (he runs at %d), backs off to at least %.0f px (bites reach %d), at up to %.0f px/s (chases at least at %.0f)"
			% [demon_stats.pack_spacing, demon_stats.pack_variation,
					demon_stats.chase_speed * highest, man_stats.max_run_speed,
					demon_stats.retreat_distance * lowest, farthest_bite,
					demon_stats.retreat_speed * highest, demon_stats.chase_speed * lowest])


## The man, behind a wall, holds up his crucifix with the demon inside its radius: the demon, which
## never saw him, is thrown off and repelled, and then goes back to standing instead of chasing.
func _repelled_before_it_saw_the_man_it_goes_back_to_standing() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_REPEL_WALL_X, HIDING_REPEL_WALL_X + WALL_THICKNESS,
			WALL_TOP)
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(REPEL_START_X + WALL_THICKNESS, LUNGE_RANGE, changes)
	var crucifix: Crucifix = await _raise_crucifix_of(man)
	var raised: bool = crucifix.is_raised()
	await wait_until(func() -> bool: return changes.size() >= 3, FRAMES_TO_WATCH)
	await _clear([ground, wall, man, demon])
	return report(raised and _names_of(changes) == "THROWN > REPELLED > IDLE",
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


## A wall that hides the man's middle but not his head: the demon sees him and chases him. The case
## also checks that the wall does hide his middle from the demon's eyes, so it does not pass on the
## middle alone.
func _sees_the_man_s_head_over_a_low_wall() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(WALL_X, WALL_X + WALL_THICKNESS, LOW_WALL_TOP)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var eyes: Vector2 = (demon.get_node(^"LineOfSight") as Node2D).global_position
	var middle: Vector2 = man.global_position + eyes - demon.global_position
	var middle_hidden: bool = not root.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(eyes, middle, _bit_of(WORLD_LAYER_NAME))).is_empty()
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, wall, man, demon])
	return report(middle_hidden and chased,
			"Behind a wall %d px high: his middle hidden %s, head above it, chased %s"
			% [-LOW_WALL_TOP, middle_hidden, chased])


## With Sight Behind Share, a demon facing either way does not see the man SEEN_X behind it, and
## sees him SEEN_X ahead.
func _sees_behind_it_only_its_behind_share() -> bool:
	var right: Array[bool] = await _chases_behind_and_ahead(false)
	var left: Array[bool] = await _chases_behind_and_ahead(true)
	return report(not right[0] and right[1] and not left[0] and left[1],
			"%d px behind and ahead, seeing %d px behind: facing right chased %s and %s; facing left %s and %s"
			% [SEEN_X, SIGHT_DISTANCE * BEHIND_SHARE, right[0], right[1], left[0], left[1]])


## With Chases Only On Screen, a demon off the screen does not chase the man it sees, and chases him
## once the screen takes it in.
func _starts_no_chase_off_the_screen() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.chases_only_on_screen = true
	var camera: Camera2D = _make_camera(_screen_width())
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased_off: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	camera.position.x = 0.0
	var chased_on: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, man, demon, camera])
	return report(not chased_off and chased_on,
			"Man seen, demon off the screen: chased %s; on it: chased %s" % [chased_off, chased_on])


## With Chases Only On Screen, a demon that chases the man gives up as soon as the screen leaves it,
## though it still sees him, and does not chase him again while it is off the screen.
func _gives_up_once_it_is_off_the_screen() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.chases_only_on_screen = true
	var camera: Camera2D = _make_camera(0.0)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	camera.position.x = 2.0 * _screen_width()
	var gave_up: bool = await _is_in_state_within(demon, Demon.State.IDLE, SETTLE_FRAMES)
	var chased_again: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, man, demon, camera])
	return report(chased and gave_up and not chased_again,
			"Chasing, then off the screen: gave up %s, chased again %s" % [gave_up, chased_again])


## With Chases Only On Screen and Screen Margin, a demon that chases the man keeps on just off the
## screen, inside Screen Margin, and gives up past it. Back inside Screen Margin but still off the
## screen, it does not chase him again; on the screen, it does (ADR 0038).
func _keeps_chasing_inside_screen_margin_and_starts_only_on_the_screen() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.chases_only_on_screen = true
	demon.stats.screen_margin = SCREEN_MARGIN
	var camera: Camera2D = _make_camera(0.0)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await wait_until(
			func() -> bool: return absf(man.position.x - demon.position.x) <= STILL_TOLERANCE,
			FRAMES_TO_WATCH)
	var inside_margin: float = demon.position.x + _half_width(demon) + SCREEN_MARGIN / 2.0 \
			+ _screen_width() / 2.0
	camera.position.x = inside_margin
	var gave_up_inside: bool = await _is_in_state_within(demon, Demon.State.IDLE, FRAMES_TO_WATCH)
	camera.position.x = inside_margin + SCREEN_MARGIN
	var gave_up_past: bool = await _is_in_state_within(demon, Demon.State.IDLE, SETTLE_FRAMES)
	camera.position.x = inside_margin
	var chased_inside: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	camera.position.x = 0.0
	var chased_on: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, man, demon, camera])
	return report(chased and not gave_up_inside and gave_up_past and not chased_inside and chased_on,
			"Screen Margin %d: chasing, then off the screen inside it: gave up %s; past it: gave up %s; back inside it: chased %s; on the screen: chased %s"
			% [SCREEN_MARGIN, gave_up_inside, gave_up_past, chased_inside, chased_on])


## With Return Speed, a demon put facing left that gives up on a man on its left walks back to its
## post at Return Speed, facing right, the way it walks, and stands there once it is back, facing
## left again, the way it was put.
func _walks_back_to_its_post_at_return_speed_once_it_gives_up() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, [], false, [], true)
	demon.stats.return_speed = RETURN_SPEED
	var post_x: float = demon.position.x
	var man: Player = await spawn_on_floor(Vector2(-SEEN_X, SPAWN_Y))
	var got_away: bool = await wait_until(
			func() -> bool: return demon.position.x < post_x - AWAY_FROM_POST)
	await remove_player(man)
	var returning: bool = await _is_in_state_within(demon, Demon.State.RETURN, SETTLE_FRAMES)
	var start_x: float = demon.position.x
	await wait_frames(RETURN_MEASURE_FRAMES)
	var speed: float = (demon.position.x - start_x) * Engine.physics_ticks_per_second \
			/ RETURN_MEASURE_FRAMES
	var walking_facing: float = demon.get_facing()
	var back: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var off_post: float = absf(demon.position.x - post_x)
	var facing: float = demon.get_facing()
	await _clear([ground, demon])
	return report(got_away and returning and absf(speed - RETURN_SPEED) <= SPEED_TOLERANCE
			and walking_facing > 0.0 and back and off_post <= TOLERANCE and facing < 0.0,
			"Gave up %s px from its post: returning %s at %.1f px/s, facing %d; back %s, %.1f px off, facing %d"
			% [AWAY_FROM_POST, returning, speed, walking_facing, back, off_post, facing])


## A demon walking back to its post chases the man again as soon as it sees him ahead of it.
func _walking_back_it_chases_a_man_it_sees_ahead() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.return_speed = RETURN_SPEED
	demon.stats.sight_behind_share = BEHIND_SHARE
	var post_x: float = demon.position.x
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	await wait_until(func() -> bool: return demon.position.x > post_x + AWAY_FROM_POST)
	await remove_player(man)
	var returning: bool = await _is_in_state_within(demon, Demon.State.RETURN, SETTLE_FRAMES)
	var ahead: Player = await spawn_on_floor(Vector2(demon.position.x - SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, ahead, demon])
	return report(returning and chased,
			"Walking back %s, the man %d px ahead: chased %s" % [returning, SEEN_X, chased])


## A demon on another floor than its post's, as a throw can leave it, walks back as far as its floor
## goes, stops at the edge and stays there (ADR 0032), standing there for now, with its post where
## the level put it (ADR 0043).
func _on_another_floor_it_stays_where_its_floor_stops_it_and_keeps_its_post() -> bool:
	var upper: StaticBody2D = make_platform(FLOOR_LEFT, UPPER_FLOOR_RIGHT)
	var lower: StaticBody2D = make_platform(LOWER_FLOOR_LEFT, FLOOR_RIGHT, LOWER_FLOOR_DROP)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	demon.position = Vector2(LOWER_START_X, LOWER_FLOOR_DROP + SPAWN_Y)
	await wait_frames(SETTLE_FRAMES)
	await wait_until(demon.is_on_floor)
	var man: Player = await spawn_on_floor(
			Vector2(LOWER_START_X + SEEN_X, LOWER_FLOOR_DROP + SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await remove_player(man)
	var stopped: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var front: float = demon.position.x - _half_width(demon)
	var stop_x: float = demon.position.x
	await wait_frames(FRAMES_TO_WATCH)
	var moved: float = absf(demon.position.x - stop_x)
	var state: Demon.State = demon.get_state()
	var kept: bool = demon.get_post().is_equal_approx(post)
	var stands: float = demon.get_stand_x()
	await _clear([upper, lower, demon])
	var at_the_edge: bool = front >= LOWER_FLOOR_LEFT and front < LOWER_FLOOR_LEFT + TOLERANCE
	return report(chased and stopped and at_the_edge and moved < STILL_TOLERANCE
			and state == Demon.State.IDLE and kept and absf(stands - stop_x) < STILL_TOLERANCE,
			"Post on the floor above, edge at x = %d: stopped %s, front at %.1f, then moved %.2f px, %s; post kept %s, stands at x = %.1f"
			% [LOWER_FLOOR_LEFT, stopped, front, moved, _name_of(state), kept, stands])


## A wall put between a demon and its post while it chases: walking back, it stops against the wall
## and stays there, standing there for now, with its post where the level put it (ADR 0043).
func _a_wall_on_the_way_back_stops_it_there_and_it_keeps_its_post() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	await wait_until(func() -> bool: return demon.position.x > AWAY_FROM_POST)
	var wall: StaticBody2D = make_wall(RETURN_WALL_X - WALL_THICKNESS, RETURN_WALL_X, WALL_TOP)
	await remove_player(man)
	var stopped: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var front: float = demon.position.x - _half_width(demon)
	var stop_x: float = demon.position.x
	await wait_frames(FRAMES_TO_WATCH)
	var moved: float = absf(demon.position.x - stop_x)
	var state: Demon.State = demon.get_state()
	var kept: bool = demon.get_post().is_equal_approx(post)
	var stands: float = demon.get_stand_x()
	await _clear([ground, wall, demon])
	var at_the_wall: bool = absf(front - RETURN_WALL_X) < TOLERANCE
	return report(stopped and at_the_wall and moved < STILL_TOLERANCE and state == Demon.State.IDLE
			and kept and absf(stands - stop_x) < STILL_TOLERANCE,
			"Wall at x = %d on the way back: stopped %s, front at %.1f, then moved %.2f px, %s; post kept %s, stands at x = %.1f"
			% [RETURN_WALL_X, stopped, front, moved, _name_of(state), kept, stands])


## A demon stopped on its way back by a wall that is gone by the time it next gives up: it walks all
## the way home to its post then, and stands there.
func _with_the_wall_gone_it_walks_home_the_next_time_it_gives_up() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.return_speed = RETURN_SPEED
	var post: Vector2 = demon.get_post()
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	await wait_until(func() -> bool: return demon.position.x > AWAY_FROM_POST)
	var wall: StaticBody2D = make_wall(RETURN_WALL_X - WALL_THICKNESS, RETURN_WALL_X, WALL_TOP)
	await remove_player(man)
	var stopped: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	wall.queue_free()
	var again: Player = await spawn_on_floor(Vector2(demon.position.x + SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await remove_player(again)
	var returning: bool = await _is_in_state_within(demon, Demon.State.RETURN, SETTLE_FRAMES)
	var home: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var off_post: float = absf(demon.position.x - post.x)
	await _clear([ground, demon])
	return report(stopped and chased and returning and home and off_post <= TOLERANCE,
			"Wall gone after it stopped there: chased again %s, walking back %s, home %s, %.1f px off its post"
			% [chased, returning, home, off_post])


## With Patrol Width, a demon kept off its post on another floor patrols around where its floor
## stopped it, across all of Patrol Width that its floor lets it, instead of turning back over and
## over at the edge towards its post.
func _kept_off_its_post_it_patrols_around_where_it_stopped() -> bool:
	var upper: StaticBody2D = make_platform(FLOOR_LEFT, UPPER_FLOOR_RIGHT)
	var lower: StaticBody2D = make_platform(LOWER_FLOOR_LEFT, FLOOR_RIGHT, LOWER_FLOOR_DROP)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.stats.return_speed = RETURN_SPEED
	demon.position = Vector2(LOWER_START_X, LOWER_FLOOR_DROP + SPAWN_Y)
	await wait_frames(SETTLE_FRAMES)
	await wait_until(demon.is_on_floor)
	var man: Player = await spawn_on_floor(
			Vector2(LOWER_START_X + SEEN_X, LOWER_FLOOR_DROP + SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await remove_player(man)
	var stopped: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	_make_it_patrol(demon)
	var stop_x: float = demon.position.x
	var patrolling: bool = await _is_in_state_within(demon, Demon.State.PATROL, MAX_FRAMES)
	var farthest: float = 0.0
	for _frame: int in MAX_FRAMES:
		await physics_frame
		farthest = maxf(farthest, absf(demon.position.x - stop_x))
	await _clear([upper, lower, demon])
	return report(chased and stopped and patrolling
			and absf(farthest - PATROL_WIDTH / 2.0) <= TOLERANCE,
			"Kept off its post, stopped at x = %.1f: patrolling %s, went %.1f px from there (half Patrol Width %d)"
			% [stop_x, patrolling, farthest, PATROL_WIDTH / 2.0])


## A man on a ledge over every attack's Max Height Difference is out of the demon's reach (ADR
## 0033): the demon, put facing away from him, turns to him and stands where it is, and stays there
## while he walks along the ledge, instead of following him along under it.
func _stands_facing_a_man_out_of_its_reach_wherever_he_walks() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, [], false, [], true)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var stop_x: float = demon.position.x
	for _frame: int in WALK_FRAMES:
		man.position.x += ALONG_LEDGE / WALK_FRAMES
		await physics_frame
	var moved: float = absf(demon.position.x - stop_x)
	var state: Demon.State = demon.get_state()
	var facing: float = demon.get_facing()
	await _clear([ground, ledge, man, demon])
	return report(stopped and moved < STILL_TOLERANCE and state == Demon.State.OUT_OF_REACH
			and facing > 0.0,
			"Man %d px up: out of reach %s; he walked %d px, it moved %.2f px, %s, facing %d"
			% [HIGH_LEDGE_HEIGHT, stopped, ALONG_LEDGE, moved, _name_of(state), facing])


## The demon on a ledge two tiles up, from where it cannot get down to the man, him on the floor
## below it: he is as much out of its reach as above it, so it stands where it noticed him, facing
## him, instead of running to the edge and following him along up there.
func _stands_facing_a_man_out_of_its_reach_below_it() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(FLOOR_LEFT, HIGH_LEDGE_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.position.y -= HIGH_LEDGE_HEIGHT
	await wait_frames(SETTLE_FRAMES)
	await wait_until(demon.is_on_floor)
	var start_x: float = demon.position.x
	var man: Player = await spawn_on_floor(Vector2(BELOW_LEDGE_X, SPAWN_Y))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var moved: float = absf(demon.position.x - start_x)
	var facing: float = demon.get_facing()
	await _clear([ground, ledge, man, demon])
	return report(stopped and moved < MOVED and facing > 0.0,
			"On a ledge %d px up, the man below: out of reach %s, moved %.1f px, facing %d"
			% [HIGH_LEDGE_HEIGHT, stopped, moved, facing])


## Out of reach, the demon chases the man again as soon as he comes back down within its reach,
## already while he is still in the air.
func _out_of_reach_it_chases_again_once_the_man_comes_back_down() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var chased: bool = false
	for _frame: int in SETTLE_FRAMES:
		man.position = Vector2(-OUT_OF_REACH_X, SPAWN_Y - IN_REACH_HEIGHT)
		man.velocity = Vector2.ZERO
		await physics_frame
		chased = chased or demon.get_state() == Demon.State.CHASE
	var in_the_air: bool = not man.is_on_floor()
	await _clear([ground, ledge, man, demon])
	return report(stopped and chased and in_the_air,
			"Out of reach %s; the man held %d px up, within reach: chased %s, still in the air %s"
			% [stopped, IN_REACH_HEIGHT, chased, in_the_air])


## Out of reach for Out Of Reach Wait, the demon gives up, though it still sees the man, and walks
## back to its post.
func _out_of_reach_for_out_of_reach_wait_it_gives_up_and_walks_back() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	demon.stats.return_speed = RETURN_SPEED
	var man: Player = await spawn_on_floor(Vector2(-SEEN_X, SPAWN_Y))
	await wait_until(func() -> bool: return demon.position.x < -AWAY_FROM_POST)
	man.position = Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT)
	var returning: bool = await _is_in_state_within(demon, Demon.State.RETURN, MAX_FRAMES)
	var waited: int = _frames_in(changes, Demon.State.OUT_OF_REACH)
	await _clear([ground, ledge, man, demon])
	var wait_frames_asked: int = roundi(OUT_OF_REACH_WAIT * Engine.physics_ticks_per_second)
	return report(returning and absi(waited - wait_frames_asked) <= ONE_FRAME,
			"Out of reach, still seeing him: waited %d frames (asked %d), walking back %s"
			% [waited, wait_frames_asked, returning])


## A man who jumps on the demon's floor, over every attack's Max Height Difference, is not out of
## its reach: in the air he can only come down, so it keeps on chasing him.
func _keeps_chasing_a_man_who_jumps_on_its_floor() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position.y -= JUMP_PEAK
	await physics_frame
	var landed: bool = await wait_until_on_floor(man)
	var state: Demon.State = demon.get_state()
	var stopped: bool = changes.any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.OUT_OF_REACH)
	await _clear([ground, man, demon])
	return report(chased and landed and not stopped and state == Demon.State.CHASE,
			"Man %d px up in the air: out of reach %s, then %s" % [JUMP_PEAK, stopped,
					_name_of(state)])


## Once it gave up on a man out of its reach, the demon does not chase him again while he stays up
## there, though it still sees him, so it never starts and stops the chase over and over; once he
## comes back down within its reach, it chases him again.
func _having_given_up_it_leaves_a_man_out_of_reach_alone_until_he_comes_down() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var gave_up: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	var given_up_at: int = changes.size()
	await wait_frames(FRAMES_TO_WATCH)
	var chased_up_there: bool = changes.slice(given_up_at).any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.CHASE)
	man.position = Vector2(-OUT_OF_REACH_X, SPAWN_Y)
	var chased_below: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, ledge, man, demon])
	return report(gave_up and not chased_up_there and chased_below,
			"Out of reach: gave up %s, chased him again up there %s; he came down: chased %s"
			% [gave_up, chased_up_there, chased_below])


## A man held in the air inside Lunge Range, over every attack's Max Height Difference: the demon
## chases on under him, since he can only come down, and never warns of an attack it could not land.
func _never_warns_of_an_attack_at_a_man_in_the_air_over_its_reach() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, LUNGE_RANGE, changes)
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	for _frame: int in FRAMES_TO_WATCH:
		man.position = Vector2(BITE_X, SPAWN_Y - JUMP_PEAK)
		man.velocity = Vector2.ZERO
		await physics_frame
	var state: Demon.State = demon.get_state()
	await _clear([ground, man, demon])
	return report(state == Demon.State.CHASE and not _warned(changes),
			"Man held %d px up, %d px ahead: %s, warned %s"
			% [JUMP_PEAK, BITE_X, _name_of(state), _warned(changes)])


## With Out Of Reach Pace Width, the demon never stands stiff below a man out of its reach (ADR
## 0039): it paces across that stretch around where it stopped, not past it, and pauses no longer
## than Out Of Reach Pause Max at a time.
func _with_pace_width_out_of_reach_it_paces_around_where_it_stopped() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_it_pace(demon)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var anchor: float = demon.position.x
	var lowest: float = anchor
	var highest: float = anchor
	var last_x: float = anchor
	var still_for: int = 0
	var longest_still: int = 0
	for _frame: int in PACE_FRAMES:
		await physics_frame
		var x: float = demon.position.x
		lowest = minf(lowest, x)
		highest = maxf(highest, x)
		still_for = still_for + 1 if absf(x - last_x) < STILL_TOLERANCE else 0
		longest_still = maxi(longest_still, still_for)
		last_x = x
	var state: Demon.State = demon.get_state()
	await _clear([ground, ledge, man, demon])
	var longest_pause: int = roundi(PACE_PAUSE_MAX * Engine.physics_ticks_per_second) + ONE_FRAME
	var inside: bool = lowest >= anchor - PACE_WIDTH / 2.0 - TOLERANCE \
			and highest <= anchor + PACE_WIDTH / 2.0 + TOLERANCE
	return report(stopped and state == Demon.State.OUT_OF_REACH and inside
			and highest - lowest >= PACE_WIDTH - TOLERANCE and longest_still <= longest_pause,
			"Out of reach %s, pacing %d px: from %.1f to %.1f around %.1f, still at most %d frames (pause up to %d), %s"
			% [stopped, PACE_WIDTH, lowest, highest, anchor, longest_still, longest_pause,
					_name_of(state)])


## Pacing out of reach on an open floor, the demon barks at each end of its stretch, turned to the
## man, and never hops, since nothing stops it on his side.
func _pacing_out_of_reach_it_barks_facing_the_man_at_each_end() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_it_pace(demon)
	var barks: Array[Vector3] = []
	_record_barks(demon, barks)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	await wait_frames(PACE_FRAMES)
	await _clear([ground, ledge, man, demon])
	var facing_him: bool = barks.all(func(bark: Vector3) -> bool: return bark.y > 0.0)
	var hopped: bool = barks.any(func(bark: Vector3) -> bool: return bark.z > 0.0)
	return report(barks.size() >= LEAST_BARKS and facing_him and not hopped,
			"Pacing out of reach: %d barks (at least %d), all facing him %s, hopped %s"
			% [barks.size(), LEAST_BARKS, facing_him, hopped])


## The man on top of a block, the demon put PACE_NEAR from its side: pacing out of reach, it stops
## against the block, never past it, and barks there hopping, turned to him, and only there, while
## it keeps on pacing out of reach.
func _pacing_out_of_reach_it_hops_where_a_wall_stops_it_on_the_man_s_side() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var block: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(HIGH_LEDGE_LEFT - PACE_NEAR, NO_LUNGE)
	_make_it_pace(demon)
	var anchor: float = demon.position.x
	var barks: Array[Vector3] = []
	_record_barks(demon, barks)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var front: float = -INF
	for _frame: int in PACE_FRAMES:
		await physics_frame
		front = maxf(front, demon.position.x + _half_width(demon))
	var state: Demon.State = demon.get_state()
	await _clear([ground, block, man, demon])
	var hops: Array[Vector3] = barks.filter(func(bark: Vector3) -> bool: return bark.z > 0.0)
	var at_the_block: bool = hops.all(
			func(bark: Vector3) -> bool: return bark.x > anchor and bark.y > 0.0)
	return report(not hops.is_empty() and at_the_block
			and front <= HIGH_LEDGE_LEFT + STILL_TOLERANCE and state == Demon.State.OUT_OF_REACH,
			"Block at x = %d: %d barks, %d hopping, all at the block facing him %s; front at most %.1f, %s"
			% [HIGH_LEDGE_LEFT, barks.size(), hops.size(), at_the_block, front, _name_of(state)])


## The demon on a ledge, put PACE_NEAR from its end, the man on the floor below: pacing out of
## reach, it stops at the end of its floor, never falls off, and barks there hopping, turned to him,
## and only there.
func _pacing_out_of_reach_it_hops_where_its_floor_ends_on_the_man_s_side() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(FLOOR_LEFT, HIGH_LEDGE_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	demon.position = Vector2(HIGH_LEDGE_RIGHT - PACE_NEAR, SPAWN_Y - HIGH_LEDGE_HEIGHT)
	await wait_frames(SETTLE_FRAMES)
	await wait_until(demon.is_on_floor)
	_make_it_pace(demon)
	var anchor: float = demon.position.x
	var barks: Array[Vector3] = []
	_record_barks(demon, barks)
	var man: Player = await spawn_on_floor(Vector2(BELOW_LEDGE_X, SPAWN_Y))
	var furthest: float = -INF
	for _frame: int in PACE_FRAMES:
		await physics_frame
		furthest = maxf(furthest, demon.position.x)
	var on_the_ledge: bool = demon.position.y < -HIGH_LEDGE_HEIGHT / 2.0
	var state: Demon.State = demon.get_state()
	await _clear([ground, ledge, man, demon])
	var hops: Array[Vector3] = barks.filter(func(bark: Vector3) -> bool: return bark.z > 0.0)
	var at_the_end: bool = hops.all(
			func(bark: Vector3) -> bool: return bark.x > anchor and bark.y > 0.0)
	return report(not hops.is_empty() and at_the_end and furthest <= HIGH_LEDGE_RIGHT
			and on_the_ledge and state == Demon.State.OUT_OF_REACH,
			"Ledge ending at x = %d, the man below: %d barks, %d hopping, all at the end facing him %s; furthest %.1f, on the ledge %s, %s"
			% [HIGH_LEDGE_RIGHT, barks.size(), hops.size(), at_the_end, furthest, on_the_ledge,
					_name_of(state)])


## Pacing out of reach, the demon still gives up after Out Of Reach Wait, having paced on the way.
func _pacing_out_of_reach_it_still_gives_up_after_out_of_reach_wait() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	_make_it_pace(demon)
	demon.stats.out_of_reach_wait = OUT_OF_REACH_WAIT
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var anchor: float = demon.position.x
	var paced: float = 0.0
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if demon.get_state() != Demon.State.OUT_OF_REACH:
			break
		paced = maxf(paced, absf(demon.position.x - anchor))
	var waited: int = _frames_in(changes, Demon.State.OUT_OF_REACH)
	await _clear([ground, ledge, man, demon])
	var wait_frames_asked: int = roundi(OUT_OF_REACH_WAIT * Engine.physics_ticks_per_second)
	return report(stopped and paced > MOVED and absi(waited - wait_frames_asked) <= ONE_FRAME,
			"Pacing out of reach: paced up to %.1f px away, waited %d frames (asked %d)"
			% [paced, waited, wait_frames_asked])


## The man on a thin shelf, the demon below it SHELF_AWAY out from its corner: pacing out of reach,
## it goes on below the shelf though the shelf hides the man for longer than Give Up Time, since it
## knows he is up there, and never stops pacing out of reach for a search, an alert or a chase.
func _pacing_out_of_reach_it_keeps_on_below_a_shelf_that_hides_the_man() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var shelf: StaticBody2D = make_wall(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -SHELF_HEIGHT,
			-SHELF_HEIGHT + SHELF_THICKNESS)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(HIGH_LEDGE_LEFT - SHELF_AWAY, NO_LUNGE, changes)
	_make_it_pace(demon)
	var man: Player = await spawn_on_floor(
			Vector2(HIGH_LEDGE_LEFT + SHELF_INSET, SPAWN_Y - SHELF_HEIGHT))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var since: int = changes.size()
	var lowest: float = demon.position.x
	var highest: float = demon.position.x
	var unseen_for: int = 0
	var longest_unseen: int = 0
	for _frame: int in PACE_FRAMES:
		await physics_frame
		lowest = minf(lowest, demon.position.x)
		highest = maxf(highest, demon.position.x)
		unseen_for = 0 if demon.sees_target() else unseen_for + 1
		longest_unseen = maxi(longest_unseen, unseen_for)
	var left_it: bool = changes.size() > since
	var state: Demon.State = demon.get_state()
	var give_up_frames: int = demon.stats.get_give_up_frames()
	await _clear([ground, shelf, man, demon])
	return report(stopped and not left_it and highest - lowest > MOVED
			and longest_unseen > give_up_frames,
			"Man on a thin shelf %d px up: out of reach %s, paced %.1f px, hidden up to %d frames (Give Up Time %d), left it %s, %s"
			% [SHELF_HEIGHT, stopped, highest - lowest, longest_unseen, give_up_frames, left_it,
					_name_of(state)])


## With no Out Of Reach Pace Width, the demon stands out of reach as before and never barks.
func _with_no_pace_width_out_of_reach_it_never_barks() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var barks: Array[Vector3] = []
	_record_barks(demon, barks)
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	var stopped: bool = await _is_in_state_within(
			demon, Demon.State.OUT_OF_REACH, FRAMES_TO_WATCH)
	var gave_up: bool = await _is_in_state_within(demon, Demon.State.IDLE, MAX_FRAMES)
	await _clear([ground, ledge, man, demon])
	return report(stopped and gave_up and barks.is_empty(),
			"No pace width: out of reach %s, gave up %s, %d barks" % [stopped, gave_up,
					barks.size()])


## Two demons out of reach of one man, with the level's pauses, draw their own pauses and the way
## they set off, so with each of PAIR_SEEDS they bark nearer than MIN_BARK_GAP frames to each other
## less than half the time: never in step. The audio keeps two barks at once from sounding as one.
func _two_demons_pacing_out_of_reach_never_bark_in_step() -> bool:
	var reports: PackedStringArray = []
	var in_step: bool = false
	for pair_seed: int in PAIR_SEEDS:
		var barks: Array[Array] = await _barks_of_two_pacing(pair_seed)
		var first: Array = barks[0]
		var second: Array = barks[1]
		var paired: int = first.filter(func(frame: int) -> bool: return second.any(
				func(other: int) -> bool: return absi(other - frame) < MIN_BARK_GAP)).size()
		in_step = in_step or first.size() < LEAST_BARKS or second.size() < LEAST_BARKS \
				or 2 * paired >= first.size()
		reports.append("seed %d: %d and %d barks, %d together" % [pair_seed, first.size(),
				second.size(), paired])
	return report(not in_step, "Two pacing out of reach, %d frames apart or less is together: %s"
			% [MIN_BARK_GAP, "; ".join(reports)])


## The physics frames on which each of two demons pacing out of reach with the level's pauses barks
## over PAIR_FRAMES, with the generators seeded by pair_seed.
func _barks_of_two_pacing(pair_seed: int) -> Array[Array]:
	seed(pair_seed)
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var ledge: StaticBody2D = make_platform(HIGH_LEDGE_LEFT, FLOOR_RIGHT, -HIGH_LEDGE_HEIGHT)
	var first: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var second: Demon = await _spawn_demon(-AWAY_FROM_POST, NO_LUNGE)
	var first_barks: Array[int] = []
	var second_barks: Array[int] = []
	for pair: Array in [[first, first_barks], [second, second_barks]]:
		var demon: Demon = pair[0]
		var frames: Array[int] = pair[1]
		_make_it_pace(demon)
		demon.stats.out_of_reach_pause_min = LEVEL_PAUSE_MIN
		demon.stats.out_of_reach_pause_max = LEVEL_PAUSE_MAX
		demon.stats.out_of_reach_wait = PAIR_WAIT
		demon.barked.connect(
				func(_hops: bool) -> void: frames.append(Engine.get_physics_frames()))
	var man: Player = await spawn_on_floor(
			Vector2(OUT_OF_REACH_X, SPAWN_Y - HIGH_LEDGE_HEIGHT))
	await wait_frames(PAIR_FRAMES)
	await _clear([ground, ledge, man, first, second])
	return [first_barks, second_barks]


## A bark makes the stand-in's drawing hop and come back down, higher when the demon hops at a wall
## or the end of its floor, while its body stays where it is on the floor.
func _a_bark_hops_only_the_drawing_and_higher_at_a_wall() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var plain: Array[float] = await _hop_of(demon, false)
	var at_a_wall: Array[float] = await _hop_of(demon, true)
	await _clear([ground, demon])
	var body_still: bool = plain[2] < STILL_TOLERANCE and at_a_wall[2] < STILL_TOLERANCE
	var back_down: bool = is_zero_approx(plain[1]) and is_zero_approx(at_a_wall[1])
	return report(plain[0] > 0.0 and at_a_wall[0] > plain[0] and back_down and body_still,
			"Bark: drawing up %.1f px, at a wall %.1f px, back down %s, body still on the floor %s"
			% [plain[0], at_a_wall[0], back_down, body_still])


## A new state, such as the chase once the man comes down, ends a hop under way: the stand-in's
## drawing is back at its rest on that same frame, and stays there.
func _a_new_state_ends_a_hop_with_the_drawing_at_rest() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var rest_y: float = placeholder.position.y
	demon.barked.emit(true)
	await wait_frames(HOP_CUT_FRAMES)
	var hopping: bool = placeholder.position.y < rest_y
	demon.change_state(Demon.State.IDLE)
	var at_once: bool = is_equal_approx(placeholder.position.y, rest_y)
	await wait_frames(HOP_FRAMES)
	var stays: bool = is_equal_approx(placeholder.position.y, rest_y)
	await _clear([ground, demon])
	return report(hopping and at_once and stays,
			"Hop cut by a new state: hopping %s, at rest at once %s, stays at rest %s"
			% [hopping, at_once, stays])


## With Patrol Width and no man about, the demon walks to and fro across Patrol Width around its post
## at Patrol Speed, facing the way it walks, and before each walk pauses, still, for between Patrol
## Pause Min and Max (ADR 0033).
func _with_patrol_width_it_walks_to_and_fro_and_pauses_at_each_end() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	_make_it_patrol(demon)
	var post_x: float = demon.position.x
	var leftmost: float = INF
	var rightmost: float = -INF
	var fastest: float = 0.0
	var facing_its_way: bool = true
	var last_x: float = demon.position.x
	for _frame: int in PATROL_FRAMES:
		await physics_frame
		var step: float = demon.position.x - last_x
		last_x = demon.position.x
		leftmost = minf(leftmost, last_x)
		rightmost = maxf(rightmost, last_x)
		fastest = maxf(fastest, absf(step) * Engine.physics_ticks_per_second)
		if step != 0.0:
			facing_its_way = facing_its_way and demon.get_facing() == signf(step)
	await _clear([ground, demon])
	var pauses: Array[int] = _stints_in(changes, Demon.State.IDLE)
	var shortest: int = roundi(PATROL_PAUSE_MIN * Engine.physics_ticks_per_second)
	var longest: int = roundi(PATROL_PAUSE_MAX * Engine.physics_ticks_per_second)
	var pauses_right: bool = pauses.all(
			func(frames: int) -> bool: return frames >= shortest and frames <= longest)
	var set_offs: int = changes.filter(
			func(change: Vector2i) -> bool: return change.x == Demon.State.PATROL).size()
	var half: float = PATROL_WIDTH / 2.0
	var across: bool = absf(leftmost - (post_x - half)) <= TOLERANCE \
			and absf(rightmost - (post_x + half)) <= TOLERANCE
	return report(across and absf(fastest - PATROL_SPEED) <= SPEED_TOLERANCE and facing_its_way
			and set_offs >= LEAST_SET_OFFS and pauses_right,
			"Patrol of %d px: from %.1f to %.1f px of its post, at up to %.1f px/s (asked %d), facing its way %s; set off %d times, pauses of %s frames (asked %d to %d)"
			% [PATROL_WIDTH, leftmost - post_x, rightmost - post_x, fastest, PATROL_SPEED,
					facing_its_way, set_offs, pauses, shortest, longest])


## On patrol, the end of its floor and a step of one tile inside Patrol Width turn the demon back
## where they stop it: it never falls off nor climbs.
func _patrolling_it_turns_at_an_edge_and_at_a_step() -> bool:
	var ground: StaticBody2D = make_platform(-PATROL_EDGE, FLOOR_RIGHT)
	var step: StaticBody2D = make_platform(PATROL_STEP_X, FLOOR_RIGHT, -TILE)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	_make_it_patrol(demon)
	var half_width: float = _half_width(demon)
	var ledge_reach: float = absf((demon.get_node(^"%LedgeCheck") as Node2D).position.x)
	var leftmost: float = INF
	var rightmost: float = -INF
	var highest: float = 0.0
	var lowest: float = 0.0
	for _frame: int in PATROL_FRAMES:
		await physics_frame
		leftmost = minf(leftmost, demon.position.x)
		rightmost = maxf(rightmost, demon.position.x + half_width)
		highest = minf(highest, demon.position.y)
		lowest = maxf(lowest, demon.position.y)
	await _clear([ground, step, demon])
	var set_offs: int = changes.filter(
			func(change: Vector2i) -> bool: return change.x == Demon.State.PATROL).size()
	var at_the_step: bool = absf(rightmost - PATROL_STEP_X) <= TOLERANCE
	var at_the_edge: bool = absf(leftmost - (-PATROL_EDGE + ledge_reach)) <= TOLERANCE
	return report(at_the_step and at_the_edge and highest > -TOLERANCE and lowest < TOLERANCE
			and set_offs >= LEAST_SET_OFFS,
			"Edge at x = %d, step at x = %d: middle back to %.1f (LedgeCheck %d ahead), front up to %.1f, feet from y = %.1f to %.1f, set off %d times"
			% [-PATROL_EDGE, PATROL_STEP_X, leftmost, ledge_reach, rightmost, highest, lowest,
					set_offs])


## A demon on patrol off the screen stands still, and sets off once the screen comes to it.
func _patrolling_off_the_screen_it_stands_still() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var camera: Camera2D = _make_camera(2.0 * _screen_width())
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_it_patrol(demon)
	var start_x: float = demon.position.x
	await wait_frames(FRAMES_TO_WATCH)
	var moved_off: float = absf(demon.position.x - start_x)
	camera.position.x = 0.0
	var moved_on: bool = await wait_until(
			func() -> bool: return absf(demon.position.x - start_x) > MOVED, FRAMES_TO_WATCH)
	await _clear([ground, demon, camera])
	return report(moved_off < STILL_TOLERANCE and moved_on,
			"On patrol off the screen: moved %.2f px; on it: set off %s" % [moved_off, moved_on])


## Two demons put on patrol together draw their own pauses, so they pause for different times and
## never set off on the same frame.
func _two_demons_on_patrol_never_set_off_together() -> bool:
	seed(PATROL_SEED)
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var first_changes: Array[Vector2i] = []
	var second_changes: Array[Vector2i] = []
	var first: Demon = await _spawn_demon(0.0, NO_LUNGE, first_changes)
	var second: Demon = await _spawn_demon(PATROL_APART, NO_LUNGE, second_changes)
	_make_it_patrol(first)
	_make_it_patrol(second)
	await wait_frames(PATROL_FRAMES)
	await _clear([ground, first, second])
	var first_set_offs: Array[int] = _frames_of(first_changes, Demon.State.PATROL)
	var second_set_offs: Array[int] = _frames_of(second_changes, Demon.State.PATROL)
	var together: bool = first_set_offs.any(
			func(frame: int) -> bool: return frame in second_set_offs)
	var first_pauses: Array[int] = _stints_in(first_changes, Demon.State.IDLE)
	var second_pauses: Array[int] = _stints_in(second_changes, Demon.State.IDLE)
	return report(not first_pauses.is_empty() and first_pauses != second_pauses
			and not together,
			"Two on patrol: pauses of %s and %s frames, set off on frames %s and %s, together %s"
			% [first_pauses, second_pauses, first_set_offs, second_set_offs, together])


## A demon on patrol chases the man as soon as it notices him ahead, straight from walking. The man
## waits past Lose Distance and is put ahead of it once it walks.
func _patrolling_it_chases_a_man_it_sees_ahead() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man: Player = await spawn_on_floor(Vector2(LOST_X, SPAWN_Y))
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	_make_it_patrol(demon)
	var set_off: bool = await _is_in_state_within(demon, Demon.State.PATROL, FRAMES_TO_WATCH)
	man.position.x = demon.position.x + demon.get_facing() * SEEN_X
	var chased: bool = await _chases_within(demon, SETTLE_FRAMES)
	var from: Demon.State = changes[changes.size() - 2].x as Demon.State
	await _clear([ground, man, demon])
	return report(set_off and chased and from == Demon.State.PATROL,
			"On patrol %s, the man %d px ahead: chased %s, from %s"
			% [set_off, SEEN_X, chased, _name_of(from)])


## With Patrol Width and Return Speed, a demon that gave up walks back to its post and patrols again
## from there.
func _back_at_its_post_it_patrols_again() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_it_patrol(demon)
	demon.stats.return_speed = RETURN_SPEED
	var man: Player = await spawn_on_floor(Vector2(-SEEN_X, SPAWN_Y))
	await wait_until(func() -> bool: return demon.position.x < -PATROL_WIDTH)
	await remove_player(man)
	var returning: bool = await _is_in_state_within(demon, Demon.State.RETURN, SETTLE_FRAMES)
	var patrolling: bool = await _is_in_state_within(demon, Demon.State.PATROL, MAX_FRAMES)
	var off_post: float = absf(demon.position.x)
	await _clear([ground, demon])
	return report(returning and patrolling and off_post <= PATROL_WIDTH / 2.0 + TOLERANCE,
			"Gave up %d px from its post: walking back %s, patrolling again %s, %.1f px from its post"
			% [PATROL_WIDTH, returning, patrolling, off_post])


## With Alert Time, a demon that notices the man behind it is alerted first (ADR 0035): it turns to
## him and stands where it is for Alert Time, and only then chases him.
func _with_alert_time_it_stands_turned_to_the_man_then_chases() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	demon.stats.alert_time = ALERT_TIME
	var man: Player = await spawn_on_floor(Vector2(-SEEN_X, SPAWN_Y))
	var alerted: bool = await _is_in_state_within(demon, Demon.State.ALERT, FRAMES_TO_WATCH)
	var alert_x: float = demon.position.x
	var facing: float = demon.get_facing()
	var alert_frames: int = demon.stats.get_alert_frames()
	var chased: bool = await _chases_within(demon, alert_frames + SETTLE_FRAMES)
	var moved: float = absf(demon.position.x - alert_x)
	var first: Demon.State = changes.front().x as Demon.State if not changes.is_empty() \
			else Demon.State.IDLE
	var stood: int = _frames_in(changes, Demon.State.ALERT)
	await _clear([ground, man, demon])
	return report(alerted and first == Demon.State.ALERT and facing < 0.0 and chased
			and stood == alert_frames and moved <= Demon.POST_REACH,
			"Man behind it: first %s, facing %d, stood %d frames (asked %d), moved %.2f px; then chased %s"
			% [_name_of(first), facing, stood, alert_frames, moved, chased])


## An alerted demon whose man is freed, as on a respawn, lets go of him and stands, with no chase.
func _alerted_it_lets_go_of_a_man_who_is_freed() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	demon.stats.alert_time = ALERT_TIME
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var alerted: bool = await _is_in_state_within(demon, Demon.State.ALERT, FRAMES_TO_WATCH)
	await remove_player(man)
	var stands: bool = await _is_in_state_within(demon, Demon.State.IDLE, SETTLE_FRAMES)
	await wait_frames(demon.stats.get_alert_frames())
	var chased: bool = changes.any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.CHASE)
	await _clear([ground, demon])
	return report(alerted and stands and not chased,
			"Alerted %s, then the man is freed: stands %s, chased %s" % [alerted, stands, chased])


## With Search Time, a wall that hides the man for Give Up Time sends the demon where it last saw him
## (ADR 0035): it walks there at Search Speed, sniffs there for Search Time, turning round on the way,
## and then walks back to its post.
func _with_search_time_it_sniffs_where_it_last_saw_the_man_then_walks_back() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_WALL_X, HIDING_WALL_X + WALL_THICKNESS, WALL_TOP)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_it_search(demon)
	demon.stats.return_speed = RETURN_SPEED
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position.x = HIDDEN_X
	var searching: bool = await _is_in_state_within(demon, Demon.State.SEARCH,
			demon.stats.get_give_up_frames() + SETTLE_FRAMES)
	var start_x: float = demon.position.x
	await wait_frames(RETURN_MEASURE_FRAMES)
	var speed: float = (demon.position.x - start_x) * Engine.physics_ticks_per_second \
			/ RETURN_MEASURE_FRAMES
	var there: bool = await wait_until(
			func() -> bool: return absf(demon.position.x - SEEN_X) <= TOLERANCE)
	var facings: Array[float] = []
	var frames_there: Array[int] = [0]
	var farthest: Array[float] = [0.0]
	var search_frames: int = demon.stats.get_search_frames()
	var walked_back: bool = await wait_until(
			func() -> bool:
				if demon.get_state() == Demon.State.RETURN:
					return true
				facings.append(demon.get_facing())
				frames_there[0] += 1
				farthest[0] = maxf(farthest[0], absf(demon.position.x - SEEN_X))
				return false,
			search_frames + SETTLE_FRAMES)
	var both_ways: bool = facings.has(1.0) and facings.has(-1.0)
	await _clear([ground, wall, man, demon])
	return report(chased and searching and absf(speed - SEARCH_SPEED) <= SPEED_TOLERANCE and there
			and farthest[0] <= TOLERANCE and both_ways
			and frames_there[0] >= search_frames - SETTLE_FRAMES and walked_back,
			"Hidden: searching %s at %.1f px/s (asked %d), got where it saw him %s, sniffed %d frames (asked %d) at most %.1f px from it, facing both ways %s, walked back %s"
			% [searching, speed, SEARCH_SPEED, there, frames_there[0], search_frames, farthest[0],
					both_ways, walked_back])


## With Search Time, a demon that loses the man any way but behind a wall never searches: freed, as
## on a respawn, past Lose Distance, or with the demon off the screen, it stands or walks back as
## before.
func _with_search_time_only_a_wall_makes_it_search() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	_make_it_search(demon)
	demon.stats.return_speed = RETURN_SPEED
	demon.stats.chases_only_on_screen = true
	var camera: Camera2D = _make_camera(0.0)
	var gave_up: Callable = func() -> bool:
		return demon.get_state() == Demon.State.IDLE or demon.get_state() == Demon.State.RETURN
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await remove_player(man)
	var freed: bool = await wait_until(gave_up, SETTLE_FRAMES)
	man = await spawn_on_floor(Vector2(demon.position.x + SEEN_X, SPAWN_Y))
	var chased_far: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position.x = demon.position.x + LOST_X
	var lost: bool = await wait_until(gave_up, SETTLE_FRAMES)
	man.position.x = demon.position.x + SEEN_X
	var chased_on_screen: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	camera.position.x = 2.0 * _screen_width()
	var off_screen: bool = await wait_until(gave_up, SETTLE_FRAMES)
	var searched: bool = changes.any(
			func(change: Vector2i) -> bool: return change.x == Demon.State.SEARCH)
	await _clear([ground, man, demon, camera])
	return report(chased and freed and chased_far and lost and chased_on_screen and off_screen
			and not searched,
			"With Search Time, it gave up on a man freed %s, past Lose Distance %s, off the screen %s; searched %s"
			% [freed, lost, off_screen, searched])


## A searching demon that sees the man again is alerted by him, as at first, and then chases him.
func _searching_it_is_alerted_by_a_man_it_sees_again() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_WALL_X, HIDING_WALL_X + WALL_THICKNESS, WALL_TOP)
	var changes: Array[Vector2i] = []
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, changes)
	_make_it_search(demon)
	demon.stats.alert_time = ALERT_TIME
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position.x = HIDDEN_X
	var searching: bool = await _is_in_state_within(demon, Demon.State.SEARCH,
			demon.stats.get_give_up_frames() + SETTLE_FRAMES)
	man.position.x = SEEN_X
	var alerted: bool = await _is_in_state_within(demon, Demon.State.ALERT, SETTLE_FRAMES)
	var chased_again: bool = await _chases_within(demon,
			demon.stats.get_alert_frames() + SETTLE_FRAMES)
	var after_search: int = _index_after(changes, Demon.State.SEARCH)
	var next: Demon.State = changes[after_search].x as Demon.State if after_search != NEVER_REACHED \
			else Demon.State.SEARCH
	await _clear([ground, wall, man, demon])
	return report(chased and searching and alerted and next == Demon.State.ALERT and chased_again,
			"Searching %s, the man seen again: next %s, chased again %s"
			% [searching, _name_of(next), chased_again])


## With Chases Only On Screen, a searching demon the screen leaves stops searching and walks back to
## its post, as it gives up a chase.
func _searching_off_the_screen_it_walks_back() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_WALL_X, HIDING_WALL_X + WALL_THICKNESS, WALL_TOP)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE)
	_make_it_search(demon)
	demon.stats.return_speed = RETURN_SPEED
	demon.stats.chases_only_on_screen = true
	var camera: Camera2D = _make_camera(0.0)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var chased: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position.x = HIDDEN_X
	var searching: bool = await _is_in_state_within(demon, Demon.State.SEARCH,
			demon.stats.get_give_up_frames() + SETTLE_FRAMES)
	camera.position.x = 2.0 * _screen_width()
	var walks_back: bool = await _is_in_state_within(demon, Demon.State.RETURN, SETTLE_FRAMES)
	await _clear([ground, wall, man, demon, camera])
	return report(chased and searching and walks_back,
			"Searching %s, then off the screen: walks back %s" % [searching, walks_back])


## Two demons, one Pack Spacing behind the other, chase the man until a wall hides him: both search
## where they last saw him, and the second sniffs Pack Spacing behind the first's body instead of
## walking on into it.
func _two_demons_searching_one_spot_sniff_pack_spacing_apart() -> bool:
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var wall: StaticBody2D = make_wall(HIDING_WALL_X, HIDING_WALL_X + WALL_THICKNESS, WALL_TOP)
	var front: Demon = await _spawn_demon(0.0, NO_LUNGE)
	var back: Demon = await _spawn_demon(-SECOND_DEMON_BEHIND, NO_LUNGE)
	for demon: Demon in [front, back]:
		_make_it_search(demon)
		_make_it_keep_apart(demon)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, SPAWN_Y))
	var got_to_him: bool = await wait_until(
			func() -> bool: return absf(man.position.x - front.position.x) <= TOLERANCE,
			FRAMES_TO_WATCH)
	man.position.x = HIDDEN_X
	var both_search: Callable = func() -> bool:
		return front.get_state() == Demon.State.SEARCH and back.get_state() == Demon.State.SEARCH
	var searching: bool = await wait_until(both_search,
			front.stats.get_give_up_frames() + SETTLE_FRAMES)
	var closest: Array[float] = [INF]
	await wait_until(
			func() -> bool:
				if not both_search.call():
					return true
				closest[0] = minf(closest[0], absf(front.position.x - back.position.x))
				return false,
			front.stats.get_search_frames() + SETTLE_FRAMES)
	var apart: float = _body_width(front) + PACK_SPACING
	await _clear([ground, wall, man, front, back])
	return report(got_to_him and searching and closest[0] >= apart - CONTACT_TOLERANCE,
			"Two demons searching one spot %s: never nearer than %.1f px (body %d + Pack Spacing %d)"
			% [searching, closest[0], apart - PACK_SPACING, PACK_SPACING])


## The demon's body is on the enemy layer and collides with the world, one-way platforms and the
## man's body only, and its sight area is on no layer and looks only for the player.
func _is_on_the_enemy_layer_and_looks_only_for_the_player() -> bool:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	var sight_area: Area2D = demon.get_node(^"SightArea") as Area2D
	var world_bit: int = _bit_of(WORLD_LAYER_NAME)
	var one_way_bit: int = _bit_of(ONE_WAY_LAYER_NAME)
	var enemy_bit: int = _bit_of(ENEMY_LAYER_NAME)
	var player_bit: int = _bit_of(PLAYER_LAYER_NAME)
	var body_right: bool = demon.collision_layer == enemy_bit \
			and demon.collision_mask == world_bit | one_way_bit | player_bit
	var sight_right: bool = sight_area.collision_layer == 0 \
			and sight_area.collision_mask == player_bit
	var found_all: bool = world_bit != 0 and one_way_bit != 0 and enemy_bit != 0 and player_bit != 0
	demon.free()
	return report(found_all and body_right and sight_right,
			"Body on the enemy layer, colliding with the world and the man only: %s; sight looking only for the player: %s"
			% [body_right, sight_right])


## A demon of DEMON_SCENE at x, with its own DemonStats of the values above and its attacks, once it
## has landed: a lunge of the values above with lunge_range as its Attack Range and, with bite, a
## bite of the values above before it. Every state it changes to from the start goes into changes,
## with the physics frame it changed in, and every attack it warns of goes into warned_of. It does
## not collide with the man's body, so his body never gets in the way of its chase and its aim;
## _make_the_bodies_solid() puts that back. With faces_left, it is put facing left.
func _spawn_demon(x: float, lunge_range: float = LUNGE_RANGE,
		changes: Array[Vector2i] = [], bite: bool = false,
		warned_of: Array[DemonAttack] = [], faces_left: bool = false) -> Demon:
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
	stats.out_of_reach_wait = OUT_OF_REACH_WAIT
	if bite:
		stats.attacks.append(_make_bite())
	stats.attacks.append(lunge)
	stats.repelled_time = REPELLED_TIME
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.stats = stats
	demon.faces_left = faces_left
	demon.position = Vector2(x, SPAWN_Y)
	demon.collision_mask &= ~_bit_of(PLAYER_LAYER_NAME)
	demon.state_changed.connect(
			func(_previous: Demon.State, current: Demon.State) -> void:
				changes.append(Vector2i(current, Engine.get_physics_frames())))
	demon.warning_started.connect(
			func(attack: DemonAttack) -> void: warned_of.append(attack))
	root.add_child(demon)
	await wait_until(demon.is_on_floor)
	return demon


## Whether a demon put facing left, or right, with BEHIND_SHARE, chases the man SEEN_X behind it,
## and then SEEN_X ahead of it. The man comes only once it stands with its share, so it never sees
## him all round.
func _chases_behind_and_ahead(faces_left: bool) -> Array[bool]:
	var ahead: float = -1.0 if faces_left else 1.0
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var demon: Demon = await _spawn_demon(0.0, NO_LUNGE, [], false, [], faces_left)
	demon.stats.sight_behind_share = BEHIND_SHARE
	var man: Player = await spawn_on_floor(Vector2(-ahead * SEEN_X, SPAWN_Y))
	var chased_behind: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	man.position.x = ahead * SEEN_X
	var chased_ahead: bool = await _chases_within(demon, FRAMES_TO_WATCH)
	await _clear([ground, man, demon])
	return [chased_behind, chased_ahead]


## A camera made current, centred at x on the floor, so the screen spans _screen_width() around it.
func _make_camera(x: float) -> Camera2D:
	var camera: Camera2D = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(x, 0.0)
	root.add_child(camera)
	camera.make_current()
	return camera


## The screen's width in the world, in px, with a camera at no zoom.
func _screen_width() -> float:
	return root.get_visible_rect().size.x


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


## Physics frames the demon stayed in state the first time it was in it, by changes; NEVER_REACHED
## if it never was, or is still in it.
func _frames_in(changes: Array[Vector2i], state: Demon.State) -> int:
	var after: int = _index_after(changes, state)
	if after == NEVER_REACHED:
		return NEVER_REACHED
	return changes[after].y - changes[after - 1].y


## Physics frames the demon stayed in state each time it was in it and left it, by changes.
func _stints_in(changes: Array[Vector2i], state: Demon.State) -> Array[int]:
	var stints: Array[int] = []
	for index: int in range(changes.size() - 1):
		if changes[index].x == state:
			stints.append(changes[index + 1].y - changes[index].y)
	return stints


## The physics frames on which the demon changed to state, by changes.
func _frames_of(changes: Array[Vector2i], state: Demon.State) -> Array[int]:
	var frames: Array[int] = []
	for change: Vector2i in changes:
		if change.x == state:
			frames.append(change.y)
	return frames


## Gives the demon the cases' patrol, from its next frame standing at its post.
func _make_it_patrol(demon: Demon) -> void:
	demon.stats.patrol_width = PATROL_WIDTH
	demon.stats.patrol_speed = PATROL_SPEED
	demon.stats.patrol_pause_min = PATROL_PAUSE_MIN
	demon.stats.patrol_pause_max = PATROL_PAUSE_MAX


## Gives the demon the cases' search: Search Time and Search Speed.
func _make_it_search(demon: Demon) -> void:
	demon.stats.search_time = SEARCH_TIME
	demon.stats.search_speed = SEARCH_SPEED


## Gives the demon the cases' pacing out of reach: Out Of Reach Pace Width, its pauses and Patrol
## Speed, with PACE_WAIT to watch it.
func _make_it_pace(demon: Demon) -> void:
	demon.stats.out_of_reach_pace_width = PACE_WIDTH
	demon.stats.out_of_reach_pause_min = PACE_PAUSE_MIN
	demon.stats.out_of_reach_pause_max = PACE_PAUSE_MAX
	demon.stats.patrol_speed = PATROL_SPEED
	demon.stats.out_of_reach_wait = PACE_WAIT


## Records each bark of the demon from now on into barks: its x, its facing, and 1 if it hopped or 0
## if not.
func _record_barks(demon: Demon, barks: Array[Vector3]) -> void:
	demon.barked.connect(
			func(hops: bool) -> void:
				barks.append(Vector3(demon.position.x, demon.get_facing(), 1.0 if hops else 0.0)))


## Has the demon bark, hopping or not, and watches its stand-in for HOP_FRAMES: how high its drawing
## went, how far from its rest it ended, and how far the body moved, INF if it left the floor.
func _hop_of(demon: Demon, hops: bool) -> Array[float]:
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var rest_y: float = placeholder.position.y
	var body: Vector2 = demon.position
	var peak: float = 0.0
	var on_floor: bool = true
	demon.barked.emit(hops)
	for _frame: int in HOP_FRAMES:
		await physics_frame
		peak = maxf(peak, rest_y - placeholder.position.y)
		on_floor = on_floor and demon.is_on_floor()
	var moved: float = demon.position.distance_to(body) if on_floor else INF
	return [peak, placeholder.position.y - rest_y, moved]


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


## Sets what attack does when it lands.
func _give_hit(attack: DemonAttack, damage: float, distance: float, height: float) -> void:
	attack.damage = damage
	attack.knockback_distance = distance
	attack.knockback_height = height


## True when hitbox carries attack's damage and knockback.
func _carries(hitbox: Hitbox, attack: DemonAttack) -> bool:
	return hitbox.damage == attack.damage and hitbox.knockback_distance == attack.knockback_distance \
			and hitbox.knockback_height == attack.knockback_height


## The physics frames, over the next frames, at the end of which hitbox was on.
func _frames_with_hitbox_on(hitbox: Hitbox, frames: int) -> Array[int]:
	var on_frames: Array[int] = []
	for _frame: int in frames:
		await physics_frame
		if hitbox.is_active():
			on_frames.append(Engine.get_physics_frames() - 1)
	return on_frames


## The man of every case, as player_test.gd makes him, with his Hurtbox off, so the demon's hits do
## not throw him, and with his body not colliding with demons; the case where a bite lands and those
## of the bodies turn them back on.
func spawn_player(at: Vector2) -> Player:
	var man: Player = super(at)
	_hurtbox_of(man).monitoring = false
	man.collision_mask &= ~_bit_of(ENEMY_LAYER_NAME)
	return man


func _hurtbox_of(man: Player) -> Hurtbox:
	return man.get_node(^"Hurtbox") as Hurtbox


func _escape_of(man: Player) -> GrabEscape:
	return man.get_node(^"GrabEscape") as GrabEscape


## The man at BITE_X, with his Hurtbox on, a stand-in input and SP below Low Threshold, so a bite
## grabs him.
func _man_a_bite_grabs() -> Player:
	var man: Player = await spawn_on_floor(Vector2(BITE_X, SPAWN_Y))
	_hurtbox_of(man).monitoring = true
	put_a_stand_in(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	return man


## Presses Jump on each physics frame until the man breaks free of the grab, or MAX_FRAMES go by.
func _press_until_free(man: Player) -> void:
	var escape: GrabEscape = _escape_of(man)
	var stand_in: StandInInput = man.input as StandInInput
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not escape.is_held():
			return
		stand_in.press_jump()


## Makes the demon back off after its attacks, with the cases' Retreat Distance and Retreat Speed.
func _make_it_back_off(demon: Demon) -> void:
	demon.stats.retreat_distance = RETREAT_DISTANCE
	demon.stats.retreat_speed = RETREAT_SPEED


## Makes the demon keep the cases' Pack Spacing from other demons.
func _make_it_keep_apart(demon: Demon) -> void:
	demon.stats.pack_spacing = PACK_SPACING


## True when value is within PACK_VARIATION of base, either way, with up to slack more above it.
func _is_within_pack_variation(value: float, base: float, slack: float = 0.0) -> bool:
	return value >= base * (1.0 - PACK_VARIATION) and value <= base * (1.0 + PACK_VARIATION) + slack


## The width of the demon's body box, read from its scene.
func _body_width(demon: Demon) -> float:
	return (demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape.get_rect().size.x


## Makes the man's body and the demon's collide with each other again, as in their scenes.
func _make_the_bodies_solid(man: Player, demon: Demon) -> void:
	man.collision_mask |= _bit_of(ENEMY_LAYER_NAME)
	demon.collision_mask |= _bit_of(PLAYER_LAYER_NAME)


## How far apart the man's middle and the demon's are with their bodies touching side to side.
func _contact_distance(man: Player, demon: Demon) -> float:
	var demon_body: CollisionShape2D = demon.get_node(^"CollisionShape2D") as CollisionShape2D
	return (body_size(man).x + (demon_body.shape as RectangleShape2D).size.x) / 2.0


func _wait_physics_frames(count: int) -> void:
	for _frame: int in count:
		await physics_frame


## Takes out what a case made at the end of the frame, and waits for it.
func _clear(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame
