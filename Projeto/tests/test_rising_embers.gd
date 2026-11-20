# Checks the embers a fire throws up when it crackles. Each crackle throws between the fewest and
# the most of Count, from Emit Area round the fire, on the side the crackle is heard from. They all
# rise, at different speeds and not straight up: some lean left and some right, and none flies in
# a straight line. They go out within their life, a few seconds, and then none is left and the node
# stops running. A fire that is hidden throws none; the pause holds them; and a crackle of the
# fire's sound throws 4 or 5 from its side, coloured with the fire's own colours and outlined in its
# darkest, as the drawn flame is. Each burns with a bloom, added over it on a canvas of its own,
# that flickers and dims as it cools.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_rising_embers.gd
extends "res://tests/support/base_test.gd"

const EMBERS_PATH: String = "res://scenes/others/ambience/rising_embers.tscn"
const FIRE_SOUND_PATH: String = "res://scenes/others/ambience/fire_sound.tscn"
## How many embers each crackle of the fire's sound throws, the fewest and the most, as asked.
const FIRE_EMBERS: Vector2i = Vector2i(4, 5)
## The prototype's fire, whose colour ramp the flame is drawn through.
const ProtoFire := preload("res://scenes/levels/prototypes/lighting/proto_fire.gd")
## The game's viewport, which the headless window is set to, and a camera far from the origin.
const SCREEN_SIZE: Vector2i = Vector2i(1920, 1080)
const CAMERA_AT: Vector2 = Vector2(5000.0, -3000.0)
## Where the fire is, away from the camera and the origin.
const FIRE_AT: Vector2 = Vector2(4800.0, -2900.0)
## The length of a frame with --fixed-fps 60, as in the command above.
const FRAME_TIME: float = 1.0 / 60.0
## The seeds of the embers' randomness and of their curls, so a run repeats.
const RANDOM_SEED: int = 2026
## Crackles watched, a third from each side.
const CRACKLES: int = 18
const SIDES: Array[float] = [-1.0, 0.0, 1.0]
## Rounding room for where one is first seen: a frame's flight at the fastest leave, in px.
const FIRST_FRAME_REACH: float = 160.0 * FRAME_TIME + 1.0
## How much each must rise over its life, at least, in px (measured on 19/11: 71 to 262).
const MIN_RISE: float = 50.0
## Not straight up: the share that end at least MIN_LEAN px to one side (measured: about 9 in 10),
## with some to each side.
const MIN_LEAN: float = 15.0
const MIN_LEAN_SHARE: float = 0.4
## Not a straight line: the median of how far each strays from the line between where it was first
## and last seen, in px (measured: about 14).
const MIN_MEDIAN_BEND: float = 3.0
## At different speeds: the fastest rise over the slowest, at least, over the first half second
## (measured: about 2.8).
const MIN_SPEED_RATIO: float = 1.5
const SPEED_FRAMES: int = 30
## Frames the pause is held for, and frames to let them leave before it.
const PAUSED_FRAMES: int = 30
const LEAVE_FRAMES: int = 10
## Real ms the audio server takes to let go of a freed player's playback.
const RELEASE_MSEC: int = 200
## The bloom: how far its light must swing with the flicker over an ember's first second, as a share
## of its brightest, and frames to watch an ember's whole life for.
const MIN_BLOOM_SWING: float = 0.2
const BLOOM_LIFE_FRAMES: int = 200

var _embers_scene: PackedScene
var _camera: Camera2D


func _initialize() -> void:
	_embers_scene = load(EMBERS_PATH) as PackedScene
	if _embers_scene == null:
		_report(false, "%s loads as a scene" % EMBERS_PATH)
		_finish([false])
		return
	# Without a window, the root takes the game's viewport only after a frame (see the commands'
	# notes).
	await process_frame
	root.size = SCREEN_SIZE
	await process_frame
	_camera = Camera2D.new()
	# The project interpolates physics, which moves every Camera2D to the physics frame anyway.
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.position = CAMERA_AT
	root.add_child(_camera)
	_camera.make_current()
	await process_frame
	await process_frame
	seed(RANDOM_SEED)
	var results: Array[bool] = []
	results.append(await _crackles_throw_embers_that_rise_and_go_out())
	results.append(await _a_hidden_fire_throws_none())
	results.append(await _the_pause_holds_them())
	results.append(await _the_fire_sound_s_crackles_throw_them_from_their_side())
	results.append(_the_fire_s_embers_take_the_fire_s_colours())
	results.append(await _each_burns_with_a_bloom())
	_camera.queue_free()
	await process_frame
	_finish(results)


