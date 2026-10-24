# Checks the Hitbox and Hurtbox components on their own, without a demon or a player. An active
# Hitbox that overlaps a Hurtbox lands once per activation, however long it stays on and
# overlapping, and both say so, each naming the other. An inactive one, or one too far away, lands
# nothing; one turned on while it already overlaps lands at once, and turning it off and on again
# lands again. While the Hurtbox is invulnerable no hit lands, and an active, overlapping Hitbox
# lands on the physics frame the invulnerability ends: its frames after the frame it started in,
# also when the owner starts it from hit_received. A pause adds its frames, and a shorter time never
# cuts a longer one short. Closed, it lets no hit land either, but is not invulnerable; opened, the
# Hitbox that overlapped all along lands at once (ADR 0029). Two Hitboxes on the same frame land
# both, unless the first hit makes the Hurtbox invulnerable. A Hitbox freed while it overlaps leaves
# the Hurtbox working. The scenes are on the layers the README names: the Hitbox on enemy_hitbox,
# looking for nothing; the Hurtbox on player_hurtbox, looking only on enemy_hitbox.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_hit_boxes.gd
extends "res://tests/support/base_test.gd"

const HITBOX_SCENE: PackedScene = preload("res://components/hitbox.tscn")
const HURTBOX_SCENE: PackedScene = preload("res://components/hurtbox.tscn")
## Radius of every shape the cases give the two areas, in px.
const SHAPE_RADIUS: float = 16.0
## Where the Hurtbox of every case is, away from the origin.
const HURTBOX_POSITION: Vector2 = Vector2(1000.0, 1000.0)
## From the Hurtbox, a Hitbox NEAR_OFFSET away overlaps it, and one FAR_OFFSET away does not.
const NEAR_OFFSET: Vector2 = Vector2(8.0, 0.0)
const FAR_OFFSET: Vector2 = Vector2(400.0, 0.0)
## Frames to wait after adding an area, so its overlaps have surely been seen.
const SETTLE_FRAMES: int = 3
## Frames a Hitbox stays on and overlapping in the case of the long activation: one second.
const LONG_FRAMES: int = 60
## The invulnerability of the timing cases, in s, and a shorter one.
const INVULNERABLE_TIME: float = 0.5
const SHORTER_INVULNERABLE_TIME: float = 0.25
## Physics frames the game stays paused in the case of the pause.
const PAUSE_FRAMES: int = 30
## The names the project gives the physics layers of the two scenes.
const HITBOX_LAYER_NAME: String = "enemy_hitbox"
const HURTBOX_LAYER_NAME: String = "player_hurtbox"
## The number of named 2D physics layers the project settings can hold.
const PHYSICS_LAYERS: int = 32


## Writes down every hit a Hurtbox receives: the Hitbox and the physics frame it came on.
class HitLog:
	var hitboxes: Array[Hitbox] = []
	var frames: Array[int] = []

	func _init(hurtbox: Hurtbox) -> void:
		hurtbox.hit_received.connect(_on_hit_received)

	func _on_hit_received(hitbox: Hitbox) -> void:
		hitboxes.append(hitbox)
		frames.append(Engine.get_physics_frames())


func _initialize() -> void:
	# Before the first frame the root is not ready yet, and a node added to it only runs _ready()
	# when the root does.
	await process_frame
	var results: Array[bool] = []
	results.append(await _an_active_hitbox_lands_once_and_both_say_so())
	results.append(await _an_inactive_or_far_hitbox_lands_nothing())
	results.append(await _turned_on_while_it_overlaps_it_lands_at_once())
	results.append(await _off_and_on_again_it_lands_again())
	results.append(await _a_hit_lands_on_the_frame_the_invulnerability_ends())
	results.append(await _invulnerability_started_by_a_hit_lasts_as_long())
	results.append(await _a_pause_adds_its_frames_to_the_invulnerability())
	results.append(await _a_shorter_invulnerability_never_cuts_a_longer_one())
	results.append(await _closed_no_hit_lands_and_opened_it_lands_at_once())
	results.append(await _two_hitboxes_on_one_frame_land_both())
	results.append(await _a_hit_that_protects_stops_the_second_of_the_frame())
	results.append(await _a_hitbox_freed_while_it_overlaps_leaves_the_hurtbox_working())
	results.append(_the_scenes_are_on_the_layers_the_readme_names())
	quit(1 if results.has(false) else 0)


