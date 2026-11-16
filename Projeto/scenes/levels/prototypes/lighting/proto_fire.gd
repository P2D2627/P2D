extends Node2D
## PROTOTYPE (#257): one of the level's fires. The flame is a flipbook drawn unshaded, so it shows
## in the dark; a soft additive halo behind it, and sparks and embers rising from it, sell the heat.
## The particles hang from a node drawn before the tiles, so the rock hides those that drift into it,
## and take the fire's opacity, so they hide with it. Its
## brightness follows the drawn frames, blended between them and kept to a gentle swing (WCAG
## 2.3.1: no strong change three times a second), and drives the halo and, in mode A, two lights
## without shadows: one for the space around it and one on the rock's light mask, so the rock faces
## near it glow.
## Its own ramp (#261, set_look): the flame's colours come from the fire's ramp
## (proto_fire_ramp.gdshader), and each fire plays at its own speed, so no two keep the same rhythm
## (the random start keeps them out of step; with their speeds they drift through it now and then).

const RAMP_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_fire_ramp.gdshader")
## The fire's ramp, by brightness: a deep wine near the cave's darkest colour, a deep magenta, the
## fire's pink, a peach and a warm core close to white.
const RAMP_OFFSETS: PackedFloat32Array = [0.0, 0.35, 0.65, 0.9, 1.0]
## The fire sheets' brightest luminance (measured on 16/11: 0.43 upright, 0.38 low), which takes
## the ramp's light end; their outline sits at ~0.01, their body at 0.26 to 0.28.
const RAMP_BRIGHTEST: float = 0.43
const RAMP_COLORS: PackedColorArray = [Color(0.3, 0.05, 0.18), Color(0.62, 0.1, 0.42),
		Color(1.0, 0.36, 0.78), Color(1.0, 0.84, 0.76), Color(1.0, 0.97, 0.92)]
## Seconds each drawn frame shows: the GIF's 130 ms.
const FRAME_TIME: float = 0.13
## With its own look, each fire plays this share faster or slower, at random.
const SPEED_SPREAD: float = 0.1
## How much of each frame's brightness change reaches the halo and the lights.
const FLICKER_SHARE: float = 0.35
## The halo's height, in flame heights.
const HALO_SIZE: float = 4.5
const HALO_STRENGTH: float = 0.32
const ROCK_LIGHT_SHARE: float = 0.5
## The box the man's sight looks at: the flame's body, this share of the drawn cell's width and,
## from the base, of its height; the cell's top corners are empty air round the flame's tip.
const LOOK_WIDTH_SHARE: float = 0.5
const LOOK_HEIGHT_SHARE: float = 0.8
## Off: played on 16/11, the sparks and embers looked wrong on these fires; the code is kept.
const PARTICLES_ON: bool = false
## Sparks: few, fast, short-lived streaks that point where they fly and curl at random; they leave at
## uneven times (Randomness), not as a steady fountain.
const SPARK_AMOUNT: int = 8
const SPARK_LIFETIME: float = 0.7
## Embers: fewer, slow, round and soft; they sway and shrink until they go out.
const EMBER_AMOUNT: int = 4
const EMBER_LIFETIME: float = 2.0
## Colors over a particle's life, never white: a peach core, the fire's pink, a deep magenta, gone.
const SPARK_CORE := Color(1.0, 0.84, 0.76)
const SPARK_DEEP := Color(0.62, 0.1, 0.42)

## Shared by every fire: a soft streak for the sparks and a soft dot for the embers.
static var _streak: GradientTexture2D
static var _dot: GradientTexture2D

## How bright the flame is now, 1 on average: the rig reads it.
var flicker: float = 1.0

var _curve: PackedFloat32Array
var _frames: int = 1
var _time: float = 0.0
var _speed: float = 1.0
var _rate: float = 1.0
var _plain: Material
var _flame: Sprite2D
var _halo: Sprite2D
var _main_light: PointLight2D
var _rock_light: PointLight2D
var _light_energy: float = 1.0
var _halo_color: Color
var _flame_size := Vector2.ZERO
var _particles: Node2D