## CRACKLES crackles, each watched until its embers are out: how many, where they leave, how they
## rise, lean and bend, how fast, how long they last, and that none is left after.
func _crackles_throw_embers_that_rise_and_go_out() -> bool:
	var embers: RisingEmbers = _new_embers()
	var frames: int = int((embers.life.y + embers.stagger) / FRAME_TIME) + 10
	var problems: Array[String] = []
	var counts: Dictionary[int, int] = {}
	var rises: Array[float] = []
	var bends: Array[float] = []
	var speeds: Array[float] = []
	var leaning: int = 0
	var lefts: int = 0
	var rights: int = 0
	for crackle: int in CRACKLES:
		var side: float = SIDES[crackle % SIDES.size()]
		embers.throw(FIRE_AT, side)
		var tracks: Array = await _watch(embers, frames)
		counts[tracks.size()] = counts.get(tracks.size(), 0) + 1
		if tracks.size() < embers.count.x or tracks.size() > embers.count.y:
			problems.append("%d embers" % tracks.size())
		for track: Array[Vector2] in tracks:
			problems.append_array(_leave_problems(track[0], side, embers))
			if track.size() * FRAME_TIME > embers.life.y + FRAME_TIME:
				problems.append("lived %.2f s" % (track.size() * FRAME_TIME))
			var rise: float = track[0].y - track[track.size() - 1].y
			rises.append(rise)
			if rise < MIN_RISE:
				problems.append("rose %.0f px" % rise)
			var lean: float = track[track.size() - 1].x - track[0].x
			if absf(lean) >= MIN_LEAN:
				leaning += 1
				if lean < 0.0:
					lefts += 1
				else:
					rights += 1
			bends.append(_bend(track))
			var early: int = mini(SPEED_FRAMES, track.size() - 1)
			speeds.append((track[0].y - track[early].y) / maxf(early * FRAME_TIME, FRAME_TIME))
		if embers.is_burning() or embers.is_processing():
			problems.append("embers left after a crackle")
	embers.queue_free()
	bends.sort()
	rises.sort()
	var seen: int = rises.size()
	var median_bend: float = bends[seen / 2] if seen > 0 else 0.0
	var speed_ratio: float = speeds.max() / maxf(speeds.min(), 0.001) if seen > 0 else 0.0
	var lean_share: float = float(leaning) / maxf(seen, 1.0)
	return _report(problems.is_empty() and counts.has(embers.count.x) and counts.has(embers.count.y)
			and lean_share >= MIN_LEAN_SHARE and lefts > 0 and rights > 0
			and median_bend >= MIN_MEDIAN_BEND and speed_ratio >= MIN_SPEED_RATIO,
			"%d crackles throw %s embers each (by count), from their side of the flame; all rise "
			% [CRACKLES, counts] + "(%.0f to %.0f px), %.0f%% lean (%d left, %d right), bending "
			% [rises.front() if seen > 0 else 0.0, rises.back() if seen > 0 else 0.0,
			lean_share * 100.0, lefts, rights]
			+ "%.1f px (median), the fastest %.1f times the slowest; out within their life, none "
			% [median_bend, speed_ratio] + "left after (problems: %s)" % "; ".join(problems))


func _a_hidden_fire_throws_none() -> bool:
	var fire := Node2D.new()
	root.add_child(fire)
	var embers: RisingEmbers = _new_embers()
	embers.fade_with = fire
	fire.modulate.a = 0.0
	embers.throw(FIRE_AT, 0.0)
	await _wait_frames(LEAVE_FRAMES)
	var none_unseen: bool = not embers.is_burning()
	fire.modulate.a = 1.0
	fire.visible = false
	embers.throw(FIRE_AT, 0.0)
	await _wait_frames(LEAVE_FRAMES)
	var none_hidden: bool = not embers.is_burning()
	fire.visible = true
	embers.throw(FIRE_AT, 0.0)
	await _wait_frames(LEAVE_FRAMES)
	var some_seen: bool = embers.is_burning()
	embers.queue_free()
	fire.queue_free()
	return _report(none_unseen and none_hidden and some_seen,
			"a fire the man cannot see (%s), or hidden (%s), throws none; one he sees does (%s)"
			% [none_unseen, none_hidden, some_seen])


