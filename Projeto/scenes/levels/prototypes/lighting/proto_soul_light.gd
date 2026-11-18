extends Node2D
## PROTOTYPE (#263): the man's trail as light leaving his body. It comes off him as wide as his body
## across his motion (his height moving sideways, his width moving up), white at the body and the
## halo colour at its edges, added to the scene so it is never grey or opaque. Its edges are flame
## tongues that roll up through the world and change every frame; it tapers as it ages, and age eats
## it along the same noise, so the tail comes apart in wisps and is gone in Lifetime s. Flakes of the
## same light come loose along it and drift up. His body keeps a faint glow of the same light, which
## grows while the trail lives, so he belongs to the light he leaves.
## Only with real momentum: fast in the air (not a hop) or a wall jump; a run kept at top speed could
## start one too, but Run Strength is 0, as on the floor it looked like a leash (kept to compare). It
## comes in over a moment and, when the momentum ends or he lands, stops growing and burns away. A
## turn sharper than Turn Angle (a wall jump, a wall or a ceiling hit in the air) starts a new ribbon
## and leaves the old one to burn away alone: as wide as his body, a ribbon bent that sharply would
## fold over itself, and the folds add up to white. A bend tighter than its half width, as two kicks
## in a chimney, narrows it to the bend's radius instead.
## A ribbon of its own mesh: his path is kept once a physics frame and drawn through a Catmull-Rom
## curve, the head where physics interpolation draws his body; each vertex carries its age and his
## momentum in its colour, and in its UV the distance he had gone and the side, so the streaks stay
## put along the ribbon (proto_soul_light.gdshader). Drawn behind him, so the head hides under him.

const SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_soul_light.gdshader")
## His body's size, in px: the ribbon is his extent across its motion.
const BODY_SIZE := Vector2(48.0, 96.0)
## The mesh reaches this many times past his body, so the flame tongues have room.
const MESH_MARGIN: float = 1.35
## A point lives Lifetime s or until he has gone Max Length px past it, whichever comes first; the
## ribbon's width follows (1 - life) to Taper Power, so the tail ends in a point.
const LIFETIME: float = 0.22
const MAX_LENGTH: float = 170.0
const TAPER_POWER: float = 0.8
## Momentum. In the air: none below Air From px/s, all of it at Air Full (a jump leaves the floor at
## ~1070 px/s, a running one at ~1220, and a fall reaches 1400). On the floor: Run Strength once he
## has run at Run Share of his top speed for Run Hold s; none, because he has one speed only, so his
## top speed kept is his walk. A wall jump: all of it for Wall Jump Hold s.
const AIR_FROM: float = 800.0
const AIR_FULL: float = 1250.0
const RUN_SHARE: float = 0.95
const RUN_HOLD: float = 0.4
const RUN_STRENGTH: float = 0.0
const WALL_JUMP_HOLD: float = 0.25
## The strength rises at most Ramp In and falls at most Ramp Out a second. A ribbon begins at Start,
## which a hop's moment of speed is too short to reach, and stops growing below Stop: so low that it
## follows his whole arc, narrowing to nothing at his body as the momentum goes, instead of stopping
## where the jump slowed and staying behind as a straight stub. Once it begins, it reaches back along
## the last History physics frames to where the momentum began (the take-off), at full strength, so
## it does not start in mid-air. The ribbon's width also follows the strength.
const RAMP_IN: float = 5.0
const RAMP_OUT: float = 6.0
const START: float = 0.3
const STOP: float = 0.02
const HISTORY: int = 16
## A point every Min Step px of his path at least; a jump of more than Teleport px in one physics
## frame cuts every ribbon (his fastest, a 1400 px/s fall, is ~23 px a frame). A turn of more than
## Turn Angle degrees from one point to the next is a hit, not his arc, which bends a few a frame.
const MIN_STEP: float = 3.0
const TURN_ANGLE: float = 45.0
const TELEPORT: float = 80.0
## The curve gets a vertex every Draw Step px. Its oldest end rounds off over Tail Cap px and its
## newest, inside his body, over Head Cap px.
const DRAW_STEP: float = 5.0
const TAIL_CAP: float = 40.0
const HEAD_CAP: float = 20.0
## Where the curve bends tighter than its half width, the half width drops to the bend's radius and
## widens back by at most Fold Slope px per px along it: then neither side folds over the other at a
## bend of up to ~125 degrees (atan of 1 / Fold Slope, twice).
const FOLD_SLOPE: float = 0.5
## The light, in the level's own pinks: a pinkish white core, as the tips of the drawn flames, and a
## light pink halo. A cool halo stood apart from the drawn cave, as if added from outside it.
const CORE := Color(1.0, 0.92, 0.96)
const HALO := Color(1.0, 0.45, 0.78)
## The flames' clock steps at the ink rate the prototype holds its drawn frames at.
const INK_FPS: float = 20.0
const NOISE_SIZE: int = 128
const NOISE_FREQUENCY: float = 0.05
const NOISE_OCTAVES: int = 3
## Flakes: one about every Flake Spacing px of his path while a ribbon grows, each living a random
## time in Flake Life s, rising Flake Rise px/s and carried back by Flake Drag of his velocity;
## Flake Size is its length and width at birth, in px.
const FLAKE_SPACING: float = 28.0
const FLAKE_LIFE := Vector2(0.3, 0.6)
const FLAKE_RISE: float = 70.0
const FLAKE_DRAG: float = 0.12
const FLAKE_SIZE := Vector2(7.0, 2.5)
const FLAKE_POOL: int = 64
## His glow: its size around his body, in px, and its alpha at rest and with full momentum.
const GLOW_SIZE := Vector2(96.0, 150.0)
const GLOW_REST: float = 0.07
const GLOW_MOVING: float = 0.12
const GLOW_TEXTURE_SIZE: int = 64

