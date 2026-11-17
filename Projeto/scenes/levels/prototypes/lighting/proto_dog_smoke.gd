extends Node
## PROTOTYPE (#261, #263): each dog as it is drawn, with now and then a flake of ash or an ember
## rising off its back, in the effects' ink (held drawings at the man's dust's rate, no glow). The
## other ways tried are kept, off: the skin's boil in proto_rim.gdshader (Boil Amount), the wisps of
## vapour off its back (proto_smoke.gd's light look, Vapour On) and the wake of puffs a running dog
## left (#261, Wake On). SightReveal shows a dog through its alpha: a dog not seen leaves no ash,
## and each flake is dimmed by its dog's alpha, so what it left before it went out of sight goes
## with it. Behind the man and the dogs, never over them.

const ProtoSmoke := preload("res://scenes/levels/prototypes/lighting/proto_smoke.gd")
const RIM_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_rim.gdshader")
## The skin's boil (proto_rim.gdshader's Boil Amount): off. Its bubbles read as pimples and its
## boiling line as the fires' drawings, on the dogs alone of everything in the game. Its clock steps
## Boil Drawings Per S, and each dog keeps its own seed, should it come back.
const BOIL_AMOUNT: float = 0.0
const BOIL_DRAWINGS_PER_S: float = 12.0
## The effects' ink rate (proto_contact_dust.gd's): the flakes move in held drawings at it.
const INK_FPS: float = 20.0
## The wake of puffs behind a running dog, from #261: off, the boil is meant to be light.
const WAKE_ON: bool = false
## The wisps of vapour off its back: off. Drawn behind the dog, only what passed its outline showed,
## and in play they read as the floor burning, not the dog.
const VAPOUR_ON: bool = false
## The sizes below are for the normal dog, whose body (its CollisionShape2D) is this half size; a
## bigger dog scales them by its body's width over this one's, so its smoke keeps to its body.
const NORMAL_HALF_SIZE := Vector2(56.0, 28.0)
const SHAPE_PATH := ^"CollisionShape2D"
## Running: a puff every Run Spacing px its rear travels; the rear is Rear Share of its half width
## behind its middle, up to Run Spread Share of its half height above or below; none below Run From
## px/s and full strength at Run Full; each lives Run Lifetime s and carries Run Inherit of its
## velocity.
const REAR_SHARE: float = 1.0
const RUN_SPACING: float = 14.0
const RUN_SPREAD_SHARE: float = 0.4
const RUN_FROM: float = 60.0
const RUN_FULL: float = 300.0
const RUN_LIFETIME: float = 0.7
const RUN_INHERIT: float = 0.25
const RUN_MIN_STRENGTH: float = 0.05
const MAX_PER_FRAME: int = 8
## Off its back: a wisp every Wisp Gap s, from a point on its back (Back Start to Back End, Back From
## to Back To), living Wisp Lifetime s, Wisp Strength strong and Wisp Size the puffs' size: small
## and close together, so they rise in threads of vapour and not in discs, and short, so the vapour
## stays a touch and never a cloud over it.
const WISP_GAP: float = 0.1
## Where ash and vapour leave its back: from Back Start to Back End of its half width behind the
## middle of its body, towards its rear, and from Back From to Back To of its half height above it.
## Measured on the normal dog (17/11), its body's middle sits low, by the legs: the back runs from
## the middle to 51 px behind it (0.9 half widths), its top line 76 to 83 px above it (2.7 to 3 half
## heights); the head and neck in front stand higher, the tail is behind, and in front of the chest
## there is only air. A point a little under the top line is inside the drawing, which hides it, so
## each flake shows only once it rises out of the back. Spread over the whole width, ash started in
## the air before the chest; from 0.7 to 1 half height, out of the belly, it read as coming from below.
const BACK_START: float = 0.0
const BACK_END: float = 0.9
const BACK_FROM: float = 2.35
const BACK_TO: float = 2.6
const WISP_LIFETIME: float = 0.5
const WISP_STRENGTH: float = 1.0
const WISP_SIZE: float = 0.3
## The puffs' size in px as they start and end, how fast they rise (px/s) and slow down (1/s): with
## the drag, a wisp rises at most Rise / Drag px, about a third of the dog's height.
const SIZE_FROM: float = 40.0
const SIZE_TO: float = 84.0
const RISE: float = 55.0
const DRAG: float = 2.0
## Ash: a flake off its back about every Flake Gap s (a third more or less, at random), rising
## Flake Rise px/s and swaying Flake Sway px, Flake Size px long, gone in Flake Lifetime s. Most are
## the scenery's dark ink and fade; Ember Share of them are embers in the fires' light pink, which
## shrink to nothing instead. A sliver, never a soft round: the effects' ink.
const FLAKE_GAP: float = 0.25
const FLAKE_RISE: float = 45.0
const FLAKE_SWAY: float = 6.0
const FLAKE_SIZE: float = 7.0
## A flake's width either side of its length, as a share of half its length: a sliver with body
## (7 x 3 px); a thin triangle, 6 x 1.2 px, did not show.
const FLAKE_WIDTH_SHARE: float = 0.45
const FLAKE_LIFETIME := Vector2(0.5, 0.8)
## Near black, a touch of the scenery's ink: a stronger magenta read as purple, not ash.
const FLAKE_COLOR := Color(0.06, 0.02, 0.045)
## Few: half pink read as purple specks over the dog.
const EMBER_SHARE: float = 0.15
const EMBER_COLOR := Color(1.0, 0.55, 0.8)
const FLAKE_POOL: int = 48
## Only dogs within this many px of the screen smoke, so far ones cost nothing; a dog less seen than
## Seen From (SightReveal's alpha) leaves none.
const SCREEN_MARGIN: float = 200.0
const SEEN_FROM: float = 0.05
## Enough for one dog chasing at its 510 px/s (~25 puffs alive) and its wisps (~13) at once, up to a
## cap.
const STAMPS_PER_DOG: int = 40
const MAX_STAMPS: int = 240
## Vapour, added to the scene: hot pink where it thins, pale pink where it is dense (by the body),
## Opacity of it: the dog's own colour, lighter. Darker or fainter, it read as dull discs on the
## cave.
const EDGE_COLOR := Color(1.0, 0.3, 0.68)
const CORE_COLOR := Color(1.0, 0.78, 0.93)
const OPACITY: float = 0.75


