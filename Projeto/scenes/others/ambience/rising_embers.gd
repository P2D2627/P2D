class_name RisingEmbers
extends CanvasLayer

## Embers a fire throws up when it crackles: Count of them for each one-shot of Emitter, from the side
## of the flame the crackle is heard from. Each leaves at its own speed and angle off straight up,
## with the pop of the crackle, then the heat carries it on up, slower as it cools, while slow curls
## of turbulence (curl noise) swing it; it goes out within a few seconds.
## They look like the drawn flame's own sparks: small flat slivers with a dark outline, coloured by
## their heat through Heat Ramp (the fire's own colours, from a peach and pink when hot through
## magenta to a deep wine as they cool), burning down and tumbling as they rise. Drawn flat and
## unshaded, as the flame is, not as glowing dots like the gusts' embers (EmberLook), but burning:
## each has a little bloom, a soft glow added over it that flickers at its own pace and dims as it
## cools, and its colour flares a little hotter with the flicker.
## They fly in the world, on a canvas layer of their own that follows the camera (Follow Viewport),
## as the gusts' embers do: they are as bright as the flame, so the level's darkness (a
## CanvasModulate, which only darkens its own canvas) does not dim them, and they pass in front of
## the level. Fade With, if set, is the fire: the embers take its opacity, so a fire the man cannot
## see throws none that show. A fixed pool drawn in one pass: nothing is made while they fly, and
## nothing runs between crackles. It runs in its frame, so the pause holds it.

## The longest step the air takes, in s: a slow frame does not fling them.
const MAX_STEP: float = 0.1
## How long one takes to appear as it leaves: almost at once, as a spark does.
const APPEAR_TIME: float = 0.06
## Below this heat an ember is out and leaves the pool.
const OUT_HEAT: float = 0.04
## How long one takes to fade out at the end of its life, in s, so none pops out.
const FADE_TIME: float = 0.3
## The turbulence's noise: two octaves, each 2.5 times finer and 0.4 as strong, as the gusts'.
const CURL_OCTAVES: int = 2
const CURL_LACUNARITY: float = 2.5
const CURL_GAIN: float = 0.4
## The step the curl is measured over, as a share of Curl Size: small against the curls.
const CURL_STEP_SHARE: float = 0.1
## The bursts the pool keeps room for: a crackle comes about every 4 s and an ember lives 3 s at
## most, so seldom two at once; three for a short wait.
const BURSTS_IN_POOL: int = 3
## Below this opacity of Fade With, a crackle throws no embers.
const MIN_OPACITY: float = 0.01
## How far into Emit Area a crackle heard from one side throws them, at most: from that half of it,
## spread over a half's width.
const SIDE_SHARE: float = 0.25
## A sliver's shape, along its length: its tip this share ahead of its middle and its base this
## share behind; the tip leans to one side by up to Tip Lean of its width, so no two are alike.
const TIP_SHARE: float = 0.6
const BASE_SHARE: float = 0.4
const TIP_LEAN: float = 0.6

## The emitter whose one-shots throw the embers: each throws one burst, from its side.
@export var emitter: SoundEmitter
## What the embers take their opacity from, such as the fire: hidden, it throws none, and those
## flying hide with it. None, they always show.
@export var fade_with: CanvasItem

@export_group("Burst")
## How many embers a crackle throws, from the fewest (x) to the most (y).
@export var count: Vector2i = Vector2i(1, 2)
## Where they leave from, around the emitter, in px: the flame's body. A crackle heard from the left
## throws them from its left half, one from the right from its right half.
@export var emit_area: Rect2 = Rect2(-24.0, -90.0, 48.0, 40.0)
## Over how long after the crackle the others leave, in s.
@export_range(0.0, 1.0, 0.01, "suffix:s") var stagger: float = 0.12

