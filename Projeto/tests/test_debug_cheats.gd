# Checks the debug overlay's two cheats (#273). God Mode, on F1: a demon's hit still throws the man
# and leaves him invulnerable for a moment, but takes no SP; a grab that runs out of time lets him go
# instead of killing him, and turned off before the time runs out the grab kills him again; spikes
# neither kill him nor hold him, and brambles that catch him take no SP; F4 still takes SP, to try
# the regeneration. Noclip, on F2: he flies with the move keys, which his own input reads, up and
# down too, with no gravity and through walls; while he flies, bites and spikes do nothing to him, a
# grab under way lets him go, and turned off he falls from where he is; turned on dead, the body
# stays put. F1 and F2 work with the text hidden, while paused and with a line on screen, toggle
# once however long they are held, show a label while either is on and the overlay has a man, and
# stay on in the next copy of the level, as after a death or a jump to a phase. Outside debug
# builds the overlay frees itself before it reads a key, so neither cheat, nor F4, does anything,
# whatever was on before: an overlay that answers as a release build checks it here, since a debug
# run can't make OS.is_debug_build() false. F1 and F2 are reserved in the controls' profiles.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_debug_cheats.gd
extends "res://tests/support/player_test.gd"

const OVERLAY_SCENE: PackedScene = preload("res://scenes/others/debug/debug_overlay.tscn")
const TEST_ROOM_SCENE: PackedScene = preload("res://scenes/levels/test_room/test_room.tscn")
const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const HITBOX_SCENE: PackedScene = preload("res://scenes/characters/components/hitbox.tscn")
const BALLOON_PATH: String = "res://scenes/screens/dialogue_balloon.tscn"

const FLOOR_LEFT: float = -4000.0
const FLOOR_RIGHT: float = 4000.0
## Where each case puts the man, just above the floor, whose top is at y = 0.
const START: Vector2 = Vector2(0.0, -2.0)
## Where the test room goes, far below the floor of the other cases, so the two never touch.
const ROOM_OFFSET: Vector2 = Vector2(0.0, 20000.0)
## SP a case takes before a bite, so the bite grabs instead of hurting: below Low Threshold.
const DAMAGE_TO_LOW: float = 80.0
const BITE_DAMAGE: float = 10.0
const BITE_DISTANCE: float = 150.0
const BITE_HEIGHT: float = 40.0
const BITE_SIZE: Vector2 = Vector2(96.0, 96.0)
## How far left of the man a bite goes, in px.
const BITE_OFFSET: float = 30.0
## Frames for a bite to land.
const HIT_FRAMES: int = 10
## Frames for what follows a change to show: a frame or two, and a spare.
const SETTLE_FRAMES: int = 3
## The grab's Time To Die in the cases that wait for it, so they do not wait 3 s.
const SHORT_TIME_TO_DIE: float = 0.5
const TILE: float = 48.0
const SPIKES_WIDTH_TILES: int = 3
## Brambles wide enough that the man, put down in their middle, stays in them.
const BRAMBLES_WIDTH_TILES: int = 8
## How far right of the man the spikes start, in px.
const SPIKES_AHEAD: float = 300.0
## Frames to run or fly past the spikes, and more.
const RUN_FRAMES: int = 180
## Frames the man stays in the brambles: at their SP Per Second, long enough to die twice.
const CAUGHT_FRAMES: int = 120
## Frames of each flight in the noclip cases.
const FLIGHT_FRAMES: int = 30
## How far a flight may be off the expected distance, and how far a man at rest may drift, in px.
const FLIGHT_TOLERANCE: float = 2.0
## The wall the noclip case flies through: how far right of the man it starts, how thick it is and
## how far it goes above and below him, in px.
const WALL_GAP: float = 100.0
const WALL_THICKNESS: float = 100.0
const WALL_HALF_HEIGHT: float = 300.0
## Frames the man falls once noclip is off.
const FALL_FRAMES: int = 20
## Repeats the keyboard sends while F1 is held down.
const KEY_REPEATS: int = 3
## A Noclip Speed for the overlay unlike the man's own, to see that it reaches him, in px/s.
const OVERLAY_NOCLIP_SPEED: float = 777.0


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	await physics_frame
	var results: Array[bool] = []
	results.append(_the_cheats_are_on_f1_and_f2_and_reserved())
	results.append(await _f1_and_f2_toggle_once_with_the_text_hidden_and_paused())
	results.append(await _in_god_mode_f4_still_takes_sp())
	results.append(await _in_god_mode_a_hit_throws_him_and_takes_no_sp())
	results.append(await _in_god_mode_a_grab_that_runs_out_lets_him_go())
	results.append(await _in_god_mode_spikes_neither_kill_nor_hold_him())
	results.append(await _in_god_mode_brambles_catch_him_and_take_no_sp())
	results.append(await _noclip_flies_with_the_move_keys_without_gravity_through_walls())
	results.append(await _in_noclip_bites_and_spikes_do_nothing())
	results.append(await _noclip_turned_on_in_a_grab_lets_him_go())
	results.append(await _noclip_turned_off_he_falls_from_where_he_is())
	results.append(await _the_cheats_outlive_the_level())
	results.append(await _outside_debug_builds_nothing_of_it_runs())
	results.append(await _a_line_on_screen_lets_f1_and_f2_through())
	results.append(await _god_mode_turned_off_in_a_grab_lets_the_time_kill_him())
	results.append(await _noclip_turned_on_dead_leaves_the_body_where_it_is())
	results.append(await _without_a_man_the_label_stays_empty())
	results.append(_the_move_keys_give_the_flight_its_height())
	results.append(await _on_the_lighting_page_f1_and_f2_go_to_the_rig())
	_turn_cheats_off()
	finish(results)


