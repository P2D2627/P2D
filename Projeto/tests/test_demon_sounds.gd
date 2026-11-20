# Test of the demon's sounds (ADR 0040). The demon scene has them, linked to the demon: the dog's own
# five, each a SoundEmitter that plays only when told, with its files (the alert on the Alerts bus,
# the others on SFX), and the placeholder beeps on a cue on the Alerts bus, off, with the alert,
# search, take-off and landing beeps still in their slots and no bark. By default no beep plays.
# The alert plays the dog's alert at the demon's voice moved by at most Pitch Variation; a take-off
# and a lunge play the jump, without cutting the alert off; a landed attack plays the attack, and
# the crucifix's hit the crucifix hit, one of its two files, but not the throw when the man breaks
# free, nor the crucifix pushing on while it is thrown. Once the alert's sound is over, Latch Gap
# later, the latch plays one of its two files, after the old beep too with Use Old Alert; not once
# the dog has lost the man or been thrown off. Each of the dog's sounds is turned off by its
# Enabled. With Play Beeps and Use Old Alert, the alert plays Alert Sound and the search Search
# Sound, a bark plays Bark Sound, and nothing while its slot is empty, a take-off Take Off Sound and
# a landing Land Sound; other states play nothing. On one physics step, a pack starts at most its
# limit of each kind of sound, and barks, leaps, attacks and hits never silence an alert. Each
# demon's voice is within Voice Spread of the normal pitch, and demons do not all share one. Neither
# making a demon nor any of its sounds takes from the global random numbers.
# The demon's own physics is off, so only the test changes its state, by emitting its signals.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_sounds.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://scenes/characters/demon/demon.tscn")
## The dog's own files, as the scene should have them.
const DOG_FILES: Dictionary[StringName, Array] = {
	&"alert": ["demon_dog_alert.wav"],
	&"latch": ["demon_dog_latch_1.wav", "demon_dog_latch_2.wav"],
	&"jump": ["demon_dog_jump.wav"],
	&"attack": ["demon_dog_attack.wav"],
	&"crucifix_hit": ["demon_dog_cruci_hit_1.wav", "demon_dog_cruci_hit_2.wav"],
}
## Demons made to compare their voices.
const VOICE_DEMONS: int = 10
## Demons barking, more than Max Barks Per Step, and demons alerted on the same step, no more than
## Max Notice Sounds Per Step.
const BARKING_DEMONS: int = 4
const ALERTED_DEMONS: int = 2
## Any seed: the case compares two runs from it.
const RANDOM_SEED: int = 7
## The length of a physics frame with --fixed-fps 60, as in the command above.
const FRAME_TIME: float = 1.0 / 60.0
## How many physics frames off its time the latch may start: the step it falls in, and rounding.
const LATCH_FRAMES_TOLERANCE: int = 2
## A Latch Gap for the second dog of the latch case, in s.
const LONGER_GAP: float = 0.5
## Times a crucifix hit is played to see both its files.
const HITS_TO_HEAR: int = 24
## Rounding room for the pitch.
const PITCH_TOLERANCE: float = 0.0001


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_demon_scene_has_its_sounds())
	results.append(await _no_beep_plays_by_default())
	results.append(await _the_dogs_own_sounds_play_at_their_moments())
	results.append(await _the_crucifix_hit_plays_only_for_the_crucifix())
	results.append(await _the_latch_plays_once_the_alerts_sound_is_over())
	results.append(await _the_latch_is_dropped_once_the_dog_loses_the_man())
	results.append(await _each_dog_sound_turns_off())
	results.append(await _the_alert_and_the_search_play_their_beeps())
	results.append(await _a_bark_plays_its_sound_and_an_empty_slot_none())
	results.append(await _other_states_play_nothing())
	results.append(await _each_demon_has_its_own_voice())
	results.append(await _a_pack_starts_at_most_its_limit_on_one_frame())
	results.append(await _barks_never_silence_an_alert())
	results.append(await _the_sounds_take_no_global_random_numbers())
	results.append(await _the_take_off_and_the_landing_play_their_sounds())
	results.append(await _leaps_count_apart_and_never_silence_an_alert())
	results.append(await _attacks_and_hits_count_apart_and_never_silence_an_alert())
	finish(results)


