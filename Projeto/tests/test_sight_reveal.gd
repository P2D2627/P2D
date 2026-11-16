# Checks SightReveal with the man's eyes in a scene (#253). With no eyes in the tree, all is drawn,
# but nothing counts as seen: one that remembers, behind a wall when the man comes, fades out. A box
# in plain sight is drawn; one behind a wall stays undrawn; a one-way platform does not hide it, nor
# does someone standing on the world's layer, as Velvet's body does. Seen and then put behind a
# wall, it stays drawn for a while and then fades out; one that remembers stays drawn and stops
# looking. A wide box seen only near one end is drawn in part, while narrow boxes at its other end
# and its middle stay hidden. With senses that see the man, a box behind a wall is drawn, and with
# senses that do not, it is not. The game's demon behind a wall is undrawn and is drawn once the wall
# is gone; behind a slab that hides it from the man but not him from it, it is drawn, through its
# senses; hidden, it is drawn in full on the frame it starts an attack's warning. The game's spikes
# behind a wall stay undrawn, while in plain sight they are drawn and then stop looking. Paused, a
# fade stops where it is. With the player's Show Hidden on, a box behind a wall is drawn, and turned
# off, it fades out again; turned on in the pause, it applies as play resumes. With no Look Box, a
# box is always drawn, and a warning says so (printed on purpose, once). With a camera, what is past
# the screen and the eyes' margin is not seen, even in plain sight. Within Near Radius of his eyes,
# a box behind a wall is drawn. A post whose top spot is hidden behind a slab, with its middle and
# bottom spots in sight, is drawn in full, while the same post looking at its top only (Rows 1)
# stays hidden; with only its bottom spot in sight, it is drawn in part, neither nothing nor all,
# and one that remembers is then drawn in full. Someone standing in front of a wall does not let the
# man see through the wall.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sight_reveal.gd
extends "res://tests/support/player_test.gd"

const StandInSenses = preload("res://tests/support/stand_in_senses.gd")
const DEMON_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
const SPIKES_SCENE: PackedScene = preload("res://scenes/objects/traps/lethal_spikes.tscn")
## The values the stand-in boxes are written for, so tuning the game changes no case.
const FADE_IN: float = 0.1
const FADE_OUT: float = 0.2
const LINGER: float = 0.2
const LOOK_EVERY: int = 3
## The box looked at, standing on the floor.
const BOX_SIZE: Vector2 = Vector2(64.0, 40.0)
## Where the boxes stand: well inside one screen of the man, who stands at x = 0.
const BOX_X: float = 400.0
## Physics frames to watch a box that should stay as it is.
const WATCH_FRAMES: int = 60
## The one-way platforms' physics layer, 9, as a mask.
const ONE_WAY_LAYER: int = 1 << 8
## Within this many px of his eyes, a box is seen through anything.
const NEAR_RADIUS: float = 240.0
## Two of three rows of spots seen draw a box in full.
const FULL_SHARE: float = 0.5
## A wall between the man and a box close to him, at x = 180: its nearest corner is about 154 px
## from his eyes.
const NEAR_WALL_LEFT: float = 100.0
const NEAR_WALL_RIGHT: float = 140.0
const NEAR_BOX_X: float = 180.0
## A post too narrow for more than one spot per row: at x = 400, its three spots sit 36, 21 and 6 px
## up, and two of them seen draw it in full.
const POST_SIZE: Vector2 = Vector2(12.0, 40.0)
## A slab just short of the post. It cuts the ray from his eyes, 84 px up, to the top spot with about
## 6 px to spare each way, and the rays to the middle and bottom spots pass under it. The deeper one
## also cuts the middle spot's ray, with about 5 px to spare over the bottom spot's.
const POST_SLAB_LEFT: float = 380.0
const POST_SLAB_RIGHT: float = 390.0
const POST_SLAB_TOP: float = -60.0
const POST_SLAB_BOTTOM: float = -31.0
const DEEP_POST_SLAB_BOTTOM: float = -15.0
## A wall just past someone standing where the full wall would be.
const PAST_SOMEONE_WALL_LEFT: float = 280.0
const PAST_SOMEONE_WALL_RIGHT: float = 320.0
## A wall between the man and the boxes, from the floor up past anything his eyes could see over.
const WALL_LEFT: float = 200.0
const WALL_RIGHT: float = 240.0
const WALL_TOP: float = -400.0
## A low wall nearer the man: from his eyes, 84 px up, it hides the row of spots of a box 40 px tall
## (36 px up) out to about x = 960, and not past it.
const LOW_WALL_LEFT: float = 150.0
const LOW_WALL_RIGHT: float = 190.0
const LOW_WALL_TOP: float = -74.0
## A thin slab between the man and the game's demon at x = 400: it cuts every ray from his eyes to
## the demon's row of spots, 52 px up, and lets the demon's own, level at 48 px up, pass under it.
const SLAB_LEFT: float = 50.0
const SLAB_RIGHT: float = 350.0
const SLAB_TOP: float = -68.0
const SLAB_BOTTOM: float = -62.0


