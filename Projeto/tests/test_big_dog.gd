# Checks level 1's big dog, the one of phase 2: the regular dog a quarter bigger, with the regular
# dog's stats but for the damage of its attacks, and its art drawn darker. Its body, hit box, art and
# the other points on it are the regular dog's times SIZE, and the checks at its feet stay as far past
# the front of its body as the regular dog's; its stats are a file of its own, equal to the regular
# dog's in every field, and in every field of each attack but the damage; its bite and lunge take
# BITE_DAMAGE and LUNGE_DAMAGE; a big dog put down right by the man bites him for BITE_DAMAGE; and its
# art is drawn darker than the regular dog's in every tint its stand-in gives it, with the same tint.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_big_dog.gd
extends "res://tests/support/player_test.gd"

const DOG_SCENE: PackedScene = preload("res://demon/demon.tscn")
const BIG_SCENE: PackedScene = preload("res://demon/big_demon.tscn")
## How many times the regular dog's size the big dog is.
const SIZE: float = 1.25
## SP the big dog's bite and lunge take: the regular dog's 10 and 20, a quarter more.
const BITE_DAMAGE: float = 12.5
const LUNGE_DAMAGE: float = 25.0
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
## Where the man stands, just over the floor.
const MAN_AT: Vector2 = Vector2(0.0, -2.0)
## Px between the dog's body and the man's when the dog is put down: inside the bite's Attack Range,
## so its first attack is a bite.
const GAP: float = 2.0
## Nodes the code sizes from the stats, so the big dog keeps the regular dog's in its scene: the
## sight's circle (Sight Distance) and the pack's box (Pack Spacing).
const SET_BY_CODE: PackedStringArray = ["SightArea/SightShape", "PackArea/PackShape"]
## The checks at the feet: as far past the front of the body as the regular dog's.
const FEET_CHECKS: PackedStringArray = ["LedgeCheck", "StepCheck"]
## What the stand-in shows, each with a tint of its own: at rest, the warning of each attack (by its
## animation) and stunned.
const SHOWN: PackedStringArray = ["rest", "lunge", "bite", "stunned"]


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(_the_big_dog_is_the_dog_a_quarter_bigger())
	results.append(_its_stats_are_the_dog_s_but_for_the_damage())
	results.append(_its_bite_and_lunge_take_more())
	results.append(await _it_bites_the_man_for_its_damage())
	results.append(await _its_art_is_drawn_darker_in_every_tint())
	finish(results)


## Every node of the regular dog, also those it gains later, is in the big dog where it is times SIZE,
## with its box times SIZE, but for SET_BY_CODE and FEET_CHECKS; and its art, stride and sinking depth
## are times SIZE too.
func _the_big_dog_is_the_dog_a_quarter_bigger() -> bool:
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	var big: Demon = BIG_SCENE.instantiate() as Demon
	var small_half: float = _body_of(dog).x / 2.0
	var wrong: Array[String] = []
	for small: Node in _all_below(dog):
		var path: String = String(dog.get_path_to(small))
		var large: Node = big.get_node_or_null(path)
		if large == null:
			wrong.append(path + " missing")
		elif not path in SET_BY_CODE:
			if small is Node2D and not _sits_scaled(path, small as Node2D, large as Node2D, small_half):
				wrong.append(path)
			if small is CollisionShape2D and not _has_scaled_box(small as CollisionShape2D, large as CollisionShape2D):
				wrong.append(path + " box")
	var small_art: Node2D = dog.get_node(^"Sprite") as Node2D
	if not (big.get_node(^"Sprite") as Node2D).scale.is_equal_approx(small_art.scale * SIZE):
		wrong.append("Sprite scale")
	var small_polygon: PackedVector2Array = (dog.get_node(^"Placeholder") as Polygon2D).polygon
	if not _is_scaled(small_polygon, (big.get_node(^"Placeholder") as Polygon2D).polygon):
		wrong.append("Placeholder polygon")
	var small_stride: float = (dog.get_node(^"DemonAnimation") as DemonAnimation).stride_length
	if not is_equal_approx((big.get_node(^"DemonAnimation") as DemonAnimation).stride_length, small_stride * SIZE):
		wrong.append("DemonAnimation stride_length")
	var small_depth: float = (dog.get_node(^"SinkingDrawing") as SinkingDrawing).depth
	if not is_equal_approx((big.get_node(^"SinkingDrawing") as SinkingDrawing).depth, small_depth * SIZE):
		wrong.append("SinkingDrawing depth")
	var body: Vector2 = _body_of(big)
	dog.free()
	big.free()
	return report(wrong.is_empty(), "Size: body %s, %.2f times the dog's; wrong %s" % [body, SIZE, wrong])


