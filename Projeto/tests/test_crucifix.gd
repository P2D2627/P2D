# Checks the crucifix and the movement modifiers it uses. A modifier's shares multiply with the
# others', a value changed while it is on takes effect at once, a share of the jump's height lowers
# the full jump and a share of the speed slows the wall jump. The crucifix's action is the left
# mouse button and R2. A press of Crucifix on the floor raises it, through the player's own input or
# a stand-in; up, it slows the run by Crucifix Stats, stops every jump, lights up and heals, and
# letting go gives the full movement back with no jump left over. A press a moment before landing
# raises it on landing; one made long before raises nothing until Crucifix is pressed again. It
# never goes up on a wall, and leaving the floor lowers it. A use lasts at most Max Use Time, every
# use is followed by the whole Cooldown Time, Crucifix held through both raises nothing, a press
# just before the cooldown ends raises it then, and the pause stops the use. Lost, it goes down,
# says so once and leaves the game, also from the cooldown. It pushes a Repellable inside its radius
# out of it while one outside stays put, and the Repellable scene is on the layer the crucifix looks
# on. A new radius or slowdown in Stats takes effect at once. No demon exists yet, so a bare
# CharacterBody2D with a Repellable stands in for one. The timing cases use short times on their own
# copy of Crucifix Stats, so they do not wait 20 s each.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix.gd
extends "res://tests/support/player_test.gd"

const REPELLABLE_SCENE: PackedScene = preload("res://components/repellable.tscn")
## The wall's face is at x = WALL_FACE, on the player's left; the floor's top is at y = 0.
const WALL_FACE: float = 0.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -3000.0
const FLOOR_RIGHT: float = 6000.0
## Where a case on the floor starts: just above it, and far from the wall and the floor's end.
const FLOOR_START: Vector2 = Vector2(2000.0, -2.0)
## Where a fall starts: high enough to reach the wall well before the floor.
const FALL_HEIGHT: float = -1500.0
## How far from the wall, in px, a fall into it starts.
const GAP: float = 40.0
## A short platform, away from the main floor, to walk off: from x = LEDGE_LEFT to x = LEDGE_RIGHT.
const LEDGE_LEFT: float = 8000.0
const LEDGE_RIGHT: float = 8200.0
## Where the case that walks off the ledge starts.
const LEDGE_START: Vector2 = Vector2(8100.0, -2.0)
## Physics frames a case watches the player for; a run reaches top speed in 6.
const FRAMES_TO_WATCH: int = 30
## Frames to wait after a press or a contact, so what follows from it has surely happened.
const SETTLE_FRAMES: int = 3
## Frames kept away from the edge of Raise Buffer Time in the landing and cooldown cases, so a frame
## more or less in the timing does not change the outcome.
const BUFFER_MARGIN_FRAMES: int = 2
## How far a peak may be from the expected height, in px. The half-frame correction is exact only at
## the full take-off speed, so a scaled one lands a little off.
const HEIGHT_TOLERANCE: float = 3.0
## How far the healing of one second may be from Heal Per Second, in SP.
const HEAL_TOLERANCE: float = 0.01
## Radius of the stand-in demon's Repellable, in px.
const DEMON_RADIUS: float = 16.0
## Where the near stand-in demon starts, from the crucifix: well inside the radius.
const NEAR_OFFSET: Vector2 = Vector2(80.0, 0.0)
## Where the far stand-in demon starts, from the crucifix: well outside the radius.
const FAR_OFFSET: Vector2 = Vector2(-600.0, 0.0)
## Max Use Time and Cooldown Time of the timing cases, in s: 30 and 60 frames.
const SHORT_USE_TIME: float = 0.5
const SHORT_COOLDOWN_TIME: float = 1.0
## Frames a short use lasts before Crucifix is let go, in the case of the short use.
const SHORT_HOLD_FRAMES: int = 10
## The share the modifier cases use.
const HALF: float = 0.5
## The values the case that tunes Stats while the game runs changes to.
const TUNED_RADIUS: float = 300.0
const TUNED_SPEED_MULTIPLIER: float = 0.5
## Physics frames the game stays paused in the case of the pause.
const PAUSE_FRAMES: int = 30
## The name the project gives the physics layer of Repellable.
const REPELLABLE_LAYER_NAME: String = "repellable"
## The number of named 2D physics layers the project settings can hold.
const PHYSICS_LAYERS: int = 32