## The demon scene's sounds are linked to it; the dog's own five play only when told, asleep, with
## their files, the alert on Alerts and the others on SFX; the beeps are off, on a cue on Alerts,
## with the alert, search, take-off and landing beeps in and no bark.
func _the_demon_scene_has_its_sounds() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	var linked: bool = sounds != null and sounds.demon == demon and sounds.cue != null \
			and sounds.cue.bus == &"Alerts"
	var problems: Array[String] = []
	for slot: StringName in DOG_FILES:
		var emitter: SoundEmitter = sounds.get(slot) as SoundEmitter if linked else null
		if emitter == null:
			problems.append("%s missing" % slot)
			continue
		var files: Array[String] = _files_of(emitter.one_shots)
		files.sort()
		if files != DOG_FILES[slot]:
			problems.append("%s has %s" % [slot, files])
		var bus: StringName = &"Alerts" if slot == &"alert" else &"SFX"
		if emitter.one_shot_player.bus != bus:
			problems.append("%s on %s" % [slot, emitter.one_shot_player.bus])
		if emitter.plays_on_its_own or emitter.is_physics_processing() or emitter.loop != null:
			problems.append("%s plays by itself or is awake" % slot)
	var beeps: bool = linked and not sounds.play_beeps and not sounds.use_old_alert \
			and sounds.alert_sound != null and sounds.search_sound != null \
			and sounds.take_off_sound != null and sounds.land_sound != null \
			and sounds.bark_sound == null
	await _clear(demon)
	return report(linked and problems.is_empty() and beeps,
			"Demon scene's sounds: linked on Alerts %s, the dog's own in place (problems: %s), "
			% [linked, "; ".join(problems)] + "beeps off and kept in their slots %s" % beeps)


## With the scene's settings, the alert, the search, a bark (its slot filled), a take-off and a
## landing play no beep on the cue.
func _no_beep_plays_by_default() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	sounds.bark_sound = sounds.alert_sound
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	demon.state_changed.emit(Demon.State.ALERT, Demon.State.SEARCH)
	demon.barked.emit(false)
	await physics_frame
	demon.took_off.emit()
	demon.landed.emit()
	var silent: bool = sounds.cue.stream == null and not sounds.cue.playing
	await _clear(demon)
	return report(silent, "Beeps off by default: the cue stays silent %s" % silent)


## The alert plays the dog's alert at the demon's voice; a take-off, and a lunge with Jump On Lunge,
## play the jump while the alert goes on; without it a lunge plays none; a landed attack plays the
## attack.
func _the_dogs_own_sounds_play_at_their_moments() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	var jumps: Array[int] = [0]
	sounds.jump.one_shot_played.connect(func(_at: Vector2, _side: float) -> void: jumps[0] += 1)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var alert_plays: bool = sounds.alert.one_shot_player.playing \
			and _within_voice(sounds, sounds.alert.one_shot_player.pitch_scale)
	await physics_frame
	demon.took_off.emit()
	var jump_plays: bool = sounds.jump.one_shot_player.playing and jumps[0] == 1
	var alert_goes_on: bool = sounds.alert.one_shot_player.playing
	await physics_frame
	demon.state_changed.emit(Demon.State.WARNING, Demon.State.LUNGE)
	var lunge_jumps: bool = jumps[0] == 2
	await physics_frame
	sounds.jump_on_lunge = false
	demon.state_changed.emit(Demon.State.WARNING, Demon.State.LUNGE)
	var lunge_silent: bool = jumps[0] == 2
	demon.attack_landed.emit(null)
	var attack_plays: bool = sounds.attack.one_shot_player.playing \
			and _within_voice(sounds, sounds.attack.one_shot_player.pitch_scale)
	await _clear(demon)
	return report(alert_plays and jump_plays and alert_goes_on and lunge_jumps and lunge_silent
			and attack_plays, "The dog's own: alert at its voice %s, take-off jumps %s and the alert "
			% [alert_plays, jump_plays] + "goes on %s, a lunge jumps %s and without Jump On Lunge "
			% [alert_goes_on, lunge_jumps] + "not %s, a landed attack plays %s"
			% [lunge_silent, attack_plays])