func _initialize() -> void:
	make_platform(-3000.0, 3000.0)
	var results: Array[bool] = []
	# Before the man comes: a box that remembers, behind a wall, with no eyes to see it.
	var wall: StaticBody2D = _make_full_wall()
	var early: SightReveal = _make_box(Vector2(BOX_X, 0.0), true)
	var drawn_with_no_eyes: bool = await wait_until(
			func() -> bool: return early.get_opacity() >= 1.0, WATCH_FRAMES)
	var player: Player = await spawn_on_floor(Vector2(0.0, -10.0))
	if player == null:
		results.append(report(false, "The man never landed"))
		finish(results)
		return
	results.append(await _with_no_eyes_all_is_drawn_but_nothing_seen(early, drawn_with_no_eyes,
			wall))
	results.append(await _in_plain_sight_it_is_drawn())
	results.append(await _behind_a_wall_it_stays_undrawn())
	results.append(await _a_one_way_platform_does_not_hide_it())
	results.append(await _someone_on_the_world_layer_does_not_hide_it())
	results.append(await _someone_in_front_of_a_wall_does_not_let_it_through())
	results.append(await _out_of_sight_it_lingers_then_fades_out())
	results.append(await _one_that_remembers_stays_drawn_and_stops_looking())
	results.append(await _a_wide_box_seen_at_one_end_is_drawn_in_part())
	results.append(await _a_demon_that_sees_the_man_is_drawn())
	results.append(await _the_game_s_demon_hides_behind_a_wall())
	results.append(await _the_game_s_demon_that_sees_the_man_is_drawn())
	results.append(await _the_game_s_demon_is_drawn_in_full_as_it_warns())
	results.append(await _the_game_s_spikes_hide_then_stay_once_seen())
	results.append(await _paused_a_fade_stops_where_it_is())
	results.append(await _show_hidden_draws_what_is_behind_a_wall())
	results.append(await _show_hidden_turned_on_in_the_pause_applies_as_play_resumes())
	results.append(await _with_no_look_box_it_is_always_drawn())
	results.append(await _off_the_screen_nothing_is_seen())
	results.append(await _near_his_eyes_it_is_drawn_behind_a_wall())
	results.append(await _with_its_top_hidden_its_body_shows_it())
	results.append(await _mostly_hidden_it_is_drawn_in_part())
	results.append(await _one_that_remembers_seen_in_part_is_drawn_in_full())
	finish(results)


## The box made before the man came: drawn with no eyes, and once he is there, behind the wall, it
## fades out, since what was drawn with no eyes was not seen.
func _with_no_eyes_all_is_drawn_but_nothing_seen(early: SightReveal, drawn_with_no_eyes: bool,
		wall: StaticBody2D) -> bool:
	var gone: bool = await wait_until(func() -> bool: return is_zero_approx(early.get_opacity()),
			WATCH_FRAMES)
	await _remove([early.get_parent(), wall])
	return report(drawn_with_no_eyes and gone,
			("No eyes in the tree: a box that remembers, behind a wall, drawn %s (expected true); "
			+ "with the man there, gone %s (expected true)") % [drawn_with_no_eyes, gone])


