# Checks which moments and states make the controller vibrate, and how (ADR 0062). The ladder in
# rumble_stats.tres, one group a step: every tick is short and runs the strong motor below a hit, in
# level and summed over its time, the moves' ticks with a thump on it; only the grave moments run
# the strong motor at a half or more; his death is the strongest on each motor and the longest, but
# for the short stab of a death on spikes; and the held vibrations stay low. In a scene with the
# player and the game camera: each moment starts its own pulse, a rock near the man by the share its
# distance gives, a normal landing by how hard PlayerSounds says it was and a press to break free by
# the share his headway gives, and the moments that should not start one start none; presses in the
# same frame keep their tick, and breaking free right after them takes each motor to the stronger of
# the two. The grab holds a vibration under its pulse that grows as he sinks and ends as he breaks
# free or dies; in a real grab, presses tick firmer as his headway grows. The crucifix held up holds
# one under its pulse that grows through its warning and ends as it comes down or as he dies with it
# up; its running out fades out; what it pushes coming into its light knocks once a frame, not a
# gate's unlocker; after his death, nothing it says vibrates. His death on lethal spikes stabs,
# whichever of the two is heard first, and only on one frame. The real moves start their ticks: a
# jump, a landing by how far he fell, his head hitting a ceiling, once even when pushed against it
# for frames in a row, and getting on a wall, once.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_rumble_moments.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const ROCK_SCENE: PackedScene = preload("res://scenes/objects/traps/falling_rock.tscn")
const HAZARD_SCENE: PackedScene = preload("res://scenes/objects/traps/spikes.tscn")
const HITBOX_SCENE: PackedScene = preload("res://scenes/characters/components/hitbox.tscn")
const REPELLABLE_SCENE: PackedScene = preload("res://scenes/characters/components/repellable.tscn")
const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const UNLOCKER_SCENE: PackedScene = preload("res://scenes/objects/gates/gate_unlocker.tscn")
const RUMBLE_STATS: RumbleStats = preload("res://scenes/others/feedback/rumble_stats.tres")
## How close two numbers must be to count as the same.
const TOLERANCE: float = 0.0001
## How close a level read a frame after the state it follows must be.
const FRAME_TOLERANCE: float = 0.02
## A controller id no controller plugged into the computer running the tests is likely to have, so
## no real controller vibrates, and a button no action uses, pressed to make it the one in use.
const PAD: int = 6
const SPARE_BUTTON: JoyButton = JOY_BUTTON_PADDLE4
## The ladder's limits: the longest tick, in s; the strong motor's level only grave moments reach;
## the most a held vibration runs on each motor.
const TICK_MOST: float = 0.1
const STRONG_GRAVE: float = 0.5
const HELD_MOST: float = 0.4
## The moves' ticks, which thump on the strong motor, and the least they ask of it: on the weak motor
## alone, near where it is felt at all, a tick felt like a tickle in play and then not at all. The
## ticks that come over a held vibration, Struggle and Crucifix Struck, run the weak motor alone.
const MOVE_TICKS: Array[StringName] = [&"jump", &"landing", &"head_bump", &"on_wall"]
const MOVE_STRONG_LEAST: float = 0.2
## Where the player stands, above a floor at y = 0, and the rest of the moments' scene, as in
## test_camera_shake.gd: the hazard away from him, a rock beside him, outside its trigger, and one
## past Rock Reach.
const START: Vector2 = Vector2(0.0, -100.0)
const FLOOR_HALF_WIDTH: float = 2000.0
const HAZARD_AT: Vector2 = Vector2(-600.0, -40.0)
const NEAR_ROCK_X: float = 150.0
const ROCK_HEIGHT: float = 300.0
const FAR_ROCK_X: float = 1500.0
## Presses to break free in a row.
const IN_A_ROW: int = 5
## Frames past a pulse's end the cases wait for it to be over.
const END_MARGIN_FRAMES: int = 3
## How far he sinks in the grab case's two steps.
const HALF_SUNK: float = 0.5
## The fall that lands hard: higher than Hard Land Height (PlayerSounds) by this much.
const HARD_FALL_MARGIN: float = 200.0
## The gap between his head and the ceiling above him, and where the wall stands from him and how
## high he starts beside it.
const CEILING_GAP: float = 60.0
const WALL_FROM_START: float = 80.0
const WALL_HEIGHT: float = 1200.0
const IN_THE_AIR: float = 400.0
## Pushed up into the ceiling: the speed set on each frame, in px/s, more than a frame of gravity
## takes off; for how many frames; and the fewest of them his head must spend on the ceiling.
const PUSH_UP_SPEED: float = 900.0
const PUSH_FRAMES: int = 12
const MIN_FRAMES_ON_CEILING: int = 3
## A bite at low SP, as in test_grab_escape.gd: the damage that takes his SP low, the bite's box, how
## far to his left it stands, what it does, and the frames it has to grab him in.
const DAMAGE_TO_LOW: float = 80.0
const BITE_SIZE: Vector2 = Vector2(96.0, 96.0)
const BITE_OFFSET: float = 30.0
const BITE_DAMAGE: float = 10.0
const BITE_DISTANCE: float = 150.0
const BITE_HEIGHT: float = 40.0
const HIT_FRAMES: int = 10
## Presses to break free in the real grab, one a physics frame.
const PRESSES: int = 3
## The crucifix's use time in the case that lets it run out, in s.
const SHORT_USE_TIME: float = 0.5
## A lost soul's stand-in for the crucifix's light: its radius, where it waits until a case puts it
## somewhere, how far from the crucifix it is put in the light, and the frames the light's overlap
## takes to see it gone once it is out.
const SOUL_RADIUS: float = 16.0
const FAR_AWAY: Vector2 = Vector2(0.0, -5000.0)
const INSIDE_THE_LIGHT: float = 50.0
const OVERLAP_FRAMES: int = 2
## How long the crucifix stays up once Death is over, in s, in the case of his death with it up.
const AFTER_DEATH_TIME: float = 0.5
## Where lethal spikes stand on the floor, to his right.
const SPIKES_FROM_START: float = 200.0


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_the_ladder_keeps_the_strong_motor_for_the_grave_moments())
	results.append(_shares_follow_progress_and_the_fall())
	results.append(await _each_moment_starts_its_own_pulse())
	results.append(await _the_grab_holds_a_vibration_that_grows_as_he_sinks())
	results.append(await _presses_in_a_real_grab_tick_firmer_with_his_headway())
	results.append(await _the_crucifix_held_up_holds_a_vibration_that_grows_as_it_runs_out())
	results.append(await _his_death_on_spikes_stabs_first())
	results.append(await _a_stab_needs_the_spikes_and_his_death_on_one_frame())
	results.append(await _something_coming_into_the_crucifix_s_light_knocks_once())
	results.append(await _the_crucifix_running_out_fades_out())
	results.append(await _his_death_with_the_crucifix_up_ends_its_held_vibration())
	results.append(await _after_his_death_the_crucifix_vibrates_nothing())
	results.append(await _a_jump_and_each_landing_tick_by_how_far_he_fell())
	results.append(await _his_head_on_a_ceiling_and_getting_on_a_wall_tick_once())
	Input.stop_joy_vibration(PAD)
	finish(results)