func _the_cheats_are_on_f1_and_f2_and_reserved() -> bool:
	var god_keys: PackedStringArray = _keys_of(DebugOverlay.GOD_MODE_ACTION)
	var noclip_keys: PackedStringArray = _keys_of(DebugOverlay.NOCLIP_ACTION)
	var reserved: bool = (InputProfiles.RESERVED_KEYS.has(KEY_F1)
			and InputProfiles.RESERVED_KEYS.has(KEY_F2))
	return report(god_keys.has("F1") and noclip_keys.has("F2") and reserved,
			"God Mode keys [%s], Noclip keys [%s], F1 and F2 reserved %s"
			% [", ".join(god_keys), ", ".join(noclip_keys), reserved])


## With the text hidden, F1 held down with its repeats turns God Mode on once, and the label says
## so; F2 while paused turns Noclip on; F1 and F2 again turn both off, and the label goes.
func _f1_and_f2_toggle_once_with_the_text_hidden_and_paused() -> bool:
	_turn_cheats_off()
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Toggles: the man never landed")
	var overlay: DebugOverlay = await _spawn_overlay(false, man)
	_hold_key(KEY_F1)
	var god_on: bool = man.god_mode and DebugOverlay.god_mode and not man.noclip
	var label_god: String = _cheat_label(overlay)
	overlay.noclip_speed = OVERLAY_NOCLIP_SPEED
	paused = true
	_press_key(KEY_F2)
	var noclip_on: bool = (man.noclip and DebugOverlay.noclip
			and is_equal_approx(man.noclip_speed, OVERLAY_NOCLIP_SPEED))
	var label_both: String = _cheat_label(overlay)
	paused = false
	_press_key(KEY_F1)
	_press_key(KEY_F2)
	var both_off: bool = (not man.god_mode and not man.noclip and not DebugOverlay.god_mode
			and not DebugOverlay.noclip)
	var label_off: String = _cheat_label(overlay)
	var hidden: bool = not overlay.visible
	await _remove(overlay)
	await remove_player(man)
	var passed: bool = (hidden and god_on and label_god == DebugOverlay.GOD_MODE_TEXT and noclip_on
			and label_both.contains(DebugOverlay.GOD_MODE_TEXT)
			and label_both.contains(DebugOverlay.NOCLIP_TEXT) and both_off and label_off.is_empty())
	return report(passed,
			("Text hidden %s; F1 held: God Mode on %s, label \"%s\"; F2 paused: Noclip on %s, label "
			+ "\"%s\"; F1 and F2 again: both off %s, label \"%s\"") % [hidden, god_on, label_god,
			noclip_on, label_both, both_off, label_off])