func _in_plain_sight_it_is_drawn() -> bool:
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	var alpha: float = (reveal.get_parent() as CanvasItem).modulate.a
	await _remove([reveal.get_parent()])
	return report(drawn and is_equal_approx(alpha, 1.0),
			"In plain sight: drawn %s, modulate alpha %s (expected true, 1)" % [drawn, alpha])


func _behind_a_wall_it_stays_undrawn() -> bool:
	var wall: StaticBody2D = _make_full_wall()
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var highest: float = await _highest_opacity(reveal, WATCH_FRAMES)
	await _remove([reveal.get_parent(), wall])
	return report(is_zero_approx(highest),
			"Behind a wall for %d frames: highest opacity %s (expected 0)" % [WATCH_FRAMES, highest])


func _a_one_way_platform_does_not_hide_it() -> bool:
	var platform: StaticBody2D = _make_full_wall()
	platform.collision_layer = ONE_WAY_LAYER
	for child: Node in platform.get_children():
		(child as CollisionShape2D).one_way_collision = true
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), platform])
	return report(drawn, "Behind a one-way platform: drawn %s (expected true)" % drawn)


## Velvet's body is a CharacterBody2D left on the world's layer. Someone as tall as the wall, where
## the wall would be, does not hide the box: only the world blocks the man's sight.
func _someone_on_the_world_layer_does_not_hide_it() -> bool:
	var someone: CharacterBody2D = _make_someone_standing()
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), someone])
	return report(drawn, ("Behind someone standing on the world's layer: drawn %s (expected true)"
			% drawn))


## The ray goes past someone's body, but not past the wall behind it.
func _someone_in_front_of_a_wall_does_not_let_it_through() -> bool:
	var someone: CharacterBody2D = _make_someone_standing()
	var wall: StaticBody2D = make_wall(PAST_SOMEONE_WALL_LEFT, PAST_SOMEONE_WALL_RIGHT, WALL_TOP)
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var highest: float = await _highest_opacity(reveal, WATCH_FRAMES)
	await _remove([reveal.get_parent(), someone, wall])
	return report(is_zero_approx(highest),
			("Behind someone standing in front of a wall, for %d frames: highest opacity %s "
			+ "(expected 0)") % [WATCH_FRAMES, highest])


func _out_of_sight_it_lingers_then_fades_out() -> bool:
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	var wall: StaticBody2D = _make_full_wall()
	var linger_frames: int = floori(LINGER * Engine.physics_ticks_per_second) - LOOK_EVERY - 2
	await wait_frames(linger_frames)
	var lingering: float = reveal.get_opacity()
	var gone: bool = await wait_until(func() -> bool: return is_zero_approx(reveal.get_opacity()),
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), wall])
	return report(drawn and is_equal_approx(lingering, 1.0) and gone,
			("Seen, then behind a wall: drawn %s, opacity %s after %d frames (expected 1), then gone "
			+ "%s (expected true)") % [drawn, lingering, linger_frames, gone])


func _one_that_remembers_stays_drawn_and_stops_looking() -> bool:
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0), true)
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	var wall: StaticBody2D = _make_full_wall()
	var lowest: float = await _lowest_opacity(reveal, WATCH_FRAMES)
	var looking: bool = reveal.is_physics_processing() or reveal.is_processing()
	await _remove([reveal.get_parent(), wall])
	return report(drawn and is_equal_approx(lowest, 1.0) and not looking,
			("Remembers, seen, then behind a wall for %d frames: lowest opacity %s (expected 1), "
			+ "still looking %s (expected false)") % [WATCH_FRAMES, lowest, looking])


