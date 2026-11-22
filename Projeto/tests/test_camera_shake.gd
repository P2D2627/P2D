# Checks the screen shake (ADR 0061). The rules on their own: trauma adds up to 1 at most and falls
# at Decay per second to 0; the shake is the trauma to the power Exponent; with no trauma, or with
# the option at 0, the screen stays put, and it never moves more than Max Offset times the shake to
# each side, though it does move; it passes its resting place about 1.35 times a second for each
# unit of Speed; even full trauma is gone half a second after the last impact. A rock shakes less
# the farther from the man it breaks, and not at all from Rock Reach on. The shake moves the screen
# by the same px at any zoom. The Screen shake option is 1 with no file, stays in 0 to 1, takes the
# default for a value that is not a number, and is saved and read back; the options screen shows it
# and changes it, and Reset brings it back. In a scene with the player and the game camera: the
# camera's impacts listen to his death, the hits he takes, the hazards, grabs and the presses to
# break free, the crucifix, the hard landings and the falling rocks, and each moment adds its own
# trauma: a normal landing, holding Jump to break free, or a hazard hitting another body, adds none.
# Raising the trauma to a level never piles up: presses to break free in a row keep their level, and
# breaking free right after them goes to its own level, not on top of theirs. His death shakes the
# screen through the camera's offset, leaves where the camera is alone, and is gone half a second
# later; with the option at 0 it leaves the screen put, though the trauma rises. A pause puts what
# is drawn back in place. A level that takes his crucifix as it starts does not shake, though its
# impacts listen. A demon's on-screen check, read on each physics frame as a demon reads it, ignores
# the shake, and with no shake it is the screen drawn, also where the camera's limits move that
# screen.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_shake.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const SHAKE_STATS: CameraShakeStats = preload("res://scenes/others/camera/camera_shake_stats.tres")
const ROCK_SCENE: PackedScene = preload("res://scenes/objects/traps/falling_rock.tscn")
const HAZARD_SCENE: PackedScene = preload("res://scenes/objects/traps/spikes.tscn")
const DEMON_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const TEST_ROOM_SCENE: PackedScene = preload("res://scenes/levels/test_room/test_room.tscn")
const OPTIONS_SCENE: PackedScene = preload("res://scenes/screens/options_menu.tscn")
const SETTINGS_SCRIPT: GDScript = preload("res://scenes/autoload/settings.gd")
const TEST_PATH: String = "user://test_camera_shake.cfg"
## One drawn frame at the tests' fixed 60 frames a second, in s.
const FRAME: float = 1.0 / 60.0
## How close two numbers must be to count as the same.
const TOLERANCE: float = 0.0001
## How far the camera may drift and still count as where it was, in px.
const SAME_SPOT: float = 0.01
## Frames of a shake the cases watch: half a second.
const WATCH_FRAMES: int = 30
## A second and a half of frames: how long the rules run at full trauma, and the longest wait for a
## shake to end.
const SETTLE_FRAMES: int = 90
## Half a second of frames: any shake must be gone by then after the last impact.
const HALF_SECOND_FRAMES: int = 30
## Frames a level runs before its trauma is read: the trauma of a moment at its start would still
## be well above 0.
const START_FRAMES: int = 3
## Frames a shake runs before a pause, and frames for a camera's new offset to reach what is drawn.
const SHAKE_FRAMES: int = 5
const DRAW_FRAMES: int = 3
## Frames the speed is read over: 60 s.
const SPEED_FRAMES: int = 3600
## How often the screen passes its resting place, a second, for each unit of Speed (measured on the
## noise at 60 frames a second), and how far from it the speed case may land, as a share.
const CROSSINGS_PER_UNIT: float = 1.35
const SPEED_TOLERANCE: float = 0.15
## The zoom of the second camera in the zoom case.
const ZOOM_IN: float = 2.0
## The level the rules raise the trauma to in the raise case, and how many raises, or presses to
## break free, come in a row in the cases that check they never pile up.
const RAISE_LEVEL: float = 0.35
const IN_A_ROW: int = 5
## Where the player stands in the cases with a scene, above a floor at y = 0.
const START: Vector2 = Vector2(0.0, -100.0)
const FLOOR_HALF_WIDTH: float = 2000.0
## Where the hazard sits in the moments case, away from the player.
const HAZARD_AT: Vector2 = Vector2(-600.0, -40.0)
## How far beside the man the near rock hangs: outside its trigger, so it never drops by itself.
const NEAR_ROCK_X: float = 150.0
## How high above the floor the rocks of the moments case hang.
const ROCK_HEIGHT: float = 300.0
## How far beside the man the far rock hangs: past Rock Reach.
const FAR_ROCK_X: float = 1500.0
## How far inside or outside an edge of the screen the demons' bodies sit, in px.
const EDGE_GAP: float = 1.0
## Camera limits narrower and shorter than any screen the tests run on, so the camera centres the
## screen on them; and limits wider and taller than any, with a camera past their far corner, so the
## camera holds the screen inside them.
const NARROW_LIMITS: Rect2i = Rect2i(-300, -400, 600, 500)
const WIDE_LIMITS: Rect2i = Rect2i(-4000, -4000, 8000, 8000)
const PAST_THE_LIMITS: Vector2 = Vector2(6000.0, 6000.0)


