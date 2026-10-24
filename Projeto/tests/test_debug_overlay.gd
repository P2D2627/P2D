# Smoke test of the debug overlay. The test room has the overlay, shown and running from the start
# and linked to the room's player. Toggle Debug Overlay is on F3; F3 hides the overlay and stops its
# processing, F3 again brings both back, and holding F3 toggles only once. While the game is paused,
# F3 and the text keep working. Without a player, the text is the frame rate and the two worst step
# times; with one, a second line follows its state and velocity, and goes away when the player is
# freed. A third line shows the man's SP out of Max SP, the speed regeneration gives, and whether it
# is low or has run out. Debug Damage is on F4: a press takes Debug Damage SP from the player once,
# even held down, and nothing while the game is paused; it works with the text hidden too. After
# the first jump, one more line says what the last jump was, from the player's jump signals, and
# how high it went: a full jump peaks at Jump Height. A player freed in the middle of a jump stops
# the overlay following it. With Start Visible off, the overlay starts hidden. In the test room the
# overlay is linked to the camera too, and a camera line shows the zone the player is in and the
# camera's look ahead and look down. That it frees itself outside debug builds can only be checked
# on a release export.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_debug_overlay.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://levels/test_room.tscn")
const OVERLAY_SCENE: PackedScene = preload("res://debug/debug_overlay.tscn")
const PERFORMANCE_LINE: String = (
		"(?m)^\\d+ FPS   worst process \\d+\\.\\d{2} ms   worst physics \\d+\\.\\d{2} ms$")
const PLAYER_LINE: String = "(?m)^state (\\w+)   velocity \\(([+-]\\d+), ([+-]\\d+)\\) px/s$"
const JUMP_LINE: String = "(?m)^jump off (.+)   peak (-?\\d+) px$"
const SP_LINE: String = "(?m)^SP .*$"
const REGEN_IN_SP_LINE: String = "(?m)^SP .*   regen (\\d+\\.\\d) SP/s"
const CAMERA_LINE: String = (
		"(?m)^camera zone (\\S+)   look ahead ([+-]\\d+) px   look down ([+-]\\d+) px$")
## A spot on the test room's floor, right of the first screen.
const FLOOR_SPOT: Vector2 = Vector2(3000.0, 998.0)
## Physics frames for the room's camera to settle after the player moves: 3 s.
const CAMERA_SETTLE_FRAMES: int = 180
## How far a camera value in the text may be from the camera's, in px: the text rounds to whole px.
const CAMERA_TOLERANCE: float = 1.0
## Frames to wait before reading the text, which the overlay writes in _process.
const TEXT_FRAMES: int = 2
## The floor of the case that runs and jumps goes from -FLOOR_HALF_WIDTH to FLOOR_HALF_WIDTH.
const FLOOR_HALF_WIDTH: float = 2000.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## Physics frames after pressing Jump at which the player is surely off the floor and still rising.
const RISE_FRAMES: int = 5
## How far a speed in the text may be from the player's, in px/s: the text rounds to whole numbers.
const SPEED_TOLERANCE: float = 1.0
## Physics frames for a full jump to rise and land again: about 21 up and 15 down.
const FULL_JUMP_FRAMES: int = 60
## Physics frames the jump line must stay unchanged after the last jump.
const LATCH_FRAMES: int = 30
## Lines in the text with a player and no jump yet: the frame rate's, the player's and the SP's.
const LINES_BEFORE_ANY_JUMP: int = 3
## Repeats the keyboard sends while F3 is held down, in the held-key case.
const KEY_REPEATS: int = 3
## The SP values of the SP line case, set on its own copy of the stats so the .tres can change.
const SP_MAX: float = 100.0
const SP_LOW_THRESHOLD: float = 25.0
## The hits of the SP line case: the first leaves 20 SP, below Low Threshold; the second runs out.
const SP_FIRST_HIT: float = 80.0
const SP_SECOND_HIT: float = 100.0
## The pause after a hit and the single regeneration speed of the case of the speed in the SP line.
const SP_SHORT_PAUSE: float = 0.5
const SP_TOP_RATE: float = 3.0


