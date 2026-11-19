# Checks the embers a passing gust carries across the screen. Each gust carries between the fewest
# and the most embers of Count; they come in just past the upwind edge of what the camera shows,
# at heights inside Height, and fly the way the gust travels, never turning back. Most cross the
# whole screen, quickly; they do not fly in a straight line, and not all at one height; and once
# the gust is over none is left and the node stops running. A sound of Layer blows a gust the way
# the sound travels, the pause holds the embers, and in level 1 the passing gusts' layer blows
# them.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wind_embers.gd
extends "res://tests/support/base_test.gd"

const EMBERS_PATH: String = "res://scenes/others/ambience/wind_embers.tscn"
const LAYER_PATH: String = "res://scenes/others/ambience/ambience_layer.tscn"
const LEVEL1_AMBIENCE_PATH: String = "res://scenes/levels/lust/lust_ambience.tscn"
## The game's viewport, which the headless window is set to, and a camera far from the origin.
const SCREEN_SIZE: Vector2i = Vector2i(1920, 1080)
const CAMERA_AT: Vector2 = Vector2(5000.0, -3000.0)
## The length of a frame with --fixed-fps 60, as in the command above.
const FRAME_TIME: float = 1.0 / 60.0
## Frames a gust is watched for: longer than the longest life of an ember, plus the last one's
## arrival.
const GUST_FRAMES: int = 360
## Gusts watched each way, so the checks see many embers.
const GUSTS_EACH_WAY: int = 4
## The seeds of the embers' randomness and of their curls, so a run repeats.
const RANDOM_SEED: int = 2026
## How far past the edge one can be by the first frame it is seen: two frames at the fastest gust
## and the biggest ember's share of it, in px.
const FIRST_FRAME_REACH: float = 2.0 * 2300.0 * 1.2 * FRAME_TIME
## Rounding room for the heights where they come in, in px: one frame's rise or settle.
const HEIGHT_TOLERANCE: float = 20.0
## The share of embers that must cross the whole screen, and the longest median time they may take,
## in s. Measured: all of them, in 0.8 to 2.1 s.
const MIN_CROSSING_SHARE: float = 0.8
const MAX_MEDIAN_CROSSING: float = 2.0
## Not a straight line: the median of how far each strays from the line between where it came in
## and where it left, in px (measured: about 55), and the share that end at least MIN_RISE_OR_FALL
## px higher or lower than they came in (measured: about 7 in 10).
const MIN_MEDIAN_BEND: float = 10.0
const MIN_RISE_OR_FALL: float = 20.0
const MIN_RISE_OR_FALL_SHARE: float = 0.4
## The layer's gaps, short, so it plays soon: in s.
const LAYER_GAP: Vector2 = Vector2(0.5, 0.6)
## Frames a gust takes to bring its first embers well onto the screen, and frames a paused one is
## watched for.
const ONTO_SCREEN_FRAMES: int = 30
const PAUSED_FRAMES: int = 30
## The silent sound the layer plays: its sample rate, in Hz, and its length, in s.
const SHORT_SOUND_RATE: int = 22050
const SHORT_SOUND_LENGTH: float = 0.1

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
	var results: Array[bool] = []
	results.append(await _gusts_carry_embers_across(1))
	results.append(await _gusts_carry_embers_across(-1))
	results.append(await _a_sound_of_the_layer_blows_a_gust_its_way())
	results.append(await _the_pause_holds_the_embers())
	results.append(_level1_passing_gusts_blow_the_embers())
	_camera.queue_free()
	await process_frame
	_finish(results)


