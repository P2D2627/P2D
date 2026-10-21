# Checks what a demon's hit does to the man (ADR 0021). Player.knock_back() throws him up to its
# height and lands him its distance away on flat floor, to either side, with Jump held or not, so
# letting go never cuts it short. While it lasts the run and the jump do nothing, and landing gives
# them back; in the air, Knockback Max Time does. A press of Jump during it never jumps, but one just
# before landing jumps as he lands. A hit through his Hurtbox takes its damage and throws him away
# from the Hitbox, and no other hit lands for Invulnerable Time. With SP low, or when the hit would
# take the SP to 0, it takes nothing, throws nothing and says so with grab_hit. The drawing blinks
# while he is invulnerable, never more than three times a second, and the scene's Hurtbox is his body.
# His body and a demon's stop each other (ADR 0022), and landing on a demon's top shoves him off it
# sideways, to the side he is on, never up, and he lands clear of it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_knockback.gd
extends "res://tests/support/player_test.gd"

const HITBOX_SCENE: PackedScene = preload("res://components/hitbox.tscn")
## A little above the floor, so the man lands on his own before a case starts.
const SPAWN_Y: float = -2.0
## Far above the floor, so the man is still in the air when a case ends.
const HIGH_IN_THE_AIR: Vector2 = Vector2(0.0, -100000.0)
## Knockbacks as distance and height, in px: the bite's and the lunge's in lust_demon_stats.tres.
const KNOCKBACKS: Array[Vector2] = [Vector2(150.0, 40.0), Vector2(250.0, 70.0)]
## How far the measured peak may miss the knockback's height, in px, as for the jump.
const PEAK_TOLERANCE: float = 1.0
## How far a speed may drift and still count as kept, in px/s. Speeds are stored as 32-bit floats.
const SPEED_TOLERANCE: float = 0.01
## The hit of the hit cases: SP taken, and its knockback.
const HIT_DAMAGE: float = 10.0
const HIT_DISTANCE: float = 150.0
const HIT_HEIGHT: float = 40.0
## A knockback that leaves the man where he is, so a Hitbox in place keeps overlapping him.
const IN_PLACE_DISTANCE: float = 0.0
const IN_PLACE_HEIGHT: float = 1.0
## The Hitbox of every hit case: a demon's, 96 px square, its feet this far to one side of the man's.
const HITBOX_SIZE: Vector2 = Vector2(96.0, 96.0)
const HITBOX_OFFSET: float = 30.0
## Frames to wait for a hit to land after the Hitbox is turned on.
const HIT_FRAMES: int = 10
## SP damage taken before the low SP case, to leave the man at 20 of 100, under Low Threshold.
const DAMAGE_TO_LOW: float = 80.0
## SP damage taken before the case of the hit that would take the SP to 0, to leave him at 30 of 100,
## above Low Threshold; then a hit of exactly 30 grabs and one of a little less hurts.
const DAMAGE_TO_THIRTY: float = 70.0
const HIT_TO_ZERO: float = 30.0
const HIT_JUST_UNDER_ZERO: float = 29.5
## Blink Rate of the blink case, above the most the blink allows.
const FAST_BLINK_RATE: float = 10.0
## Invulnerability of the blink case, in s.
const BLINK_CASE_TIME: float = 1.0
## Frames before the landing at which the case of the late press presses Jump: within Jump Buffer.
const PRESS_BEFORE_LANDING_FRAMES: int = 2
## Frames after the landing in which that press must jump.
const JUMP_AFTER_LANDING_FRAMES: int = 3
## The demon's body of the knock-off case, the size of demon.tscn's, standing on the floor.
const DEMON_BODY_SIZE: Vector2 = Vector2(48.0, 96.0)
## How far to one side of that body's middle the man drops onto it, and from how high above its top.
const DROP_OFF_CENTRE: float = 8.0
const DROP_HEIGHT: float = 100.0
## Frames the man may stay on a demon's top beyond the slide off it at Knock Off Speed: the landing
## frame, and one for rounding.
const SLIDE_SLACK_FRAMES: int = 2
## How far the man may rise off a demon's top and still count as shoved sideways, in px.
const RISE_TOLERANCE: float = 1.0
## The body that stops the shove in the case of the stopped shove, as another demon in a lunge: this
## far past the man's side as he drops, in px, and its bottom this far above the first demon's top.
const BLOCK_GAP: float = 1.0
const BLOCK_LIFT: float = 1.0
## The frame on which a stopped shove turns the other way.
const TURN_FRAMES: int = 1
## Physics layer names, as in the project settings.
const WORLD_LAYER_NAME: String = "world"
const ONE_WAY_LAYER_NAME: String = "one_way_platform"
const ENEMY_LAYER_NAME: String = "enemy"
## The number of named 2D physics layers the project settings can hold.
const PHYSICS_LAYERS: int = 32