## Half the width of the player's collision box, read from its scene.
var _half_width: float = 0.0


func _initialize() -> void:
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP)
	make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	make_platform(LEDGE_LEFT, LEDGE_RIGHT)
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	_half_width = body_size(probe).x / 2.0
	probe.queue_free()
	var results: Array[bool] = []
	results.append(await _modifiers_combine_and_come_off())
	results.append(await _a_value_changed_while_on_takes_effect_at_once())
	results.append(await _a_share_of_the_jump_height_lowers_the_full_jump())
	results.append(await _a_share_of_the_speed_slows_the_wall_jump())
	results.append(_the_crucifix_action_is_the_left_mouse_button_and_r2())
	results.append(await _the_crucifix_action_raises_it_through_the_players_own_input())
	results.append(await _holding_it_slows_the_run_to_its_share())
	results.append(await _letting_go_gives_the_full_speed_back())
	results.append(await _no_jump_while_it_is_up_nor_left_over_after())
	results.append(await _a_press_just_before_landing_raises_it_on_landing())
	results.append(await _a_press_long_before_landing_raises_nothing_until_pressed_again())
	results.append(await _a_press_on_a_wall_raises_nothing())
	results.append(await _leaving_the_floor_lowers_it_and_starts_the_cooldown())
	results.append(await _a_use_lasts_at_most_max_use_time())
	results.append(await _a_short_use_still_takes_the_whole_cooldown())
	results.append(await _held_through_the_cooldown_it_waits_for_a_fresh_press())
	results.append(await _a_press_just_before_the_cooldown_ends_raises_it_then())
	results.append(await _the_pause_stops_the_use_and_letting_go_in_it_lowers_it())
	results.append(await _lost_it_goes_down_says_so_once_and_leaves_the_game())
	results.append(await _lost_during_the_cooldown_it_also_leaves_the_game())
	results.append(await _one_second_up_heals_heal_per_second())
	results.append(await _it_pushes_a_repellable_inside_out_and_leaves_one_outside())
	results.append(_the_repellable_scene_is_on_the_layer_the_crucifix_looks_on())
	results.append(await _a_new_radius_or_slowdown_in_stats_takes_effect_at_once())
	finish(results)


## Two modifiers on the player multiply their shares, and one that blocks jumping blocks it for
## both; taking one off leaves only the other's, and taking both off gives the full movement back.
func _modifiers_combine_and_come_off() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Modifiers: the player never landed")
	player.add_movement_modifier(&"a", MovementModifier.new(0.5, 0.8, true))
	player.add_movement_modifier(&"b", MovementModifier.new(0.5, 0.5))
	var both: Vector2 = Vector2(player.get_speed_multiplier(), player.get_jump_height_multiplier())
	var both_block: bool = player.is_jump_blocked()
	player.remove_movement_modifier(&"a")
	var one: Vector2 = Vector2(player.get_speed_multiplier(), player.get_jump_height_multiplier())
	var one_blocks: bool = player.is_jump_blocked()
	player.remove_movement_modifier(&"b")
	var none: Vector2 = Vector2(player.get_speed_multiplier(), player.get_jump_height_multiplier())
	await remove_player(player)
	var passed: bool = both.is_equal_approx(Vector2(0.25, 0.4)) and both_block \
			and one.is_equal_approx(Vector2(0.5, 0.5)) and not one_blocks \
			and none.is_equal_approx(Vector2.ONE)
	return report(passed,
			"Modifiers: both %s blocking %s, one %s blocking %s, none %s (speed, jump height)"
			% [both, both_block, one, one_blocks, none])


## A modifier changed while it is on changes the player at once. Put on under two sources and taken
## off under one, it still does; taken off under both, it no longer does.
func _a_value_changed_while_on_takes_effect_at_once() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "A changed modifier: the player never landed")
	var modifier: MovementModifier = MovementModifier.new(HALF)
	player.add_movement_modifier(&"a", modifier)
	modifier.speed_multiplier = 0.25
	var changed: float = player.get_speed_multiplier()
	modifier.blocks_jump = true
	var blocks: bool = player.is_jump_blocked()
	player.add_movement_modifier(&"b", modifier)
	player.remove_movement_modifier(&"b")
	modifier.speed_multiplier = HALF
	var still_heard: float = player.get_speed_multiplier()
	player.remove_movement_modifier(&"a")
	modifier.speed_multiplier = 0.1
	var off: float = player.get_speed_multiplier()
	await remove_player(player)
	return report(is_equal_approx(changed, 0.25) and blocks and is_equal_approx(still_heard, HALF)
			and is_equal_approx(off, 1.0),
			"A changed modifier: speed share %.2f after the change, jump blocked %s; %.2f after one of two sources took it off; %.2f once off"
			% [changed, blocks, still_heard, off])