## The ladder in rumble_stats.tres, one group a step: every tick lasts TICK_MOST s or less and runs
## the strong motor lower than Hit, both at its top and over its time, so a hit from a demon or a
## hazard weighs more than a move; each move's tick asks the strong motor for MOVE_STRONG_LEAST or
## more; only the grave moments run the strong motor at STRONG_GRAVE or more; his death lasts longer
## than any other pulse and is at least as strong as any other on each motor, but for Spike Death,
## the stab that is part of a death on spikes, which may run the weak motor above it but runs it
## alone, for TICK_MOST s or less; the held vibrations are all in Held and run each motor at
## HELD_MOST or less. Every step has something.
func _the_ladder_keeps_the_strong_motor_for_the_grave_moments() -> bool:
	var death: RumblePulse = RUMBLE_STATS.death
	var spike_death: RumblePulse = RUMBLE_STATS.spike_death
	var hit: RumblePulse = RUMBLE_STATS.hit
	var wrong: Array[String] = []
	for move: StringName in MOVE_TICKS:
		var tick: RumblePulse = RUMBLE_STATS.get(move) as RumblePulse
		if tick == null or tick.strong < MOVE_STRONG_LEAST:
			wrong.append("the move's tick %s asks the strong motor for %s (%.2f at least)"
					% [move, "nothing" if tick == null else "%.2f" % tick.strong,
					MOVE_STRONG_LEAST])
	var counted: Dictionary[String, int] = {}
	var group: String = ""
	for property: Dictionary in RUMBLE_STATS.get_property_list():
		var property_name: String = property["name"]
		if int(property["usage"]) & PROPERTY_USAGE_GROUP:
			group = property_name
			continue
		var value: Variant = RUMBLE_STATS.get(property_name)
		if value is RumblePulse:
			var pulse: RumblePulse = value as RumblePulse
			counted[group] = counted.get(group, 0) + 1
			if group == "Ticks" and (pulse.strong >= hit.strong
					or _strong_motor_area(pulse) >= _strong_motor_area(hit)
					or pulse.duration > TICK_MOST):
				wrong.append(("the tick %s runs the strong motor at %.2f (Hit's %.2f), %.4f over "
						+ "its time (Hit's %.4f), for %.2f s") % [property_name, pulse.strong,
						hit.strong, _strong_motor_area(pulse), _strong_motor_area(hit),
						pulse.duration])
			if group != "Grave" and pulse.strong >= STRONG_GRAVE:
				wrong.append("%s, in %s, runs the strong motor at %.2f"
						% [property_name, group, pulse.strong])
			if pulse == spike_death and (pulse.strong > 0.0 or pulse.duration > TICK_MOST):
				wrong.append("the stab %s runs the strong motor at %.2f for %.2f s"
						% [property_name, pulse.strong, pulse.duration])
			if pulse != death and pulse != spike_death and (pulse.duration >= death.duration
					or pulse.weak > death.weak or pulse.strong > death.strong):
				wrong.append("%s (%.2f, %.2f, %.2f s) against death's (%.2f, %.2f, %.2f s)"
						% [property_name, pulse.weak, pulse.strong, pulse.duration, death.weak,
						death.strong, death.duration])
		elif value is RumbleSustain:
			var held: RumbleSustain = value as RumbleSustain
			counted[group] = counted.get(group, 0) + 1
			if group != "Held" or held.weak > HELD_MOST or held.strong > HELD_MOST:
				wrong.append("the held %s, in %s, runs at (%.2f, %.2f)"
						% [property_name, group, held.weak, held.strong])
	for step: String in ["Ticks", "Blows", "Grave", "Held"]:
		if counted.get(step, 0) == 0:
			wrong.append("%s is empty" % step)
	return report(wrong.is_empty(), "the ladder's steps hold %s; wrong: %s" % [counted, wrong])


## The shares the moments and states run at: a press to break free from Struggle Start Share with no
## headway to all of it close to breaking free; a held vibration from its Start Share as its state
## begins to all of it at its worst; a pulse blended a weight of the way to another; a landing from
## Landing at 0 to Hard Landing at 1, below the straight line halfway. Values out of 0 to 1 are kept
## in range and ones that are not a number count as 0. The crucifix's warning is in
## test_crucifix_warning.gd.
func _shares_follow_progress_and_the_fall() -> bool:
	var stats: RumbleStats = RUMBLE_STATS
	var start: float = stats.struggle_start_share
	var presses: bool = (is_equal_approx(stats.struggle_share(0.0), start)
			and is_equal_approx(stats.struggle_share(0.5), lerpf(start, 1.0, 0.5))
			and stats.struggle_share(1.0) == 1.0 and stats.struggle_share(2.0) == 1.0
			and is_equal_approx(stats.struggle_share(NAN), start))
	var held: RumbleSustain = RumbleSustain.new(0.2, 0.4, 0.25)
	var holds: bool = (is_equal_approx(held.share_at(0.0), 0.25)
			and is_equal_approx(held.share_at(0.5), 0.625) and held.share_at(1.0) == 1.0
			and is_equal_approx(held.share_at(-1.0), 0.25) and is_equal_approx(held.share_at(NAN), 0.25))
	var from: RumblePulse = RumblePulse.new(0.2, 0.0, 0.1, 0.0)
	var to: RumblePulse = RumblePulse.new(0.6, 0.8, 0.3, 1.0)
	var blended: RumblePulse = from.blended_with(to, 0.5)
	var blends: bool = (is_equal_approx(blended.weak, 0.4) and is_equal_approx(blended.strong, 0.4)
			and is_equal_approx(blended.duration, 0.2) and is_equal_approx(blended.fade, 0.5)
			and is_equal_approx(from.blended_with(to, 2.0).weak, 0.6)
			and is_equal_approx(from.blended_with(to, NAN).weak, 0.2))
	var halfway: RumblePulse = stats.landing_at(0.5)
	var straight: RumblePulse = stats.landing.blended_with(stats.hard_landing, 0.5)
	var landings: bool = (_same_pulse(stats.landing_at(0.0), stats.landing)
			and _same_pulse(stats.landing_at(1.0), stats.hard_landing)
			and _same_pulse(halfway,
					stats.landing.blended_with(stats.hard_landing, pow(0.5, stats.landing_growth)))
			and halfway.weak < straight.weak and halfway.strong < straight.strong
			and _same_pulse(stats.landing_at(2.0), stats.hard_landing)
			and _same_pulse(stats.landing_at(NAN), stats.landing))
	return report(presses and holds and blends and landings,
			("presses from Struggle Start Share to all of it: %s; a held vibration from its Start Share "
			+ "to all of it: %s; a pulse blended halfway: %s; a landing from Landing to Hard Landing, "
			+ "below the straight line halfway (%.3f, %.3f against %.3f, %.3f): %s") % [presses, holds,
			blends, halfway.weak, halfway.strong, straight.weak, straight.strong, landings])