## Reads, on each physics frame as a demon does, whether two demons count as on screen. It runs before
## the camera, as the demons of a level placed before the camera do, so it reads what the camera
## worked out on the physics frame before.
class OnScreenWatch extends Node:
	var inside: DemonSenses
	var outside: DemonSenses
	var frames: int = 0
	var wrong: int = 0

	func _ready() -> void:
		process_physics_priority = -1

	func _physics_process(_delta: float) -> void:
		frames += 1
		if not inside.is_on_screen() or outside.is_on_screen():
			wrong += 1


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_trauma_adds_up_to_one_and_falls_to_zero())
	results.append(_raising_the_trauma_never_piles_up())
	results.append(_the_shake_is_the_trauma_to_the_power_exponent())
	results.append(_no_trauma_or_no_option_leaves_the_screen_put())
	results.append(_the_screen_moves_but_never_past_max_offset_times_the_shake())
	results.append(_the_screen_passes_its_rest_about_as_often_as_speed_says())
	results.append(_even_full_trauma_is_gone_in_half_a_second())
	results.append(_a_rock_shakes_less_the_farther_it_breaks())
	results.append(await _the_shake_is_the_same_on_screen_at_any_zoom())
	results.append(await _the_option_is_one_by_default_kept_in_range_and_saved())
	results.append(await _the_options_screen_shows_and_changes_the_option())
	results.append(await _each_moment_adds_its_own_trauma())
	results.append(await _his_death_shakes_the_screen_and_not_the_camera())
	results.append(await _with_the_option_at_zero_his_death_leaves_the_screen_put())
	results.append(await _a_pause_puts_the_screen_back_in_place())
	results.append(await _a_level_that_starts_without_his_crucifix_does_not_shake())
	results.append(await _the_demons_do_not_see_the_shake())
	results.append(await _with_no_shake_the_demons_see_what_is_drawn())
	_delete_test_file()
	finish(results)


func _trauma_adds_up_to_one_and_falls_to_zero() -> bool:
	var stats: CameraShakeStats = CameraShakeStats.new()
	var trauma: ShakeTrauma = ShakeTrauma.new(stats)
	trauma.add(0.5)
	trauma.add(0.7)
	var capped: float = trauma.get_trauma()
	trauma.add(-1.0)
	var negative_adds_nothing: bool = is_equal_approx(trauma.get_trauma(), capped)
	trauma.advance(0.25)
	var after_a_quarter: float = trauma.get_trauma()
	var expected: float = 1.0 - stats.decay * 0.25
	trauma.advance(10.0)
	var after_ten: float = trauma.get_trauma()
	return report(is_equal_approx(capped, 1.0) and negative_adds_nothing
			and absf(after_a_quarter - expected) < TOLERANCE and after_ten == 0.0,
			("0.5 and 0.7 of trauma make %.3f (1); a negative amount adds nothing: %s; 0.25 s later "
			+ "it is %.3f (%.3f); 10 s later %.3f (0)")
			% [capped, negative_adds_nothing, after_a_quarter, expected, after_ten])


## Raising the trauma to a level lifts it to that level and no higher, however often it comes, and
## leaves a higher trauma alone.
func _raising_the_trauma_never_piles_up() -> bool:
	var trauma: ShakeTrauma = ShakeTrauma.new(CameraShakeStats.new())
	for raise: int in IN_A_ROW:
		trauma.raise_to(RAISE_LEVEL)
	var after_raises: float = trauma.get_trauma()
	trauma.add(RAISE_LEVEL)
	var higher: float = trauma.get_trauma()
	trauma.raise_to(RAISE_LEVEL)
	var left_alone: bool = is_equal_approx(trauma.get_trauma(), higher)
	return report(is_equal_approx(after_raises, RAISE_LEVEL) and left_alone,
			"%d raises to %.2f in a row leave %.3f (%.2f); a raise leaves a higher trauma alone: %s"
			% [IN_A_ROW, RAISE_LEVEL, after_raises, RAISE_LEVEL, left_alone])


