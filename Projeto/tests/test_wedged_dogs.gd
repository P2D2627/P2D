# Checks that dogs wedged in a pack never shake (#271): a dog that turns back along the floor on its
# own walk, or turns to face the other way, never does it again within JITTER_FRAMES (0.1 s), which
# reads as a tremble, not a walk. A lunge, a throw, a leap or a drop carries the dog and does not
# count as its walk.
# The case is the one seen in play: three of the level's dogs between a wall and a man cornered
# against another wall, with room for their three bodies and one Pack Spacing only, so no dog has
# Pack Spacing on both sides and none can wait at its Retreat Distance. The man's SP is raised in
# memory so far that no grab ends the case early.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wedged_dogs.gd
extends "res://tests/support/player_test.gd"

const DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const LEVEL_STATS: String = "res://scenes/characters/demon/lust_demon_stats.tres"
const FLOOR_LEFT: float = -1000.0
const FLOOR_RIGHT: float = 2000.0
const SPAWN_Y: float = -2.0
const WALL_THICKNESS: float = 100.0
const WALL_HEIGHT: float = 600.0
## Where the wall behind the man has its face, on his right.
const MAN_WALL_X: float = 600.0
const DOGS: int = 3
## So high that the dogs never take the man low and grab him.
const MAN_MAX_SP: float = 1000000.0
## Seeds the dogs' own draws (Pack Variation, hesitation), so each run is the same.
const DRAW_SEED: int = 27
## Frames after the dogs land before watching, as they come to the man.
const SETTLE_FRAMES: int = 90
const WATCH_FRAMES: int = 600
## Least frames between two turns back, or two turns of the face, that is not a tremble: 0.1 s at
## the project's 60 physics frames per second, under Min Turn Time.
const JITTER_FRAMES: int = 6
## Where the man is put, px from the wall behind him: he lands against it.
const MAN_FROM_HIS_WALL: float = 40.0
## Frames for the man to settle on the floor against his wall before the dogs come.
const MAN_SETTLE_FRAMES: int = 10
## Least move along the floor in a frame, in px, that counts as going one way.
const MOVE_STEP: float = 0.25


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _three_dogs_wedged_by_a_cornered_man_never_shake())
	finish(results)


func _three_dogs_wedged_by_a_cornered_man_never_shake() -> bool:
	seed(DRAW_SEED)
	var ground: StaticBody2D = make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var man_wall: StaticBody2D = make_wall(MAN_WALL_X, MAN_WALL_X + WALL_THICKNESS, -WALL_HEIGHT)
	var man: Player = await spawn_on_floor(Vector2(MAN_WALL_X - MAN_FROM_HIS_WALL, SPAWN_Y))
	_raise_sp(man)
	await wait_frames(MAN_SETTLE_FRAMES)
	var man_left: float = man.position.x - body_size(man).x / 2.0
	var dog_width: float = _body_width_of(DOG_SCENE)
	var spacing: float = (load(LEVEL_STATS) as DemonStats).pack_spacing
	var room: float = DOGS * dog_width + spacing
	var dog_wall_x: float = man_left - room
	var dog_wall: StaticBody2D = make_wall(dog_wall_x - WALL_THICKNESS, dog_wall_x, -WALL_HEIGHT)
	var dogs: Array[Demon] = []
	for index: int in DOGS:
		var x: float = dog_wall_x + dog_width / 2.0 + index * (dog_width + spacing / DOGS)
		dogs.append(await _spawn_level_dog(x))
	await wait_frames(SETTLE_FRAMES)
	var watches: Array[TurnWatch] = []
	for dog: Demon in dogs:
		watches.append(TurnWatch.new(dog))
	for frame: int in WATCH_FRAMES:
		await physics_frame
		for watch: TurnWatch in watches:
			watch.see(frame)
	var described: Array[String] = []
	var steady: bool = true
	for watch: TurnWatch in watches:
		described.append(watch.describe())
		steady = steady and watch.quickest_turn_back >= JITTER_FRAMES \
				and watch.quickest_face_turn >= JITTER_FRAMES
	var nodes: Array[Node] = [ground, man_wall, dog_wall, man]
	nodes.append_array(dogs)
	await _clear(nodes)
	return report(steady,
			"%d of the level's dogs in %.0f px between a wall and a cornered man, for %d frames (no turn within %d frames of the last): %s"
			% [DOGS, room, WATCH_FRAMES, JITTER_FRAMES, ", ".join(described)])


## A dog of DOG_SCENE at x with a shallow copy of the level's stats, as the level has it, its body
## solid to the man's. Comes back once it has landed.
func _spawn_level_dog(x: float) -> Demon:
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	dog.stats = dog.stats.duplicate() as DemonStats
	dog.position = Vector2(x, SPAWN_Y)
	root.add_child(dog)
	await wait_until(dog.is_on_floor)
	return dog


func _raise_sp(man: Player) -> void:
	var soul_points: SoulPoints = man.soul_points
	soul_points.stats = soul_points.stats.duplicate() as SoulPointsStats
	soul_points.stats.max_sp = MAN_MAX_SP
	soul_points.heal(MAN_MAX_SP)


## The width of the body box of a dog of scene, read from a copy that is freed at once.
func _body_width_of(scene: PackedScene) -> float:
	var dog: Demon = scene.instantiate() as Demon
	var width: float = (dog.get_node(^"CollisionShape2D") as CollisionShape2D).shape.get_rect().size.x
	dog.free()
	return width


func _clear(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame


## What a case saw of a dog: each time it turned back along the floor or turned its face, and the
## fewest frames between two of either.
class TurnWatch:
	var dog: Demon
	var quickest_turn_back: int = WATCH_FRAMES
	var quickest_face_turn: int = WATCH_FRAMES
	var turns_back: int = 0
	var face_turns: int = 0
	var _last_x: float
	var _going: float = 0.0
	var _last_turn_back: int = -WATCH_FRAMES
	var _facing: float
	var _last_face_turn: int = -WATCH_FRAMES

	func _init(watched: Demon) -> void:
		dog = watched
		_last_x = watched.position.x
		_facing = watched.get_facing()

	## A lunge, a throw, a leap or a drop carries the dog and is no walk of its own: it is not a
	## turn, and the walk after it starts afresh.
	func see(frame: int) -> void:
		var step: float = dog.position.x - _last_x
		_last_x = dog.position.x
		if dog.get_state() in Demon.STATES_THAT_CARRY_IT:
			_going = 0.0
		elif absf(step) >= MOVE_STEP:
			var going: float = signf(step)
			if _going != 0.0 and going != _going:
				turns_back += 1
				quickest_turn_back = mini(quickest_turn_back, frame - _last_turn_back)
				_last_turn_back = frame
			_going = going
		var facing: float = dog.get_facing()
		if facing != _facing:
			face_turns += 1
			quickest_face_turn = mini(quickest_face_turn, frame - _last_face_turn)
			_last_face_turn = frame
			_facing = facing

	func describe() -> String:
		return "%d turns back (quickest %d frames apart), %d face turns (quickest %d)" % [turns_back,
				quickest_turn_back, face_turns, quickest_face_turn]