func _in_god_mode_f4_still_takes_sp() -> bool:
	_turn_cheats_off()
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "F4 in God Mode: the man never landed")
	var overlay: DebugOverlay = await _spawn_overlay(false, man)
	_press_key(KEY_F1)
	var expected: float = man.soul_points.get_sp() - overlay.debug_damage
	_press_key(KEY_F4)
	var sp: float = man.soul_points.get_sp()
	var god_on: bool = man.god_mode
	_turn_cheats_off()
	await _remove(overlay)
	await remove_player(man)
	return report(god_on and is_equal_approx(sp, expected),
			"F4 in God Mode (on %s): %.1f SP, expected %.1f" % [god_on, sp, expected])


func _in_god_mode_a_hit_throws_him_and_takes_no_sp() -> bool:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Hit in God Mode: the man never landed")
	put_a_stand_in(man)
	man.god_mode = true
	var sp_before: float = man.soul_points.get_sp()
	var start_x: float = man.position.x
	var bite: Hitbox = _make_bite_by(man)
	bite.activate()
	var thrown: bool = await wait_until(man.is_knocked_back, HIT_FRAMES)
	var invulnerable: bool = _hurtbox_of(man).is_invulnerable()
	await wait_frames(HIT_FRAMES)
	var moved: float = man.position.x - start_x
	var sp: float = man.soul_points.get_sp()
	var held: bool = _escape_of(man).is_held()
	bite.queue_free()
	await remove_player(man)
	return report(thrown and invulnerable and moved > 0.0 and is_equal_approx(sp, sp_before)
			and not held,
			("Hit in God Mode: thrown %s, %.0f px away, invulnerable %s, held %s, %.1f SP, "
			+ "expected %.1f") % [thrown, moved, invulnerable, held, sp, sp_before])


## The time runs out and he goes free, alive; once his invulnerability ends, a bite grabs him again.
func _in_god_mode_a_grab_that_runs_out_lets_him_go() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Grab in God Mode: the man never landed")
	man.god_mode = true
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second) + SETTLE_FRAMES
	var let_go: bool = await wait_until(func() -> bool: return &"broke_free" in heard, frames)
	await wait_frames(SETTLE_FRAMES)
	var state: Player.State = man.get_state()
	var dead: bool = man.is_dead()
	var held: bool = escape.is_held()
	await wait_until(_hurtbox_of(man).takes_hits)
	bite.deactivate()
	bite.activate()
	var grabbed_again: bool = await wait_until(escape.is_held, HIT_FRAMES)
	bite.queue_free()
	await remove_player(man)
	return report(let_go and not dead and not held and state != Player.State.GRABBED
			and heard.slice(0, 2) == [&"grabbed", &"broke_free"] and grabbed_again,
			("Grab in God Mode, Time To Die %.1f s: let go %s, dead %s, held %s, %s, signals %s; "
			+ "grabbed again %s") % [SHORT_TIME_TO_DIE, let_go, dead, held,
			Player.State.find_key(state), heard, grabbed_again])


func _in_god_mode_spikes_neither_kill_nor_hold_him() -> bool:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Spikes in God Mode: the man never landed")
	var stand_in: StandInInput = put_a_stand_in(man)
	man.god_mode = true
	var spikes: LethalSpikes = _make_spikes(_strip_middle_ahead_of(man), false, SPIKES_WIDTH_TILES)
	await physics_frame
	var deaths: Array[int] = [0]
	man.died.connect(func() -> void: deaths[0] += 1)
	var past_x: float = spikes.position.x + SPIKES_WIDTH_TILES * TILE
	stand_in.run_direction = 1.0
	var passed_them: bool = await wait_until(func() -> bool: return man.position.x > past_x,
			RUN_FRAMES)
	var dead: bool = man.is_dead()
	var caught: bool = man.bramble_death != null and man.bramble_death.is_caught()
	spikes.queue_free()
	await remove_player(man)
	return report(passed_them and not dead and deaths[0] == 0 and not caught,
			"Spikes in God Mode: ran past them %s, dead %s, %d death(s), caught by the brambles %s"
			% [passed_them, dead, deaths[0], caught])