@export_group("Flight")
## How fast each leaves, with the pop of the crackle, from the slowest (x) to the fastest (y), in
## px per s.
@export var speed: Vector2 = Vector2(70.0, 160.0)
## How far off straight up each leaves, at most, either way, in degrees.
@export_range(0.0, 90.0, 0.5) var spread: float = 25.0
## How much of the sideways speed it left with each keeps as it rises, so they fan out over the
## fire instead of lining up above it.
@export_range(0.0, 1.0, 0.01) var keep_sideways: float = 0.5
## How fast the heat carries one up at full heat, and how fast a cooled one settles, in px per s:
## it slows as it cools.
@export_range(0.0, 1000.0, 5.0, "suffix:px/s") var lift: float = 120.0
@export_range(0.0, 500.0, 5.0, "suffix:px/s") var settle: float = 10.0
## How long one takes to follow the air, from x to y, in s: long enough that the pop carries it a
## while.
@export var response: Vector2 = Vector2(0.4, 0.9)

@export_group("Air")
## How big the curls of turbulence are, in px.
@export_range(10.0, 1000.0, 5.0, "suffix:px") var curl_size: float = 140.0
## How strong the curls are, in px per s.
@export_range(0.0, 500.0, 1.0, "suffix:px/s") var curl_strength: float = 45.0
## How fast the curls change, in noise steps per s.
@export_range(0.0, 3.0, 0.01) var curl_drift: float = 0.3

@export_group("Look")
## Colour (rgb) and opacity (alpha) by heat, from out (0) to the hottest (1): the fire's own
## colours, set in the fire's scene; the gusts' (EmberLook's), made in code, if empty.
@export var heat_ramp: Gradient
## The dark edge round each sliver, as the drawn flame has, and its width in px.
@export var outline_colour: Color = Color(0.3, 0.05, 0.18)
@export_range(0.0, 6.0, 0.1, "suffix:px") var outline_width: float = 1.5
## How long each lives, from the shortest (x) to the longest (y), in s.
@export var life: Vector2 = Vector2(1.5, 3.0)
## How long each sliver is, from the smallest (x) to the biggest (y), in px; many are small.
@export var size: Vector2 = Vector2(7.0, 14.0)
## How wide each is, as a share of its length, from the thinnest (x) to the widest (y).
@export var thickness: Vector2 = Vector2(0.35, 0.55)
## How big one is as it goes out, as a share of its size: it burns down as it cools.
@export_range(0.0, 1.0, 0.01) var burnt_size: float = 0.4
## How far its tip leans off the way it leaves, at most, either way, in degrees.
@export_range(0.0, 90.0, 0.5) var tilt: float = 35.0
## How fast each tumbles, at most, either way, in degrees per s.
@export_range(0.0, 720.0, 5.0) var spin: float = 150.0
## How hot each leaves, from the coolest (x) to the hottest (y).
@export var start_heat: Vector2 = Vector2(0.75, 1.0)
## How fast each cools: its heat falls by e every this share of its life, from x to y.
@export var cooling: Vector2 = Vector2(0.6, 1.0)

@export_group("Bloom")
## How bright the glow round each is at its hottest, as an alpha, added over it; it dims as it
## cools. 0: none.
@export_range(0.0, 2.0, 0.01) var bloom_strength: float = 0.35
## How wide the glow is, as a multiple of the ember's length.
@export_range(0.5, 8.0, 0.05) var bloom_size: float = 2.6
## How deep the glow flickers, as a share of its brightness.
@export_range(0.0, 1.0, 0.01) var bloom_flicker: float = 0.55
## How deep a cooled one's flicker stays, as a share of Bloom Flicker.
@export_range(0.0, 1.0, 0.01) var cooled_flicker: float = 0.4
## How fast each flickers, from the slowest (x) to the fastest (y), in Hz.
@export var flicker_rate: Vector2 = Vector2(5.0, 11.0)
## How much hotter its colour flares with the flicker, as a share of its heat: never cooler than
## its heat.
@export_range(0.0, 0.5, 0.01) var shimmer: float = 0.12

