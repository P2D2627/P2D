# Checks the tutorial, the start of Lust phase 1. The man wakes at its Wake Point, and its way out
# leads into the phase's start hall with no cut. Each key drawn on the background shows the key the Input Map has for its action, Interact's R included, and reads it
# again when the game comes back from the pause, where the controls are changed. Velvet, the
# tutorial's demon, talks on her own the first time the man walks in, and only that once: he stands
# still, with no jump and no crucifix, until the balloon goes. Then her key shows, and Interact talks
# again; a state that says they met keeps her from starting over. The demon in the corridor attacks as a demon does but takes no SP: its lunge only throws
# the man back, and the crucifix throws it into the pit at the corridor's end.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_tutorial_room.gd
extends "res://tests/support/player_test.gd"

const ROOM_SCENE: PackedScene = preload("res://scenes/levels/Lust/LustLevel_Phase1_Cave.tscn")
## Where the Tutorial node sits in the phase: the positions below are its own.
const OFFSET: Vector2 = Vector2(-4560.0, 3984.0)
## Just left of Velvet's Talk Area.
const BEFORE_VELVET: Vector2 = OFFSET + Vector2(1000.0, 960.0)
## Inside her Talk Area.
const AT_VELVET: Vector2 = OFFSET + Vector2(1200.0, 960.0)
## Under the crucifix's key, before the corridor, past Velvet and the climb.
const BEFORE_CORRIDOR: Vector2 = OFFSET + Vector2(2976.0, 960.0)
## Top of the floor the corridor's demon stands on.
const FLOOR_Y: float = OFFSET.y + 960.0
## Before the jump wall, past Velvet's Talk Area.
const BEFORE_JUMP_WALL: Vector2 = OFFSET + Vector2(1650.0, 960.0)
## Right edge of the jump wall.
const JUMP_WALL_RIGHT: float = OFFSET.x + 1968.0
## At the foot of the chimney, between the pillar and the block.
const CHIMNEY_FOOT: Vector2 = OFFSET + Vector2(2424.0, 960.0)
## Top of the pillar and of the block the chimney climbs.
const CLIMB_TOP_Y: float = OFFSET.y + 432.0
## Physics frames the man walks at the corridor's demon without the crucifix.
const WALK_FRAMES: int = 300
## Inside the phase's start hall, past the opening in its left wall.
const IN_THE_HALL_X: float = 192.0


func _initialize() -> void:
	# The DialogueManager autoload joins the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(await _the_man_wakes_at_the_wake_point())
	results.append(await _the_way_out_leads_into_the_hall())
	results.append(await _each_key_shows_its_action_s_key())
	results.append(await _a_key_changed_in_the_pause_shows_once_it_ends())
	results.append(await _velvet_talks_once_on_her_own_and_holds_the_man())
	results.append(await _after_the_first_talk_interact_talks_again())
	results.append(await _with_the_talk_in_the_state_she_does_not_start_over())
	results.append(await _a_jump_clears_the_jump_wall())
	results.append(await _the_chimney_climbs_with_jump_on_each_wall())
	results.append(await _the_corridor_demon_throws_the_man_back_unhurt())
	results.append(await _the_crucifix_throws_the_corridor_demon_into_the_pit())
	_progress().reset()
	finish(results)


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


func _new_room(new_game: bool = true) -> Node2D:
	if new_game:
		_progress().reset()
	var room: Node2D = ROOM_SCENE.instantiate() as Node2D
	root.add_child(room)
	await physics_frame
	return room


func _remove_room(room: Node2D) -> void:
	room.queue_free()
	await physics_frame


func _the_man_wakes_at_the_wake_point() -> bool:
	var room: Node2D = await _new_room()
	var player: Player = room.get_node(^"Player") as Player
	var wake: Marker2D = room.get_node(^"Tutorial/WakePoint") as Marker2D
	var distance: float = player.global_position.distance_to(wake.global_position)
	await _remove_room(room)
	return report(distance < 2.0, "Waking: %.1f px from the Wake Point" % distance)