## The crucifix's push throws the dog off and plays the crucifix hit, one of its files at the
## demon's voice within its Random Pitch; pushing on while thrown plays no other. Over many hits
## both files play. The throw when the man breaks free plays none.
func _the_crucifix_hit_plays_only_for_the_crucifix() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	var repellable: Repellable = demon.get_node(^"Repellable") as Repellable
	var hits: Array[int] = [0]
	sounds.crucifix_hit.one_shot_played.connect(
			func(_at: Vector2, _side: float) -> void: hits[0] += 1)
	repellable.repelled.emit(demon.global_position + Vector2(-60.0, 0.0))
	var thrown: bool = demon.get_state() == Demon.State.THROWN
	var hit_plays: bool = hits[0] == 1 and sounds.crucifix_hit.one_shot_player.playing
	var randomizer := sounds.crucifix_hit.one_shots as AudioStreamRandomizer
	var spread: float = randomizer.random_pitch if randomizer != null else 1.0
	var within: bool = _within_hit_pitch(sounds, spread)
	await physics_frame
	repellable.repelled.emit(demon.global_position + Vector2(-60.0, 0.0))
	var once: bool = hits[0] == 1
	var heard: Dictionary[String, bool] = {}
	for _index: int in HITS_TO_HEAR:
		await physics_frame
		demon.change_state(Demon.State.REPELLED)
		repellable.repelled.emit(demon.global_position + Vector2(-60.0, 0.0))
		heard[sounds.crucifix_hit.one_shot_player.stream.resource_path.get_file()] = true
		within = within and _within_hit_pitch(sounds, spread)
	var both: bool = heard.size() == 2
	await _clear(demon)
	var freed: Demon = await _make_demon()
	var freed_hits: Array[int] = [0]
	_sounds_of(freed).crucifix_hit.one_shot_played.connect(
			func(_at: Vector2, _side: float) -> void: freed_hits[0] += 1)
	freed.change_state(Demon.State.GRAB)
	freed._throw_off(freed.global_position + Vector2(60.0, 0.0), false)
	var break_free_silent: bool = freed.get_state() == Demon.State.THROWN and freed_hits[0] == 0
	await _clear(freed)
	return report(thrown and hit_plays and within and once and both and break_free_silent,
			"Crucifix hit: thrown %s and heard %s, within its pitch %s, once while thrown %s, both "
			% [thrown, hit_plays, within, once] + "files over %d hits %s %s; breaking free plays none %s"
			% [HITS_TO_HEAR, both, heard.keys(), break_free_silent])


## A dog alerted waits, and plays the latch, one of its files, Latch Gap after the alert's sound
## ends at the pitch it played at, give or take LATCH_FRAMES_TOLERANCE frames: one at the scene's
## gap, one LONGER_GAP later, and one with Use Old Alert, after the old beep.
func _the_latch_plays_once_the_alerts_sound_is_over() -> bool:
	var demons: Array[Demon] = []
	for _index: int in 3:
		demons.append(await _make_demon())
	_sounds_of(demons[1]).latch_gap += LONGER_GAP
	_sounds_of(demons[2]).use_old_alert = true
	var expected: Array[float] = []
	var started: Array[int] = [-1, -1, -1]
	var waiting: bool = true
	for index: int in demons.size():
		var sounds: DemonSounds = _sounds_of(demons[index])
		demons[index].state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
		waiting = waiting and sounds.is_latch_waiting()
		var player: AudioStreamPlayer2D = sounds.cue if sounds.use_old_alert \
				else sounds.alert.one_shot_player
		expected.append(player.stream.get_length() / player.pitch_scale + sounds.latch_gap)
		var on_latch := func(_at: Vector2, _side: float) -> void:
			started[index] = Engine.get_physics_frames()
		sounds.latch.one_shot_played.connect(on_latch)
	var from: int = Engine.get_physics_frames()
	var last: float = expected.max()
	while Engine.get_physics_frames() - from < int(last / FRAME_TIME) + 30 and started.has(-1):
		await physics_frame
	var lines: Array[String] = []
	var on_time: bool = waiting
	for index: int in demons.size():
		var at: float = (started[index] - from) * FRAME_TIME
		var files: bool = DOG_FILES[&"latch"].has(
				_sounds_of(demons[index]).latch.one_shot_player.stream.resource_path.get_file())
		on_time = on_time and started[index] >= 0 and files \
				and absf(at - expected[index]) <= LATCH_FRAMES_TOLERANCE * FRAME_TIME
		lines.append("%.3f s for %.3f" % [at, expected[index]])
	for demon: Demon in demons:
		await _clear(demon)
	return report(on_time, "Latch after the alert's sound (waiting %s): %s" % [waiting,
			", ".join(lines)])


