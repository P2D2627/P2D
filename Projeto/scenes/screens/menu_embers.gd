class_name MenuEmbers
extends Control

## Embers from the fire below the bottom left of the menu, as a wood fire throws them. They leave it
## fast, at an angle round the upright, and slow down as they rise in its plume, whose air rises
## slower higher up and only near the fire; curls of turbulence that all of them share (curl noise)
## turn them, and those that leave the plume sink. They come steadily and in bursts, as wood
## cracks. Each cools from a saturated core through orange to deep red and goes out (Heat Ramp),
## flickering as it tumbles and flaring now and then; a spark is drawn as a short streak, as long as
## it moves while a film camera's shutter is open, with a faint halo. Look sets what a layer is:
## sparks, discs out of focus near the lens, or grey ash that tumbles and sinks, lit by the fire. The
## sizes follow a power law (many tiny, few big) and the lives lean short. A fixed pool drawn in one
## pass, so nothing is made while they fly; the air is full from the first frame.

enum Look { SPARK, BOKEH, ASH }

## How long the air is run before the first frame, so it starts full, and in what steps.
const PREWARM_TIME: float = 3.0
const PREWARM_STEP: float = 1.0 / 30.0
## How long one takes to appear as it leaves the fire: almost at once, so none pops in.
const APPEAR_TIME: float = 0.06
## Below this heat an ember gives no light any more and leaves the pool.
const OUT_HEAT: float = 0.04
## A halo's size, as a multiple of its core.
const HALO_SIZE: float = 4.0
## How far past the edges one may fly before it leaves the pool, in px.
const MARGIN: float = 60.0
## The longest step the air takes, in s: a slow frame does not fling them.
const MAX_STEP: float = 0.1
## The turbulence's noise: two octaves, each 2.5 times finer and 0.4 as strong, so the big curls
## carry small eddies.
const CURL_OCTAVES: int = 2
const CURL_LACUNARITY: float = 2.5
const CURL_GAIN: float = 0.4
## The step the curl is measured over, as a share of Curl Size: small against the curls.
const CURL_STEP_SHARE: float = 0.1
## The brightest the flame counts for: the backdrop's waver stays under it.
const MAX_FIRE_LEVEL: float = 1.5
## How far below the bottom edge one may leave the fire, in px, so they never start on one line.
const LAUNCH_DEPTH: float = 20.0
## How thin a flake of ash gets as it turns edge on, as a share of its width.
const ASH_EDGE_ON: float = 0.25
## The flicker's second wave runs at these shares of the first's phase and pace: not whole numbers,
## so the two never fall into step.
const SECOND_WAVE_PHASE: float = 1.7
const SECOND_WAVE_PACE: float = 0.63
## The heats over which the flicker deepens, from a cooled red (x) to a hot ember (y).
const FLICKER_HEAT: Vector2 = Vector2(0.1, 0.4)
## The wait for a burst stays within these multiples of Burst Every.
const BURST_WAIT_LIMITS: Vector2 = Vector2(0.5, 2.0)
## The dots' texture size, in px.
const DOT_SIZE: int = 64
## How far out from its heart each look's dot stays solid before it fades, as a share of its radius;
## a spark's halo fades from its heart.
const SOLID_SHARE: Dictionary[Look, float] = {Look.SPARK: 0.35, Look.BOKEH: 0.8, Look.ASH: 0.6}

@export var look: Look = Look.SPARK
## How many fly at once, on average; bursts add more for a moment.
@export_range(0, 300) var count: int = 60
## How long each lives, from the shortest (x) to the longest (y), in s; most live short.
@export var life: Vector2 = Vector2(0.8, 2.2)
## How big each core is, from the smallest (x) to the biggest (y), in px: a disc's width for Bokeh.
@export var core_size: Vector2 = Vector2(1.2, 3.0)
## Where across the bottom edge the fire is, as a share of the width (Ash: how far right it drifts).
@export_range(0.0, 1.0, 0.01) var fire_at: float = 0.15
## How wide the fire's mouth is, where they leave it, as a share of Plume Width (one standard
## deviation).
@export_range(0.0, 2.0, 0.05) var fire_width: float = 0.6

