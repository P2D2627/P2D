# Checks the ActivityTracker with stand-in members and a camera that only moves when the test moves it: a member
# far off the screen sleeps within a cycle, one on it stays awake, and one between the two margins keeps what it
# was, awake or asleep; a member busy (can_sleep() false) stays awake however far, and sleeps once it is not; a
# member with no can_sleep() sleeps like any other; a jump of the screen wakes all that is near its new place at
# once, not a share at a time (the screen follows the camera a frame or two later, with the physics interpolation
# of ADR 0013, so the test waits for the screen itself); a member woken gets back its own process mode, ALWAYS
# included; a member freed while asleep leaves the counts; turned off, the tracker wakes every member, and on
# again puts the same ones to sleep at once; and with no camera everything wakes. Positions are from the screen's
# own size, which a run without a window sets.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_activity_tracker.gd
extends "res://tests/support/player_test.gd"


## A stand-in member: a square of SIZE px at its position, busy while busy is true, counting its physics frames.
class Member extends Node2D:
	const SIZE: float = 100.0
	var busy: bool = false
	var frames: int = 0

	func _ready() -> void:
		ActivityTracker.join(self)

	func _physics_process(_delta: float) -> void:
		frames += 1

	func get_activity_rect() -> Rect2:
		return Rect2(global_position - Vector2.ONE * SIZE / 2.0, Vector2.ONE * SIZE)

	func can_sleep() -> bool:
		return not busy


## A member that never says whether it may sleep.
class PlainMember extends Node2D:
	func _ready() -> void:
		ActivityTracker.join(self)

	func get_activity_rect() -> Rect2:
		return Rect2(global_position, Vector2.ZERO)


const WAKE_MARGIN: float = 480.0
const SLEEP_MARGIN: float = 960.0
const CYCLE_FRAMES: int = 6
## Far past Sleep Margin, in px from the screen's side.
const FAR: float = 4000.0
## How far apart, in px, the members the screen jumps onto are; and a Cycle Frames slow enough that one member is
## checked on each frame.
const JUMP_SPREAD: float = 200.0
const SLOW_CYCLE_FRAMES: int = 60
## The most frames the screen may take to follow the camera.
const CAMERA_FRAMES: int = 10