## Drawn flat over what is behind, as the flame is, and unshaded, so the level's lights neither
## light nor shade them: one material for every fire.
static var _material: CanvasItemMaterial

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The flicker's own randomness, apart from the flight's, so the look never changes how they fly.
var _flicker_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## What the embers are drawn on, in the world's coordinates: the layer follows the camera. Their
## bloom is drawn after them, added, on a canvas of its own.
var _canvas: Node2D
var _glow: Node2D
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
## A sliver's corners, and the same closed for its outline, filled in for each one drawn.
var _corners: PackedVector2Array = PackedVector2Array()
var _edge: PackedVector2Array = PackedVector2Array()
## The embers still to leave: in how long, from where (the emitter, then) and from which side.
var _waits: PackedFloat32Array = PackedFloat32Array()
var _origins: PackedVector2Array = PackedVector2Array()
var _sides: PackedFloat32Array = PackedFloat32Array()
## Per ember, in the pool's order; a life of 0 marks a free place.
var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _ages: PackedFloat32Array = PackedFloat32Array()
var _lives: PackedFloat32Array = PackedFloat32Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _widths: PackedFloat32Array = PackedFloat32Array()
var _leans: PackedFloat32Array = PackedFloat32Array()
var _angles: PackedFloat32Array = PackedFloat32Array()
var _spins: PackedFloat32Array = PackedFloat32Array()
var _heats: PackedFloat32Array = PackedFloat32Array()
var _coolings: PackedFloat32Array = PackedFloat32Array()
var _responses: PackedFloat32Array = PackedFloat32Array()
var _sideways: PackedFloat32Array = PackedFloat32Array()
var _phases: PackedFloat32Array = PackedFloat32Array()
var _rates: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_canvas = Node2D.new()
	_canvas.name = "Canvas"
	_canvas.material = _material
	_canvas.draw.connect(_draw_embers)
	add_child(_canvas)
	_glow = Node2D.new()
	_glow.name = "Bloom"
	_glow.material = EmberLook.light_material()
	_glow.draw.connect(_draw_bloom)
	add_child(_glow)
	if heat_ramp == null:
		heat_ramp = EmberLook.blackbody_ramp()
	_corners.resize(3)
	_edge.resize(4)
	_rng.randomize()
	_flicker_rng.randomize()
	_noise.seed = _rng.randi()
	_noise.frequency = 1.0 / curl_size
	_noise.fractal_octaves = CURL_OCTAVES
	_noise.fractal_lacunarity = CURL_LACUNARITY
	_noise.fractal_gain = CURL_GAIN
	var places: int = maxi(count.x, count.y) * BURSTS_IN_POOL
	_positions.resize(places)
	_velocities.resize(places)
	_ages.resize(places)
	_lives.resize(places)
	_sizes.resize(places)
	_widths.resize(places)
	_leans.resize(places)
	_angles.resize(places)
	_spins.resize(places)
	_heats.resize(places)
	_coolings.resize(places)
	_responses.resize(places)
	_sideways.resize(places)
	_phases.resize(places)
	_rates.resize(places)
	set_process(false)
	if emitter != null:
		emitter.one_shot_played.connect(_on_emitter_one_shot_played)


func _process(delta: float) -> void:
	_step(minf(delta, MAX_STEP))
	_canvas.queue_redraw()
	_glow.queue_redraw()
	if _waits.is_empty() and not is_burning():
		set_process(false)


