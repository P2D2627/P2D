# Checks that the biggest dog follows the man down a shaft narrower than its leap (#271, phase C): its leap down
# off the end of its floor meets the shaft's far wall near the top, and with Drops Down Shafts it slides down that
# wall, as its body does, onto the floor below. Built here: a corridor whose floor ends at a shaft as wide and as
# deep as level 1's chimney, over a hall the man stands in; with Drops Down Shafts the dog lands in the hall, and
# without it the same dog stays up in the corridor, stopped by that step of his trail; given Drops Down Shafts
# then, it tries the step again once Trail Retry Time is up, and goes down. Only the biggest dog drops down
# shafts. In level 1, from the
# corridor behind gate 3, the dog goes down the step, the well and the chimney into the hall after the man.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_dog_shafts.gd
extends "res://tests/support/player_test.gd"

const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const STATS_PATHS: Array[String] = [
	"res://scenes/characters/demon/lust_demon_stats.tres",
	"res://scenes/characters/demon/big_demon_stats.tres",
	"res://scenes/characters/demon/jumping_demon_stats.tres",
	"res://scenes/characters/demon/tutorial_blocker_stats.tres",
]
const BIGGEST_STATS_PATH: String = "res://scenes/characters/demon/biggest_demon_stats.tres"
## Level 1's chimney behind gate 3, in px: 4 tiles wide, and from the corridor's floor to the hall's.
const SHAFT_WIDTH: float = 192.0
const SHAFT_DEPTH: float = 1488.0
## The hall under the shaft and the corridor over its top, in px high, as in level 1.
const HALL_HEIGHT: float = 912.0
const CORRIDOR_HEIGHT: float = 240.0
## How far the corridor and the rock past the shaft reach, in px, from the shaft's sides.
const BLOCK_LENGTH: float = 1600.0
## The dog stands in the corridor DOG_FROM_SHAFT px short of the shaft, the man first beside it, MAN_BESIDE px
## nearer the shaft, then in the hall MAN_PAST_SHAFT px past the shaft's far side.
const DOG_FROM_SHAFT: float = 700.0
const MAN_BESIDE: float = 350.0
const MAN_PAST_SHAFT: float = 600.0
## Frames given to the dog to notice the man, and to get down the shaft.
const NOTICE_FRAMES: int = 120
const SHAFT_FRAMES: int = 480
## Frames the dog without Drops Down Shafts is left at the shaft, stopped, before it is given it.
const STOPPED_FRAMES: int = 240
## The seed every case starts from, so the dogs' draws repeat.
const SEED: int = 27
## How near a floor's top, in px, a dog's feet are to stand on it.
const ON_TOP: float = 4.0
## Level 1, on its grid of 48 px tiles: the floor of the corridor behind gate 3, the dog's spot on it, where the
## man is put to be noticed, on the floor one step down, and where he is put in the hall, east of the chimney;
## and the hall's floor.
const GATE_3_CORRIDOR_FLOOR: float = 8304.0
const LEVEL_DOG_X: float = 4700.0
const LEVEL_MAN_NOTICED_AT: Vector2 = Vector2(5150.0, 8446.0)
const LEVEL_MAN_IN_HALL: Vector2 = Vector2(7600.0, 10318.0)
const HALL_FLOOR: float = 10320.0
const LEVEL_SETTLE_FRAMES: int = 30
## Frames given to the dog to notice the man in level 1: it chases only on the screen, and the camera takes
## time to get to where he is put.
const LEVEL_NOTICE_FRAMES: int = 600
const LEVEL_FRAMES: int = 900


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_biggest_dog_drops_down_a_shaft_after_the_man())
	results.append(await _without_drops_down_shafts_it_stays_above())
	results.append(await _given_drops_down_shafts_later_it_tries_the_shaft_again())
	results.append(_only_the_biggest_dog_drops_down_shafts())
	results.append(await _in_level_1_it_goes_down_the_chimney_after_the_man())
	finish(results)


func _the_biggest_dog_drops_down_a_shaft_after_the_man() -> bool:
	var landed: bool = await _down_the_shaft(true)
	return report(landed, "Biggest dog: down a shaft %.0f px wide and %.0f px deep after the man within %d frames %s"
			% [SHAFT_WIDTH, SHAFT_DEPTH, SHAFT_FRAMES, landed])


func _without_drops_down_shafts_it_stays_above() -> bool:
	var landed: bool = await _down_the_shaft(false)
	return report(not landed, "Biggest dog without Drops Down Shafts: down the same shaft %s (false)" % landed)


func _given_drops_down_shafts_later_it_tries_the_shaft_again() -> bool:
	var landed: bool = await _down_the_shaft(false, STOPPED_FRAMES)
	return report(landed, ("Biggest dog stopped at the shaft for %d frames, then given Drops Down Shafts: down the "
			+ "shaft once it tried again %s") % [STOPPED_FRAMES, landed])