## Behind the low wall, a box from x = 400 to 1200 is seen only by the top spots near its right end,
## a few of the many across it, so it is drawn in part: neither cut off nor drawn whole. Narrow boxes
## at its left end and at its middle stay hidden.
func _a_wide_box_seen_at_one_end_is_drawn_in_part() -> bool:
	var wall: StaticBody2D = make_wall(LOW_WALL_LEFT, LOW_WALL_RIGHT, LOW_WALL_TOP)
	var narrow: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var middle: SightReveal = _make_box(Vector2(800.0, 0.0))
	var wide: SightReveal = _make_box(Vector2(800.0, 0.0), false, Vector2(800.0, BOX_SIZE.y))
	var wide_highest: float = await _highest_opacity(wide, WATCH_FRAMES)
	var narrow_highest: float = await _highest_opacity(narrow, LOOK_EVERY * 2)
	var middle_highest: float = await _highest_opacity(middle, LOOK_EVERY * 2)
	await _remove([narrow.get_parent(), middle.get_parent(), wide.get_parent(), wall])
	return report(wide_highest > 0.05 and wide_highest < 0.95 and is_zero_approx(narrow_highest)
			and is_zero_approx(middle_highest),
			("Behind a low wall: a box from x = 400 to 1200 at highest opacity %s (expected between 0 "
			+ "and 1); boxes 64 px wide at x = 400 and at its middle, x = 800, highest opacity %s and %s "
			+ "(expected 0)") % [wide_highest, narrow_highest, middle_highest])


func _a_demon_that_sees_the_man_is_drawn() -> bool:
	var wall: StaticBody2D = _make_full_wall()
	var seeing: SightReveal = _make_box(Vector2(BOX_X, 0.0), false, BOX_SIZE, true)
	var blind: SightReveal = _make_box(Vector2(BOX_X + 100.0, 0.0), false, BOX_SIZE, false)
	var seeing_drawn: bool = await wait_until(func() -> bool: return seeing.get_opacity() >= 1.0,
			WATCH_FRAMES)
	var blind_highest: float = await _highest_opacity(blind, LOOK_EVERY * 2)
	await _remove([seeing.get_parent(), blind.get_parent(), wall])
	return report(seeing_drawn and is_zero_approx(blind_highest),
			("Behind a wall: with senses that see the man, drawn %s (expected true); with senses "
			+ "that do not, highest opacity %s (expected 0)") % [seeing_drawn, blind_highest])


func _the_game_s_demon_hides_behind_a_wall() -> bool:
	var wall: StaticBody2D = _make_full_wall()
	var demon: Node2D = _add_still_demon(Vector2(BOX_X, 0.0))
	var reveal: SightReveal = demon.get_node("SightReveal") as SightReveal
	var highest: float = await _highest_opacity(reveal, WATCH_FRAMES)
	await _remove([wall])
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	var alpha: float = demon.modulate.a
	await _remove([demon])
	return report(is_zero_approx(highest) and drawn and is_equal_approx(alpha, 1.0),
			("The game's demon behind a wall: highest opacity %s (expected 0); with the wall gone, "
			+ "drawn %s and alpha %s (expected true, 1)") % [highest, drawn, alpha])


## Behind the slab, the man's rays to the demon are cut and the demon's to him are not: it is drawn
## only through its senses, which the scene gives the reveal.
func _the_game_s_demon_that_sees_the_man_is_drawn() -> bool:
	var slab: StaticBody2D = make_wall(SLAB_LEFT, SLAB_RIGHT, SLAB_TOP, SLAB_BOTTOM)
	var demon: Node2D = _add_still_demon(Vector2(BOX_X, 0.0))
	var reveal: SightReveal = demon.get_node("SightReveal") as SightReveal
	var wired: bool = reveal.senses == demon.get_node("Senses")
	var sees: bool = await wait_until(
			func() -> bool: return reveal.senses.can_see(SightEyes.current.get_man()), WATCH_FRAMES)
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([demon, slab])
	return report(wired and sees and drawn,
			("The game's demon behind a slab: its reveal has its senses %s, it sees the man %s, drawn "
			+ "%s (expected all true)") % [wired, sees, drawn])