func _initialize() -> void:
	make_platform(-5000.0, 5000.0)
	var results: Array[bool] = []
	results.append(await _a_knockback_peaks_at_its_height_and_lands_its_distance_away())
	results.append(await _the_run_does_nothing_until_the_man_lands())
	results.append(await _in_the_air_the_knockback_ends_after_its_max_time())
	results.append(await _a_press_during_it_never_jumps_but_one_just_before_landing_does())
	results.append(await _a_hit_takes_its_damage_and_throws_the_man_away_from_the_hitbox())
	results.append(await _after_a_hit_no_other_hit_lands_for_invulnerable_time())
	results.append(await _at_low_sp_a_hit_grabs_and_takes_nothing())
	results.append(await _a_hit_that_would_take_the_sp_to_0_grabs_instead())
	results.append(await _the_blink_is_at_most_three_a_second_and_ends_with_the_invulnerability())
	results.append(await _the_man_s_hurtbox_is_his_body_and_is_wired())
	results.append(await _landing_on_a_demon_shoves_the_man_off_it_sideways())
	results.append(await _a_shove_stopped_on_one_side_turns_to_the_other())
	results.append(await _the_man_s_body_collides_with_demons_and_can_t_stand_on_them())
	finish(results)


## With Jump let go, so a cut would show, and held, to both sides.
func _a_knockback_peaks_at_its_height_and_lands_its_distance_away() -> bool:
	var passed: bool = true
	for knockback: Vector2 in KNOCKBACKS:
		for direction: float in [1.0, -1.0]:
			for hold_jump: bool in [false, true]:
				var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
				var stand_in: StandInInput = put_a_stand_in(man)
				stand_in.hold_jump = hold_jump
				var floor_y: float = man.position.y
				var start_x: float = man.position.x
				man.knock_back(direction, knockback.x, knockback.y)
				var half_frame_move: float = absf(man.velocity.x) / Engine.physics_ticks_per_second / 2.0
				var highest_y: float = floor_y
				var left_floor: bool = false
				for _frame: int in MAX_FRAMES:
					await physics_frame
					if man.is_on_floor():
						if left_floor:
							break
						continue
					left_floor = true
					highest_y = minf(highest_y, man.position.y)
				var peak: float = floor_y - highest_y
				var travelled: float = (man.position.x - start_x) * direction
				var case_passed: bool = (absf(peak - knockback.y) <= PEAK_TOLERANCE
						and absf(travelled - knockback.x) <= half_frame_move)
				passed = report(case_passed,
						("Knockback of %.0f px, %.0f px high, direction %+.0f, Jump held %s: peaked at "
						+ "%.1f px, landed %.1f px away (half a frame moves %.1f)")
						% [knockback.x, knockback.y, direction, hold_jump, peak, travelled,
						half_frame_move]) and passed
				await remove_player(man)
	return passed


## Running back towards the hit changes nothing while he flies, and changes the speed at once after
## the landing, which comes before Knockback Max Time does.
func _the_run_does_nothing_until_the_man_lands() -> bool:
	var passed: bool = true
	for knockback: Vector2 in KNOCKBACKS:
		var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
		var stand_in: StandInInput = put_a_stand_in(man)
		man.knock_back(1.0, knockback.x, knockback.y)
		var launch_speed: float = man.velocity.x
		stand_in.run_direction = -1.0
		var speed_kept: bool = true
		var frames_to_landing: int = 0
		var left_floor: bool = false
		for _frame: int in MAX_FRAMES:
			await physics_frame
			frames_to_landing += 1
			speed_kept = speed_kept and absf(man.velocity.x - launch_speed) <= SPEED_TOLERANCE
			if not man.is_on_floor():
				left_floor = true
			elif left_floor:
				break
		await physics_frame
		var control_back: bool = (not man.is_knocked_back()
				and man.velocity.x < launch_speed - SPEED_TOLERANCE)
		var max_frames: int = man.stats.get_knockback_max_frames()
		var case_passed: bool = speed_kept and control_back and frames_to_landing < max_frames
		passed = report(case_passed,
				("Knockback of %.0f px, running back: speed kept to the landing %s, landed after %d "
				+ "frames (Knockback Max Time %d), control back on the next frame %s")
				% [knockback.x, speed_kept, frames_to_landing, max_frames, control_back]) and passed
		await remove_player(man)
	return passed


