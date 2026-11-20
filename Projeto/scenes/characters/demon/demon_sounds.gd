class_name DemonSounds
extends Node2D

## The demon's sounds (ADR 0040). It only listens to the demon's signals, as CrucifixSounds does the
## crucifix's, so the demon's script never touches the audio. It is a Node2D so that its sounds
## follow the demon. The dog's own sounds are SoundEmitters, each heard by how far the dog is from
## the man, and from its side of the screen, as a fire is, and each with its own player, so that a
## long one is never cut off by the next: Alert as it notices the man, Latch once the alert's sound
## is over, Jump as it leaves its floor, Attack as its bite or blow lands on him, and Crucifix Hit as
## the man's crucifix throws it off. Each is turned off with its own Enabled and tuned in itself:
## its volume, its distances and falloff, and its player's bus; a sound with two files or more picks
## one each time through an AudioStreamRandomizer. The placeholder beeps that came before them stay
## in their slots and play on Cue only with Play Beeps, and Use Old Alert brings the old beep back
## for the alert. An empty slot plays nothing. Each sound has a picture that goes with it, for a man
## who does not hear: DemonMark's for the alert and the search, the placeholder's hop for the bark,
## and its stretch and squash for the take-off and the landing (ADR 0042).

## What a sound tells, for the limits on how many start on one physics step.
enum Kind { NOTICE, BARK, LEAP, ATTACK, HIT }

## The most real time one frame counts for, in s, as in SoundEmitter.
const MAX_STEP: float = 0.1
## The states in which a dog is no longer after the man, or has been thrown off, so the latch it
## was waiting to play is not heard.
const STATES_THAT_DROP_THE_LATCH: Array[Demon.State] = [Demon.State.IDLE, Demon.State.PATROL,
		Demon.State.RETURN, Demon.State.SEARCH, Demon.State.THROWN, Demon.State.REPELLED,
		Demon.State.STUNNED]

## The demon whose sounds these are.
@export var demon: Demon
## How far this demon's voice is from the normal pitch, either way, picked once for each demon so
## that two of them never sound the same: 0.08 is up to 8% up or down.
@export_range(0.0, 0.5, 0.005) var voice_spread: float = 0.08
## How far each sound's pitch can move from the demon's voice, either way, each time it plays.
@export_range(0.0, 0.5, 0.005) var pitch_variation: float = 0.02
## The most alert and search sounds all the demons together start on one physics step; the others
## play none. A pack that notices the man at once is heard as one, and its marks still show which
## ones saw him; starting 50 sound players on one step cost about 2 ms on the steps after it (ADR
## 0040). Counted in physics steps, not in frames drawn: at 120 physics steps a second, or with the
## game slow enough to run two steps a frame, one frame drawn can start twice as many.
@export_range(1, 50, 1) var max_notice_sounds_per_step: int = 3
## The most barks all the demons together start on one physics step, counted apart from the alert
## and search sounds, so that barks, which only tell the man is out of reach, never silence a demon
## that has just noticed him.
@export_range(0, 50, 1) var max_barks_per_step: int = 2
## The most jumps, take-offs and landings all the demons together start on one physics step,
## counted apart from the others, so that a pack leaping down together is heard as one and never
## silences a demon that has just noticed the man.
@export_range(0, 50, 1) var max_leap_sounds_per_step: int = 2
## The most attack sounds all the demons together start on one physics step, counted apart, so a
## pack biting the man at once is heard as one.
@export_range(0, 50, 1) var max_attack_sounds_per_step: int = 2
## The most crucifix hits all the demons together start on one physics step, counted apart, so a
## pack thrown off by one swing is heard as one.
@export_range(0, 50, 1) var max_hit_sounds_per_step: int = 2

