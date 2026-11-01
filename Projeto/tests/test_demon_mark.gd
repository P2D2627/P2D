# Test of the mark over a demon's head (ADR 0040). The demon scene has it, hidden at the start and
# wired to the demon's state_changed. Alerted, the demon shows Alert Text, which pops up and shrinks
# to its own size, and keeps it Alert Linger Time into the chase; searching, it shows Search Text.
# Any other state hides it at once, a chase with no alert shows none, and a pause stops the linger.
# The demon's own physics is off, so only the test changes its state, by emitting state_changed.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_mark.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## Physics frames of leeway on each side of a time the mark counts.
const LEEWAY_FRAMES: int = 2
## Physics steps a second for the case at a higher rate.
const HIGH_TICKS: int = 120
## How far in front of the demon the man stands, in px: in its sight, and far enough that it is
## still chasing, not yet warning of an attack, once the linger is over.
const MAN_GAP: float = 900.0
## Half the width of the floor of the live cases, in px.
const LIVE_FLOOR_HALF: float = 1500.0
## Physics frames the live cases watch the demon, past its alert and linger.
const LIVE_FRAMES: int = 120


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_demon_has_a_hidden_mark())
	results.append(await _the_alert_mark_pops_up_and_shrinks())
	results.append(await _the_alert_mark_stays_into_the_chase_and_goes())
	results.append(await _the_search_mark_stays_until_another_state())
	results.append(await _other_states_hide_it_at_once())
	results.append(await _a_pause_stops_the_linger())
	results.append(await _the_linger_counts_seconds_at_120_hz())
	results.append(await _a_demon_freed_mid_linger_leaves_no_error())
	results.append(await _a_demon_that_notices_the_man_shows_the_alert_mark())
	results.append(await _a_demon_with_no_alert_shows_no_mark())
	finish(results)


## The demon scene's mark is linked to its label and hidden.
func _the_demon_has_a_hidden_mark() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	var linked: bool = mark != null and mark.label != null
	var hidden: bool = linked and not mark.visible
	await _clear(demon)
	return report(linked and hidden, "Demon scene's mark: linked %s, hidden at the start %s"
			% [linked, hidden])


## Alerted, the demon shows Alert Text at Pop Scale, at its own size again after Pop Time.
func _the_alert_mark_pops_up_and_shrinks() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var shown: bool = mark.visible and mark.label.text == mark.alert_text
	var popped: bool = is_equal_approx(mark.scale.x, mark.pop_scale)
	await wait_frames(_frames_of(mark.pop_time) + LEEWAY_FRAMES)
	var settled: bool = mark.scale.is_equal_approx(Vector2.ONE)
	var text: String = mark.alert_text
	await _clear(demon)
	return report(shown and popped and settled,
			"Alert: shows \"%s\" %s, popped %s, back to its own size %s"
			% [text, shown, popped, settled])


## The alert turned into the chase keeps the mark for Alert Linger Time, and then hides it.
func _the_alert_mark_stays_into_the_chase_and_goes() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	var linger_frames: int = _frames_of(mark.alert_linger_time)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.CHASE)
	await wait_frames(linger_frames - LEEWAY_FRAMES)
	var stayed: bool = mark.visible and mark.label.text == mark.alert_text
	await wait_frames(LEEWAY_FRAMES * 2)
	var gone: bool = not mark.visible
	var text: String = mark.alert_text
	await _clear(demon)
	return report(stayed and gone, "Alert into the chase: \"%s\" stays %d frames %s, then goes %s"
			% [text, linger_frames, stayed, gone])


## Searching, the demon shows Search Text for as long as it searches, and none once it returns.
func _the_search_mark_stays_until_another_state() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	demon.state_changed.emit(Demon.State.CHASE, Demon.State.SEARCH)
	await wait_frames(_frames_of(mark.alert_linger_time) + LEEWAY_FRAMES)
	var stayed: bool = mark.visible and mark.label.text == mark.search_text
	demon.state_changed.emit(Demon.State.SEARCH, Demon.State.RETURN)
	var gone: bool = not mark.visible
	var text: String = mark.search_text
	await _clear(demon)
	return report(stayed and gone, "Search: \"%s\" stays %s, gone on the return at once %s"
			% [text, stayed, gone])


## The crucifix in the alert, which throws the demon off and then repels it, hides the mark at once,
## and so does an attack while it lingers; a chase with no alert before it shows none.
func _other_states_hide_it_at_once() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.THROWN)
	var thrown_hides: bool = not mark.visible
	demon.state_changed.emit(Demon.State.THROWN, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.REPELLED)
	var repelled_hides: bool = thrown_hides and not mark.visible
	demon.state_changed.emit(Demon.State.REPELLED, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.CHASE)
	demon.state_changed.emit(Demon.State.CHASE, Demon.State.WARNING)
	var warning_hides: bool = not mark.visible
	demon.state_changed.emit(Demon.State.WARNING, Demon.State.CHASE)
	var chase_shows_none: bool = not mark.visible
	await _clear(demon)
	return report(repelled_hides and warning_hides and chase_shows_none,
			"Other states: thrown and repelled hide it %s, a warning while it lingers %s, chase alone shows none %s"
			% [repelled_hides, warning_hides, chase_shows_none])