func _the_shake_is_the_trauma_to_the_power_exponent() -> bool:
	var stats: CameraShakeStats = CameraShakeStats.new()
	var trauma: ShakeTrauma = ShakeTrauma.new(stats)
	trauma.add(0.5)
	var expected: float = pow(0.5, stats.exponent)
	return report(absf(trauma.get_shake() - expected) < TOLERANCE,
			"half the trauma shakes %.3f (%.3f, Exponent %.1f)"
			% [trauma.get_shake(), expected, stats.exponent])


func _no_trauma_or_no_option_leaves_the_screen_put() -> bool:
	var trauma: ShakeTrauma = ShakeTrauma.new(CameraShakeStats.new())
	var still_without_trauma: bool = true
	for frame: int in WATCH_FRAMES:
		trauma.advance(FRAME)
		still_without_trauma = still_without_trauma and trauma.get_offset(1.0) == Vector2.ZERO
	var still_without_option: bool = true
	for frame: int in WATCH_FRAMES:
		trauma.add(1.0)
		trauma.advance(FRAME)
		still_without_option = still_without_option and trauma.get_offset(0.0) == Vector2.ZERO
	return report(still_without_trauma and still_without_option,
			"no trauma leaves the screen put: %s; full trauma with the option at 0 leaves it put: %s"
			% [still_without_trauma, still_without_option])


## Trauma kept near 1 for 6 s: the offset stays within Max Offset times the shake on each axis, and
## at some point reaches at least half of Max Offset, so the shake does show.
func _the_screen_moves_but_never_past_max_offset_times_the_shake() -> bool:
	var stats: CameraShakeStats = CameraShakeStats.new()
	var trauma: ShakeTrauma = ShakeTrauma.new(stats)
	var within: bool = true
	var widest: float = 0.0
	for frame: int in SETTLE_FRAMES * 4:
		trauma.add(1.0)
		trauma.advance(FRAME)
		var offset: Vector2 = trauma.get_offset(1.0)
		var reach: float = stats.max_offset * trauma.get_shake() + TOLERANCE
		within = within and absf(offset.x) <= reach and absf(offset.y) <= reach
		widest = maxf(widest, maxf(absf(offset.x), absf(offset.y)))
	return report(within and widest >= stats.max_offset / 2.0,
			"the offset stays within Max Offset times the shake: %s; the widest is %.1f px (at least %.1f)"
			% [within, widest, stats.max_offset / 2.0])


## Trauma kept near 1 for SPEED_FRAMES, with the game camera's stats: each axis passes 0 about
## CROSSINGS_PER_UNIT times a second for each unit of Speed, as Speed's note says.
func _the_screen_passes_its_rest_about_as_often_as_speed_says() -> bool:
	var stats: CameraShakeStats = SHAKE_STATS
	var trauma: ShakeTrauma = ShakeTrauma.new(stats)
	var crossings: int = 0
	var previous: Vector2 = Vector2.ZERO
	for frame: int in SPEED_FRAMES:
		trauma.add(1.0)
		trauma.advance(FRAME)
		var offset: Vector2 = trauma.get_offset(1.0)
		if offset.x * previous.x < 0.0:
			crossings += 1
		if offset.y * previous.y < 0.0:
			crossings += 1
		previous = offset
	var per_second: float = crossings / (2.0 * SPEED_FRAMES * FRAME)
	var expected: float = CROSSINGS_PER_UNIT * stats.speed
	return report(absf(per_second - expected) <= expected * SPEED_TOLERANCE,
			"at Speed %.1f the screen passes its resting place %.1f times a second (%.1f, within %d %%)"
			% [stats.speed, per_second, expected, roundi(SPEED_TOLERANCE * 100.0)])


## With the game camera's stats, full trauma with no impact after it is gone within half a second, so
## no shake lasts longer than that after the last impact, however many came before it.
func _even_full_trauma_is_gone_in_half_a_second() -> bool:
	var stats: CameraShakeStats = SHAKE_STATS
	var trauma: ShakeTrauma = ShakeTrauma.new(stats)
	trauma.add(1.0)
	for frame: int in HALF_SECOND_FRAMES:
		trauma.advance(FRAME)
	return report(trauma.get_trauma() <= TOLERANCE,
			"full trauma half a second later: %.4f (0, at a Decay of %.2f a second)"
			% [trauma.get_trauma(), stats.decay])