## A dog alerted that then loses the man, starts to search or is thrown off plays no latch; one
## that chases on does.
func _the_latch_is_dropped_once_the_dog_loses_the_man() -> bool:
	var moves: Array[Demon.State] = [Demon.State.RETURN, Demon.State.SEARCH, Demon.State.THROWN,
			Demon.State.CHASE]
	var demons: Array[Demon] = []
	var latches: Array[int] = [0, 0, 0, 0]
	for index: int in moves.size():
		var demon: Demon = await _make_demon()
		demons.append(demon)
		_sounds_of(demon).latch.one_shot_played.connect(
				func(_at: Vector2, _side: float) -> void: latches[index] += 1)
	var longest: float = 0.0
	for index: int in moves.size():
		await physics_frame
		demons[index].state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
		var sounds: DemonSounds = _sounds_of(demons[index])
		var player: AudioStreamPlayer2D = sounds.alert.one_shot_player
		longest = maxf(longest, player.stream.get_length() / player.pitch_scale + sounds.latch_gap)
	await physics_frame
	for index: int in moves.size():
		demons[index].state_changed.emit(Demon.State.ALERT, moves[index])
	for _step: int in int(longest * 1.2 / FRAME_TIME) + 10:
		await physics_frame
	var dropped: bool = latches[0] == 0 and latches[1] == 0 and latches[2] == 0
	var kept: bool = latches[3] == 1
	for demon: Demon in demons:
		await _clear(demon)
	return report(dropped and kept, "Latch dropped on return, search and throw %s (%s), kept on "
			% [dropped, latches.slice(0, 3)] + "the chase %s" % kept)


## Each of the dog's sounds, Enabled off, plays nothing at its moment, and the latch off is not
## waited for.
func _each_dog_sound_turns_off() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	for emitter: SoundEmitter in _dog_sounds(sounds):
		emitter.enabled = false
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var no_latch: bool = not sounds.is_latch_waiting()
	await physics_frame
	demon.took_off.emit()
	demon.attack_landed.emit(null)
	(demon.get_node(^"Repellable") as Repellable).repelled.emit(demon.global_position)
	var silent: bool = not _is_playing(demon)
	await _clear(demon)
	return report(silent and no_latch, "Each of the dog's sounds off: silent %s, no latch waits %s"
			% [silent, no_latch])


## With Use Old Alert and Play Beeps, the alert plays Alert Sound and not the dog's alert, and the
## search Search Sound, each at the demon's voice moved by at most Pitch Variation.
func _the_alert_and_the_search_play_their_beeps() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	sounds.use_old_alert = true
	sounds.play_beeps = true
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var alert_plays: bool = sounds.cue.stream == sounds.alert_sound and sounds.cue.playing \
			and _within_voice(sounds, sounds.cue.pitch_scale) \
			and not sounds.alert.one_shot_player.playing
	demon.state_changed.emit(Demon.State.CHASE, Demon.State.SEARCH)
	var search_plays: bool = sounds.cue.stream == sounds.search_sound and sounds.cue.playing \
			and _within_voice(sounds, sounds.cue.pitch_scale)
	await _clear(demon)
	return report(alert_plays and search_plays, "Beeps: old alert plays at its voice instead of "
			+ "the dog's %s, search %s" % [alert_plays, search_plays])


## With Play Beeps, a bark plays nothing while Bark Sound is empty, as in the scene, and plays it
## once filled.
func _a_bark_plays_its_sound_and_an_empty_slot_none() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	sounds.play_beeps = true
	demon.barked.emit(false)
	var empty_plays_none: bool = sounds.cue.stream == null and not sounds.cue.playing
	sounds.bark_sound = sounds.alert_sound
	demon.barked.emit(true)
	var filled_plays: bool = sounds.cue.stream == sounds.bark_sound and sounds.cue.playing
	await _clear(demon)
	return report(empty_plays_none and filled_plays,
			"Bark: empty slot plays nothing %s, filled plays it %s" % [empty_plays_none, filled_plays])