func _in_god_mode_brambles_catch_him_and_take_no_sp() -> bool:
	var brambles: LethalSpikes = _make_spikes(START.x, true, BRAMBLES_WIDTH_TILES)
	await physics_frame
	var man: Player = spawn_player(START)
	man.god_mode = true
	await wait_frames(CAUGHT_FRAMES)
	var caught: bool = man.snag != null and man.snag.is_caught()
	var sp: float = man.soul_points.get_sp()
	var full: float = man.soul_points.get_max_sp()
	var dead: bool = man.is_dead()
	await remove_player(man)
	brambles.queue_free()
	return report(caught and is_equal_approx(sp, full) and not dead,
			"Brambles in God Mode, %d frames: caught %s, %.1f SP of %.1f, dead %s"
			% [CAUGHT_FRAMES, caught, sp, full, dead])


## At rest he stays where he is; up and down he flies at Noclip Speed, with no sideways drift; right,
## he flies through a wall.
func _noclip_flies_with_the_move_keys_without_gravity_through_walls() -> bool:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Flight: the man never landed")
	var flyer: FlyingStandIn = _put_a_flyer(man)
	# Standing a moment puts him ON_FLOOR, so the flight's own state shows.
	await wait_frames(SETTLE_FRAMES)
	man.noclip = true
	var speed: float = man.noclip_speed
	var expected: float = speed * FLIGHT_FRAMES / Engine.physics_ticks_per_second
	var rest: Vector2 = man.position
	await wait_frames(FLIGHT_FRAMES)
	var drift: float = man.position.distance_to(rest)
	var rise: Vector2 = await _fly(man, flyer, Vector2.UP)
	var state: Player.State = man.get_state()
	var wall: StaticBody2D = make_wall(man.position.x + WALL_GAP,
			man.position.x + WALL_GAP + WALL_THICKNESS, man.position.y - WALL_HALF_HEIGHT,
			man.position.y + WALL_HALF_HEIGHT)
	await physics_frame
	var past_x: float = man.position.x + WALL_GAP + WALL_THICKNESS + body_size(man).x
	flyer.run_direction = 1.0
	var through: bool = await wait_until(func() -> bool: return man.position.x > past_x, RUN_FRAMES)
	flyer.run_direction = 0.0
	var fall: Vector2 = await _fly(man, flyer, Vector2.DOWN)
	var diagonal: Vector2 = await _fly(man, flyer, Vector2.ONE)
	wall.queue_free()
	await remove_player(man)
	var passed: bool = (drift <= FLIGHT_TOLERANCE and _is_flight(rise, -expected)
			and state == Player.State.IN_AIR and through and _is_flight(fall, expected)
			and absf(diagonal.length() - expected) <= FLIGHT_TOLERANCE)
	return report(passed,
			("Flight at %.0f px/s: drift at rest %.1f px; up %s, %s up there, down %s, diagonal "
			+ "%s, expected %.0f px each; through the wall %s") % [speed, drift, rise,
			Player.State.find_key(state), fall, diagonal, expected, through])


func _in_noclip_bites_and_spikes_do_nothing() -> bool:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Untouchable: the man never landed")
	var flyer: FlyingStandIn = _put_a_flyer(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	man.noclip = true
	var sp_before: float = man.soul_points.get_sp()
	var heard: Array[StringName] = _signals_of(_escape_of(man))
	var bite: Hitbox = _make_bite_by(man)
	bite.activate()
	await wait_frames(HIT_FRAMES)
	# Not even a grab that noclip lets go of at once.
	var held: bool = not heard.is_empty() or _escape_of(man).is_held()
	var thrown: bool = man.is_knocked_back()
	var sp: float = man.soul_points.get_sp()
	bite.queue_free()
	var spikes: LethalSpikes = _make_spikes(_strip_middle_ahead_of(man), false, SPIKES_WIDTH_TILES)
	await physics_frame
	var past_x: float = spikes.position.x + SPIKES_WIDTH_TILES * TILE
	flyer.run_direction = 1.0
	var passed_them: bool = await wait_until(func() -> bool: return man.position.x > past_x,
			RUN_FRAMES)
	var dead: bool = man.is_dead()
	var caught: bool = man.bramble_death != null and man.bramble_death.is_caught()
	spikes.queue_free()
	await remove_player(man)
	return report(not held and not thrown and is_equal_approx(sp, sp_before) and passed_them
			and not dead and not caught,
			("Noclip at low SP: bitten, held %s, thrown %s, %.1f SP of %.1f; flew past spikes %s, "
			+ "dead %s, caught %s") % [held, thrown, sp, sp_before, passed_them, dead, caught])


func _noclip_turned_on_in_a_grab_lets_him_go() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "Noclip in a grab: the man never landed")
	var escape: GrabEscape = _escape_of(man)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	var was_held: bool = escape.is_held()
	man.noclip = true
	var let_go: bool = await wait_until(func() -> bool: return not escape.is_held(), SETTLE_FRAMES)
	await wait_frames(SETTLE_FRAMES)
	var state: Player.State = man.get_state()
	var dead: bool = man.is_dead()
	bite.queue_free()
	await remove_player(man)
	return report(was_held and let_go and not dead and state != Player.State.GRABBED
			and heard == [&"grabbed", &"broke_free"],
			"Noclip in a grab: held %s, let go %s, dead %s, %s, signals %s"
			% [was_held, let_go, dead, Player.State.find_key(state), heard])


