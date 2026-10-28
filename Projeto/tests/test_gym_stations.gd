# Test of where the man starts in the gym (ADR 0036). A gym made here, a Level with three station
# starts, GymStations and a man, over a floor: the first copy puts him at the first start; the
# station of an x is the last start at or left of it; a man who dies in a station starts the next
# copy at its start and lands there; a copy after that one, with no death, starts at the first
# station again; and so does one after a death whose gym was left before it asked to start over.
# The number keys 1 to 9 give their stations; a press puts the man at that start; a key past the
# last station, a key the controls give to an action, and any key once he is dead do nothing.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym_stations.gd
extends "res://tests/support/player_test.gd"

## Each station's start, as the gym lays them: one screen apart, above the floor.
const STARTS: Array[Vector2] = [Vector2(240, 900), Vector2(2160, 900), Vector2(4080, 900)]
const FLOOR_TOP: float = 1000.0
const FLOOR_LEFT: float = -200.0
const FLOOR_RIGHT: float = 6000.0
## Into the third station, past its start.
const DEATH_X: float = 4800.0
## A Restart Delay long enough for the gym to be left before it asks to start over, in s.
const SLOW_RESTART: float = 1.5
## An action made here for a number key, as a Custom profile could.
const KEY_ACTION: StringName = &"test_gym_number_key"


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT, FLOOR_TOP)
	# Before the first frame, nodes added to the tree are not made ready yet.
	await process_frame
	var results: Array[bool] = []
	results.append(await _the_first_copy_starts_at_the_first_station())
	results.append(await _the_station_of_an_x_is_the_last_start_before_it())
	results.append(await _a_man_who_dies_starts_again_at_his_station())
	results.append(await _a_copy_with_no_death_starts_at_the_first_again())
	results.append(await _a_gym_left_before_its_restart_starts_at_the_first())
	results.append(_the_number_keys_give_their_stations())
	results.append(await _a_number_key_puts_the_man_at_its_start())
	results.append(await _a_number_key_of_an_action_does_nothing())
	results.append(await _a_number_key_does_nothing_once_he_is_dead())
	finish(results)


func _the_first_copy_starts_at_the_first_station() -> bool:
	var gym: Node2D = _make_gym()
	var player: Player = _player_of(gym)
	var at_first: bool = player.global_position.is_equal_approx(STARTS[0])
	gym.free()
	return report(at_first, "First copy: the man at the first start %s" % at_first)


func _the_station_of_an_x_is_the_last_start_before_it() -> bool:
	var gym: Node2D = _make_gym()
	var stations: GymStations = _stations_of(gym)
	var got: Array[int] = [stations.station_at(0.0), stations.station_at(STARTS[1].x),
			stations.station_at(STARTS[1].x + 100.0), stations.station_at(FLOOR_RIGHT)]
	var expected: Array[int] = [0, 1, 1, 2]
	gym.free()
	return report(got == expected,
			"Station of x: before the first, on, past and after the last start give %s (want %s)"
			% [got, expected])


func _a_man_who_dies_starts_again_at_his_station() -> bool:
	var gym: Node2D = _make_gym()
	var player: Player = _player_of(gym)
	player.global_position = Vector2(DEATH_X, STARTS[2].y)
	player.died.emit()
	gym.free()
	gym = _make_gym()
	player = _player_of(gym)
	var at_start: bool = player.global_position.is_equal_approx(STARTS[2])
	var landed: bool = await wait_until_on_floor(player)
	gym.free()
	return report(at_start and landed,
			"Died in the third station: next copy at its start %s, lands there %s"
			% [at_start, landed])


func _a_copy_with_no_death_starts_at_the_first_again() -> bool:
	var gym: Node2D = _make_gym()
	var player: Player = _player_of(gym)
	player.global_position = Vector2(DEATH_X, STARTS[2].y)
	player.died.emit()
	gym.free()
	_make_gym().free()
	gym = _make_gym()
	var at_first: bool = _player_of(gym).global_position.is_equal_approx(STARTS[0])
	gym.free()
	return report(at_first, "After a restart, a copy with no death: the man at the first start %s"
			% at_first)