func _initialize() -> void:
	# Without a window the root is 64 × 64 px, and the Expand aspect makes that a 1920 × 1920 screen.
	# A size set before the first frame is undone when the window starts, and a new size takes
	# effect on the next frame.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(_the_toggle_is_on_f3())
	results.append(_the_debug_damage_is_on_f4())
	results.append(await _the_test_room_shows_the_overlay_from_the_start())
	results.append(await _f3_hides_the_overlay_and_f3_again_shows_it())
	results.append(await _holding_f3_toggles_only_once())
	results.append(await _while_paused_f3_and_the_text_keep_working())
	results.append(await _without_a_player_the_text_is_the_performance_line())
	results.append(await _with_start_visible_off_the_overlay_starts_hidden())
	results.append(await _the_player_line_follows_the_player())
	results.append(await _a_freed_player_leaves_only_the_performance_line())
	results.append(await _the_sp_line_says_the_sp_and_whether_it_is_low_or_run_out())
	results.append(await _the_sp_line_shows_the_regen_rate())
	results.append(await _f4_takes_debug_damage_once_and_not_while_paused())
	results.append(await _f4_works_with_the_text_hidden())
	results.append(await _a_full_jump_shows_its_peak_at_jump_height())
	results.append(await _the_jump_line_says_what_each_jump_was_and_keeps_it())
	results.append(await _a_player_freed_mid_jump_stops_the_following())
	results.append(await _the_camera_line_follows_the_room_s_camera())
	finish(results)


## Toggle Debug Overlay is in the Input Map, on F3.
func _the_toggle_is_on_f3() -> bool:
	var keys: PackedStringArray = _keys_of(DebugOverlay.TOGGLE_ACTION)
	return report(keys.has("F3"), "Toggle Debug Overlay keys: [%s]" % ", ".join(keys))


func _the_debug_damage_is_on_f4() -> bool:
	var keys: PackedStringArray = _keys_of(DebugOverlay.DAMAGE_ACTION)
	return report(keys.has("F4"), "Debug Damage keys: [%s]" % ", ".join(keys))


## The test room has the overlay, shown and running from the start, with the process mode that
## keeps it working while the game is paused, and linked to the room's player, whose SP line shows
## next to the camera's.
func _the_test_room_shows_the_overlay_from_the_start() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	await process_frame
	var overlay: DebugOverlay = _find_overlay(room)
	if overlay == null:
		await _remove(room)
		return report(false, "Test room: no debug overlay")
	var is_ready: bool = overlay.is_node_ready()
	var always: bool = overlay.process_mode == Node.PROCESS_MODE_ALWAYS
	var linked: bool = overlay.player != null and overlay.player == room.get_node_or_null(^"Player")
	var shown: bool = overlay.visible
	var processing: bool = overlay.is_processing()
	await _wait_process_frames(TEXT_FRAMES)
	var sp_line: String = _sp_line(overlay)
	var passed: bool = (is_ready and shown and processing and always and linked
			and not sp_line.is_empty())
	var what: String = ("Test room: ready %s, shown %s, processing %s, Always %s, player linked %s, "
			+ "SP line \"%s\"") % [is_ready, shown, processing, always, linked, sp_line]
	await _remove(room)
	return report(passed, what)


## F3 hides the overlay and stops its processing, and a second F3 brings both back.
func _f3_hides_the_overlay_and_f3_again_shows_it() -> bool:
	var overlay: DebugOverlay = await _spawn_overlay(true)
	_press_f3()
	var hidden: bool = not overlay.visible and not overlay.is_processing()
	_press_f3()
	var shown: bool = overlay.visible and overlay.is_processing()
	await _remove(overlay)
	return report(hidden and shown,
			"F3: hidden and idle after the first press %s, shown and running after the second %s"
			% [hidden, shown])