## True when a and b have the same motors, time and fade.
func _same_pulse(a: RumblePulse, b: RumblePulse) -> bool:
	return (is_equal_approx(a.weak, b.weak) and is_equal_approx(a.strong, b.strong)
			and is_equal_approx(a.duration, b.duration) and is_equal_approx(a.fade, b.fade))


## The camera's impacts start a pulse on PAD, the controller in use, for each moment: the moment's
## own pulse; a rock near the man that pulse times the share its distance gives, which lies between 0
## and 1; a normal landing the blend from Landing to Hard Landing by how hard PlayerSounds says the
## last one was; a press to break free Struggle at the share his headway gives. A grab and raising
## the crucifix start their held vibrations too, under their pulses. A hazard hitting another body,
## holding Jump to break free and a rock past Rock Reach start none. Each handler is called with
## what its signal carries, so the other listeners do not run. Presses in the same frame keep their
## tick, and breaking free right after them takes each motor to the stronger of the two pulses.
func _each_moment_starts_its_own_pulse() -> bool:
	var hazard: Hazard = HAZARD_SCENE.instantiate() as Hazard
	hazard.position = HAZARD_AT
	root.add_child(hazard)
	var near_rock: FallingRock = _add_rock(Vector2(START.x + NEAR_ROCK_X, -ROCK_HEIGHT))
	var far_rock: FallingRock = _add_rock(Vector2(START.x + FAR_ROCK_X, -ROCK_HEIGHT))
	var others: Array[Node] = [hazard, near_rock, far_rock]
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		for node: Node in others:
			node.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var player: Player = scene.player
	var impacts: ImpactFeedback = scene.impacts
	var pulses: RumbleStats = impacts.rumble_stats
	var grab: GrabEscape = player.get_node(^"GrabEscape") as GrabEscape
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var sounds: PlayerSounds = player.get_node(^"PlayerSounds") as PlayerSounds
	var hurtbox: Hurtbox = player.get_node(^"Hurtbox") as Hurtbox
	var broke_at: Vector2 = (near_rock.global_position
			+ Vector2.DOWN * maxf(near_rock.get_fall_distance(), 0.0))
	var near_share: float = impacts.stats.rock_closeness(broke_at.distance_to(player.global_position))
	var press_share: float = pulses.struggle_share(grab.get_escape_progress())
	var soft_landing: RumblePulse = pulses.landing_at(sounds.get_last_landing_share())
	# What happens, its signal, what the signal carries, its pulse (null for none), and the share of
	# that pulse it must ask for.
	var moments: Array[Array] = [
		["a hit", hurtbox.hit_received, [null], pulses.hit, 1.0],
		["a hazard on him", hazard.player_hit, [player, hazard.health_fraction], pulses.hit, 1.0],
		["a hazard on another body", hazard.player_hit, [scene.floor_body, hazard.health_fraction],
				null, 0.0],
		["a grab", grab.grabbed, [], pulses.grab, 1.0],
		["breaking free", grab.broke_free, [], pulses.break_free, 1.0],
		["a press to break free", grab.struggled, [true], pulses.struggle, press_share],
		["holding Jump to break free", grab.struggled, [false], null, 0.0],
		["his death", player.died, [], pulses.death, 1.0],
		["a hard landing", sounds.land_played, [true], pulses.hard_landing, 1.0],
		["a normal landing", sounds.land_played, [false], soft_landing, 1.0],
		["a jump", player.jumped, [0, 0], pulses.jump, 1.0],
		["a wall jump", player.wall_jumped, [0, 0], pulses.jump, 1.0],
		["his head on a ceiling", player.head_bumped, [], pulses.head_bump, 1.0],
		["getting on a wall", player.got_on_wall, [], pulses.on_wall, 1.0],
		["raising the crucifix", crucifix.raised, [], pulses.crucifix_raised, 1.0],
		["the crucifix running out", crucifix.ran_out, [], pulses.crucifix_ran_out, 1.0],
		["something coming into its light", crucifix.struck, [], pulses.crucifix_struck, 1.0],
		["losing it", crucifix.lost, [], pulses.crucifix_lost, 1.0],
		["a rock near him", near_rock.broke, [], pulses.rock, near_share],
		["a rock past Rock Reach", far_rock.broke, [], null, 0.0],
	]
	var wrong: Array[String] = []
	if near_share <= 0.0 or near_share >= 1.0:
		wrong.append("the near rock's share is %.3f, not between 0 and 1" % near_share)
	for moment: Array in moments:
		scene.rumble.stop()
		if not _call_handler(moment[1], impacts, moment[2]):
			wrong.append("%s: not heard" % moment[0])
			continue
		var pulse: RumblePulse = moment[3]
		var wanted: Vector2 = (Vector2(pulse.weak, pulse.strong) * float(moment[4]) if pulse != null
				else Vector2.ZERO)
		if not _asked_of(PAD).is_equal_approx(wanted):
			wrong.append("%s: %s (%s)" % [moment[0], _asked_of(PAD), wanted])
	scene.rumble.stop()
	for press: int in IN_A_ROW:
		_call_handler(grab.struggled, impacts, [true])
	var tick: Vector2 = Vector2(pulses.struggle.weak, pulses.struggle.strong) * press_share
	if not _asked_of(PAD).is_equal_approx(tick):
		wrong.append("%d presses to break free in a row: %s (%s)" % [IN_A_ROW, _asked_of(PAD), tick])
	_call_handler(grab.broke_free, impacts, [])
	var freed: Vector2 = tick.max(Vector2(pulses.break_free.weak, pulses.break_free.strong))
	if not _asked_of(PAD).is_equal_approx(freed):
		wrong.append("breaking free right after them: %s (%s)" % [_asked_of(PAD), freed])
	await _free_scene(scene)
	for node: Node in others:
		node.queue_free()
	await process_frame
	return report(wrong.is_empty(), "each moment starts its own pulse; wrong: %s" % [wrong])