@export_group("Air")
## How fast the plume's air rises at the fire, in px per s.
@export_range(0.0, 1500.0, 5.0, "suffix:px/s") var plume_speed: float = 260.0
## Over what height the plume's air slows: it rises at Plume Speed × (1 + height / this)^(−1/3).
@export_range(10.0, 2000.0, 5.0, "suffix:px") var plume_height: float = 250.0
## How wide the plume is round the fire, as a share of the width (one standard deviation).
@export_range(0.01, 0.5, 0.01) var plume_width: float = 0.1
## How big the curls of turbulence are, in px.
@export_range(20.0, 1000.0, 5.0, "suffix:px") var curl_size: float = 220.0
## How strong the curls are, as a share of Plume Speed.
@export_range(0.0, 1.5, 0.01) var curl_strength: float = 0.45
## How strong the curls are out of the plume, as a share of their strength in it.
@export_range(0.0, 1.0, 0.01) var curl_outside: float = 0.35
## How fast the curls change, in noise steps per s.
@export_range(0.0, 2.0, 0.01) var curl_drift: float = 0.15
## How long one takes to follow the air, from the smallest ember (x) to the biggest (y), in s.
@export var response: Vector2 = Vector2(0.05, 0.12)
## How hard one is pulled down, in px per s²: those that leave the plume sink.
@export_range(0.0, 400.0, 1.0) var sink: float = 60.0
## How far off the upright they leave the fire, in degrees (one standard deviation).
@export_range(0.0, 90.0, 1.0) var spread: float = 33.0
## How fast they leave the fire, as a share of Plume Speed, from the slowest (x) to the fastest (y):
## faster than the air, which then slows them, so they streak as they leave and drift higher up.
@export var launch: Vector2 = Vector2(1.0, 2.2)

@export_group("Bursts")
## The time between bursts, on average, in s; each wait is drawn at random round it.
@export_range(0.5, 30.0, 0.5, "suffix:s") var burst_every: float = 4.0
## How many leave the fire in a burst, from the fewest (x) to the most (y); 0 for none.
@export var burst_size: Vector2i = Vector2i(12, 40)
## How much faster a burst throws them, as a multiple of a steady launch.
@export_range(1.0, 3.0, 0.05) var burst_speed: float = 1.7
## How far round the burst's point they leave the fire, in px (one standard deviation).
@export_range(0.0, 60.0, 1.0, "suffix:px") var burst_scatter: float = 8.0

@export_group("Glow")
## Colour (rgb) and brightness (alpha) by heat, from out (0) to the hottest (1); made in code if
## empty. Ash ignores it.
@export var heat_ramp: Gradient
## How hot each leaves the fire, from the coolest (x) to the hottest (y); bursts leave the hottest.
@export var start_heat: Vector2 = Vector2(0.55, 1.0)
## How fast each cools: its heat falls by e every this share of its life, from x to y.
@export var cooling: Vector2 = Vector2(0.35, 0.6)
## The brightest one gets, as an alpha; a disc out of focus is faint.
@export_range(0.0, 2.0, 0.01) var brightness: float = 1.0
## How deep the flicker is, as a share of the brightness.
@export_range(0.0, 1.0, 0.01) var flicker_depth: float = 0.4
## How deep a cooled red one's flicker stays, as a share of Flicker Depth: flashes count saturated
## red apart, so it flickers less.
@export_range(0.0, 1.0, 0.01) var cooled_flicker: float = 0.3
## How fast each flickers, from the slowest (x) to the fastest (y), in Hz.
@export var flicker_rate: Vector2 = Vector2(5.0, 12.0)
## How often one flares, per s, at a launch's speed; faster ones flare more.
@export_range(0.0, 3.0, 0.05) var flare_rate: float = 0.3
## How much brighter a flare is, as a multiple.
@export_range(1.0, 3.0, 0.05) var flare_gain: float = 1.45
## How long a flare lasts, from the shortest (x) to the longest (y), in s.
@export var flare_time: Vector2 = Vector2(0.06, 0.15)
## How bright a spark's halo is, as a share of its core.
@export_range(0.0, 1.0, 0.01) var halo_share: float = 0.13
## How long a film camera's shutter stays open, in s: a spark's streak is as long as it moves in it.
@export_range(0.0, 0.1, 0.001, "suffix:s") var shutter: float = 1.0 / 48.0
## Ash's colour in the dark; the fire lights it up to twice this.
@export var ash_color: Color = Color(0.35, 0.33, 0.31, 0.85)

