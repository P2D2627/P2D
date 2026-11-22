# Checks where Asmodeus appears next to the man (#284). Appear Offset puts her 300 px to his right, far enough
# for the talk's shot to read the two as two. Where that spot has rock in her figure, as at the start of
# phase 2 of level 1, where the man lands at the bottom of a shaft, she appears as far to his left, mirrored
# so she still faces him. With rock on both sides she keeps the right, as before. One-way platforms, which
# are not rock, do not count.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus_appears_in_the_open.gd
extends "res://tests/support/player_test.gd"

const ASMODEUS_SCENE: PackedScene = preload("res://scenes/characters/demon/asmodeus.tscn")
## A block of rock beside the man: from Near to Far px from him, as tall as Height above the floor.
const ROCK_NEAR: float = 200.0
const ROCK_FAR: float = 500.0
const ROCK_HEIGHT: float = 400.0
const WORLD_LAYER: int = 1
const TOLERANCE: float = 0.01


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
	root.add_child(asmodeus)
	var man: Vector2 = player.global_position
	var offset: Vector2 = asmodeus.appear_offset
	var sprite: Sprite2D = asmodeus.get_figure() as Sprite2D

	asmodeus.appear_at(man)
	var right_flip: bool = sprite.flip_h
	results.append(report(asmodeus.global_position.is_equal_approx(man + offset),
			"In the open: %s, Appear Offset %s from him (%s)" % [asmodeus.global_position, offset, man + offset]))

	var right_rock: StaticBody2D = _rock(man.x + ROCK_NEAR, man.x + ROCK_FAR, man.y)
	await physics_frame
	await physics_frame
	asmodeus.appear_at(man)
	var left: Vector2 = man + Vector2(-offset.x, offset.y)
	results.append(report(asmodeus.global_position.is_equal_approx(left) and sprite.flip_h != right_flip,
			"Rock on his right: %s (%s), mirrored to face him %s" % [asmodeus.global_position, left,
			sprite.flip_h != right_flip]))

	var left_rock: StaticBody2D = _rock(man.x - ROCK_FAR, man.x - ROCK_NEAR, man.y)
	await physics_frame
	await physics_frame
	asmodeus.appear_at(man)
	results.append(report(asmodeus.global_position.is_equal_approx(man + offset) and sprite.flip_h == right_flip,
			"Rock on both sides: the right, as before, %s, facing as on the right %s"
			% [asmodeus.global_position, sprite.flip_h == right_flip]))

	right_rock.queue_free()
	left_rock.queue_free()
	await physics_frame
	await physics_frame
	asmodeus.appear_at(man)
	results.append(report(asmodeus.global_position.is_equal_approx(man + offset) and sprite.flip_h == right_flip,
			"In the open again: the right %s, facing as on the right %s"
			% [asmodeus.global_position, sprite.flip_h == right_flip]))
	asmodeus.queue_free()
	await process_frame
	finish(results)


## A block of rock on the world's layer, from x left to x right, standing on the floor at y.
func _rock(left: float, right: float, y: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(right - left, ROCK_HEIGHT)
	shape.shape = rect
	body.add_child(shape)
	body.position = Vector2((left + right) / 2.0, y - ROCK_HEIGHT / 2.0)
	root.add_child(body)
	return body