## Without a player, the text is one line, with the frame rate and both frame times.
func _without_a_player_the_text_is_the_performance_line() -> bool:
	var overlay: DebugOverlay = await _spawn_overlay(true)
	await _wait_process_frames(TEXT_FRAMES)
	var text: String = _text(overlay)
	await _remove(overlay)
	return report(_is_only_the_performance_line(text), "Text without a player: \"%s\"" % text)


## With Start Visible off, the overlay starts hidden and idle, as a playtest would want it.
func _with_start_visible_off_the_overlay_starts_hidden() -> bool:
	var overlay: DebugOverlay = await _spawn_overlay(false)
	var is_ready: bool = overlay.is_node_ready()
	var was_visible: bool = overlay.visible
	var was_processing: bool = overlay.is_processing()
	await _remove(overlay)
	return report(is_ready and not was_visible and not was_processing,
			"Start Visible off: ready %s, visible %s, processing %s"
			% [is_ready, was_visible, was_processing])


## The player's line follows the player: on the floor at rest, on the floor at top running speed,
## and in the air going up after a jump.
func _the_player_line_follows_the_player() -> bool:
	var platform: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(platform)
		return report(false, "Player line: the player never landed")
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	await _wait_process_frames(TEXT_FRAMES)
	var at_rest: PlayerLine = _read_player_line(overlay)
	Input.action_press(&"move_right")
	await _wait_until_at_top_run_speed(player)
	await _wait_process_frames(TEXT_FRAMES)
	var running: PlayerLine = _read_player_line(overlay)
	Input.action_release(&"move_right")
	Input.action_press(&"jump")
	await _wait_physics_frames(RISE_FRAMES)
	await _wait_process_frames(TEXT_FRAMES)
	var rising: PlayerLine = _read_player_line(overlay)
	Input.action_release(&"jump")
	var top_speed: float = player.stats.max_run_speed
	var passed: bool = (at_rest.is_like("ON_FLOOR", Vector2.ZERO, SPEED_TOLERANCE)
			and running.is_like("ON_FLOOR", Vector2(top_speed, 0.0), SPEED_TOLERANCE)
			and rising.found and rising.state == "IN_AIR" and rising.velocity.y < 0.0)
	await _remove(overlay)
	await _remove(player)
	await _remove(platform)
	return report(passed, "Player line: at rest \"%s\", running \"%s\", rising \"%s\""
			% [at_rest.text, running.text, rising.text])


## When the player is freed, as on a respawn, the text goes back to the performance line, and the
## overlay keeps working.
func _a_freed_player_leaves_only_the_performance_line() -> bool:
	# No floor in this case: the player just falls until it is freed.
	var player: Player = spawn_player(Vector2.ZERO)
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	await _wait_process_frames(TEXT_FRAMES)
	var had_player_line: bool = _read_player_line(overlay).found
	player.queue_free()
	await _wait_process_frames(TEXT_FRAMES)
	var text: String = _text(overlay)
	await _remove(overlay)
	return report(had_player_line and _is_only_the_performance_line(text),
			"Freed player: player line before %s, text after \"%s\"" % [had_player_line, text])


## The SP line shows the man's SP out of Max SP, then "low" once a hit leaves him at or below Low
## Threshold, and "run out" once a hit takes them all. His regeneration is off in a copy of his
## stats, so the SP stay where the hits leave them.
func _the_sp_line_says_the_sp_and_whether_it_is_low_or_run_out() -> bool:
	# No floor in this case: the player just falls while the text is read.
	var player: Player = spawn_player(Vector2.ZERO)
	var stats: SoulPointsStats = player.soul_points.stats.duplicate() as SoulPointsStats
	stats.max_sp = SP_MAX
	stats.low_threshold = SP_LOW_THRESHOLD
	stats.regen_start_per_second = 0.0
	stats.regen_top_per_second = 0.0
	player.soul_points.stats = stats
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	await _wait_process_frames(TEXT_FRAMES)
	var full: String = _sp_line(overlay)
	player.soul_points.take_damage(SP_FIRST_HIT)
	await _wait_process_frames(TEXT_FRAMES)
	var low: String = _sp_line(overlay)
	player.soul_points.take_damage(SP_SECOND_HIT)
	await _wait_process_frames(TEXT_FRAMES)
	var run_out: String = _sp_line(overlay)
	await _remove(overlay)
	await _remove(player)
	var heard: Array[String] = [full, low, run_out]
	var expected: Array[String] = ["SP 100.0 / 100   regen 0.0 SP/s",
			"SP 20.0 / 100   regen 0.0 SP/s   low", "SP 0.0 / 100   regen 0.0 SP/s   run out"]
	return report(heard == expected, "SP line: %s, expected %s" % [heard, expected])