## A grab starts its pulse with the held vibration under it; once the pulse is over, the held one
## runs at its Start Share, and it grows as he sinks: at HALF_SUNK and at 1, his death's depth. Breaking
## free ends it, so once the snap is over the controller stops and the node goes idle. A grab that
## ends in his death ends it too. The cases' held vibration is flat, so its level reads the same on
## every frame.
func _the_grab_holds_a_vibration_that_grows_as_he_sinks() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var stats: RumbleStats = _flat_stats()
	scene.impacts.rumble_stats = stats
	var grab: GrabEscape = scene.player.get_node(^"GrabEscape") as GrabEscape
	var held: RumbleSustain = stats.grab_sink
	var full: Vector2 = Vector2(held.weak, held.strong)
	_call_handler(grab.grabbed, scene.impacts, [])
	var grabbed: Vector2 = _asked_of(PAD)
	await _frames(_frames_of(stats.grab))
	var held_at_start: Vector2 = _asked_of(PAD)
	_call_handler(grab.sink_changed, scene.impacts, [HALF_SUNK])
	var half_sunk: Vector2 = _asked_of(PAD)
	_call_handler(grab.sink_changed, scene.impacts, [1.0])
	var sunk: Vector2 = _asked_of(PAD)
	_call_handler(grab.broke_free, scene.impacts, [])
	var freed: Vector2 = _asked_of(PAD)
	await _frames(_frames_of(stats.break_free))
	var after_freed: Vector2 = _asked_of(PAD)
	var idle: bool = not scene.rumble.is_processing()
	_call_handler(grab.grabbed, scene.impacts, [])
	_call_handler(scene.player.died, scene.impacts, [])
	var died: Vector2 = _asked_of(PAD)
	await _frames(_frames_of(stats.death))
	var after_death: Vector2 = _asked_of(PAD)
	await _free_scene(scene)
	var grab_pulse: Vector2 = Vector2(stats.grab.weak, stats.grab.strong)
	var break_free: Vector2 = Vector2(stats.break_free.weak, stats.break_free.strong)
	var death: Vector2 = Vector2(stats.death.weak, stats.death.strong)
	return report(grabbed.is_equal_approx(grab_pulse)
			and held_at_start.is_equal_approx(full * held.start_share)
			and half_sunk.is_equal_approx(full * held.share_at(HALF_SUNK)) and sunk.is_equal_approx(full)
			and freed.is_equal_approx(break_free) and after_freed == Vector2.ZERO and idle
			and died.is_equal_approx(death) and after_death == Vector2.ZERO,
			("a grab asks %s (%s); after its pulse %s (%s); at %.1f sunk %s (%s); at 1 %s (%s); breaking "
			+ "free %s (%s), then %s with the node idle: %s; his death in a grab %s (%s), then %s")
			% [grabbed, grab_pulse, held_at_start, full * held.start_share, HALF_SUNK, half_sunk,
			full * held.share_at(HALF_SUNK), sunk, full, freed, break_free, after_freed, idle, died,
			death, after_death])


## In a real grab, by a bite at low SP, each press to break free ticks at the share his headway gives
## when it counts: after PRESSES presses the headway is above 0, so the last tick is firmer than
## Struggle Start Share, on the weak motor, where nothing else runs as strong.
func _presses_in_a_real_grab_tick_firmer_with_his_headway() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var pulses: RumbleStats = scene.impacts.rumble_stats
	var grab: GrabEscape = scene.player.get_node(^"GrabEscape") as GrabEscape
	var input: StandInInput = put_a_stand_in(scene.player)
	scene.player.soul_points.take_damage(DAMAGE_TO_LOW)
	var bite: Hitbox = _make_bite_by(scene.player)
	bite.activate()
	var held: bool = await wait_until(grab.is_held, HIT_FRAMES)
	await _frames(_frames_of(pulses.grab))
	var ticks: Array[float] = []
	var headways: Array[float] = []
	grab.struggled.connect(func(pressed: bool) -> void:
			if pressed:
				ticks.append(_asked_of(PAD).x)
				headways.append(grab.get_escape_progress()))
	for press: int in PRESSES:
		await physics_frame
		input.press_jump()
	await physics_frame
	bite.queue_free()
	await _free_scene(scene)
	var headway: float = headways.back() if not headways.is_empty() else 0.0
	var share: float = pulses.struggle_share(headway)
	var tick: float = ticks.back() if not ticks.is_empty() else 0.0
	return report(held and ticks.size() == PRESSES and headway > 0.0
			and share > pulses.struggle_start_share and is_equal_approx(tick, pulses.struggle.weak * share),
			("grabbed: %s; %d presses gave %d ticks; the last, at a headway of %.3f, asks %.3f of the "
			+ "weak motor (%.3f: Struggle at %.3f, above its Start Share, %.2f)") % [held, PRESSES,
			ticks.size(), headway, tick, pulses.struggle.weak * share, share,
			pulses.struggle_start_share])