## One flake of ash: where it came off, how old it is and how long it lives, its sway's phase,
## whether it is an ember, and the dog whose alpha it takes.
class Flake:
	var start := Vector2.ZERO
	var age: float = 1.0
	var life: float = 0.0
	var phase: float = 0.0
	var ember: bool = false
	var source: CanvasItem


var _dogs: Array[Demon] = []
## Each dog's drawing material (the rim shader's; null if it has none) and its boil's seed.
var _materials: Array[ShaderMaterial] = []
var _seeds := PackedFloat32Array()
var _until_flake := PackedFloat32Array()
var _clock: float = 0.0
var _drawing: int = -1
var _flakes: Array[Flake] = []
var _next_flake: int = 0
var _flake_layer: Node2D
## Each dog's body (its middle) and half size, and its rear where its last puff was left.
var _bodies: Array[Node2D] = []
var _halves: Array[Vector2] = []
var _rears: Array[Vector2] = []
var _until_wisp: Array[float] = []
var _smoke: ProtoSmoke
var _on: bool = false


## One smoke for all Dogs, just before Player in his parent: the dogs come after him, so the smoke is
## drawn behind him and them, and among what they are.
func setup(dogs: Array[Demon], player: Node2D) -> void:
	_dogs = dogs
	for dog: Demon in dogs:
		var shape := dog.get_node_or_null(SHAPE_PATH) as CollisionShape2D
		var body: Node2D = shape if shape != null else dog
		var half: Vector2 = NORMAL_HALF_SIZE
		if shape != null and shape.shape is RectangleShape2D:
			half = (shape.shape as RectangleShape2D).size * 0.5 * shape.global_scale.abs()
		_bodies.append(body)
		_halves.append(half)
		_rears.append(body.global_position)
		_until_wisp.append(randf() * WISP_GAP)
		_until_flake.append(randf() * FLAKE_GAP)
		_materials.append(_drawing_material(dog))
		_seeds.append(randf() * 100.0)
	if dogs.is_empty():
		return
	_smoke = ProtoSmoke.new()
	_smoke.name = "ProtoDogSmoke"
	_smoke.size_from = SIZE_FROM
	_smoke.size_to = SIZE_TO
	_smoke.rise = RISE
	_smoke.drag = DRAG
	player.get_parent().add_child(_smoke)
	player.get_parent().move_child(_smoke, player.get_index())
	_smoke.setup(mini(STAMPS_PER_DOG * dogs.size(), MAX_STAMPS), EDGE_COLOR, CORE_COLOR, OPACITY)
	_smoke.set_look(ProtoSmoke.Look.LIGHT)
	_smoke.visible = false
	# The ash over the vapour, still behind the man and the dogs.
	_flake_layer = Node2D.new()
	_flake_layer.name = "ProtoDogAsh"
	player.get_parent().add_child(_flake_layer)
	player.get_parent().move_child(_flake_layer, player.get_index())
	_flake_layer.draw.connect(_draw_flakes)
	_flake_layer.visible = false
	# Unshaded: lit by the scene, the cave's dark ate even the embers.
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_flake_layer.material = unlit
	for i: int in FLAKE_POOL:
		_flakes.append(Flake.new())