## Hidden behind the wall, the demon starts an attack's warning: on that frame it is drawn in full.
func _the_game_s_demon_is_drawn_in_full_as_it_warns() -> bool:
	var wall: StaticBody2D = _make_full_wall()
	var demon: Node2D = _add_still_demon(Vector2(BOX_X, 0.0))
	var reveal: SightReveal = demon.get_node("SightReveal") as SightReveal
	var hidden: float = await _highest_opacity(reveal, LOOK_EVERY * 2)
	var stats: DemonStats = demon.get("stats") as DemonStats
	demon.emit_signal(&"warning_started", stats.attacks[0])
	var at_warning: float = reveal.get_opacity()
	var alpha: float = demon.modulate.a
	await _remove([demon, wall])
	return report(is_zero_approx(hidden) and is_equal_approx(at_warning, 1.0)
			and is_equal_approx(alpha, 1.0),
			("The game's demon behind a wall: opacity %s (expected 0); on its warning, %s and alpha %s "
			+ "on the same frame (expected 1 and 1)") % [hidden, at_warning, alpha])


func _the_game_s_spikes_hide_then_stay_once_seen() -> bool:
	var wall: StaticBody2D = _make_full_wall()
	var hidden_spikes: Node2D = _make_spikes(Vector2(BOX_X, 0.0))
	var seen_spikes: Node2D = _make_spikes(Vector2(-BOX_X, 0.0))
	var hidden_reveal: SightReveal = hidden_spikes.get_node("SightReveal") as SightReveal
	var seen_reveal: SightReveal = seen_spikes.get_node("SightReveal") as SightReveal
	var highest: float = await _highest_opacity(hidden_reveal, WATCH_FRAMES)
	var seen_drawn: bool = seen_reveal.get_opacity() >= 1.0
	var looking: bool = seen_reveal.is_physics_processing()
	await _remove([hidden_spikes, seen_spikes, wall])
	return report(is_zero_approx(highest) and seen_drawn and not looking,
			("The game's spikes: behind a wall, highest opacity %s (expected 0); in plain sight, "
			+ "drawn %s and still looking %s (expected true, false)") % [highest, seen_drawn, looking])


func _paused_a_fade_stops_where_it_is() -> bool:
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	reveal.fade_in_time = 1.0
	var started: bool = await wait_until(func() -> bool: return reveal.get_opacity() > 0.0,
			WATCH_FRAMES)
	paused = true
	var at_pause: float = reveal.get_opacity()
	await wait_frames(WATCH_FRAMES)
	var after_pause: float = reveal.get_opacity()
	paused = false
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES * 3)
	await _remove([reveal.get_parent()])
	return report(started and at_pause < 1.0 and is_equal_approx(at_pause, after_pause) and drawn,
			("Paused mid-fade: %s at the pause and %s after %d paused frames (expected the same, "
			+ "under 1); drawn after %s (expected true)")
			% [at_pause, after_pause, WATCH_FRAMES, drawn])


func _show_hidden_draws_what_is_behind_a_wall() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"/root/Settings") as GameSettings
	if settings == null:
		return report(false, "Show Hidden: no autoload Settings")
	var wall: StaticBody2D = _make_full_wall()
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	settings.set_show_hidden(true)
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	settings.set_show_hidden(false)
	var gone: bool = await wait_until(func() -> bool: return is_zero_approx(reveal.get_opacity()),
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), wall])
	return report(drawn and gone,
			("Behind a wall, Show Hidden on: drawn %s (expected true); turned off: gone %s "
			+ "(expected true)") % [drawn, gone])


func _show_hidden_turned_on_in_the_pause_applies_as_play_resumes() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"/root/Settings") as GameSettings
	if settings == null:
		return report(false, "Show Hidden in the pause: no autoload Settings")
	var wall: StaticBody2D = _make_full_wall()
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	await wait_frames(LOOK_EVERY * 2)
	paused = true
	settings.set_show_hidden(true)
	var in_pause: float = await _highest_opacity(reveal, WATCH_FRAMES)
	paused = false
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	settings.set_show_hidden(false)
	await _remove([reveal.get_parent(), wall])
	return report(is_zero_approx(in_pause) and drawn,
			("Behind a wall, Show Hidden turned on in the pause: highest opacity %s while paused "
			+ "(expected 0); drawn once play resumes %s (expected true)") % [in_pause, drawn])