## One ribbon: his body's middle at each kept point, oldest first.
class Ribbon:
	var points := PackedVector2Array()
	## The trail's clock when each point was kept.
	var births := PackedFloat32Array()
	var strengths := PackedFloat32Array()
	## How far he had gone when each point was kept.
	var marks := PackedFloat32Array()
	var growing: bool = true

## A flake of light, drawn by the Flakes child.
class Flake:
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var age: float = 0.0
	var life: float = 0.0

var _player: Player
## From his feet to the middle of his drawing.
var _body_center := Vector2.ZERO
## His body's middle at the last two physics frames: the head is drawn between them.
var _body_before := Vector2.ZERO
var _body_now := Vector2.ZERO
var _ribbons: Array[Ribbon] = []
var _on: bool = false
var _clock: float = 0.0
## How far his body has gone so far, in px.
var _distance: float = 0.0
var _strength: float = 0.0
var _run_time: float = 0.0
var _wall_jump_left: float = 0.0
var _top_speed: float = 600.0
## His body, the clock, his distance and the momentum at each of the last History physics frames.
var _history_points := PackedVector2Array()
var _history_births := PackedFloat32Array()
var _history_marks := PackedFloat32Array()
var _history_targets := PackedFloat32Array()
var _material: ShaderMaterial
var _flakes: Array[Flake] = []
var _next_flake: int = 0
## His path since the last flake, in px.
var _since_flake: float = 0.0
var _flake_layer: Node2D
var _flake_texture: Texture2D
var _glow: Sprite2D


## Follows Player; Body Center goes from his feet to the middle of his drawing.
func setup(player: Player, body_center: Vector2) -> void:
	_player = player
	_body_center = body_center
	_top_speed = player.stats.max_run_speed
	player.wall_jumped.connect(_on_wall_jumped.unbind(2))
	# Placed by hand: drawn where its points are, not slid there.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# His physics runs first, so his body is read where move_and_slide left it.
	process_physics_priority = player.process_physics_priority + 1
	_body_now = player.global_position + body_center
	_body_before = _body_now
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"noise_texture", _make_noise())
	_material.set_shader_parameter(&"core_color", CORE)
	_material.set_shader_parameter(&"halo_color", HALO)
	material = _material
	_make_flakes()
	_make_glow(player)