func _draw_embers() -> void:
	var opacity: float = _opacity()
	if opacity <= 0.0:
		return
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		var heat: float = _heat(index)
		var flicker: float = _flicker(index, heat)
		var colour: Color = heat_ramp.sample(minf(heat * (1.0 + shimmer * flicker), 1.0))
		var alpha: float = colour.a * _shown(index) * opacity
		if alpha <= 0.0:
			continue
		var burn: float = lerpf(burnt_size, 1.0, clampf(heat / _heats[index], 0.0, 1.0))
		var length: float = _sizes[index] * burn
		var width: float = _widths[index] * length
		_corners[0] = Vector2(length * TIP_SHARE, _leans[index] * width)
		_corners[1] = Vector2(-length * BASE_SHARE, -width * 0.5)
		_corners[2] = Vector2(-length * BASE_SHARE, width * 0.5)
		for k: int in 3:
			_edge[k] = _corners[k]
		_edge[3] = _corners[0]
		_canvas.draw_set_transform(_positions[index], _angles[index])
		_canvas.draw_colored_polygon(_corners, Color(colour, alpha))
		if outline_width > 0.0:
			_canvas.draw_polyline(_edge, Color(outline_colour, outline_colour.a * alpha), outline_width,
					true)
	_canvas.draw_set_transform(Vector2.ZERO)


## Each ember's bloom: a soft glow over it, as wide as Bloom Size of its length, as bright as Bloom
## Strength at its hottest, dimmer as it cools, flickering.
func _draw_bloom() -> void:
	var opacity: float = _opacity()
	if opacity <= 0.0 or bloom_strength <= 0.0:
		return
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		var light: float = get_bloom_light(index) * opacity
		if light <= 0.0:
			continue
		var heat: float = _heat(index)
		var length: float = _sizes[index] * lerpf(burnt_size, 1.0, clampf(heat / _heats[index], 0.0, 1.0))
		EmberLook.draw_glow(_glow, _positions[index], length * bloom_size, heat_ramp.sample(heat), light)


## How bright the bloom of ember index is now, as an alpha, before Fade With: Bloom Strength at its
## hottest, dimmer as it cools and as it fades out, flickering by Bloom Flicker. 0 for a free place.
func get_bloom_light(index: int) -> float:
	if _lives[index] <= 0.0:
		return 0.0
	var heat: float = _heat(index)
	return (bloom_strength * heat * _shown(index)
			* (1.0 - bloom_flicker * (1.0 - _flicker(index, heat))))


## How much of ember index shows by its age: it appears at once as it leaves and fades out at the
## end of its life.
func _shown(index: int) -> float:
	var appeared: float = minf(1.0, _ages[index] / APPEAR_TIME)
	return appeared * clampf((_lives[index] - _ages[index]) / FADE_TIME, 0.0, 1.0)


## The flicker of ember index now, from 0 to 1: two waves at its own pace and phase, shallower as it
## cools (as the gusts' embers flicker, EmberLook.flicker).
func _flicker(index: int, heat: float) -> float:
	return EmberLook.flicker(_phases[index], _time * _rates[index], heat, 1.0, cooled_flicker)


## Throws one burst from origin, the emitter's place, from side of the flame: -1 its left, 1 its
## right, 0 its middle. Nothing while Fade With is hidden.
func throw(origin: Vector2, side: float) -> void:
	if _opacity() < MIN_OPACITY:
		return
	var embers: int = _rng.randi_range(mini(count.x, count.y), maxi(count.x, count.y))
	for k: int in embers:
		_waits.append(0.0 if k == 0 else _rng.randf() * stagger)
		_origins.append(origin)
		_sides.append(clampf(side, -1.0, 1.0))
	set_process(true)


## Whether any ember is flying.
func is_burning() -> bool:
	for index: int in _lives.size():
		if _lives[index] > 0.0:
			return true
	return false


func _on_emitter_one_shot_played(at: Vector2, side: float) -> void:
	throw(at, side)


## One step of the air: the embers still to leave leave on time, and each flying one follows the
## heat's lift, what it keeps of its sideways speed and the curls, tumbles, and cools.
func _step(delta: float) -> void:
	_time += delta
	var k: int = 0
	while k < _waits.size():
		_waits[k] -= delta
		if _waits[k] <= 0.0:
			_launch(_free_place(), _origins[k], _sides[k])
			_waits.remove_at(k)
			_origins.remove_at(k)
			_sides.remove_at(k)
		else:
			k += 1
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		_ages[index] += delta
		var heat: float = _heat(index)
		if _ages[index] >= _lives[index] or heat < OUT_HEAT:
			_lives[index] = 0.0
			continue
		var at: Vector2 = _positions[index]
		var air: Vector2 = (Vector2(_sideways[index], settle - lift * heat)
				+ _curl(at) * curl_strength)
		var velocity: Vector2 = _velocities[index]
		velocity += (air - velocity) * (1.0 - exp(-delta / _responses[index]))
		_velocities[index] = velocity
		_positions[index] = at + velocity * delta
		_angles[index] += _spins[index] * delta


## Ember index leaves from Emit Area round origin, on side's half of it, at its own speed and angle,
## its tip leaning off the way it goes. Nothing when the pool is full (index -1).
func _launch(index: int, origin: Vector2, side: float) -> void:
	if index < 0:
		return
	_lives[index] = _rng.randf_range(life.x, life.y)
	# Sizes follow a power law, as the gusts': many small, few big.
	var power: float = _rng.randf()
	_sizes[index] = size.x * size.y / (size.y - power * (size.y - size.x))
	_widths[index] = _rng.randf_range(thickness.x, thickness.y)
	_leans[index] = _rng.randf_range(-TIP_LEAN, TIP_LEAN)
	_spins[index] = deg_to_rad(_rng.randf_range(-spin, spin))
	_responses[index] = _rng.randf_range(response.x, response.y)
	_ages[index] = 0.0
	_heats[index] = _rng.randf_range(start_heat.x, start_heat.y)
	_coolings[index] = _rng.randf_range(cooling.x, cooling.y)
	_phases[index] = _flicker_rng.randf() * TAU
	_rates[index] = _flicker_rng.randf_range(flicker_rate.x, flicker_rate.y)
	var across: float = clampf(0.5 + side * SIDE_SHARE + _rng.randf_range(-SIDE_SHARE, SIDE_SHARE),
			0.0, 1.0)
	_positions[index] = origin + emit_area.position + emit_area.size * Vector2(across, _rng.randf())
	var angle: float = deg_to_rad(_rng.randf_range(-spread, spread))
	var velocity: Vector2 = Vector2(sin(angle), -cos(angle)) * _rng.randf_range(speed.x, speed.y)
	_velocities[index] = velocity
	_sideways[index] = velocity.x * keep_sideways
	_angles[index] = velocity.angle() + deg_to_rad(_rng.randf_range(-tilt, tilt))


## How much of the embers shows: Fade With's opacity, or all without it.
func _opacity() -> float:
	if fade_with == null:
		return 1.0
	if not fade_with.is_visible_in_tree():
		return 0.0
	return clampf(fade_with.modulate.a, 0.0, 1.0)


## How hot ember index is now: it cools by e every Cooling share of its life.
func _heat(index: int) -> float:
	return _heats[index] * exp(-_ages[index] / (_coolings[index] * _lives[index]))


## The turbulence's air at a point, round 1 at its strongest: the curl of a noise that changes
## slowly, so it swings the embers without gathering them in one place.
func _curl(at: Vector2) -> Vector2:
	var step: float = curl_size * CURL_STEP_SHARE
	var depth: float = _time * curl_drift * curl_size
	var here: float = _noise.get_noise_3d(at.x, at.y, depth)
	var right: float = _noise.get_noise_3d(at.x + step, at.y, depth)
	var below: float = _noise.get_noise_3d(at.x, at.y + step, depth)
	return Vector2(below - here, here - right) * (curl_size / step)


## A free place in the pool, or -1 when every ember flies.
func _free_place() -> int:
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			return index
	return -1