func _in_the_air_the_knockback_ends_after_its_max_time() -> bool:
	var man: Player = spawn_player(HIGH_IN_THE_AIR)
	var stand_in: StandInInput = put_a_stand_in(man)
	await physics_frame
	man.knock_back(1.0, HIT_DISTANCE, HIT_HEIGHT)
	var launch_speed: float = man.velocity.x
	stand_in.run_direction = -1.0
	var frames_kept: int = 0
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if absf(man.velocity.x - launch_speed) > SPEED_TOLERANCE:
			break
		frames_kept += 1
	var max_frames: int = man.stats.get_knockback_max_frames()
	await remove_player(man)
	return report(frames_kept == max_frames and max_frames > 0,
			"In the air, running back: speed kept for %d frames, Knockback Max Time %d frames"
			% [frames_kept, max_frames])


## A press on the hit's own frame is dropped by the landing; one PRESS_BEFORE_LANDING_FRAMES before
## it, within Jump Buffer, jumps within JUMP_AFTER_LANDING_FRAMES of it.
func _a_press_during_it_never_jumps_but_one_just_before_landing_does() -> bool:
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var stand_in: StandInInput = put_a_stand_in(man)
	man.knock_back(1.0, HIT_DISTANCE, HIT_HEIGHT)
	stand_in.press_jump()
	var jumped_early: bool = false
	var frames_to_landing: int = 0
	var left_floor: bool = false
	var previous_speed: float = man.velocity.y
	for _frame: int in MAX_FRAMES:
		await physics_frame
		jumped_early = jumped_early or is_jump(previous_speed, man.velocity.y)
		previous_speed = man.velocity.y
		frames_to_landing += 1
		if not man.is_on_floor():
			left_floor = true
		elif left_floor:
			break
	for _frame: int in JUMP_AFTER_LANDING_FRAMES:
		await physics_frame
		jumped_early = jumped_early or is_jump(previous_speed, man.velocity.y)
		previous_speed = man.velocity.y
	await remove_player(man)

	man = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	stand_in = put_a_stand_in(man)
	man.knock_back(1.0, HIT_DISTANCE, HIT_HEIGHT)
	await wait_frames(frames_to_landing - PRESS_BEFORE_LANDING_FRAMES)
	stand_in.press_jump()
	previous_speed = man.velocity.y
	var jumped_on_landing: bool = false
	for _frame: int in PRESS_BEFORE_LANDING_FRAMES + JUMP_AFTER_LANDING_FRAMES:
		await physics_frame
		jumped_on_landing = jumped_on_landing or is_jump(previous_speed, man.velocity.y)
		previous_speed = man.velocity.y
	await remove_player(man)
	return report(not jumped_early and jumped_on_landing,
			("Jump pressed on the hit's frame: jumped %s; pressed %d frames before the landing: "
			+ "jumped on landing %s") % [jumped_early, PRESS_BEFORE_LANDING_FRAMES, jumped_on_landing])