func _a_rock_shakes_less_the_farther_it_breaks() -> bool:
	var stats: ImpactStats = ImpactStats.new()
	var at_him: float = stats.rock_trauma_at(0.0)
	var halfway: float = stats.rock_trauma_at(stats.rock_reach / 2.0)
	var at_reach: float = stats.rock_trauma_at(stats.rock_reach)
	var beyond: float = stats.rock_trauma_at(stats.rock_reach * 2.0)
	return report(is_equal_approx(at_him, stats.rock_trauma)
			and absf(halfway - stats.rock_trauma / 2.0) < TOLERANCE and at_reach == 0.0 and beyond == 0.0,
			"a rock's trauma where he is: %.3f (%.3f); halfway to Rock Reach: %.3f; at it: %.3f; past it: %.3f"
			% [at_him, stats.rock_trauma, halfway, at_reach, beyond])


func _the_option_is_one_by_default_kept_in_range_and_saved() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var with_no_file: float = settings.get_screen_shake()
	settings.set_screen_shake(2.0)
	var above: float = settings.get_screen_shake()
	settings.set_screen_shake(-1.0)
	var below: float = settings.get_screen_shake()
	settings.set_screen_shake(NAN)
	var not_a_number: float = settings.get_screen_shake()
	settings.set_screen_shake(0.3)
	settings.queue_free()
	var again: GameSettings = await _new_settings()
	var read_back: float = again.get_screen_shake()
	again.reset_to_defaults()
	var after_reset: float = again.get_screen_shake()
	again.queue_free()
	var default_shake: float = GameSettings.DEFAULT_SCREEN_SHAKE
	return report(with_no_file == default_shake and above == 1.0 and below == 0.0
			and not_a_number == default_shake and is_equal_approx(read_back, 0.3)
			and after_reset == default_shake,
			("with no file %.2f (%.2f); 2 gives %.2f, -1 gives %.2f, nan gives %.2f; 0.3 is read back as "
			+ "%.2f; Reset gives %.2f")
			% [with_no_file, default_shake, above, below, not_a_number, read_back, after_reset])


## Two cameras, at zoom 1 and ZOOM_IN, each with a shake of the game camera's stats, take the same
## trauma at the same frames: the zoomed one's offset, in the world, is the other's divided by
## ZOOM_IN, so both move what is drawn by the same px.
func _the_shake_is_the_same_on_screen_at_any_zoom() -> bool:
	var plain: CameraShake = _new_shake(Vector2.ONE)
	var zoomed: CameraShake = _new_shake(Vector2.ONE * ZOOM_IN)
	await process_frame
	var same: bool = true
	var moved: bool = false
	for frame: int in WATCH_FRAMES:
		plain.add_trauma(1.0)
		zoomed.add_trauma(1.0)
		await process_frame
		same = same and plain.camera.offset.is_equal_approx(zoomed.camera.offset * ZOOM_IN)
		moved = moved or plain.camera.offset != Vector2.ZERO
	plain.camera.queue_free()
	zoomed.camera.queue_free()
	await process_frame
	return report(same and moved,
			"the shake moves the screen: %s; at zoom %.0f its offset is the one at zoom 1 divided by %.0f: %s"
			% [moved, ZOOM_IN, ZOOM_IN, same])


## The options screen on its own, opened with Screen shake at 0.3: its slider, in the accessibility
## grid, goes from 0 to 1 in steps of the screen's own step and shows 0.3 and "30%"; moving it to 0.6
## hands 0.6 to Settings and shows "60%"; Reset brings back the default on both.
func _the_options_screen_shows_and_changes_the_option() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	settings.set_screen_shake(0.3)
	var options: OptionsMenu = OPTIONS_SCENE.instantiate() as OptionsMenu
	root.add_child(options)
	options.open()
	var slider: HSlider = _screen_shake_slider(options)
	var passed: bool = slider != null
	var what: String = "the accessibility grid has no slider"
	if slider != null:
		var steps_right: bool = (slider.min_value == 0.0 and slider.max_value == 1.0
				and is_equal_approx(slider.step, OptionsMenu.SCREEN_SHAKE_STEP))
		var shown: bool = is_equal_approx(slider.value, 0.3) and _text_after(slider) == "30%"
		slider.value = 0.6
		var changed: bool = (is_equal_approx(settings.get_screen_shake(), 0.6)
				and _text_after(slider) == "60%")
		(options.get_node(^"%ResetButton") as Button).pressed.emit()
		var default_shake: float = GameSettings.DEFAULT_SCREEN_SHAKE
		var reset: bool = (is_equal_approx(settings.get_screen_shake(), default_shake)
				and is_equal_approx(slider.value, default_shake)
				and _text_after(slider) == "%d%%" % roundi(default_shake * 100.0))
		passed = steps_right and shown and changed and reset
		what = ("the slider goes from 0 to 1 in steps of %.2f: %s; it shows 0.3 as 30 %%: %s; moved to "
				+ "0.6, it hands 0.6 to Settings and shows 60 %%: %s; Reset brings back the default on "
				+ "both: %s") % [OptionsMenu.SCREEN_SHAKE_STEP, steps_right, shown, changed, reset]
	options.queue_free()
	settings.set_screen_shake(GameSettings.DEFAULT_SCREEN_SHAKE)
	await process_frame
	return report(passed, what)