func set_on(on: bool) -> void:
	_on = on
	visible = on
	_glow.visible = on
	if not on:
		clear()


## Drops every ribbon and flake at once.
func clear() -> void:
	_ribbons.clear()
	for flake: Flake in _flakes:
		flake.age = flake.life
	queue_redraw()
	_flake_layer.queue_redraw()


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var body: Vector2 = _player.global_position + _body_center
	if body.distance_to(_body_now) > TELEPORT:
		# A teleport: the trail starts again where he is now, and does not cross the gap.
		_body_before = body
		_body_now = body
		_strength = 0.0
		_forget()
		clear()
		return
	var step: float = _body_now.distance_to(body)
	_distance += step
	_body_before = _body_now
	_body_now = body
	_wall_jump_left = maxf(_wall_jump_left - delta, 0.0)
	var target: float = _target_strength(delta)
	_strength = move_toward(_strength, target, (RAMP_IN if target > _strength else RAMP_OUT) * delta)
	_remember(body, target)
	if _on:
		_grow(body, target)
		_shed_flakes(body, step)


func _process(delta: float) -> void:
	_clock += delta
	if not _on:
		return
	_age_out()
	_material.set_shader_parameter(&"clock", floorf(_clock * INK_FPS) / INK_FPS)
	_glow.modulate.a = lerpf(GLOW_REST, GLOW_MOVING, _strength)
	for flake: Flake in _flakes:
		if flake.age < flake.life:
			flake.age += delta
			flake.velocity.y -= FLAKE_RISE * delta
			flake.position += flake.velocity * delta
	queue_redraw()
	_flake_layer.queue_redraw()


func _draw() -> void:
	for ribbon: Ribbon in _ribbons:
		_draw_ribbon(ribbon)


func _on_wall_jumped() -> void:
	_wall_jump_left = WALL_JUMP_HOLD


## How strong the trail should be now; counts how long he has kept his top speed on the floor.
func _target_strength(delta: float) -> float:
	if _wall_jump_left > 0.0:
		return 1.0
	if _player.is_on_floor():
		if absf(_player.velocity.x) >= _top_speed * RUN_SHARE:
			_run_time += delta
		else:
			_run_time = 0.0
		return RUN_STRENGTH if _run_time >= RUN_HOLD else 0.0
	_run_time = 0.0
	return smoothstep(AIR_FROM, AIR_FULL, _player.velocity.length())


## Starts, grows or stops the growing ribbon by the strength, at Body. On the floor with no momentum
## (Target), his arc is over: the ribbon stops where he landed, and none begins until he has momentum
## again, though the strength takes a moment to fall.
func _grow(body: Vector2, target: float) -> void:
	var ribbon: Ribbon = _ribbons.back() if not _ribbons.is_empty() else null
	if ribbon != null and not ribbon.growing:
		ribbon = null
	var landed: bool = target == 0.0 and _player.is_on_floor()
	if ribbon == null:
		if _strength >= START and not landed:
			_begin_ribbon()
		return
	if _strength < STOP or landed:
		ribbon.growing = false
		return
	var count: int = ribbon.points.size()
	if count > 0 and ribbon.points[count - 1].distance_to(body) < MIN_STEP:
		return
	if count > 1:
		var before: Vector2 = ribbon.points[count - 1] - ribbon.points[count - 2]
		var now: Vector2 = body - ribbon.points[count - 1]
		if rad_to_deg(absf(before.angle_to(now))) > TURN_ANGLE:
			# A sharp turn: the old ribbon burns away alone; the new one starts at the corner.
			ribbon.growing = false
			var corner: Vector2 = ribbon.points[count - 1]
			ribbon = _new_ribbon()
			_keep(ribbon, corner)
	_keep(ribbon, body)