## With the Hitbox on either side, the man flies away from it at the knockback's launch velocity.
func _a_hit_takes_its_damage_and_throws_the_man_away_from_the_hitbox() -> bool:
	var passed: bool = true
	for side: float in [-1.0, 1.0]:
		var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
		var start_sp: float = man.soul_points.get_sp()
		var hitbox: Hitbox = _make_hitbox(man.position + Vector2(side * HITBOX_OFFSET, 0.0),
				HIT_DAMAGE, HIT_DISTANCE, HIT_HEIGHT)
		hitbox.activate()
		var hit: bool = await wait_until(man.is_knocked_back, HIT_FRAMES)
		var launch: Vector2 = man.stats.get_knockback_velocity(HIT_DISTANCE, HIT_HEIGHT)
		var expected: Vector2 = Vector2(-side * launch.x, launch.y)
		var taken: float = start_sp - man.soul_points.get_sp()
		var case_passed: bool = (hit and is_equal_approx(taken, HIT_DAMAGE)
				and man.velocity.is_equal_approx(expected))
		passed = report(case_passed,
				"Hitbox on the man's %s: knocked back %s, took %.1f SP of %.1f, velocity %s, expected %s"
				% ["left" if side < 0.0 else "right", hit, taken, HIT_DAMAGE, man.velocity, expected]
				) and passed
		hitbox.queue_free()
		await remove_player(man)
	return passed


## The Hitbox stays on him, turned off and on every frame, and the next hit lands on the frame the
## invulnerability ends: its frames after the frame of the first hit.
func _after_a_hit_no_other_hit_lands_for_invulnerable_time() -> bool:
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var reaction: HitReaction = man.get_node(^"HitReaction") as HitReaction
	var hitbox: Hitbox = _make_hitbox(man.position + Vector2(-HITBOX_OFFSET, 0.0), HIT_DAMAGE,
			IN_PLACE_DISTANCE, IN_PLACE_HEIGHT)
	hitbox.activate()
	var hurt: Callable = func() -> bool: return man.soul_points.get_sp() < man.soul_points.get_max_sp()
	var first_hit: bool = await wait_until(hurt, HIT_FRAMES)
	var sp_after_first: float = man.soul_points.get_sp()
	var frames_to_second: int = NEVER_REACHED
	for frame: int in MAX_FRAMES:
		hitbox.deactivate()
		hitbox.activate()
		await physics_frame
		if man.soul_points.get_sp() < sp_after_first:
			frames_to_second = frame + 1
			break
	var expected: int = roundi(reaction.invulnerable_time * Engine.physics_ticks_per_second)
	hitbox.queue_free()
	await remove_player(man)
	return report(first_hit and frames_to_second == expected,
			"Hitbox kept on the man: first hit %s, the next one %d frames later, expected %d"
			% [first_hit, frames_to_second, expected])


func _at_low_sp_a_hit_grabs_and_takes_nothing() -> bool:
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	var grabs: Array[Hitbox] = _grabs_of(man)
	man.soul_points.take_damage(DAMAGE_TO_LOW)
	var sp_before: float = man.soul_points.get_sp()
	var hitbox: Hitbox = _make_hitbox(man.position + Vector2(-HITBOX_OFFSET, 0.0), HIT_DAMAGE,
			HIT_DISTANCE, HIT_HEIGHT)
	hitbox.activate()
	await wait_until(func() -> bool: return not grabs.is_empty(), HIT_FRAMES)
	var case_passed: bool = (grabs == [hitbox] and man.soul_points.get_sp() == sp_before
			and not man.is_knocked_back() and man.velocity == Vector2.ZERO
			and not hurtbox.is_invulnerable())
	var verdict: bool = report(case_passed,
			("Hit at %.1f SP, low: grab_hit %d times, from the Hitbox %s; SP %.1f; knocked back %s, "
			+ "velocity %s; invulnerable %s") % [sp_before, grabs.size(), grabs == [hitbox],
			man.soul_points.get_sp(), man.is_knocked_back(), man.velocity,
			hurtbox.is_invulnerable()])
	hitbox.queue_free()
	await remove_player(man)
	return verdict