## The camera finds the player's parts, the hazards and the rocks around it as the level starts, and
## listens to them from the next frame on. Each moment, from rest, adds its own trauma. Its handler
## is called with what its signal carries, so the other listeners (the player's own, the rocks') do
## not run. A normal landing and a hazard hitting another body add none; a rock that breaks near the
## man adds at least what one as far as it can be gives, and one past Rock Reach adds none. Presses
## in a row keep the trauma at Struggle Trauma, and breaking free right after them takes it to Break
## Free Trauma, not on top.
func _each_moment_adds_its_own_trauma() -> bool:
	var floor_body: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var hazard: Hazard = HAZARD_SCENE.instantiate() as Hazard
	hazard.position = HAZARD_AT
	root.add_child(hazard)
	var near_rock: FallingRock = _add_rock(Vector2(START.x + NEAR_ROCK_X, -ROCK_HEIGHT))
	var far_rock: FallingRock = _add_rock(Vector2(START.x + FAR_ROCK_X, -ROCK_HEIGHT))
	var others: Array[Node] = [floor_body, hazard, near_rock, far_rock]
	var player: Player = await spawn_on_floor(START)
	if player == null:
		for node: Node in others:
			node.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	await process_frame
	var impacts: ImpactFeedback = camera.get_node(^"ImpactFeedback") as ImpactFeedback
	var shake: CameraShake = camera.get_node(^"CameraShake") as CameraShake
	var stats: ImpactStats = impacts.stats
	var grab: GrabEscape = player.get_node(^"GrabEscape") as GrabEscape
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var sounds: PlayerSounds = player.get_node(^"PlayerSounds") as PlayerSounds
	var hit: float = stats.hit_trauma
	var near_least: float = stats.rock_trauma_at(NEAR_ROCK_X + ROCK_HEIGHT)
	# What happens, its signal, what the signal carries, and the least and most trauma it may add.
	var moments: Array[Array] = [
		["a hit", (player.get_node(^"Hurtbox") as Hurtbox).hit_received, [null], hit, hit],
		["a hazard on him", hazard.player_hit, [player, hazard.health_fraction], hit, hit],
		["a hazard on another body", hazard.player_hit, [floor_body, hazard.health_fraction], 0.0, 0.0],
		["a grab", grab.grabbed, [], stats.grab_trauma, stats.grab_trauma],
		["breaking free", grab.broke_free, [], stats.break_free_trauma, stats.break_free_trauma],
		["a press to break free", grab.struggled, [true], stats.struggle_trauma, stats.struggle_trauma],
		["holding Jump to break free", grab.struggled, [false], 0.0, 0.0],
		["his death", player.died, [], stats.death_trauma, stats.death_trauma],
		["a hard landing", sounds.land_played, [true], stats.hard_landing_trauma, stats.hard_landing_trauma],
		["a normal landing", sounds.land_played, [false], 0.0, 0.0],
		["raising the crucifix", crucifix.raised, [], stats.crucifix_raised_trauma,
				stats.crucifix_raised_trauma],
		["losing it", crucifix.lost, [], stats.crucifix_lost_trauma, stats.crucifix_lost_trauma],
		["a rock near him", near_rock.broke, [], near_least, stats.rock_trauma],
		["a rock past Rock Reach", far_rock.broke, [], 0.0, 0.0],
	]
	var wrong: Array[String] = []
	for moment: Array in moments:
		await _until_still(shake)
		var before: float = shake.get_trauma()
		if not _call_handler(moment[1], impacts, moment[2]):
			wrong.append("%s: not heard" % moment[0])
			continue
		var added: float = shake.get_trauma() - before
		if added < moment[3] - TOLERANCE or added > moment[4] + TOLERANCE:
			wrong.append("%s: %.3f (%.3f to %.3f)" % [moment[0], added, moment[3], moment[4]])
	await _until_still(shake)
	for press: int in IN_A_ROW:
		_call_handler(grab.struggled, impacts, [true])
	if not is_equal_approx(shake.get_trauma(), stats.struggle_trauma):
		wrong.append("%d presses to break free in a row: %.3f (%.3f)"
				% [IN_A_ROW, shake.get_trauma(), stats.struggle_trauma])
	_call_handler(grab.broke_free, impacts, [])
	if not is_equal_approx(shake.get_trauma(), stats.break_free_trauma):
		wrong.append("breaking free right after them: %.3f (%.3f)"
				% [shake.get_trauma(), stats.break_free_trauma])
	camera.queue_free()
	for node: Node in others:
		node.queue_free()
	await remove_player(player)
	return report(wrong.is_empty(), "each moment adds its own trauma; wrong: %s" % [wrong])


