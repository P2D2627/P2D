extends Node2D
## PROTOTYPE (#257): dust where the man and the dogs touch the floor or a wall, made only by listening
## to their signals; rewritten, never copied, in its own issue. The rig hangs it from the level before
## the tiles, so the floor hides the lower part of each puff, the rock hides what drifts into it, and
## it is drawn behind the man and the dogs.
## Each puff is drawn by proto_puff.gdshader: a cloud shape out of noise, lighter on top, eaten from its
## edges as it ages. Clouds roll out along what was touched and stop fast, then drift up.
## The man: a small cloud to each side on each jump; off a wall, up and down the wall's face; on each
## landing, a cloud to each side as big as PlayerSounds' last landing share says, and specks that fall
## back after a hard one; a thin trail while he slides down a wall.
## Each dog: a puff kicked back from the man when it warns of attack, unshaded so it shows in the dark
## too; a cloud to each side when it lands; dark smoke rising while the crucifix repels it. A dog's dust
## takes the dog's opacity, so it shows only while the dog does (#253).

const SHAPE_PATH := ^"CollisionShape2D"
## The floor's rim of stones (Art/StoneRim) is drawn over the man's feet and over this dust: the dust
## starts this many px above the feet, so it shows over the stones.
const FEET_LIFT: float = 14.0
const SOUNDS_PATH := ^"PlayerSounds"
const PUFF_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_puff.gdshader")
const PUFF_UNSHADED_SHADER: Shader = preload(
		"res://scenes/levels/prototypes/lighting/proto_puff_unshaded.gdshader")
## The square, in px, each puff is drawn on; the shader draws the cloud inside it.
const QUAD_SIZE: int = 64
## The noise the clouds are cut from: how fine it is, over a seamless square of Noise Size px.
const NOISE_SIZE: int = 128
const NOISE_FREQUENCY: float = 0.025
## How much of a cloud its age eats away (proto_puff.gdshaderinc): dust, and the slower smoke.
const DUST_EROSION: float = 0.75
const SMOKE_EROSION: float = 0.9
## Dust comes off the floor, so it takes the floor's color: a greyed mauve, darker and duller than the
## man and the lit walls, so it never reads as part of him; lit by the level's lights.
const PUFF_COLOR := Color(0.66, 0.58, 0.66)
## Played on 16/11: only a hint of dust, never a cloud that draws the eye.
const PUFF_ALPHA: float = 0.4
const PUFF_LIFETIME: float = 0.6
## Ink style (#261): each image of an effect is held for 1/Ink FPS s, like a drawing animated on
## threes at 60 fps, close to the man's walk (18 fps). Every effect of the rig in ink style uses it.
const INK_FPS: int = 20
## A landing rolls a cloud out to each side along the floor: Land Amount particles per side, sizes in
## px (min, max) for the hardest; a softer one is smaller (down to Soft Land Size times) and slower,
## from the first to the second px/s, by how hard it was (0 to 1). The amount never changes, so no
## emitter is rebuilt on a landing.
const LAND_AMOUNT: int = 2
const LAND_SIZE := Vector2(14.0, 28.0)
const SOFT_LAND_SIZE: float = 0.6
const LAND_SPEED := Vector2(60.0, 170.0)
## A landing at least Debris From hard also flings up to Debris Amount specks, which fall back.
const DEBRIS_FROM: float = 0.8
const DEBRIS_AMOUNT: int = 4
const DEBRIS_SIZE := Vector2(2.0, 4.0)
const DEBRIS_SPEED := Vector2(120.0, 240.0)
const DEBRIS_COLOR := Color(0.5, 0.4, 0.45)
const JUMP_AMOUNT: int = 1
const JUMP_SIZE := Vector2(12.0, 22.0)
const JUMP_SPEED := Vector2(50.0, 110.0)
## Off a wall the cloud rolls up and down the wall's face, a little away from it.
const WALL_JUMP_AMOUNT: int = 2
const WALL_JUMP_SPEED := Vector2(50.0, 120.0)
## Sliding down a wall faster than Slide Min Speed px/s leaves the trail.
const SLIDE_MIN_SPEED: float = 60.0
const SLIDE_AMOUNT: int = 4
const SLIDE_SIZE := Vector2(8.0, 14.0)
const SLIDE_SPEED := Vector2(15.0, 40.0)
## A dog warning of attack: a puff kicked back from the man, fainter, since it is unshaded.
const WARN_AMOUNT: int = 3
const WARN_SPEED := Vector2(60.0, 130.0)
const WARN_ALPHA: float = 0.3
const DOG_LAND_AMOUNT: int = 1
## The smoke off a dog the crucifix repels: it rises, spreads and is eaten away as it goes.
const SMOKE_COLOR := Color(0.42, 0.18, 0.36)
const SMOKE_ALPHA: float = 0.35
const SMOKE_AMOUNT: int = 8
const SMOKE_LIFETIME: float = 1.4
const SMOKE_SIZE := Vector2(20.0, 40.0)
const SMOKE_SPEED := Vector2(20.0, 45.0)


