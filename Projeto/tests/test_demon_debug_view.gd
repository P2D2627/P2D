# Smoke test of the demon debug view of the test room. The room has the view, shown and running from
# the start and linked to the room's four demons and its player. Toggle Debug Overlay, on F3, hides
# the view and stops its processing along with the overlay, and F3 again brings both back. Each
# demon's text names the state it is in and follows it when it changes, its seconds starting over
# and stopping in a pause. With two steps on a demon's way back, the view numbers them in the order
# the demon undoes them, the last step 1, and draws them with no error. The room's hiding wall hides the man right behind it from the nearest
# floor demon, not in front of it, and is lower than his Jump Height, so he jumps over it.
# That the view frees itself outside debug builds can only be checked on a release export.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_debug_view.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://levels/test_room.tscn")
const PLAYER_MOVEMENT_STATS: String = "res://player/player_movement_stats.tres"
## The demons the test room puts in.
const ROOM_DEMONS: int = 4
const HIDING_WALL_SHAPE: NodePath = ^"HidingWall/CollisionShape2D"
## Frames to wait before reading the text, which the view writes in _process.
const TEXT_FRAMES: int = 2
## Frames counted in a state, past what the text rounds to 0.0 s, and in the pause.
const COUNT_FRAMES: int = 12
## How far from the hiding wall's middle the man stands, behind it and in front of it, in px, on the
## room's floor, whose top is at ROOM_FLOOR_Y; and the frames for the demon's sight area to find
## him there.
const BESIDE_WALL: float = 100.0
const ROOM_FLOOR_Y: float = 998.0
const SIGHT_FRAMES: int = 3
## How far across and down each step of the made-up way back goes, in px.
const WAY_STEP_ACROSS: float = 100.0
const WAY_STEP_DOWN: float = 96.0


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_test_room_shows_its_demons_and_the_man())
	results.append(await _f3_hides_and_shows_it_with_the_overlay())
	results.append(await _each_demon_s_text_follows_its_state())
	results.append(await _the_hiding_wall_hides_the_man_and_a_jump_clears_it())
	results.append(await _the_way_back_is_numbered_last_step_first())
	finish(results)


## The test room's view is shown and running, with its four demons and the room's player.
func _the_test_room_shows_its_demons_and_the_man() -> bool:
	var room: Node2D = await _make_room()
	var view: DemonDebugView = _view_of(room)
	var linked: bool = view != null and view.demons.size() == ROOM_DEMONS \
			and view.demons.all(func(demon: Demon) -> bool: return is_instance_valid(demon)) \
			and view.player == room.get_node(^"Player")
	var running: bool = view != null and view.visible and view.is_processing()
	var count: int = view.demons.size() if view != null else 0
	await _clear(room)
	return report(linked and running,
			"Test room's demon view: %d demons, linked with the player %s, shown and running %s"
			% [count, linked, running])


## F3 hides the view and stops its processing, with the overlay, and F3 again brings both back.
func _f3_hides_and_shows_it_with_the_overlay() -> bool:
	var room: Node2D = await _make_room()
	var view: DemonDebugView = _view_of(room)
	var overlay: DebugOverlay = room.get_node(^"DebugOverlay") as DebugOverlay
	_press_f3()
	await wait_frames(TEXT_FRAMES)
	var hidden: bool = not view.visible and not view.is_processing() and not overlay.visible
	_press_f3()
	await wait_frames(TEXT_FRAMES)
	var shown: bool = view.visible and view.is_processing() and overlay.visible
	await _clear(room)
	return report(hidden and shown, "F3: view and overlay hidden %s, back %s" % [hidden, shown])


## Each demon's text starts with the name of the state it is in, also after the state changes to
## one it stays in a while: stunned, which lasts Stunned Time. Its seconds start over at the change,
## and stop while the game is paused.
func _each_demon_s_text_follows_its_state() -> bool:
	var room: Node2D = await _make_room()
	var view: DemonDebugView = _view_of(room)
	var demon: Demon = view.demons[0]
	await wait_frames(TEXT_FRAMES)
	var at_first: bool = _names_state(view, 0)
	await wait_frames(COUNT_FRAMES)
	var before_change: String = view.get_text(0)
	demon.change_state(Demon.State.STUNNED)
	await wait_frames(TEXT_FRAMES)
	var text: String = view.get_text(0)
	var after: bool = demon.get_state() == Demon.State.STUNNED and _names_state(view, 0)
	var started_over: bool = text.ends_with(" 0.0 s") and not before_change.ends_with(" 0.0 s")
	paused = true
	await wait_frames(COUNT_FRAMES)
	var stopped: bool = view.get_text(0) == text
	paused = false
	await _clear(room)
	return report(at_first and after and started_over and stopped,
			("Demon text names its state at first %s, once stunned %s ('%s' after '%s'),"
			+ " started over %s, stopped in the pause %s")
			% [at_first, after, text, before_change, started_over, stopped])