## A new ribbon from where the momentum began, among the last physics frames, to his body now, each
## point at the momentum it had; the strength jumps to the momentum now, so the head matches.
func _begin_ribbon() -> void:
	var ribbon: Ribbon = _new_ribbon()
	var last: int = _history_targets.size() - 1
	_strength = maxf(_strength, _history_targets[last])
	var first: int = last
	while first > 0 and _history_targets[first - 1] > 0.0:
		first -= 1
	for index: int in range(first, last + 1):
		ribbon.points.append(_history_points[index])
		ribbon.births.append(_history_births[index])
		ribbon.strengths.append(_history_targets[index] if index < last else _strength)
		ribbon.marks.append(_history_marks[index])


func _remember(body: Vector2, target: float) -> void:
	_history_points.append(body)
	_history_births.append(_clock)
	_history_marks.append(_distance)
	_history_targets.append(target)
	if _history_points.size() > HISTORY:
		_history_points.remove_at(0)
		_history_births.remove_at(0)
		_history_marks.remove_at(0)
		_history_targets.remove_at(0)


func _forget() -> void:
	_history_points.clear()
	_history_births.clear()
	_history_marks.clear()
	_history_targets.clear()


func _new_ribbon() -> Ribbon:
	var ribbon := Ribbon.new()
	_ribbons.append(ribbon)
	return ribbon


func _keep(ribbon: Ribbon, at: Vector2) -> void:
	ribbon.points.append(at)
	ribbon.births.append(_clock)
	ribbon.strengths.append(_strength)
	ribbon.marks.append(_distance)


## Drops the points that have lived out, from the tail, and the ribbons left with none.
func _age_out() -> void:
	for ribbon: Ribbon in _ribbons:
		var dead: int = 0
		while dead < ribbon.points.size() and _life(ribbon, dead) >= 1.0:
			dead += 1
		if dead > 0:
			ribbon.points = ribbon.points.slice(dead)
			ribbon.births = ribbon.births.slice(dead)
			ribbon.strengths = ribbon.strengths.slice(dead)
			ribbon.marks = ribbon.marks.slice(dead)
	for index: int in range(_ribbons.size() - 1, -1, -1):
		if not _ribbons[index].growing and _ribbons[index].points.is_empty():
			_ribbons.remove_at(index)


## A point's life, 0 as it is kept to 1 when it is gone: by its age, or by how far he went since.
func _life(ribbon: Ribbon, index: int) -> float:
	var by_age: float = (_clock - ribbon.births[index]) / LIFETIME
	var by_path: float = (_distance - ribbon.marks[index]) / MAX_LENGTH
	return maxf(by_age, by_path)


## His body's middle where physics interpolation draws it now, between the last two physics frames.
func _head() -> Vector2:
	return _body_before.lerp(_body_now, Engine.get_physics_interpolation_fraction())


