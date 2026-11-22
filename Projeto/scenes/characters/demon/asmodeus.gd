class_name Asmodeus
extends Node2D

## Asmodeus, the boss of Lust, drawn with her figure from the visual novel: she never fights. The level
## calls talk() with a cue of lust.dialogue, at the start of a phase, when his deaths bring an offer
## or at the end of the level, and she appears, talks and goes. While she talks the man stands
## still, with no run, no jump and no crucifix, as with Velvet; he moves again on the physics frame
## after her last line, so the press that closed it does not make him jump. What Stills names (the
## dogs) stands still while she talks, so nothing bites the man she holds. When she talks is up to
## the level's AsmodeusDirector. appear_at() puts her
## next to where he is, for the offer that waits at the entrance of a zone: on his floor, in front
## of him if there is room and behind him if not, the two turned to face each other. Only Visible While
## Talking off keeps her on screen between talks. The level's TalkFraming shows her talks as a scene; with
## Centres Camera on, she only glides the camera to the two instead. She never decides what happens after a talk: the
## lines accept or refuse through Offers, and whoever called talk() hears talk_ended.

## She started talking from cue.
signal talk_started(cue: String)
## The talk from cue is over, and the man can move again.
signal talk_ended(cue: String)

## Name of her change to the man's movement, and of what keeps his crucifix down, while she talks.
const SOURCE: StringName = &"asmodeus"
## Every how many px the floor is looked for on the way from the man to her: half a tile, so no
## gap of a tile goes unseen.
const FLOOR_SAMPLE: float = 24.0
## How far above the floor her body's room is looked at, so the floor itself is not in it.
const BODY_LIFT: float = 2.0

## The man she talks to.
@export var player: Player
## The man's crucifix, kept down while she talks; empty takes the one under Player.
@export var crucifix: Crucifix
@export var dialogue_resource: DialogueResource
## The balloon her lines show in.
@export var balloon_scene: PackedScene
## Advances the lines; held, skips them up to the next answers.
@export var next_action: StringName = &"jump"
## Whether she shows only while she talks, as if she came and went.
@export var visible_while_talking_only: bool = true
## What stands still while she talks, as the level's dogs, so none bites the man she holds: each
## one is switched off, its children too, and back on after.
@export var stills: Array[Node] = []
@export_group("Appearing")
## How far from the man she stands when appear_at() puts her next to him.
@export_range(60.0, 600.0, 10.0, "suffix:px") var appear_distance: float = 180.0
## The nearest she comes when Appear Distance has no room, on a small ledge: she tries nearer and
## nearer on one side, by Distance Step, before the other side.
@export_range(60.0, 600.0, 10.0, "suffix:px") var min_appear_distance: float = 90.0
## How much nearer each try is.
@export_range(10.0, 120.0, 5.0, "suffix:px") var distance_step: float = 30.0
## How far above or below his feet the floor under her, and under the way to her, may be.
@export_range(0.0, 192.0, 4.0, "suffix:px") var max_floor_step: float = 48.0
## The room her body takes, with her feet in the middle of its bottom edge: nothing of Wall Layers
## may be in it.
@export var body_size: Vector2 = Vector2(70.0, 140.0)
## What she can stand on: the world's rock only, never a platform (one-way or collapsing), and
## nowhere the man stands on one.
@export_flags_2d_physics var floor_layers: int = 1
## What she cannot stand inside nor talk through.
@export_flags_2d_physics var wall_layers: int = 1
## Groups of areas she never stands in, as the brambles (LethalSpikes) and the hazards. They are on
## no collision layer, so they are looked for by group.
@export var danger_groups: Array[StringName] = [&"lethal_spikes", &"hazards"]
## How much wider than her body, on each side, the room kept clear of them is: brambles are drawn
## wider than the part that kills.
@export_range(0.0, 96.0, 4.0, "suffix:px") var danger_margin: float = 24.0
## Whether asmodeus.png faces right as drawn; she is turned to face the man from it. It faces left:
## before she turned, she always stood on his right.
@export var art_faces_right: bool = false
@export_group("Camera while talking")
## Off: the level's TalkFraming shows her talks as a scene, with bars, a closer shot and the man shielded.
## On: the camera only glides to the middle of the two (Centre Time, Centre Height), as before #284, and
## TalkFraming stays out of her talks.
@export var centres_camera: bool = false
## Seconds the camera takes to glide to the middle of the two when she starts talking.
@export_range(0.0, 2.0, 0.05, "suffix:s") var centre_time: float = 0.5
## How far above their feet the middle of the screen goes: about the middle of their bodies.
@export_range(0.0, 300.0, 5.0, "suffix:px") var centre_height: float = 80.0