## The SP line shows the speed regeneration gives: none during the pause after a hit, and its speed
## once it runs. The ramp of a copy of the stats is 0 s, so the speed does not change while the text
## is read.
func _the_sp_line_shows_the_regen_rate() -> bool:
	var player: Player = spawn_player(Vector2.ZERO)
	var stats: SoulPointsStats = player.soul_points.stats.duplicate() as SoulPointsStats
	stats.regen_delay = SP_SHORT_PAUSE
	stats.regen_top_per_second = SP_TOP_RATE
	stats.regen_ramp_time = 0.0
	player.soul_points.stats = stats
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	player.soul_points.take_damage(SP_FIRST_HIT)
	await _wait_process_frames(TEXT_FRAMES)
	var in_the_pause: String = _regen_in_sp_line(overlay)
	await _wait_physics_frames(stats.get_regen_delay_frames())
	await _wait_process_frames(TEXT_FRAMES)
	var running: String = _regen_in_sp_line(overlay)
	await _remove(overlay)
	await _remove(player)
	var expected_running: String = "%.1f" % SP_TOP_RATE
	return report(in_the_pause == "0.0" and running == expected_running,
			"Regeneration in the SP line: %s SP/s in the pause, %s SP/s after it, expected 0.0 and %s"
			% [in_the_pause, running, expected_running])


## A press of F4 takes Debug Damage SP from the player once, even held down with its repeats, and
## nothing while the game is paused.
func _f4_takes_debug_damage_once_and_not_while_paused() -> bool:
	var player: Player = spawn_player(Vector2.ZERO)
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	var soul_points: SoulPoints = player.soul_points
	var expected: float = soul_points.get_sp() - overlay.debug_damage
	root.push_input(_key_event(KEY_F4, true, false))
	for _repeat: int in KEY_REPEATS:
		root.push_input(_key_event(KEY_F4, true, true))
	root.push_input(_key_event(KEY_F4, false, false))
	var after_a_press: float = soul_points.get_sp()
	paused = true
	_press_key(KEY_F4)
	var after_a_paused_press: float = soul_points.get_sp()
	paused = false
	await _remove(overlay)
	await _remove(player)
	return report(after_a_press == expected and after_a_paused_press == expected,
			"F4 held, with %d repeats: %.1f SP; F4 while paused: %.1f SP; expected %.1f"
			% [KEY_REPEATS, after_a_press, after_a_paused_press, expected])


## With the text hidden, F4 still takes Debug Damage SP from the player.
func _f4_works_with_the_text_hidden() -> bool:
	var player: Player = spawn_player(Vector2.ZERO)
	var overlay: DebugOverlay = await _spawn_overlay(false, player)
	var soul_points: SoulPoints = player.soul_points
	var expected: float = soul_points.get_sp() - overlay.debug_damage
	_press_key(KEY_F4)
	var after_a_press: float = soul_points.get_sp()
	var hidden: bool = not overlay.visible
	await _remove(overlay)
	await _remove(player)
	return report(hidden and after_a_press == expected,
			"F4 with the text hidden (hidden %s): %.1f SP, expected %.1f"
			% [hidden, after_a_press, expected])