## Also sets each dog's boil, after the rig has given its drawing the rim shader.
func set_on(on: bool) -> void:
	_on = on
	for k: int in _materials.size():
		if _materials[k] != null:
			_materials[k].set_shader_parameter(&"boil_amount", BOIL_AMOUNT if on else 0.0)
			_materials[k].set_shader_parameter(&"boil_seed", _seeds[k])
	_drawing = -1
	if _smoke == null:
		return
	_smoke.visible = on
	_flake_layer.visible = on
	if not on:
		_smoke.clear()
		for flake: Flake in _flakes:
			flake.age = flake.life


func get_dog_count() -> int:
	return _dogs.size()


func _process(delta: float) -> void:
	if not _on or _smoke == null:
		return
	_clock += delta
	var drawing: int = floori(_clock * BOIL_DRAWINGS_PER_S)
	var new_drawing: bool = drawing != _drawing
	_drawing = drawing
	var screen: Rect2 = _screen_in_world().grow(SCREEN_MARGIN)
	for k: int in _dogs.size():
		var dog: Demon = _dogs[k]
		if not is_instance_valid(dog) or not dog.is_visible_in_tree():
			continue
		var half: Vector2 = _halves[k]
		var middle: Vector2 = _bodies[k].global_position
		var rear: Vector2 = middle - Vector2(signf(dog.velocity.x) * half.x * REAR_SHARE, 0.0)
		if dog.modulate.a < SEEN_FROM or not screen.has_point(middle):
			_rears[k] = rear
			continue
		# Only the dogs in view step their boil: one call a drawing each.
		if new_drawing and BOIL_AMOUNT > 0.0 and _materials[k] != null:
			_materials[k].set_shader_parameter(&"boil_clock", drawing / BOIL_DRAWINGS_PER_S)
		var size: float = half.x / NORMAL_HALF_SIZE.x
		if WAKE_ON:
			_run_puffs(k, dog, rear, size)
		_until_flake[k] -= delta
		if _until_flake[k] <= 0.0:
			_until_flake[k] += FLAKE_GAP * randf_range(0.67, 1.33)
			_shed_flake(_back_point(dog, middle, half), dog)
		_until_wisp[k] -= delta
		if VAPOUR_ON and _until_wisp[k] <= 0.0:
			_until_wisp[k] += WISP_GAP
			_smoke.puff(_back_point(dog, middle, half), dog.velocity * RUN_INHERIT, WISP_LIFETIME,
					WISP_STRENGTH, WISP_SIZE * size, dog)
	for flake: Flake in _flakes:
		if flake.age < flake.life:
			flake.age += delta
	_flake_layer.queue_redraw()


