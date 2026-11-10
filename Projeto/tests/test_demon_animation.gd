# Checks DemonAnimation and the dog's drawing in demon.tscn. The choice alone, from the demon's state
# as the man's comes from his: standing ones (idle, alert, warning, repelled, stunned, grab) show
# idle; walking ones (chase, patrol, return, search, retreat, out of reach) run at Run Min Speed or
# faster and show idle slower; leaping ones (lunge, thrown, jump, drop) and any state off the floor
# show the run's stretched frame. The run keeps pace with the ground: one loop of its frames for
# every Stride Length it runs, at any speed. In the scene: the body lies down, wider than high, as the
# dog is drawn; the drawing has the run, looping, with its frames, and idle; the stand-in rectangle
# no longer shows; the dog faces the way the demon faces; standing it shows idle, and chasing the
# man it runs. The stand-in's shapes never reach the dog: squashed for a warning or flat while
# stunned, the dog keeps its size, while it takes the stand-in's tint and Z Index.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_animation.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const START: Vector2 = Vector2(0.0, -2.0)
## Where the man stands for the demon to see him and chase him.
const SEEN_X: float = 300.0
## Speeds well above Run Min Speed and below it, in px/s.
const FAST: float = 400.0
const SLOW: float = 5.0
const RUN_MIN_SPEED: float = 20.0
## The run's frames as drawn in dog_movement.png.
const RUN_FRAMES: int = 8
const SETTLE_FRAMES: int = 10
## Frames given to the demon to see the man and run after him.
const CHASE_FRAMES: int = 60
## The demon's states by how they show.
const STANDING: Array[Demon.State] = [Demon.State.IDLE, Demon.State.ALERT, Demon.State.WARNING,
		Demon.State.REPELLED, Demon.State.STUNNED, Demon.State.GRAB]
const WALKING: Array[Demon.State] = [Demon.State.CHASE, Demon.State.PATROL, Demon.State.RETURN,
		Demon.State.SEARCH, Demon.State.RETREAT, Demon.State.OUT_OF_REACH]
const LEAPING: Array[Demon.State] = [Demon.State.LUNGE, Demon.State.THROWN, Demon.State.JUMP,
		Demon.State.DROP]


func _initialize() -> void:
	await process_frame
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(_every_state_is_shown())
	results.append(_each_state_floor_and_speed_gives_its_pose())
	results.append(_the_run_plays_one_loop_per_stride())
	results.append(await _in_the_scene_the_dog_lies_down_stands_and_runs())
	results.append(await _the_dog_keeps_its_size_and_takes_the_stand_in_s_tint())
	finish(results)


## No state is left out of the three lists, so a new one has to be given its pose.
func _every_state_is_shown() -> bool:
	var missing: Array[String] = []
	for state: int in Demon.State.values():
		if state not in STANDING and state not in WALKING and state not in LEAPING:
			missing.append(Demon.State.find_key(state))
	return report(missing.is_empty(), "Every state has a pose%s"
			% ("" if missing.is_empty() else ": missing " + ", ".join(missing)))


func _each_state_floor_and_speed_gives_its_pose() -> bool:
	# [state, on the floor, speed across, pose]
	var cases: Array[Array] = []
	for state: Demon.State in STANDING:
		cases.append([state, true, 0.0, DemonAnimation.Pose.IDLE])
		cases.append([state, true, FAST, DemonAnimation.Pose.IDLE])
		cases.append([state, false, 0.0, DemonAnimation.Pose.LEAP])
	for state: Demon.State in WALKING:
		cases.append([state, true, 0.0, DemonAnimation.Pose.IDLE])
		cases.append([state, true, SLOW, DemonAnimation.Pose.IDLE])
		cases.append([state, true, FAST, DemonAnimation.Pose.RUN])
		cases.append([state, true, -FAST, DemonAnimation.Pose.RUN])
		cases.append([state, false, FAST, DemonAnimation.Pose.LEAP])
	for state: Demon.State in LEAPING:
		cases.append([state, true, 0.0, DemonAnimation.Pose.LEAP])
		cases.append([state, false, FAST, DemonAnimation.Pose.LEAP])
	var wrong: Array[String] = []
	for case: Array in cases:
		var got: DemonAnimation.Pose = DemonAnimation.pose_for(case[0], case[1], case[2],
				RUN_MIN_SPEED)
		if got != case[3]:
			wrong.append("%s floor %s %.0f px/s: %s, not %s" % [Demon.State.find_key(case[0]),
					case[1], case[2], DemonAnimation.Pose.find_key(got),
					DemonAnimation.Pose.find_key(case[3])])
	return report(wrong.is_empty(), "Poses, %d cases%s" % [cases.size(),
			"" if wrong.is_empty() else ": " + "; ".join(wrong)])