## A full jump from the floor, holding Jump: the jump line says it was on time, and once the player
## has landed again it still shows the peak, at Jump Height.
func _a_full_jump_shows_its_peak_at_jump_height() -> bool:
	var platform: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(platform)
		return report(false, "Full jump: the player never landed")
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	Input.action_press(&"jump")
	await _wait_physics_frames(FULL_JUMP_FRAMES)
	Input.action_release(&"jump")
	await _wait_process_frames(TEXT_FRAMES)
	var landed: bool = player.is_on_floor()
	var line: RegExMatch = RegEx.create_from_string(JUMP_LINE).search(_text(overlay))
	var jump_height: float = player.stats.jump_height
	var passed: bool = (landed and line != null and line.get_string(1) == "the floor   on time"
			and line.get_string(2) == "%.0f" % jump_height)
	var shown: String = line.get_string() if line != null else "no jump line"
	await _remove(overlay)
	await _remove(player)
	await _remove(platform)
	return report(passed, "Full jump, landed again %s: \"%s\", Jump Height %.0f px"
			% [landed, shown, jump_height])


## The jump line comes from the player's signals, sent here by hand: there is none before the first
## jump, it says what each jump was off and which tolerance it used, out of the frames in Stats,
## and it stays until the next jump. The player stands still, so each peak is 0.
func _the_jump_line_says_what_each_jump_was_and_keeps_it() -> bool:
	var platform: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(platform)
		return report(false, "Jump line: the player never landed")
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	await _wait_process_frames(TEXT_FRAMES)
	var lines_before: int = _text(overlay).split("\n").size()
	var coyote: int = player.stats.get_coyote_frames()
	var buffer: int = player.stats.get_jump_buffer_frames()
	var heard: PackedStringArray = []
	player.jumped.emit(coyote - 1, 0)
	await _wait_process_frames(TEXT_FRAMES)
	heard.append(_jump_line(overlay))
	player.wall_jumped.emit(0, buffer - 2)
	await _wait_process_frames(TEXT_FRAMES)
	heard.append(_jump_line(overlay))
	player.jumped.emit(0, 0)
	await _wait_process_frames(TEXT_FRAMES)
	heard.append(_jump_line(overlay))
	await _wait_physics_frames(LATCH_FRAMES)
	heard.append(_jump_line(overlay))
	var expected: PackedStringArray = [
		"jump off the floor   coyote %d/%d frames late   peak 0 px" % [coyote - 1, coyote],
		"jump off a wall   buffer %d/%d frames early   peak 0 px" % [buffer - 2, buffer],
		"jump off the floor   on time   peak 0 px",
		"jump off the floor   on time   peak 0 px",
	]
	await _remove(overlay)
	await _remove(player)
	await _remove(platform)
	return report(lines_before == LINES_BEFORE_ANY_JUMP and heard == expected,
			"Jump line: %d lines before any jump; then \"%s\""
			% [lines_before, "\", \"".join(heard)])


## Holding F3 down sends repeats after the first press, and only that first press toggles.
func _holding_f3_toggles_only_once() -> bool:
	var overlay: DebugOverlay = await _spawn_overlay(true)
	root.push_input(_f3_event(true, false))
	for _repeat: int in KEY_REPEATS:
		root.push_input(_f3_event(true, true))
	root.push_input(_f3_event(false, false))
	var hidden: bool = not overlay.visible
	await _remove(overlay)
	return report(hidden, "F3 held, with %d repeats: hidden %s" % [KEY_REPEATS, hidden])


## While the game is paused, the overlay keeps processing: F3 still hides and shows it, and the
## text is still written.
func _while_paused_f3_and_the_text_keep_working() -> bool:
	var overlay: DebugOverlay = await _spawn_overlay(true)
	paused = true
	_press_f3()
	var hidden: bool = not overlay.visible
	_press_f3()
	var shown: bool = overlay.visible
	var label: Label = overlay.get_node(^"%Label") as Label
	label.text = ""
	await _wait_process_frames(TEXT_FRAMES)
	var rewritten: bool = not label.text.is_empty()
	paused = false
	await _remove(overlay)
	return report(hidden and shown and rewritten,
			"Paused: F3 hides %s, F3 shows %s, text rewritten %s" % [hidden, shown, rewritten])


