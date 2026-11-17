extends Node2D
## PROTOTYPE (#261): the crucifix's light on its events, drawn as proto_puff.gdshaderinc shards
## (proto_shard.gdshader, unshaded since they are light). Each effect is an answer to something the
## crucifix does, never a stream while it is only held: its own light says that. The shards are a
## fixed pool of Sprite2D this script moves, not particles: in ink style it holds each image for
## 1/Ink FPS s itself, like drawn frames, and the motion is exact. (CPUParticles2D here drew nothing
## in recorded runs, for a reason not found; the pool needs none of it.)
## Raised: a short burst of thin shards out of it, flying fast and stopping hard, most of the move in
## the first quarter of their life, then eaten away.
## Struck: a few shards from the crucifix's side of the dog that came into its radius, towards it.
## Warning: at the bottom of each dip of the light's pulse near the end of a use, a few chips fall
## off it, tumbling. Ran out: the last chips fall.
## Flashing: the raise cannot come again before the crucifix's cooldown (15 s). A strike can come on
## any physics frame a dog comes in, but its few shards cover a fraction of a percent of the screen,
## far under the flash area of WCAG 2.3.1 (~10 % of the central field).

const ProtoContactDust := preload("res://scenes/levels/prototypes/lighting/proto_contact_dust.gd")
const SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_shard.gdshader")
const LIGHT_PATH := ^"Light"
## Near white and warm, as the crucifix's light, the one light that never takes the level's colour.
const LIGHT_COLOR := Color(1.0, 0.93, 0.82)
## The line round each shard and chip: a deeper warm colour, and how far in it reaches (shape units).
const LIGHT_LINE_COLOR := Color(0.95, 0.5, 0.3)
const LIGHT_LINE_WIDTH: float = 0.08
## The shards are drawn on a quad Shard Quad px; the shader's diamond fills it, so they are long and
## thin and, aligned to their velocity, point the way they fly.
const SHARD_QUAD := Vector2i(16, 64)
## Chips are slivers, not squares: square ones read as confetti.
const CHIP_QUAD := Vector2i(16, 40)
## The raise: how many shards, their length in px (min, max), speed in px/s, how hard they stop
## (px/s²) and how long they live.
const RAISE_AMOUNT: int = 10
const RAISE_LENGTH := Vector2(36.0, 64.0)
const RAISE_SPEED := Vector2(520.0, 820.0)
const RAISE_LIFETIME: float = 0.4
## The raise's shards go all round, evenly spaced, each turned up to this share of its slot either
## way, so the burst has no gap and no clump.
const RAISE_JITTER: float = 0.3
## How hard every shard stops, in px/s².
const SHARD_DAMPING := Vector2(2200.0, 2800.0)
## Each shard and chip lives its kind's lifetime times a random share from this to 1.
const LIFE_VARIETY: float = 0.8
## The strike: fewer, shorter, in a cone towards the dog.
const STRIKE_AMOUNT: int = 6
const STRIKE_LENGTH := Vector2(24.0, 44.0)
const STRIKE_SPEED := Vector2(380.0, 620.0)
const STRIKE_SPREAD: float = 35.0
const STRIKE_LIFETIME: float = 0.3
## Where on a dog the strike shows: up from its feet to its middle (the body is 56 px tall), then
## this far back towards the crucifix, on the dog's edge.
const DOG_MIDDLE: float = 28.0
const DOG_EDGE: float = 40.0
## A dog shows a strike only within the crucifix's repel radius plus this much (half its body, 112
## px long): the one that just came in, never one far away.
const DOG_REACH: float = 60.0
## A dog fainter than this (hidden by the man's sight) shows no strike, so the light gives no hidden
## dog away.
const DOG_SEEN_ALPHA: float = 0.5
## The chips: length in px, how far round the crucifix they come off, how many fall at each dip and
## when it runs out, how they fall and tumble.
const CHIP_SIZE := Vector2(12.0, 20.0)
const CHIP_SPREAD_PX: float = 24.0
const DIP_AMOUNT: int = 3
const RAN_OUT_AMOUNT: int = 9
const CHIP_SPEED := Vector2(30.0, 90.0)
## Chips leave up to this many degrees either side of straight up.
const CHIP_CONE: float = 80.0
const CHIP_GRAVITY: float = 320.0
const CHIP_SPIN: float = 240.0
const CHIP_LIFETIME: float = 0.8
## How much of each shard and chip the erosion eats by the end of its life: past the tallest part
## of the diamond, so nothing is left when it goes.
const EROSION: float = 1.5
## The noise the shards are chipped by.
const NOISE_SIZE: int = 64
const NOISE_FREQUENCY: float = 0.05
## How many shards and chips can be out at once: a raise and a strike together, and a run out.
const SHARD_POOL: int = 20
const CHIP_POOL: int = 12
## Of a shard's length: all of it at first, this much a quarter into its life, this much at the end.
const SHRINK_QUARTER: float = 0.85
const SHRINK_END: float = 0.35