func _its_stats_are_the_dog_s_but_for_the_damage() -> bool:
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	var big: Demon = BIG_SCENE.instantiate() as Demon
	var own_file: bool = big.stats != null and big.stats != dog.stats
	var different: Array[String] = []
	if own_file:
		different = _different_fields(dog.stats, big.stats, ["attacks"])
		var small_attacks: Array[DemonAttack] = dog.stats.attacks
		var large_attacks: Array[DemonAttack] = big.stats.attacks
		if small_attacks.size() != large_attacks.size():
			different.append("attacks: %d, not %d" % [large_attacks.size(), small_attacks.size()])
		else:
			for i: int in small_attacks.size():
				for field: String in _different_fields(small_attacks[i], large_attacks[i], ["damage"]):
					different.append("%s %s" % [small_attacks[i].animation, field])
	dog.free()
	big.free()
	return report(own_file and different.is_empty(),
			"Stats: a file of its own %s; fields that differ from the dog's, the damage aside: %s"
			% [own_file, different])


func _its_bite_and_lunge_take_more() -> bool:
	var big: Demon = BIG_SCENE.instantiate() as Demon
	var bite: DemonAttack = _attack_of(big.stats, &"bite")
	var lunge: DemonAttack = _attack_of(big.stats, &"lunge")
	var bite_damage: float = bite.damage if bite != null else -1.0
	var lunge_damage: float = lunge.damage if lunge != null else -1.0
	big.free()
	return report(is_equal_approx(bite_damage, BITE_DAMAGE) and is_equal_approx(lunge_damage, LUNGE_DAMAGE),
			"Damage: the bite takes %.1f SP and the lunge %.1f, expected %.1f and %.1f"
			% [bite_damage, lunge_damage, BITE_DAMAGE, LUNGE_DAMAGE])


func _it_bites_the_man_for_its_damage() -> bool:
	var man: Player = await spawn_on_floor(MAN_AT)
	if man == null:
		return report(false, "Bite: the man never landed")
	var taken: Array[float] = []
	man.soul_points.damaged.connect(func(amount: float) -> void: taken.append(amount))
	var dog: Demon = BIG_SCENE.instantiate() as Demon
	var distance: float = _body_of(dog).x / 2.0 + body_size(man).x / 2.0 + GAP
	var bite: DemonAttack = _attack_of(dog.stats, &"bite")
	var bite_range: float = bite.attack_range if bite != null else 0.0
	dog.position = Vector2(MAN_AT.x - distance, 0.0)
	root.add_child(dog)
	var bitten: bool = await wait_until(func() -> bool: return not taken.is_empty())
	var first: float = taken[0] if bitten else 0.0
	await remove_player(man)
	dog.queue_free()
	await physics_frame
	return report(distance < bite_range and bitten and is_equal_approx(first, BITE_DAMAGE),
			"Bite at a man %.0f px away, bite range %.0f px: bitten %s, the first hit took %.1f SP, expected %.1f"
			% [distance, bite_range, bitten, first, BITE_DAMAGE])