## The chase, a warning, the return and the stun play none of these sounds, beeps on or off.
func _other_states_play_nothing() -> bool:
	var silent: bool = true
	for beeps: bool in [false, true]:
		var demon: Demon = await _make_demon()
		_sounds_of(demon).play_beeps = beeps
		for state: Demon.State in [Demon.State.CHASE, Demon.State.WARNING, Demon.State.RETURN,
				Demon.State.STUNNED]:
			demon.state_changed.emit(Demon.State.IDLE, state)
		silent = silent and not _is_playing(demon) and _sounds_of(demon).cue.stream == null
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
	var started: int = demons.filter(_is_playing).size()
	await physics_frame
	var late: Demon = await _make_demon()
	late.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var next_frame_plays: bool = _is_playing(late)
	demons.append(late)
	for demon: Demon in demons:
		await _clear(demon)
	return report(started == limit and next_frame_plays,
			"Pack of %d alerted at once: %d sounds started, limit %d; next frame plays %s"
			% [VOICE_DEMONS, started, limit, next_frame_plays])


## BARKING_DEMONS demons barking with Play Beeps on one physics step start Max Barks Per Step barks
## between them, and ALERTED_DEMONS more alerted on that same step all start their alerts: barks
## count apart.
func _barks_never_silence_an_alert() -> bool:
	var barking: Array[Demon] = []
	var alerted: Array[Demon] = []
	for _index: int in BARKING_DEMONS:
		barking.append(await _make_demon())
	for _index: int in ALERTED_DEMONS:
		alerted.append(await _make_demon())
	var bark_limit: int = _sounds_of(barking[0]).max_barks_per_step
	for demon: Demon in barking:
		_sounds_of(demon).play_beeps = true
		_sounds_of(demon).bark_sound = _sounds_of(demon).alert_sound
		demon.barked.emit(false)
	for demon: Demon in alerted:
		demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var barks: int = barking.filter(_is_playing).size()
	var alerts: int = alerted.filter(_is_playing).size()
	for demon: Demon in barking + alerted:
		await _clear(demon)
	return report(barks == bark_limit and alerts == ALERTED_DEMONS,
			"Barks on one step: %d of %d bark (limit %d), %d of %d alerted play after them"
			% [barks, BARKING_DEMONS, bark_limit, alerts, ALERTED_DEMONS])


## Making a demon takes from the global random numbers only what the demon itself takes, the seed
## of its own: the same next number as a seed with one number taken. Its sounds take none either:
## the alert, the latch, a take-off, an attack and the crucifix hit, the two last picked from
## their files.
func _the_sounds_take_no_global_random_numbers() -> bool:
	seed(RANDOM_SEED)
	randi()
	var expected: int = randi()
	seed(RANDOM_SEED)
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	root.add_child(demon)
	demon.set_physics_process(false)
	var made: bool = randi() == expected
	var sounds: DemonSounds = _sounds_of(demon)
	sounds.latch_gap = -10.0
	seed(RANDOM_SEED)
	var after: int = randi()
	seed(RANDOM_SEED)
	demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	await physics_frame
	await physics_frame
	var latched: bool = sounds.latch.one_shot_player.playing
	demon.took_off.emit()
	demon.attack_landed.emit(null)
	(demon.get_node(^"Repellable") as Repellable).repelled.emit(demon.global_position)
	var played: bool = randi() == after
	await _clear(demon)
	return report(made and played and latched, "Global random numbers: making a demon takes one "
			+ "%s, its sounds none %s (the latch played %s)" % [made, played, latched])


## The demon scene fills Take Off Sound and Land Sound; with Play Beeps a take-off plays the first
## and a landing the second, each at the demon's voice moved by at most Pitch Variation.
func _the_take_off_and_the_landing_play_their_sounds() -> bool:
	var demon: Demon = await _make_demon()
	var sounds: DemonSounds = _sounds_of(demon)
	sounds.play_beeps = true
	var filled: bool = sounds.take_off_sound != null and sounds.land_sound != null
	demon.took_off.emit()
	var take_off_plays: bool = sounds.cue.stream == sounds.take_off_sound and sounds.cue.playing \
			and _within_voice(sounds, sounds.cue.pitch_scale)
	await physics_frame
	demon.landed.emit()
	var land_plays: bool = sounds.cue.stream == sounds.land_sound and sounds.cue.playing \
			and _within_voice(sounds, sounds.cue.pitch_scale)
	await _clear(demon)
	return report(filled and take_off_plays and land_plays,
			"Leap beeps: both in the scene %s, take-off plays at its voice %s, landing %s"
			% [filled, take_off_plays, land_plays])