func _with_no_look_box_it_is_always_drawn() -> bool:
	var wall: StaticBody2D = _make_full_wall()
	var box: Node2D = Node2D.new()
	box.position = Vector2(BOX_X, 0.0)
	var reveal: SightReveal = SightReveal.new()
	reveal.fade_in_time = FADE_IN
	box.add_child(reveal)
	root.add_child(box)
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([box, wall])
	return report(drawn, "No Look Box, behind a wall: drawn %s (expected true)" % drawn)


## With a camera on the man, the headless screen is 1920 px wide: a box in plain sight past its edge
## and the eyes' Screen Margin stays undrawn, while one on the screen is drawn.
func _off_the_screen_nothing_is_seen() -> bool:
	var camera: Camera2D = Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	var screen_edge: float = root.get_visible_rect().size.x / 2.0 + SightEyes.current.screen_margin
	var near: SightReveal = _make_box(Vector2(BOX_X, 0.0))
	var far: SightReveal = _make_box(Vector2(screen_edge + BOX_SIZE.x * 2.0, 0.0))
	var near_drawn: bool = await wait_until(func() -> bool: return near.get_opacity() >= 1.0,
			WATCH_FRAMES)
	var far_highest: float = await _highest_opacity(far, WATCH_FRAMES)
	await _remove([near.get_parent(), far.get_parent(), camera])
	return report(near_drawn and is_zero_approx(far_highest),
			("With a camera: a box on the screen drawn %s (expected true); one in plain sight past "
			+ "x = %.0f, the screen's edge and the margin, highest opacity %s (expected 0)")
			% [near_drawn, screen_edge, far_highest])


func _near_his_eyes_it_is_drawn_behind_a_wall() -> bool:
	var wall: StaticBody2D = make_wall(NEAR_WALL_LEFT, NEAR_WALL_RIGHT, WALL_TOP)
	var reveal: SightReveal = _make_box(Vector2(NEAR_BOX_X, 0.0))
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), wall])
	return report(drawn, "Behind a wall, within Near Radius of his eyes: drawn %s (expected true)"
			% drawn)


## The same post twice: one looks at all three rows and sees two spots; the other, with Rows 1,
## looks at its top only, which the slab hides, so the slab really cuts that ray.
func _with_its_top_hidden_its_body_shows_it() -> bool:
	var slab: StaticBody2D = make_wall(POST_SLAB_LEFT, POST_SLAB_RIGHT, POST_SLAB_TOP,
			POST_SLAB_BOTTOM)
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0), false, POST_SIZE)
	var top_only: SightReveal = _make_box(Vector2(BOX_X, 0.0), false, POST_SIZE)
	top_only.rows = 1
	var top_only_highest: float = await _highest_opacity(top_only, WATCH_FRAMES)
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), top_only.get_parent(), slab])
	return report(drawn and is_zero_approx(top_only_highest),
			("Its top spot behind a slab, the rest in sight: drawn in full %s (expected true); looking "
			+ "at its top only, highest opacity %s (expected 0)") % [drawn, top_only_highest])


func _mostly_hidden_it_is_drawn_in_part() -> bool:
	var slab: StaticBody2D = make_wall(POST_SLAB_LEFT, POST_SLAB_RIGHT, POST_SLAB_TOP,
			DEEP_POST_SLAB_BOTTOM)
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0), false, POST_SIZE)
	var highest: float = await _highest_opacity(reveal, WATCH_FRAMES)
	await _remove([reveal.get_parent(), slab])
	return report(highest > 0.05 and highest < 0.95,
			"Only its bottom spot in sight: highest opacity %s (expected between 0 and 1)" % highest)