## The crucifix raised with Crucifix held: its pulse, with the held vibration under it; once the pulse
## is over, the held one runs at its Start Share while more than Crucifix Warning Time is left, and
## it grows once less is left, to the share the time left gives. Letting Crucifix go lowers it and
## ends the held vibration. The case's held vibration is flat, so its level reads the same on every
## frame.
func _the_crucifix_held_up_holds_a_vibration_that_grows_as_it_runs_out() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var stats: RumbleStats = _flat_stats()
	scene.impacts.rumble_stats = stats
	var crucifix: Crucifix = scene.player.get_node(^"Crucifix") as Crucifix
	var input: StandInInput = put_a_stand_in(scene.player)
	var held: RumbleSustain = stats.crucifix_held
	var full: Vector2 = Vector2(held.weak, held.strong)
	await physics_frame
	input.crucifix_held = true
	var raised: bool = await wait_until(crucifix.is_raised)
	var at_raise: Vector2 = _asked_of(PAD)
	await _frames(_frames_of(stats.crucifix_raised))
	var held_up: Vector2 = _asked_of(PAD)
	var half_warning: float = crucifix.stats.warning_time * 0.5
	var near_the_end: bool = await wait_until(func() -> bool:
			return not crucifix.is_raised() or crucifix.get_use_time_left() <= half_warning)
	var time_left: float = crucifix.get_use_time_left()
	var growing: Vector2 = _asked_of(PAD)
	var wanted_growing: Vector2 = full * held.share_at(crucifix.get_warning_progress())
	input.crucifix_held = false
	await wait_frames(PRESS_DELAY_FRAMES)
	var lowered: Vector2 = _asked_of(PAD)
	var down: bool = not crucifix.is_raised()
	await _free_scene(scene)
	var raise_pulse: Vector2 = Vector2(stats.crucifix_raised.weak, stats.crucifix_raised.strong)
	return report(raised and at_raise.is_equal_approx(raise_pulse)
			and held_up.is_equal_approx(full * held.start_share) and near_the_end
			and growing.distance_to(wanted_growing) <= FRAME_TOLERANCE
			and growing.x > (full * held.start_share).x and down and lowered == Vector2.ZERO,
			("raised: %s, asking %s (%s); after its pulse %s (%s); with %.2f s left %s (%s, more than at "
			+ "the start); let go, it is down: %s, asking %s") % [raised, at_raise, raise_pulse,
			held_up, full * held.start_share, time_left, growing, wanted_growing, down, lowered])


## Walking into lethal spikes, he dies on them, and his death stabs: while Spike Death lasts, the
## weak motor runs at its level, above Death's, with the strong one at Death's; once it is over, Death
## runs alone, weaker on the weak motor than it was. The game's freeze at his death in brambles
## (#263) holds the stab too, so its time counts from the end of the freeze. A death without spikes,
## in the case of every moment, asks for Death alone.
func _his_death_on_spikes_stabs_first() -> bool:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.position = Vector2(START.x + SPIKES_FROM_START, 0.0)
	root.add_child(spikes)
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		spikes.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var pulses: RumbleStats = scene.impacts.rumble_stats
	var input: StandInInput = put_a_stand_in(scene.player)
	input.run_direction = 1.0
	var died: bool = await wait_until(scene.player.is_dead)
	var stabbed: Vector2 = _asked_of(PAD)
	# The brambles' hitstop slows the game first: the stab is timed from its end. Waited out for a
	# second at most, so a freeze that never ends fails the case instead of hanging the run.
	var bramble_death: Node = scene.player.get_node(^"BrambleDeath")
	for frame: int in Engine.physics_ticks_per_second:
		if not bramble_death.is_frozen():
			break
		await process_frame
	await _frames(_frames_of(pulses.spike_death))
	var after_stab: Vector2 = _asked_of(PAD)
	spikes.queue_free()
	await _free_scene(scene)
	var stab: Vector2 = Vector2(pulses.spike_death.weak, pulses.death.strong)
	var death_ratio: float = pulses.death.weak / pulses.death.strong
	return report(died and stabbed.is_equal_approx(stab) and after_stab.x < stabbed.x
			and after_stab.y > 0.0 and is_equal_approx(after_stab.x, after_stab.y * death_ratio),
			("he dies on the spikes: %s, asking %s (%s); once the stab is over %s, Death alone")
			% [died, stabbed, stab, after_stab])


## The stab needs his coming into lethal spikes and his death on the same physics frame, whichever
## is heard first. The spikes kill him as he comes in, so their death is heard first in the game; here
## the coming in is heard first, then he dies on that frame, and it stabs. A man killed by something
## else whose body comes into the spikes a frame later gets no stab.
func _a_stab_needs_the_spikes_and_his_death_on_one_frame() -> bool:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate() as LethalSpikes
	spikes.position = FAR_AWAY
	root.add_child(spikes)
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		spikes.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var pulses: RumbleStats = scene.impacts.rumble_stats
	var stab: Vector2 = Vector2(pulses.spike_death.weak, pulses.death.strong)
	await physics_frame
	var heard_first: bool = _call_handler(spikes.body_entered, scene.impacts, [scene.player])
	scene.player.die()
	var spikes_first: Vector2 = _asked_of(PAD)
	await _free_scene(scene)
	scene = await _spawn_scene(START)
	if scene == null:
		spikes.queue_free()
		await process_frame
		return report(false, "the player never landed the second time")
	await physics_frame
	scene.player.die()
	await physics_frame
	var heard_later: bool = _call_handler(spikes.body_entered, scene.impacts, [scene.player])
	var a_frame_later: Vector2 = _asked_of(PAD)
	spikes.queue_free()
	await _free_scene(scene)
	return report(heard_first and spikes_first.is_equal_approx(stab) and heard_later
			and a_frame_later.x < pulses.spike_death.weak - TOLERANCE,
			("coming into the spikes heard first, then his death on that frame: %s, asking %s (%s); "
			+ "killed by something else, his body coming into them a frame later: %s, asking %s "
			+ "(the weak motor below %.2f)") % [heard_first, spikes_first, stab, heard_later,
			a_frame_later, pulses.spike_death.weak])


