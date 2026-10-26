# Checks DemonTarget on its own, without a demon (ADR 0037): what it keeps as it takes the man, his
# speed along the floor, the frames unseen and where he was last seen, that letting go of him keeps
# where he was last seen, that taking him again starts over, and that a man freed while the demon is
# after him counts as let go.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_target.gd
extends "res://tests/support/base_test.gd"

const MAN_SIZE: Vector2 = Vector2(40.0, 80.0)
const MAN_START: Vector2 = Vector2(500.0, 300.0)
## How far the man moves along the floor in one physics frame of FRAME seconds, in px.
const STEP: float = 10.0
const FRAME: float = 1.0 / 60.0
## The physics frame the demon sees the man on in the memory case.
const SEEN_FRAME: int = 10


func _initialize() -> void:
	var results: Array[bool] = [
		_take_keeps_the_man(),
		_track_measures_his_speed(),
		_memory_counts_unseen_frames(),
		_forget_keeps_the_last_seen_x(),
		_take_again_starts_over(),
		_freed_man_is_let_go(),
		_man_without_hurtbox_takes_hits(),
	]
	quit(0 if not results.has(false) else 1)


## A man of MAN_SIZE at MAN_START, in the tree, with a Hurtbox unless with_hurtbox is false.
func _make_man(with_hurtbox: bool = true) -> CharacterBody2D:
	var man: CharacterBody2D = CharacterBody2D.new()
	var box: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = MAN_SIZE
	box.shape = shape
	man.add_child(box)
	if with_hurtbox:
		man.add_child(Hurtbox.new())
	man.position = MAN_START
	root.add_child(man)
	return man


func _report(passed: bool, text: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", text])
	return passed


func _take_keeps_the_man() -> bool:
	var man: CharacterBody2D = _make_man()
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	var open: bool = not target.takes_no_hits()
	(man.get_child(1) as Hurtbox).set_closed(true)
	var passed: bool = target.has_man() and target.get_man() == man \
			and target.get_box() == man.get_child(0) and target.get_half_size() == MAN_SIZE / 2.0 \
			and open and target.takes_no_hits() and target.get_speed() == 0.0 \
			and target.get_unseen_frames() == 0 and target.get_last_seen_x() == MAN_START.x
	man.free()
	return _report(passed, "taking the man keeps him, his box, his Hurtbox, and where he stands as "
			+ "last seen, standing still")


func _track_measures_his_speed() -> bool:
	var man: CharacterBody2D = _make_man()
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	man.position.x += STEP
	target.track(FRAME)
	var speed: float = target.get_speed()
	man.free()
	return _report(is_equal_approx(speed, STEP / FRAME),
			"%.0f px in a frame tracks as %.0f px/s (expected %.0f)" % [STEP, speed, STEP / FRAME])


func _memory_counts_unseen_frames() -> bool:
	var man: CharacterBody2D = _make_man()
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	target.missed_him()
	target.missed_him()
	var unseen: int = target.get_unseen_frames()
	man.position.x += STEP
	target.saw_him(SEEN_FRAME)
	var passed: bool = unseen == 2 and target.get_unseen_frames() == 0 \
			and target.get_last_seen_x() == MAN_START.x + STEP \
			and target.sees_him_on(SEEN_FRAME) \
			and target.sees_him_on(SEEN_FRAME + DemonTarget.SEEN_FRAMES) \
			and not target.sees_him_on(SEEN_FRAME + DemonTarget.SEEN_FRAMES + 1)
	man.free()
	return _report(passed, "two misses count 2 unseen frames; seeing him starts over, moves the "
			+ "last seen x, and counts as seeing him for %d frame after" % DemonTarget.SEEN_FRAMES)


func _forget_keeps_the_last_seen_x() -> bool:
	var man: CharacterBody2D = _make_man()
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	man.position.x += STEP
	target.saw_him(SEEN_FRAME)
	target.missed_him()
	target.forget()
	var passed: bool = not target.has_man() and target.get_man() == null \
			and target.get_box() == null and not target.takes_no_hits() \
			and not target.sees_him_on(SEEN_FRAME) \
			and target.get_last_seen_x() == MAN_START.x + STEP and target.get_unseen_frames() == 1
	man.free()
	return _report(passed, "letting go of the man keeps where he was last seen, for the search, "
			+ "and the frames unseen")


func _take_again_starts_over() -> bool:
	var man: CharacterBody2D = _make_man()
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	man.position.x += STEP
	target.track(FRAME)
	target.missed_him()
	target.forget()
	target.take(man)
	var passed: bool = target.get_speed() == 0.0 and target.get_unseen_frames() == 0 \
			and target.get_last_seen_x() == MAN_START.x + STEP
	man.free()
	return _report(passed, "taking the man again starts his speed and frames unseen over, from "
			+ "where he stands now")


func _freed_man_is_let_go() -> bool:
	var man: CharacterBody2D = _make_man()
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	man.position.x += STEP
	target.track(FRAME)
	target.saw_him(SEEN_FRAME)
	man.free()
	target.track(FRAME)
	var passed: bool = not target.has_man() and is_equal_approx(target.get_speed(), STEP / FRAME) \
			and not target.takes_no_hits() and not target.sees_him_on(SEEN_FRAME)
	return _report(passed, "a man freed while the demon is after him counts as let go: tracking "
			+ "skips him, keeping his last speed, no hits held back, not seen")


func _man_without_hurtbox_takes_hits() -> bool:
	var man: CharacterBody2D = _make_man(false)
	var target: DemonTarget = DemonTarget.new()
	target.take(man)
	var passed: bool = target.has_man() and not target.takes_no_hits()
	man.free()
	return _report(passed, "a man with no Hurtbox never holds an attack back")