## Builds the fire. Its origin is the middle of the flame's base, on the floor. Its sparks and
## embers go under Particle Parent, which the rig draws before the tiles.
func setup(sheet: Texture2D, frames: int, curve: PackedFloat32Array, flame_scale: float,
		color: Color, unshaded: Material, additive: Material, halo_texture: Texture2D,
		particle_parent: Node2D) -> void:
	_curve = curve
	_frames = frames
	_time = randf() * FRAME_TIME * float(frames)
	_speed = randf_range(1.0 - SPEED_SPREAD, 1.0 + SPEED_SPREAD)
	_plain = unshaded
	_halo_color = color
	var cell_height: float = float(sheet.get_height())
	var flame_height: float = cell_height * flame_scale
	_halo = Sprite2D.new()
	_halo.texture = halo_texture
	_halo.material = additive
	_halo.scale = Vector2.ONE * (flame_height * HALO_SIZE / float(halo_texture.get_height()))
	_halo.position = Vector2(0.0, -flame_height * 0.45)
	add_child(_halo)
	_flame = Sprite2D.new()
	_flame.texture = sheet
	_flame.hframes = frames
	_flame.material = unshaded
	_flame.scale = Vector2.ONE * flame_scale
	_flame.offset = Vector2(0.0, -cell_height * 0.5)
	add_child(_flame)
	_flame_size = Vector2(float(sheet.get_width()) / float(frames) * flame_scale, flame_height)
	if not PARTICLES_ON:
		return
	if _streak == null:
		_streak = _make_soft_texture(Vector2i(8, 32))
		_dot = _make_soft_texture(Vector2i(32, 32))
	_particles = Node2D.new()
	particle_parent.add_child(_particles)
	_particles.global_position = global_position
	_particles.add_child(_make_sparks(flame_height, _flame_size.x, color, additive))
	_particles.add_child(_make_embers(flame_height, _flame_size.x, color, additive))


## Drawn only while the man sees it, as the dogs are (#253): a look box over the flame's body and a
## SightReveal on the whole fire, halo and embers included. The lights stay on, so the glow on the
## rock round a corner gives a hidden fire away, while the flame itself shows only in his sight.
func hide_when_unseen() -> void:
	var size := Vector2(_flame_size.x * LOOK_WIDTH_SHARE, _flame_size.y * LOOK_HEIGHT_SHARE)
	var shape := RectangleShape2D.new()
	shape.size = size
	var look_box := CollisionShape2D.new()
	look_box.shape = shape
	look_box.position = Vector2(0.0, -size.y * 0.5)
	add_child(look_box)
	var reveal := SightReveal.new()
	reveal.target = self
	reveal.look_box = look_box
	add_child(reveal)


## Mode A: a light on the world's mask and a smaller one on the rock's.
func add_lights(light_texture: Texture2D, color: Color, energy: float, radius: float,
		height: float, world_mask: int, rock_mask: int) -> void:
	_light_energy = energy
	_main_light = _make_light(light_texture, color, energy, radius, world_mask)
	_rock_light = _make_light(light_texture, color, energy * ROCK_LIGHT_SHARE, radius * ROCK_LIGHT_SHARE,
			rock_mask)
	for light: PointLight2D in [_main_light, _rock_light]:
		light.position = Vector2(0.0, -height)
		add_child(light)


func set_lights_enabled(on: bool) -> void:
	if _main_light != null:
		_main_light.enabled = on
		_rock_light.enabled = on


## The material every fire shares for its own look: proto_fire_ramp.gdshader with the fire's ramp.
static func make_ramp_material() -> ShaderMaterial:
	var gradient := Gradient.new()
	gradient.offsets = RAMP_OFFSETS
	gradient.colors = RAMP_COLORS
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	var material := ShaderMaterial.new()
	material.shader = RAMP_SHADER
	material.set_shader_parameter(&"ramp", texture)
	material.set_shader_parameter(&"brightest", RAMP_BRIGHTEST)
	return material


## On: the flame through Ramp, at this fire's own speed. Off: the GIF's colours, all at one speed.
func set_look(ramp: Material, on: bool) -> void:
	_flame.material = ramp if on else _plain
	_rate = _speed if on else 1.0


## The drawn flame, in the world: for the measure of what feeds the glow.
func get_flame_rect() -> Rect2:
	return Rect2(global_position - Vector2(_flame_size.x * 0.5, _flame_size.y), _flame_size)