## Seen in part once, one that remembers is drawn in full, as spikes half behind a ledge are.
func _one_that_remembers_seen_in_part_is_drawn_in_full() -> bool:
	var slab: StaticBody2D = make_wall(POST_SLAB_LEFT, POST_SLAB_RIGHT, POST_SLAB_TOP,
			DEEP_POST_SLAB_BOTTOM)
	var reveal: SightReveal = _make_box(Vector2(BOX_X, 0.0), true, POST_SIZE)
	var drawn: bool = await wait_until(func() -> bool: return reveal.get_opacity() >= 1.0,
			WATCH_FRAMES)
	await _remove([reveal.get_parent(), slab])
	return report(drawn, ("Remembers, only its bottom spot in sight: drawn in full %s (expected "
			+ "true)") % drawn)


## The game's demon on the floor at at, standing still: its own physics is off, so it neither moves
## nor attacks, while its senses and its reveal run.
func _add_still_demon(at: Vector2) -> Node2D:
	var demon: Node2D = DEMON_SCENE.instantiate() as Node2D
	demon.position = at
	root.add_child(demon)
	demon.set_physics_process(false)
	return demon


## A box standing on the floor at at, with its SightReveal, both already in the scene. With a
## seeing value, it has stand-in senses that say it.
func _make_box(at: Vector2, remembers: bool = false, size: Vector2 = BOX_SIZE,
		seeing: Variant = null) -> SightReveal:
	var box: Node2D = Node2D.new()
	box.position = at
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var look_box: CollisionShape2D = CollisionShape2D.new()
	look_box.shape = shape
	look_box.position = Vector2(0.0, -size.y / 2.0)
	box.add_child(look_box)
	var reveal: SightReveal = SightReveal.new()
	reveal.look_box = look_box
	reveal.remembers = remembers
	reveal.fade_in_time = FADE_IN
	reveal.fade_out_time = FADE_OUT
	reveal.linger_time = LINGER
	reveal.look_every = LOOK_EVERY
	reveal.near_radius = NEAR_RADIUS
	reveal.full_share = FULL_SHARE
	if seeing != null:
		var senses: StandInSenses = StandInSenses.new()
		senses.body_box = look_box
		senses.sees = seeing as bool
		box.add_child(senses)
		reveal.senses = senses
	box.add_child(reveal)
	root.add_child(box)
	return reveal


## The game's spikes, four tiles wide, on the floor at at, already in the scene.
func _make_spikes(at: Vector2) -> Node2D:
	var spikes: Node2D = SPIKES_SCENE.instantiate() as Node2D
	spikes.position = at
	spikes.set("width_tiles", 4)
	root.add_child(spikes)
	return spikes


## The wall between the man and the boxes, already in the scene.
func _make_full_wall() -> StaticBody2D:
	return make_wall(WALL_LEFT, WALL_RIGHT, WALL_TOP)


## Someone where the wall would be and as tall, on the world's layer, the default, already in the
## scene: a CharacterBody2D, as Velvet's body is.
func _make_someone_standing() -> CharacterBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(WALL_RIGHT - WALL_LEFT, -WALL_TOP)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var someone: CharacterBody2D = CharacterBody2D.new()
	someone.position = Vector2((WALL_LEFT + WALL_RIGHT) / 2.0, WALL_TOP / 2.0)
	someone.add_child(collision)
	root.add_child(someone)
	return someone


## The highest opacity over frames physics frames.
func _highest_opacity(reveal: SightReveal, frames: int) -> float:
	var highest: float = reveal.get_opacity()
	for i: int in frames:
		await physics_frame
		highest = maxf(highest, reveal.get_opacity())
	return highest


## The lowest opacity over frames physics frames.
func _lowest_opacity(reveal: SightReveal, frames: int) -> float:
	var lowest: float = reveal.get_opacity()
	for i: int in frames:
		await physics_frame
		lowest = minf(lowest, reveal.get_opacity())
	return lowest


## Takes nodes out at the end of the frame, and waits for it.
func _remove(nodes: Array) -> void:
	for node: Node in nodes:
		node.queue_free()
	await physics_frame
	await physics_frame