## GUSTS_EACH_WAY gusts that travel as way says, each watched until it is over: how many embers,
## where they come in, which way they go, how many cross and how fast, how they bend, and that
## none is left after.
func _gusts_carry_embers_across(way: int) -> bool:
	var embers: WindEmbers = _new_embers()
	var screen: Rect2 = _screen_rect()
	var problems: Array[String] = []
	var bends: Array[float] = []
	var crossings: Array[float] = []
	var embers_seen: int = 0
	var risen_or_fallen: int = 0
	for gust: int in GUSTS_EACH_WAY:
		embers.blow(way)
		var tracks: Array = await _watch(embers, GUST_FRAMES)
		if tracks.size() < embers.count.x or tracks.size() > embers.count.y:
			problems.append("gust %d carried %d embers" % [gust, tracks.size()])
		if embers.is_blowing() or embers.is_processing():
			problems.append("gust %d still runs after %d frames" % [gust, GUST_FRAMES])
		for track: Array[Vector2] in tracks:
			embers_seen += 1
			problems.append_array(_entry_problems(track, screen, way, embers))
			problems.append_array(_backtrack_problems(track, way))
			var crossed: int = _crossing_frame(track, screen, way)
			if crossed >= 0:
				crossings.append(crossed * FRAME_TIME)
			bends.append(_bend(track))
			if absf(track[track.size() - 1].y - track[0].y) >= MIN_RISE_OR_FALL:
				risen_or_fallen += 1
	embers.queue_free()
	await process_frame
	var crossing_share: float = float(crossings.size()) / maxi(embers_seen, 1)
	var median_crossing: float = _median(crossings)
	var median_bend: float = _median(bends)
	var rise_share: float = float(risen_or_fallen) / maxi(embers_seen, 1)
	problems.resize(mini(problems.size(), 5))
	return _report(problems.is_empty() and crossing_share >= MIN_CROSSING_SHARE
			and median_crossing <= MAX_MEDIAN_CROSSING and median_bend >= MIN_MEDIAN_BEND
			and rise_share >= MIN_RISE_OR_FALL_SHARE,
			"gusts travelling %s carry their embers in from the upwind edge and across, never "
			% ("left to right" if way > 0 else "right to left")
			+ "back: %.0f%% cross, in %.2f s (median), bending %.0f px (median), %.0f%% end "
			% [crossing_share * 100.0, median_crossing, median_bend, rise_share * 100.0]
			+ "higher or lower, none left after (problems: %s)" % "; ".join(problems))


## A layer that plays an unpanned sound travelling right to left, with embers listening to it: the
## first sound blows a gust that way.
func _a_sound_of_the_layer_blows_a_gust_its_way() -> bool:
	var layer: AmbienceLayer = (load(LAYER_PATH) as PackedScene).instantiate() as AmbienceLayer
	layer.unpanned_sounds = _short_sound()
	layer.unpanned_travel = AmbienceLayer.Travel.RIGHT_TO_LEFT
	layer.min_gap = LAYER_GAP.x
	layer.max_gap = LAYER_GAP.y
	root.add_child(layer)
	var embers: WindEmbers = _new_embers(layer)
	var heard: Array[int] = []
	layer.sound_played.connect(func(_at: Vector2, travel: int) -> void: heard.append(travel))
	var frames: int = int(LAYER_GAP.y / FRAME_TIME) + ONTO_SCREEN_FRAMES * 2
	var tracks: Array = await _watch(embers, frames)
	layer.queue_free()
	embers.queue_free()
	await process_frame
	var leftwards: int = 0
	for track: Array[Vector2] in tracks:
		if track.size() > 1 and track[track.size() - 1].x < track[0].x:
			leftwards += 1
	return _report(not heard.is_empty() and heard[0] == -1 and not tracks.is_empty()
			and leftwards == tracks.size(),
			"a sound of the layer travelling right to left blows a gust that way (%d of %d embers)"
			% [leftwards, tracks.size()])


func _the_pause_holds_the_embers() -> bool:
	var embers: WindEmbers = _new_embers()
	embers.blow(1)
	await _wait_frames(ONTO_SCREEN_FRAMES)
	var before: PackedVector2Array = _flying(embers)
	paused = true
	await _wait_frames(PAUSED_FRAMES)
	var held: bool = not before.is_empty() and _flying(embers) == before
	paused = false
	await _wait_frames(2)
	var resumed: bool = _flying(embers) != before
	embers.queue_free()
	await process_frame
	return _report(held and resumed, "the pause holds the embers (%d flying), and they go on after "
			% before.size() + "it")


