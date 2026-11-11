# Shared by the route tests: plays a level from start to finish with the real man in the real scene, without the
# dogs. A stand-in input repeats, move by move, the way a paper check found (a .json made by the tools outside the
# repository, which only know the movement's numbers). Before each jump he is put on that floor or wall, so a hop
# that fails is reported on its own and the rest still run. At an unlocker it waits for the crucifix to cool down
# from the last one, raises it, sees the gate open and goes through, and it ends walking into the way out. A "walkback" move goes off an edge, falls straight
# and, from a given frame, pushes back the other way. It says how many moves worked as the check said,
# and fails if the man dies, an unlocker or gate does not work, or a move does not get where it should. A test
# extends this file, with
# extends "res://tests/support/route_test.gd"
extends "res://tests/support/player_test.gd"

const TILE: float = 48.0
## Frames to wait for a move to get where it should.
const MOVE_FRAMES: int = 240
## Frames to let him settle on a floor he was put on.
const SETTLE_FRAMES: int = 3
## Frames to wait for an unlocker, a gate or the way out.
const WAIT_FRAMES: int = 240
## How far above a floor the feet may be and still stand on it, in px.
const ON_TOP: float = 2.0
## How far from the height the check had him on a wall he may touch it and still be there, in px: half a tile.
const ON_THE_WALL: float = 24.0

var _level: Node
var _player: Player
var _stand_in: StandInInput
var _failed_moves: Array[String] = []
var _moves_played: int = 0
var _reached_exit: bool = false


## This file only holds what the route tests share, so on its own it says so and stops.
func _initialize() -> void:
	printerr("route_test.gd only holds shared setup: run one of the tests/test_*_route.gd files.")
	quit(1)


## What a test takes out of the level before it joins the tree. The way is about the jumps; the dogs would only
## make the replay depend on them.
func prepare_level(level: Node) -> void:
	level.get_node("Dogs").free()
	var view: Node = level.get_node("DemonDebugView")
	view.set("demons", [] as Array[Demon])


## Plays the route at route_path in the scene at scene_path, and finishes the test with what it found.
func replay(scene_path: String, route_path: String) -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var route: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(route_path))
	_level = (load(scene_path) as PackedScene).instantiate()
	prepare_level(_level)
	root.add_child(_level)
	var exit: PhaseExit = _level.get_node("PhaseExit") as PhaseExit
	exit.reached.connect(func(_path: String) -> void: _reached_exit = true)
	_player = _level.get_node("Player") as Player
	_stand_in = put_a_stand_in(_player)
	await wait_frames(SETTLE_FRAMES)

	var results: Array[bool] = []
	var leg_number: int = 0
	for leg: Dictionary in route["legs"]:
		leg_number += 1
		var leg_name: String = String(leg.get("name", "Leg %d" % leg_number))
		var failed_before: int = _failed_moves.size()
		for step: Dictionary in leg["steps"]:
			await _play(step)
			if _player.is_dead():
				for line: String in _failed_moves:
					print("  did not get there: %s" % line)
				results.append(report(false, "%s: he died at %s" % [leg_name, _player.global_position]))
				finish(results)
				return
		var moves: int = (leg["steps"] as Array).size()
		results.append(report(_failed_moves.size() == failed_before and not _player.is_dead(),
				"%s: %d moves, %d did not get there, dead %s" % [leg_name, moves,
				_failed_moves.size() - failed_before, _player.is_dead()]))
		match leg["then"]:
			"unlock":
				results.append(await _use_unlocker(leg))
			"gate":
				results.append(await _gate_is_open(String(leg["gate"])))
			"finish":
				results.append(await _walk_out(leg))
	for line: String in _failed_moves:
		print("  did not get there: %s" % line)
	print("%d moves played" % _moves_played)
	finish(results)


