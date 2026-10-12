# Checks that the player moves only by what its PlayerInput says. With the scene's own
# PlayerInput, the keyboard moves it. With a stand-in that the case drives, and no key pressed, it
# runs, jumps, holds a jump up to Jump Height and pushes into a wall; and while the stand-in is in
# place, keys pressed on the keyboard do nothing.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_input.gd
extends "res://tests/support/player_test.gd"

## The wall's face is at x = WALL_FACE, on the player's left; the floor's top is at y = 0.
const WALL_FACE: float = 0.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -3000.0
const FLOOR_RIGHT: float = 4000.0
## Where a case on the floor starts: just above it, and far from the wall and the floor's end.
const FLOOR_START: Vector2 = Vector2(2000.0, -2.0)
## How far from the wall, in px, a fall into it starts.
const GAP: float = 40.0
## Where a fall into the wall starts: high enough to reach the wall well before the floor.
const FALL_HEIGHT: float = -1500.0
## Physics frames a case watches the player for; a run reaches top speed in 6.
const FRAMES_TO_WATCH: int = 30
## Frames to wait after the first contact with the wall, so the player is surely on it.
const SETTLE_FRAMES: int = 3
## How far a peak may be from Jump Height, in px, as in test_jump_height.gd.
const HEIGHT_TOLERANCE: float = 1.0

## Half the width of the player's collision box, read from its scene.
var _half_width: float = 0.0


func _initialize() -> void:
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP)
	make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	_half_width = body_size(probe).x / 2.0
	probe.queue_free()
	var results: Array[bool] = []
	results.append(await _the_keyboard_moves_the_player_through_its_own_player_input())
	results.append(await _runs_where_the_stand_in_says_with_no_key_pressed())
	results.append(await _jumps_when_the_stand_in_says_with_no_key_pressed())
	results.append(await _a_jump_the_stand_in_holds_peaks_at_jump_height())
	results.append(await _pushes_into_a_wall_when_the_stand_in_says())
	results.append(await _keys_do_nothing_while_a_stand_in_is_in_place())
	finish(results)


## The scene's own PlayerInput is a child of the player and reads the keyboard: holding Run right
## moves the player right.
func _the_keyboard_moves_the_player_through_its_own_player_input() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The scene's own PlayerInput: the player never landed")
	var own_child: bool = player.input != null and player.input.get_parent() == player
	Input.action_press(&"move_right")
	await _wait_frames(FRAMES_TO_WATCH)
	Input.action_release(&"move_right")
	var speed: float = player.velocity.x
	await _remove(player)
	return report(own_child and speed > 0.0,
			"The scene's own PlayerInput: a child of the player %s, speed %.1f px/s holding Run right"
			% [own_child, speed])


## A stand-in that says "run right" takes the player to top speed to the right, with no key pressed.
func _runs_where_the_stand_in_says_with_no_key_pressed() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Running on the stand-in's word: the player never landed")
	var stand_in: StandInInput = _put_a_stand_in(player)
	stand_in.run_direction = 1.0
	await _wait_frames(FRAMES_TO_WATCH)
	var speed: float = player.velocity.x
	var top_speed: float = player.stats.max_run_speed
	await _remove(player)
	return report(is_equal_approx(speed, top_speed),
			"Running on the stand-in's word: speed %.1f px/s, Max Run Speed %.1f px/s"
			% [speed, top_speed])


## A stand-in that presses Jump makes the player jump, with no key pressed.
func _jumps_when_the_stand_in_says_with_no_key_pressed() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Jumping on the stand-in's word: the player never landed")
	var stand_in: StandInInput = _put_a_stand_in(player)
	stand_in.press_jump()
	var rose: bool = await _wait_until_rising(player)
	await _remove(player)
	return report(rose, "Jumping on the stand-in's word: left the floor going up %s" % rose)