func _level1_passing_gusts_blow_the_embers() -> bool:
	var scene: PackedScene = load(LEVEL1_AMBIENCE_PATH) as PackedScene
	if scene == null:
		return _report(false, "%s loads as a scene" % LEVEL1_AMBIENCE_PATH)
	var ambience: Node = scene.instantiate()
	var embers := ambience.get_node_or_null(^"WindEmbers") as WindEmbers
	var passing: Node = ambience.get_node_or_null(^"PassingWind")
	var linked: bool = embers != null and passing != null and embers.wind_layer == passing
	ambience.queue_free()
	return _report(linked, "in level 1, the passing gusts' layer blows the wind embers")


## Embers in the tree, listening to layer if given, with their randomness seeded.
func _new_embers(layer: AmbienceLayer = null) -> WindEmbers:
	var embers: WindEmbers = _embers_scene.instantiate() as WindEmbers
	embers.wind_layer = layer
	root.add_child(embers)
	embers._rng.seed = RANDOM_SEED
	embers._noise.seed = RANDOM_SEED
	return embers


## Watches the embers for frames frames and gives each one's path, an Array[Vector2] with a place
## per frame, from the frame it was first seen to its last. Arrays, which are passed by reference,
## so each path grows where it is kept.
func _watch(embers: WindEmbers, frames: int) -> Array:
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
func _flying(embers: WindEmbers) -> PackedVector2Array:
	var places := PackedVector2Array()
	for index: int in embers._lives.size():
		if embers._lives[index] > 0.0:
			places.append(embers._positions[index])
	return places


## What is wrong with where an ember came in: just past the upwind edge, inside Height.
func _entry_problems(track: Array[Vector2], screen: Rect2, way: int,
		embers: WindEmbers) -> Array[String]:
	var first: Vector2 = track[0]
	var past_edge: float = (first.x - screen.position.x if way > 0 else screen.end.x - first.x)
	var down: float = first.y - screen.position.y
	var problems: Array[String] = []
	if past_edge > FIRST_FRAME_REACH or past_edge < -embers.entry_depth - FIRST_FRAME_REACH:
		problems.append("came in %.0f px past the upwind edge" % past_edge)
	if (down < embers.height.x * screen.size.y - HEIGHT_TOLERANCE
			or down > embers.height.y * screen.size.y + HEIGHT_TOLERANCE):
		problems.append("came in at %.2f of the height" % (down / screen.size.y))
	return problems


## A frame in which an ember went back against the gust, if any.
func _backtrack_problems(track: Array[Vector2], way: int) -> Array[String]:
	for index: int in range(1, track.size()):
		if (track[index].x - track[index - 1].x) * way < 0.0:
			return ["went back on frame %d" % index]
	return []


## The frame, counted from the ember's first, on which it was past the far edge, or -1.
func _crossing_frame(track: Array[Vector2], screen: Rect2, way: int) -> int:
	for index: int in track.size():
		if ((way > 0 and track[index].x > screen.end.x)
				or (way < 0 and track[index].x < screen.position.x)):
			return index
	return -1


## How far an ember strayed, at most, from the straight line between its first and last places.
func _bend(track: Array[Vector2]) -> float:
	var first: Vector2 = track[0]
	var along: Vector2 = (track[track.size() - 1] - first).normalized()
	var most: float = 0.0
	for at: Vector2 in track:
		most = maxf(most, absf(along.cross(at - first)))
	return most


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return INF
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


## What the camera shows, in the world.
func _screen_rect() -> Rect2:
	return root.get_canvas_transform().affine_inverse() * root.get_visible_rect()


func _wait_frames(frames: int) -> void:
	for _step: int in frames:
		await process_frame


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func _finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)


## A tenth of a second of silence, made in memory: the layer needs a sound to play, not to hear one.
func _short_sound() -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SHORT_SOUND_RATE
	var bytes := PackedByteArray()
	bytes.resize(int(SHORT_SOUND_RATE * SHORT_SOUND_LENGTH) * 2)
	sound.data = bytes
	return sound
