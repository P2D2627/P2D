extends Node2D
## PROTOTYPE (#261): what ties the man into the cave, each part switched by the rig.
## Scene light: his drawing leaves the light mask his own main light reaches, so his body takes the
## cave's dark, the fires, his wide fill light and the crucifix's light, not the light he carries.
## Outline: the scenery's dark ink round his drawing (proto_rim.gdshader's outline).
## Contact shadow: a soft dark ellipse on the floor under him, fainter and smaller as he rises.
## Squash: his drawing squashes as he lands, more the harder he lands, and comes back in a few held
## steps, like drawn frames: squashed, half way, a little stretched, back. The drawing's origin is on
## his feet (player.tscn), so they stay on the floor. There is no drawn landing frame yet.
## Trail: moving fast, he leaves a short wake of ash behind his body (proto_smoke.gd), one smooth
## body that erodes away; little while he walks, most in the air and as he falls, and never longer
## than Trail Max Length, so it shows his momentum and does not make him light. It can be light
## instead of ash, to compare, or light leaving his body (proto_soul_light.gd, #263).

const ProtoContactDust := preload("res://scenes/levels/prototypes/lighting/proto_contact_dust.gd")
const ProtoSmoke := preload("res://scenes/levels/prototypes/lighting/proto_smoke.gd")
const ProtoSoulLight := preload("res://scenes/levels/prototypes/lighting/proto_soul_light.gd")
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
## Trail: a stamp every Trail Spacing px along his body's path, each living Trail Lifetime s or until
## he has gone Trail Max Length px past it, whichever comes first, so the trail is never longer than
## that (by time alone it would be 270 px at 600 px/s, and 630 falling at 1400). Each starts Trail
## Size From px wide and ends Trail Size To, rising Trail Rise px/s and carrying Trail Inherit of his
## velocity, slowed by Trail Drag (1/s).
const TRAIL_SPACING: float = 8.0
const TRAIL_LIFETIME: float = 0.45
const TRAIL_MAX_LENGTH: float = 180.0
const TRAIL_SIZE_FROM: float = 30.0
const TRAIL_SIZE_TO: float = 54.0
const TRAIL_RISE: float = 25.0
const TRAIL_INHERIT: float = 0.1
const TRAIL_DRAG: float = 3.0
## How strong it is: on the floor, nothing below Trail Run From px/s and Trail Floor Share at Trail
## Run Full; in the air, nothing below Trail Air From px/s, all of it falling at Fast Fall Speed, and
## at most Trail Air Share otherwise (a jump's take-off is faster than that, but it is no fall).
const TRAIL_RUN_FROM: float = 150.0
const TRAIL_RUN_FULL: float = 600.0
const TRAIL_FLOOR_SHARE: float = 0.45
const TRAIL_AIR_FROM: float = 200.0
const TRAIL_AIR_SHARE: float = 0.85
## Below this strength no stamp is left. A jump of more than Trail Jump px in one physics frame is a
## teleport, and the trail does not cross it: his fastest, a 1400 px/s fall, is ~23 px a frame; the
## rig's debug moves and his first frame jump further (a respawn reloads the level).
const TRAIL_MIN_STRENGTH: float = 0.05
const TRAIL_JUMP: float = 80.0
const TRAIL_MAX_PER_FRAME: int = 16
const TRAIL_POOL: int = 48
## Ash: lighter than the cave's dark, so it shows, and lit by the scene, its dense middle a little
## lighter than its edge, as smoke that catches the light; light: the fires' warm.
const ASH_EDGE := Color(0.48, 0.43, 0.46)
const ASH_CORE := Color(0.58, 0.53, 0.56)
const ASH_OPACITY: float = 0.55
const LIGHT_EDGE := Color(0.95, 0.62, 0.35)
const LIGHT_CORE := Color(1.0, 0.85, 0.62)
const LIGHT_OPACITY: float = 0.45
## When the drawing braces for the landing (PlayerAnimation's Fast Fall Speed): the trail at full.
const FAST_FALL_SPEED: float = 900.0

var _player: CharacterBody2D
var _drawing: CanvasItem
var _sprite: AnimatedSprite2D
var _shadow: Sprite2D
var _ray := PhysicsRayQueryParameters2D.new()
var _shadow_on: bool = false
var _ink: bool = true
var _squash_on: bool = false
var _trail_on: bool = false
var _base_scale := Vector2.ONE
var _squash: float = 0.0
## Seconds since the landing, or below 0 while there is no squash going on.
var _squash_time: float = -1.0
var _fast_fall_speed: float = FAST_FALL_SPEED
var _trail: ProtoSmoke
var _soul: ProtoSoulLight
## From his feet to the middle of his drawing.
var _body_center := Vector2.ZERO
## His body's middle at the last two physics frames: the trail's head is drawn between them, where
## physics interpolation draws his drawing.
var _body_before := Vector2.ZERO
var _body_now := Vector2.ZERO
var _last_stamp := Vector2.ZERO
## Where the trail's head was drawn last frame: how far he went since adds to the trail's distance.
var _last_head := Vector2.ZERO
var _trail_strength: float = 0.0
var _sounds: PlayerSounds