## Paused while the mark lingers, it stays past Alert Linger Time; unpaused, it goes once the rest
## of it is over.
func _a_pause_stops_the_linger() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	var linger_frames: int = _frames_of(mark.alert_linger_time)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.CHASE)
	paused = true
	await wait_frames(linger_frames + LEEWAY_FRAMES)
	var stays_paused: bool = mark.visible
	paused = false
	await wait_frames(linger_frames + LEEWAY_FRAMES)
	var goes_after: bool = not mark.visible
	await _clear(demon)
	return report(stays_paused and goes_after, "Pause: the mark stays paused %s, goes after %s"
			% [stays_paused, goes_after])


## At HIGH_TICKS physics steps a second, the linger still lasts Alert Linger Time: twice as many
## steps as at 60.
func _the_linger_counts_seconds_at_120_hz() -> bool:
	var ticks_before: int = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = HIGH_TICKS
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	var linger_steps: int = _frames_of(mark.alert_linger_time)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.CHASE)
	await wait_frames(linger_steps - LEEWAY_FRAMES)
	var stayed: bool = mark.visible
	await wait_frames(LEEWAY_FRAMES * 2)
	var gone: bool = not mark.visible
	await _clear(demon)
	Engine.physics_ticks_per_second = ticks_before
	return report(stayed and gone, "At %d Hz: the mark stays %d steps %s, then goes %s"
			% [HIGH_TICKS, linger_steps, stayed, gone])


## A demon freed while its mark lingers takes the mark's tween with it: the test goes on with no
## error, and the next demon's mark shows as usual.
func _a_demon_freed_mid_linger_leaves_no_error() -> bool:
	var demon: Demon = await _make_demon()
	var mark: DemonMark = _mark_of(demon)
	var linger_frames: int = _frames_of(mark.alert_linger_time)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.CHASE)
	await wait_frames(LEEWAY_FRAMES)
	await _clear(demon)
	await wait_frames(linger_frames)
	var next: Demon = await _make_demon()
	next.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var next_shows: bool = _mark_of(next).visible
	await _clear(next)
	return report(next_shows, "Freed mid-linger: no error, the next demon's mark shows %s"
			% next_shows)


## A demon on a floor, with the man standing MAN_GAP in front of it, in its sight, notices him by
## itself: its mark shows Alert Text as it goes into ALERT, and stays its Alert Time and then Alert
## Linger Time into the chase.
func _a_demon_that_notices_the_man_shows_the_alert_mark() -> bool:
	var scene: Array[Node] = await _make_live_scene(-1.0)
	var demon: Demon = scene[0] as Demon
	var mark: DemonMark = _mark_of(demon)
	var expected: int = demon.stats.get_alert_frames() + _frames_of(mark.alert_linger_time)
	var shown_in_alert: bool = false
	var shown_frames: int = 0
	for _frame: int in LIVE_FRAMES:
		await physics_frame
		if mark.visible:
			shown_frames += 1
			if shown_frames == 1:
				shown_in_alert = demon.get_state() == Demon.State.ALERT \
						and mark.label.text == mark.alert_text
		elif shown_frames > 0:
			break
	await _clear_live(scene)
	var lasted: bool = absi(shown_frames - expected) <= LEEWAY_FRAMES
	return report(shown_in_alert and lasted,
			"Live alert: \"!\" shows in ALERT %s, for %d frames (alert and linger %d)"
			% [shown_in_alert, shown_frames, expected])


## The same demon with Alert Time 0 chases the man at once, with no alert, so no mark either.
func _a_demon_with_no_alert_shows_no_mark() -> bool:
	var scene: Array[Node] = await _make_live_scene(0.0)
	var demon: Demon = scene[0] as Demon
	var mark: DemonMark = _mark_of(demon)
	var chased: bool = false
	var ever_shown: bool = false
	for _frame: int in LIVE_FRAMES:
		await physics_frame
		chased = chased or demon.get_state() == Demon.State.CHASE
		ever_shown = ever_shown or mark.visible
	await _clear_live(scene)
	return report(chased and not ever_shown, "Alert Time 0: chases %s, mark never shown %s"
			% [chased, not ever_shown])


## The demon, the man and the floor: the man stands MAN_GAP in front of where the demon lands, and
## the demon gets its own copy of its stats, with Alert Time alert_time, or its own if negative.
func _make_live_scene(alert_time: float) -> Array[Node]:
	var floor_body: StaticBody2D = make_platform(-LIVE_FLOOR_HALF, LIVE_FLOOR_HALF)
	var man: Player = await spawn_on_floor(Vector2(MAN_GAP, -1.0))
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.stats = demon.stats.duplicate(true) as DemonStats
	if alert_time >= 0.0:
		demon.stats.alert_time = alert_time
	demon.position = Vector2(0.0, -1.0)
	root.add_child(demon)
	return [demon, man, floor_body]


func _clear_live(scene: Array[Node]) -> void:
	for node: Node in scene:
		if is_instance_valid(node):
			node.queue_free()
	await physics_frame


## A demon of DEMON_SCENE with its own physics off, so it stays in the state the test gives it.
func _make_demon() -> Demon:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	root.add_child(demon)
	demon.set_physics_process(false)
	await physics_frame
	return demon


func _mark_of(demon: Demon) -> DemonMark:
	return demon.get_node_or_null(^"Mark") as DemonMark


func _frames_of(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)


func _clear(demon: Demon) -> void:
	paused = false
	demon.queue_free()
	await physics_frame