@export_group("Dog")
## The dog noticing the man, with the "!", unless Use Old Alert.
@export var alert: SoundEmitter
## Once the alert's sound is over, one of the latches, if the dog is still after the man then: not
## once it has lost him or been thrown off.
@export var latch: SoundEmitter
## How long after the alert's sound ends the latch starts, in s; below 0, over the alert's tail.
@export_range(-2.0, 3.0, 0.05, "suffix:s") var latch_gap: float = -1.5
## The dog leaving its floor: up a step, down off its end and, with Jump On Lunge, in a lunge at
## the man.
@export var jump: SoundEmitter
@export var jump_on_lunge: bool = true
## The dog's bite or blow landing on the man, one that holds him too.
@export var attack: SoundEmitter
## The man's crucifix hitting the dog and throwing it off.
@export var crucifix_hit: SoundEmitter

@export_group("Beeps")
## Whether the placeholder beeps play, on Cue: the search, the bark, the take-off and the landing.
## Off since the dog's own sounds came; their slots stay filled, to bring them back.
@export var play_beeps: bool = false
## Whether the alert plays the old beep, Alert Sound on Cue, instead of the dog's own alert (Alert),
## whatever Play Beeps says.
@export var use_old_alert: bool = false
## Plays the beeps. Its own stream is replaced by the beep of each moment.
@export var cue: AudioStreamPlayer2D
## The demon noticing the man, with the "!".
@export var alert_sound: AudioStream
## The demon starting to search for the man, with the "?".
@export var search_sound: AudioStream
## The demon barking at a man out of its reach (ADR 0039).
@export var bark_sound: AudioStream
## The demon leaving its floor, up a step or down off its end (ADR 0042).
@export var take_off_sound: AudioStream
## The demon landing from a take-off.
@export var land_sound: AudioStream

## Shared by every demon: the physics step the last sound started on, and how many sounds of each
## Kind started on it.
static var _sound_step: int = -1
static var _started_on_step: Dictionary[Kind, int] = {}

## This demon's pitch, picked in _ready.
var _voice: float = 1.0
## Its own, so the sounds never take numbers from the global one, from which each demon seeds its
## own: a sound must never change what a demon does, nor a test with a fixed seed.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Real seconds until the latch, while one waits to play.
var _latch_left: float = 0.0


func _ready() -> void:
	assert(demon != null, "DemonSounds: assign the Demon to Demon.")
	assert(cue != null, "DemonSounds: assign an AudioStreamPlayer2D to Cue.")
	_rng.randomize()
	_voice = 1.0 + _rng.randf_range(-voice_spread, voice_spread)
	set_physics_process(false)
	demon.state_changed.connect(_on_demon_state_changed)
	demon.barked.connect(_on_demon_barked)
	demon.took_off.connect(_on_demon_took_off)
	demon.landed.connect(_on_demon_landed)
	demon.attack_landed.connect(_on_demon_attack_landed)
	demon.repelled.connect(_on_demon_repelled)


# Only while a latch waits to play. In real time, as the emitters count, since the audio plays on
# through the hitstop of a death; in the physics frame, so the pause holds it.
func _physics_process(delta: float) -> void:
	var step: float = minf(delta / Engine.time_scale, MAX_STEP) if Engine.time_scale > 0.0 else 0.0
	_latch_left -= step
	if _latch_left <= 0.0:
		set_physics_process(false)
		if _can_play(latch):
			_play_on(latch)


## The pitch this demon plays its next sound at.
func get_voice() -> float:
	return _voice


## Whether a latch waits to play, after the alert.
func is_latch_waiting() -> bool:
	return is_physics_processing()


## Starts a sound of kind: beep on Cue and the one-shot of emitter, either of them null for none,
## counted as one with the sounds of its kind. Neither starts if as many of its kind as its limit
## already started on this physics step, or if neither has anything to play. Returns whether it
## started.
func _start(kind: Kind, beep: AudioStream, emitter: SoundEmitter) -> bool:
	var beeps: bool = beep != null
	var own: bool = _can_play(emitter)
	if not (beeps or own) or not _may_start(kind):
		return false
	if beeps:
		cue.stream = beep
		cue.pitch_scale = _next_pitch()
		cue.play()
	if own:
		_play_on(emitter)
	return true


## Whether one more sound of kind may start on this physics step, counting it if so.
func _may_start(kind: Kind) -> bool:
	var step: int = Engine.get_physics_frames()
	if step != _sound_step:
		_sound_step = step
		_started_on_step.clear()
	var started: int = _started_on_step.get(kind, 0)
	if started >= _limit(kind):
		return false
	_started_on_step[kind] = started + 1
	return true