## A hit of exactly the SP left grabs; one of a little less hurts and throws. Each hit has a man of
## its own at the same SP, since a grabbed man takes no SP from any hit until he breaks free.
func _a_hit_that_would_take_the_sp_to_0_grabs_instead() -> bool:
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var grabs: Array[Hitbox] = _grabs_of(man)
	man.soul_points.take_damage(DAMAGE_TO_THIRTY)
	var hitbox: Hitbox = _make_hitbox(man.position + Vector2(-HITBOX_OFFSET, 0.0), HIT_TO_ZERO,
			HIT_DISTANCE, HIT_HEIGHT)
	hitbox.activate()
	await wait_until(func() -> bool: return not grabs.is_empty(), HIT_FRAMES)
	var sp_after_grab: float = man.soul_points.get_sp()
	var grabbed: bool = (grabs.size() == 1 and is_equal_approx(sp_after_grab, HIT_TO_ZERO)
			and not man.is_knocked_back())
	hitbox.queue_free()
	await remove_player(man)
	man = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	grabs = _grabs_of(man)
	man.soul_points.take_damage(DAMAGE_TO_THIRTY)
	hitbox = _make_hitbox(man.position + Vector2(-HITBOX_OFFSET, 0.0), HIT_JUST_UNDER_ZERO,
			HIT_DISTANCE, HIT_HEIGHT)
	hitbox.activate()
	var hurt: bool = await wait_until(man.is_knocked_back, HIT_FRAMES)
	hurt = (hurt and grabs.is_empty()
			and is_equal_approx(man.soul_points.get_sp(), HIT_TO_ZERO - HIT_JUST_UNDER_ZERO))
	var verdict: bool = report(grabbed and hurt,
			("At %.1f SP: a hit of %.1f grabbed %s (SP %.1f); on another man at that SP, one of "
			+ "%.1f hurt and threw %s (SP %.1f)") % [HIT_TO_ZERO, HIT_TO_ZERO, grabbed,
			sp_after_grab, HIT_JUST_UNDER_ZERO, hurt, man.soul_points.get_sp()])
	hitbox.queue_free()
	await remove_player(man)
	return verdict


## Counts the times the drawing goes dim, frame by frame, while the Hurtbox is invulnerable, with a
## Blink Rate above the most allowed; the first frame must already be dim, and the drawing whole at
## the end. It reads after each physics frame, by which time the blink's _process of the frame before
## has run; process_frame comes before it.
func _the_blink_is_at_most_three_a_second_and_ends_with_the_invulnerability() -> bool:
	var man: Player = await spawn_on_floor(Vector2(0.0, SPAWN_Y))
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	var blink: InvulnerabilityBlink = man.get_node(^"InvulnerabilityBlink") as InvulnerabilityBlink
	var drawing: CanvasItem = blink.drawing
	blink.blink_rate = FAST_BLINK_RATE
	hurtbox.start_invulnerability(BLINK_CASE_TIME)
	var dim_starts: int = 0
	var first_frame_dim: bool = false
	var was_dim: bool = false
	var frames: int = 0
	while hurtbox.is_invulnerable() and frames < MAX_FRAMES:
		await physics_frame
		frames += 1
		var dim: bool = drawing.modulate.a < 1.0
		if frames == 1:
			first_frame_dim = dim
		if dim and not was_dim:
			dim_starts += 1
		was_dim = dim
	var whole_after: bool = drawing.modulate.a == 1.0
	var seconds: float = float(frames) / Engine.physics_ticks_per_second
	var most_allowed: int = ceili(seconds * InvulnerabilityBlink.MAX_BLINKS_PER_SECOND)
	await remove_player(man)
	return report(first_frame_dim and dim_starts > 0 and dim_starts <= most_allowed and whole_after,
			("Blink Rate %.0f, invulnerable %.2f s: first frame dim %s, went dim %d times (at most "
			+ "%d), whole after %s") % [FAST_BLINK_RATE, seconds, first_frame_dim, dim_starts,
			most_allowed, whole_after])


## The Hurtbox covers the body exactly, and HitReaction and the blink are wired to this man's nodes.
func _the_man_s_hurtbox_is_his_body_and_is_wired() -> bool:
	var man: Player = spawn_player(Vector2(0.0, SPAWN_Y))
	var body: CollisionShape2D = man.get_node(^"CollisionShape2D") as CollisionShape2D
	var hurtbox: Hurtbox = man.get_node(^"Hurtbox") as Hurtbox
	var hurtbox_shape: CollisionShape2D = hurtbox.get_node(^"HurtboxShape") as CollisionShape2D
	var reaction: HitReaction = man.get_node(^"HitReaction") as HitReaction
	var blink: InvulnerabilityBlink = man.get_node(^"InvulnerabilityBlink") as InvulnerabilityBlink
	var same_box: bool = (hurtbox.position == Vector2.ZERO
			and hurtbox_shape.position == body.position
			and (hurtbox_shape.shape as RectangleShape2D).size == body_size(man))
	var wired: bool = (reaction.player == man and reaction.hurtbox == hurtbox
			and blink.hurtbox == hurtbox and blink.drawing == man.get_node(^"Placeholder"))
	await remove_player(man)
	return report(same_box and wired,
			"Scene: the Hurtbox is the body's box %s; HitReaction and the blink on this man's nodes %s"
			% [same_box, wired])


