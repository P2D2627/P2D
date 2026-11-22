# Checks that Asmodeus never appears inside rock next to the man (#284), with level 1's Appear Distance of
# 300 px, far enough for the talk's shot to read the two as two. In the open she stands that far in front of
# him. With rock in front of him, as at the start of phase 2 of level 1, where the man lands at the bottom of a
# shaft, find_spot() puts her nearer or behind him, and her drawn figure stays out of the rock. Wherever she
# stands, the two face each other.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus_appears_in_the_open.gd
extends "res://tests/support/player_test.gd"

const ASMODEUS_SCENE: PackedScene = preload("res://scenes/characters/demon/asmodeus.tscn")
## Level 1's Appear Distance (its Asmodeus node).
const APPEAR_DISTANCE: float = 300.0
## A block of rock beside the man: from Near to Far px from him, as tall as Height above the floor.
const ROCK_NEAR: float = 200.0
const ROCK_FAR: float = 500.0
const ROCK_HEIGHT: float = 400.0
const WORLD_LAYER: int = 1
## Px her drawn figure is taken in all round, so her feet on the floor do not count as in the rock.
const FIGURE_MARGIN: float = 4.0


func _initialize() -> void:
	var results: Array[bool] = []
	make_platform(-4000.0, 4000.0)
	var player: Player = await spawn_on_floor(Vector2(0.0, -2.0))
	if player == null:
		results.append(report(false, "The man never landed"))
		finish(results)
		return
	var asmodeus: Asmodeus = ASMODEUS_SCENE.instantiate() as Asmodeus
	asmodeus.player = player
	asmodeus.appear_distance = APPEAR_DISTANCE
	root.add_child(asmodeus)
	var man: Vector2 = player.global_position
	var front: float = player.get_facing()
	await physics_frame

	asmodeus.appear_at(man)
	var open_spot: Vector2 = man + Vector2(front * APPEAR_DISTANCE, 0.0)
	results.append(report(asmodeus.global_position.distance_to(open_spot) < 1.0,
			"In the open: %s, Appear Distance in front of him (%s)" % [asmodeus.global_position, open_spot]))
	results.append(_faces_him(asmodeus, player, "In the open"))

	var rocks: Array[Rect2] = [_rock_rect(man, front)]
	var front_rock: StaticBody2D = _add_rock(rocks[0])
	await physics_frame
	await physics_frame
	asmodeus.appear_at(man)
	results.append(_clear_of(asmodeus, rocks, "Rock in front of him"))
	results.append(_faces_him(asmodeus, player, "Rock in front of him"))

	rocks.append(_rock_rect(man, -front))
	var back_rock: StaticBody2D = _add_rock(rocks[1])
	await physics_frame
	await physics_frame
	asmodeus.appear_at(man)
	results.append(_clear_of(asmodeus, rocks, "Rock on both sides"))
	results.append(_faces_him(asmodeus, player, "Rock on both sides"))

	front_rock.queue_free()
	back_rock.queue_free()
	await physics_frame
	await physics_frame
	asmodeus.appear_at(man)
	results.append(report(asmodeus.global_position.distance_to(open_spot) < 1.0,
			"In the open again: %s, Appear Distance in front of him (%s)" % [asmodeus.global_position, open_spot]))
	results.append(_faces_him(asmodeus, player, "In the open again"))
	asmodeus.queue_free()
	await process_frame
	finish(results)


## Whether her drawn figure, taken in by Figure Margin, overlaps none of rocks.
func _clear_of(asmodeus: Asmodeus, rocks: Array[Rect2], case: String) -> bool:
	var figure: Rect2 = TalkFraming.drawn_rect(asmodeus.get_figure()).grow(-FIGURE_MARGIN)
	var inside: bool = false
	for rock: Rect2 in rocks:
		inside = inside or figure.intersects(rock)
	return report(not inside, "%s: she stands at %s, her figure %s out of the rock %s"
			% [case, asmodeus.global_position, figure, not inside])


## Whether she and the man are turned to each other: her art faces left as drawn (Art Faces Right off).
func _faces_him(asmodeus: Asmodeus, player: Player, case: String) -> bool:
	var her_side: float = signf(asmodeus.global_position.x - player.global_position.x)
	var she_faces: float = 1.0 if (asmodeus.get_figure() as Sprite2D).flip_h != asmodeus.art_faces_right else -1.0
	var both: bool = she_faces == -her_side and player.get_facing() == her_side
	return report(both, "%s: she faces him %s, he faces her %s" % [case, she_faces == -her_side,
			player.get_facing() == her_side])


## The rock from Rock Near to Rock Far px from the man on side (1 right, -1 left), standing on his floor.
func _rock_rect(man: Vector2, side: float) -> Rect2:
	var near_x: float = man.x + side * ROCK_NEAR
	var far_x: float = man.x + side * ROCK_FAR
	return Rect2(minf(near_x, far_x), man.y - ROCK_HEIGHT, absf(far_x - near_x), ROCK_HEIGHT)


## A block of rock on the world's layer, filling rect.
func _add_rock(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	body.position = rect.get_center()
	root.add_child(body)
	return body
