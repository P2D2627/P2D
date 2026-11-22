# Checks Asmodeus as a node, with the man on a floor. She starts hidden. talk() shows her, says
# talk_started with its cue, keeps the man from running and jumping and his crucifix down, and
# opens the game's balloon; a second talk() meanwhile does nothing. Once her last line goes, on the
# next physics frame, the man runs, jumps and can raise the crucifix again, she hides, and she says
# talk_ended with the same cue. appear_at() puts her on the man's floor Appear Distance in front of
# him, nearer down to Min Appear Distance on a small ledge, or behind him when the front has a pit,
# a gap, a wall, brambles, a platform or no room for her, with her feet on rock (never a platform),
# a step up too, and turns the two to face each other; with room on neither side, or the man on a
# platform, find_spot() finds nothing and she stands in front of him at his height.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus.gd
extends "res://tests/support/player_test.gd"

const ASMODEUS_SCENE: PackedScene = preload("res://scenes/characters/demon/asmodeus.tscn")
const BRAMBLES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
## The one_way_platform physics layer (9), as a bit.
const ONE_WAY_LAYER: int = 256
## Her last cue; the first answer at each of its choices runs it to the end.
const CUE: String = "stairs"
## Frames to wait for a line to come, or for the talk to end.
const LINE_FRAMES: int = 60
## Choices answered before giving up, in case a jump loops.
const MAX_CHOICES: int = 8


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	make_platform(-2000.0, 2000.0)
	var results: Array[bool] = []
	results.append(await _a_talk_holds_the_man_and_lets_him_go_after())
	results.append(await _appear_at_puts_her_beside_a_point())
	finish(results)


func _a_talk_holds_the_man_and_lets_him_go_after() -> bool:
	var player: Player = await spawn_on_floor(Vector2(0.0, -100.0))
	var asmodeus: Asmodeus = _add_asmodeus(player)
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var started: Array[String] = []
	var ended: Array[String] = []
	asmodeus.talk_started.connect(func(cue: String) -> void: started.append(cue))
	asmodeus.talk_ended.connect(func(cue: String) -> void: ended.append(cue))
	await wait_frames(2)
	var hidden_first: bool = not asmodeus.visible
	asmodeus.talk(CUE)
	asmodeus.talk(CUE)
	var balloon: DialogueBalloon = await _balloon_of(asmodeus)
	var balloons: int = asmodeus.find_children("*", "CanvasLayer", false, false).size()
	var held: bool = (asmodeus.visible and asmodeus.is_talking() and player.get_speed_multiplier() == 0.0
			and player.is_jump_blocked() and crucifix.is_blocked() and balloon != null and balloons == 1)
	var over: bool = balloon != null and await _talk_to_the_end(balloon, ended)
	var let_go: bool = (player.get_speed_multiplier() == 1.0 and not player.is_jump_blocked()
			and not crucifix.is_blocked() and not asmodeus.visible and not asmodeus.is_talking())
	asmodeus.queue_free()
	await remove_player(player)
	return report(hidden_first and held and over and let_go and started == [CUE] and ended == [CUE],
			("Talk: hidden at first %s; while talking shown, the man held, the crucifix down, one "
			+ "balloon %s; after the last line it ended %s, the man let go and she hid %s; started %s, "
			+ "ended %s") % [hidden_first, held, over, let_go, started, ended])


func _appear_at_puts_her_beside_a_point() -> bool:
	var player: Player = await spawn_on_floor(Vector2(0.0, -100.0))
	var asmodeus: Asmodeus = _add_asmodeus(player)
	await physics_frame
	var feet: Vector2 = player.global_position
	player.face(-1.0)
	asmodeus.appear_at(feet)
	# Her feet on the floor, at y = 0; his stay the safe margin above it.
	var expected: Vector2 = Vector2(feet.x - asmodeus.appear_distance, 0.0)
	var at: Vector2 = asmodeus.global_position
	# She is left of him, so she faces right: as drawn if the art faces right.
	var she_faces_him: bool = _faces_right(asmodeus)
	var front: bool = report(at.is_equal_approx(expected) and player.get_facing() == -1.0
			and she_faces_him, ("Open floor, the man facing left: she stands at %s (expected %s), "
			+ "he still faces left %s, she faces him %s")
			% [at, expected, player.get_facing() == -1.0, she_faces_him])
	asmodeus.queue_free()
	await remove_player(player)
	var turned: bool = await _a_pit_in_front_puts_her_behind_and_turns_him()
	var spots: bool = await _spots_on_other_floors()
	return front and turned and spots


func _a_pit_in_front_puts_her_behind_and_turns_him() -> bool:
	var floor_body: StaticBody2D = make_platform(8600.0, 9100.0)
	var player: Player = await spawn_on_floor(Vector2(9050.0, -100.0))
	var asmodeus: Asmodeus = _add_asmodeus(player)
	await physics_frame
	var feet: Vector2 = player.global_position
	player.face(1.0)
	asmodeus.appear_at(feet)
	var at: Vector2 = asmodeus.global_position
	# Her feet on the floor, at y = 0; his stay the safe margin above it.
	var expected: Vector2 = Vector2(feet.x - asmodeus.appear_distance, 0.0)
	var she_faces_him: bool = _faces_right(asmodeus)
	var passed: bool = report(at.is_equal_approx(expected) and player.get_facing() == -1.0
			and she_faces_him, ("A pit in front of the man facing right: she stands behind him at "
			+ "%s (expected %s), he turns to her %s, she faces him %s")
			% [at, expected, player.get_facing() == -1.0, she_faces_him])
	asmodeus.queue_free()
	await remove_player(player)
	floor_body.queue_free()
	return passed