## BARKING_DEMONS demons taking off on one physics step start Max Leap Sounds Per Step jumps
## between them, and ALERTED_DEMONS more alerted on that same step all start their alerts.
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
			"Take-offs on one step: %d of %d jump (limit %d), %d of %d alerted play after them"
			% [leaps, BARKING_DEMONS, leap_limit, alerts, ALERTED_DEMONS])


## BARKING_DEMONS demons whose attacks land on one physics step start Max Attack Sounds Per Step
## between them, BARKING_DEMONS more hit by the crucifix on it Max Hit Sounds Per Step, and
## ALERTED_DEMONS more alerted on that same step all start their alerts.
func _attacks_and_hits_count_apart_and_never_silence_an_alert() -> bool:
	var attacking: Array[Demon] = []
	var hit: Array[Demon] = []
	var alerted: Array[Demon] = []
	for _index: int in BARKING_DEMONS:
		attacking.append(await _make_demon())
		hit.append(await _make_demon())
	for _index: int in ALERTED_DEMONS:
		alerted.append(await _make_demon())
	var attack_limit: int = _sounds_of(attacking[0]).max_attack_sounds_per_step
	var hit_limit: int = _sounds_of(attacking[0]).max_hit_sounds_per_step
	for demon: Demon in attacking:
		demon.attack_landed.emit(null)
	for demon: Demon in hit:
		(demon.get_node(^"Repellable") as Repellable).repelled.emit(demon.global_position)
	for demon: Demon in alerted:
		demon.state_changed.emit(Demon.State.IDLE, Demon.State.ALERT)
	var attacks: int = attacking.filter(_is_playing).size()
	var hits: int = hit.filter(_is_playing).size()
	var alerts: int = alerted.filter(_is_playing).size()
	for demon: Demon in attacking + hit + alerted:
		await _clear(demon)
	return report(attacks == attack_limit and hits == hit_limit and alerts == ALERTED_DEMONS,
			"On one step: %d of %d attacks play (limit %d), %d of %d crucifix hits (limit %d), "
			% [attacks, BARKING_DEMONS, attack_limit, hits, BARKING_DEMONS, hit_limit]
			+ "%d of %d alerted play after them"
			% [alerts, ALERTED_DEMONS])


## Whether any of the demon's sounds plays: a beep or one of the dog's own.
func _is_playing(demon: Demon) -> bool:
	var sounds: DemonSounds = _sounds_of(demon)
	if sounds.cue.playing:
		return true
	for emitter: SoundEmitter in _dog_sounds(sounds):
		if emitter.one_shot_player.playing:
			return true
	return false


func _dog_sounds(sounds: DemonSounds) -> Array[SoundEmitter]:
	return [sounds.alert, sounds.latch, sounds.jump, sounds.attack, sounds.crucifix_hit]


## The files a stream plays: its own, or those of a randomizer.
func _files_of(stream: AudioStream) -> Array[String]:
	var files: Array[String] = []
	var randomizer := stream as AudioStreamRandomizer
	if randomizer != null:
		for index: int in randomizer.streams_count:
			var each: AudioStream = randomizer.get_stream(index)
			files.append(each.resource_path.get_file() if each != null else "<empty>")
	elif stream != null:
		files.append(stream.resource_path.get_file())
	return files


## Whether pitch is within Pitch Variation of the demon's voice.
func _within_voice(sounds: DemonSounds, pitch: float) -> bool:
	return absf(pitch / sounds.get_voice() - 1.0) <= sounds.pitch_variation + PITCH_TOLERANCE


## Whether the crucifix hit's pitch is within Pitch Variation of the demon's voice, moved by up to
## the randomizer's Random Pitch, spread, either way.
func _within_hit_pitch(sounds: DemonSounds, spread: float) -> bool:
	var moved: float = sounds.crucifix_hit.one_shot_player.pitch_scale / sounds.get_voice()
	var low: float = (1.0 - sounds.pitch_variation) / spread - PITCH_TOLERANCE
	var high: float = (1.0 + sounds.pitch_variation) * spread + PITCH_TOLERANCE
	return moved >= low and moved <= high


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
