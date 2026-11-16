extends Node2D
## PROTOTYPE (#261): what ties the man into the cave, each part switched by the rig.
## Scene light: his drawing leaves the light mask his own main light reaches, so his body takes the
## cave's dark, the fires, his wide fill light and the crucifix's light, not the light he carries.
## Outline: the scenery's dark ink round his drawing (proto_rim.gdshader's outline).
## Contact shadow: a soft dark ellipse on the floor under him, fainter and smaller as he rises.
## Squash: his drawing squashes as he lands, more the harder he lands, and comes back in a few held
## steps, like drawn frames: squashed, half way, a little stretched, back. The drawing's origin is on
## his feet (player.tscn), so they stay on the floor. There is no drawn landing frame yet.
## Ghosts: falling fast, he leaves a few copies of his drawing in the cave's dusky mauve, eaten away
## by noise held in steps (proto_ghost.gdshader): weight, not the grace of a light trail.

const ProtoContactDust := preload("res://scenes/levels/prototypes/lighting/proto_contact_dust.gd")
const GHOST_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_ghost.gdshader")
## The shadow: its size on the floor, how dark it is there, and how high above the floor he can be
## before it is gone.
const SHADOW_SIZE := Vector2(72.0, 14.0)
const SHADOW_ALPHA: float = 0.55
const SHADOW_REACH: float = 160.0
## At the top of the reach, the shadow is this share of its size.
const SHADOW_FAR_SCALE: float = 0.6
## The ray starts this far above his feet, which rest on the floor's surface: a ray that starts on
## or inside a shape does not see it.
const SHADOW_RAY_LIFT: float = 8.0
const SHADOW_TEXTURE_SIZE: int = 32
## The squash at the hardest landing: the drawing this share wider and shorter. Below Squash From of
## PlayerSounds' landing share (0 soft to 1 hardest), none. Each step holds for 1/Ink FPS s and is
## this share of the squash; a negative one stretches.
const SQUASH_MAX: float = 0.14
const SQUASH_FROM: float = 0.2
const SQUASH_STEPS: Array[float] = [1.0, 0.7, 0.25, -0.15, 0.0]
## Ghosts: one every Ghost Gap s while he falls faster than PlayerAnimation's Fast Fall Speed (when
## the drawing braces for the landing), at most Ghost Count at once, each living Ghost Lifetime s.
## Enough that none is taken back while still alive: one every 3 physics frames (Ghost Gap rounds up
## to 0.05 s), 6 cover 0.3 s.
const GHOST_COUNT: int = 6
const GHOST_GAP: float = 0.035
const GHOST_LIFETIME: float = 0.3
## The cave's dusky mauve, not light: a heavy body leaving its shape in the air for a moment.
const GHOST_COLOR := Color(0.42, 0.28, 0.4, 0.6)
const FAST_FALL_SPEED: float = 900.0

var _player: CharacterBody2D
var _drawing: CanvasItem
var _sprite: AnimatedSprite2D
var _shadow: Sprite2D
var _ray := PhysicsRayQueryParameters2D.new()
var _shadow_on: bool = false
var _ink: bool = true
var _squash_on: bool = false
var _ghosts_on: bool = false
var _base_scale := Vector2.ONE
var _squash: float = 0.0
## Seconds since the landing, or below 0 while there is no squash going on.
var _squash_time: float = -1.0
var _ghosts: Array[Sprite2D] = []
var _ghost_ages: Array[float] = []
var _next_ghost: int = 0
var _until_ghost: float = 0.0
var _fast_fall_speed: float = FAST_FALL_SPEED
## His drawing's place one physics frame ago: a ghost goes there, behind the drawing on screen,
## which physics interpolation draws between the last two frames.
var _last_drawing_transform := Transform2D.IDENTITY
var _sounds: PlayerSounds


## Builds the shadow, the squash and the ghosts for Player; Drawing is his visible drawing.
func setup(player: CharacterBody2D, drawing: CanvasItem) -> void:
	_player = player
	_drawing = drawing
	_sprite = drawing as AnimatedSprite2D
	if _sprite != null:
		_base_scale = _sprite.scale
	var animation := player.get_node_or_null(^"PlayerAnimation") as PlayerAnimation
	if animation != null:
		_fast_fall_speed = animation.fast_fall_speed
	_sounds = player.get_node_or_null(^"PlayerSounds") as PlayerSounds
	if _sounds != null:
		_sounds.land_played.connect(_on_landed.unbind(1))
	_make_ghosts(player)
	_shadow = Sprite2D.new()
	_shadow.name = "ProtoContactShadow"
	_shadow.texture = _make_soft_dot(Color.BLACK)
	_shadow.material = _unshaded()
	# Drawn first among his children, so behind his drawing; the rock in front hides its lower half.
	player.add_child(_shadow)
	player.move_child(_shadow, 0)
	_ray.collision_mask = player.collision_mask
	_ray.exclude = [player.get_rid()]


## Scene light on: his drawing is on Own Mask, which his main light leaves out. Off: on the world's.
func set_scene_light(on: bool, own_mask: int, world_mask: int) -> void:
	_drawing.light_mask = own_mask if on else world_mask