## The man drops onto a demon's body a little to one side of its middle, to both sides, and runs the
## other way once on it: landing on its top shoves him along it to that side at Knock Off Speed, never up, and
## the run changes nothing. He is off it in the frames the slide takes, and lands on the floor clear
## of it. The body is a stand-in on the demons' layer.
func _landing_on_a_demon_shoves_the_man_off_it_sideways() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var demon_body: StaticBody2D = make_wall(-DEMON_BODY_SIZE.x / 2.0, DEMON_BODY_SIZE.x / 2.0,
				-DEMON_BODY_SIZE.y)
		demon_body.collision_layer = _bit_of(ENEMY_LAYER_NAME)
		var man: Player = spawn_player(
				Vector2(side * DROP_OFF_CENTRE, -DEMON_BODY_SIZE.y - DROP_HEIGHT))
		var stand_in: StandInInput = put_a_stand_in(man)
		var speed: float = man.stats.knock_off_speed
		var slide: float = (DEMON_BODY_SIZE.x + body_size(man).x) / 2.0 - DROP_OFF_CENTRE
		var most_frames_on_top: int = (ceili(slide / speed * Engine.physics_ticks_per_second)
				+ SLIDE_SLACK_FRAMES)
		var frames_on_top: int = 0
		var rose: float = 0.0
		var shoved_at_speed: bool = true
		var landed_on_floor: bool = false
		for _frame: int in MAX_FRAMES:
			await physics_frame
			if frames_on_top > 0:
				rose = maxf(rose, -DEMON_BODY_SIZE.y - man.position.y)
			if not man.is_on_floor():
				continue
			if man.position.y < -DEMON_BODY_SIZE.y / 2.0:
				frames_on_top += 1
				stand_in.run_direction = -side
				shoved_at_speed = shoved_at_speed and (frames_on_top == 1
						or absf(man.velocity.x - side * speed) <= SPEED_TOLERANCE)
				continue
			landed_on_floor = true
			break
		var clearance: float = side * man.position.x - (DEMON_BODY_SIZE.x + body_size(man).x) / 2.0
		demon_body.queue_free()
		await remove_player(man)
		passed = report(landed_on_floor and frames_on_top <= most_frames_on_top
				and rose <= RISE_TOLERANCE and shoved_at_speed and clearance > 0.0,
				("Dropped onto a demon %+.0f px off its middle, running the other way: on its top %d "
				+ "frames (at most %d), rose %.2f px, shoved at Knock Off Speed %s, landed on the "
				+ "floor %s, %.1f px clear of it on that side") % [side * DROP_OFF_CENTRE,
				frames_on_top, most_frames_on_top, rose, shoved_at_speed, landed_on_floor,
				clearance]) and passed
	return passed