func _only_the_biggest_dog_drops_down_shafts() -> bool:
	var others: Array[String] = []
	if DemonStats.new().drops_down_shafts:
		others.append("DemonStats.new()")
	for path: String in STATS_PATHS:
		if (load(path) as DemonStats).drops_down_shafts:
			others.append(path.get_file())
	var biggest: bool = (load(BIGGEST_STATS_PATH) as DemonStats).drops_down_shafts
	return report(biggest and others.is_empty(), "Drops Down Shafts: biggest dog %s (true), others with it: %s"
			% [biggest, others if not others.is_empty() else "none"])


## A corridor whose floor, SHAFT_DEPTH px over the hall's, ends at x = 0 at a shaft SHAFT_WIDTH px wide; the
## biggest dog, with Drops Down Shafts as given and no Pack Variation, from SEED, in the corridor after the
## man; then he stands in the hall. With given_after, the dog is given Drops Down Shafts that many frames later,
## and has its Trail Retry Time more to get down. True when the dog lands on the hall's floor within
## SHAFT_FRAMES; with given_after, never before it was given Drops Down Shafts.
func _down_the_shaft(drops_down_shafts: bool, given_after: int = -1) -> bool:
	var hall: StaticBody2D = make_platform(-BLOCK_LENGTH, SHAFT_WIDTH + BLOCK_LENGTH)
	var corridor: StaticBody2D = make_wall(-BLOCK_LENGTH, 0.0, -SHAFT_DEPTH, -HALL_HEIGHT)
	var far_side: StaticBody2D = make_wall(SHAFT_WIDTH, SHAFT_WIDTH + BLOCK_LENGTH,
			-SHAFT_DEPTH - CORRIDOR_HEIGHT, -HALL_HEIGHT)
	seed(SEED)
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	big.stats = big.stats.duplicate() as DemonStats
	big.stats.drops_down_shafts = drops_down_shafts
	big.stats.pack_variation = 0.0
	big.position = Vector2(-DOG_FROM_SHAFT, -SHAFT_DEPTH - 2.0)
	root.add_child(big)
	await wait_until(big.is_on_floor)
	var player: Player = await spawn_on_floor(Vector2(-DOG_FROM_SHAFT + MAN_BESIDE, -SHAFT_DEPTH - 2.0))
	await wait_until(big.has_target, NOTICE_FRAMES)
	player.global_position = Vector2(SHAFT_WIDTH + MAN_PAST_SHAFT, -2.0)
	var in_the_hall: Callable = func() -> bool:
			return big.is_on_floor() and absf(big.global_position.y) <= ON_TOP
	var frames: int = SHAFT_FRAMES
	var too_soon: bool = false
	if given_after >= 0:
		too_soon = await wait_until(in_the_hall, given_after)
		big.stats.drops_down_shafts = true
		frames += big.stats.get_trail_retry_frames()
	var landed: bool = not too_soon and await wait_until(in_the_hall, frames)
	big.queue_free()
	for body: StaticBody2D in [hall, corridor, far_side]:
		body.queue_free()
	await remove_player(player)
	return landed


## Level 1: the biggest dog stands in the corridor behind gate 3, turned east, and notices the man one step
## down; then he stands in the hall, east of the chimney. It lands on the hall's floor within LEVEL_FRAMES.
func _in_level_1_it_goes_down_the_chimney_after_the_man() -> bool:
	seed(SEED)
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await wait_frames(LEVEL_SETTLE_FRAMES)
	var big: Demon = level.get_node(^"Dogs/P3BiggestDog") as Demon
	var man: Player = level.get_node(^"Player") as Player
	big.global_position = Vector2(LEVEL_DOG_X, GATE_3_CORRIDOR_FLOOR - 2.0)
	big.velocity = Vector2.ZERO
	big.turn_to(1.0)
	man.global_position = LEVEL_MAN_NOTICED_AT
	man.velocity = Vector2.ZERO
	var noticed: bool = await wait_until(big.has_target, LEVEL_NOTICE_FRAMES)
	man.global_position = LEVEL_MAN_IN_HALL
	man.velocity = Vector2.ZERO
	var landed: bool = await wait_until(func() -> bool:
			return big.is_on_floor() and absf(big.global_position.y - HALL_FLOOR) <= ON_TOP, LEVEL_FRAMES)
	var at: Vector2 = big.global_position
	level.queue_free()
	await wait_frames(2)
	return report(noticed and landed, ("Level 1: the biggest dog noticed the man %s, and went from the corridor "
			+ "behind gate 3 down the chimney into the hall within %d frames %s (at %.0f, %.0f)")
			% [noticed, LEVEL_FRAMES, landed, at.x, at.y])