func _his_death_shakes_the_screen_and_not_the_camera() -> bool:
	var floor_body: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(START)
	if player == null:
		floor_body.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	await wait_frames(WATCH_FRAMES)
	var camera_at: Vector2 = camera.global_position
	var still_before: bool = camera.offset == Vector2.ZERO
	player.die()
	var shook: bool = false
	var camera_stayed: bool = true
	for frame: int in HALF_SECOND_FRAMES:
		await process_frame
		shook = shook or camera.offset != Vector2.ZERO
		camera_stayed = camera_stayed and camera.global_position.distance_to(camera_at) <= SAME_SPOT
	# Each read above comes before that frame's shake, so the shake's half second, its last frame
	# included, is over only by the next physics frame. Full trauma ends right on it.
	await physics_frame
	var shake: CameraShake = camera.get_node(^"CameraShake") as CameraShake
	var settled: bool = shake.get_trauma() <= TOLERANCE and camera.offset.length() <= TOLERANCE
	camera.queue_free()
	floor_body.queue_free()
	await remove_player(player)
	return report(still_before and shook and camera_stayed and settled,
			("still before: %s; his death shakes the screen: %s; the camera stays where it was: %s; "
			+ "the shake is gone half a second later: %s")
			% [still_before, shook, camera_stayed, settled])


## The trauma rises, so the screen stays put because of the option and not for want of an impact.
func _with_the_option_at_zero_his_death_leaves_the_screen_put() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	settings.set_screen_shake(0.0)
	var floor_body: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(START)
	var put: bool = player != null
	var trauma_rose: bool = false
	if player != null:
		var camera: GameCamera = _spawn_camera(player)
		await wait_frames(WATCH_FRAMES)
		player.die()
		trauma_rose = (camera.get_node(^"CameraShake") as CameraShake).get_trauma() > 0.0
		for frame: int in WATCH_FRAMES:
			await process_frame
			put = put and camera.offset == Vector2.ZERO
		camera.queue_free()
		floor_body.queue_free()
		await remove_player(player)
	else:
		floor_body.queue_free()
		await process_frame
	settings.set_screen_shake(GameSettings.DEFAULT_SCREEN_SHAKE)
	return report(put and trauma_rose,
			"with Screen shake at 0, his death raises the trauma: %s, and leaves the screen put: %s"
			% [trauma_rose, put])


## The screen shakes and the game pauses: the offset goes back to 0, and what is drawn goes back to
## where it was before the shake, though the camera does not run in the pause. The camera does not
## zoom in as he stands still, so what is drawn moves only with the shake.
func _a_pause_puts_the_screen_back_in_place() -> bool:
	var floor_body: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(START)
	if player == null:
		floor_body.queue_free()
		await process_frame
		return report(false, "the player never landed")
	var camera: GameCamera = _spawn_camera(player, false)
	await wait_frames(WATCH_FRAMES)
	var resting: Vector2 = root.get_canvas_transform().origin
	(camera.get_node(^"CameraShake") as CameraShake).add_trauma(1.0)
	await _frames(SHAKE_FRAMES)
	var shaken_by: float = root.get_canvas_transform().origin.distance_to(resting)
	paused = true
	await process_frame
	var offset_in_pause: Vector2 = camera.offset
	var off_in_pause: float = root.get_canvas_transform().origin.distance_to(resting)
	paused = false
	await _frames(DRAW_FRAMES)
	var shakes_again: bool = camera.offset != Vector2.ZERO
	camera.queue_free()
	floor_body.queue_free()
	await remove_player(player)
	return report(shaken_by > SAME_SPOT and offset_in_pause == Vector2.ZERO and off_in_pause <= SAME_SPOT
			and shakes_again,
			("the shake moves what is drawn by %.2f px; in the pause the offset is %s and what is drawn "
			+ "is %.2f px from where it was (0); the shake goes on after the pause: %s")
			% [shaken_by, offset_in_pause, off_in_pause, shakes_again])


