class_name ActivityTracker
extends Node
## Puts to sleep what is at rest and far off the screen, and wakes it as the screen comes near, so a level only
## pays on each frame for what the man can meet soon; what it draws is left to Godot, which already skips what is
## off the screen. It runs the nodes that join it with join(): each answers get_activity_rect(), the rect of the
## world where it is or acts on the man, and may answer can_sleep(), false while it is busy and has to go on
## wherever it is, as a dog after the man. A member sleeps once its rect is further than Sleep Margin off the screen
## and it can sleep, and wakes once its rect comes within Wake Margin of it; between the two it stays as it is, so
## nothing by the edge keeps switching. Asleep, it is Godot's PROCESS_MODE_DISABLED: no _process nor
## _physics_process, its animations, timers and tweens stop, and its areas leave the physics, but on the screen it is
## still drawn. Woken, it gets back its own process mode. Each member is checked once every Cycle Frames physics
## frames, a share of them on each frame, and all of them at once on the first frame and when the screen jumps
## further than Wake Margin in one frame, as on a respawn. The screen is the camera's view, from the canvas
## transform, so it takes in the zones' zoom and works without a window; with no camera, as in the tests,
## everything stays awake, as the demons' senses count all of the world as the screen.

## The group the tracker is in, for the members to find it, and the one its members are in, for it to find those
## that joined before it was ready.
const TRACKER_GROUP: StringName = &"activity_tracker"
const MEMBER_GROUP: StringName = &"activity"
## What a member answers: the world rect where it is or acts (required), and whether it may sleep now (optional;
## without it, always).
const RECT_METHOD: StringName = &"get_activity_rect"
const SLEEP_METHOD: StringName = &"can_sleep"
## Runs before the nodes it puts to sleep and wakes, so a member woken on a frame is not a frame behind.
const PHYSICS_PRIORITY: int = -100

## How near the screen, in px, a member's rect has to come to wake it: far enough out that it is moving before the
## man can see it.
@export_range(0.0, 4000.0, 8.0, "suffix:px") var wake_margin: float = 480.0
## How far off the screen, in px, a member's rect has to be to put it to sleep, once it can sleep. More than Wake
## Margin, so a member between the two keeps what it was.
@export_range(0.0, 8000.0, 8.0, "suffix:px") var sleep_margin: float = 960.0
## Physics frames over which every member is checked once.
@export_range(1, 60, 1) var cycle_frames: int = 6
## Off, every member is awake, as with no tracker, so the cost can be compared while playing, in the Remote tab;
## turned on again, every member is checked at once.
@export var enabled: bool = true:
	set(value):
		enabled = value
		_had_screen = false
		if not enabled:
			_wake_all()

## Every member, in the order they are checked in, and the next to check.
var _members: Array[Node] = []
var _next: int = 0
## Each member answers can_sleep() or not: found once, as it joins.
var _asks_before_sleep: Dictionary[Node, bool] = {}
## The members asleep, each with its own process mode, given back as it wakes.
var _asleep: Dictionary[Node, ProcessMode] = {}
## The screen's middle on the last frame with a camera, and whether there was one.
var _last_center: Vector2 = Vector2.ZERO
var _had_screen: bool = false


## For a member: joins the tracker the level has, if any. Without one, as in a scene with no GameCamera, it is never
## put to sleep. Call it in _ready; the tracker also takes in the members that joined before it was ready.
static func join(member: Node) -> void:
	member.add_to_group(MEMBER_GROUP)
	var tracker: ActivityTracker = member.get_tree().get_first_node_in_group(TRACKER_GROUP) as ActivityTracker
	if tracker != null:
		tracker._add(member)


func _enter_tree() -> void:
	add_to_group(TRACKER_GROUP)


func _ready() -> void:
	assert(sleep_margin >= wake_margin, "ActivityTracker: Sleep Margin must be no less than Wake Margin.")
	process_physics_priority = PHYSICS_PRIORITY
	for member: Node in get_tree().get_nodes_in_group(MEMBER_GROUP):
		_add(member)


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	var viewport: Viewport = get_viewport()
	if viewport.get_camera_2d() == null:
		_had_screen = false
		_wake_all()
		return
	var screen: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var wake_area: Rect2 = screen.grow(wake_margin)
	var sleep_area: Rect2 = screen.grow(sleep_margin)
	var center: Vector2 = screen.get_center()
	var jumped: bool = not _had_screen or center.distance_to(_last_center) > wake_margin
	_had_screen = true
	_last_center = center
	if jumped:
		for member: Node in _members:
			_check(member, wake_area, sleep_area)
		_next = 0
		return
	for _index: int in ceili(float(_members.size()) / cycle_frames):
		if _next >= _members.size():
			_next = 0
		_check(_members[_next], wake_area, sleep_area)
		_next += 1


## How many members the tracker runs, and how many of them are awake, for the debug overlay.
func get_member_count() -> int:
	return _members.size()


func get_awake_count() -> int:
	return _members.size() - _asleep.size()


## True while member is asleep.
func is_asleep(member: Node) -> bool:
	return _asleep.has(member)


func _add(member: Node) -> void:
	if _asks_before_sleep.has(member):
		return
	assert(member.has_method(RECT_METHOD), "ActivityTracker: a member needs get_activity_rect().")
	_members.append(member)
	_asks_before_sleep[member] = member.has_method(SLEEP_METHOD)
	member.tree_exiting.connect(_remove.bind(member), CONNECT_ONE_SHOT)


func _remove(member: Node) -> void:
	_members.erase(member)
	_asks_before_sleep.erase(member)
	_asleep.erase(member)


func _check(member: Node, wake_area: Rect2, sleep_area: Rect2) -> void:
	var rect: Rect2 = member.call(RECT_METHOD)
	if _asleep.has(member):
		if rect.intersects(wake_area, true):
			_wake(member)
	elif not rect.intersects(sleep_area, true) \
			and (not _asks_before_sleep[member] or member.call(SLEEP_METHOD)):
		_asleep[member] = member.process_mode
		member.process_mode = Node.PROCESS_MODE_DISABLED


func _wake_all() -> void:
	for member: Node in _asleep.keys():
		_wake(member)


func _wake(member: Node) -> void:
	member.process_mode = _asleep[member]
	_asleep.erase(member)