## find_spot() on floors far from the others, the man's feet at y = 0 facing right.
func _spots_on_other_floors() -> bool:
	var player: Player = await spawn_on_floor(Vector2(0.0, -100.0))
	var asmodeus: Asmodeus = _add_asmodeus(player)
	var d: float = asmodeus.appear_distance
	var bodies: Array[StaticBody2D] = []
	# A wall in front.
	bodies.append(make_platform(18600.0, 19600.0))
	bodies.append(make_wall(19100.0, 19148.0, -300.0))
	# A gap of a tile and a bit between him and the floor in front.
	bodies.append(make_platform(28600.0, 29100.0))
	bodies.append(make_platform(29160.0, 29600.0))
	# A step up of a tile in front.
	bodies.append(make_platform(38600.0, 39150.0))
	bodies.append(make_platform(39150.0, 39600.0, -48.0))
	# A ceiling too low for her in front.
	bodies.append(make_platform(48600.0, 49600.0))
	bodies.append(make_wall(49100.0, 49600.0, -200.0, -100.0))
	# A ledge with pits on both sides.
	bodies.append(make_platform(58980.0, 59120.0))
	# A small ledge, with room only nearer than Appear Distance in front.
	bodies.append(make_platform(68900.0, 69190.0))
	# Brambles in front, two tiles wide, on the floor.
	bodies.append(make_platform(78600.0, 79600.0))
	var brambles: Node2D = BRAMBLES_SCENE.instantiate() as Node2D
	brambles.position = Vector2(79230.0, 0.0)
	root.add_child(brambles)
	# A platform (on the one-way layer) wide enough for both, over a pit.
	bodies.append(_on_platform_layer(make_platform(88600.0, 89600.0)))
	# Rock under the man, a platform at the same height in front of him.
	bodies.append(make_platform(98600.0, 99100.0))
	bodies.append(_on_platform_layer(make_platform(99100.0, 99600.0)))
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState2D = asmodeus.get_world_2d().direct_space_state
	var cases: Array[Array] = [
		["wall in front", Vector2(19050.0, 0.0), Vector2(19050.0 - d, 0.0)],
		["gap in front", Vector2(29050.0, 0.0), Vector2(29050.0 - d, 0.0)],
		["step up in front", Vector2(39050.0, 0.0), Vector2(39050.0 + d, -48.0)],
		["low ceiling in front", Vector2(49050.0, 0.0), Vector2(49050.0 - d, 0.0)],
		["pits on both sides", Vector2(59050.0, 0.0), Vector2.INF],
		["small ledge", Vector2(69050.0, 0.0), Vector2(69170.0, 0.0)],
		["brambles in front", Vector2(79050.0, 0.0), Vector2(79050.0 - d, 0.0)],
		["the man on a platform", Vector2(89050.0, 0.0), Vector2.INF],
		["a platform in front", Vector2(99050.0, 0.0), Vector2(99050.0 - d, 0.0)],
	]
	var passed: bool = true
	for case: Array in cases:
		var spot: Vector2 = asmodeus.find_spot(space, case[1], 1.0)
		var expected: Vector2 = case[2]
		var right: bool = (not spot.is_finite() if not expected.is_finite()
				else spot.is_equal_approx(expected))
		passed = report(right, "find_spot, %s: %s (expected %s)" % [case[0], spot, expected]) and passed
	for body: StaticBody2D in bodies:
		body.queue_free()
	brambles.queue_free()
	asmodeus.queue_free()
	await remove_player(player)
	return passed


## Moves body to the levels' one-way platform layer, where the platforms and collapsing platforms are.
func _on_platform_layer(body: StaticBody2D) -> StaticBody2D:
	body.collision_layer = ONE_WAY_LAYER
	return body


## Whether her drawing shows her facing right.
func _faces_right(asmodeus: Asmodeus) -> bool:
	var sprite: Sprite2D = asmodeus.get_node(^"Sprite") as Sprite2D
	return sprite.flip_h != asmodeus.art_faces_right


func _add_asmodeus(player: Player) -> Asmodeus:
	var asmodeus: Asmodeus = ASMODEUS_SCENE.instantiate() as Asmodeus
	asmodeus.player = player
	root.add_child(asmodeus)
	return asmodeus


## Her balloon once it shows its first line; null if it never does.
func _balloon_of(asmodeus: Asmodeus) -> DialogueBalloon:
	var found: Array[DialogueBalloon] = []
	await wait_until(func() -> bool:
		for child: Node in asmodeus.get_children():
			if child is DialogueBalloon and (child as DialogueBalloon).dialogue_line != null:
				found.append(child)
				return true
		return false, LINE_FRAMES)
	return found[0] if not found.is_empty() else null


## Skips the lines and picks the first answer at each choice, until the talk says it ended (ended
## gets its cue); whether it did.
func _talk_to_the_end(balloon: DialogueBalloon, ended: Array[String]) -> bool:
	for i: int in MAX_CHOICES:
		if not is_instance_valid(balloon) or not ended.is_empty():
			break
		balloon.skip_to_the_next_choice()
		await wait_until(func() -> bool:
			return not is_instance_valid(balloon) or not ended.is_empty() or balloon.is_at_a_choice(),
			LINE_FRAMES)
		if not is_instance_valid(balloon) or not ended.is_empty() or not balloon.is_at_a_choice():
			break
		var line: DialogueLine = balloon.dialogue_line
		balloon.next(line.responses[0].next_id)
		await wait_until(func() -> bool:
			return (not is_instance_valid(balloon) or not ended.is_empty()
					or balloon.dialogue_line != line), LINE_FRAMES)
	return await wait_until(func() -> bool: return not ended.is_empty(), LINE_FRAMES)