## One shard or chip: where it set off, how it moves, and how old it is (below 0: not out).
class Shard:
	var sprite: Sprite2D
	var origin := Vector2.ZERO
	var direction := Vector2.UP
	var speed: float = 0.0
	var damping: float = 0.0
	var gravity: float = 0.0
	var angle: float = 0.0
	var spin: float = 0.0
	var size: float = 1.0
	var lifetime: float = 1.0
	var aligned: bool = false
	var age: float = -1.0


var _crucifix: Crucifix
var _source: Node2D
var _dogs: Array[Demon] = []
var _material: ShaderMaterial
var _shards: Array[Shard] = []
var _chips: Array[Shard] = []
var _on: bool = false
var _ink: bool = true
## The pulse on the frame before, and whether it was going down: a dip's bottom is where it turns.
var _last_pulse: float = 1.0
var _pulse_falling: bool = false


## Listens to Crucifix; Dogs are the ones a strike can show on.
func setup(crucifix: Crucifix, dogs: Array[Demon]) -> void:
	_crucifix = crucifix
	_dogs = dogs
	_source = crucifix.get_node_or_null(LIGHT_PATH) as Node2D
	if _source == null:
		_source = crucifix
	# Placed by hand each frame: drawn where they are put, not slid there.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"noise_texture", _make_noise())
	_material.set_shader_parameter(&"erosion", EROSION)
	_material.set_shader_parameter(&"shard", true)
	# Light is not drawn in dark ink but with a line of a deeper warm colour, so it reads on a lit man
	# as well as on the dark; its two tones are near white and the warm body.
	_material.set_shader_parameter(&"ink_width", LIGHT_LINE_WIDTH)
	_material.set_shader_parameter(&"ink_color", LIGHT_LINE_COLOR)
	_material.set_shader_parameter(&"core_tone", 1.0)
	_material.set_shader_parameter(&"body_tone", 0.82)
	var shard_quad: Texture2D = _make_quad(SHARD_QUAD)
	var chip_quad: Texture2D = _make_quad(CHIP_QUAD)
	for k: int in SHARD_POOL:
		_shards.append(_make_shard(shard_quad))
	for k: int in CHIP_POOL:
		_chips.append(_make_shard(chip_quad))
	crucifix.raised.connect(_on_raised)
	crucifix.struck.connect(_on_struck)
	crucifix.ran_out.connect(_on_ran_out)


func set_on(on: bool) -> void:
	_on = on
	if not on:
		for pool: Array[Shard] in [_shards, _chips]:
			for shard: Shard in pool:
				shard.age = -1.0
				shard.sprite.visible = false


## Ink style (proto_puff.gdshaderinc): two flat tones, each image held for 1/Ink FPS s. Off: soft.
func set_ink(on: bool) -> void:
	_ink = on
	_material.set_shader_parameter(&"ink_style", on)


func _process(delta: float) -> void:
	for shard: Shard in _shards:
		if shard.age >= 0.0:
			_move(shard, delta)
	for chip: Shard in _chips:
		if chip.age >= 0.0:
			_move(chip, delta)
	if not _on or _crucifix == null or not _crucifix.is_raised():
		_last_pulse = 1.0
		_pulse_falling = false
		return
	# Every dip of the warning, however shallow, at its bottom: where the pulse turns back up.
	var pulse: float = _crucifix.get_warning_pulse()
	if _crucifix.get_warning_progress() > 0.0 and _pulse_falling and pulse > _last_pulse:
		_drop_chips(DIP_AMOUNT)
	_pulse_falling = pulse < _last_pulse
	_last_pulse = pulse


func _on_raised() -> void:
	if not _on:
		return
	var at: Vector2 = _source.global_position
	for k: int in RAISE_AMOUNT:
		# All round, evenly spaced with a little play, so the burst has no gap and no clump.
		var slot: float = float(k) + randf_range(-RAISE_JITTER, RAISE_JITTER)
		var direction := Vector2.UP.rotated(TAU * slot / RAISE_AMOUNT)
		_launch(_take(_shards), at, direction, RAISE_SPEED, RAISE_LENGTH, RAISE_LIFETIME)


## On the edge of the dog nearest the crucifix, of those in sight, pointing from the crucifix at it.
func _on_struck() -> void:
	if not _on:
		return
	var from: Vector2 = _source.global_position
	var nearest: Demon = null
	var nearest_distance: float = _crucifix.stats.repel_radius + DOG_REACH
	for dog: Demon in _dogs:
		if not is_instance_valid(dog) or dog.modulate.a < DOG_SEEN_ALPHA:
			continue
		var distance: float = from.distance_to(dog.global_position)
		if distance < nearest_distance:
			nearest = dog
			nearest_distance = distance
	if nearest == null:
		return
	var middle: Vector2 = nearest.global_position + Vector2(0.0, -DOG_MIDDLE)
	var toward: Vector2 = from.direction_to(middle)
	var at: Vector2 = middle - toward * DOG_EDGE
	for k: int in STRIKE_AMOUNT:
		var direction: Vector2 = toward.rotated(deg_to_rad(randf_range(-STRIKE_SPREAD, STRIKE_SPREAD)))
		_launch(_take(_shards), at, direction, STRIKE_SPEED, STRIKE_LENGTH, STRIKE_LIFETIME)