func set_shadow(on: bool) -> void:
	_shadow_on = on
	_shadow.visible = on


func set_squash(on: bool) -> void:
	_squash_on = on
	if not on and _sprite != null:
		_squash_time = -1.0
		_sprite.scale = _base_scale


func set_ghosts(on: bool) -> void:
	_ghosts_on = on
	if not on:
		for ghost: Sprite2D in _ghosts:
			ghost.visible = false


## Ink style: the squash and the ghosts' erosion go in steps held 1/Ink FPS s, and the ghosts get
## their ink line. Off: both run smooth.
func set_ink(on: bool) -> void:
	_ink = on
	if not _ghosts.is_empty():
		(_ghosts[0].material as ShaderMaterial).set_shader_parameter(&"ink_style", on)


func _process(delta: float) -> void:
	if _sprite == null:
		return
	var fps: float = float(ProtoContactDust.INK_FPS)
	if _squash_time >= 0.0:
		_squash_time += delta
		var position: float = _squash_time * fps
		var step: int = floori(position)
		if step >= SQUASH_STEPS.size() - 1:
			_squash_time = -1.0
			_sprite.scale = _base_scale
		else:
			var share: float = (SQUASH_STEPS[step] if _ink
					else lerpf(SQUASH_STEPS[step], SQUASH_STEPS[step + 1], position - float(step)))
			var amount: float = _squash * share
			_sprite.scale = _base_scale * Vector2(1.0 + amount, 1.0 - amount)
	for k: int in _ghosts.size():
		var ghost: Sprite2D = _ghosts[k]
		if not ghost.visible:
			continue
		_ghost_ages[k] += delta
		if _ghost_ages[k] >= GHOST_LIFETIME:
			ghost.visible = false
			continue
		var age: float = floorf(_ghost_ages[k] * fps) / fps if _ink else _ghost_ages[k]
		ghost.set_instance_shader_parameter(&"age", age / GHOST_LIFETIME)


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	if _shadow_on:
		_place_shadow()
	if _ghosts_on and _sprite != null:
		var falling_fast: bool = not _player.is_on_floor() and _player.velocity.y >= _fast_fall_speed
		_until_ghost -= delta
		if falling_fast and _until_ghost <= 0.0:
			_until_ghost = GHOST_GAP
			_leave_ghost()
	if _sprite != null:
		_last_drawing_transform = _sprite.global_transform


func _on_landed() -> void:
	if not _squash_on or _sprite == null:
		return
	var share: float = _sounds.get_last_landing_share()
	if share < SQUASH_FROM:
		return
	_squash = SQUASH_MAX * share
	_squash_time = 0.0


## A copy of his drawing as it is now, where it was a physics frame ago.
func _leave_ghost() -> void:
	var ghost: Sprite2D = _ghosts[_next_ghost]
	_ghost_ages[_next_ghost] = 0.0
	_next_ghost = (_next_ghost + 1) % _ghosts.size()
	ghost.texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	ghost.offset = _sprite.offset
	ghost.centered = _sprite.centered
	ghost.flip_h = _sprite.flip_h
	ghost.global_transform = _last_drawing_transform
	ghost.set_instance_shader_parameter(&"age", 0.0)
	ghost.visible = true


## The ghosts go just before him in his parent, so they are drawn behind him and among what he is.
func _make_ghosts(player: Node2D) -> void:
	var holder := Node2D.new()
	holder.name = "ProtoGhosts"
	# Placed by hand: drawn where they are put, not slid there.
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.get_parent().add_child(holder)
	player.get_parent().move_child(holder, player.get_index())
	var material := ShaderMaterial.new()
	material.shader = GHOST_SHADER
	material.set_shader_parameter(&"ghost_color", GHOST_COLOR)
	material.set_shader_parameter(&"noise_texture", _make_noise())
	for k: int in GHOST_COUNT:
		var ghost := Sprite2D.new()
		ghost.material = material
		ghost.visible = false
		holder.add_child(ghost)
		_ghosts.append(ghost)
		_ghost_ages.append(0.0)


## The floor under his feet, straight down, within Shadow Reach; the shadow is his child, so it
## moves with his drawing, and only its height and fade follow the floor.
func _place_shadow() -> void:
	_ray.from = _player.global_position - Vector2(0.0, SHADOW_RAY_LIFT)
	_ray.to = _player.global_position + Vector2(0.0, SHADOW_REACH)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(_ray)
	if hit.is_empty():
		_shadow.visible = false
		return
	var height: float = (hit["position"] as Vector2).y - _player.global_position.y
	var near: float = 1.0 - clampf(height / SHADOW_REACH, 0.0, 1.0)
	_shadow.visible = true
	_shadow.position = Vector2(0.0, height)
	var size: Vector2 = SHADOW_SIZE * lerpf(SHADOW_FAR_SCALE, 1.0, near)
	_shadow.scale = size / float(SHADOW_TEXTURE_SIZE)
	_shadow.modulate = Color(1.0, 1.0, 1.0, SHADOW_ALPHA * near)


func _make_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	return texture


func _make_soft_dot(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(color, 1.0), Color(color, 0.5), Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = SHADOW_TEXTURE_SIZE
	texture.height = SHADOW_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


func _unshaded() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material