@export_group("Ash")
## How far round the fire ash appears across, as a multiple of Plume Width (one standard deviation).
@export_range(0.0, 10.0, 0.1) var ash_spread: float = 3.0
## Where up and down ash appears, from the highest (x) to the lowest (y), as shares of the height
## from the top.
@export var ash_height: Vector2 = Vector2(0.3, 1.0)
## How fast ash drifts as it appears, at most, each way, in px per s.
@export_range(0.0, 100.0, 1.0, "suffix:px/s") var ash_drift: float = 10.0

## How bright the flame is now, round 1; the backdrop sets it each frame.
var fire_level: float = 1.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _noise: FastNoiseLite = FastNoiseLite.new()
var _core: GradientTexture2D
var _halo: GradientTexture2D
var _time: float = 0.0
var _emit_owed: float = 0.0
var _next_burst: float = 0.0
var _warm: bool = false
## Per ember, in the pool's order; a life of 0 marks a free place.
var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _ages: PackedFloat32Array = PackedFloat32Array()
var _lives: PackedFloat32Array = PackedFloat32Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _heats: PackedFloat32Array = PackedFloat32Array()
var _coolings: PackedFloat32Array = PackedFloat32Array()
var _responses: PackedFloat32Array = PackedFloat32Array()
var _phases: PackedFloat32Array = PackedFloat32Array()
var _rates: PackedFloat32Array = PackedFloat32Array()
var _flares_until: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = (CanvasItemMaterial.BLEND_MODE_MIX if look == Look.ASH
			else CanvasItemMaterial.BLEND_MODE_ADD)
	material = blend
	if heat_ramp == null:
		heat_ramp = _blackbody_ramp()
	_core = _dot(PackedFloat32Array([0.0, SOLID_SHARE[look], 1.0]), PackedFloat32Array([1.0, 1.0, 0.0]))
	if look == Look.SPARK:
		_halo = _dot(PackedFloat32Array([0.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	_rng.randomize()
	_noise.seed = _rng.randi()
	_noise.frequency = 1.0 / curl_size
	_noise.fractal_octaves = CURL_OCTAVES
	_noise.fractal_lacunarity = CURL_LACUNARITY
	_noise.fractal_gain = CURL_GAIN
	var places: int = count + maxi(burst_size.y, 0)
	_positions.resize(places)
	_velocities.resize(places)
	_ages.resize(places)
	_lives.resize(places)
	_sizes.resize(places)
	_heats.resize(places)
	_coolings.resize(places)
	_responses.resize(places)
	_phases.resize(places)
	_rates.resize(places)
	_flares_until.resize(places)
	_next_burst = _burst_wait()


## The air is run for a while before the first frame, once the layout has given the pool its size.
## Nothing runs while the menu is hidden: the pause's stays in the tree through the whole game.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if not _warm:
		if size.x <= 0.0:
			return
		_warm = true
		var warmed: float = 0.0
		while warmed < PREWARM_TIME:
			_step(PREWARM_STEP)
			warmed += PREWARM_STEP
	_step(minf(delta, MAX_STEP))
	queue_redraw()


func _draw() -> void:
	var glow: float = clampf(fire_level, 0.0, MAX_FIRE_LEVEL)
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		var at: Vector2 = _positions[index]
		var core: float = _sizes[index]
		var appeared: float = minf(1.0, _ages[index] / APPEAR_TIME)
		if look == Look.ASH:
			_draw_ash(index, at, core, appeared, glow)
			continue
		var heat: float = _heat(index)
		var colour: Color = heat_ramp.sample(heat)
		var light: float = colour.a * brightness * appeared * glow * _flicker(index, heat)
		if _time < _flares_until[index]:
			light *= flare_gain
		var tint: Color = Color(colour.r, colour.g, colour.b, 1.0)
		if look == Look.BOKEH:
			draw_set_transform(at)
			draw_texture_rect(_core, Rect2(Vector2(-core, -core) * 0.5, Vector2(core, core)), false,
					Color(tint, light))
			continue
		var velocity: Vector2 = _velocities[index]
		var streak: float = maxf(core, velocity.length() * shutter)
		var halo: float = core * HALO_SIZE
		draw_set_transform(at)
		draw_texture_rect(_halo, Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false,
				Color(tint, light * halo_share))
		# A streak spreads the same light along its length, so each of its pixels is dimmer: by the
		# square root of how much longer it is, not by all of it, or the fastest vanish on a screen.
		draw_set_transform(at, velocity.angle())
		draw_texture_rect(_core, Rect2(Vector2(-streak, -core) * 0.5, Vector2(streak, core)), false,
				Color(tint, light * sqrt(core / streak)))
	draw_set_transform(Vector2.ZERO)


## One step of the air: new embers leave the fire, steadily and in bursts, and each flying one
## follows the plume and the curls, sinks a little, cools and may flare.
func _step(delta: float) -> void:
	_time += delta
	_emit_owed += count / _mean_life() * delta
	while _emit_owed >= 1.0:
		_emit_owed -= 1.0
		_launch(_free_place(), _fire_x(), 1.0, false)
	if burst_size.y > 0 and _time >= _next_burst:
		_next_burst = _time + _burst_wait()
		var from_x: float = _fire_x()
		for _i: int in _rng.randi_range(burst_size.x, burst_size.y):
			_launch(_free_place(), from_x + _rng.randfn(0.0, burst_scatter), burst_speed, true)
	var fire_x: float = fire_at * size.x
	var plume_across: float = plume_width * size.x
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			continue
		_ages[index] += delta
		var at: Vector2 = _positions[index]
		if (_ages[index] >= _lives[index] or (look != Look.ASH and _heat(index) < OUT_HEAT)
				or at.x < -MARGIN or at.x > size.x + MARGIN or at.y < -MARGIN
				or at.y > size.y + MARGIN):
			_lives[index] = 0.0
			continue
		var across: float = (at.x - fire_x) / plume_across
		var in_plume: float = exp(-0.5 * across * across)
		var height: float = maxf(0.0, size.y - at.y)
		var rise: float = plume_speed * pow(1.0 + height / plume_height, -1.0 / 3.0) * in_plume
		var air: Vector2 = (Vector2(0.0, -rise)
				+ _curl(at) * curl_strength * plume_speed * lerpf(curl_outside, 1.0, in_plume))
		var velocity: Vector2 = _velocities[index]
		velocity += (air - velocity) * (1.0 - exp(-delta / _responses[index]))
		velocity.y += sink * delta
		_velocities[index] = velocity
		_positions[index] = at + velocity * delta
		if _rng.randf() < flare_rate * delta * velocity.length() / maxf(1.0, plume_speed):
			_flares_until[index] = _time + _rng.randf_range(flare_time.x, flare_time.y)


## Ember index leaves the fire at x (Ash: appears in the air round the fire), speed_gain times as
## fast as a steady one; a burst's leave the hottest. Nothing when the pool is full (index -1).
func _launch(index: int, x: float, speed_gain: float, hottest: bool) -> void:
	if index < 0:
		return
	var share: float = _rng.randf()
	_lives[index] = life.x + (life.y - life.x) * share * share
	var power: float = _rng.randf()
	_sizes[index] = core_size.x * core_size.y / (core_size.y - power * (core_size.y - core_size.x))
	var big: float = 0.0
	if core_size.y > core_size.x:
		big = (_sizes[index] - core_size.x) / (core_size.y - core_size.x)
	_responses[index] = lerpf(response.x, response.y, big)
	_ages[index] = 0.0
	_heats[index] = start_heat.y if hottest else _rng.randf_range(start_heat.x, start_heat.y)
	_coolings[index] = _rng.randf_range(cooling.x, cooling.y)
	_phases[index] = _rng.randf() * TAU
	_rates[index] = _rng.randf_range(flicker_rate.x, flicker_rate.y)
	_flares_until[index] = 0.0
	if look == Look.ASH:
		_positions[index] = Vector2(
				absf(_rng.randfn(fire_at * size.x, plume_width * size.x * ash_spread)),
				_rng.randf_range(ash_height.x, ash_height.y) * size.y)
		_velocities[index] = Vector2(_rng.randf_range(-ash_drift, ash_drift),
				_rng.randf_range(-ash_drift, ash_drift))
		return
	_positions[index] = Vector2(x, size.y + _rng.randf_range(0.0, LAUNCH_DEPTH))
	var angle: float = deg_to_rad(_rng.randfn(0.0, spread))
	var speed: float = plume_speed * _rng.randf_range(launch.x, launch.y) * speed_gain
	_velocities[index] = Vector2(sin(angle), -cos(angle)) * speed


## A flake of ash: grey, lit by the fire, tumbling (it narrows as it turns edge on), faded in and
## out over its life.
func _draw_ash(index: int, at: Vector2, core: float, appeared: float, glow: float) -> void:
	var share: float = _ages[index] / _lives[index]
	var tumble: float = maxf(ASH_EDGE_ON, absf(cos(_phases[index] + _time * TAU * _rates[index])))
	var lit: float = 1.0 + glow / MAX_FIRE_LEVEL
	draw_set_transform(at, _phases[index], Vector2(1.0, tumble))
	draw_texture_rect(_core, Rect2(Vector2(-core, -core) * 0.5, Vector2(core, core)), false,
			Color(ash_color.r * lit, ash_color.g * lit, ash_color.b * lit,
					ash_color.a * sin(PI * share) * appeared))


## How hot ember index is now: it cools by e every Cooling share of its life.
func _heat(index: int) -> float:
	return _heats[index] * exp(-_ages[index] / (_coolings[index] * _lives[index]))


## The tumble's flicker, as a share of the brightness: two waves at the ember's own pace and phase,
## never in step with the others. Weaker as it cools to a saturated red, which flashes count apart.
func _flicker(index: int, heat: float) -> float:
	var phase: float = _phases[index]
	var pace: float = _time * TAU * _rates[index]
	var wave: float = ((0.5 + 0.5 * sin(phase + pace))
			* (0.5 + 0.5 * sin(phase * SECOND_WAVE_PHASE + pace * SECOND_WAVE_PACE)))
	var depth: float = flicker_depth * lerpf(cooled_flicker, 1.0,
			smoothstep(FLICKER_HEAT.x, FLICKER_HEAT.y, heat))
	return 1.0 - depth + depth * wave


## The turbulence's air at a point, round 1 at its strongest: the curl of a noise that changes
## slowly, so it swirls and never gathers the embers in one place.
func _curl(at: Vector2) -> Vector2:
	var step: float = curl_size * CURL_STEP_SHARE
	var depth: float = _time * curl_drift * curl_size
	var here: float = _noise.get_noise_3d(at.x, at.y, depth)
	var right: float = _noise.get_noise_3d(at.x + step, at.y, depth)
	var below: float = _noise.get_noise_3d(at.x, at.y + step, depth)
	return Vector2(below - here, here - right) * (curl_size / step)


## Where along the bottom edge one leaves the fire: round its middle, within the plume.
func _fire_x() -> float:
	return fire_at * size.x + _rng.randfn(0.0, plume_width * size.x * fire_width)


## A free place in the pool, or -1 when every ember flies.
func _free_place() -> int:
	for index: int in _lives.size():
		if _lives[index] <= 0.0:
			return index
	return -1


## The average life: most live short (life share squared), so a third of the way along.
func _mean_life() -> float:
	return life.x + (life.y - life.x) / 3.0


## The wait for the next burst: random as wood cracks (exponential), kept within half and twice
## the average.
func _burst_wait() -> float:
	return clampf(-log(1.0 - _rng.randf()) * burst_every, burst_every * BURST_WAIT_LIMITS.x,
			burst_every * BURST_WAIT_LIMITS.y)


## A round dot for the pool's look, white, its alpha falling from its heart outwards as given.
func _dot(offsets: PackedFloat32Array, alphas: PackedFloat32Array) -> GradientTexture2D:
	var colours: PackedColorArray = PackedColorArray()
	for alpha: float in alphas:
		colours.append(Color(1.0, 1.0, 1.0, alpha))
	var gradient: Gradient = Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colours
	var dot: GradientTexture2D = GradientTexture2D.new()
	dot.gradient = gradient
	dot.width = DOT_SIZE
	dot.height = DOT_SIZE
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	return dot


## A wood ember's light by heat: the colours of a black body from about 1000 K to a core the camera
## saturates (Charity's table), with the brightness squeezed into what a screen can show.
static func _blackbody_ramp() -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.1, 0.25, 0.45, 0.65, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color(0.7, 0.14, 0.01, 0.0), Color(0.7, 0.14, 0.01, 0.05),
			Color(0.9, 0.22, 0.01, 0.15), Color(1.0, 0.32, 0.02, 0.35), Color(1.0, 0.44, 0.06, 0.6),
			Color(1.0, 0.62, 0.2, 0.85), Color(1.0, 0.88, 0.62, 1.0)])
	return ramp