func _on_ran_out() -> void:
	if _on:
		_drop_chips(RAN_OUT_AMOUNT)


## Thin shards that fly out fast, stop hard and point the way they flew.
func _launch(shard: Shard, at: Vector2, direction: Vector2, speed: Vector2, length: Vector2,
		lifetime: float) -> void:
	shard.origin = at
	shard.direction = direction
	shard.speed = randf_range(speed.x, speed.y)
	shard.damping = randf_range(SHARD_DAMPING.x, SHARD_DAMPING.y)
	shard.gravity = 0.0
	shard.size = randf_range(length.x, length.y) / float(SHARD_QUAD.y)
	shard.lifetime = lifetime * randf_range(LIFE_VARIETY, 1.0)
	shard.aligned = true
	shard.spin = 0.0
	_start(shard)


## Chips that fall off the crucifix, tumbling.
func _drop_chips(amount: int) -> void:
	for k: int in amount:
		var chip: Shard = _take(_chips)
		chip.origin = _source.global_position + Vector2(randf_range(-CHIP_SPREAD_PX, CHIP_SPREAD_PX),
				randf_range(-CHIP_SPREAD_PX, CHIP_SPREAD_PX))
		chip.direction = Vector2.UP.rotated(deg_to_rad(randf_range(-CHIP_CONE, CHIP_CONE)))
		chip.speed = randf_range(CHIP_SPEED.x, CHIP_SPEED.y)
		chip.damping = 0.0
		chip.gravity = CHIP_GRAVITY
		chip.size = randf_range(CHIP_SIZE.x, CHIP_SIZE.y) / float(CHIP_QUAD.y)
		chip.lifetime = CHIP_LIFETIME * randf_range(LIFE_VARIETY, 1.0)
		chip.aligned = false
		chip.angle = randf_range(-PI, PI)
		chip.spin = deg_to_rad(randf_range(-CHIP_SPIN, CHIP_SPIN))
		_start(chip)


func _start(shard: Shard) -> void:
	shard.age = 0.0
	shard.sprite.set_instance_shader_parameter(&"seed", randf())
	shard.sprite.visible = true
	_move(shard, 0.0)


## A free one, or the oldest if all are out.
func _take(pool: Array[Shard]) -> Shard:
	var oldest: Shard = pool[0]
	for shard: Shard in pool:
		if shard.age < 0.0:
			return shard
		if shard.age > oldest.age:
			oldest = shard
	return oldest


## Where the shard is at its age, held in steps of 1/Ink FPS s in ink style: the travel stops when
## the damping has eaten the speed, gravity pulls chips down, and a shard shrinks as it is eaten.
func _move(shard: Shard, delta: float) -> void:
	shard.age += delta
	if shard.age >= shard.lifetime:
		shard.age = -1.0
		shard.sprite.visible = false
		return
	var fps: float = float(ProtoContactDust.INK_FPS)
	var t: float = floorf(shard.age * fps) / fps if _ink else shard.age
	var travel_time: float = minf(t, shard.speed / shard.damping) if shard.damping > 0.0 else t
	var travel: float = shard.speed * travel_time - 0.5 * shard.damping * travel_time * travel_time
	shard.sprite.global_position = (shard.origin + shard.direction * travel
			+ Vector2(0.0, 0.5 * shard.gravity * t * t))
	var share: float = t / shard.lifetime
	if shard.aligned:
		# The quad's long side is its y: turned so that y points the way it flies.
		shard.sprite.rotation = shard.direction.angle() - PI * 0.5
		var shrink: float = (lerpf(1.0, SHRINK_QUARTER, share / 0.25) if share < 0.25
				else lerpf(SHRINK_QUARTER, SHRINK_END, (share - 0.25) / 0.75))
		shard.sprite.scale = Vector2(shard.size, shard.size * shrink)
	else:
		shard.sprite.rotation = shard.angle + shard.spin * t
		shard.sprite.scale = Vector2.ONE * shard.size
	shard.sprite.set_instance_shader_parameter(&"life_share", share)


func _make_shard(quad: Texture2D) -> Shard:
	var shard := Shard.new()
	shard.sprite = Sprite2D.new()
	shard.sprite.texture = quad
	shard.sprite.material = _material
	# Shows at once and holds: the shader's erosion takes it away, not a fade.
	shard.sprite.modulate = LIGHT_COLOR
	shard.sprite.visible = false
	add_child(shard.sprite)
	return shard


func _make_quad(size: Vector2i) -> Texture2D:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func _make_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = NOISE_SIZE
	texture.height = NOISE_SIZE
	texture.seamless = true
	texture.noise = noise
	return texture