## A player freed in the middle of a jump stops the overlay following it up, instead of reading a
## freed player on every physics frame, and the text goes back to the performance line.
func _a_player_freed_mid_jump_stops_the_following() -> bool:
	var platform: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(platform)
		return report(false, "Freed mid-jump: the player never landed")
	var overlay: DebugOverlay = await _spawn_overlay(true, player)
	Input.action_press(&"jump")
	await _wait_physics_frames(RISE_FRAMES)
	Input.action_release(&"jump")
	var following: bool = overlay.is_physics_processing()
	player.queue_free()
	await _wait_physics_frames(TEXT_FRAMES)
	await _wait_process_frames(TEXT_FRAMES)
	var stopped: bool = not overlay.is_physics_processing()
	var text: String = _text(overlay)
	await _remove(overlay)
	await _remove(platform)
	return report(following and stopped and _is_only_the_performance_line(text),
			"Freed mid-jump: following before %s, stopped after %s, text after \"%s\""
			% [following, stopped, text])


## In the test room the overlay is linked to the room's camera too, and a camera line shows what the
## camera gives: the zone the player is in, the look ahead and the look down. The line matches the
## camera at the start, and again with the player moved along the floor and the camera settled
## there, leading ahead.
func _the_camera_line_follows_the_room_s_camera() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	var overlay: DebugOverlay = _find_overlay(room)
	var camera: GameCamera = room.get_node(^"GameCamera") as GameCamera
	# The player stands still the whole case, and the camera would settle on it after Idle Delay,
	# taking the lead back to nothing while the case reads it; this case wants it leading ahead.
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.idle_delay = INF
	var player: Player = room.get_node(^"Player") as Player
	var linked: bool = overlay.get(&"camera") == camera
	await _wait_process_frames(TEXT_FRAMES)
	var at_start: CameraLine = _read_camera_line(overlay)
	var start_right: bool = at_start.is_like(camera.get_zone_name(), camera.get_look_ahead(),
			camera.get_look_down(), CAMERA_TOLERANCE)
	player.global_position = FLOOR_SPOT
	player.reset_physics_interpolation()
	await _wait_physics_frames(CAMERA_SETTLE_FRAMES)
	await _wait_process_frames(TEXT_FRAMES)
	var after_the_move: CameraLine = _read_camera_line(overlay)
	var moved_right: bool = after_the_move.is_like(camera.get_zone_name(), camera.get_look_ahead(),
			camera.get_look_down(), CAMERA_TOLERANCE)
	await _remove(room)
	return report(linked and start_right and moved_right,
			"Camera line: linked %s; at the start \"%s\"; after the move \"%s\""
			% [linked, at_start.text, after_the_move.text])


## An overlay on its own, linked to linked_player if one is given, in the scene, after a frame. The
## frame matters: _initialize runs before the root is in the tree, so a node added then only gets
## its _ready once _initialize yields.
func _spawn_overlay(start_visible: bool, linked_player: Player = null) -> DebugOverlay:
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.start_visible = start_visible
	overlay.player = linked_player
	root.add_child(overlay)
	await process_frame
	return overlay


func _find_overlay(room: Node) -> DebugOverlay:
	for child: Node in room.get_children():
		if child is DebugOverlay:
			return child as DebugOverlay
	return null


func _text(overlay: DebugOverlay) -> String:
	return (overlay.get_node(^"%Label") as Label).text


func _is_only_the_performance_line(text: String) -> bool:
	var has_it: bool = RegEx.create_from_string(PERFORMANCE_LINE).search(text) != null
	return has_it and not text.contains("\n")