## A stand-in that presses Jump and holds it gives a full jump, up to Jump Height, so the gravity
## of the jump also asks the input whether Jump is held.
func _a_jump_the_stand_in_holds_peaks_at_jump_height() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Holding the stand-in's jump: the player never landed")
	var stand_in: StandInInput = _put_a_stand_in(player)
	var floor_y: float = player.position.y
	stand_in.hold_jump = true
	stand_in.press_jump()
	var peak: float = await _peak_height(player, floor_y)
	var expected: float = player.stats.jump_height
	await _remove(player)
	return report(absf(peak - expected) <= HEIGHT_TOLERANCE,
			"Holding the stand-in's jump: peak %.1f px, Jump Height %.1f px, tolerance %.1f px"
			% [peak, expected, HEIGHT_TOLERANCE])


## A stand-in that says "run left", into the wall, puts the player on the wall, so the push into
## the wall also asks the input for the direction.
func _pushes_into_a_wall_when_the_stand_in_says() -> bool:
	var player: Player = spawn_player(Vector2(_x_near_the_wall(GAP), FALL_HEIGHT))
	var stand_in: StandInInput = _put_a_stand_in(player)
	stand_in.run_direction = -1.0
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	var state: Player.State = player.get_state()
	await _remove(player)
	return report(touched and state == Player.State.ON_WALL,
			"Pushing into the wall on the stand-in's word: state %s%s"
			% [Player.State.find_key(state), "" if touched else " (never reached the wall)"])


## With a stand-in that says nothing, holding Run right and pressing Jump on the keyboard leave the
## player standing where it was: nothing reads the keyboard for it any more.
func _keys_do_nothing_while_a_stand_in_is_in_place() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Keys with a stand-in in place: the player never landed")
	var stand_in: StandInInput = _put_a_stand_in(player)
	stand_in.run_direction = 0.0
	var start_x: float = player.position.x
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	await _wait_frames(FRAMES_TO_WATCH)
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	var moved: float = player.position.x - start_x
	var on_floor: bool = player.is_on_floor()
	await _remove(player)
	return report(is_zero_approx(moved) and on_floor,
			"Keys with a stand-in in place: moved %.1f px, on the floor %s" % [moved, on_floor])


## Puts a stand-in in the player's input, as a child of the player, and hands it back.
func _put_a_stand_in(player: Player) -> StandInInput:
	var stand_in: StandInInput = StandInInput.new()
	player.add_child(stand_in)
	player.input = stand_in
	return stand_in


## The x at which the side of the player's body is gap px from the wall.
func _x_near_the_wall(gap: float) -> float:
	return WALL_FACE + _half_width + gap


func _wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


## True once the player is off the floor and going up, which only a jump does here.
func _wait_until_rising(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor() and player.velocity.y < 0.0:
			return true
	return false


func _wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


## How high the feet go above floor_y before the player lands again, in px; 0 if it never leaves
## the floor.
func _peak_height(player: Player, floor_y: float) -> float:
	var highest_y: float = floor_y
	var left_floor: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			if left_floor:
				break
			continue
		left_floor = true
		highest_y = minf(highest_y, player.position.y)
	return floor_y - highest_y


func _remove(player: Player) -> void:
	player.queue_free()
	await physics_frame


## A PlayerInput the case drives by hand: it never reads the keyboard, only what the case sets.
class StandInInput extends PlayerInput:
	## What _press_frame holds before the first press.
	const NO_PRESS: int = -1

	var run_direction: float = 0.0
	var hold_jump: bool = false
	## The physics frame of the last press of Jump.
	var _press_frame: int = NO_PRESS

	## Jump counts as just pressed for the whole of the current physics frame, as on the keyboard,
	## however many times the player asks in it.
	func press_jump() -> void:
		_press_frame = Engine.get_physics_frames()

	func get_run_direction() -> float:
		return run_direction

	func is_jump_just_pressed() -> bool:
		return Engine.get_physics_frames() == _press_frame

	func is_jump_held() -> bool:
		return hold_jump