## A level whose man lost the crucifix before takes it from him as it starts (Level), and that is
## no impact: the camera must not shake. Its impacts do listen in that level all the same: his
## death, after the start, raises the trauma.
func _a_level_that_starts_without_his_crucifix_does_not_shake() -> bool:
	var progress: GameProgress = root.get_node_or_null(^"GameState") as GameProgress
	if progress == null:
		return report(false, "the autoload GameState is missing")
	var had_crucifix: bool = progress.has_crucifix
	progress.has_crucifix = false
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	await _frames(START_FRAMES)
	var shake: CameraShake = room.get_node_or_null(^"GameCamera/CameraShake") as CameraShake
	var impacts: ImpactFeedback = room.get_node_or_null(^"GameCamera/ImpactFeedback") as ImpactFeedback
	var player: Player = room.get_node_or_null(^"Player") as Player
	var crucifix_gone: bool = room.get_node_or_null(^"Player/Crucifix") == null
	var trauma: float = shake.get_trauma() if shake != null else -1.0
	var hears_death: bool = (shake != null and impacts != null and player != null
			and _call_handler(player.died, impacts, []) and shake.get_trauma() > 0.0)
	room.queue_free()
	progress.has_crucifix = had_crucifix
	await process_frame
	return report(crucifix_gone and trauma == 0.0 and hears_death,
			("a level that starts without his crucifix takes it: %s; the trauma %d frames later: %.3f (0); "
			+ "its impacts hear his death after the start: %s")
			% [crucifix_gone, START_FRAMES, trauma, hears_death])


## A still camera shakes at full trauma for a second, with two demons by the right edge of where it
## looks, one EDGE_GAP px inside and one EDGE_GAP px outside. On every physics frame, read as a demon
## reads it, the one inside is on screen and the one outside is not, though what is drawn moves. With
## physics interpolation, what is drawn trails the offset by up to two physics frames, so a check
## made from what is drawn, even minus the offset, would see the shake.
func _the_demons_do_not_see_the_shake() -> bool:
	var shake: CameraShake = _new_shake(Vector2.ONE)
	shake.camera.position = START
	var inside: Demon = _new_still_demon()
	var outside: Demon = _new_still_demon()
	await _frames(DRAW_FRAMES)
	var edge: Vector2 = START + Vector2.RIGHT * root.get_visible_rect().size.x / 2.0
	_place_by_edge(inside, edge, Vector2.RIGHT, -EDGE_GAP)
	_place_by_edge(outside, edge, Vector2.RIGHT, EDGE_GAP)
	var watch: OnScreenWatch = OnScreenWatch.new()
	watch.inside = _senses_of(inside)
	watch.outside = _senses_of(outside)
	root.add_child(watch)
	var resting: Vector2 = root.get_canvas_transform().origin
	var drawn_moved: float = 0.0
	for frame: int in 2 * WATCH_FRAMES:
		shake.add_trauma(1.0)
		await process_frame
		drawn_moved = maxf(drawn_moved, root.get_canvas_transform().origin.distance_to(resting))
	var frames: int = watch.frames
	var wrong: int = watch.wrong
	watch.queue_free()
	inside.queue_free()
	outside.queue_free()
	shake.camera.queue_free()
	await process_frame
	return report(frames > 0 and wrong == 0 and drawn_moved > SAME_SPOT,
			("the shake moves what is drawn by up to %.1f px; demons %.0f px inside and outside the edge "
			+ "are seen wrong on %d of %d physics frames (0)") % [drawn_moved, EDGE_GAP, wrong, frames])