## Walking on from the end of the tutorial, past the pit, with nothing else pressed.
func _the_way_out_leads_into_the_hall() -> bool:
	var room: Node2D = await _new_room()
	var player: Player = room.get_node(^"Player") as Player
	var end: Marker2D = room.get_node(^"Tutorial/TutorialEnd") as Marker2D
	var stand_in: StandInInput = put_a_stand_in(player)
	player.global_position = end.global_position
	stand_in.run_direction = 1.0
	var reached: bool = await wait_until(
			func() -> bool: return player.global_position.x > IN_THE_HALL_X)
	var x: float = player.global_position.x
	await _remove_room(room)
	return report(reached, "The way out: reaches the hall %s, at x %.0f" % [reached, x])


func _each_key_shows_its_action_s_key() -> bool:
	var room: Node2D = await _new_room()
	var texts: Array[String] = []
	for path: NodePath in [^"Tutorial/Move/MoveLeftKey", ^"Tutorial/Move/MoveRightKey",
			^"Tutorial/Jump/JumpKey", ^"Tutorial/WallJump/WallJumpKey",
			^"Tutorial/Crucifix/CrucifixKey", ^"Tutorial/TutorialDemon/TalkKey"]:
		var prompt: KeyPrompt = room.get_node(path) as KeyPrompt
		texts.append(prompt.get_text())
	var expected: Array[String] = []
	for action: StringName in [&"move_left", &"move_right", &"jump", &"jump", &"crucifix",
			&"interact"]:
		expected.append(KeyPrompt.key_text(action))
	await _remove_room(room)
	return report(texts == expected and texts[2] == "Space" and texts[5] == "R"
			and not texts.has(KeyPrompt.NO_KEY_TEXT),
			"Keys on the background: %s, from the Input Map %s" % [texts, expected])


func _a_key_changed_in_the_pause_shows_once_it_ends() -> bool:
	var room: Node2D = await _new_room()
	var prompt: KeyPrompt = room.get_node(^"Tutorial/Jump/JumpKey") as KeyPrompt
	var events: Array[InputEvent] = InputMap.action_get_events(&"jump")
	paused = true
	await process_frame
	InputMap.action_erase_events(&"jump")
	InputMap.action_add_event(&"jump", InputProfiles.event_from_binding(InputProfiles.key(KEY_J)))
	var during_pause: String = prompt.get_text()
	paused = false
	await process_frame
	var after_pause: String = prompt.get_text()
	InputMap.action_erase_events(&"jump")
	for event: InputEvent in events:
		InputMap.action_add_event(&"jump", event)
	await _remove_room(room)
	return report(during_pause == "Space" and after_pause == "J",
			"Jump moved to J in the pause: %s in it, %s after" % [during_pause, after_pause])


func _velvet_talks_once_on_her_own_and_holds_the_man() -> bool:
	var room: Node2D = await _new_room()
	var velvet: TutorialDemon = room.get_node(^"Tutorial/TutorialDemon") as TutorialDemon
	var player: Player = room.get_node(^"Player") as Player
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var arrivals: Array[int] = [0]
	velvet.player_arrived.connect(func() -> void: arrivals[0] += 1)
	var waits: bool = velvet.get_state() == TutorialDemon.State.WAITING
	player.global_position = AT_VELVET
	var talks: bool = await wait_until(
			func() -> bool: return velvet.get_state() == TutorialDemon.State.TALKING)
	var held: bool = player.is_jump_blocked() and crucifix.is_blocked() and _balloon(velvet) != null
	var key_hidden: bool = not (velvet.get_node(^"TalkKey") as Node2D).visible
	_balloon(velvet).queue_free()
	var idle: bool = await wait_until(
			func() -> bool: return velvet.get_state() == TutorialDemon.State.IDLE)
	var free: bool = not player.is_jump_blocked() and not crucifix.is_blocked()
	player.global_position = BEFORE_VELVET
	await wait_frames(5)
	player.global_position = AT_VELVET
	await wait_frames(5)
	var once: bool = arrivals[0] == 1 and velvet.get_state() == TutorialDemon.State.IDLE
	await _remove_room(room)
	return report(waits and talks and held and key_hidden and idle and free and once,
			("Velvet: waits %s, talks on her own %s, holds the man %s, key hidden %s; after the "
			+ "balloon, idle %s and the man free %s; walking in again, %d arrival(s) and no talk %s")
			% [waits, talks, held, key_hidden, idle, free, arrivals[0], once])