## At any speed, the frames shown while running Stride Length make one loop.
func _the_run_plays_one_loop_per_stride() -> bool:
	var stride: float = 260.0
	var fps: float = 12.0
	var wrong: Array[String] = []
	for speed: float in [150.0, 400.0, 560.0, -560.0]:
		var speed_scale: float = DemonAnimation.run_speed_scale(speed, stride, RUN_FRAMES, fps)
		var frames_per_stride: float = speed_scale * fps * stride / absf(speed)
		if not is_equal_approx(frames_per_stride, RUN_FRAMES):
			wrong.append("%.0f px/s: %.2f frames per stride" % [speed, frames_per_stride])
	return report(wrong.is_empty(), "Run pace, 4 speeds%s"
			% ("" if wrong.is_empty() else ": " + "; ".join(wrong)))


func _in_the_scene_the_dog_lies_down_stands_and_runs() -> bool:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.position = START
	root.add_child(demon)
	await wait_frames(SETTLE_FRAMES)
	var body: Vector2 = ((demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape
			as RectangleShape2D).size
	var placeholder: Polygon2D = demon.get_node(^"Placeholder") as Polygon2D
	var sprite: AnimatedSprite2D = demon.get_node_or_null(^"Sprite") as AnimatedSprite2D
	if sprite == null:
		demon.queue_free()
		return report(false, "In the scene: no Sprite; body %s" % body)
	var frames: SpriteFrames = sprite.sprite_frames
	var has_run: bool = frames.has_animation(DemonAnimation.RUN)
	var run_ok: bool = (has_run and frames.get_frame_count(DemonAnimation.RUN) == RUN_FRAMES
			and frames.get_animation_loop(DemonAnimation.RUN))
	var has_idle: bool = frames.has_animation(DemonAnimation.IDLE)
	await process_frame
	var standing_state: String = Demon.State.find_key(demon.get_state())
	var stands_idle: bool = sprite.animation == DemonAnimation.IDLE
	var faces_as_the_demon: bool = sprite.flip_h == (demon.get_facing() < 0.0)
	var man: Player = await spawn_on_floor(Vector2(SEEN_X, START.y))
	var ran: bool = false
	for _frame: int in CHASE_FRAMES:
		await process_frame
		ran = ran or (demon.get_state() == Demon.State.CHASE
				and sprite.animation == DemonAnimation.RUN and sprite.is_playing())
	var hidden_rectangle: bool = placeholder.self_modulate.a == 0.0
	demon.queue_free()
	if man != null:
		await remove_player(man)
	var passed: bool = (body.x > body.y and run_ok and has_idle and hidden_rectangle
			and stands_idle and faces_as_the_demon and ran)
	return report(passed,
			("In the scene: body %s, lying down %s; run with %d frames, looping %s; idle %s; "
			+ "rectangle hidden %s; in %s it shows idle %s; facing as the demon %s; chasing it "
			+ "runs %s") % [body, body.x > body.y,
			frames.get_frame_count(DemonAnimation.RUN) if has_run else 0, run_ok, has_idle,
			hidden_rectangle, standing_state, stands_idle, faces_as_the_demon, ran])


## The stand-in lying flat while stunned and drawn over the man while it grabs: the dog keeps its
## own scale, and takes the stand-in's tint and Z Index on the next frame drawn.
func _the_dog_keeps_its_size_and_takes_the_stand_in_s_tint() -> bool:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.position = START
	root.add_child(demon)
	await wait_frames(SETTLE_FRAMES)
	var placeholder: DemonPlaceholder = demon.get_node(^"Placeholder") as DemonPlaceholder
	var sprite: Node2D = demon.get_node_or_null(^"Sprite") as Node2D
	if sprite == null:
		demon.queue_free()
		return report(false, "Size and tint: no Sprite")
	var own_scale: Vector2 = sprite.global_transform.get_scale()
	placeholder._on_demon_state_changed(Demon.State.IDLE, Demon.State.STUNNED)
	# process_frame comes before the nodes' _process on its frame: one more for the stand-in's.
	await process_frame
	await process_frame
	var stunned_scale: Vector2 = sprite.global_transform.get_scale()
	var squashed: bool = placeholder.scale != Vector2.ONE
	var tinted: bool = sprite.modulate == placeholder.modulate and sprite.modulate != Color.WHITE
	placeholder._on_demon_state_changed(Demon.State.STUNNED, Demon.State.GRAB)
	await process_frame
	await process_frame
	var over_him: bool = sprite.z_index == placeholder.z_index and sprite.z_index != 0
	demon.queue_free()
	var passed: bool = squashed and own_scale.is_equal_approx(stunned_scale) and tinted and over_him
	return report(passed,
			("Size and tint: stand-in squashed %s, dog at %s before and %s stunned; tinted as the "
			+ "stand-in %s; Z Index as the stand-in while it grabs %s") % [squashed, own_scale,
			stunned_scale, tinted, over_him])