func _play(step: Dictionary) -> void:
	_moves_played += 1
	var move: Dictionary = step["move"]
	var target: Dictionary = step["target"]
	var kind: String = move["kind"]
	var direction: float = float(move["dir"])
	_stand_in.hold_jump = bool(move.get("hold", true))
	match kind:
		"jump":
			# Put on the floor with the run he would have, then pressed.
			_stand_in.crucifix_held = false
			var vx: float = float(move["vx"])
			var start: Vector2 = Vector2(float(move["x"]), float(move["y"]) - 0.1)
			_stand_in.run_direction = 0.0
			_player.global_position = start
			_player.velocity = Vector2.ZERO
			await wait_frames(SETTLE_FRAMES)
			_player.velocity.x = vx
			_stand_in.run_direction = direction
			_stand_in.press_jump()
		"walk":
			_stand_in.run_direction = direction
			_player.global_position = Vector2(float(move["x"]), float(move["y"]))
			_player.velocity = Vector2(float(move["vx"]), 0.0)
		"wall":
			# Put back on the wall at the height the check had him, as a player keeps hopping to make up for a
			# low hop, pushing into it for a frame so he touches it. Then off it: the run is what the check held
			# after the jump.
			var side: float = float(move["side"])
			_player.global_position = Vector2(float(move["x"]), float(move["y"]))
			# Put there from a floor, Godot would still count him on it: with Floor Block On Wall, a body that was on
			# the floor and meets a wall stays on the floor, so the push would end on a floor and the jump would be
			# one from the floor. A player comes to a wall through the air: one still move there first, with
			# nothing under him, takes the floor away.
			_player.velocity = Vector2.ZERO
			_player.move_and_slide()
			_player.velocity = Vector2(side * _player.stats.max_run_speed, 0.0)
			_stand_in.run_direction = side
			await physics_frame
			_stand_in.run_direction = direction
			_stand_in.press_jump()
		"letgo":
			_stand_in.run_direction = 0.0
		"walkback":
			# Off the edge with the run, then let go and fall straight, as down a shaft with spikes on its walls;
			# at the switch's frame, push the other way, out from under the shaft.
			_stand_in.run_direction = 0.0
			_player.global_position = Vector2(float(move["x"]), float(move["y"]))
			_player.velocity = Vector2(float(move["vx"]), 0.0)
	var stop: Variant = move.get("stop")
	var switch: Array = move.get("switch", [])
	var moved: bool = false
	for frame: int in MOVE_FRAMES:
		if not switch.is_empty() and frame == int(switch[0]):
			_stand_in.run_direction = float(switch[1])
			stop = float(switch[2])
		await physics_frame
		if _player.is_dead():
			break
		if stop != null and _stand_in.run_direction != 0.0:
			if (_player.global_position.x - float(stop)) * _stand_in.run_direction >= 0.0:
				_stand_in.run_direction = 0.0
		if _got_there(target):
			moved = true
			break
	if not moved:
		_failed_moves.append("%s from (%.0f, %.0f) to %s; he is at %s" % [kind, float(move["x"]), float(move["y"]), target,
				_player.global_position])
		_put_at_target(target)
		await wait_frames(SETTLE_FRAMES)


func _got_there(target: Dictionary) -> bool:
	if target["reach"] == "floor":
		if not _player.is_on_floor():
			return false
		var row: float = _player.global_position.y / TILE
		if absf(row - float(target["row"])) * TILE > ON_TOP:
			return false
		var half: float = 24.0
		var first: float = float(target["first"]) * TILE - half
		var last: float = (float(target["last"]) + 1.0) * TILE + half
		return _player.global_position.x >= first and _player.global_position.x <= last
	if not _player.is_on_wall():
		return false
	# On that wall, and near the height the check had him there: not further down it, on the floor at its foot.
	return (signf(_player.get_wall_normal().x) == -float(target["side"])
			and absf(_player.global_position.y - float(target["y"])) <= ON_THE_WALL)


## After a move that failed, puts him where it should have got to, so the rest can still be played.
func _put_at_target(target: Dictionary) -> void:
	_player.velocity = Vector2.ZERO
	_stand_in.run_direction = 0.0
	if target["reach"] == "floor":
		_player.global_position = Vector2((float(target["first"]) + float(target["last"]) + 1.0) / 2.0 * TILE,
				float(target["row"]) * TILE - 0.1)
	else:
		_player.global_position = Vector2(float(target["x"]), float(target["y"]))


func _use_unlocker(leg: Dictionary) -> bool:
	var unlocker: GateUnlocker = _level.get_node("GateUnlockers/%s" % leg["unlocker"]) as GateUnlocker
	_stand_in.run_direction = 0.0
	# Walks to the spot of the floor within the crucifix's reach, waits, as a player does, for the crucifix to
	# cool down from the last unlocker, and raises it there.
	_player.global_position = Vector2(float(leg["stand_x"]), float(leg["stand_row"]) * TILE - 0.1)
	_player.velocity = Vector2.ZERO
	await wait_frames(SETTLE_FRAMES)
	var crucifix: Crucifix = _player.get_node("Crucifix") as Crucifix
	await wait_until(func() -> bool: return crucifix.get_phase() == Crucifix.Phase.READY,
			crucifix.stats.get_cooldown_frames() + SETTLE_FRAMES)
	_stand_in.crucifix_held = true
	var used: bool = await wait_until(unlocker.is_activated, WAIT_FRAMES)
	_stand_in.crucifix_held = false
	return report(used, "%s: used with the crucifix %s" % [leg["unlocker"], used])


func _gate_is_open(gate_name: String) -> bool:
	var gate: Gate = _level.get_node("Gates/%s" % gate_name) as Gate
	var opened: bool = await wait_until(func() -> bool: return gate.is_unlocked() and not gate.get_tree().paused, WAIT_FRAMES)
	await wait_frames(roundi(gate.slide_time * Engine.physics_ticks_per_second) + SETTLE_FRAMES)
	return report(opened, "%s: open %s" % [gate_name, opened])


func _walk_out(leg: Dictionary) -> bool:
	_player.global_position = Vector2(float(leg["finish_x"]), float(leg["finish_row"]) * TILE - 0.1)
	_player.velocity = Vector2.ZERO
	var out: bool = await wait_until(func() -> bool: return _reached_exit, WAIT_FRAMES)
	return report(out, "Way out: reached %s" % out)