## On and overlapping for a whole second, a Hitbox lands once, and the two say so naming each other.
func _an_active_hitbox_lands_once_and_both_say_so() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, true)
	var landed_on: Array[Hurtbox] = []
	hitbox.hit_landed.connect(func(target: Hurtbox) -> void: landed_on.append(target))
	await _wait_physics_frames(LONG_FRAMES)
	var received_once: bool = hits.hitboxes.size() == 1 and hits.hitboxes[0] == hitbox
	var landed_once: bool = landed_on.size() == 1 and landed_on[0] == hurtbox
	_free([hurtbox, hitbox])
	return _report(received_once and landed_once,
			"On for %d frames: %d hits received from it, %d landed on the Hurtbox, expected 1 and 1"
			% [LONG_FRAMES, hits.hitboxes.size(), landed_on.size()])


func _an_inactive_or_far_hitbox_lands_nothing() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var inactive: Hitbox = _new_hitbox(NEAR_OFFSET, false)
	var far: Hitbox = _new_hitbox(FAR_OFFSET, true)
	await _wait_physics_frames(LONG_FRAMES)
	_free([hurtbox, inactive, far])
	return _report(hits.hitboxes.is_empty(),
			"An inactive Hitbox over it and an active one %.0f px away: %d hits, expected 0"
			% [FAR_OFFSET.length(), hits.hitboxes.size()])


func _turned_on_while_it_overlaps_it_lands_at_once() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, false)
	await _wait_physics_frames(SETTLE_FRAMES)
	var before: int = hits.hitboxes.size()
	var on_frame: int = Engine.get_physics_frames()
	hitbox.activate()
	await _wait_physics_frames(SETTLE_FRAMES)
	var landed_at_once: bool = hits.frames.size() == 1 and hits.frames[0] == on_frame
	_free([hurtbox, hitbox])
	return _report(before == 0 and landed_at_once,
			"Turned on while over it: %d hits before, then hits on frames %s, expected [%d]"
			% [before, hits.frames, on_frame])


func _off_and_on_again_it_lands_again() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, true)
	await _wait_physics_frames(SETTLE_FRAMES)
	hitbox.activate()
	await _wait_physics_frames(SETTLE_FRAMES)
	var after_a_second_activate: int = hits.hitboxes.size()
	hitbox.deactivate()
	await physics_frame
	hitbox.activate()
	await _wait_physics_frames(SETTLE_FRAMES)
	_free([hurtbox, hitbox])
	return _report(after_a_second_activate == 1 and hits.hitboxes.size() == 2,
			"activate() while on: %d hits, expected 1; off and on again: %d, expected 2"
			% [after_a_second_activate, hits.hitboxes.size()])


## Started before the frame's physics, Invulnerable Time's frames go by with no hit, and the
## Hitbox that has been on and overlapping all along lands on the next.
func _a_hit_lands_on_the_frame_the_invulnerability_ends() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var start_frame: int = Engine.get_physics_frames()
	hurtbox.start_invulnerability(INVULNERABLE_TIME)
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, true)
	var frames: int = _frames_in(INVULNERABLE_TIME)
	await _wait_physics_frames(frames + SETTLE_FRAMES)
	var expected: int = start_frame + frames
	_free([hurtbox, hitbox])
	return _report(hits.frames.size() == 1 and hits.frames[0] == expected,
			"%d invulnerable frames from frame %d: hits on frames %s, expected [%d]"
			% [frames, start_frame, hits.frames, expected])


## Started from hit_received, Invulnerable Time lasts as many frames: a new activation of the same
## Hitbox, made right after the hit, lands that many frames after it.
func _invulnerability_started_by_a_hit_lasts_as_long() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	hurtbox.hit_received.connect(func(_hitbox: Hitbox) -> void:
			hurtbox.start_invulnerability(INVULNERABLE_TIME))
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, true)
	await _wait_physics_frames(SETTLE_FRAMES)
	hitbox.deactivate()
	hitbox.activate()
	var frames: int = _frames_in(INVULNERABLE_TIME)
	await _wait_physics_frames(frames + SETTLE_FRAMES)
	var passed: bool = hits.frames.size() == 2 and hits.frames[1] - hits.frames[0] == frames
	_free([hurtbox, hitbox])
	return _report(passed,
			"Invulnerable from a hit: hits on frames %s, expected two %d frames apart"
			% [hits.frames, frames])