## A cloud that rolls out both ways: one emitter for each side.
class Roll:
	var sides: Array[CPUParticles2D] = []


## One dog's emitters, made the first time it needs one.
class DogDust:
	var holder: Node2D
	var warn: CPUParticles2D
	var land: Roll
	var smoke: CPUParticles2D


var _player: Player
var _sounds: PlayerSounds
var _quad: Texture2D
var _speck: Texture2D
var _lit: ShaderMaterial
var _glow: ShaderMaterial
var _smoke_material: ShaderMaterial
var _man_lands: Array[Roll] = []
var _next_land: int = 0
var _man_debris: CPUParticles2D
var _man_jump: Roll
var _man_wall_jump: Roll
var _man_slide: CPUParticles2D
var _dog_dust: Dictionary[Demon, DogDust] = {}
var _ink: bool = false


## Speck is the soft dot the falling specks are drawn with.
func setup(player: Player, dogs: Array[Demon], speck: Texture2D) -> void:
	_player = player
	_speck = speck
	# The project interpolates physics (project.godot): an emitter moved to a new spot in a physics
	# signal would be drawn sliding in from its last spot, so each cloud first showed where the one
	# before it had been. These emitters are placed by hand, never moved by physics: nothing of this
	# node and its children is interpolated.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_sounds = player.get_node_or_null(SOUNDS_PATH) as PlayerSounds
	_quad = _make_quad()
	var noise: NoiseTexture2D = _make_noise()
	_lit = _make_material(PUFF_SHADER, noise, DUST_EROSION)
	_glow = _make_material(PUFF_UNSHADED_SHADER, noise, DUST_EROSION)
	_smoke_material = _make_material(PUFF_SHADER, noise, SMOKE_EROSION)
	# Two landing clouds taking turns, so a landing right after another does not cut the first short.
	for k: int in 2:
		_man_lands.append(_make_roll(self, LAND_AMOUNT, LAND_SIZE, PUFF_ALPHA, _lit))
	_man_debris = _make_debris(self)
	_man_jump = _make_roll(self, JUMP_AMOUNT, JUMP_SIZE, PUFF_ALPHA, _lit)
	_man_wall_jump = _make_roll(self, WALL_JUMP_AMOUNT, JUMP_SIZE, PUFF_ALPHA, _lit)
	_man_slide = _make_puff(self, SLIDE_AMOUNT, SLIDE_SIZE, PUFF_ALPHA * 0.6, _lit)
	_man_slide.one_shot = false
	_man_slide.explosiveness = 0.0
	_man_slide.spread = 30.0
	_man_slide.initial_velocity_min = SLIDE_SPEED.x
	_man_slide.initial_velocity_max = SLIDE_SPEED.y
	# Against a wall the dust comes off a strip up its face, not along the floor.
	var wall_puffs: Array[CPUParticles2D] = [_man_slide]
	wall_puffs.append_array(_man_wall_jump.sides)
	for wall_puff: CPUParticles2D in wall_puffs:
		wall_puff.emission_rect_extents = Vector2(2.0, 16.0)
	player.jumped.connect(_on_man_jumped.unbind(2))
	player.wall_jumped.connect(_on_man_wall_jumped.unbind(2))
	if _sounds != null:
		_sounds.land_played.connect(_on_man_landed)
	else:
		player.landed.connect(_on_man_landed.bind(true))
	for dog: Demon in dogs:
		dog.warning_started.connect(_on_dog_warned.bind(dog))
		dog.landed.connect(_on_dog_landed.bind(dog))
		dog.state_changed.connect(_on_dog_state_changed.bind(dog))