## With no shake, against limits that move what is drawn away from where the camera stands (narrower
## than the screen, or wide with the camera past them), a demon EDGE_GAP px inside each edge of what
## is drawn is on screen, and EDGE_GAP px outside it is not, so the demons' screen is the one drawn.
func _with_no_shake_the_demons_see_what_is_drawn() -> bool:
	var camera: Camera2D = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	root.add_child(camera)
	var demon: Demon = _new_still_demon()
	var moved_by_limits: bool = true
	var wrong: Array[String] = []
	for setup: Array in [[NARROW_LIMITS, START], [WIDE_LIMITS, PAST_THE_LIMITS]]:
		var limits: Rect2i = setup[0]
		camera.position = setup[1]
		camera.limit_left = limits.position.x
		camera.limit_top = limits.position.y
		camera.limit_right = limits.end.x
		camera.limit_bottom = limits.end.y
		await _frames(DRAW_FRAMES)
		var drawn: Rect2 = root.get_canvas_transform().affine_inverse() * root.get_visible_rect()
		var centred: Rect2 = Rect2(camera.position - drawn.size / 2.0, drawn.size)
		moved_by_limits = moved_by_limits and not drawn.is_equal_approx(centred)
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var edge: Vector2 = drawn.get_center() + direction * drawn.size / 2.0
			_place_by_edge(demon, edge, direction, -EDGE_GAP)
			var inside_seen: bool = _senses_of(demon).is_on_screen()
			_place_by_edge(demon, edge, direction, EDGE_GAP)
			var outside_seen: bool = _senses_of(demon).is_on_screen()
			if not inside_seen or outside_seen:
				wrong.append("limits %s, side %s: inside %s, outside %s"
						% [limits, direction, inside_seen, outside_seen])
	demon.queue_free()
	camera.queue_free()
	await process_frame
	return report(moved_by_limits and wrong.is_empty(),
			("the limits move what is drawn away from the camera: %s; demons %.0f px inside each of its "
			+ "edges are on screen and %.0f px outside are not; wrong: %s")
			% [moved_by_limits, EDGE_GAP, EDGE_GAP, wrong])


## A game camera following player. One that does not zoom in when he stands still keeps what is
## drawn put while he does: its stats are a copy, so the scene's stay as they are.
func _spawn_camera(player: Player, zooms_in_when_idle: bool = true) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	if not zooms_in_when_idle:
		camera.stats = camera.stats.duplicate() as CameraStats
		camera.stats.idle_zoom = 1.0
	root.add_child(camera)
	return camera


## A camera of its own at zoom, with a shake of the game camera's stats.
func _new_shake(zoom: Vector2) -> CameraShake:
	var camera: Camera2D = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.zoom = zoom
	var shake: CameraShake = CameraShake.new()
	shake.stats = SHAKE_STATS
	shake.camera = camera
	camera.add_child(shake)
	root.add_child(camera)
	return shake


## A demon of DEMON_SCENE with its own physics off, so it stays where the test puts it.
func _new_still_demon() -> Demon:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	root.add_child(demon)
	demon.set_physics_process(false)
	return demon


func _senses_of(demon: Demon) -> DemonSenses:
	return demon.get_node(^"%Senses") as DemonSenses


## Moves demon beside the edge point of a screen, on the side direction points to, level with the
## point: its body gap px outside the edge, or -gap px inside it.
func _place_by_edge(demon: Demon, edge: Vector2, direction: Vector2, gap: float) -> void:
	var senses: DemonSenses = _senses_of(demon)
	var half: Vector2 = senses.body_box.shape.get_rect().size / 2.0
	demon.global_position += edge + direction * (half + Vector2.ONE * gap) - senses.body_box.global_position


func _add_rock(at: Vector2) -> FallingRock:
	var rock: FallingRock = ROCK_SCENE.instantiate() as FallingRock
	rock.position = at
	root.add_child(rock)
	return rock


## Calls listener's handler of sent with args, as if sent had been emitted with them, without
## reaching sent's other listeners; false if listener does not listen to sent.
func _call_handler(sent: Signal, listener: Object, args: Array) -> bool:
	for connection: Dictionary in sent.get_connections():
		var handler: Callable = connection["callable"]
		if handler.get_object() == listener:
			handler.callv(args)
			return true
	return false


## Waits until shake's trauma is back to 0, for SETTLE_FRAMES at most.
func _until_still(shake: CameraShake) -> void:
	for frame: int in SETTLE_FRAMES:
		if shake.get_trauma() == 0.0:
			return
		await process_frame


func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame


func _screen_shake_slider(options: OptionsMenu) -> HSlider:
	var grid: Node = options.get_node_or_null(^"%Accessibility")
	if grid != null:
		for child: Node in grid.get_children():
			if child is HSlider:
				return child as HSlider
	return null


## The text of the label after slider in its grid.
func _text_after(slider: HSlider) -> String:
	var next: int = slider.get_index() + 1
	if next >= slider.get_parent().get_child_count():
		return ""
	var after: Node = slider.get_parent().get_child(next)
	return (after as Label).text if after is Label else ""


func _new_settings() -> GameSettings:
	var settings: GameSettings = SETTINGS_SCRIPT.new() as GameSettings
	settings.path = TEST_PATH
	root.add_child(settings)
	await process_frame
	return settings


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