## Turned off in the middle of a flight up, with Jump pressed at once, he goes no higher: the
## flight's speed stops, and the coyote frames he had on the floor before it are gone.
func _noclip_turned_off_he_falls_from_where_he_is() -> bool:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Noclip off: the man never landed")
	var flyer: FlyingStandIn = _put_a_flyer(man)
	# Standing a moment fills his coyote frames, which the flight must not leave him.
	await wait_frames(SETTLE_FRAMES)
	man.noclip = true
	flyer.vertical_direction = -1.0
	await wait_frames(FLIGHT_FRAMES)
	var where: Vector2 = man.position
	man.noclip = false
	flyer.vertical_direction = 0.0
	flyer.press_jump()
	var highest: float = where.y
	for _frame: int in FALL_FRAMES:
		await physics_frame
		highest = minf(highest, man.position.y)
	var rose: float = where.y - highest
	var fell: float = man.position.y - where.y
	var sideways: float = absf(man.position.x - where.x)
	var falling: bool = man.velocity.y > 0.0
	var state: Player.State = man.get_state()
	var landed: bool = await wait_until_on_floor(man)
	await remove_player(man)
	return report(rose <= FLIGHT_TOLERANCE and fell > 0.0 and falling
			and sideways <= FLIGHT_TOLERANCE and state == Player.State.IN_AIR and landed,
			("Noclip off flying up, Jump pressed: rose %.1f px more, fell %.0f px in %d frames, "
			+ "falling %s, %.1f px sideways, %s; landed on the floor %s") % [rose, fell,
			FALL_FRAMES, falling, sideways, Player.State.find_key(state), landed])


## Turned on in one copy of the test room, the cheats are on in the next copy's man, with the label,
## as after a death or a jump to a phase, until F1 and F2 turn them off.
func _the_cheats_outlive_the_level() -> bool:
	_turn_cheats_off()
	var first: Node = await _add_room()
	var first_on: bool = _find_overlay(first) != null
	_press_key(KEY_F1)
	_press_key(KEY_F2)
	await _remove(first)
	var second: Node = await _add_room()
	var man: Player = second.get_node(^"Player") as Player
	var overlay: DebugOverlay = _find_overlay(second)
	var still_on: bool = man.god_mode and man.noclip
	var label: String = _cheat_label(overlay) if overlay != null else ""
	_press_key(KEY_F1)
	_press_key(KEY_F2)
	var off: bool = not man.god_mode and not man.noclip
	await _remove(second)
	return report(first_on and still_on and label.contains(DebugOverlay.GOD_MODE_TEXT)
			and label.contains(DebugOverlay.NOCLIP_TEXT) and off,
			"Next copy of the room: both on %s, label \"%s\"; F1 and F2 there turn them off %s"
			% [still_on, label, off])


