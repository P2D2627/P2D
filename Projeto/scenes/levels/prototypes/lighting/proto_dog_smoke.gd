extends Node
## PROTOTYPE (#261): smoke off each dog (proto_smoke.gd): wisps rising off its back all the time, and
## a wake of puffs behind it as it runs, stronger the faster, so its movement reads in the dark
## without eyes or marks. SightReveal shows a dog through its alpha: a dog not seen leaves no smoke,
## and each puff is dimmed by its dog's alpha, so smoke left before the dog went out of sight goes
## with it. Behind the man and the dogs, never over them. Lit by the scene (the fires tint it, the
## cave's dark eats it). It carries information, so an option that reduces effects keeps it.

const ProtoSmoke := preload("res://scenes/levels/prototypes/lighting/proto_smoke.gd")
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
## Off its back: a wisp every Wisp Gap s, within Back Width Share of its half width either side of
## its middle and between Back From and Back To of its half height above it, living Wisp Lifetime s,
## Wisp Strength strong and Wisp Size the puffs' size. Close enough in time that they overlap: a lone
## small stamp hardly passes the smoke's threshold.
const WISP_GAP: float = 0.07
const BACK_WIDTH_SHARE: float = 0.9
const BACK_FROM: float = 0.6
const BACK_TO: float = 1.3
const WISP_LIFETIME: float = 0.9
const WISP_STRENGTH: float = 1.0
const WISP_SIZE: float = 0.7
## The puffs' size in px as they start and end, how fast they rise (px/s) and slow down (1/s).
const SIZE_FROM: float = 40.0
const SIZE_TO: float = 84.0
const RISE: float = 40.0
const DRAG: float = 2.0
## Only dogs within this many px of the screen smoke, so far ones cost nothing; a dog less seen than
## Seen From (SightReveal's alpha) leaves none.
const SCREEN_MARGIN: float = 200.0
const SEEN_FROM: float = 0.05
## Enough for one dog chasing at its 510 px/s (~25 puffs alive) and its wisps (~13) at once, up to a
## cap.
const STAMPS_PER_DOG: int = 40
const MAX_STAMPS: int = 240
## Thin and dense: a step lighter than the cave's darkest, so it shows where it is lit.
const EDGE_COLOR := Color(0.24, 0.17, 0.22)
const CORE_COLOR := Color(0.1, 0.07, 0.1)
const OPACITY: float = 0.85

var _dogs: Array[Demon] = []
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
	_smoke.visible = false


func set_on(on: bool) -> void:
	_on = on
	if _smoke == null:
		return
	_smoke.visible = on
	if not on:
		_smoke.clear()


func get_dog_count() -> int:
	return _dogs.size()


func _process(delta: float) -> void:
	if not _on or _smoke == null:
		return
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
		var size: float = half.x / NORMAL_HALF_SIZE.x
		_run_puffs(k, dog, rear, size)
		_until_wisp[k] -= delta
		if _until_wisp[k] <= 0.0:
			_until_wisp[k] += WISP_GAP
			var at: Vector2 = middle + Vector2(randf_range(-1.0, 1.0) * half.x * BACK_WIDTH_SHARE,
					-randf_range(BACK_FROM, BACK_TO) * half.y)
			_smoke.puff(at, dog.velocity * RUN_INHERIT, WISP_LIFETIME, WISP_STRENGTH, WISP_SIZE * size, dog)


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
