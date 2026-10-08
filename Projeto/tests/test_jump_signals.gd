# Checks the jump signals. A jump off the floor emits jumped, and a jump off a wall emits
# wall_jumped and nothing else, once per jump. Both carry late_frames, how many physics frames after
# leaving the floor or the wall the jump came (0 on it), and buffered_frames, how many frames the
# press of Jump waited in Jump Buffer (0 when it counts on the jump's own frame). Each of the six
# ways to jump is checked at the edge of its tolerance, on the last frame of Coyote Time or of Jump
# Buffer, with the timing of test_coyote_time.gd, test_jump_buffer.gd and test_wall_jump.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_signals.gd
extends "res://tests/support/player_test.gd"

## The floor runs from x = -FLOOR_LENGTH to x = 0, with nothing past it: its right end is a ledge.
const FLOOR_LENGTH: float = 2000.0
## Where the runs start: on the floor, far enough from the ledge to reach top speed.
const RUN_UP_POSITION: Vector2 = Vector2(-1000.0, -2.0)
## Where the drops start: high enough above the floor to reach top falling speed before landing.
const DROP_POSITION: Vector2 = Vector2(-1000.0, -400.0)
## The wall is on the player's left, with its face at x = WALL_FACE, far past the ledge, so the wall
## cases have no floor under them.
const WALL_FACE: float = 5000.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -5000.0
const WALL_BOTTOM: float = 5000.0
## The wall cases start in the air, GAP px from the wall, or FAR_GAP px for the press kept before it.
const WALL_START_HEIGHT: float = 0.0
const GAP: float = 40.0
const FAR_GAP: float = 200.0
## Frames to keep pushing after the first contact, so the player is surely on the wall.
const SETTLE_FRAMES: int = 3
## Frames still watched after the press, so the jump and its signal have time to come.
const FRAMES_TO_WATCH: int = 10

## Half the width of the player's collision box, read from its scene.
var _half_width: float = 0.0
## The frame of a run on which the player is first off the floor, found once, without jumping.
var _off_the_ledge_frame: int = NEVER_REACHED
## The frame of a drop on which the player is first on the floor, found once, without jumping.
var _landing_frame: int = NEVER_REACHED
## Frames from the spawn until a player flying into the wall first touches it, found once.
var _wall_contact_frame: int = NEVER_REACHED


func _initialize() -> void:
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	_half_width = body_size(probe).x / 2.0
	probe.queue_free()
	make_platform(-FLOOR_LENGTH, 0.0)
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP, WALL_BOTTOM)
	_off_the_ledge_frame = await _frames_until_off_the_ledge()
	_landing_frame = await _frames_until_landing()
	_wall_contact_frame = await _frames_until_on_the_wall()
	var results: Array[bool] = []
	results.append(await _a_jump_from_the_floor_is_on_time())
	results.append(await _a_coyote_jump_says_how_late_it_came())
	results.append(await _a_kept_press_says_how_long_it_waited())
	results.append(await _a_wall_jump_says_only_wall_jumped())
	results.append(await _a_late_wall_jump_says_how_late_it_came())
	results.append(await _a_press_kept_for_a_wall_says_how_long_it_waited())
	finish(results)


## On the floor, Jump jumps on the frame it counts: jumped(0, 0).
func _a_jump_from_the_floor_is_on_time() -> bool:
	var what: String = "Jump on the floor"
	var player: Player = await spawn_on_floor(RUN_UP_POSITION)
	if player == null:
		return report(false, "%s: the player never landed" % what)
	var heard: JumpSignals = JumpSignals.new(player)
	Input.action_press(&"jump")
	await _watch(FRAMES_TO_WATCH)
	_release_all()
	await _remove(player)
	return _report_signals(what, heard, ["jumped(0, 0)"])