## The ribbon through a Catmull-Rom curve, the head on his body while it grows.
func _draw_ribbon(ribbon: Ribbon) -> void:
	var points: PackedVector2Array = ribbon.points.duplicate()
	var lives := PackedFloat32Array()
	var strengths: PackedFloat32Array = ribbon.strengths.duplicate()
	var marks: PackedFloat32Array = ribbon.marks.duplicate()
	for index: int in points.size():
		lives.append(clampf(_life(ribbon, index), 0.0, 1.0))
	if points.is_empty():
		return
	if ribbon.growing:
		# The head is drawn a little behind his body's last physics place, which is usually the
		# last point kept: appended after it, the curve would fold back and draw a spike.
		var last_kept: int = points.size() - 1
		if points[last_kept] == _body_now:
			points[last_kept] = _head()
			lives[last_kept] = 0.0
			strengths[last_kept] = _strength
		else:
			points.append(_head())
			lives.append(0.0)
			strengths.append(_strength)
			marks.append(_distance)
	var count: int = points.size()
	if count < 2:
		return
	var centers := PackedVector2Array()
	var vertex_lives := PackedFloat32Array()
	var vertex_strengths := PackedFloat32Array()
	var vertex_marks := PackedFloat32Array()
	for index: int in count - 1:
		var before: Vector2 = points[maxi(index - 1, 0)]
		var after: Vector2 = points[mini(index + 2, count - 1)]
		var steps: int = maxi(1, ceili(points[index].distance_to(points[index + 1]) / DRAW_STEP))
		for step: int in steps:
			var weight: float = float(step) / float(steps)
			centers.append(points[index].cubic_interpolate(points[index + 1], before, after, weight))
			vertex_lives.append(lerpf(lives[index], lives[index + 1], weight))
			vertex_strengths.append(lerpf(strengths[index], strengths[index + 1], weight))
			vertex_marks.append(lerpf(marks[index], marks[index + 1], weight))
	centers.append(points[count - 1])
	vertex_lives.append(lives[count - 1])
	vertex_strengths.append(strengths[count - 1])
	vertex_marks.append(marks[count - 1])
	_add_ribbon(centers, vertex_lives, vertex_strengths, vertex_marks)


## A strip of triangles along Centers, his body's extent across each normal to each side, tapering
## with life; colour red = life, green = strength; UV x = distance gone / 100, UV y = side (0 or 1).
func _add_ribbon(centers: PackedVector2Array, lives: PackedFloat32Array,
		strengths: PackedFloat32Array, marks: PackedFloat32Array) -> void:
	var count: int = centers.size()
	var corners := PackedVector2Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	corners.resize(count * 2)
	colors.resize(count * 2)
	uvs.resize(count * 2)
	var last: int = count - 1
	var lengths := PackedFloat32Array()
	lengths.resize(count)
	for index: int in range(1, count):
		lengths[index] = lengths[index - 1] + centers[index].distance_to(centers[index - 1])
	var total: float = lengths[last]
	# The widest each vertex may be: its bend's radius, or a neighbour's limit plus Fold Slope of the
	# way between them, from both sides.
	var limits := PackedFloat32Array()
	limits.resize(count)
	for index: int in count:
		limits[index] = _bend_radius(centers, index)
	for index: int in range(1, count):
		limits[index] = minf(limits[index],
				limits[index - 1] + FOLD_SLOPE * (lengths[index] - lengths[index - 1]))
	for index: int in range(count - 2, -1, -1):
		limits[index] = minf(limits[index],
				limits[index + 1] + FOLD_SLOPE * (lengths[index + 1] - lengths[index]))
	for index: int in count:
		var along: Vector2 = centers[mini(index + 1, last)] - centers[maxi(index - 1, 0)]
		var normal: Vector2 = along.normalized().orthogonal()
		var extent: float = 0.5 * (absf(normal.x) * BODY_SIZE.x + absf(normal.y) * BODY_SIZE.y)
		# Both ends round off, so neither is cut square.
		var ends: float = (smoothstep(0.0, TAIL_CAP, lengths[index])
				* smoothstep(0.0, HEAD_CAP, total - lengths[index]))
		var half: float = minf(limits[index], extent * MESH_MARGIN
				* pow(1.0 - lives[index], TAPER_POWER) * sqrt(ends * strengths[index]))
		var center: Vector2 = to_local(centers[index])
		corners[index * 2] = center + normal * half
		corners[index * 2 + 1] = center - normal * half
		var color := Color(lives[index], strengths[index], 0.0, 1.0)
		colors[index * 2] = color
		colors[index * 2 + 1] = color
		uvs[index * 2] = Vector2(marks[index] / 100.0, 0.0)
		uvs[index * 2 + 1] = Vector2(marks[index] / 100.0, 1.0)
	var indices := PackedInt32Array()
	indices.resize(last * 6)
	for index: int in last:
		var left: int = index * 2
		var at: int = index * 6
		indices[at] = left
		indices[at + 1] = left + 1
		indices[at + 2] = left + 2
		indices[at + 3] = left + 1
		indices[at + 4] = left + 3
		indices[at + 5] = left + 2
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, corners, colors, uvs)