## With both cheats left on, an overlay that answers as a release build frees itself before it gives
## them to the man, and F1, F2 and F4 do nothing.
func _outside_debug_builds_nothing_of_it_runs() -> bool:
	DebugOverlay.god_mode = true
	DebugOverlay.noclip = true
	var man: Player = await spawn_on_floor(START)
	if man == null:
		_turn_cheats_off()
		return report(false, "Release build: the man never landed")
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.set_script(ReleaseOverlay)
	overlay.player = man
	root.add_child(overlay)
	await process_frame
	await process_frame
	var freed: bool = not is_instance_valid(overlay)
	var sp_before: float = man.soul_points.get_sp()
	_press_key(KEY_F1)
	_press_key(KEY_F2)
	_press_key(KEY_F4)
	var untouched: bool = (not man.god_mode and not man.noclip
			and is_equal_approx(man.soul_points.get_sp(), sp_before))
	_turn_cheats_off()
	await remove_player(man)
	return report(freed and untouched,
			"Release build: overlay freed %s; the man without cheats and his SP as it was %s"
			% [freed, untouched])


## The balloon of the lines lets F1 and F2 through, as the other debug keys: with a line on screen,
## the balloon gets the keys before the overlay and would keep them.
func _a_line_on_screen_lets_f1_and_f2_through() -> bool:
	var balloon: DialogueBalloon = (load(BALLOON_PATH) as PackedScene).instantiate() as DialogueBalloon
	# In the tree, so its _ready takes in the timer it makes as it is made: freed outside the tree,
	# the balloon would leave that timer behind.
	root.add_child(balloon)
	var lets_through: bool = (balloon.lets_through.has(DebugOverlay.GOD_MODE_ACTION)
			and balloon.lets_through.has(DebugOverlay.NOCLIP_ACTION))
	await _remove(balloon)
	return report(lets_through, "A line lets F1 and F2 through: %s" % lets_through)


## The guard does not stick: with God Mode off again before the time runs out, it kills him.
func _god_mode_turned_off_in_a_grab_lets_the_time_kill_him() -> bool:
	var man: Player = await _low_sp_man()
	if man == null:
		return report(false, "God Mode off in a grab: the man never landed")
	man.god_mode = true
	var escape: GrabEscape = _escape_of(man)
	_use_short_time_to_die(escape)
	var heard: Array[StringName] = _signals_of(escape)
	var bite: Hitbox = await _bite_and_wait_for_the_grab(man)
	man.god_mode = false
	var frames: int = roundi(SHORT_TIME_TO_DIE * Engine.physics_ticks_per_second) + SETTLE_FRAMES
	var died: bool = await wait_until(man.is_dead, frames)
	bite.queue_free()
	await remove_player(man)
	return report(died and heard == [&"grabbed", &"died"],
			"God Mode off in a grab, Time To Die %.1f s: died %s, signals %s"
			% [SHORT_TIME_TO_DIE, died, heard])


## Turned on during a death's fade, noclip does not make the body fall through the floor.
func _noclip_turned_on_dead_leaves_the_body_where_it_is() -> bool:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Noclip dead: the man never landed")
	put_a_stand_in(man)
	await wait_frames(SETTLE_FRAMES)
	man.die()
	await physics_frame
	var where: Vector2 = man.position
	man.noclip = true
	await wait_frames(FALL_FRAMES)
	var moved: float = man.position.distance_to(where)
	await remove_player(man)
	return report(moved <= FLIGHT_TOLERANCE,
			"Noclip on dead: the body moved %.1f px in %d frames" % [moved, FALL_FRAMES])


## In a level whose overlay has no man, the cheats reach no one, so the label says nothing.
func _without_a_man_the_label_stays_empty() -> bool:
	DebugOverlay.god_mode = true
	DebugOverlay.noclip = true
	var overlay: DebugOverlay = await _spawn_overlay(true, null)
	var label: String = _cheat_label(overlay)
	_turn_cheats_off()
	await _remove(overlay)
	return report(label.is_empty(), "No man, both cheats on: label \"%s\"" % label)


## The man's own input reads Move Up and Move Down for the flight's height.
func _the_move_keys_give_the_flight_its_height() -> bool:
	var input: PlayerInput = PlayerInput.new()
	Input.action_press(&"move_up")
	var up: float = input.get_vertical_direction()
	Input.action_release(&"move_up")
	Input.action_press(&"move_down")
	var down: float = input.get_vertical_direction()
	Input.action_release(&"move_down")
	var none: float = input.get_vertical_direction()
	input.free()
	return report(up == -1.0 and down == 1.0 and none == 0.0,
			"Move Up %.0f, Move Down %.0f, neither %.0f; expected -1, 1 and 0" % [up, down, none])