## A full jump with a modifier that keeps half the jump's height peaks at half Jump Height.
func _a_share_of_the_jump_height_lowers_the_full_jump() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "A share of the jump's height: the player never landed")
	player.add_movement_modifier(&"test", MovementModifier.new(1.0, HALF))
	var stand_in: StandInInput = put_a_stand_in(player)
	var floor_y: float = player.position.y
	stand_in.hold_jump = true
	stand_in.press_jump()
	var peak: float = await peak_height(player, floor_y)
	var expected: float = player.stats.jump_height * HALF
	await remove_player(player)
	return report(absf(peak - expected) <= HEIGHT_TOLERANCE,
			"A share of the jump's height: peak %.1f px, expected %.1f px, tolerance %.1f px"
			% [peak, expected, HEIGHT_TOLERANCE])


## A wall jump with a modifier that keeps half the speed leaves the wall at half Max Run Speed.
func _a_share_of_the_speed_slows_the_wall_jump() -> bool:
	var player: Player = spawn_player(Vector2(_x_near_the_wall(GAP), FALL_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = -1.0
	var touched: bool = await wait_until_on_wall(player)
	await wait_frames(SETTLE_FRAMES)
	player.add_movement_modifier(&"test", MovementModifier.new(HALF))
	var kick: Array[float] = [0.0]
	player.wall_jumped.connect(func(_late_frames: int, _buffered_frames: int) -> void:
		kick[0] = player.velocity.x)
	stand_in.press_jump()
	await wait_frames(SETTLE_FRAMES)
	var expected: float = player.stats.max_run_speed * HALF
	await remove_player(player)
	return report(touched and is_equal_approx(kick[0], expected),
			"A share of the speed on a wall jump: left the wall at %.1f px/s, expected %.1f px/s%s"
			% [kick[0], expected, "" if touched else " (never reached the wall)"])


## The Input Map binds Crucifix to the left mouse button and to R2 pulled all the way, and to no key.
func _the_crucifix_action_is_the_left_mouse_button_and_r2() -> bool:
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	var trigger: InputEventJoypadMotion = InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	var by_mouse: bool = InputMap.event_is_action(mouse, &"crucifix", true)
	var by_trigger: bool = InputMap.event_is_action(trigger, &"crucifix", true)
	var keys: int = 0
	for event: InputEvent in InputMap.action_get_events(&"crucifix"):
		if event is InputEventKey:
			keys += 1
	return report(by_mouse and by_trigger and keys == 0,
			"The Crucifix action: left mouse button %s, R2 %s, keys %d" % [by_mouse, by_trigger, keys])


## The scene's own PlayerInput reads the Crucifix action: pressing it raises the crucifix, lights it
## up and shows it, and letting go lowers it again.
func _the_crucifix_action_raises_it_through_the_players_own_input() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The Crucifix action: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var light: PointLight2D = crucifix.get_node(^"%Light") as PointLight2D
	Input.action_press(&"crucifix")
	await wait_frames(SETTLE_FRAMES)
	var up: bool = crucifix.is_raised()
	var lit: bool = light.enabled
	Input.action_release(&"crucifix")
	await wait_frames(SETTLE_FRAMES)
	var down: bool = not crucifix.is_raised() and not light.enabled
	await remove_player(player)
	return report(up and lit and down,
			"The Crucifix action: up after a press %s, lit %s, down and dark after letting go %s"
			% [up, lit, down])


## Running right with the crucifix up reaches Max Run Speed times Speed Multiplier, no more.
func _holding_it_slows_the_run_to_its_share() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Running with the crucifix: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	stand_in.run_direction = 1.0
	await wait_frames(FRAMES_TO_WATCH)
	var speed: float = player.velocity.x
	var expected: float = player.stats.max_run_speed * _crucifix_of(player).stats.speed_multiplier
	await remove_player(player)
	return report(is_equal_approx(speed, expected),
			"Running with the crucifix: speed %.1f px/s, expected %.1f px/s" % [speed, expected])


## Letting go of the crucifix while running takes the player back up to Max Run Speed.
func _letting_go_gives_the_full_speed_back() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Letting go of the crucifix: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	stand_in.run_direction = 1.0
	await wait_frames(FRAMES_TO_WATCH)
	stand_in.crucifix_held = false
	await wait_frames(FRAMES_TO_WATCH)
	var speed: float = player.velocity.x
	var top_speed: float = player.stats.max_run_speed
	await remove_player(player)
	return report(is_equal_approx(speed, top_speed),
			"Letting go of the crucifix: speed %.1f px/s, Max Run Speed %.1f px/s"
			% [speed, top_speed])


## With the crucifix up, a press of Jump leaves the player on the floor and the crucifix up. Letting
## go of the crucifix then does not jump by itself, from a press kept from before, and a fresh press
## of Jump jumps, cooldown or not.
func _no_jump_while_it_is_up_nor_left_over_after() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Jumping with the crucifix up: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	stand_in.press_jump()
	var jumped_while_up: bool = await _leaves_the_floor_within(player, FRAMES_TO_WATCH)
	var still_up: bool = crucifix.is_raised()
	stand_in.press_jump()
	await physics_frame
	stand_in.crucifix_held = false
	var jumped_after: bool = await _leaves_the_floor_within(player, FRAMES_TO_WATCH)
	stand_in.press_jump()
	var fresh_press_jumps: bool = await _leaves_the_floor_within(player, FRAMES_TO_WATCH)
	await remove_player(player)
	return report(not jumped_while_up and still_up and not jumped_after and fresh_press_jumps,
			"Jumping with the crucifix up: jumped %s, still up %s; after letting go, jumped by itself %s, a fresh press jumps %s"
			% [jumped_while_up, still_up, jumped_after, fresh_press_jumps])


## Falling, Crucifix is pressed a little less than Raise Buffer Time before the player can raise it,
## and held: it goes up, and only once the player stands on the floor.
func _a_press_just_before_landing_raises_it_on_landing() -> bool:
	var frames_to_land: int = await _frames_to_land(Vector2(FLOOR_START.x, FALL_HEIGHT))
	var player: Player = spawn_player(Vector2(FLOOR_START.x, FALL_HEIGHT))
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	await wait_frames(frames_to_land - BUFFER_MARGIN_FRAMES)
	var in_the_air: bool = not player.is_on_floor()
	stand_in.crucifix_held = true
	var up: bool = await wait_until(crucifix.is_raised,
			crucifix.stats.get_raise_buffer_frames() + SETTLE_FRAMES)
	var on_the_floor_then: bool = player.get_state() == Player.State.ON_FLOOR
	await remove_player(player)
	return report(frames_to_land > 0 and in_the_air and up and on_the_floor_then,
			"A press %d frames before landing: pressed in the air %s, went up %s, on the floor then %s"
			% [BUFFER_MARGIN_FRAMES, in_the_air, up, on_the_floor_then])


## Falling, Crucifix is pressed well before Raise Buffer Time and held through the landing: it stays
## down on the floor until Crucifix is let go and pressed again.
func _a_press_long_before_landing_raises_nothing_until_pressed_again() -> bool:
	var frames_to_land: int = await _frames_to_land(Vector2(FLOOR_START.x, FALL_HEIGHT))
	var player: Player = spawn_player(Vector2(FLOOR_START.x, FALL_HEIGHT))
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	var early: int = crucifix.stats.get_raise_buffer_frames() + 2 * BUFFER_MARGIN_FRAMES
	await wait_frames(frames_to_land - early)
	stand_in.crucifix_held = true
	var landed: bool = await wait_until_on_floor(player)
	var up_while_held: bool = await wait_until(crucifix.is_raised, FRAMES_TO_WATCH)
	stand_in.crucifix_held = false
	await physics_frame
	stand_in.crucifix_held = true
	var up_after_fresh_press: bool = await wait_until(crucifix.is_raised, SETTLE_FRAMES)
	await remove_player(player)
	return report(frames_to_land > early and landed and not up_while_held and up_after_fresh_press,
			"A press %d frames before landing, held: up after landing %s, up after a fresh press %s"
			% [early, up_while_held, up_after_fresh_press])


## On the wall, a press of Crucifix, held, leaves it down.
func _a_press_on_a_wall_raises_nothing() -> bool:
	var player: Player = spawn_player(Vector2(_x_near_the_wall(GAP), FALL_HEIGHT))
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = -1.0
	var touched: bool = await wait_until_on_wall(player)
	await wait_frames(SETTLE_FRAMES)
	stand_in.crucifix_held = true
	var up: bool = await wait_until(crucifix.is_raised,
			crucifix.stats.get_raise_buffer_frames() + SETTLE_FRAMES)
	var state: Player.State = player.get_state()
	var speed_multiplier: float = player.get_speed_multiplier()
	await remove_player(player)
	return report(touched and state == Player.State.ON_WALL and not up
			and is_equal_approx(speed_multiplier, 1.0),
			"A press on a wall: state %s, up %s, speed multiplier %.2f%s"
			% [Player.State.find_key(state), up, speed_multiplier,
			"" if touched else " (never reached the wall)"])


## Walking off a ledge with the crucifix up lowers it as the player leaves the floor, and the
## cooldown starts.
func _leaving_the_floor_lowers_it_and_starts_the_cooldown() -> bool:
	var player: Player = await spawn_on_floor(LEDGE_START)
	if player == null:
		return report(false, "Walking off a ledge: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_before: bool = crucifix.is_raised()
	stand_in.run_direction = 1.0
	var left_floor: bool = false
	var frames_up_in_the_air: int = 0
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor():
			left_floor = true
			if crucifix.is_raised():
				frames_up_in_the_air += 1
			else:
				break
	var phase: Crucifix.Phase = crucifix.get_phase()
	await remove_player(player)
	# The crucifix runs after the player, so it can only see the fall one frame after it starts.
	return report(up_before and left_floor and frames_up_in_the_air <= 1
			and phase == Crucifix.Phase.COOLDOWN,
			"Walking off a ledge: up before %s, frames up in the air %d, phase then %s%s"
			% [up_before, frames_up_in_the_air, Crucifix.Phase.find_key(phase),
			"" if left_floor else " (never left the floor)"])


## Holding Crucifix for longer than Max Use Time keeps the crucifix up for exactly Max Use Time,
## then it goes down and cools down.
func _a_use_lasts_at_most_max_use_time() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The longest use: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	_use_short_times(crucifix)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	var frames_up: int = await _count_frames_while(crucifix.is_raised, true)
	var phase: Crucifix.Phase = crucifix.get_phase()
	var expected: int = crucifix.stats.get_max_use_frames()
	await remove_player(player)
	return report(frames_up == expected and phase == Crucifix.Phase.COOLDOWN,
			"The longest use: up %d frames, Max Use Time %d frames, then %s"
			% [frames_up, expected, Crucifix.Phase.find_key(phase)])


## Letting go after a short use starts the whole Cooldown Time, and a press made at its start, and
## held, does not raise the crucifix during it.
func _a_short_use_still_takes_the_whole_cooldown() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The cooldown after a short use: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	_use_short_times(crucifix)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES + SHORT_HOLD_FRAMES)
	stand_in.crucifix_held = false
	await physics_frame
	# The frame that let go has run: the cooldown starts full, and this is its first frame.
	var expected: int = crucifix.stats.get_cooldown_frames()
	var full_time: float = crucifix.stats.cooldown_time
	var cooldown_left: float = crucifix.get_cooldown_left()
	var started: bool = crucifix.get_phase() == Crucifix.Phase.COOLDOWN
	stand_in.crucifix_held = true
	var raised_during: Array[bool] = [false]
	var more_frames: int = await _count_frames_while(func() -> bool:
		raised_during[0] = raised_during[0] or crucifix.is_raised()
		return crucifix.get_phase() == Crucifix.Phase.COOLDOWN, false)
	await remove_player(player)
	var frames_cooling: int = more_frames + 1 if started else 0
	return report(frames_cooling == expected and is_equal_approx(cooldown_left, full_time)
			and not raised_during[0],
			"The cooldown after a short use: %d frames, Cooldown Time %d frames, %.3f s left on its first frame; went up during it %s"
			% [frames_cooling, expected, cooldown_left, raised_during[0]])


## Holding Crucifix through a whole use and the whole cooldown leaves the crucifix down once it is
## ready; letting go and pressing again raises it.
func _held_through_the_cooldown_it_waits_for_a_fresh_press() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Held through the cooldown: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	_use_short_times(crucifix)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	var frames: int = crucifix.stats.get_max_use_frames() + crucifix.stats.get_cooldown_frames()
	await wait_frames(frames + SETTLE_FRAMES)
	var phase: Crucifix.Phase = crucifix.get_phase()
	var up_while_held: bool = crucifix.is_raised()
	stand_in.crucifix_held = false
	await physics_frame
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_after_fresh_press: bool = crucifix.is_raised()
	await remove_player(player)
	return report(phase == Crucifix.Phase.READY and not up_while_held and up_after_fresh_press,
			"Held through the cooldown: phase %s, up while still held %s, up after a fresh press %s"
			% [Crucifix.Phase.find_key(phase), up_while_held, up_after_fresh_press])


## Crucifix pressed a little less than Raise Buffer Time before the cooldown ends, and held, raises
## the crucifix as soon as it is ready.
func _a_press_just_before_the_cooldown_ends_raises_it_then() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "A press just before the cooldown ends: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	_use_short_times(crucifix)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES + SHORT_HOLD_FRAMES)
	stand_in.crucifix_held = false
	await wait_until(func() -> bool: return crucifix.get_phase() == Crucifix.Phase.COOLDOWN)
	await wait_frames(crucifix.stats.get_cooldown_frames() - BUFFER_MARGIN_FRAMES)
	var still_cooling: bool = crucifix.get_phase() == Crucifix.Phase.COOLDOWN
	stand_in.crucifix_held = true
	var up: bool = await wait_until(crucifix.is_raised,
			crucifix.stats.get_raise_buffer_frames() + SETTLE_FRAMES)
	await remove_player(player)
	return report(still_cooling and up,
			"A press %d frames before the cooldown ends: pressed during it %s, up once ready %s"
			% [BUFFER_MARGIN_FRAMES, still_cooling, up])


## The pause stops the use's count; Crucifix let go during the pause lowers the crucifix, and starts
## the cooldown, once the game comes back.
func _the_pause_stops_the_use_and_letting_go_in_it_lowers_it() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The pause: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	paused = true
	var left_at_pause: float = crucifix.get_use_time_left()
	await wait_frames(PAUSE_FRAMES)
	var left_after_pause: float = crucifix.get_use_time_left()
	var up_in_the_pause: bool = crucifix.is_raised()
	stand_in.crucifix_held = false
	paused = false
	await wait_frames(SETTLE_FRAMES)
	var phase: Crucifix.Phase = crucifix.get_phase()
	await remove_player(player)
	return report(is_equal_approx(left_at_pause, left_after_pause) and up_in_the_pause
			and phase == Crucifix.Phase.COOLDOWN,
			"The pause: %.3f s of use left before it and %.3f s after %d frames of it, up in it %s; let go in it, then %s"
			% [left_at_pause, left_after_pause, PAUSE_FRAMES, up_in_the_pause,
			Crucifix.Phase.find_key(phase)])


## Lost while up, the crucifix goes down, says so once, however many times it is lost, and leaves
## the game; the run is back at Max Run Speed.
func _lost_it_goes_down_says_so_once_and_leaves_the_game() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The lost crucifix: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var times_lost: Array[int] = [0]
	var times_lowered: Array[int] = [0]
	crucifix.lost.connect(func() -> void: times_lost[0] += 1)
	crucifix.lowered.connect(func() -> void: times_lowered[0] += 1)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	stand_in.run_direction = 1.0
	await wait_frames(SETTLE_FRAMES)
	var up_before: bool = crucifix.is_raised()
	crucifix.lose()
	crucifix.lose()
	await wait_frames(FRAMES_TO_WATCH)
	var gone: bool = not is_instance_valid(crucifix)
	var speed: float = player.velocity.x
	var top_speed: float = player.stats.max_run_speed
	await remove_player(player)
	return report(up_before and times_lost[0] == 1 and times_lowered[0] == 1 and gone
			and is_equal_approx(speed, top_speed),
			"The lost crucifix: up before %s, lost said %d times, lowered %d, out of the game %s, speed %.1f px/s of %.1f px/s"
			% [up_before, times_lost[0], times_lowered[0], gone, speed, top_speed])


## Lost during the cooldown, the crucifix says so and leaves the game too.
func _lost_during_the_cooldown_it_also_leaves_the_game() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Lost during the cooldown: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	stand_in.crucifix_held = false
	await wait_frames(SETTLE_FRAMES)
	var cooling: bool = crucifix.get_phase() == Crucifix.Phase.COOLDOWN
	var times_lost: Array[int] = [0]
	crucifix.lost.connect(func() -> void: times_lost[0] += 1)
	crucifix.lose()
	await physics_frame
	var gone: bool = not is_instance_valid(crucifix)
	await remove_player(player)
	return report(cooling and times_lost[0] == 1 and gone,
			"Lost during the cooldown: cooling %s, lost said %d times, out of the game %s"
			% [cooling, times_lost[0], gone])


## With the crucifix up, healed comes once per physics frame, and a second's worth of frames adds
## up to Heal Per Second. The calls are counted, because a function connected during a frame also
## hears that frame.
func _one_second_up_heals_heal_per_second() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Healing: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var healed: Array[float] = [0.0]
	var calls: Array[int] = [0]
	crucifix.healed.connect(func(amount: float) -> void:
		healed[0] += amount
		calls[0] += 1)
	var frames: int = Engine.physics_ticks_per_second
	await wait_frames(frames)
	var per_second: float = healed[0] / calls[0] * frames if calls[0] > 0 else 0.0
	var expected: float = crucifix.stats.heal_per_second
	await remove_player(player)
	return report(calls[0] >= frames and absf(per_second - expected) <= HEAL_TOLERANCE,
			"Healing: %.3f SP per second over %d frames, Heal Per Second %.3f SP"
			% [per_second, calls[0], expected])


## With the crucifix up, a stand-in demon inside the radius is pushed until it is out of it, and
## says so with repelled; one outside the radius does not move.
func _it_pushes_a_repellable_inside_out_and_leaves_one_outside() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Repelling: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var near: CharacterBody2D = _make_demon(crucifix.global_position + NEAR_OFFSET)
	var far: CharacterBody2D = _make_demon(crucifix.global_position + FAR_OFFSET)
	var far_start: Vector2 = far.global_position
	var times_repelled: Array[int] = [0]
	var near_repellable: Repellable = near.get_node(^"Repellable") as Repellable
	near_repellable.repelled.connect(func(_origin: Vector2) -> void: times_repelled[0] += 1)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(FRAMES_TO_WATCH)
	var outside_at: float = crucifix.stats.repel_radius + DEMON_RADIUS
	var near_distance: float = crucifix.global_position.distance_to(near.global_position)
	var far_moved: float = far.global_position.distance_to(far_start)
	near.queue_free()
	far.queue_free()
	await remove_player(player)
	return report(near_distance >= outside_at and times_repelled[0] > 0 and is_zero_approx(far_moved),
			"Repelling: the near one ends %.1f px away (out from %.1f px), repelled %d times; the far one moved %.1f px"
			% [near_distance, outside_at, times_repelled[0], far_moved])


## The Repellable scene is on the layer the project names repellable, looks for nothing itself, and
## the crucifix looks on that layer.
func _the_repellable_scene_is_on_the_layer_the_crucifix_looks_on() -> bool:
	var layer: int = _layer_named(REPELLABLE_LAYER_NAME)
	var repellable: Repellable = REPELLABLE_SCENE.instantiate() as Repellable
	var on_it: bool = layer > 0 and repellable.get_collision_layer_value(layer)
	var looks_for_nothing: bool = repellable.collision_mask == 0 and not repellable.monitoring
	repellable.free()
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	var area: Area2D = _crucifix_of(probe).get_node(^"%RepelArea") as Area2D
	var crucifix_looks: bool = layer > 0 and area.get_collision_mask_value(layer)
	probe.free()
	return report(on_it and looks_for_nothing and crucifix_looks,
			"The Repellable scene: on layer %d, %s, %s; looks for nothing %s; the crucifix looks on it %s"
			% [layer, REPELLABLE_LAYER_NAME, on_it, looks_for_nothing, crucifix_looks])


## Changed while the game runs, Repel Radius moves the edge of the area and of the light at once, and
## Speed Multiplier slows the player at once, also with the crucifix up.
func _a_new_radius_or_slowdown_in_stats_takes_effect_at_once() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Tuning Stats: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	crucifix.stats = crucifix.stats.duplicate() as CrucifixStats
	crucifix.stats.repel_radius = TUNED_RADIUS
	var shape: CircleShape2D = (crucifix.get_node(^"%RepelShape") as CollisionShape2D).shape \
			as CircleShape2D
	var light: PointLight2D = crucifix.get_node(^"%Light") as PointLight2D
	var light_edge: float = light.texture.get_width() * light.texture_scale / 2.0
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	stand_in.run_direction = 1.0
	await wait_frames(SETTLE_FRAMES)
	crucifix.stats.speed_multiplier = TUNED_SPEED_MULTIPLIER
	var share: float = player.get_speed_multiplier()
	await wait_frames(FRAMES_TO_WATCH)
	var speed: float = player.velocity.x
	var expected_speed: float = player.stats.max_run_speed * TUNED_SPEED_MULTIPLIER
	await remove_player(player)
	return report(is_equal_approx(shape.radius, TUNED_RADIUS)
			and is_equal_approx(light_edge, TUNED_RADIUS) and is_equal_approx(share, TUNED_SPEED_MULTIPLIER)
			and is_equal_approx(speed, expected_speed),
			"Tuning Stats: area radius %.1f px, light edge %.1f px, for %.1f px; speed share %.2f and speed %.1f px/s, for %.1f px/s"
			% [shape.radius, light_edge, TUNED_RADIUS, share, speed, expected_speed])


## A stand-in demon: a CharacterBody2D that collides with the world only, with a round Repellable,
## made from its scene.
func _make_demon(at: Vector2) -> CharacterBody2D:
	var demon: CharacterBody2D = CharacterBody2D.new()
	demon.collision_layer = 1 << 2
	demon.collision_mask = 1
	demon.global_position = at
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = DEMON_RADIUS
	var repellable: Repellable = REPELLABLE_SCENE.instantiate() as Repellable
	repellable.name = "Repellable"
	repellable.target = demon
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	repellable.add_child(collision)
	demon.add_child(repellable)
	root.add_child(demon)
	return demon


func _crucifix_of(player: Player) -> Crucifix:
	return player.get_node(^"Crucifix") as Crucifix


## Gives the crucifix its own copy of Stats with SHORT_USE_TIME and SHORT_COOLDOWN_TIME, so the case
## neither waits the real times nor touches the .tres or the other cases.
func _use_short_times(crucifix: Crucifix) -> void:
	crucifix.stats = crucifix.stats.duplicate() as CrucifixStats
	crucifix.stats.max_use_time = SHORT_USE_TIME
	crucifix.stats.cooldown_time = SHORT_COOLDOWN_TIME


## Physics frames from a player's spawn at the given spot until its state is on the floor, the
## first frame on which the crucifix can go up; 0 if it never lands.
func _frames_to_land(at: Vector2) -> int:
	var probe: Player = spawn_player(at)
	var frames: int = 0
	for frame: int in MAX_FRAMES:
		await physics_frame
		if probe.get_state() == Player.State.ON_FLOOR:
			frames = frame + 1
			break
	await remove_player(probe)
	return frames


## Waits a physics frame at a time and counts the frames after which condition holds, from the first
## one that holds to the last; gives up after MAX_FRAMES. With wait_for_start, frames before the
## condition first holds are not counted.
func _count_frames_while(condition: Callable, wait_for_start: bool) -> int:
	var count: int = 0
	var started: bool = not wait_for_start
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if condition.call():
			started = true
			count += 1
		elif started:
			break
	return count


## True if the player leaves the floor within frames physics frames.
func _leaves_the_floor_within(player: Player, frames: int) -> bool:
	return await wait_until(func() -> bool: return not player.is_on_floor(), frames)


## The x at which the side of the player's body is gap px from the wall.
func _x_near_the_wall(gap: float) -> float:
	return WALL_FACE + _half_width + gap


## The number of the 2D physics layer the project gives this name; 0 if none has it.
func _layer_named(layer_name: String) -> int:
	for layer: int in range(1, PHYSICS_LAYERS + 1):
		if ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % layer, "") == layer_name:
			return layer
	return 0