## A point at random on Dog's back, its body's middle at Middle and its half size Half: from the
## middle towards its rear, the way it does not face, just under the top line.
static func _back_point(dog: Demon, middle: Vector2, half: Vector2) -> Vector2:
	var rear: float = -signf(dog.get_facing())
	return middle + Vector2(rear * randf_range(BACK_START, BACK_END) * half.x,
			-randf_range(BACK_FROM, BACK_TO) * half.y)


## A flake of ash off At, from the pool, dimmed by Dog's alpha.
func _shed_flake(at: Vector2, dog: Demon) -> void:
	var flake: Flake = _flakes[_next_flake]
	_next_flake = (_next_flake + 1) % _flakes.size()
	flake.start = at
	flake.age = 0.0
	flake.life = randf_range(FLAKE_LIFETIME.x, FLAKE_LIFETIME.y)
	flake.phase = randf() * TAU
	flake.ember = randf() < EMBER_SHARE
	flake.source = dog


## Each live flake as a small sliver, turning and swaying as it rises, in held drawings: ash holding
## its black and fading only near the end (half see-through black over the lit rock reads purple),
## an ember shrinking with age, both dimmed by their dog's alpha.
func _draw_flakes() -> void:
	for flake: Flake in _flakes:
		if flake.age >= flake.life or not is_instance_valid(flake.source):
			continue
		var held: float = floorf(flake.age * INK_FPS) / INK_FPS
		var gone: float = held / flake.life
		var at: Vector2 = _flake_layer.to_local(flake.start + Vector2(
				sin(flake.phase + held * 5.0) * FLAKE_SWAY, -FLAKE_RISE * held))
		var length: float = FLAKE_SIZE * (1.0 - gone if flake.ember else 1.0)
		var tip := Vector2.from_angle(flake.phase + held * 3.0) * length * 0.5
		var side: Vector2 = tip.orthogonal() * FLAKE_WIDTH_SHARE
		var alpha: float = flake.source.modulate.a * (1.0 if flake.ember else 1.0 - gone * gone)
		# A diamond straight to the GPU: draw_colored_polygon triangulates, and fails on one so small.
		var color := Color(EMBER_COLOR if flake.ember else FLAKE_COLOR, alpha)
		_flake_layer.draw_primitive(PackedVector2Array([at - tip, at + side, at + tip, at - side]),
				PackedColorArray([color, color, color, color]), PackedVector2Array())


## The material of Dog's drawing, the one SinkingDrawing gave it and the rig turns into the rim
## shader; null if it has none.
static func _drawing_material(dog: Demon) -> ShaderMaterial:
	for node: Node in dog.find_children("*", "CanvasItem", true, false):
		var drawing_material := (node as CanvasItem).material as ShaderMaterial
		if drawing_material != null and (drawing_material.shader == SinkingDrawing.SHADER
				or drawing_material.shader == RIM_SHADER):
			return drawing_material
	return null


## Puffs along the path of Dog's rear since its last one, Size times the normal dog's; a rear that
## jumped (the dog turned round) starts again where it is.
func _run_puffs(k: int, dog: Demon, rear: Vector2, size: float) -> void:
	var strength: float = smoothstep(RUN_FROM, RUN_FULL, absf(dog.velocity.x))
	var half: Vector2 = _halves[k]
	if strength < RUN_MIN_STRENGTH or _rears[k].distance_to(rear) > half.x * REAR_SHARE:
		_rears[k] = rear
		return
	var spacing: float = RUN_SPACING * size
	var left: int = MAX_PER_FRAME
	while left > 0 and _rears[k].distance_to(rear) >= spacing:
		_rears[k] = _rears[k].move_toward(rear, spacing)
		var spread: float = half.y * RUN_SPREAD_SHARE
		var at: Vector2 = _rears[k] + Vector2(0.0, randf_range(-spread, spread))
		_smoke.puff(at, dog.velocity * RUN_INHERIT, RUN_LIFETIME, strength, size, dog)
		left -= 1
	if left == 0:
		_rears[k] = rear


## What the camera shows, in the dogs' world.
func _screen_in_world() -> Rect2:
	var viewport: Viewport = _smoke.get_viewport()
	return _smoke.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