## The physics frames stop in the pause, so the invulnerability ends the pause's frames later.
func _a_pause_adds_its_frames_to_the_invulnerability() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, false)
	await _wait_physics_frames(SETTLE_FRAMES)
	var start_frame: int = Engine.get_physics_frames()
	hurtbox.start_invulnerability(INVULNERABLE_TIME)
	hitbox.activate()
	paused = true
	await _wait_physics_frames(PAUSE_FRAMES)
	paused = false
	var frames: int = _frames_in(INVULNERABLE_TIME)
	await _wait_physics_frames(frames + SETTLE_FRAMES)
	var expected: int = start_frame + PAUSE_FRAMES + frames
	_free([hurtbox, hitbox])
	return _report(hits.frames.size() == 1 and hits.frames[0] == expected,
			"%d invulnerable frames from frame %d, %d of them paused: hits on frames %s, expected [%d]"
			% [frames, start_frame, PAUSE_FRAMES, hits.frames, expected])


func _a_shorter_invulnerability_never_cuts_a_longer_one() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	hurtbox.start_invulnerability(INVULNERABLE_TIME)
	hurtbox.start_invulnerability(SHORTER_INVULNERABLE_TIME)
	var shorter_frames: int = _frames_in(SHORTER_INVULNERABLE_TIME)
	await _wait_physics_frames(shorter_frames + SETTLE_FRAMES)
	var still: bool = hurtbox.is_invulnerable()
	await _wait_physics_frames(_frames_in(INVULNERABLE_TIME) - shorter_frames)
	var after: bool = hurtbox.is_invulnerable()
	_free([hurtbox])
	return _report(still and not after,
			"%.2f s then %.2f s: invulnerable after the shorter %s, after the longer %s"
			% [INVULNERABLE_TIME, SHORTER_INVULNERABLE_TIME, still, after])


## Closed for a whole second with a Hitbox on and overlapping it all along, the Hurtbox takes no hit
## and is not invulnerable, so nothing blinks; opened, the Hitbox lands on that same frame.
func _closed_no_hit_lands_and_opened_it_lands_at_once() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	hurtbox.set_closed(true)
	var hitbox: Hitbox = _new_hitbox(NEAR_OFFSET, true)
	await _wait_physics_frames(LONG_FRAMES)
	var while_closed: int = hits.hitboxes.size()
	var took_hits: bool = hurtbox.takes_hits()
	var invulnerable: bool = hurtbox.is_invulnerable()
	var open_frame: int = Engine.get_physics_frames()
	hurtbox.set_closed(false)
	await _wait_physics_frames(SETTLE_FRAMES)
	var landed_at_once: bool = hits.frames.size() == 1 and hits.frames[0] == open_frame
	_free([hurtbox, hitbox])
	return _report(while_closed == 0 and not took_hits and not invulnerable and landed_at_once,
			"Closed for %d frames with a Hitbox on it: %d hits, takes hits %s, invulnerable %s; opened on frame %d, hits on frames %s, expected [%d]"
			% [LONG_FRAMES, while_closed, took_hits, invulnerable, open_frame, hits.frames,
			open_frame])


func _two_hitboxes_on_one_frame_land_both() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var first: Hitbox = _new_hitbox(NEAR_OFFSET, false)
	var second: Hitbox = _new_hitbox(-NEAR_OFFSET, false)
	await _wait_physics_frames(SETTLE_FRAMES)
	first.activate()
	second.activate()
	await _wait_physics_frames(SETTLE_FRAMES)
	var passed: bool = hits.frames.size() == 2 and hits.frames[0] == hits.frames[1] \
			and hits.hitboxes.has(first) and hits.hitboxes.has(second)
	_free([hurtbox, first, second])
	return _report(passed, "Two Hitboxes turned on together: hits on frames %s, expected two on one"
			% [hits.frames])