## Two souls in the crucifix's light while it is down strike nothing; raised over them, the crucifix is
## struck once, on that frame, though both are in and are pushed for frames until they are out. A
## gate's unlocker coming into the light strikes nothing and opens nothing: it answers Interact, not
## the crucifix. Both souls put back in on one frame strike it once more, asking for Crucifix Struck over
## the held vibration, once the raise's pulse is over. The case's held vibration is flat.
func _something_coming_into_the_crucifix_s_light_knocks_once() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var stats: RumbleStats = _flat_stats()
	scene.impacts.rumble_stats = stats
	var crucifix: Crucifix = scene.player.get_node(^"Crucifix") as Crucifix
	var input: StandInInput = put_a_stand_in(scene.player)
	var souls: Array[Node2D] = [_add_soul(), _add_soul()]
	var unlocker: GateUnlocker = _add_unlocker()
	var strikes: Array[int] = [0]
	var knocks: Array[Vector2] = []
	crucifix.struck.connect(func() -> void:
			strikes[0] += 1
			knocks.append(_asked_of(PAD)))
	await physics_frame
	_put_in_the_light(souls, crucifix)
	await wait_frames(OVERLAP_FRAMES)
	var strikes_while_down: int = strikes[0]
	input.crucifix_held = true
	var raised: bool = await wait_until(crucifix.is_raised)
	var struck: bool = await wait_until(func() -> bool: return strikes[0] > 0)
	await wait_frames(OVERLAP_FRAMES)
	var strikes_as_raised: int = strikes[0]
	var pushed_out: bool = await wait_until(func() -> bool:
			return souls.all(func(soul: Node2D) -> bool:
					return (soul.global_position.distance_to(crucifix.global_position)
							> crucifix.stats.repel_radius + SOUL_RADIUS)))
	await _frames(_frames_of(stats.crucifix_raised))
	unlocker.global_position = crucifix.global_position + Vector2(INSIDE_THE_LIGHT, 0.0)
	await wait_frames(OVERLAP_FRAMES)
	var opened: bool = unlocker.is_activated()
	var strikes_with_the_unlocker: int = strikes[0]
	_put_in_the_light(souls, crucifix)
	var struck_again: bool = await wait_until(func() -> bool:
			return strikes[0] > strikes_with_the_unlocker)
	await wait_frames(OVERLAP_FRAMES)
	var strikes_put_back: int = strikes[0]
	for soul: Node2D in souls:
		soul.queue_free()
	_free_unlocker(unlocker)
	await _free_scene(scene)
	var knock: Vector2 = Vector2(stats.crucifix_struck.weak, stats.crucifix_struck.strong)
	var last_knock: Vector2 = knocks[-1] if not knocks.is_empty() else Vector2.ZERO
	return report(strikes_while_down == 0 and raised and struck and strikes_as_raised == 1
			and pushed_out and not opened and strikes_with_the_unlocker == 1 and struck_again
			and strikes_put_back == 2 and last_knock.is_equal_approx(knock),
			("two souls in its light while it is down strike it %d time(s) (0); raised over them: %s, "
			+ "struck: %s, %d time(s) (1); pushed out: %s; an unlocker in its light opens its gate (no): "
			+ "%s, with %d strike(s) in all (1); both put back in on one frame strike it again: %s, "
			+ "%d in all (2), asking %s (%s)") % [strikes_while_down, raised, struck,
			strikes_as_raised, pushed_out, opened, strikes_with_the_unlocker, struck_again,
			strikes_put_back, last_knock, knock])


## His death with the crucifix up leaves it up until the room starts over. Once Death is over, nothing
## the crucifix says vibrates: neither a soul coming into its light nor its use running out, though
## the crucifix says both.
func _after_his_death_the_crucifix_vibrates_nothing() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var pulses: RumbleStats = scene.impacts.rumble_stats
	var crucifix: Crucifix = scene.player.get_node(^"Crucifix") as Crucifix
	var use: CrucifixStats = crucifix.stats.duplicate() as CrucifixStats
	use.max_use_time = pulses.death.duration + AFTER_DEATH_TIME
	crucifix.stats = use
	var input: StandInInput = put_a_stand_in(scene.player)
	var soul: Node2D = _add_soul()
	var said: Array[int] = [0, 0]
	crucifix.struck.connect(func() -> void: said[0] += 1)
	crucifix.ran_out.connect(func() -> void: said[1] += 1)
	await physics_frame
	input.crucifix_held = true
	var raised: bool = await wait_until(crucifix.is_raised)
	scene.player.die()
	await _frames(_frames_of(pulses.death))
	var still_up: bool = crucifix.is_raised()
	var after_death: Vector2 = _asked_of(PAD)
	soul.global_position = crucifix.global_position + Vector2(INSIDE_THE_LIGHT, 0.0)
	var most: Vector2 = Vector2.ZERO
	for frame: int in ceili(AFTER_DEATH_TIME * Engine.physics_ticks_per_second) + END_MARGIN_FRAMES:
		await physics_frame
		most = most.max(_asked_of(PAD))
	soul.queue_free()
	await _free_scene(scene)
	return report(raised and still_up and after_death == Vector2.ZERO and said[0] > 0
			and said[1] == 1 and most == Vector2.ZERO,
			("raised: %s; dead, with Death over, the crucifix is still up: %s, asking %s; then it is "
			+ "struck %d time(s) and runs out %d time(s), asking at most %s (nothing)") % [raised,
			still_up, after_death, said[0], said[1], most])


## Held up until its use runs out, SHORT_USE_TIME here, the crucifix ends with Crucifix Ran Out in
## place of its held vibration: at the pulse's levels as it runs out, below them halfway through it,
## and nothing once it is over.
func _the_crucifix_running_out_fades_out() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var pulse: RumblePulse = scene.impacts.rumble_stats.crucifix_ran_out
	var crucifix: Crucifix = scene.player.get_node(^"Crucifix") as Crucifix
	var short_use: CrucifixStats = crucifix.stats.duplicate() as CrucifixStats
	short_use.max_use_time = SHORT_USE_TIME
	crucifix.stats = short_use
	var input: StandInInput = put_a_stand_in(scene.player)
	var at_end: Array[Vector2] = []
	crucifix.ran_out.connect(func() -> void: at_end.append(_asked_of(PAD)))
	await physics_frame
	input.crucifix_held = true
	var ran_out: bool = await wait_until(func() -> bool: return not at_end.is_empty())
	await _frames(roundi(pulse.duration * Engine.physics_ticks_per_second / 2.0))
	var halfway: Vector2 = _asked_of(PAD)
	await _frames(_frames_of(pulse))
	var over: Vector2 = _asked_of(PAD)
	await _free_scene(scene)
	var full: Vector2 = Vector2(pulse.weak, pulse.strong)
	var ended: Vector2 = at_end[0] if not at_end.is_empty() else Vector2.ZERO
	return report(ran_out and ended.is_equal_approx(full) and halfway.x > 0.0 and halfway.x < full.x
			and halfway.y < full.y and over == Vector2.ZERO,
			("ran out: %s, asking %s (%s); halfway through the pulse %s, below it; once it is over %s")
			% [ran_out, ended, full, halfway, over])