## Ink style (#261, proto_puff.gdshaderinc): the clouds in two flat tones with an ink line, each
## image held for 1/Ink FPS s. Off, the soft clouds of #257.
func set_ink(on: bool) -> void:
	_ink = on
	for shader_material: ShaderMaterial in [_lit, _glow, _smoke_material]:
		shader_material.set_shader_parameter(&"ink_style", on)
	for puff: Node in find_children("*", "CPUParticles2D", true, false):
		(puff as CPUParticles2D).fixed_fps = INK_FPS if on else 0


func _process(_delta: float) -> void:
	if _player == null:
		return
	var sliding: bool = _player.is_on_wall_only() and _player.velocity.y > SLIDE_MIN_SPEED
	if sliding:
		var normal: Vector2 = _player.get_wall_normal()
		_man_slide.global_position = _side(_player, -normal.x, 0.3)
		_man_slide.direction = Vector2(normal.x, -0.3).normalized()
	_man_slide.emitting = sliding
	for key: Variant in _dog_dust.keys():
		var dust: DogDust = _dog_dust[key]
		if not is_instance_valid(key):
			dust.holder.queue_free()
			_dog_dust.erase(key)
			continue
		var dog := key as Demon
		dust.holder.modulate.a = dog.modulate.a
		if dust.smoke.emitting:
			dust.smoke.global_position = _center(dog)


func _on_man_jumped() -> void:
	_roll(_man_jump, _feet(_player), JUMP_SPEED)


func _on_man_wall_jumped() -> void:
	var away: float = signf(_player.velocity.x)
	if is_zero_approx(away):
		away = _player.get_wall_normal().x
	var at: Vector2 = _side(_player, -away, 0.6)
	_burst(_man_wall_jump.sides[0], at, Vector2(away * 0.35, -1.0).normalized(), 15.0, WALL_JUMP_SPEED)
	_burst(_man_wall_jump.sides[1], at, Vector2(away * 0.35, 1.0).normalized(), 15.0, WALL_JUMP_SPEED)


func _on_man_landed(_hard: bool) -> void:
	var share: float = _sounds.get_last_landing_share() if _sounds != null else 1.0
	var roll: Roll = _man_lands[_next_land]
	_next_land = (_next_land + 1) % _man_lands.size()
	var size: float = lerpf(SOFT_LAND_SIZE, 1.0, share) / float(QUAD_SIZE)
	for side: CPUParticles2D in roll.sides:
		side.scale_amount_min = LAND_SIZE.x * size
		side.scale_amount_max = LAND_SIZE.y * size
	var speed: float = lerpf(LAND_SPEED.x, LAND_SPEED.y, share)
	_roll(roll, _feet(_player), Vector2(speed * 0.6, speed))
	if share >= DEBRIS_FROM:
		_burst(_man_debris, _feet(_player), Vector2.UP, 70.0, DEBRIS_SPEED)


func _on_dog_warned(_attack: DemonAttack, dog: Demon) -> void:
	var back: float = signf(dog.global_position.x - _player.global_position.x)
	if is_zero_approx(back):
		back = 1.0
	_burst(_dust_for(dog).warn, _feet(dog), Vector2(back, -0.25).normalized(), 20.0, WARN_SPEED)