func _the_pause_holds_them() -> bool:
	var embers: RisingEmbers = _new_embers()
	embers.throw(FIRE_AT, 0.0)
	await _wait_frames(LEAVE_FRAMES)
	var before: PackedVector2Array = _flying(embers)
	paused = true
	await _wait_frames(PAUSED_FRAMES)
	var held: bool = not before.is_empty() and _flying(embers) == before
	paused = false
	await _wait_frames(LEAVE_FRAMES)
	var after: PackedVector2Array = _flying(embers)
	var moved: bool = after.size() == before.size() and after != before
	embers.queue_free()
	return _report(held and moved,
			"the pause holds the embers (%d flying), and they go on after it" % before.size())


## The fire's sound, at the centre of the screen, plays a crackle from each side: each throws
## FIRE_EMBERS of them, from that side of the flame.
func _the_fire_sound_s_crackles_throw_them_from_their_side() -> bool:
	var sound: SoundEmitter = (load(FIRE_SOUND_PATH) as PackedScene).instantiate() as SoundEmitter
	sound.position = _camera.get_screen_center_position()
	root.add_child(sound)
	var embers: RisingEmbers = sound.get_node(^"%RisingEmbers") as RisingEmbers
	embers._rng.seed = RANDOM_SEED
	await process_frame
	# No crackle of its own while it is watched.
	sound._time_left = INF
	var problems: Array[String] = []
	if embers.count != FIRE_EMBERS:
		problems.append("Count is %s" % embers.count)
	var thrown: Array[int] = []
	for side: float in [-1.0, 1.0]:
		var before: int = _flying(embers).size()
		sound.play_one_shot(side)
		await _wait_frames(LEAVE_FRAMES)
		var places: PackedVector2Array = _flying(embers)
		thrown.append(places.size() - before)
		if places.size() - before < FIRE_EMBERS.x or places.size() - before > FIRE_EMBERS.y:
			problems.append("%d from side %.0f" % [places.size() - before, side])
		for k: int in range(before, places.size()):
			var middle: float = sound.global_position.x + embers.emit_area.get_center().x
			if (places[k].x - middle) * side < -(LEAVE_FRAMES * FRAME_TIME * embers.speed.y):
				problems.append("one from side %.0f left from the other side" % side)
		await _wait_frames(int(embers.life.y / FRAME_TIME) + 10)
	sound.queue_free()
	# The audio server lets go of the crackles' playback on its next mix, in real time, while the
	# frames run unthrottled.
	var until: int = Time.get_ticks_msec() + RELEASE_MSEC
	while Time.get_ticks_msec() < until:
		await process_frame
	return _report(problems.is_empty(),
			"the fire's sound throws %s embers with each crackle (%d to %d), from its side (problems: %s)"
			% [thrown, FIRE_EMBERS.x, FIRE_EMBERS.y, "; ".join(problems)])


## Every colour of the fire's embers, by heat, is one of the fire's own ramp, and their outline is
## its darkest, the colour of the flame's drawn edge.
func _the_fire_s_embers_take_the_fire_s_colours() -> bool:
	var sound: SoundEmitter = (load(FIRE_SOUND_PATH) as PackedScene).instantiate() as SoundEmitter
	var embers: RisingEmbers = sound.get_node(^"%RisingEmbers") as RisingEmbers
	var fire_colours: PackedColorArray = ProtoFire.RAMP_COLORS
	var strangers: Array[String] = []
	if embers.heat_ramp == null:
		strangers.append("no ramp")
	else:
		for colour: Color in embers.heat_ramp.colors:
			if not _is_one_of(Color(colour, 1.0), fire_colours):
				strangers.append(str(colour))
	var outlined: bool = embers.outline_colour.is_equal_approx(fire_colours[0])
	sound.free()
	return _report(strangers.is_empty() and outlined,
			"the fire's embers take the fire's own colours (not the fire's: %s) and its darkest for "
			% ", ".join(strangers) + "their outline (%s)" % outlined)


