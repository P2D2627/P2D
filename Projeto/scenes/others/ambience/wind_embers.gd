class_name WindEmbers
extends CanvasLayer

## Embers a passing gust carries across the screen, as from fires out of sight. A sound of Wind
## Layer blows one gust, the way the sound travels: the embers come in on the side the wind comes from,
## at heights spread over the screen, a few at a time, and cross it in about a second, with the
## gust's rise, hold and fall. They do not fly in a straight line: each gust leans a little up or
## down, curls of turbulence (curl noise), carried along by the gust, swing them as they pass, hot
## ones rise and cooled ones settle, and the big ones, nearer the eye, cross faster. They look like
## the main menu's embers (MenuEmbers), with the glowing embers' look (EmberLook): a core
## coloured by its heat, which cools towards deep red and goes out, drawn as a streak as long as it
## moves while a film camera's shutter is open, with a faint halo, flickering as it tumbles.
## They fly in the world, round what the camera shows, on a canvas layer of their own that follows
## the camera (Follow Viewport), as the lighting prototype's rocks in front do: they give light, so
## the level's darkness (a CanvasModulate, which only darkens its own canvas) does not dim them, and
## they pass in front of the level. Layer 1 keeps them under the glow and the colour grade, which
## reach up to it. A fixed pool drawn in one pass: nothing is made while they fly, and nothing runs
## between gusts. It runs in its frame, so the pause holds it.

## The longest step the air takes, in s: a slow frame does not fling them.
const MAX_STEP: float = 0.1
## How long one takes to appear as it comes in: almost at once, and off the screen anyway.
const APPEAR_TIME: float = 0.06
## Below this heat an ember gives no light any more and leaves the pool.
const OUT_HEAT: float = 0.04
## How long one takes to fade out at the end of its life, in s, so none that still glows pops out.
const FADE_TIME: float = 0.3
## How far past the screen, beyond Entry Depth, one may fly before it leaves the pool, in px.
const MARGIN: float = 200.0
## The turbulence's noise: two octaves, each 2.5 times finer and 0.4 as strong, so the big curls
## carry small eddies, as the main menu's.
const CURL_OCTAVES: int = 2
const CURL_LACUNARITY: float = 2.5
const CURL_GAIN: float = 0.4
## The step the curl is measured over, as a share of Curl Size: small against the curls.
const CURL_STEP_SHARE: float = 0.1
## How much of the gust's travel carries the curls along: less than all, so an ember, which goes
## with the air, passes through them and swings, instead of riding one curl in a straight line.
const EDDY_CARRY: float = 0.6

## The ambience layer whose sounds blow the gusts: each sound blows one, the way it travels.
@export var wind_layer: AmbienceLayer

@export_group("Gust")
## How many embers a gust carries, from the fewest (x) to the most (y).
@export var count: Vector2i = Vector2i(6, 14)
## When the first ember comes in after the sound starts, in s.
@export_range(0.0, 3.0, 0.05, "suffix:s") var delay: float = 0.1
## Over how long after the first the others come in, in s.
@export_range(0.0, 3.0, 0.05, "suffix:s") var arrival: float = 0.7
## How fast the gust's air blows at its strongest, from the softest gust (x) to the strongest (y),
## in px per s.
@export var speed: Vector2 = Vector2(1500.0, 2300.0)
## How long the gust takes to blow at full, in s.
@export_range(0.0, 3.0, 0.05, "suffix:s") var rise_time: float = 0.35
## How long it blows at full, in s.
@export_range(0.0, 5.0, 0.05, "suffix:s") var hold_time: float = 0.9
## How long it then takes to die down, by e, in s.
@export_range(0.05, 5.0, 0.05, "suffix:s") var fall_time: float = 1.2
## How far a gust leans off the level, up or down, in degrees (one standard deviation).
@export_range(0.0, 30.0, 0.5) var lean: float = 5.0
## Where up and down they come in, from the highest (x) to the lowest (y), as shares of the
## screen's height from the top.
@export var height: Vector2 = Vector2(0.1, 0.9)
## How far outside the upwind edge they come in, at most, in px, so they never enter on one line.
@export_range(0.0, 600.0, 5.0, "suffix:px") var entry_depth: float = 120.0
## How fast each crosses, as a share of the gust's air, from the smallest ember (x), far off, to the
## biggest (y), near the eye.
@export var depth_speed: Vector2 = Vector2(0.8, 1.2)