var _talking_cue: String = ""
## The camera she holds while she talks, as a cutscene would; null when none.
var _camera: GameCamera
var _camera_glide: Tween
## The process mode each of Stills had before she talked.
var _modes_before: Dictionary[Node, ProcessMode] = {}
## No run and no jump while she talks.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	assert(player != null, "Asmodeus: assign the man to Player.")
	assert(dialogue_resource != null, "Asmodeus: assign lust.dialogue to Dialogue Resource.")
	assert(balloon_scene != null, "Asmodeus: assign the balloon's scene to Balloon Scene.")
	if crucifix == null:
		crucifix = player.get_node_or_null(^"Crucifix") as Crucifix
	if visible_while_talking_only:
		hide()


func is_talking() -> bool:
	return not _talking_cue.is_empty()


## The cue she is talking from; empty when she is not talking.
func get_talking_cue() -> String:
	return _talking_cue


## Her drawing, for what frames her, as the camera in a talk.
func get_figure() -> Node2D:
	return _sprite


## Whether her talks are shown by her own camera glide (Centres Camera) rather than by TalkFraming.
func frames_its_own_talks() -> bool:
	return centres_camera


## Whether find_spot() has a spot for her next to the man whose feet are at point, as he faces now:
## her director waits for it, so appear_at() never needs its fallback. From the physics step.
func can_appear_next_to(point: Vector2) -> bool:
	return find_spot(get_world_2d().direct_space_state, point, player.get_facing()).is_finite()


## Puts her next to the man whose feet are at point, as find_spot() says, and turns the two to
## face each other. With no spot, she stands in front of him at his height, as before, and warns.
## Call it from the physics step: the physics queries are locked while areas report a body.
func appear_at(point: Vector2) -> void:
	var facing: float = player.get_facing()
	var spot: Vector2 = find_spot(get_world_2d().direct_space_state, point, facing)
	if not spot.is_finite():
		push_warning("Asmodeus: no floor with room next to %s; she stands in front, at his height."
				% point)
		spot = point + Vector2(facing * appear_distance, 0.0)
	global_position = spot
	face(point.x - spot.x)
	player.face(spot.x - point.x)


## Where she stands to talk to a man whose feet are at feet and who faces facing (1 right, -1
## left): Appear Distance in front of him if that spot has room, then nearer, down to Min Appear
## Distance, then the same behind him; Vector2.INF if none has. A spot has room when it has a floor
## within Max Floor Step of his feet, and so does all the way to it, her body fits there, and no
## wall stands between the two. Her feet go on that floor.
func find_spot(space: PhysicsDirectSpaceState2D, feet: Vector2, facing: float) -> Vector2:
	var side: float = 1.0 if facing >= 0.0 else -1.0
	for direction: float in [side, -side]:
		var distance: float = appear_distance
		while true:
			var spot: Vector2 = _spot_on_side(space, feet, direction * distance)
			if spot.is_finite():
				return spot
			if distance <= min_appear_distance:
				break
			distance = maxf(distance - distance_step, min_appear_distance)
	return Vector2.INF


## Turns her drawing to the side of direction (positive right); 0 leaves it.
func face(direction: float) -> void:
	if direction != 0.0:
		_sprite.flip_h = (direction > 0.0) != art_faces_right


## She talks from cue. Nothing happens while she is already talking.
func talk(cue: String) -> void:
	if is_talking():
		return
	_talking_cue = cue
	show()
	if centres_camera:
		_centre_the_camera()
	player.add_movement_modifier(SOURCE, _modifier)
	player.hold_still()
	if is_instance_valid(crucifix):
		crucifix.block(SOURCE)
	_still_the_stills()
	var balloon: DialogueBalloon = balloon_scene.instantiate()
	balloon.next_action = next_action
	balloon.skip_action = next_action
	balloon.tree_exited.connect(_on_balloon_tree_exited)
	add_child(balloon)
	balloon.start(dialogue_resource, cue)
	talk_started.emit(cue)


