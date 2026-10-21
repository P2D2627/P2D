# Checks that something else, such as the grab, can keep the crucifix down (ADR 0021). Blocked
# while up, it goes down at once, says so once and starts the cooldown, and the player runs and
# jumps in full again. While blocked, a press raises nothing; after the block, Crucifix held since
# then raises nothing until it is pressed again. It stays down while any source keeps it there,
# blocking twice for one source is the same as once, and unblocking a source that kept nothing down
# changes nothing. After lose(), a block does nothing.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_block.gd
extends "res://tests/support/player_test.gd"

## The floor runs from FLOOR_LEFT to FLOOR_RIGHT with its top at y = 0; the player starts on it.
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const START: Vector2 = Vector2(0.0, -2.0)
## Physics frames for a press or a block to take effect.
const SETTLE_FRAMES: int = 3
## Physics frames Crucifix is held to see the crucifix stay down: longer than Raise Buffer Time.
const HOLD_FRAMES: int = 30
## Sources that keep the crucifix down in the cases, and one that never does.
const GRAB: StringName = &"grab"
const OTHER: StringName = &"dialogue"
const NOBODY: StringName = &"nobody"


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _blocked_while_up_it_goes_down_and_cools_down())
	results.append(await _while_blocked_a_press_raises_nothing())
	results.append(await _after_the_block_it_waits_for_a_fresh_press())
	results.append(await _it_stays_down_while_any_source_keeps_it())
	results.append(await _after_lose_a_block_does_nothing())
	finish(results)


func _blocked_while_up_it_goes_down_and_cools_down() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Blocked while up: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	var heard: Array[StringName] = _signals_of(crucifix)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_before: bool = crucifix.is_raised()
	crucifix.block(GRAB)
	var phase: Crucifix.Phase = crucifix.get_phase()
	var full_movement: bool = (is_equal_approx(player.get_speed_multiplier(), 1.0)
			and not player.is_jump_blocked())
	await remove_player(player)
	return report(up_before and phase == Crucifix.Phase.COOLDOWN and full_movement
			and heard == [&"raised", &"lowered", &"cooldown_started"],
			"Blocked while up %s: phase %s, signals %s, full run and jump %s"
			% [up_before, Crucifix.Phase.find_key(phase), heard, full_movement])


## Blocked while ready, Crucifix pressed and held for longer than Raise Buffer Time raises nothing.
func _while_blocked_a_press_raises_nothing() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Pressed while blocked: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	var heard: Array[StringName] = _signals_of(crucifix)
	crucifix.block(GRAB)
	stand_in.crucifix_held = true
	var went_up: bool = await wait_until(func() -> bool: return crucifix.is_raised(), HOLD_FRAMES)
	var blocked: bool = crucifix.is_blocked()
	await remove_player(player)
	return report(blocked and not went_up and heard.is_empty(),
			"Pressed and held %d frames while blocked %s: went up %s, signals %s"
			% [HOLD_FRAMES, blocked, went_up, heard])


## Crucifix pressed while blocked, and still held after unblock(), raises nothing; let go and
## pressed again, it goes up.
func _after_the_block_it_waits_for_a_fresh_press() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Held through the block: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	crucifix.block(GRAB)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	crucifix.unblock(GRAB)
	await wait_frames(HOLD_FRAMES)
	var up_while_held: bool = crucifix.is_raised()
	stand_in.crucifix_held = false
	await physics_frame
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_after_fresh_press: bool = crucifix.is_raised()
	await remove_player(player)
	return report(not up_while_held and up_after_fresh_press,
			"Held through the block: up while still held %s, up after a fresh press %s"
			% [up_while_held, up_after_fresh_press])


## Blocked twice by GRAB and once by OTHER: unblocking NOBODY and then GRAB, once, leaves it down for
## OTHER, even with a press; unblocking OTHER lets a fresh press raise it.
func _it_stays_down_while_any_source_keeps_it() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Two sources: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	var is_up: Callable = func() -> bool: return crucifix.is_raised()
	crucifix.block(GRAB)
	crucifix.block(GRAB)
	crucifix.block(OTHER)
	crucifix.unblock(NOBODY)
	crucifix.unblock(GRAB)
	var blocked_by_other: bool = crucifix.is_blocked()
	stand_in.crucifix_held = true
	var up_with_other: bool = await wait_until(is_up, HOLD_FRAMES)
	stand_in.crucifix_held = false
	crucifix.unblock(OTHER)
	var free: bool = not crucifix.is_blocked()
	await physics_frame
	stand_in.crucifix_held = true
	var up_after: bool = await wait_until(is_up, SETTLE_FRAMES)
	await remove_player(player)
	return report(blocked_by_other and not up_with_other and free and up_after,
			("Two sources, one blocked twice: still blocked by the other %s, up with a press %s; "
			+ "both unblocked %s, up after a fresh press %s")
			% [blocked_by_other, up_with_other, free, up_after])


## lose() and then block() on the same frame: it went down once, and the block kept nothing.
func _after_lose_a_block_does_nothing() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Blocked after lose: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_before: bool = crucifix.is_raised()
	var heard: Array[StringName] = _signals_of(crucifix)
	crucifix.lose()
	crucifix.block(GRAB)
	var blocked: bool = crucifix.is_blocked()
	await remove_player(player)
	return report(up_before and not blocked and heard == [&"lowered", &"lost"],
			"Up %s, lost and blocked on one frame: signals %s, blocked %s"
			% [up_before, heard, blocked])


func _crucifix_of(player: Player) -> Crucifix:
	return player.get_node(^"Crucifix") as Crucifix


## The names of the crucifix's signals, in the order they come from now on.
func _signals_of(crucifix: Crucifix) -> Array[StringName]:
	var heard: Array[StringName] = []
	crucifix.raised.connect(func() -> void: heard.append(&"raised"))
	crucifix.lowered.connect(func() -> void: heard.append(&"lowered"))
	crucifix.cooldown_started.connect(
			func(_duration: float) -> void: heard.append(&"cooldown_started"))
	crucifix.lost.connect(func() -> void: heard.append(&"lost"))
	return heard