@export_group("Air")
## How big the curls of turbulence are, in px.
@export_range(20.0, 2000.0, 5.0, "suffix:px") var curl_size: float = 260.0
## How strong the curls are, as a share of the gust's air.
@export_range(0.0, 1.0, 0.01) var curl_strength: float = 0.12
## How fast the curls change, in noise steps per s.
@export_range(0.0, 3.0, 0.01) var curl_drift: float = 0.4
## How long one takes to follow the air, from the smallest ember (x) to the biggest (y), in s.
@export var response: Vector2 = Vector2(0.05, 0.15)
## How fast a cooled ember settles through the air, and how fast one at full heat rises, in px per
## s: a hot one rises, and sinks as it cools.
@export_range(0.0, 1000.0, 5.0, "suffix:px/s") var settle: float = 120.0
@export_range(0.0, 1000.0, 5.0, "suffix:px/s") var lift: float = 220.0

@export_group("Glow")
## Colour (rgb) and brightness (alpha) by heat, from out (0) to the hottest (1); the main menu's,
## made in code, if empty.
@export var heat_ramp: Gradient
## How long each lives, from the shortest (x) to the longest (y), in s.
@export var life: Vector2 = Vector2(2.0, 3.0)
## How big each core is, from the smallest (x) to the biggest (y), in px; many are small.
@export var core_size: Vector2 = Vector2(3.0, 7.0)
## How hot each comes in, from the coolest (x) to the hottest (y): they have flown a while.
@export var start_heat: Vector2 = Vector2(0.7, 1.0)
## How fast each cools: its heat falls by e every this share of its life, from x to y.
@export var cooling: Vector2 = Vector2(0.6, 1.0)
## The brightest one gets, as an alpha.
@export_range(0.0, 3.0, 0.01) var brightness: float = 1.8
## How deep the flicker is, as a share of the brightness.
@export_range(0.0, 1.0, 0.01) var flicker_depth: float = 0.4
## How deep a cooled red one's flicker stays, as a share of Flicker Depth.
@export_range(0.0, 1.0, 0.01) var cooled_flicker: float = 0.3
## How fast each flickers, from the slowest (x) to the fastest (y), in Hz.
@export var flicker_rate: Vector2 = Vector2(6.0, 12.0)
## How bright a halo is, as a share of its core.
@export_range(0.0, 1.0, 0.01) var halo_share: float = 0.2
## How long a film camera's shutter stays open, in s: a streak is as long as it moves in it. Shorter
## than the main menu's (1/48 s), whose embers are slow: at a gust's speed a long streak spreads one
## so thin it vanishes.
@export_range(0.0, 0.1, 0.001, "suffix:s") var shutter: float = 1.0 / 96.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## What the embers are drawn on, in the world's coordinates: the layer follows the camera.
var _canvas: Node2D
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
## The gust blowing now: how long since it began, which way (a unit vector), how fast at its
## strongest, how far its air has carried the curls, and when, in its age, each ember still to come
## comes in.
var _gust_age: float = 0.0
var _gust_direction: Vector2 = Vector2.RIGHT
var _gust_speed: float = 0.0
var _gust_travelled: Vector2 = Vector2.ZERO
var _arrivals: PackedFloat32Array = PackedFloat32Array()
## Per ember, in the pool's order; a life of 0 marks a free place.
var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _ages: PackedFloat32Array = PackedFloat32Array()
var _lives: PackedFloat32Array = PackedFloat32Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _heats: PackedFloat32Array = PackedFloat32Array()
var _coolings: PackedFloat32Array = PackedFloat32Array()
var _responses: PackedFloat32Array = PackedFloat32Array()
var _speed_shares: PackedFloat32Array = PackedFloat32Array()
var _phases: PackedFloat32Array = PackedFloat32Array()
var _rates: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_canvas = Node2D.new()
	_canvas.name = "Canvas"
	_canvas.material = EmberLook.light_material()
	_canvas.draw.connect(_draw_embers)
	add_child(_canvas)
	if heat_ramp == null:
		heat_ramp = EmberLook.blackbody_ramp()
	_rng.randomize()
	_noise.seed = _rng.randi()
	_noise.frequency = 1.0 / curl_size
	_noise.fractal_octaves = CURL_OCTAVES
	_noise.fractal_lacunarity = CURL_LACUNARITY
	_noise.fractal_gain = CURL_GAIN
	# Room for two gusts' worth, should a gust blow before the last one's embers are gone.
	var places: int = maxi(count.x, count.y) * 2
	_positions.resize(places)
	_velocities.resize(places)
	_ages.resize(places)
	_lives.resize(places)
	_sizes.resize(places)
	_heats.resize(places)
	_coolings.resize(places)
	_responses.resize(places)
	_speed_shares.resize(places)
	_phases.resize(places)
	_rates.resize(places)
	set_process(false)
	if wind_layer != null:
		wind_layer.sound_played.connect(_on_wind_layer_sound_played)