## Builds the shadow, the squash and the trail for Player; Drawing is his visible drawing.
func setup(player: CharacterBody2D, drawing: CanvasItem) -> void:
	_player = player
	_drawing = drawing
	_sprite = drawing as AnimatedSprite2D
	if _sprite != null:
		_base_scale = _sprite.scale
		_body_center = _sprite.position + _sprite.offset * _sprite.scale
	var animation := player.get_node_or_null(^"PlayerAnimation") as PlayerAnimation
	if animation != null:
		_fast_fall_speed = animation.fast_fall_speed
	_sounds = player.get_node_or_null(^"PlayerSounds") as PlayerSounds
	if _sounds != null:
		_sounds.land_played.connect(_on_landed.unbind(1))
	_make_trail(player)
	# His physics runs first, so his body is read where move_and_slide left it.
	process_physics_priority = player.process_physics_priority + 1
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
	# The ash stays on the world's mask, lit by the light he carries too: by the fires alone it is
	# about the tone of the lit rock and is lost against it (seen in recordings); with his light it
	# reads, and it stayed darker than his body.
	_trail.light_mask = world_mask
	# The light leaving his body is unshaded and added: no mask to follow.


func set_shadow(on: bool) -> void:
	_shadow_on = on
	_shadow.visible = on


func set_squash(on: bool) -> void:
	_squash_on = on
	if not on and _sprite != null:
		_squash_time = -1.0
		_sprite.scale = _base_scale


## The trail on or off; Light: light instead of ash.
func set_trail(on: bool, light: bool) -> void:
	if on and not _trail_on:
		_last_stamp = _head()
		_last_head = _last_stamp
	_trail_on = on
	_trail.visible = on
	_trail.set_look(ProtoSmoke.Look.LIGHT if light else ProtoSmoke.Look.ASH)
	if not on:
		_trail.clear()


## The trail as light leaving his body, with his faint glow, on or off.
func set_soul_trail(on: bool) -> void:
	_soul.set_on(on)


## Ink style: the squash goes in steps held 1/Ink FPS s. Off: smooth. The trail is always smooth.
func set_ink(on: bool) -> void:
	_ink = on


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
	if _trail_on:
		_emit_trail()


func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	if _shadow_on:
		_place_shadow()
	var body: Vector2 = _player.global_position + _body_center
	if body.distance_to(_body_now) > TRAIL_JUMP:
		# A teleport: the trail starts again where he is now, and does not cross the gap.
		_body_before = body
		_last_stamp = body
		_last_head = body
		_trail.clear()
	else:
		_body_before = _body_now
	_body_now = body
	_trail_strength = _trail_strength_now()


func _on_landed() -> void:
	if not _squash_on or _sprite == null:
		return
	var share: float = _sounds.get_last_landing_share()
	if share < SQUASH_FROM:
		return
	_squash = SQUASH_MAX * share
	_squash_time = 0.0


## Stamps along his body's path since the last one, up to where his drawing is drawn now. The
## trail's distance grows by how far the head went, so the stamps behind him age by it too.
func _emit_trail() -> void:
	var head: Vector2 = _head()
	_trail.distance += _last_head.distance_to(head)
	_last_head = head
	if _trail_strength < TRAIL_MIN_STRENGTH:
		_last_stamp = head
		return
	var inherited: Vector2 = _player.velocity * TRAIL_INHERIT
	var left: int = TRAIL_MAX_PER_FRAME
	while left > 0 and _last_stamp.distance_to(head) >= TRAIL_SPACING:
		_last_stamp = _last_stamp.move_toward(head, TRAIL_SPACING)
		_trail.puff(_last_stamp, inherited, TRAIL_LIFETIME, _trail_strength, 1.0, null,
				_last_stamp.distance_to(head))
		left -= 1
	if left == 0:
		_last_stamp = head


## His body's middle where physics interpolation draws it now, between the last two physics frames.
func _head() -> Vector2:
	return _body_before.lerp(_body_now, Engine.get_physics_interpolation_fraction())


## On the floor, by how fast he runs, and never full; in the air, by how fast he falls, full when he
## falls as fast as the drawing braces for the landing, and up to Trail Air Share by his speed.
func _trail_strength_now() -> float:
	if _player.is_on_floor():
		return smoothstep(TRAIL_RUN_FROM, TRAIL_RUN_FULL, absf(_player.velocity.x)) * TRAIL_FLOOR_SHARE
	var falling: float = smoothstep(TRAIL_AIR_FROM, _fast_fall_speed, _player.velocity.y)
	var moving: float = smoothstep(TRAIL_AIR_FROM, _fast_fall_speed, _player.velocity.length())
	return maxf(falling, moving * TRAIL_AIR_SHARE)


## The trail goes just before him in his parent, so it is drawn behind him and among what he is.
func _make_trail(player: Node2D) -> void:
	_trail = ProtoSmoke.new()
	_trail.name = "ProtoTrail"
	_trail.size_from = TRAIL_SIZE_FROM
	_trail.size_to = TRAIL_SIZE_TO
	_trail.rise = TRAIL_RISE
	_trail.drag = TRAIL_DRAG
	_trail.trail_length = TRAIL_MAX_LENGTH
	player.get_parent().add_child(_trail)
	player.get_parent().move_child(_trail, player.get_index())
	_trail.setup(TRAIL_POOL, ASH_EDGE, ASH_CORE, ASH_OPACITY)
	_trail.set_light_colors(LIGHT_EDGE, LIGHT_CORE, LIGHT_OPACITY)
	_trail.visible = false
	_soul = ProtoSoulLight.new()
	_soul.name = "ProtoSoulLight"
	player.get_parent().add_child(_soul)
	player.get_parent().move_child(_soul, player.get_index())
	_soul.setup(player as Player, _body_center)
	_soul.set_on(false)


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