func _after_the_first_talk_interact_talks_again() -> bool:
	var room: Node2D = await _new_room()
	var velvet: TutorialDemon = room.get_node(^"Tutorial/TutorialDemon") as TutorialDemon
	var player: Player = room.get_node(^"Player") as Player
	player.global_position = AT_VELVET
	await wait_until(func() -> bool: return velvet.get_state() == TutorialDemon.State.TALKING)
	_balloon(velvet).queue_free()
	await wait_until(func() -> bool: return velvet.get_state() == TutorialDemon.State.IDLE)
	var key_shows: bool = (velvet.get_node(^"TalkKey") as Node2D).visible
	Input.action_press(&"interact")
	var talks_again: bool = await wait_until(
			func() -> bool: return velvet.get_state() == TutorialDemon.State.TALKING, 5)
	Input.action_release(&"interact")
	var balloon: DialogueManagerExampleBalloon = _balloon(velvet)
	var again_cue: String = velvet.again_cue
	var from_again_cue: bool = balloon != null and balloon.start_from_cue == again_cue
	await _remove_room(room)
	return report(key_shows and talks_again and from_again_cue,
			"Talking again: key shows %s, Interact talks %s, from %s %s"
			% [key_shows, talks_again, again_cue, from_again_cue])


func _a_jump_clears_the_jump_wall() -> bool:
	var room: Node2D = await _new_room()
	var player: Player = room.get_node(^"Player") as Player
	var stand_in: StandInInput = put_a_stand_in(player)
	player.global_position = BEFORE_JUMP_WALL
	await wait_until(func() -> bool: return player.is_on_floor())
	stand_in.run_direction = 1.0
	await wait_frames(60)
	var stopped_walking: bool = player.global_position.x < JUMP_WALL_RIGHT
	stand_in.hold_jump = true
	stand_in.press_jump()
	var cleared: bool = await wait_until(
			func() -> bool: return player.global_position.x > JUMP_WALL_RIGHT + 48.0)
	await _remove_room(room)
	return report(stopped_walking and cleared,
			"Jump wall: walking stops at it %s; a jump clears it %s" % [stopped_walking, cleared])


## Pressing Jump each time he touches a wall, as a person tapping on time, and on the floor at the
## start, the man climbs out of the top of the chimney: his feet get above it. Running on, he then
## carries over the block and down to the floor past it, the way on.
func _the_chimney_climbs_with_jump_on_each_wall() -> bool:
	var room: Node2D = await _new_room()
	var player: Player = room.get_node(^"Player") as Player
	var stand_in: StandInInput = put_a_stand_in(player)
	player.global_position = CHIMNEY_FOOT
	await wait_until(func() -> bool: return player.is_on_floor())
	stand_in.run_direction = 1.0
	var highest_feet: float = player.global_position.y
	for _frame: int in MAX_FRAMES:
		if player.is_on_wall() or player.is_on_floor():
			stand_in.press_jump()
		stand_in.hold_jump = player.velocity.y < 0.0 or player.is_on_wall()
		await physics_frame
		highest_feet = minf(highest_feet, player.global_position.y)
		if highest_feet < CLIMB_TOP_Y:
			break
	var climbed: bool = highest_feet < CLIMB_TOP_Y
	await _remove_room(room)
	return report(climbed, "Chimney: feet as high as y %.0f, above the top at y %.0f %s"
			% [highest_feet, CLIMB_TOP_Y, climbed])