## The bloom is drawn after the embers, added; over one ember's life its light flickers, and it is
## dimmer in the last third of its life, cooler, than in the first.
func _each_burns_with_a_bloom() -> bool:
	var embers: RisingEmbers = _new_embers()
	embers._flicker_rng.seed = RANDOM_SEED
	embers.throw(FIRE_AT, 0.0)
	await process_frame
	await process_frame
	var drawn_after: bool = (embers._glow != null and embers._glow.get_index() > embers._canvas.get_index()
			and embers._glow.material == EmberLook.light_material())
	var index: int = -1
	for k: int in embers._lives.size():
		if embers._lives[k] > 0.0:
			index = k
			break
	var lights: Array[float] = []
	if index >= 0:
		for _frame: int in BLOOM_LIFE_FRAMES:
			if embers._lives[index] <= 0.0:
				break
			lights.append(embers.get_bloom_light(index))
			await process_frame
	embers.queue_free()
	await process_frame
	if lights.size() < 30:
		return _report(false, "an ember burns long enough to watch its bloom (%d frames)" % lights.size())
	var first_second: Array[float] = lights.slice(0, 60)
	var swing: float = (first_second.max() - first_second.min()) / maxf(first_second.max(), 0.0001)
	var third: int = lights.size() / 3
	var early: float = _mean(lights.slice(0, third))
	var late: float = _mean(lights.slice(lights.size() - third))
	return _report(drawn_after and swing >= MIN_BLOOM_SWING and late < early,
			"each ember burns with a bloom drawn after them, added (%s), flickering " % drawn_after
			+ "(swings %.0f%% in its first second) and dimmer as it cools " % (swing * 100.0)
			+ "(%.3f in the first third of its life, %.3f in the last)" % [early, late])


func _mean(values: Array[float]) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / maxf(values.size(), 1.0)


func _is_one_of(colour: Color, colours: PackedColorArray) -> bool:
	for other: Color in colours:
		if colour.is_equal_approx(other):
			return true
	return false


func _new_embers() -> RisingEmbers:
	var embers: RisingEmbers = _embers_scene.instantiate() as RisingEmbers
	root.add_child(embers)
	embers._rng.seed = RANDOM_SEED
	embers._noise.seed = RANDOM_SEED
	return embers


## What is wrong with where an ember was first seen: inside Emit Area round the fire, on the
## crackle's half of it, give or take a frame's flight.
func _leave_problems(first: Vector2, side: float, embers: RisingEmbers) -> Array[String]:
	var area := Rect2(FIRE_AT + embers.emit_area.position, embers.emit_area.size)
	var problems: Array[String] = []
	if not area.grow(FIRST_FRAME_REACH).has_point(first):
		problems.append("left from %s, outside %s" % [first, area])
	var middle: float = area.get_center().x
	if side != 0.0 and (first.x - middle) * side < -FIRST_FRAME_REACH:
		problems.append("left from the far side of the flame (%.0f px from its middle)"
				% (first.x - middle))
	return problems


## How far a track strays, at most, from the line between where it was first and last seen.
func _bend(track: Array[Vector2]) -> float:
	var start: Vector2 = track[0]
	var end: Vector2 = track[track.size() - 1]
	var most: float = 0.0
	for at: Vector2 in track:
		most = maxf(most, at.distance_to(Geometry2D.get_closest_point_to_segment(at, start, end)))
	return most


## Watches the embers for frames frames and gives each one's path, an Array[Vector2] with a place
## per frame, from the frame it was first seen to its last.
func _watch(embers: RisingEmbers, frames: int) -> Array:
	var done: Array = []
	var flying: Dictionary = {}
	for _frame: int in frames:
		await process_frame
		for index: int in embers._lives.size():
			if embers._lives[index] > 0.0:
				if not flying.has(index):
					var track: Array[Vector2] = []
					flying[index] = track
				(flying[index] as Array).append(embers._positions[index])
			elif flying.has(index):
				done.append(flying[index])
				flying.erase(index)
	done.append_array(flying.values())
	return done


## Where the flying embers are, in the pool's order.
func _flying(embers: RisingEmbers) -> PackedVector2Array:
	var places := PackedVector2Array()
	for index: int in embers._lives.size():
		if embers._lives[index] > 0.0:
			places.append(embers._positions[index])
	return places


func _wait_frames(frames: int) -> void:
	for _step: int in frames:
		await process_frame


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func _finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)
