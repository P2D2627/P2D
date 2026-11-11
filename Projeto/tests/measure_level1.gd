# Prints what level 1 costs on a frame at five of its spots, with its ActivityTracker off and on, and with every
# dog's and every parallax drawing's processing off, the least they could cost. At each spot the man stands on a
# floor of the paper check's route (support/level1_route.json), the camera settles on him, and the level is
# measured those three ways; the tracker goes first off at one spot and first on at the next, so neither is always
# measured first. With it on, it also prints how many of its members are awake. Each cost is over MEASURED_FRAMES
# frames: the whole frame, from one physics frame to the next, which
# with --fixed-fps and no window waits for nothing, so it takes in the physics server's step and the _process of
# every node; and inside it the physics scripts and the process scripts, each from a node that runs before every
# other node's callback to one that runs after them all. It checks nothing: the exit code is 1 only if the man
# never stands at a spot. The README quotes the result in its section on activity off the screen.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_level1.gd
extends "res://tests/support/player_test.gd"


## Stamps the time of its own _physics_process and _process. With the lowest priority it runs before every other
## node's, and with the highest after them all.
class Stamp extends Node:
	var physics_usec: int = 0
	var process_usec: int = 0

	func _init(priority: int) -> void:
		process_physics_priority = priority
		process_priority = priority

	func _physics_process(_delta: float) -> void:
		physics_usec = Time.get_ticks_usec()

	func _process(_delta: float) -> void:
		process_usec = Time.get_ticks_usec()


## What a measure found, in us per frame.
class Cost:
	var frame: float = 0.0
	var worst_frame: float = 0.0
	var physics_scripts: float = 0.0
	var process_scripts: float = 0.0


const SCENE_PATH: String = "res://levels/lust/level1.tscn"
const ROUTE_PATH: String = "res://tests/support/level1_route.json"
## With this event, Velvet does not stop the man to talk as he walks past.
const VELVET_MET: StringName = &"velvet_met"
## The route's legs whose first floor is a spot, after the man's own start in the tutorial: phase 1's start, its
## climb to F's room, phase 2's start and phase 2's way out.
const SPOT_LEGS: Array[int] = [1, 2, 4, 8]
## Physics frames each measure averages over: five seconds.
const MEASURED_FRAMES: int = 300
## Physics frames for the camera to reach the man after he is put at a spot, and for a change of processing to
## settle.
const CAMERA_FRAMES: int = 240
const CHANGE_FRAMES: int = 30
## Priorities that put a Stamp before or after every other node's callbacks.
const FIRST: int = -1000000
const LAST: int = 1000000
## A little above the route's floor, so the man lands on his own.
const ABOVE_FLOOR: float = 2.0

var _level: Node
var _player: Player
var _dogs: Array[Node] = []
var _parallax: Array[Node] = []
var _tracker: ActivityTracker


func _initialize() -> void:
	# The GameState autoload joins the tree on the first frame.
	await process_frame
	(root.get_node(^"GameState") as GameProgress).mark_event(VELVET_MET)
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	_level = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(_level)
	_player = _level.get_node("Player") as Player
	put_a_stand_in(_player)
	_dogs.assign(_level.get_node("Dogs").get_children())
	_collect_parallax(_level)
	_tracker = get_first_node_in_group(ActivityTracker.TRACKER_GROUP) as ActivityTracker
	if _tracker == null:
		printerr("Level 1 has no ActivityTracker.")
		quit(1)
		return
	var first: Stamp = Stamp.new(FIRST)
	var last: Stamp = Stamp.new(LAST)
	root.add_child(first)
	root.add_child(last)
	print("Level 1: %d dogs, %d parallax drawings, %d nodes" % [_dogs.size(), _parallax.size(),
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	var spots: Array[Vector2] = [_player.global_position]
	var route: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROUTE_PATH))
	for leg_index: int in SPOT_LEGS:
		spots.append(_first_floor(route["legs"][leg_index]))
	for spot_index: int in spots.size():
		var spot: Vector2 = spots[spot_index]
		if not await _stand_at(spot):
			printerr("The man never stood at %s." % spot)
			quit(1)
			return
		var on_screen: int = _dogs.filter(func(dog: Node) -> bool:
				return dog is Demon and (dog as Demon).is_on_screen()).size()
		print("At %s, %d dogs on the screen:" % [spot, on_screen])
		var tracker_first: bool = spot_index % 2 == 1
		for tracker_on: bool in [tracker_first, not tracker_first]:
			_tracker.enabled = tracker_on
			await wait_frames(CHANGE_FRAMES)
			var cost: Cost = await _measure(first, last)
			_print("tracker %-3s" % ("on" if tracker_on else "off"), cost,
					", %d of %d members awake" % [_tracker.get_awake_count(), _tracker.get_member_count()]
					if tracker_on else "")
		_tracker.enabled = false
		_set_processing(_dogs, false)
		_set_processing(_parallax, false)
		await wait_frames(CHANGE_FRAMES)
		_print("all off    ", await _measure(first, last), "")
		_set_processing(_dogs, true)
		_set_processing(_parallax, true)
		_tracker.enabled = true
	quit(0)


func _print(what: String, cost: Cost, more: String) -> void:
	print("  %s: whole frame %5.0f us on average, %5.0f us on the worst; physics scripts %5.0f us, process scripts %5.0f us%s"
			% [what, cost.frame, cost.worst_frame, cost.physics_scripts, cost.process_scripts, more])


func _collect_parallax(node: Node) -> void:
	for child: Node in node.get_children():
		if child is ParallaxSprite:
			_parallax.append(child)
		_collect_parallax(child)


## Where the leg's first jump starts: a floor the man stands on.
func _first_floor(leg: Dictionary) -> Vector2:
	for step: Dictionary in leg["steps"]:
		var move: Dictionary = step["move"]
		if move["kind"] == "jump":
			return Vector2(float(move["x"]), float(move["y"]))
	return Vector2.ZERO


## Puts the man just above spot, waits for him to land and for the camera to reach him; false if he never lands.
func _stand_at(spot: Vector2) -> bool:
	_player.global_position = spot - Vector2(0.0, ABOVE_FLOOR)
	_player.velocity = Vector2.ZERO
	var landed: bool = await wait_until_on_floor(_player)
	await wait_frames(CAMERA_FRAMES)
	return landed


func _set_processing(nodes: Array[Node], on: bool) -> void:
	for node: Node in nodes:
		node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## The whole frame and the scripts' time between the two Stamps, over MEASURED_FRAMES frames. Each read runs as a
## physics frame starts, so it reads the frame before, which has run whole by then.
func _measure(first: Stamp, last: Stamp) -> Cost:
	var cost: Cost = Cost.new()
	await physics_frame
	var frame_start: int = Time.get_ticks_usec()
	for _frame: int in MEASURED_FRAMES:
		await physics_frame
		var now: int = Time.get_ticks_usec()
		var frame: float = now - frame_start
		frame_start = now
		cost.frame += frame / MEASURED_FRAMES
		cost.worst_frame = maxf(cost.worst_frame, frame)
		cost.physics_scripts += float(last.physics_usec - first.physics_usec) / MEASURED_FRAMES
		cost.process_scripts += float(last.process_usec - first.process_usec) / MEASURED_FRAMES
	return cost