## The room comes back as a new copy with the state as it is, as a save brings it.
func _with_the_talk_in_the_state_she_does_not_start_over() -> bool:
	var room: Node2D = await _new_room()
	var velvet: TutorialDemon = room.get_node(^"Tutorial/TutorialDemon") as TutorialDemon
	var player: Player = room.get_node(^"Player") as Player
	player.global_position = AT_VELVET
	await wait_until(func() -> bool: return velvet.get_state() == TutorialDemon.State.TALKING)
	_balloon(velvet).queue_free()
	await wait_until(func() -> bool: return velvet.get_state() == TutorialDemon.State.IDLE)
	await _remove_room(room)
	room = await _new_room(false)
	velvet = room.get_node(^"Tutorial/TutorialDemon") as TutorialDemon
	player = room.get_node(^"Player") as Player
	player.global_position = AT_VELVET
	await wait_frames(5)
	var stays_idle: bool = velvet.get_state() == TutorialDemon.State.IDLE
	await _remove_room(room)
	return report(stays_idle, "Having met her: she does not start over %s" % stays_idle)


## Walking at it, the man sees it notice him, warn and lunge, and the lunge throws him back without
## taking SP. He never gets past it.
func _the_corridor_demon_throws_the_man_back_unhurt() -> bool:
	var room: Node2D = await _new_room()
	var player: Player = room.get_node(^"Player") as Player
	var demon: Demon = room.get_node(^"Tutorial/BlockerDemon") as Demon
	var stand_in: StandInInput = put_a_stand_in(player)
	player.global_position = BEFORE_CORRIDOR
	var start_sp: float = player.soul_points.get_sp()
	var states: Array[Demon.State] = []
	demon.state_changed.connect(func(_previous: Demon.State, current: Demon.State) -> void:
		states.append(current))
	stand_in.run_direction = 1.0
	var thrown_back: bool = false
	var got_past: bool = false
	for _frame: int in WALK_FRAMES:
		await physics_frame
		thrown_back = thrown_back or player.is_knocked_back()
		got_past = got_past or player.global_position.x > demon.global_position.x
	var end_sp: float = player.soul_points.get_sp()
	var warned: bool = (states.has(Demon.State.ALERT) and states.has(Demon.State.WARNING)
			and states.has(Demon.State.LUNGE))
	var no_grab: bool = not states.has(Demon.State.GRAB)
	await _remove_room(room)
	return report(warned and thrown_back and not got_past and no_grab and end_sp >= start_sp,
			("Corridor demon: alert, warning and lunge %s; throws the man back %s; he gets past "
			+ "%s; grabs %s; SP %.1f to %.1f")
			% [warned, thrown_back, got_past, not no_grab, start_sp, end_sp])


func _the_crucifix_throws_the_corridor_demon_into_the_pit() -> bool:
	var room: Node2D = await _new_room()
	var player: Player = room.get_node(^"Player") as Player
	var demon: Demon = room.get_node(^"Tutorial/BlockerDemon") as Demon
	var stand_in: StandInInput = put_a_stand_in(player)
	player.global_position = BEFORE_CORRIDOR
	await wait_until(func() -> bool: return player.is_on_floor())
	var start_sp: float = player.soul_points.get_sp()
	stand_in.crucifix_held = true
	stand_in.run_direction = 1.0
	var in_the_pit: bool = await wait_until(
			func() -> bool: return demon.global_position.y > FLOOR_Y + 1.0)
	var end_sp: float = player.soul_points.get_sp()
	await _remove_room(room)
	return report(in_the_pit and end_sp >= start_sp,
			"Crucifix held, walking at the corridor demon: in the pit %s; SP %.1f to %.1f"
			% [in_the_pit, start_sp, end_sp])


func _balloon(velvet: TutorialDemon) -> DialogueManagerExampleBalloon:
	for child: Node in velvet.get_children():
		if child is DialogueManagerExampleBalloon and not child.is_queued_for_deletion():
			return child as DialogueManagerExampleBalloon
	return null