## The jump line of the text, or "" if there is none.
func _jump_line(overlay: DebugOverlay) -> String:
	var found: RegExMatch = RegEx.create_from_string(JUMP_LINE).search(_text(overlay))
	return found.get_string() if found != null else ""


## The SP line of the text, or "" if there is none.
func _sp_line(overlay: DebugOverlay) -> String:
	var found: RegExMatch = RegEx.create_from_string(SP_LINE).search(_text(overlay))
	return found.get_string() if found != null else ""


## The regeneration speed in the SP line, as text such as "1.5", or "" if there is none.
func _regen_in_sp_line(overlay: DebugOverlay) -> String:
	var found: RegExMatch = RegEx.create_from_string(REGEN_IN_SP_LINE).search(_text(overlay))
	return found.get_string(1) if found != null else ""


func _read_player_line(overlay: DebugOverlay) -> PlayerLine:
	var line: PlayerLine = PlayerLine.new()
	var found: RegExMatch = RegEx.create_from_string(PLAYER_LINE).search(_text(overlay))
	if found != null:
		line.found = true
		line.text = found.get_string()
		line.state = found.get_string(1)
		line.velocity = Vector2(found.get_string(2).to_float(), found.get_string(3).to_float())
	return line


func _read_camera_line(overlay: DebugOverlay) -> CameraLine:
	var line: CameraLine = CameraLine.new()
	var found: RegExMatch = RegEx.create_from_string(CAMERA_LINE).search(_text(overlay))
	if found != null:
		line.found = true
		line.text = found.get_string()
		line.zone = found.get_string(1)
		line.look_ahead = found.get_string(2).to_float()
		line.look_down = found.get_string(3).to_float()
	return line


## One press and release of F3, sent through the viewport as the keyboard would.
func _press_f3() -> void:
	_press_key(KEY_F3)


func _press_key(keycode: Key) -> void:
	root.push_input(_key_event(keycode, true, false))
	root.push_input(_key_event(keycode, false, false))


func _f3_event(pressed: bool, echo: bool) -> InputEventKey:
	return _key_event(KEY_F3, pressed, echo)


## A key event; echo marks the repeats the keyboard sends while a key is held down.
func _key_event(keycode: Key, pressed: bool, echo: bool) -> InputEventKey:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = keycode
	key.physical_keycode = keycode
	key.pressed = pressed
	key.echo = echo
	return key


## The keys of an action in the Input Map, by name, such as "F3"; none if the action is missing.
func _keys_of(action: StringName) -> PackedStringArray:
	var keys: PackedStringArray = []
	if InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(OS.get_keycode_string((event as InputEventKey).physical_keycode))
	return keys


func _wait_until_at_top_run_speed(player: Player) -> void:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.velocity.x >= player.stats.max_run_speed:
			return


func _wait_physics_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


func _wait_process_frames(frames: int) -> void:
	for _frame: int in frames:
		await process_frame


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame


## What the player's line of the text says. found is false if the text has no such line.
class PlayerLine:
	var found: bool = false
	var text: String = ""
	var state: String = ""
	var velocity: Vector2 = Vector2.ZERO

	## True if the line is there, with this state and a velocity within tolerance of this one.
	func is_like(expected_state: String, expected_velocity: Vector2, tolerance: float) -> bool:
		return (found and state == expected_state
				and absf(velocity.x - expected_velocity.x) <= tolerance
				and absf(velocity.y - expected_velocity.y) <= tolerance)


## What the camera's line of the text says. found is false if the text has no such line.
class CameraLine:
	var found: bool = false
	var text: String = ""
	var zone: String = ""
	var look_ahead: float = 0.0
	var look_down: float = 0.0

	## True if the line is there, naming this zone, with a look ahead and a look down within
	## tolerance of these.
	func is_like(expected_zone: String, expected_look_ahead: float, expected_look_down: float,
			tolerance: float) -> bool:
		return (found and zone == expected_zone
				and absf(look_ahead - expected_look_ahead) <= tolerance
				and absf(look_down - expected_look_down) <= tolerance)