## The man dies, and the gym is taken out, as for the menu, before its Restart Delay is over: the
## next copy starts at the first station, not at his.
func _a_gym_left_before_its_restart_starts_at_the_first() -> bool:
	var gym: Level = _make_gym(SLOW_RESTART)
	var player: Player = _player_of(gym)
	player.global_position = Vector2(DEATH_X, STARTS[2].y)
	player.died.emit()
	gym.free()
	gym = _make_gym()
	var at_first: bool = _player_of(gym).global_position.is_equal_approx(STARTS[0])
	gym.free()
	return report(at_first, "Died and left before the restart: the next copy at the first start %s"
			% at_first)


func _the_number_keys_give_their_stations() -> bool:
	var got: Array[int] = [GymStations.station_of_key(KEY_1), GymStations.station_of_key(KEY_9),
			GymStations.station_of_key(KEY_0), GymStations.station_of_key(KEY_A)]
	var expected: Array[int] = [0, 8, 9, -1]
	return report(got == expected, "Number keys: 1, 9, 0 and A give %s (want %s)" % [got, expected])


## A press of 3 puts the man at the third start, at rest; a press of 4, with three stations, leaves
## him where he is.
func _a_number_key_puts_the_man_at_its_start() -> bool:
	var gym: Node2D = _make_gym()
	var player: Player = _player_of(gym)
	await wait_until_on_floor(player)
	player.velocity = Vector2(500.0, 0.0)
	_press_key(KEY_3)
	var at_third: bool = player.global_position.is_equal_approx(STARTS[2]) \
			and player.velocity.is_zero_approx()
	_press_key(KEY_4)
	var stayed: bool = player.global_position.is_equal_approx(STARTS[2])
	gym.free()
	return report(at_third and stayed,
			"Number keys: 3 to the third start, at rest %s; 4 past the last does nothing %s"
			% [at_third, stayed])


## With 2 given to an action, as Jump can be in a Custom profile, a press of 2 leaves the man at the
## first start; with the action gone, it takes him to the second.
func _a_number_key_of_an_action_does_nothing() -> bool:
	var gym: Level = _make_gym()
	var player: Player = _player_of(gym)
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_2
	InputMap.add_action(KEY_ACTION)
	InputMap.action_add_event(KEY_ACTION, key)
	_press_key(KEY_2)
	var stayed: bool = player.global_position.is_equal_approx(STARTS[0])
	InputMap.erase_action(KEY_ACTION)
	_press_key(KEY_2)
	var moved: bool = player.global_position.is_equal_approx(STARTS[1])
	gym.free()
	return report(stayed and moved,
			"Number key of an action: 2 ignored while an action has it %s, works without %s"
			% [stayed, moved])


## Once the man is dead, while the gym waits to start over, a press of 2 leaves his body where it is.
func _a_number_key_does_nothing_once_he_is_dead() -> bool:
	var gym: Level = _make_gym(SLOW_RESTART)
	var player: Player = _player_of(gym)
	player.global_position = Vector2(DEATH_X, STARTS[2].y)
	player.died.emit()
	_press_key(KEY_2)
	var stayed: bool = player.global_position.is_equal_approx(Vector2(DEATH_X, STARTS[2].y))
	gym.free()
	return report(stayed, "Number key once dead: the body left where it is %s" % stayed)


func _press_key(keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	root.push_input(event)


## A Level, as gym.tscn's root, with the starts, then GymStations, then the man, as gym.tscn orders
## them, so GymStations is ready before the man is. At a Restart Delay of 0 a death asks to start
## over at once.
func _make_gym(restart_delay: float = 0.0) -> Level:
	var gym: Level = Level.new()
	gym.restart_delay = restart_delay
	var stations: GymStations = GymStations.new()
	stations.name = "GymStations"
	for at: Vector2 in STARTS:
		var start: Marker2D = Marker2D.new()
		start.position = at
		gym.add_child(start)
		stations.starts.append(start)
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player"
	stations.player = player
	stations.level = gym
	gym.player = player
	gym.add_child(stations)
	gym.add_child(player)
	root.add_child(gym)
	return gym


func _stations_of(gym: Node2D) -> GymStations:
	return gym.get_node(^"GymStations") as GymStations


func _player_of(gym: Node2D) -> Player:
	return gym.get_node(^"Player") as Player