## Off the ledge, Jump still works on the last frame of Coyote Time, C frames late: jumped(C, 0).
func _a_coyote_jump_says_how_late_it_came() -> bool:
	var what: String = "Jump on the last frame of Coyote Time off the ledge"
	if _off_the_ledge_frame == NEVER_REACHED:
		return report(false, "%s: the player never ran off the ledge" % what)
	var player: Player = await spawn_on_floor(RUN_UP_POSITION)
	if player == null:
		return report(false, "%s: the player never landed" % what)
	var heard: JumpSignals = JumpSignals.new(player)
	var coyote_frames: int = player.stats.get_coyote_frames()
	# Frame k in the air comes _off_the_ledge_frame + k frames into the run, as in
	# test_coyote_time.gd, and a press counts PRESS_DELAY_FRAMES after it is made.
	var press_at: int = _off_the_ledge_frame + coyote_frames - PRESS_DELAY_FRAMES
	Input.action_press(&"move_right")
	for frame: int in press_at + FRAMES_TO_WATCH:
		if frame == press_at:
			Input.action_press(&"jump")
		await physics_frame
	_release_all()
	await _remove(player)
	return _report_signals(what, heard, ["jumped(%d, 0)" % coyote_frames])


## A press made on the last frame of Jump Buffer before the landing jumps as the player lands, after
## waiting B frames: jumped(0, B).
func _a_kept_press_says_how_long_it_waited() -> bool:
	var what: String = "Jump pressed on the last frame of Jump Buffer before the landing"
	if _landing_frame == NEVER_REACHED:
		return report(false, "%s: the player never landed" % what)
	# Like the drop that found _landing_frame, this one starts inside a physics frame.
	await physics_frame
	var player: Player = spawn_player(DROP_POSITION)
	var heard: JumpSignals = JumpSignals.new(player)
	var buffer_frames: int = player.stats.get_jump_buffer_frames()
	# Frame j before the landing comes _landing_frame + 1 - j frames into the drop, as in
	# test_jump_buffer.gd.
	var press_at: int = _landing_frame + 1 - buffer_frames - PRESS_DELAY_FRAMES
	for frame: int in _landing_frame + FRAMES_TO_WATCH:
		if frame == press_at:
			Input.action_press(&"jump")
		await physics_frame
	_release_all()
	await _remove(player)
	return _report_signals(what, heard, ["jumped(0, %d)" % buffer_frames])


## Sliding down a wall, Jump kicks off it on the frame it counts: wall_jumped(0, 0), and no jumped.
func _a_wall_jump_says_only_wall_jumped() -> bool:
	var what: String = "Jump while sliding down a wall"
	var player: Player = await _spawn_sliding()
	if player == null:
		return report(false, "%s: never got on the wall" % what)
	var heard: JumpSignals = JumpSignals.new(player)
	Input.action_press(&"jump")
	await _watch(FRAMES_TO_WATCH)
	_release_all()
	await _remove(player)
	return _report_signals(what, heard, ["wall_jumped(0, 0)"])


## Off the wall, Jump still kicks off it on the last frame of Coyote Time, C frames late:
## wall_jumped(C, 0).
func _a_late_wall_jump_says_how_late_it_came() -> bool:
	var what: String = "Jump on the last frame of Coyote Time off the wall"
	var player: Player = await _spawn_leaving_the_wall()
	if player == null:
		return report(false, "%s: never got on the wall or off it" % what)
	var heard: JumpSignals = JumpSignals.new(player)
	var coyote_frames: int = player.stats.get_coyote_frames()
	# Frame 1 off the wall is about to run, and a press made after w more frames counts on frame
	# w + PRESS_DELAY_FRAMES off the wall, as in test_wall_jump.gd: here, the last of Coyote Time's.
	await _watch(coyote_frames - PRESS_DELAY_FRAMES)
	Input.action_press(&"jump")
	await _watch(FRAMES_TO_WATCH)
	_release_all()
	await _remove(player)
	return _report_signals(what, heard, ["wall_jumped(%d, 0)" % coyote_frames])


## A press made on the last frame of Jump Buffer before touching a wall kicks off it on the first
## frame against it, after waiting B frames: wall_jumped(0, B).
func _a_press_kept_for_a_wall_says_how_long_it_waited() -> bool:
	var what: String = "Jump pressed on the last frame of Jump Buffer before touching a wall"
	if _wall_contact_frame == NEVER_REACHED:
		return report(false, "%s: never reached the wall" % what)
	var player: Player = _spawn_flying_into_the_wall()
	var heard: JumpSignals = JumpSignals.new(player)
	var buffer_frames: int = player.stats.get_jump_buffer_frames()
	# The first frame against the wall is _wall_contact_frame + 1. A press made after f frames counts
	# on frame f + PRESS_DELAY_FRAMES and is kept for Jump Buffer's frames after it.
	await _watch(_wall_contact_frame + 1 - PRESS_DELAY_FRAMES - buffer_frames)
	Input.action_press(&"jump")
	await _watch(FRAMES_TO_WATCH)
	_release_all()
	await _remove(player)
	return _report_signals(what, heard, ["wall_jumped(0, %d)" % buffer_frames])