## The radius of the curve's bend at a vertex: the mean of its two segments over the angle between
## them; INF at the ends and where it runs straight.
func _bend_radius(centers: PackedVector2Array, index: int) -> float:
	if index == 0 or index == centers.size() - 1:
		return INF
	var before: Vector2 = centers[index] - centers[index - 1]
	var after: Vector2 = centers[index + 1] - centers[index]
	var angle: float = absf(before.angle_to(after))
	if is_zero_approx(angle):
		return INF
	return 0.5 * (before.length() + after.length()) / angle


## While a ribbon grows, a flake about every Flake Spacing px of his path, somewhere on his body,
## carried back a little by his velocity.
func _shed_flakes(body: Vector2, step: float) -> void:
	if _ribbons.is_empty() or not _ribbons.back().growing:
		_since_flake = 0.0
		return
	_since_flake += step
	while _since_flake >= FLAKE_SPACING:
		_since_flake -= FLAKE_SPACING
		var flake: Flake = _flakes[_next_flake]
		_next_flake = (_next_flake + 1) % _flakes.size()
		flake.position = body + Vector2(randf_range(-0.5, 0.5) * BODY_SIZE.x,
				randf_range(-0.5, 0.5) * BODY_SIZE.y)
		flake.velocity = -_player.velocity * FLAKE_DRAG + Vector2(randf_range(-30.0, 30.0),
				randf_range(-40.0, 0.0))
		flake.age = 0.0
		flake.life = randf_range(FLAKE_LIFE.x, FLAKE_LIFE.y) * _strength


func _make_flakes() -> void:
	for k: int in FLAKE_POOL:
		var flake := Flake.new()
		_flakes.append(flake)
	_flake_texture = _make_soft_dot(16)
	_flake_layer = Node2D.new()
	_flake_layer.name = "Flakes"
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_flake_layer.material = additive
	_flake_layer.draw.connect(_draw_flakes)
	add_child(_flake_layer)


## Each live flake, stretched along its motion, shrinking and fading as it ages.
func _draw_flakes() -> void:
	for flake: Flake in _flakes:
		if flake.age >= flake.life:
			continue
		var left: float = 1.0 - flake.age / flake.life
		var size: Vector2 = FLAKE_SIZE * (0.4 + 0.6 * left)
		_flake_layer.draw_set_transform(to_local(flake.position), flake.velocity.angle())
		_flake_layer.draw_texture_rect(_flake_texture, Rect2(-size * 0.5, size), false,
				Color(HALO.lerp(CORE, left), left))
	_flake_layer.draw_set_transform(Vector2.ZERO)


## A faint glow of his light behind his drawing, at the middle of his body.
func _make_glow(player: Player) -> void:
	_glow = Sprite2D.new()
	_glow.name = "SoulGlow"
	_glow.texture = _make_soft_dot(GLOW_TEXTURE_SIZE)
	_glow.scale = GLOW_SIZE / float(GLOW_TEXTURE_SIZE)
	_glow.position = _body_center
	_glow.modulate = Color(HALO.lerp(CORE, 0.4), GLOW_REST)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_glow.material = additive
	player.add_child(_glow)
	player.move_child(_glow, 0)


func _make_soft_dot(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = size
	texture.height = size
	return texture


func _make_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = NOISE_OCTAVES
	var texture := NoiseTexture2D.new()
	texture.width = NOISE_SIZE
	texture.height = NOISE_SIZE
	texture.seamless = true
	texture.noise = noise
	return texture