func _limit(kind: Kind) -> int:
	match kind:
		Kind.NOTICE:
			return max_notice_sounds_per_step
		Kind.BARK:
			return max_barks_per_step
		Kind.LEAP:
			return max_leap_sounds_per_step
		Kind.ATTACK:
			return max_attack_sounds_per_step
		_:
			return max_hit_sounds_per_step


## Whether emitter is there, on and has something to play.
func _can_play(emitter: SoundEmitter) -> bool:
	return emitter != null and emitter.enabled and emitter.one_shots != null \
			and emitter.one_shot_player != null


## Plays emitter's one-shot from the dog itself, at the demon's voice moved a little at random. Of
## an AudioStreamRandomizer, it picks one of its streams by their weights and moves the pitch by its
## Random Pitch, with this demon's own random numbers, so no sound takes from the global ones (the
## randomizer would); its Random Volume Offset is not used. A new pick cuts the last one short.
func _play_on(emitter: SoundEmitter) -> void:
	var sound: AudioStream = emitter.one_shots
	var pitch: float = _next_pitch()
	var randomizer := sound as AudioStreamRandomizer
	if randomizer != null:
		sound = _pick(randomizer)
		var spread: float = maxf(randomizer.random_pitch, 1.0)
		pitch *= _rng.randf_range(1.0 / spread, spread)
	if sound == null:
		return
	var player: AudioStreamPlayer2D = emitter.one_shot_player
	if player.stream != sound:
		player.stream = sound
	player.pitch_scale = pitch
	emitter.play_one_shot(0.0)


## One of randomizer's streams, picked by their weights with this demon's random numbers.
func _pick(randomizer: AudioStreamRandomizer) -> AudioStream:
	var total: float = 0.0
	for index: int in randomizer.streams_count:
		total += maxf(randomizer.get_stream_probability_weight(index), 0.0)
	var at: float = _rng.randf() * total
	for index: int in randomizer.streams_count:
		var weight: float = maxf(randomizer.get_stream_probability_weight(index), 0.0)
		if at < weight:
			return randomizer.get_stream(index)
		at -= weight
	return randomizer.get_stream(randomizer.streams_count - 1) if randomizer.streams_count > 0 else null


func _next_pitch() -> float:
	return _voice * (1.0 + _rng.randf_range(-pitch_variation, pitch_variation))


## sound, with Play Beeps; none without.
func _beep(sound: AudioStream) -> AudioStream:
	return sound if play_beeps else null


## The alert, the dog's own or with Use Old Alert the old beep, and then the latch once its sound is
## over, Latch Gap later.
func _on_alert() -> void:
	var old: bool = use_old_alert
	if not _start(Kind.NOTICE, alert_sound if old else null, null if old else alert):
		return
	var player: AudioStreamPlayer2D = cue if old else alert.one_shot_player
	if _can_play(latch):
		_latch_left = player.stream.get_length() / maxf(player.pitch_scale, 0.01) + latch_gap
		set_physics_process(true)


func _on_demon_state_changed(_previous: Demon.State, current: Demon.State) -> void:
	if current in STATES_THAT_DROP_THE_LATCH:
		set_physics_process(false)
	match current:
		Demon.State.ALERT:
			_on_alert()
		Demon.State.SEARCH:
			_start(Kind.NOTICE, _beep(search_sound), null)
		Demon.State.LUNGE:
			if jump_on_lunge:
				_start(Kind.LEAP, null, jump)


func _on_demon_barked(_hops: bool) -> void:
	_start(Kind.BARK, _beep(bark_sound), null)


func _on_demon_took_off() -> void:
	_start(Kind.LEAP, _beep(take_off_sound), jump)


func _on_demon_landed() -> void:
	_start(Kind.LEAP, _beep(land_sound), null)


func _on_demon_attack_landed(_attack: DemonAttack) -> void:
	_start(Kind.ATTACK, null, attack)


func _on_demon_repelled() -> void:
	_start(Kind.HIT, null, crucifix_hit)