## The hiding wall is lower than the man's Jump Height, and from the nearest floor demon it hides the
## man standing right behind it, but not in front of it.
func _the_hiding_wall_hides_the_man_and_a_jump_clears_it() -> bool:
	var room: Node2D = await _make_room()
	var wall: CollisionShape2D = room.get_node_or_null(HIDING_WALL_SHAPE) as CollisionShape2D
	var wall_height: float = wall.shape.get_rect().size.y if wall != null else 0.0
	var stats: PlayerMovementStats = load(PLAYER_MOVEMENT_STATS) as PlayerMovementStats
	var man: Player = room.get_node(^"Player") as Player
	var senses: DemonSenses = room.get_node(^"FloorDemon").get_node(^"%Senses") as DemonSenses
	var wall_x: float = wall.global_position.x if wall != null else 0.0
	man.position = Vector2(wall_x - BESIDE_WALL, ROOM_FLOOR_Y)
	await wait_frames(SIGHT_FRAMES)
	var hidden: bool = not senses.can_see(man)
	man.position = Vector2(wall_x + BESIDE_WALL, ROOM_FLOOR_Y)
	await wait_frames(SIGHT_FRAMES)
	var seen: bool = senses.can_see(man)
	await _clear(room)
	return report(wall_height < stats.jump_height and hidden and seen,
			"Hiding wall %d px high (he jumps %d px): hides him behind it %s, not in front %s"
			% [wall_height, stats.jump_height, hidden, seen])


## A demon, its own physics off so only the test moves it along its way, lands on two floors each
## lower than the last: the view numbers the second step 1 and the first 2, as the demon undoes
## them, and draws them for TEXT_FRAMES frames.
func _the_way_back_is_numbered_last_step_first() -> bool:
	var room: Node2D = await _make_room()
	var view: DemonDebugView = _view_of(room)
	var demon: Demon = view.demons[0]
	demon.set_physics_process(false)
	var way: DemonPath = demon.get_way_back()
	var start: Vector2 = demon.global_position
	for floor_index: int in [1, 2]:
		way.update(start + Vector2(floor_index * WAY_STEP_ACROSS, (floor_index - 1) * WAY_STEP_DOWN),
				true)
		way.update(start + Vector2(floor_index * WAY_STEP_ACROSS, floor_index * WAY_STEP_DOWN),
				false)
		way.update(start + Vector2((floor_index + 1) * WAY_STEP_ACROSS, floor_index * WAY_STEP_DOWN),
				true)
	await wait_frames(TEXT_FRAMES)
	var steps: int = way.size()
	var marks: Array[String] = []
	for step: int in steps:
		marks.append(view.get_step_mark(0, step))
	await _clear(room)
	return report(steps == 2 and marks[0] == "2" and marks[1] == "1",
			"Way back of %d steps, numbered first to last %s" % [steps, marks])


func _make_room() -> Node2D:
	var room: Node2D = TEST_ROOM_SCENE.instantiate() as Node2D
	root.add_child(room)
	await wait_frames(TEXT_FRAMES)
	return room


func _view_of(room: Node2D) -> DemonDebugView:
	for child: Node in room.get_children():
		if child is DemonDebugView:
			return child as DemonDebugView
	return null


## Whether the text of the view's demon at index starts with the name of its state.
func _names_state(view: DemonDebugView, index: int) -> bool:
	var state: Demon.State = view.demons[index].get_state()
	return view.get_text(index).begins_with(Demon.State.keys()[state])


func _press_f3() -> void:
	for pressed: bool in [true, false]:
		var key: InputEventKey = InputEventKey.new()
		key.keycode = KEY_F3
		key.physical_keycode = KEY_F3
		key.pressed = pressed
		root.push_input(key)


func _clear(room: Node2D) -> void:
	room.queue_free()
	await physics_frame