func _on_dog_landed(dog: Demon) -> void:
	_roll(_dust_for(dog).land, _feet(dog), JUMP_SPEED)


func _on_dog_state_changed(_previous: Demon.State, current: Demon.State, dog: Demon) -> void:
	var repelled: bool = current == Demon.State.REPELLED
	if not repelled and not _dog_dust.has(dog):
		return
	var smoke: CPUParticles2D = _dust_for(dog).smoke
	if repelled:
		smoke.global_position = _center(dog)
	smoke.emitting = repelled


func _dust_for(dog: Demon) -> DogDust:
	if _dog_dust.has(dog):
		return _dog_dust[dog]
	var dust := DogDust.new()
	dust.holder = Node2D.new()
	add_child(dust.holder)
	dust.warn = _make_puff(dust.holder, WARN_AMOUNT, JUMP_SIZE, WARN_ALPHA, _glow)
	dust.land = _make_roll(dust.holder, DOG_LAND_AMOUNT, JUMP_SIZE, PUFF_ALPHA, _lit)
	dust.smoke = _make_smoke(dust.holder, dog)
	for puff: Node in dust.holder.get_children():
		(puff as CPUParticles2D).fixed_fps = INK_FPS if _ink else 0
	_dog_dust[dog] = dust
	return dust


func _burst(puff: CPUParticles2D, at: Vector2, direction: Vector2, spread: float, speed: Vector2) -> void:
	puff.global_position = at
	puff.direction = direction
	puff.spread = spread
	puff.initial_velocity_min = speed.x
	puff.initial_velocity_max = speed.y
	puff.restart()


## Out to both sides, nearly flat along the floor.
func _roll(roll: Roll, at: Vector2, speed: Vector2) -> void:
	for k: int in roll.sides.size():
		var side: float = -1.0 if k == 0 else 1.0
		_burst(roll.sides[k], at + Vector2(side * 8.0, 0.0), Vector2(side, -0.25).normalized(), 12.0, speed)


func _make_roll(parent: Node, amount: int, size_px: Vector2, alpha: float, look: Material) -> Roll:
	var roll := Roll.new()
	for k: int in 2:
		roll.sides.append(_make_puff(parent, amount, size_px, alpha, look))
	return roll


## A cloud that bursts out, stops hard, drifts up and grows as its edges are eaten away. The random
## anim offset only seeds which patch of noise each cloud is cut from (proto_puff.gdshaderinc).
func _make_puff(parent: Node, amount: int, size_px: Vector2, alpha: float, look: Material) -> CPUParticles2D:
	var puff := CPUParticles2D.new()
	puff.texture = _quad
	puff.material = look
	puff.emitting = false
	puff.one_shot = true
	puff.explosiveness = 0.85
	puff.amount = amount
	puff.lifetime = PUFF_LIFETIME
	puff.lifetime_randomness = 0.35
	puff.local_coords = false
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	puff.emission_rect_extents = Vector2(14.0, 3.0)
	puff.gravity = Vector2(0.0, -45.0)
	puff.damping_min = 200.0
	puff.damping_max = 380.0
	puff.angle_min = -25.0
	puff.angle_max = 25.0
	puff.anim_offset_max = 1.0
	puff.scale_amount_min = size_px.x / float(QUAD_SIZE)
	puff.scale_amount_max = size_px.y / float(QUAD_SIZE)
	puff.scale_amount_curve = _grow_curve()
	puff.color_ramp = _fade_ramp(PUFF_COLOR, alpha)
	parent.add_child(puff)
	return puff