## The man drops onto a demon's body as above, but another demon's body, off the floor as in a lunge,
## stands just past his side the way he is shoved, and stops him: he is shoved the other way at once,
## never stays on the top, and lands on the floor clear of it on that side. Both bodies are stand-ins
## on the demons' layer.
func _a_shove_stopped_on_one_side_turns_to_the_other() -> bool:
	var passed: bool = true
	for side: float in [1.0, -1.0]:
		var demon_body: StaticBody2D = make_wall(-DEMON_BODY_SIZE.x / 2.0, DEMON_BODY_SIZE.x / 2.0,
				-DEMON_BODY_SIZE.y)
		demon_body.collision_layer = _bit_of(ENEMY_LAYER_NAME)
		var man: Player = spawn_player(
				Vector2(side * DROP_OFF_CENTRE, -DEMON_BODY_SIZE.y - DROP_HEIGHT))
		var man_size: Vector2 = body_size(man)
		var near_face: float = DROP_OFF_CENTRE + man_size.x / 2.0 + BLOCK_GAP
		var left: float = near_face if side > 0.0 else -near_face - DEMON_BODY_SIZE.x
		var blocker: StaticBody2D = make_wall(left, left + DEMON_BODY_SIZE.x,
				-DEMON_BODY_SIZE.y - DROP_HEIGHT - man_size.y, -DEMON_BODY_SIZE.y - BLOCK_LIFT)
		blocker.collision_layer = _bit_of(ENEMY_LAYER_NAME)
		put_a_stand_in(man)
		var speed: float = man.stats.knock_off_speed
		var slide: float = (DEMON_BODY_SIZE.x + man_size.x) / 2.0 + DROP_OFF_CENTRE + BLOCK_GAP
		var most_frames_on_top: int = (ceili(slide / speed * Engine.physics_ticks_per_second)
				+ SLIDE_SLACK_FRAMES + TURN_FRAMES)
		var frames_on_top: int = 0
		var rose: float = 0.0
		var landed_on_floor: bool = false
		for _frame: int in MAX_FRAMES:
			await physics_frame
			if frames_on_top > 0:
				rose = maxf(rose, -DEMON_BODY_SIZE.y - man.position.y)
			if not man.is_on_floor():
				continue
			if man.position.y < -DEMON_BODY_SIZE.y / 2.0:
				frames_on_top += 1
				continue
			landed_on_floor = true
			break
		var clearance: float = -side * man.position.x - (DEMON_BODY_SIZE.x + man_size.x) / 2.0
		demon_body.queue_free()
		blocker.queue_free()
		await remove_player(man)
		passed = report(landed_on_floor and frames_on_top <= most_frames_on_top
				and rose <= RISE_TOLERANCE and clearance > 0.0,
				("Dropped onto a demon %+.0f px off its middle, another demon's body stopping the "
				+ "shove that way: on its top %d frames (at most %d), rose %.2f px, landed on the "
				+ "floor %s, %.1f px clear of it on the other side") % [side * DROP_OFF_CENTRE,
				frames_on_top, most_frames_on_top, rose, landed_on_floor, clearance]) and passed
	return passed


## The scene's body collides with the world, one-way platforms and demons, and can't stand on demons.
func _the_man_s_body_collides_with_demons_and_can_t_stand_on_them() -> bool:
	var man: Player = spawn_player(Vector2(0.0, SPAWN_Y))
	var enemy_bit: int = _bit_of(ENEMY_LAYER_NAME)
	var solid: bool = (enemy_bit != 0 and man.collision_mask
			== _bit_of(WORLD_LAYER_NAME) | _bit_of(ONE_WAY_LAYER_NAME) | enemy_bit)
	var knocked_off: bool = enemy_bit != 0 and man.knock_off_layers == enemy_bit
	await remove_player(man)
	return report(solid and knocked_off,
			"Scene: the body collides with the world, one-way platforms and demons only %s; can't stand on demons %s"
			% [solid, knocked_off])


## A demon's Hitbox, off, with its feet at at and the hit's values, already in the scene.
func _make_hitbox(at: Vector2, damage: float, distance: float, height: float) -> Hitbox:
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = HITBOX_SIZE
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = rectangle
	shape.position = Vector2(0.0, -HITBOX_SIZE.y / 2.0)
	var hitbox: Hitbox = HITBOX_SCENE.instantiate() as Hitbox
	hitbox.add_child(shape)
	hitbox.position = at
	hitbox.damage = damage
	hitbox.knockback_distance = distance
	hitbox.knockback_height = height
	root.add_child(hitbox)
	return hitbox


## The Hitboxes the man's HitReaction says grabbed him, in order, as they come.
func _grabs_of(man: Player) -> Array[Hitbox]:
	var grabs: Array[Hitbox] = []
	var reaction: HitReaction = man.get_node(^"HitReaction") as HitReaction
	reaction.grab_hit.connect(func(hitbox: Hitbox) -> void: grabs.append(hitbox))
	return grabs


## The bit of the 2D physics layer with this name in the project settings, or 0 if none has it.
func _bit_of(layer_name: String) -> int:
	for layer: int in range(1, PHYSICS_LAYERS + 1):
		if ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % layer, "") == layer_name:
			return 1 << (layer - 1)
	return 0
