extends CanvasGroup
## PROTOTYPE (#261): smoke made of soft stamps that melt into one body. Each stamp is a soft round
## eaten by noise held in the world (proto_smoke_stamp.gdshader); it drifts, rises, grows and thins
## with age. The group draws them all into one buffer, one over the other, and its own shader
## (proto_smoke.gdshaderinc) keeps only where the alpha they make together passes a threshold: one
## continuous body with a soft edge, which erodes along the noise as the stamps thin, and with its
## opacity applied once, so where the smoke crosses itself it does not darken in blotches. Ash is lit
## by the scene (the fires tint it, the cave's dark eats it); light is unshaded and added. Time is its
## own, so it stops with the game's pause. A trail (Trail Length above 0) also ages its stamps by how
## far its source has gone since it left them, so it is never longer than that, however fast.

enum Look { ASH, LIGHT }

const STAMP_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_smoke_stamp.gdshader")
const ASH_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_smoke_ash.gdshader")
const LIGHT_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_smoke_light.gdshader")
const STAMP_TEXTURE_SIZE: int = 64
const NOISE_SIZE: int = 128
const NOISE_FREQUENCY: float = 0.05
## Two octaves: large soft clumps; a third breaks the edge into grain.
const NOISE_OCTAVES: int = 2
## A stamp comes in over this share of its life, so the head of a trail does not pop.
const FADE_IN: float = 0.12

## One stamp of the pool.
class Stamp:
	var sprite: Sprite2D
	var velocity := Vector2.ZERO
	var size_scale: float = 1.0
	var lifetime: float = 1.0
	var age: float = 0.0
	var strength: float = 1.0
	## Its alpha (modulate) dims the stamp: the smoke of a dog the man has not seen is not seen. A
	## freed source is not null in a comparison, so whether there was one is kept apart.
	var source: CanvasItem
	var has_source: bool = false
	## Distance (the group's) when it was left.
	var left_at: float = 0.0

## The stamps' diameter in px as they start and as they end; how fast they rise (px/s); how fast
## what they inherit slows down (1/s).
var size_from: float = 32.0
var size_to: float = 56.0
var rise: float = 25.0
var drag: float = 3.0
## How the noise inside the smoke churns, in world px/s: the smoke seems to roll as it goes.
var churn := Vector2(6.0, -18.0)
## For a trail: its longest, in px of its source's path (0, no such limit), and how far the source
## has gone so far, which its emitter keeps adding to.
var trail_length: float = 0.0
var distance: float = 0.0

var _stamps: Array[Stamp] = []
var _next: int = 0
var _clock: float = 0.0
var _stamp_material: ShaderMaterial
var _ash: ShaderMaterial
var _light: ShaderMaterial


## Pool Size stamps; Edge and Core are the smoke's thin and dense colours, Opacity its strongest.
func setup(pool_size: int, edge: Color, core: Color, opacity: float) -> void:
	# Placed by hand every frame: drawn where they are put, not slid there.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_stamp_material = ShaderMaterial.new()
	_stamp_material.shader = STAMP_SHADER
	_stamp_material.set_shader_parameter(&"noise_texture", _make_noise())
	_ash = _make_group_material(ASH_SHADER, edge, core, opacity)
	_light = _make_group_material(LIGHT_SHADER, edge, core, opacity)
	material = _ash
	var round_texture: GradientTexture2D = _make_round()
	for k: int in pool_size:
		var stamp := Stamp.new()
		stamp.sprite = Sprite2D.new()
		stamp.sprite.texture = round_texture
		stamp.sprite.material = _stamp_material
		stamp.sprite.visible = false
		add_child(stamp.sprite)
		_stamps.append(stamp)


## The light look's colours, if they differ from the ash's.
func set_light_colors(edge: Color, core: Color, opacity: float) -> void:
	_set_colors(_light, edge, core, opacity)


func set_look(look: Look) -> void:
	material = _ash if look == Look.ASH else _light


## Hides every stamp at once (the smoke switched off, or its source jumped elsewhere).
func clear() -> void:
	for stamp: Stamp in _stamps:
		stamp.sprite.visible = false


## A stamp at At (global), carried by Velocity, for Lifetime s, Strength 0 to 1, Size Scale times
## the group's sizes; Source's alpha dims it, if given; Behind is how far behind the source's present
## place, along its path, it is left (a trail's stamps laid in one frame). Takes the next stamp in
## turn, which is about the oldest.
func puff(at: Vector2, velocity: Vector2, lifetime: float, strength: float, size_scale: float = 1.0,
		source: CanvasItem = null, behind: float = 0.0) -> void:
	var stamp: Stamp = _stamps[_next]
	_next = (_next + 1) % _stamps.size()
	stamp.velocity = velocity
	stamp.lifetime = maxf(lifetime, 0.01)
	stamp.age = 0.0
	stamp.strength = strength
	stamp.size_scale = size_scale
	stamp.source = source
	stamp.has_source = source != null
	stamp.left_at = distance - behind
	stamp.sprite.global_position = at
	stamp.sprite.rotation = randf() * TAU
	_place(stamp, 0.0)
	stamp.sprite.visible = true


func _process(delta: float) -> void:
	_clock += delta
	_stamp_material.set_shader_parameter(&"drift", churn * _clock)
	var slow: float = exp(-drag * delta)
	for stamp: Stamp in _stamps:
		if not stamp.sprite.visible:
			continue
		stamp.age += delta
		var life: float = stamp.age / stamp.lifetime
		if trail_length > 0.0:
			life = maxf(life, (distance - stamp.left_at) / trail_length)
		if life >= 1.0:
			stamp.sprite.visible = false
			continue
		stamp.velocity *= slow
		stamp.sprite.global_position += (stamp.velocity + Vector2(0.0, -rise)) * delta
		_place(stamp, life)


## Its size and how much it still weighs at Life (0 to 1): it grows fast and then slowly, comes in
## over Fade In and thins away to nothing.
func _place(stamp: Stamp, life: float) -> void:
	var grown: float = 1.0 - (1.0 - life) * (1.0 - life)
	var size: float = lerpf(size_from, size_to, grown) * stamp.size_scale
	stamp.sprite.scale = Vector2.ONE * (size / float(STAMP_TEXTURE_SIZE))
	var seen: float = 1.0
	if stamp.has_source:
		seen = stamp.source.modulate.a if is_instance_valid(stamp.source) else 0.0
	var weight: float = stamp.strength * seen * clampf(life / FADE_IN, 0.0, 1.0) * (1.0 - life)
	# The stamp's shader reads its weight in the modulate's alpha.
	stamp.sprite.self_modulate = Color(1.0, 1.0, 1.0, weight)


func _make_group_material(shader: Shader, edge: Color, core: Color, opacity: float) -> ShaderMaterial:
	var group_material := ShaderMaterial.new()
	group_material.shader = shader
	_set_colors(group_material, edge, core, opacity)
	return group_material


func _set_colors(group_material: ShaderMaterial, edge: Color, core: Color, opacity: float) -> void:
	group_material.set_shader_parameter(&"edge_color", edge)
	group_material.set_shader_parameter(&"core_color", core)
	group_material.set_shader_parameter(&"opacity", opacity)


func _make_round() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = STAMP_TEXTURE_SIZE
	texture.height = STAMP_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


func _make_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = NOISE_OCTAVES
	var texture := NoiseTexture2D.new()
	texture.width = NOISE_SIZE
	texture.height = NOISE_SIZE
	texture.seamless = true
	texture.noise = noise
	return texture