## The owner makes the Hurtbox invulnerable from the first hit, so the second Hitbox of the frame
## lands nothing: two demons biting together take SP once.
func _a_hit_that_protects_stops_the_second_of_the_frame() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	hurtbox.hit_received.connect(func(_hitbox: Hitbox) -> void:
			hurtbox.start_invulnerability(INVULNERABLE_TIME))
	var first: Hitbox = _new_hitbox(NEAR_OFFSET, false)
	var second: Hitbox = _new_hitbox(-NEAR_OFFSET, false)
	await _wait_physics_frames(SETTLE_FRAMES)
	first.activate()
	second.activate()
	await _wait_physics_frames(SETTLE_FRAMES)
	_free([hurtbox, first, second])
	return _report(hits.hitboxes.size() == 1,
			"Two Hitboxes together, invulnerable from the first hit: %d hits, expected 1"
			% hits.hitboxes.size())


func _a_hitbox_freed_while_it_overlaps_leaves_the_hurtbox_working() -> bool:
	var hurtbox: Hurtbox = _new_hurtbox()
	var hits: HitLog = HitLog.new(hurtbox)
	var freed: Hitbox = _new_hitbox(NEAR_OFFSET, true)
	await _wait_physics_frames(SETTLE_FRAMES)
	freed.queue_free()
	await _wait_physics_frames(SETTLE_FRAMES)
	var hitbox: Hitbox = _new_hitbox(-NEAR_OFFSET, true)
	await _wait_physics_frames(SETTLE_FRAMES)
	var passed: bool = hits.hitboxes.size() == 2 and hits.hitboxes[1] == hitbox
	_free([hurtbox, hitbox])
	return _report(passed, "A Hitbox freed over it, then a new one: %d hits, expected 2"
			% hits.hitboxes.size())


func _the_scenes_are_on_the_layers_the_readme_names() -> bool:
	var hitbox_layer: int = _layer_named(HITBOX_LAYER_NAME)
	var hurtbox_layer: int = _layer_named(HURTBOX_LAYER_NAME)
	var hitbox: Hitbox = HITBOX_SCENE.instantiate() as Hitbox
	var hurtbox: Hurtbox = HURTBOX_SCENE.instantiate() as Hurtbox
	var hitbox_ok: bool = hitbox_layer > 0 and hitbox.collision_layer == 1 << (hitbox_layer - 1) \
			and hitbox.collision_mask == 0 and not hitbox.monitoring and hitbox.monitorable
	var hurtbox_ok: bool = hurtbox_layer > 0 \
			and hurtbox.collision_layer == 1 << (hurtbox_layer - 1) \
			and hurtbox.collision_mask == 1 << (hitbox_layer - 1) and hurtbox.monitoring
	hitbox.free()
	hurtbox.free()
	return _report(hitbox_ok and hurtbox_ok,
			"The Hitbox scene only on layer %d, %s, looking for nothing: %s; the Hurtbox scene only on layer %d, %s, looking only on %s: %s"
			% [hitbox_layer, HITBOX_LAYER_NAME, hitbox_ok, hurtbox_layer, HURTBOX_LAYER_NAME,
			HITBOX_LAYER_NAME, hurtbox_ok])


## A Hurtbox from its scene at HURTBOX_POSITION, with a round shape, in the tree.
func _new_hurtbox() -> Hurtbox:
	var hurtbox: Hurtbox = HURTBOX_SCENE.instantiate() as Hurtbox
	hurtbox.position = HURTBOX_POSITION
	hurtbox.add_child(_round_shape())
	root.add_child(hurtbox)
	return hurtbox


## A Hitbox from its scene, offset px from the Hurtbox's position, with a round shape, in the tree;
## on if active.
func _new_hitbox(offset: Vector2, active: bool) -> Hitbox:
	var hitbox: Hitbox = HITBOX_SCENE.instantiate() as Hitbox
	hitbox.position = HURTBOX_POSITION + offset
	hitbox.add_child(_round_shape())
	root.add_child(hitbox)
	if active:
		hitbox.activate()
	return hitbox


func _round_shape() -> CollisionShape2D:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = SHAPE_RADIUS
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = circle
	return shape


func _frames_in(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)


func _free(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		node.queue_free()


## Waits for count physics frames. Code after it runs before the nodes' physics of the frame it
## stops on.
func _wait_physics_frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func _layer_named(layer_name: String) -> int:
	for layer: int in range(1, PHYSICS_LAYERS + 1):
		if ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % layer, "") == layer_name:
			return layer
	return 0


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