## Runs right from the run-up spot without jumping and returns the frame of the run on which the
## player is first off the floor, or NEVER_REACHED.
func _frames_until_off_the_ledge() -> int:
	var player: Player = await spawn_on_floor(RUN_UP_POSITION)
	if player == null:
		return NEVER_REACHED
	var frames: int = NEVER_REACHED
	Input.action_press(&"move_right")
	for frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor():
			frames = frame + 1
			break
	_release_all()
	await _remove(player)
	return frames


## Drops the player without jumping and returns the frame of the drop on which it is first on the
## floor, or NEVER_REACHED. Like every drop, it starts inside a physics frame.
func _frames_until_landing() -> int:
	await physics_frame
	var player: Player = spawn_player(DROP_POSITION)
	var frames: int = NEVER_REACHED
	for frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			frames = frame + 1
			break
	await _remove(player)
	return frames


## Frames from the spawn until a player flying into the wall first touches it, or NEVER_REACHED.
func _frames_until_on_the_wall() -> int:
	var player: Player = _spawn_flying_into_the_wall()
	var frames: int = NEVER_REACHED
	for frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			frames = frame + 1
			break
	_release_all()
	await _remove(player)
	return frames


## The x at which the side of the player's body is gap px from the wall on its left.
func _x_near_the_wall(gap: float) -> float:
	return WALL_FACE + _half_width + gap


## A player in the air FAR_GAP px from the wall on its left, pushing toward it.
func _spawn_flying_into_the_wall() -> Player:
	var player: Player = spawn_player(Vector2(_x_near_the_wall(FAR_GAP), WALL_START_HEIGHT))
	Input.action_press(&"move_left")
	return player


## A player sliding down the wall on its left, still pushing into it. Null, with nothing held, if it
## never gets on the wall.
func _spawn_sliding() -> Player:
	var player: Player = spawn_player(Vector2(_x_near_the_wall(GAP), WALL_START_HEIGHT))
	Input.action_press(&"move_left")
	if not await _wait_until_on_wall(player):
		_release_all()
		await _remove(player)
		return null
	await _watch(SETTLE_FRAMES)
	return player


## A player that slid down the wall on its left and has just left it, pushing away from it, with
## that push still held. Null, with nothing held, if it never got on the wall or off it.
func _spawn_leaving_the_wall() -> Player:
	var player: Player = await _spawn_sliding()
	if player == null:
		return null
	Input.action_release(&"move_left")
	Input.action_press(&"move_right")
	if not await _wait_until_off_the_wall(player):
		_release_all()
		await _remove(player)
		return null
	return player


func _wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


func _wait_until_off_the_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_wall():
			return true
	return false


func _watch(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


func _release_all() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame


## PASS if the player emitted exactly the expected jump signals, in order.
func _report_signals(what: String, heard: JumpSignals, expected: PackedStringArray) -> bool:
	if not heard.missing.is_empty():
		return report(false, "%s: the player has no %s signal" % [what, " or ".join(heard.missing)])
	return report(heard.entries == expected, "%s: heard [%s], expected [%s]"
			% [what, ", ".join(heard.entries), ", ".join(expected)])


## The jump signals a player emits, in order, as text: "jumped(late_frames, buffered_frames)" or
## "wall_jumped(late_frames, buffered_frames)". missing names the signals the player does not have.
class JumpSignals:
	var entries: PackedStringArray = []
	var missing: PackedStringArray = []

	func _init(player: Player) -> void:
		for signal_name: StringName in [&"jumped", &"wall_jumped"]:
			if player.has_signal(signal_name):
				player.connect(signal_name, _record.bind(signal_name))
			else:
				missing.append(signal_name)

	func _record(late_frames: int, buffered_frames: int, signal_name: StringName) -> void:
		entries.append("%s(%d, %d)" % [signal_name, late_frames, buffered_frames])