## On the lighting page the lighting rig gets F1 and F2 first, as its other keys, so they change the
## light and leave the cheats as they are; on the numbers page, F1 is God Mode again.
func _on_the_lighting_page_f1_and_f2_go_to_the_rig() -> bool:
	_turn_cheats_off()
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return report(false, "Lighting page: the man never landed")
	var lighting: FakeLighting = FakeLighting.new()
	root.add_child(lighting)
	var overlay: DebugOverlay = await _spawn_overlay(false, man)
	overlay.show_page(DebugOverlay.Page.LIGHTING)
	_press_key(KEY_F1)
	_press_key(KEY_F2)
	var to_the_rig: PackedStringArray = lighting.keys.duplicate()
	var cheats_there: bool = man.god_mode or man.noclip
	overlay.show_page(DebugOverlay.Page.NUMBERS)
	_press_key(KEY_F1)
	var god_on_numbers: bool = man.god_mode
	_turn_cheats_off()
	await _remove(overlay)
	lighting.queue_free()
	await remove_player(man)
	return report(to_the_rig == PackedStringArray(["F1", "F2"]) and not cheats_there
			and god_on_numbers,
			("Lighting page: the rig got %s, cheats on %s; numbers page: F1 turns God Mode on %s")
			% [to_the_rig, cheats_there, god_on_numbers])


## Flies the man direction for FLIGHT_FRAMES, then stops him, and gives how far he went.
func _fly(man: Player, flyer: FlyingStandIn, direction: Vector2) -> Vector2:
	var from: Vector2 = man.position
	flyer.run_direction = direction.x
	flyer.vertical_direction = direction.y
	await wait_frames(FLIGHT_FRAMES)
	flyer.run_direction = 0.0
	flyer.vertical_direction = 0.0
	await physics_frame
	return man.position - from


## True if a flight went straight up or down, by expected_y px, give or take FLIGHT_TOLERANCE.
func _is_flight(went: Vector2, expected_y: float) -> bool:
	return absf(went.x) <= FLIGHT_TOLERANCE and absf(went.y - expected_y) <= FLIGHT_TOLERANCE


func _turn_cheats_off() -> void:
	DebugOverlay.god_mode = false
	DebugOverlay.noclip = false


## What the cheats' label says while it shows; "" while it does not.
func _cheat_label(overlay: DebugOverlay) -> String:
	var label: Label = overlay.get_node(^"%CheatLabel") as Label
	return label.text if label.is_visible_in_tree() else ""


## An overlay on its own, linked to man, in the scene, after a frame: _initialize runs before the
## root is in the tree, so a node added then only gets its _ready once it yields.
func _spawn_overlay(start_visible: bool, man: Player) -> DebugOverlay:
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.start_visible = start_visible
	overlay.player = man
	root.add_child(overlay)
	await process_frame
	return overlay


## A copy of the test room, ROOM_OFFSET away, after a frame.
func _add_room() -> Node:
	var room: Node2D = TEST_ROOM_SCENE.instantiate() as Node2D
	room.position = ROOM_OFFSET
	root.add_child(room)
	await process_frame
	return room


func _find_overlay(room: Node) -> DebugOverlay:
	for child: Node in room.get_children():
		if child is DebugOverlay:
			return child as DebugOverlay
	return null


## A strip of spikes or brambles with its middle at x, on the floor. The case frees it.
func _make_spikes(middle_x: float, catches: bool, width_tiles: int) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.catches = catches
	spikes.width_tiles = width_tiles
	spikes.position = Vector2(middle_x, 0.0)
	root.add_child(spikes)
	return spikes


## The x of the middle of a strip of SPIKES_WIDTH_TILES that starts SPIKES_AHEAD right of man.
func _strip_middle_ahead_of(man: Player) -> float:
	return man.position.x + SPIKES_AHEAD + SPIKES_WIDTH_TILES * TILE / 2.0


