# Checks the jumps set in the player's Stats: holding Jump peaks at Jump Height, also with other
# Time To Peak values; a tap peaks just above Min Jump Height; pressing Jump again in the air lands
# between the two; and holding Jump through the landing does not jump again.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_height.gd
extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
## How far a measured peak may miss its target, in px.
const TOLERANCE: float = 1.0
## Physics frames to wait for each phase (landing, then the jump) before giving up.
const MAX_FRAMES: int = 300
const GROUND_SIZE: Vector2 = Vector2(2000.0, 100.0)
## A little above the ground, so the player lands on its own before jumping.
const SPAWN_POSITION: Vector2 = Vector2(0.0, -2.0)
## What _measure_jump returns when the player never lands or never jumps.
const NO_JUMP: float = -1.0
## For _measure_jump: a frame in the air that never comes, so Jump is never let go or pressed again.
const NEVER: int = -1
## Frame in the air on which a tap lets go of Jump: the first one.
const TAP: int = 1
## Frame in the air on which the press-again case presses Jump a second time, still going up.
const PRESS_AGAIN_FRAME: int = 3
## Frames Jump stays held in the landing case: one full jump, then over a second on the floor.
const HOLD_THROUGH_LANDING_FRAMES: int = 120
## Time To Peak values for the other-times case: 0.06 and 0.36 s are not a whole number of physics
## frames at 60 per second, and 0.5 s is.
const OTHER_TIMES_TO_PEAK: Array[float] = [0.06, 0.36, 0.5]


func _initialize() -> void:
	root.add_child(_make_ground())
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.position = SPAWN_POSITION
	root.add_child(player)
	var results: Array[bool] = []
	results.append(await _full_jump_peaks_at_jump_height(player))
	results.append(await _tap_peaks_just_above_min_jump_height(player))
	results.append(await _pressing_again_lands_between_tap_and_full_jump(player))
	results.append(await _holding_through_landing_does_not_jump_again(player))
	results.append(await _full_jump_peaks_at_jump_height_for_other_times(player))
	quit(1 if results.has(false) else 0)


## Ground with its top edge at y = 0.
func _make_ground() -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = GROUND_SIZE
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var ground: StaticBody2D = StaticBody2D.new()
	ground.position.y = GROUND_SIZE.y / 2.0
	ground.add_child(collision)
	return ground


func _full_jump_peaks_at_jump_height(player: Player) -> bool:
	var peak: float = await _measure_jump(player, NEVER)
	if peak == NO_JUMP:
		return false
	var expected: float = player.stats.jump_height
	var passed: bool = absf(peak - expected) <= TOLERANCE
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: full jump peak %.1f px, Jump Height %.1f px, tolerance %.1f px"
			% [verdict, peak, expected, TOLERANCE])
	return passed


## The peak must stay on Jump Height for any Time To Peak in the Inspector, not only the default.
## The resource is changed in memory only and set back at the end; the file is never saved.
func _full_jump_peaks_at_jump_height_for_other_times(player: Player) -> bool:
	var original_time_to_peak: float = player.stats.time_to_peak
	var all_passed: bool = true
	for time_to_peak: float in OTHER_TIMES_TO_PEAK:
		player.stats.time_to_peak = time_to_peak
		var peak: float = await _measure_jump(player, NEVER)
		var expected: float = player.stats.jump_height
		var passed: bool = peak != NO_JUMP and absf(peak - expected) <= TOLERANCE
		var verdict: String = "PASS" if passed else "FAIL"
		print("%s: full jump with Time To Peak %.2f s peaks at %.1f px, Jump Height %.1f px"
				% [verdict, time_to_peak, peak, expected])
		all_passed = all_passed and passed
	player.stats.time_to_peak = original_time_to_peak
	return all_passed


func _tap_peaks_just_above_min_jump_height(player: Player) -> bool:
	var peak: float = await _measure_jump(player, TAP)
	if peak == NO_JUMP:
		return false
	var lowest: float = player.stats.min_jump_height - TOLERANCE
	var highest: float = _highest_tap(player)
	var passed: bool = peak >= lowest and peak <= highest
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: tap peak %.1f px, Min Jump Height %.1f px, allowed %.1f to %.1f px"
			% [verdict, peak, player.stats.min_jump_height, lowest, highest])
	return passed


## Speed lost while Jump was let go does not come back: pressing it again goes higher than a tap,
## but never past a full jump.
func _pressing_again_lands_between_tap_and_full_jump(player: Player) -> bool:
	var peak: float = await _measure_jump(player, TAP, PRESS_AGAIN_FRAME)
	if peak == NO_JUMP:
		return false
	var lowest: float = _highest_tap(player)
	var highest: float = player.stats.jump_height + TOLERANCE
	var passed: bool = peak > lowest and peak <= highest
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: tap, then Jump again on frame %d in the air, peak %.1f px, allowed %.1f to %.1f px"
			% [verdict, PRESS_AGAIN_FRAME, peak, lowest, highest])
	return passed


## is_action_just_pressed is true on one frame only, so holding Jump through the landing must not
## make the player take off a second time.
func _holding_through_landing_does_not_jump_again(player: Player) -> bool:
	if not await _wait_until_on_floor(player):
		printerr("FAIL: the player never landed.")
		return false
	var take_offs: int = 0
	var was_on_floor: bool = true
	Input.action_press(&"jump")
	for _frame: int in HOLD_THROUGH_LANDING_FRAMES:
		await physics_frame
		var on_floor: bool = player.is_on_floor()
		if was_on_floor and not on_floor:
			take_offs += 1
		was_on_floor = on_floor
	Input.action_release(&"jump")
	var passed: bool = take_offs == 1
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: Jump held through the landing, %d take-off(s), expected 1" % [verdict, take_offs])
	return passed


## The highest a tap may peak. On the take-off frame the player is still on the floor when gravity
## runs, so that frame rises at full take-off speed and the cut starts on the next one: that frame
## is as far as a tap may go above Min Jump Height.
func _highest_tap(player: Player) -> float:
	var stats: PlayerMovementStats = player.stats
	var one_frame_of_rise: float = stats.get_jump_velocity() * player.get_physics_process_delta_time()
	return stats.min_jump_height + one_frame_of_rise


## Jumps from the floor and returns the peak height in px, or NO_JUMP if that fails. Frames in the
## air count from 1: Jump is let go on release_frame and pressed again on press_again_frame, and
## NEVER skips either one.
func _measure_jump(player: Player, release_frame: int, press_again_frame: int = NEVER) -> float:
	if not await _wait_until_on_floor(player):
		printerr("FAIL: the player never landed.")
		return NO_JUMP
	var start_y: float = player.position.y
	var peak_y: float = start_y
	var frames_in_air: int = 0
	Input.action_press(&"jump")
	for _frame: int in MAX_FRAMES:
		await physics_frame
		peak_y = minf(peak_y, player.position.y)
		if not player.is_on_floor():
			frames_in_air += 1
			if frames_in_air == release_frame:
				Input.action_release(&"jump")
			elif frames_in_air == press_again_frame:
				Input.action_press(&"jump")
		elif frames_in_air > 0:
			break
	Input.action_release(&"jump")
	if frames_in_air == 0:
		printerr("FAIL: the player did not jump.")
		return NO_JUMP
	return start_y - peak_y


func _wait_until_on_floor(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			return true
	return false