## The balloon frees itself after the last line. The man moves again on the next physics frame,
## so the press of Jump that closed it does not also make him jump.
func _on_balloon_tree_exited() -> void:
	# The level going away takes the balloon with it: nothing to let go of then.
	if not is_inside_tree() or is_queued_for_deletion():
		return
	await get_tree().physics_frame
	if not is_instance_valid(player):
		return
	player.remove_movement_modifier(SOURCE)
	player.let_go()
	if is_instance_valid(crucifix):
		crucifix.unblock(SOURCE)
	_wake_the_stills()
	var cue: String = _talking_cue
	_talking_cue = ""
	if visible_while_talking_only:
		hide()
	# Before talk_ended, so a cutscene the end starts takes the camera after her.
	_let_the_camera_go()
	talk_ended.emit(cue)


## The spot reach px from feet (negative to the left), as find_spot() asks; Vector2.INF if it has
## no room.
func _spot_on_side(space: PhysicsDirectSpaceState2D, feet: Vector2, reach: float) -> Vector2:
	var x: float = feet.x + reach
	var floor_y: float = _floor_under(space, x, feet.y)
	if not is_finite(floor_y):
		return Vector2.INF
	var direction: float = signf(reach)
	var walked: float = FLOOR_SAMPLE
	while walked < absf(reach):
		if not is_finite(_floor_under(space, feet.x + direction * walked, feet.y)):
			return Vector2.INF
		walked += FLOOR_SAMPLE
	var spot: Vector2 = Vector2(x, floor_y)
	var room: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = body_size
	room.shape = shape
	room.transform = Transform2D(0.0, spot - Vector2(0.0, BODY_LIFT + body_size.y / 2.0))
	room.collision_mask = wall_layers
	if not space.intersect_shape(room, 1).is_empty():
		return Vector2.INF
	var clear: Rect2 = Rect2(spot - Vector2(body_size.x / 2.0, body_size.y + BODY_LIFT),
			body_size).grow_individual(danger_margin, 0.0, danger_margin, BODY_LIFT)
	if _touches_danger(clear):
		return Vector2.INF
	var chest: Vector2 = Vector2(0.0, -body_size.y / 2.0)
	var sight: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(feet + chest,
			spot + chest, wall_layers)
	if not space.intersect_ray(sight).is_empty():
		return Vector2.INF
	return spot


## Whether rect touches a shape of an area in Danger Groups, by the box around the shape.
func _touches_danger(rect: Rect2) -> bool:
	for group: StringName in danger_groups:
		for node: Node in get_tree().get_nodes_in_group(group):
			for child: Node in node.get_children():
				var collision: CollisionShape2D = child as CollisionShape2D
				if collision == null or collision.disabled or collision.shape == null:
					continue
				if (collision.global_transform * collision.shape.get_rect()).intersects(rect):
					return true
	return false


## The height of the floor at x within Max Floor Step of feet_y, looked for from above; INF if none.
func _floor_under(space: PhysicsDirectSpaceState2D, x: float, feet_y: float) -> float:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			Vector2(x, feet_y - max_floor_step - 1.0), Vector2(x, feet_y + max_floor_step + 1.0),
			floor_layers)
	var hit: Dictionary = space.intersect_ray(ray)
	if hit.is_empty():
		return INF
	return (hit["position"] as Vector2).y


## With Centres Camera: takes the screen's camera as a cutscene does and glides it to the middle of
## her and the man, whatever its zone, so both are centred while she talks.
func _centre_the_camera() -> void:
	_camera = get_viewport().get_camera_2d() as GameCamera
	if _camera == null:
		return
	_camera.direct()
	var middle: Vector2 = (global_position + player.global_position) / 2.0 - Vector2(0.0, centre_height)
	_camera_glide = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_camera_glide.tween_property(_camera, ^"global_position", middle, centre_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Gives the camera back to the man; it glides to him as from a cutscene.
func _let_the_camera_go() -> void:
	if is_instance_valid(_camera_glide):
		_camera_glide.kill()
	if is_instance_valid(_camera):
		_camera.release()
	_camera = null


func _still_the_stills() -> void:
	for node: Node in stills:
		if is_instance_valid(node):
			_modes_before[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_DISABLED


func _wake_the_stills() -> void:
	for node: Node in _modes_before:
		if is_instance_valid(node):
			node.process_mode = _modes_before[node]
	_modes_before.clear()