## A man on the floor, with a stand-in input and SP below Low Threshold; null if he never lands.
func _low_sp_man() -> Player:
	var man: Player = await spawn_on_floor(START)
	if man == null:
		return null
	put_a_stand_in(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	return man


## A bite on the man's left, on, and waits for it to grab him. The case frees the bite.
func _bite_and_wait_for_the_grab(man: Player) -> Hitbox:
	var bite: Hitbox = _make_bite_by(man)
	bite.activate()
	await wait_until(_escape_of(man).is_held, HIT_FRAMES)
	return bite


## A bite on the man's left, still off. The case frees it.
func _make_bite_by(man: Player) -> Hitbox:
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = BITE_SIZE
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = rectangle
	shape.position = Vector2(0.0, -BITE_SIZE.y / 2.0)
	var bite: Hitbox = HITBOX_SCENE.instantiate() as Hitbox
	bite.add_child(shape)
	bite.position = man.position + Vector2(-BITE_OFFSET, 0.0)
	bite.damage = BITE_DAMAGE
	bite.knockback_distance = BITE_DISTANCE
	bite.knockback_height = BITE_HEIGHT
	root.add_child(bite)
	return bite


## Gives the grab its own copy of Stats with SHORT_TIME_TO_DIE, so the .tres stays as it is.
func _use_short_time_to_die(escape: GrabEscape) -> void:
	escape.stats = escape.stats.duplicate() as GrabStats
	escape.stats.time_to_die = SHORT_TIME_TO_DIE


## The names of the grab's signals, in the order they come from now on.
func _signals_of(escape: GrabEscape) -> Array[StringName]:
	var heard: Array[StringName] = []
	escape.grabbed.connect(func() -> void: heard.append(&"grabbed"))
	escape.broke_free.connect(func() -> void: heard.append(&"broke_free"))
	escape.died.connect(func() -> void: heard.append(&"died"))
	return heard


func _escape_of(man: Player) -> GrabEscape:
	return man.get_node(^"GrabEscape") as GrabEscape


func _hurtbox_of(man: Player) -> Hurtbox:
	return man.get_node(^"Hurtbox") as Hurtbox


## Puts a flying stand-in in the man's input, as a child of him, and hands it back.
func _put_a_flyer(man: Player) -> FlyingStandIn:
	var flyer: FlyingStandIn = FlyingStandIn.new()
	man.add_child(flyer)
	man.input = flyer
	return flyer


## One press and release of a key, sent through the viewport as the keyboard would.
func _press_key(keycode: Key) -> void:
	root.push_input(_key_event(keycode, true, false))
	root.push_input(_key_event(keycode, false, false))


## A key held down, with the repeats the keyboard sends, and let go.
func _hold_key(keycode: Key) -> void:
	root.push_input(_key_event(keycode, true, false))
	for _repeat: int in KEY_REPEATS:
		root.push_input(_key_event(keycode, true, true))
	root.push_input(_key_event(keycode, false, false))


## A key event; echo marks the repeats the keyboard sends while a key is held down.
func _key_event(keycode: Key, pressed: bool, echo: bool) -> InputEventKey:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = keycode
	key.physical_keycode = keycode
	key.pressed = pressed
	key.echo = echo
	return key


## The keys of an action in the Input Map, by name, such as "F1"; none if the action is missing.
func _keys_of(action: StringName) -> PackedStringArray:
	var keys: PackedStringArray = []
	if InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(OS.get_keycode_string((event as InputEventKey).physical_keycode))
	return keys


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame


## A stand-in input that can also be told to go up or down, which only a flight reads.
class FlyingStandIn extends "res://tests/support/stand_in_input.gd":
	## -1 to go up, 1 to go down, 0 to stay at the height he is.
	var vertical_direction: float = 0.0

	func get_vertical_direction() -> float:
		return vertical_direction


## Stands in for the lighting rig: a text of its own, and the keys it is given, by name.
class FakeLighting extends Node:
	var keys: PackedStringArray = []

	func _ready() -> void:
		add_to_group(DebugOverlay.LIGHTING_GROUP)

	func get_debug_text() -> String:
		return "fake lighting settings"

	func handle_debug_key(event: InputEvent) -> bool:
		var key: InputEventKey = event as InputEventKey
		if key == null or not key.pressed or key.echo:
			return false
		keys.append(OS.get_keycode_string(key.physical_keycode))
		return true


## The debug overlay as a release build runs it, where OS.is_debug_build() is false.
class ReleaseOverlay extends DebugOverlay:
	func _is_debug_build() -> bool:
		return false