func _process(delta: float) -> void:
	_step(minf(delta, MAX_STEP))
	_canvas.queue_redraw()
	if _arrivals.is_empty() and not is_blowing():
		set_process(false)


func _draw_embers() -> void:
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		var heat: float = _heat(index)
		var colour: Color = heat_ramp.sample(heat)
		var appeared: float = minf(1.0, _ages[index] / APPEAR_TIME)
		var left: float = clampf((_lives[index] - _ages[index]) / FADE_TIME, 0.0, 1.0)
		var light: float = colour.a * brightness * appeared * left * _flicker(index, heat)
		EmberLook.draw(_canvas, _positions[index], _velocities[index], _sizes[index], colour, light,
				halo_share, shutter)


## Blows a gust across the screen, travelling as travel says: 1 from left to right, -1 from right
## to left, 0 either, at random. A gust still blowing gives way to it, and its embers ride the new
## one.
func blow(travel: int) -> void:
	var way: float = signf(travel)
	if way == 0.0:
		way = 1.0 if _rng.randf() < 0.5 else -1.0
	var angle: float = deg_to_rad(_rng.randfn(0.0, lean))
	_gust_direction = Vector2(cos(angle) * way, sin(angle))
	_gust_speed = _rng.randf_range(minf(speed.x, speed.y), maxf(speed.x, speed.y))
	_gust_age = 0.0
	_arrivals.clear()
	for _i: int in _rng.randi_range(mini(count.x, count.y), maxi(count.x, count.y)):
		_arrivals.append(delay + _rng.randf() * arrival)
	_arrivals.sort()
	set_process(true)


## Whether any ember is flying.
func is_blowing() -> bool:
	for index: int in _lives.size():
		if _lives[index] > 0.0:
			return true
	return false


func _on_wind_layer_sound_played(_position: Vector2, travel: int) -> void:
	blow(travel)