func _process(delta: float) -> void:
	_time += delta * _rate
	var step: float = fposmod(_time / FRAME_TIME, float(_frames))
	var index: int = int(step)
	_flame.frame = index
	var brightness: float = lerpf(_curve[index], _curve[(index + 1) % _frames], step - float(index))
	flicker = 1.0 + FLICKER_SHARE * (brightness - 1.0)
	_halo.modulate = Color(_halo_color, HALO_STRENGTH * flicker)
	if _particles != null:
		_particles.modulate.a = modulate.a
	if _main_light != null:
		_main_light.energy = _light_energy * flicker
		_rock_light.energy = _light_energy * ROCK_LIGHT_SHARE * flicker


func _make_light(texture: Texture2D, color: Color, energy: float, radius: float, mask: int) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = radius / (float(texture.get_width()) * 0.5)
	light.color = color
	light.energy = energy
	light.range_item_cull_mask = mask
	return light


## The streak's long side follows the velocity (Align Y), so each spark points where it flies; the
## tangential pull, random per spark, bends its path sideways as it rises.
func _make_sparks(flame_height: float, flame_width: float, color: Color, additive: Material) -> CPUParticles2D:
	var sparks := _make_emitter(_streak, SPARK_AMOUNT, SPARK_LIFETIME, additive)
	sparks.randomness = 0.7
	sparks.position = Vector2(0.0, -flame_height * 0.6)
	sparks.emission_rect_extents = Vector2(flame_width * 0.15, 6.0)
	sparks.spread = 25.0
	sparks.gravity = Vector2(0.0, -40.0)
	sparks.initial_velocity_min = 110.0
	sparks.initial_velocity_max = 220.0
	sparks.damping_min = 60.0
	sparks.damping_max = 120.0
	sparks.tangential_accel_min = -90.0
	sparks.tangential_accel_max = 90.0
	sparks.particle_flag_align_y = true
	sparks.scale_amount_min = 0.22
	sparks.scale_amount_max = 0.38
	sparks.scale_amount_curve = _life_curve(0.1, 0.1)
	sparks.color_ramp = _fire_ramp(color, PackedFloat32Array([1.0, 1.0, 0.7, 0.0]))
	return sparks


func _make_embers(flame_height: float, flame_width: float, color: Color, additive: Material) -> CPUParticles2D:
	var embers := _make_emitter(_dot, EMBER_AMOUNT, EMBER_LIFETIME, additive)
	embers.randomness = 0.8
	embers.position = Vector2(0.0, -flame_height * 0.5)
	embers.emission_rect_extents = Vector2(flame_width * 0.25, 8.0)
	embers.spread = 35.0
	embers.gravity = Vector2(0.0, -14.0)
	embers.initial_velocity_min = 18.0
	embers.initial_velocity_max = 45.0
	embers.damping_min = 4.0
	embers.damping_max = 10.0
	embers.tangential_accel_min = -30.0
	embers.tangential_accel_max = 30.0
	embers.scale_amount_min = 0.12
	embers.scale_amount_max = 0.22
	embers.scale_amount_curve = _life_curve(0.15, 0.6)
	embers.color_ramp = _fire_ramp(color, PackedFloat32Array([0.9, 0.85, 0.6, 0.0]))
	return embers


func _make_emitter(texture: Texture2D, amount: int, lifetime: float, additive: Material) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.texture = texture
	emitter.material = additive
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.lifetime_randomness = 0.5
	emitter.local_coords = false
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emitter.direction = Vector2.UP
	return emitter


## Size over life: from 40 % it grows to full by Full At, holds until Hold Until, then shrinks to
## nothing, so a particle goes out instead of just fading.
func _life_curve(full_at: float, hold_until: float) -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(full_at, 1.0))
	if hold_until > full_at:
		curve.add_point(Vector2(hold_until, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve


func _fire_ramp(color: Color, alphas: PackedFloat32Array) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
	ramp.colors = PackedColorArray([Color(SPARK_CORE, alphas[0]), Color(color, alphas[1]),
			Color(SPARK_DEEP, alphas[2]), Color(SPARK_DEEP, alphas[3])])
	return ramp


## A white radial falloff; on a texture that is not square it is an ellipse, which makes the streak.
static func _make_soft_texture(size: Vector2i) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.5),
			Color(1.0, 1.0, 1.0, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size.x
	texture.height = size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture
