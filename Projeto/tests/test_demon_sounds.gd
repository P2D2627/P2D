# Test of the demon's sounds (ADR 0040). The demon scene has them, linked to the demon and to a cue
# on the SFX bus, with the alert and search beeps and no bark yet. The alert plays Alert Sound and
# the search Search Sound, at the demon's voice moved by at most Pitch Variation; a bark plays Bark
# Sound, and nothing while its slot is empty; other states play nothing. A take-off plays Take Off
# Sound and a landing Land Sound, both in the scene, at the demon's voice; a pack leaping on one
# step starts at most Max Leap Sounds Per Step of them, and never silences an alert. Each demon's
# voice is within Voice Spread of the normal pitch, and demons do not all share one.
# The demon's own physics is off, so only the test changes its state, by emitting its signals.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_sounds.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## Demons made to compare their voices.
const VOICE_DEMONS: int = 10
## Demons barking, more than Max Barks Per Step, and demons alerted on the same step, no more than
## Max Notice Sounds Per Step.
const BARKING_DEMONS: int = 4
const ALERTED_DEMONS: int = 2
## Any seed: the case compares two runs from it.
const RANDOM_SEED: int = 7


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_demon_scene_has_its_sounds())
	results.append(await _the_alert_and_the_search_play_their_beeps())
	results.append(await _a_bark_plays_its_sound_and_an_empty_slot_none())
	results.append(await _other_states_play_nothing())
	results.append(await _each_demon_has_its_own_voice())
	results.append(await _a_pack_starts_at_most_its_limit_on_one_frame())
	results.append(await _barks_never_silence_an_alert())
	results.append(await _the_sounds_take_no_global_random_numbers())
	results.append(await _the_take_off_and_the_landing_play_their_sounds())
	results.append(await _leaps_count_apart_and_never_silence_an_alert())
	finish(results)


## The demon scene's sounds are linked to it and to a cue on the SFX bus, with both beeps and no
## bark yet.
func _the_demon_scene_has_its_sounds() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	var linked: bool = sounds != null and sounds.demon == demon and sounds.cue != null \
			and sounds.cue.bus == &"SFX"
	var filled: bool = linked and sounds.alert_sound != null and sounds.search_sound != null \
			and sounds.bark_sound == null
	await _clear(demon)
	return report(linked and filled, "Demon scene's sounds: linked on SFX %s, beeps in and no bark %s"
			% [linked, filled])


## The alert plays Alert Sound and the search Search Sound, each at the demon's voice moved by at
## most Pitch Variation.
func _the_alert_and_the_search_play_their_beeps() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var alert_plays: bool = sounds.cue.stream == sounds.alert_sound and sounds.cue.playing \
			and _within_voice(sounds)
	demon.state_changed.emit(Demon.State.CHASE, Demon.State.SEARCH)
	var search_plays: bool = sounds.cue.stream == sounds.search_sound and sounds.cue.playing \
			and _within_voice(sounds)
	await _clear(demon)
	return report(alert_plays and search_plays, "Beeps: alert plays at its voice %s, search %s"
			% [alert_plays, search_plays])


## A bark plays nothing while Bark Sound is empty, as in the scene, and plays it once filled.
func _a_bark_plays_its_sound_and_an_empty_slot_none() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	demon.barked.emit(false)
	var empty_plays_none: bool = sounds.cue.stream == null and not sounds.cue.playing
	sounds.bark_sound = sounds.alert_sound
	demon.barked.emit(true)
	var filled_plays: bool = sounds.cue.stream == sounds.bark_sound and sounds.cue.playing
	await _clear(demon)
	return report(empty_plays_none and filled_plays,
			"Bark: empty slot plays nothing %s, filled plays it %s" % [empty_plays_none, filled_plays])


## The chase, a warning, the return and the stun play none of these sounds.
func _other_states_play_nothing() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	for state: Demon.State in [Demon.State.CHASE, Demon.State.WARNING, Demon.State.RETURN,
			Demon.State.STUNNED]:
		demon.state_changed.emit(Demon.State.IDLE, state)
	var silent: bool = sounds.cue.stream == null and not sounds.cue.playing
	await _clear(demon)
	return report(silent, "Other states: silent %s" % silent)


## Each demon's voice is within Voice Spread of the normal pitch, and VOICE_DEMONS demons do not
## all share one.
func _each_demon_has_its_own_voice() -> bool:
	var voices: Array[float] = []
	var within: bool = true
	for _index: int in VOICE_DEMONS:
		var demon: Demon = await _make_demon()
		var sounds: DemonSounds = _sounds_of(demon)
		voices.append(sounds.get_voice())
		within = within and absf(sounds.get_voice() - 1.0) <= sounds.voice_spread
		await _clear(demon)
	var differ: bool = voices.min() < voices.max()
	return report(within and differ, "Voices of %d demons: %.3f to %.3f, within the spread %s"
			% [VOICE_DEMONS, voices.min(), voices.max(), within])


## VOICE_DEMONS demons alerted on one physics step start Max Notice Sounds Per Step sounds between
## them, and on the next step one more alerted starts its own.
func _a_pack_starts_at_most_its_limit_on_one_frame() -> bool:
	var demons: Array[Demon] = []
	for _index: int in VOICE_DEMONS:
		demons.append(await _make_demon())
	var limit: int = _sounds_of(demons[0]).max_notice_sounds_per_step
	for demon: Demon in demons:
		demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var started: int = demons.filter(
			func(demon: Demon) -> bool: return _sounds_of(demon).cue.playing).size()
	await physics_frame
	var late: Demon = await _make_demon()
	late.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var next_frame_plays: bool = _sounds_of(late).cue.playing
	demons.append(late)
	for demon: Demon in demons:
		await _clear(demon)
	return report(started == limit and next_frame_plays,
			"Pack of %d alerted at once: %d sounds started, limit %d; next frame plays %s"
			% [VOICE_DEMONS, started, limit, next_frame_plays])


## BARKING_DEMONS demons barking on one physics step start Max Barks Per Step barks between them,
## and ALERTED_DEMONS more alerted on that same step all start their beeps: barks count apart.
func _barks_never_silence_an_alert() -> bool:
	var barking: Array[Demon] = []
	var alerted: Array[Demon] = []
	for _index: int in BARKING_DEMONS:
		barking.append(await _make_demon())
	for _index: int in ALERTED_DEMONS:
		alerted.append(await _make_demon())
	var bark_limit: int = _sounds_of(barking[0]).max_barks_per_step
	for demon: Demon in barking:
		_sounds_of(demon).bark_sound = _sounds_of(demon).alert_sound
		demon.barked.emit(false)
	for demon: Demon in alerted:
		demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var barks: int = barking.filter(_is_playing).size()
	var alerts: int = alerted.filter(_is_playing).size()
	for demon: Demon in barking + alerted:
		await _clear(demon)
	return report(barks == bark_limit and alerts == ALERTED_DEMONS,
			"Barks on one step: %d of %d bark (limit %d), %d of %d alerted beep after them"
			% [barks, BARKING_DEMONS, bark_limit, alerts, ALERTED_DEMONS])


## Making a demon takes from the global random numbers only what the demon itself takes, the seed
## of its own: the same next number as a seed with one number taken, so its sounds take none.
func _the_sounds_take_no_global_random_numbers() -> bool:
	seed(RANDOM_SEED)
	randi()
	var expected: int = randi()
	seed(RANDOM_SEED)
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	root.add_child(demon)
	demon.set_physics_process(false)
	var next: int = randi()
	await _clear(demon)
	return report(next == expected, "Global random numbers after making a demon: one taken %s"
			% (next == expected))


## The demon scene fills Take Off Sound and Land Sound; a take-off plays the first and a landing
## the second, each at the demon's voice moved by at most Pitch Variation.
func _the_take_off_and_the_landing_play_their_sounds() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	var filled: bool = sounds.take_off_sound != null and sounds.land_sound != null
	demon.took_off.emit()
	var take_off_plays: bool = sounds.cue.stream == sounds.take_off_sound and sounds.cue.playing \
			and _within_voice(sounds)
	await physics_frame
	demon.landed.emit()
	var land_plays: bool = sounds.cue.stream == sounds.land_sound and sounds.cue.playing \
			and _within_voice(sounds)
	await _clear(demon)
	return report(filled and take_off_plays and land_plays,
			"Leap: both sounds in the scene %s, take-off plays at its voice %s, landing %s"
			% [filled, take_off_plays, land_plays])


## BARKING_DEMONS demons taking off on one physics step start Max Leap Sounds Per Step sounds
## between them, and ALERTED_DEMONS more alerted on that same step all start their beeps.
func _leaps_count_apart_and_never_silence_an_alert() -> bool:
	var leaping: Array[Demon] = []
	var alerted: Array[Demon] = []
	for _index: int in BARKING_DEMONS:
		leaping.append(await _make_demon())
	for _index: int in ALERTED_DEMONS:
		alerted.append(await _make_demon())
	var leap_limit: int = _sounds_of(leaping[0]).max_leap_sounds_per_step
	for demon: Demon in leaping:
		demon.took_off.emit()
	for demon: Demon in alerted:
		demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var leaps: int = leaping.filter(_is_playing).size()
	var alerts: int = alerted.filter(_is_playing).size()
	for demon: Demon in leaping + alerted:
		await _clear(demon)
	return report(leaps == leap_limit and alerts == ALERTED_DEMONS,
			"Take-offs on one step: %d of %d play (limit %d), %d of %d alerted beep after them"
			% [leaps, BARKING_DEMONS, leap_limit, alerts, ALERTED_DEMONS])


func _is_playing(demon: Demon) -> bool:
	return _sounds_of(demon).cue.playing


## Whether the cue's pitch is within Pitch Variation of the demon's voice.
func _within_voice(sounds: DemonSounds) -> bool:
	return absf(sounds.cue.pitch_scale / sounds.get_voice() - 1.0) \
			<= sounds.pitch_variation + 0.0001


## A demon of DEMON_SCENE with its own physics off, so it stays in the state the test gives it.
func _make_demon() -> Demon:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	root.add_child(demon)
	demon.set_physics_process(false)
	await physics_frame
	return demon


func _sounds_of(demon: Demon) -> DemonSounds:
	return demon.get_node_or_null(^"DemonSounds") as DemonSounds


func _clear(demon: Demon) -> void:
	demon.queue_free()
	await physics_frame