## One step of the air: the gust's embers come in on time, and each flying one follows the gust and
## the curls, rises or settles by its heat, and cools.
func _step(delta: float) -> void:
	_time += delta
	_gust_age += delta
	var air_speed: float = _gust_speed * _gust_strength()
	_gust_travelled += _gust_direction * air_speed * delta
	var screen: Rect2 = _screen_rect()
	while not _arrivals.is_empty() and _arrivals[0] <= _gust_age:
		_arrivals.remove_at(0)
		_launch(_free_place(), screen, air_speed)
	var room: Rect2 = screen.grow(entry_depth + MARGIN)
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		_ages[index] += delta
		var at: Vector2 = _positions[index]
		var heat: float = _heat(index)
		if _ages[index] >= _lives[index] or heat < OUT_HEAT or not room.has_point(at):
			_lives[index] = 0.0
			continue
		var air: Vector2 = (_gust_direction * air_speed * _speed_shares[index]
				+ _curl(at) * curl_strength * air_speed
				+ Vector2(0.0, settle - lift * heat))
		var velocity: Vector2 = _velocities[index]
		velocity += (air - velocity) * (1.0 - exp(-delta / _responses[index]))
		_velocities[index] = velocity
		_positions[index] = at + velocity * delta


## Ember index comes in past the upwind edge of screen, already moving with the gust's air.
## Nothing when the pool is full (index -1).
func _launch(index: int, screen: Rect2, air_speed: float) -> void:
	if index < 0:
		return
	_lives[index] = _rng.randf_range(life.x, life.y)
	# Sizes follow a power law, as the main menu's: many tiny, few big.
	var power: float = _rng.randf()
	_sizes[index] = core_size.x * core_size.y / (core_size.y - power * (core_size.y - core_size.x))
	var big: float = 0.0
	if core_size.y > core_size.x:
		big = (_sizes[index] - core_size.x) / (core_size.y - core_size.x)
	_responses[index] = lerpf(response.x, response.y, big)
	_speed_shares[index] = lerpf(depth_speed.x, depth_speed.y, big)
	_ages[index] = 0.0
	_heats[index] = _rng.randf_range(start_heat.x, start_heat.y)
	_coolings[index] = _rng.randf_range(cooling.x, cooling.y)
	_phases[index] = _rng.randf() * TAU
	_rates[index] = _rng.randf_range(flicker_rate.x, flicker_rate.y)
	var outside: float = _rng.randf_range(0.0, entry_depth)
	var x: float = (screen.position.x - outside if _gust_direction.x > 0.0
			else screen.end.x + outside)
	var y: float = screen.position.y + _rng.randf_range(height.x, height.y) * screen.size.y
	_positions[index] = Vector2(x, y)
	_velocities[index] = _gust_direction * air_speed * _speed_shares[index]


## How strongly the gust blows now, from 0 to 1: it rises over Rise Time, holds for Hold Time and
## dies down by e every Fall Time.
func _gust_strength() -> float:
	if _gust_age < rise_time:
		return smoothstep(0.0, rise_time, _gust_age)
	var after: float = _gust_age - rise_time - hold_time
	if after <= 0.0:
		return 1.0
	return exp(-after / fall_time)


## What the camera shows, in the world.
func _screen_rect() -> Rect2:
	var viewport: Viewport = get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()


## How hot ember index is now: it cools by e every Cooling share of its life.
func _heat(index: int) -> float:
	return _heats[index] * exp(-_ages[index] / (_coolings[index] * _lives[index]))


## The tumble's flicker, as a share of the brightness, at the ember's own pace and phase.
func _flicker(index: int, heat: float) -> float:
	return EmberLook.flicker(_phases[index], _time * _rates[index], heat, flicker_depth,
			cooled_flicker)


## The turbulence's air at a point, round 1 at its strongest: the curl of a noise the gust carries
## along and that changes slowly, so it swings the embers without gathering them in one place.
func _curl(at: Vector2) -> Vector2:
	var step: float = curl_size * CURL_STEP_SHARE
	var from: Vector2 = at - _gust_travelled * EDDY_CARRY
	var depth: float = _time * curl_drift * curl_size
	var here: float = _noise.get_noise_3d(from.x, from.y, depth)
	var right: float = _noise.get_noise_3d(from.x + step, from.y, depth)
	var below: float = _noise.get_noise_3d(from.x, from.y + step, depth)
	return Vector2(below - here, here - right) * (curl_size / step)


## A free place in the pool, or -1 when every ember flies.
func _free_place() -> int:
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			return index
	return -1