## His death with the crucifix still up ends its held vibration: once his death's pulse is over, the
## controller stops and the node goes idle, though the crucifix is up. Only the vibration's handler
## hears the death, so the crucifix stays up. The case's held vibration is flat.
func _his_death_with_the_crucifix_up_ends_its_held_vibration() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var stats: RumbleStats = _flat_stats()
	scene.impacts.rumble_stats = stats
	var crucifix: Crucifix = scene.player.get_node(^"Crucifix") as Crucifix
	var input: StandInInput = put_a_stand_in(scene.player)
	await physics_frame
	input.crucifix_held = true
	var raised: bool = await wait_until(crucifix.is_raised)
	await _frames(_frames_of(stats.crucifix_raised))
	var held_up: Vector2 = _asked_of(PAD)
	_call_handler(scene.player.died, scene.impacts, [])
	await _frames(_frames_of(stats.death))
	var after_death: Vector2 = _asked_of(PAD)
	var still_up: bool = crucifix.is_raised()
	var idle: bool = not scene.rumble.is_processing()
	await _free_scene(scene)
	return report(raised and held_up != Vector2.ZERO and still_up and after_death == Vector2.ZERO
			and idle,
			("raised: %s, held up asking %s; after his death's pulse, with the crucifix still up (%s): "
			+ "%s, with the node idle: %s") % [raised, held_up, still_up, after_death, idle])


## A real jump asks for the jump's tick as it leaves the floor, and its landing for the blend from
## Landing to Hard Landing by how hard PlayerSounds says it was, a share between 0 and 1. A fall from
## higher than Hard Land Height lands hard, asking for Hard Landing itself.
func _a_jump_and_each_landing_tick_by_how_far_he_fell() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var pulses: RumbleStats = scene.impacts.rumble_stats
	var sounds: PlayerSounds = scene.player.get_node(^"PlayerSounds") as PlayerSounds
	var asked: Dictionary[String, Vector2] = {}
	scene.player.jumped.connect(func(_late: int, _buffered: int) -> void:
			asked["jump"] = _asked_of(PAD))
	sounds.land_played.connect(func(hard: bool) -> void:
			asked["hard landing" if hard else "landing"] = _asked_of(PAD))
	var input: StandInInput = put_a_stand_in(scene.player)
	await physics_frame
	input.press_jump()
	var landed: bool = await wait_until(func() -> bool: return asked.has("landing"))
	var share: float = sounds.get_last_landing_share()
	var landing: RumblePulse = pulses.landing_at(share)
	var high: Vector2 = Vector2(START.x, -(sounds.hard_land_height + HARD_FALL_MARGIN))
	scene.player.global_position = high
	scene.player.velocity = Vector2.ZERO
	var landed_hard: bool = await wait_until(func() -> bool: return asked.has("hard landing"))
	await _free_scene(scene)
	var jump: Vector2 = Vector2(pulses.jump.weak, pulses.jump.strong)
	var hard: Vector2 = Vector2(pulses.hard_landing.weak, pulses.hard_landing.strong)
	return report(asked.get("jump", Vector2.ONE).is_equal_approx(jump) and landed and share > 0.0
			and share < 1.0
			and asked.get("landing", Vector2.ONE).is_equal_approx(Vector2(landing.weak, landing.strong))
			and landed_hard and asked.get("hard landing", Vector2.ONE).is_equal_approx(hard),
			("a jump asks %s (%s); its landing, %.2f of the way to a hard one, %s (%s); a fall from %.0f "
			+ "px up lands hard: %s, asking %s (%s)") % [asked.get("jump"), jump, share,
			asked.get("landing"), Vector2(landing.weak, landing.strong), -high.y, landed_hard,
			asked.get("hard landing"), hard])


## A jump under a low ceiling hits it once and asks for the head bump's tick. Pushed up into it on
## every frame, his head stays on it for frames in a row, and that is still one bump. Falling beside
## a wall while running into it gets him on it once and asks for the wall's tick.
func _his_head_on_a_ceiling_and_getting_on_a_wall_tick_once() -> bool:
	var scene: Scene = await _spawn_scene(START)
	if scene == null:
		return report(false, "the player never landed")
	var pulses: RumbleStats = scene.impacts.rumble_stats
	var height: float = body_size(scene.player).y
	var ceiling: StaticBody2D = make_platform(START.x - FLOOR_HALF_WIDTH, START.x + FLOOR_HALF_WIDTH,
			-(height + CEILING_GAP + PLATFORM_THICKNESS))
	var asked: Dictionary[String, Vector2] = {}
	var bumps: Array[int] = [0]
	var walls: Array[int] = [0]
	scene.player.head_bumped.connect(func() -> void:
			bumps[0] += 1
			if bumps[0] == 1:
				asked["head"] = _asked_of(PAD))
	scene.player.got_on_wall.connect(func() -> void:
			walls[0] += 1
			asked["wall"] = _asked_of(PAD))
	var input: StandInInput = put_a_stand_in(scene.player)
	await physics_frame
	input.press_jump()
	var bumped: bool = await wait_until(func() -> bool: return bumps[0] > 0)
	await wait_until_on_floor(scene.player)
	var one_jump_bumps: int = bumps[0]
	input.hold_jump = true
	input.press_jump()
	var frames_on_ceiling: int = 0
	for frame: int in PUSH_FRAMES:
		await physics_frame
		scene.player.velocity.y = -PUSH_UP_SPEED
		if scene.player.is_on_ceiling():
			frames_on_ceiling += 1
	input.hold_jump = false
	await wait_until_on_floor(scene.player)
	var pushed_bumps: int = bumps[0] - one_jump_bumps
	ceiling.queue_free()
	var wall_x: float = START.x + WALL_FROM_START
	var wall: StaticBody2D = make_wall(wall_x, wall_x + PLATFORM_THICKNESS, -WALL_HEIGHT)
	scene.player.global_position = Vector2(START.x, -IN_THE_AIR)
	scene.player.velocity = Vector2.ZERO
	input.run_direction = 1.0
	var on_wall: bool = await wait_until(func() -> bool: return walls[0] > 0)
	await wait_until_on_floor(scene.player)
	wall.queue_free()
	await _free_scene(scene)
	var head: Vector2 = Vector2(pulses.head_bump.weak, pulses.head_bump.strong)
	var wall_tick: Vector2 = Vector2(pulses.on_wall.weak, pulses.on_wall.strong)
	return report(bumped and one_jump_bumps == 1 and asked.get("head", Vector2.ONE).is_equal_approx(head)
			and frames_on_ceiling >= MIN_FRAMES_ON_CEILING and pushed_bumps == 1
			and on_wall and walls[0] == 1 and asked.get("wall", Vector2.ONE).is_equal_approx(wall_tick),
			("a jump under a ceiling hits it %d time(s) (1), asking %s (%s); pushed up into it, his "
			+ "head spends %d frames on it (%d or more) and bumps %d time(s) (1); falling into a wall "
			+ "gets him on it %d time(s) (1), asking %s (%s)") % [one_jump_bumps, asked.get("head"),
			head, frames_on_ceiling, MIN_FRAMES_ON_CEILING, pushed_bumps, walls[0], asked.get("wall"),
			wall_tick])


