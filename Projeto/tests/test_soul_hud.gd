# Checks the soul bar (SoulHud) against a real player and his crucifix: the bar fills with his SP, from
# 0 to the most; the aura moves at its frames per second; the cross is gold while the crucifix may go
# up, blue with the seconds left while it cools down, and gold again once it is full; and once the
# crucifix is lost, the placeholder takes its place.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_soul_hud.gd
extends "res://tests/support/player_test.gd"

const HUD_SCENE: PackedScene = preload("res://scenes/screens/soul_hud/soul_hud.tscn")
const FLOOR_START: Vector2 = Vector2(0.0, 0.0)
## SP taken off the man for the bar's check.
const DAMAGE: float = 40.0
## Frames after a change for what follows from it to have happened.
const SETTLE_FRAMES: int = 3
## Frames past the use time for the crucifix to go up and run out.
const USE_MARGIN_FRAMES: int = 60
## Frames the aura is watched for, a second at 60 fps.
const AURA_FRAMES: int = 60


func _initialize() -> void:
	make_platform(-2000.0, 2000.0)
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		finish([report(false, "The player never landed")])
		return
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var hud: SoulHud = HUD_SCENE.instantiate() as SoulHud
	hud.player = player
	hud.crucifix = crucifix
	root.add_child(hud)
	await process_frame
	var results: Array[bool] = []
	results.append(_the_bar_follows_his_sp(hud, player.soul_points))
	results.append(await _the_aura_moves_at_its_fps(hud))
	results.append(await _the_cross_shows_the_cooldown(hud, crucifix, put_a_stand_in(player)))
	results.append(await _a_lost_crucifix_leaves_the_placeholder(hud, crucifix))
	hud.queue_free()
	await remove_player(player)
	finish(results)


func _the_bar_follows_his_sp(hud: SoulHud, soul_points: SoulPoints) -> bool:
	var full: float = hud.get_fill_ratio()
	soul_points.take_damage(DAMAGE)
	var hurt: float = hud.get_fill_ratio()
	var expected: float = soul_points.get_sp() / soul_points.get_max_sp()
	return report(is_equal_approx(full, 1.0) and is_equal_approx(hurt, expected),
			"Bar: full %.3f (1), after %d SP of damage %.3f (%.3f)" % [full, DAMAGE, hurt, expected])


func _the_aura_moves_at_its_fps(hud: SoulHud) -> bool:
	var aura: TextureRect = hud.get_node(^"%Aura") as TextureRect
	var changes: int = 0
	var last: Texture2D = aura.texture
	for _frame: int in AURA_FRAMES:
		await process_frame
		if aura.texture != last:
			changes += 1
			last = aura.texture
	var expected: int = roundi(hud.aura_fps * AURA_FRAMES / 60.0)
	return report(absi(changes - expected) <= 1,
			"Aura: %d drawings in a second (%d)" % [changes, expected])


func _the_cross_shows_the_cooldown(hud: SoulHud, crucifix: Crucifix, stand_in: StandInInput) -> bool:
	var gold_before: bool = hud.is_cross_ready() and hud.get_cooldown_text().is_empty()
	# A press counts on the physics frame it is made in, so it is made right after one.
	await physics_frame
	stand_in.crucifix_held = true
	var cooling: bool = await wait_until(func() -> bool: return crucifix.get_phase() == Crucifix.Phase.COOLDOWN,
			crucifix.stats.get_max_use_frames() + USE_MARGIN_FRAMES)
	stand_in.crucifix_held = false
	await process_frame
	var seconds: String = str(ceili(crucifix.get_cooldown_left()))
	var text: String = hud.get_cooldown_text()
	var blue: bool = not hud.is_cross_ready()
	var ready_again: bool = await wait_until(func() -> bool: return crucifix.get_phase() == Crucifix.Phase.READY,
			crucifix.stats.get_cooldown_frames() + SETTLE_FRAMES)
	await process_frame
	var gold_after: bool = hud.is_cross_ready() and hud.get_cooldown_text().is_empty()
	return report(gold_before and cooling and blue and text == seconds and ready_again and gold_after,
			"Cross: gold before %s; cooling %s, blue %s, text \"%s\" (\"%s\"); full again %s, gold %s"
			% [gold_before, cooling, blue, text, seconds, ready_again, gold_after])


func _a_lost_crucifix_leaves_the_placeholder(hud: SoulHud, crucifix: Crucifix) -> bool:
	var before: bool = hud.is_placeholder_shown()
	crucifix.lose()
	await wait_frames(SETTLE_FRAMES)
	await process_frame
	var cross: TextureRect = hud.get_node(^"%Cross") as TextureRect
	return report(not before and hud.is_placeholder_shown() and not cross.visible,
			"Lost crucifix: placeholder before %s, after %s, cross still shown %s"
			% [before, hud.is_placeholder_shown(), cross.visible])