## Specks of grit flung up by a hard landing, which fall back fast.
func _make_debris(parent: Node) -> CPUParticles2D:
	var debris := CPUParticles2D.new()
	debris.texture = _speck
	debris.emitting = false
	debris.one_shot = true
	debris.explosiveness = 0.95
	debris.amount = DEBRIS_AMOUNT
	debris.lifetime = 0.6
	debris.lifetime_randomness = 0.3
	debris.local_coords = false
	debris.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	debris.emission_rect_extents = Vector2(14.0, 2.0)
	debris.gravity = Vector2(0.0, 900.0)
	debris.scale_amount_min = DEBRIS_SIZE.x / float(_speck.get_width())
	debris.scale_amount_max = DEBRIS_SIZE.y / float(_speck.get_width())
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(DEBRIS_COLOR, 0.9), Color(DEBRIS_COLOR, 0.9), Color(DEBRIS_COLOR, 0.0)])
	debris.color_ramp = ramp
	parent.add_child(debris)
	return debris


func _make_quad() -> Texture2D:
	var image := Image.create_empty(QUAD_SIZE, QUAD_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func _make_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = NOISE_SIZE
	texture.height = NOISE_SIZE
	texture.seamless = true
	texture.noise = noise
	return texture


func _make_material(shader: Shader, noise: Texture2D, erosion: float) -> ShaderMaterial:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("noise_texture", noise)
	shader_material.set_shader_parameter("erosion", erosion)
	return shader_material


func _make_smoke(parent: Node, dog: Demon) -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.texture = _quad
	smoke.material = _smoke_material
	smoke.angle_min = -30.0
	smoke.angle_max = 30.0
	smoke.anim_offset_max = 1.0
	smoke.emitting = false
	smoke.amount = SMOKE_AMOUNT
	smoke.lifetime = SMOKE_LIFETIME
	smoke.lifetime_randomness = 0.3
	smoke.local_coords = false
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = _half_size(dog) * 0.6
	smoke.direction = Vector2.UP
	smoke.spread = 30.0
	smoke.gravity = Vector2(0.0, -25.0)
	smoke.initial_velocity_min = SMOKE_SPEED.x
	smoke.initial_velocity_max = SMOKE_SPEED.y
	smoke.damping_min = 5.0
	smoke.damping_max = 10.0
	smoke.scale_amount_min = SMOKE_SIZE.x / float(QUAD_SIZE)
	smoke.scale_amount_max = SMOKE_SIZE.y / float(QUAD_SIZE)
	smoke.scale_amount_curve = _grow_curve()
	smoke.color_ramp = _fade_ramp(SMOKE_COLOR, SMOKE_ALPHA)
	parent.add_child(smoke)
	return smoke


## From a little over half its size it grows to full by 30 % of its life and keeps growing slowly.
func _grow_curve() -> Curve:
	var curve := Curve.new()
	curve.max_value = 1.5
	curve.add_point(Vector2(0.0, 0.55))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 1.35))
	return curve


## Shows at once and fades a little; the erosion in the shader does the rest.
func _fade_ramp(color: Color, alpha: float) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.06, 0.5, 1.0])
	ramp.colors = PackedColorArray([Color(color, 0.0), Color(color, alpha), Color(color, alpha * 0.8),
			Color(color, 0.0)])
	return ramp


func _shape(body: Node2D) -> CollisionShape2D:
	return body.get_node_or_null(SHAPE_PATH) as CollisionShape2D


func _half_size(body: Node2D) -> Vector2:
	var shape := _shape(body)
	if shape != null and shape.shape is RectangleShape2D:
		return (shape.shape as RectangleShape2D).size * 0.5
	return Vector2.ZERO


func _center(body: Node2D) -> Vector2:
	var shape := _shape(body)
	return shape.global_position if shape != null else body.global_position


func _feet(body: Node2D) -> Vector2:
	return _center(body) + Vector2(0.0, _half_size(body).y - FEET_LIFT)


## A point on the body's side (-1 left, 1 right), at a share of the way from its middle to its feet.
func _side(body: Node2D, side: float, down_share: float) -> Vector2:
	var half: Vector2 = _half_size(body)
	return _center(body) + Vector2(side * half.x, half.y * down_share)