## A floor, the player standing on it at at and the game camera following him, with PAD in use and
## stopped; null if he never lands.
func _spawn_scene(at: Vector2) -> Scene:
	var scene: Scene = Scene.new()
	scene.floor_body = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	scene.player = await spawn_on_floor(at)
	if scene.player == null:
		scene.floor_body.queue_free()
		await process_frame
		return null
	Input.stop_joy_vibration(PAD)
	scene.camera = CAMERA_SCENE.instantiate() as GameCamera
	scene.camera.player = scene.player
	root.add_child(scene.camera)
	await process_frame
	_press_on(PAD)
	scene.impacts = scene.camera.get_node(^"ImpactFeedback") as ImpactFeedback
	scene.rumble = scene.camera.get_node(^"ControllerRumble") as ControllerRumble
	scene.rumble.stop()
	return scene


func _free_scene(scene: Scene) -> void:
	scene.rumble.stop()
	scene.camera.queue_free()
	scene.floor_body.queue_free()
	await remove_player(scene.player)


## The game's values, with the held vibrations flat, so their levels read the same on every frame.
## The loaded resource is left as it is: the copy takes new held vibrations.
func _flat_stats() -> RumbleStats:
	var stats: RumbleStats = RUMBLE_STATS.duplicate() as RumbleStats
	var grab_sink: RumbleSustain = RUMBLE_STATS.grab_sink
	var crucifix_held: RumbleSustain = RUMBLE_STATS.crucifix_held
	stats.grab_sink = RumbleSustain.new(grab_sink.weak, grab_sink.strong, grab_sink.start_share)
	stats.crucifix_held = RumbleSustain.new(crucifix_held.weak, crucifix_held.strong,
			crucifix_held.start_share)
	return stats


## What pulse asks of the strong motor over its time: its level by its duration, the fading part
## counting half, as it falls in a straight line. A slow motor answers to both, not to the top alone.
func _strong_motor_area(pulse: RumblePulse) -> float:
	return pulse.strong * pulse.duration * (1.0 - pulse.fade / 2.0)


## The frames pulse lasts, with a margin.
func _frames_of(pulse: RumblePulse) -> int:
	return ceili(pulse.duration * Engine.physics_ticks_per_second) + END_MARGIN_FRAMES


## What device is asked to vibrate with now, the weak motor in x and the strong one in y.
func _asked_of(device: int) -> Vector2:
	return Input.get_joy_vibration_strength(device)


## A press of a button no action uses on device, so it is the controller in use.
func _press_on(device: int) -> void:
	var press: InputEventJoypadButton = InputEventJoypadButton.new()
	press.device = device
	press.button_index = SPARE_BUTTON
	press.pressed = true
	root.push_input(press)
	var release: InputEventJoypadButton = press.duplicate() as InputEventJoypadButton
	release.pressed = false
	root.push_input(release)


## A lost soul's stand-in, far from everything: a Node2D with a Repellable of SOUL_RADIUS px that
## flies, so the crucifix pushes it straight away. The case frees it.
func _add_soul() -> Node2D:
	var soul: Node2D = Node2D.new()
	soul.position = FAR_AWAY
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = SOUL_RADIUS
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = circle
	var repellable: Repellable = REPELLABLE_SCENE.instantiate() as Repellable
	repellable.target = soul
	repellable.add_child(shape)
	soul.add_child(repellable)
	root.add_child(soul)
	return soul


## Puts every soul in the crucifix's light, on this frame.
func _put_in_the_light(souls: Array[Node2D], crucifix: Crucifix) -> void:
	for soul: Node2D in souls:
		soul.global_position = crucifix.global_position + Vector2(INSIDE_THE_LIGHT, 0.0)


## A gate's unlocker far from everything, with its gate further still. _free_unlocker() frees both.
func _add_unlocker() -> GateUnlocker:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = FAR_AWAY * 2.0
	root.add_child(gate)
	var gates: Array[Gate] = [gate]
	var unlocker: GateUnlocker = UNLOCKER_SCENE.instantiate() as GateUnlocker
	unlocker.gates = gates
	unlocker.position = FAR_AWAY
	root.add_child(unlocker)
	return unlocker


func _free_unlocker(unlocker: GateUnlocker) -> void:
	for gate: Gate in unlocker.gates:
		gate.queue_free()
	unlocker.queue_free()


## A bite on the man's left, still off, as in test_grab_escape.gd. The case frees it.
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


func _add_rock(at: Vector2) -> FallingRock:
	var rock: FallingRock = ROCK_SCENE.instantiate() as FallingRock
	rock.position = at
	root.add_child(rock)
	return rock


## Calls listener's handler of sent with args, as if sent had been emitted with them, without
## reaching sent's other listeners; false if listener does not listen to sent.
func _call_handler(sent: Signal, listener: Object, args: Array) -> bool:
	for connection: Dictionary in sent.get_connections():
		var handler: Callable = connection["callable"]
		if handler.get_object() == listener:
			handler.callv(args)
			return true
	return false


func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame


## What a case builds: the floor, the player, the camera and its impacts and vibration.
class Scene:
	var floor_body: StaticBody2D
	var player: Player
	var camera: GameCamera
	var impacts: ImpactFeedback
	var rumble: ControllerRumble