## The big dog's art is drawn darker than the regular dog's in each of SHOWN, with the same tint from
## its stand-in: the darker art outlives the stand-in setting the art's Modulate on every frame drawn.
func _its_art_is_drawn_darker_in_every_tint() -> bool:
	var dog: Demon = DOG_SCENE.instantiate() as Demon
	var big: Demon = BIG_SCENE.instantiate() as Demon
	dog.position = Vector2(FLOOR_LEFT / 2.0, 0.0)
	big.position = Vector2(FLOOR_RIGHT / 2.0, 0.0)
	root.add_child(dog)
	root.add_child(big)
	# With no physics frames the dogs never change state, so only _show tints them.
	dog.set_physics_process(false)
	big.set_physics_process(false)
	var not_darker: Array[String] = []
	for shown: String in SHOWN:
		_show(dog, shown)
		_show(big, shown)
		# process_frame comes before the nodes' _process on its frame: one more for the stand-in's.
		await process_frame
		await process_frame
		if not _drawn_darker(big, dog):
			not_darker.append(shown)
	dog.queue_free()
	big.queue_free()
	await physics_frame
	return report(not_darker.is_empty(),
			"Art: the big dog's drawn darker than the dog's, with the same tint, in %s; not in %s"
			% [SHOWN, not_darker])


## Gives demon's stand-in the tint of shown, as the demon's own signals do.
func _show(demon: Demon, shown: String) -> void:
	var placeholder: DemonPlaceholder = demon.get_node(^"Placeholder") as DemonPlaceholder
	match shown:
		"rest":
			placeholder._on_demon_state_changed(Demon.State.STUNNED, Demon.State.IDLE)
		"stunned":
			placeholder._on_demon_state_changed(Demon.State.IDLE, Demon.State.STUNNED)
		_:
			placeholder._on_demon_warning_started(_attack_of(demon.stats, StringName(shown)))


## True when big's art takes from its stand-in the tint dog's takes, and is drawn darker than dog's.
func _drawn_darker(big: Demon, dog: Demon) -> bool:
	var big_art: CanvasItem = big.get_node(^"Sprite") as CanvasItem
	var dog_art: CanvasItem = dog.get_node(^"Sprite") as CanvasItem
	var big_drawn: Color = big_art.modulate * big_art.self_modulate
	var dog_drawn: Color = dog_art.modulate * dog_art.self_modulate
	return big_art.modulate == dog_art.modulate and big_drawn.get_luminance() < dog_drawn.get_luminance()


## The size of demon's body.
func _body_of(demon: Demon) -> Vector2:
	return ((demon.get_node(^"CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size


## Every node under top, at any depth.
func _all_below(top: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in top.get_children():
		found.append(child)
		found.append_array(_all_below(child))
	return found


## True when large sits where small does times SIZE; a check at the feet keeps instead the regular
## dog's distance past the front of the body.
func _sits_scaled(path: String, small: Node2D, large: Node2D, small_half: float) -> bool:
	if path in FEET_CHECKS:
		var past_front: float = small.position.x - small_half
		return large.position.is_equal_approx(Vector2(small_half * SIZE + past_front, small.position.y))
	return large.position.is_equal_approx(small.position * SIZE)


## True when large's box is small's times SIZE; a shape that is not a box is not covered, so it fails.
func _has_scaled_box(small: CollisionShape2D, large: CollisionShape2D) -> bool:
	var small_box: RectangleShape2D = small.shape as RectangleShape2D
	var large_box: RectangleShape2D = large.shape as RectangleShape2D
	return small_box != null and large_box != null and large_box.size.is_equal_approx(small_box.size * SIZE)


## True when large has the points of small times SIZE, in the same order.
func _is_scaled(small: PackedVector2Array, large: PackedVector2Array) -> bool:
	if small.size() != large.size():
		return false
	for i: int in small.size():
		if not large[i].is_equal_approx(small[i] * SIZE):
			return false
	return true


## The first attack in stats with that animation; null with none.
func _attack_of(stats: DemonStats, animation: StringName) -> DemonAttack:
	for attack: DemonAttack in stats.attacks:
		if attack.animation == animation:
			return attack
	return null


## Names of the saved script fields whose values differ between a and b, leaving out those in skip.
func _different_fields(a: Resource, b: Resource, skip: Array[String]) -> Array[String]:
	var different: Array[String] = []
	for property: Dictionary in a.get_property_list():
		var usage: int = property["usage"]
		var field: String = property["name"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 or (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		if field in skip:
			continue
		if a.get(field) != b.get(field):
			different.append(field)
	return different