var _camera: Camera2D
var _tracker: ActivityTracker
## Half the screen, in px.
var _half: Vector2


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	_half = root.get_visible_rect().size / 2.0
	_camera = Camera2D.new()
	root.add_child(_camera)
	_camera.make_current()
	# A member joins before the tracker is there, and the tracker takes it in as it is ready.
	var early: Member = _member(Vector2.ZERO)
	_tracker = ActivityTracker.new()
	_tracker.wake_margin = WAKE_MARGIN
	_tracker.sleep_margin = SLEEP_MARGIN
	_tracker.cycle_frames = CYCLE_FRAMES
	root.add_child(_tracker)
	var near: Member = _member(Vector2(_half.x - Member.SIZE, 0.0))
	var far: Member = _member(Vector2(_half.x + FAR, 0.0))
	# Its left side is between the margins: past Wake Margin, short of Sleep Margin.
	var between_x: float = _half.x + (WAKE_MARGIN + SLEEP_MARGIN) / 2.0 + Member.SIZE / 2.0
	var between: Member = _member(Vector2(between_x, 0.0))
	var busy: Member = _member(Vector2(-_half.x - FAR, 0.0))
	busy.busy = true
	var always: Member = _member(Vector2(0.0, _half.y + FAR))
	always.process_mode = Node.PROCESS_MODE_ALWAYS
	var landing: Array[Member] = [always, _member(always.position + Vector2(-JUMP_SPREAD, 0.0)),
			_member(always.position + Vector2(JUMP_SPREAD, 0.0))]
	var plain: PlainMember = PlainMember.new()
	plain.position = Vector2(0.0, -_half.y - FAR)
	root.add_child(plain)
	await _steps(CYCLE_FRAMES + 1)

	var results: Array[bool] = []
	results.append(report(_tracker.get_member_count() == 9,
			"all nine members joined, one before the tracker: %d" % _tracker.get_member_count()))
	results.append(report(not _tracker.is_asleep(early) and not _tracker.is_asleep(near),
			"members on the screen are awake"))
	var far_frames: int = far.frames
	await _steps(CYCLE_FRAMES)
	results.append(report(_tracker.is_asleep(far) and far.process_mode == Node.PROCESS_MODE_DISABLED
			and far.frames == far_frames,
			"a member far off the screen sleeps and stops processing: %d frames in a cycle asleep"
			% (far.frames - far_frames)))
	results.append(report(not _tracker.is_asleep(between),
			"an awake member between the margins stays awake"))
	results.append(report(not _tracker.is_asleep(busy), "a busy member stays awake however far it is"))
	results.append(report(_tracker.is_asleep(plain), "a member with no can_sleep() sleeps when far"))
	results.append(report(_tracker.is_asleep(always) and always.process_mode == Node.PROCESS_MODE_DISABLED,
			"a member that processes always sleeps too when far"))
	results.append(report(_tracker.get_awake_count() == 4 and landing.all(_tracker.is_asleep),
			"four of nine are awake: %d" % _tracker.get_awake_count()))

	busy.busy = false
	await _steps(CYCLE_FRAMES)
	results.append(report(_tracker.is_asleep(busy), "a member that stops being busy sleeps"))

	# A step of less than Wake Margin puts the far member between the margins: asleep, it stays asleep.
	var step: float = WAKE_MARGIN / 2.0
	var left_side: float = far.position.x - Member.SIZE / 2.0
	var target: float = left_side - _half.x - (WAKE_MARGIN + SLEEP_MARGIN) / 2.0
	while _camera.position.x + step < target:
		_camera.position.x += step
		await _steps(1)
	await _move_camera(Vector2(target, 0.0))
	await _steps(CYCLE_FRAMES)
	results.append(report(_tracker.is_asleep(far), "an asleep member between the margins stays asleep"))
	await _move_camera(Vector2(left_side - _half.x - WAKE_MARGIN / 2.0, 0.0))
	await _steps(CYCLE_FRAMES)
	results.append(report(not _tracker.is_asleep(far) and far.process_mode == Node.PROCESS_MODE_INHERIT,
			"a member within Wake Margin wakes, with its own process mode back"))

	# A jump: the screen lands on three asleep members. Checked a share at a time, one a frame with this Cycle
	# Frames, the one frame the tracker has seen the screen there would wake one at most.
	_tracker.cycle_frames = SLOW_CYCLE_FRAMES
	await _move_camera(always.position)
	results.append(report(not landing.any(_tracker.is_asleep)
			and always.process_mode == Node.PROCESS_MODE_ALWAYS,
			"a jump of the screen wakes all it lands on at once, with ALWAYS back: %d of 3 still asleep, the screen at %s"
			% [landing.filter(_tracker.is_asleep).size(), _screen().get_center()]))
	_tracker.cycle_frames = CYCLE_FRAMES
	await _steps(CYCLE_FRAMES)

	var asleep_before: int = _tracker.get_member_count() - _tracker.get_awake_count()
	plain.queue_free()
	await _steps(1)
	results.append(report(_tracker.get_member_count() == 8
			and _tracker.get_member_count() - _tracker.get_awake_count() == asleep_before - 1,
			"a member freed asleep leaves the counts: %d members, %d asleep, %d before"
			% [_tracker.get_member_count(), _tracker.get_member_count() - _tracker.get_awake_count(),
					asleep_before]))

	var asleep_on: int = _tracker.get_member_count() - _tracker.get_awake_count()
	_tracker.enabled = false
	var all_awake_at_once: bool = _tracker.get_awake_count() == _tracker.get_member_count()
	await _steps(CYCLE_FRAMES)
	var all_awake_later: bool = _tracker.get_awake_count() == _tracker.get_member_count()
	_tracker.enabled = true
	await _steps(1)
	results.append(report(asleep_on > 0 and all_awake_at_once and all_awake_later
			and _tracker.get_member_count() - _tracker.get_awake_count() == asleep_on,
			"turned off, every member wakes and stays awake; on again, the same %d sleep at once" % asleep_on))

	_camera.queue_free()
	await _steps(2)
	results.append(report(_tracker.get_awake_count() == _tracker.get_member_count(),
			"with no camera every member wakes"))
	finish(results)


## Moves the camera to at, and lets frames run whole until the screen is there: with the project's physics
## interpolation the screen follows the camera a frame or two later. The tracker has then checked once with the
## screen there.
func _move_camera(at: Vector2) -> void:
	_camera.position = at
	for _frame: int in CAMERA_FRAMES:
		await _steps(1)
		if _screen().get_center().is_equal_approx(at):
			return
	push_error("The screen never got to %s." % at)


func _screen() -> Rect2:
	return root.get_canvas_transform().affine_inverse() * root.get_visible_rect()


func _member(at: Vector2) -> Member:
	var member: Member = Member.new()
	member.position = at
	root.add_child(member)
	return member


## Lets frames run whole: the physics, where the tracker checks, and then the process, where the camera moves the
## screen.
func _steps(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame
		await process_frame
