class_name SoundEmitter
extends Node2D

## The sound of a thing in the world, such as a fire or a demon dog, heard by how far it is from
## the centre of the screen, where Godot's 2D audio listens: a steady Loop, and One Shots on top of
## it at random moments, about one every Interval, so the loop never sounds like one. The loop plays
## only while the centre of the screen is within Hearing Distance, the only place where Godot's
## attenuation gives it any volume, and stops a little past it, so a level can hold many and only
## the near ones play.
## Each one-shot comes from a little to one side of the thing, up to Pan Spread of the stereo field
## (a balance from 50/50 to 40/60 at 0.1), and as loud as it would be from the thing itself.
## One Shot Played tells which side, so something seen, such as a fire's embers (RisingEmbers),
## can come from there too. A thing that moves, such as a dog, carries the emitter and its players
## with it.
## It counts in real time, as AmbienceBed does, because the audio keeps playing through the hitstop
## of a death, and in its frame, so the pause holds it, and its players with it.

## A one-shot started, heard from side of the thing: -1 at the left edge of Pan Spread, 1 at the
## right one, 0 from the thing itself. at is where the thing was.
signal one_shot_played(at: Vector2, side: float)

## The most real time one frame counts for, in s: on the frame the game's time scale changes, the
## frame's delta still has the old scale (see AmbienceBed).
const MAX_STEP: float = 0.1
## The shortest wait between two one-shots, in s, however far Deviation reaches.
const MIN_GAP: float = 0.2
## The most a one-shot's volume is raised, in dB, to sound as loud from its side as from the thing:
## a side further from the centre of the screen than that is too near the edge of hearing, and the
## one-shot comes from the other side, or from the thing. The lift follows the camera while the
## one-shot plays, so it never grows past what the thing would give.
const MAX_LIFT_DB: float = 18.0
## A one-shot's volume once its side is out of hearing, in dB: silent.
const SILENT_DB: float = -80.0
## Godot's 2D pan: a sound one screen width to the side of the centre moves this share of the
## stereo field per unit of panning strength (the player's times the project's), as in
## AudioStreamPlayer2D's own code (measured on 19/11: a sound 400 px right of the centre, at
## strength 1 and the project's 0.5, plays 1.232 times louder right than left, as it says).
const PAN_PER_SCREEN: float = 0.5
## The project setting that scales every 2D player's panning, and Godot's own default for it.
const PANNING_SETTING: String = "audio/general/2d_panning_strength"
const DEFAULT_PANNING: float = 0.5

## The steady sound: a seamless loop. It loops here even if its import does not (a copy of it is
## set to loop, so the file and its import stay as they are). It replaces Loop Player's stream.
@export var loop: AudioStream
## The sounds to play over the loop. An AudioStreamRandomizer with Playback Mode Random (Avoid
## Repetitions) picks a different one each time and varies its pitch and its volume, with Random
## Pitch and Random Volume Offset dB. It replaces One Shot Player's stream.
@export var one_shots: AudioStream
## Play the loop and the one-shots. Their bus is set in them; their volume, Max Distance and
## Attenuation are the emitter's. A one-shot moves One Shot Player to its side, so a Max Polyphony
## of 2 lets the last one's tail go on, from the new side.
@export var loop_player: AudioStreamPlayer2D
@export var one_shot_player: AudioStreamPlayer2D
## Whether it sounds at all: off, it stops, as a fire put out or a dog gone.
@export var enabled: bool = true

@export_group("Distance")
## How far from the centre of the screen it is heard, in px of the world: both players' Max
## Distance. Beyond it Godot gives it no volume, and the loop stops.
@export_range(50.0, 5000.0, 10.0, "suffix:px") var hearing_distance: float = 1500.0:
	set(value):
		hearing_distance = value
		_apply_distance()
## How the volume falls with distance, both players' Attenuation: (1 - distance / Hearing
## Distance) to this power. 1 falls in a straight line; above 1, it falls fast near the thing and
## lingers far off.
@export_range(0.1, 8.0, 0.05) var attenuation: float = 1.5:
	set(value):
		attenuation = value
		_apply_distance()
## How far past Hearing Distance the loop goes on before it stops, in px, so walking along the edge
## does not start and stop it every frame.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var hearing_margin: float = 100.0

@export_group("Volume")
## The loop's volume and the one-shots', as heard right at the thing.
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var loop_volume_db: float = 0.0:
	set(value):
		loop_volume_db = value
		if loop_player != null:
			loop_player.volume_db = value
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var one_shot_volume_db: float = 0.0

@export_group("One Shots")
## The mean wait from one one-shot to the next, in s, while it is heard.
@export_range(0.5, 60.0, 0.1, "suffix:s") var interval: float = 4.0
## How far each wait strays from Interval, at most, either way, in s: picked at random between.
@export_range(0.0, 30.0, 0.1, "suffix:s") var deviation: float = 1.5
## How far to either side of the thing a one-shot comes from, as a share of the stereo field: 0.1
## moves a balance of 50/50 up to 40/60.
@export_range(0.0, 0.5, 0.01) var pan_spread: float = 0.1

@export_group("Loop")
## The loop starts at a random point each time it is heard, so two things never play in step.
@export var random_start: bool = true

## Whether the centre of the screen is within hearing, so the loop plays and the one-shots come.
var _hearing: bool = false
## Real seconds until the next one-shot.
var _time_left: float = 0.0
## The project's 2D panning strength, read once.
var _project_panning: float = DEFAULT_PANNING


func _ready() -> void:
	_project_panning = float(ProjectSettings.get_setting(PANNING_SETTING, DEFAULT_PANNING))
	if loop_player != null:
		loop_player.stream = _looping(loop)
		loop_player.volume_db = loop_volume_db
	if one_shot_player != null:
		one_shot_player.stream = one_shots
	_apply_distance()
	if loop == null and one_shots == null:
		push_warning("SoundEmitter %s: no Loop or One Shots to play." % name)


func _process(delta: float) -> void:
	var step: float = minf(delta / Engine.time_scale, MAX_STEP) if Engine.time_scale > 0.0 else 0.0
	var distance: float = global_position.distance_to(get_listener_position())
	if not _hearing:
		if enabled and distance <= hearing_distance:
			_begin()
		return
	if not enabled or distance > hearing_distance + hearing_margin:
		_end()
		return
	_time_left -= step
	if _time_left <= 0.0:
		_time_left = _next_gap()
		if one_shot_player != null and one_shots != null:
			play_one_shot(randf_range(-1.0, 1.0))
	elif one_shot_player != null and one_shot_player.playing:
		_lift_one_shot()


## Plays one one-shot now, from side of the thing (-1 at the left edge of Pan Spread, 1 at the
## right one), as loud as from the thing. A side too near the edge of hearing gives way to the
## other side, or to the thing itself.
func play_one_shot(side: float) -> void:
	if one_shot_player == null or one_shots == null:
		return
	var listener: Vector2 = get_listener_position()
	var chosen: float = 0.0
	var place: Vector2 = global_position
	for way: float in [side, -side]:
		var spot: Vector2 = global_position + Vector2(_side_offset(way), 0.0)
		if _lift_db(spot, listener) <= MAX_LIFT_DB:
			chosen = way
			place = spot
			break
	one_shot_player.global_position = place
	_lift_one_shot()
	one_shot_player.play()
	one_shot_played.emit(global_position, chosen)


## Whether it is heard now: the loop plays and the one-shots come.
func is_hearing() -> bool:
	return _hearing


## Where Godot's 2D audio listens from, in the world: the current AudioListener2D, or else the
## centre of the screen.
func get_listener_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	var listener: AudioListener2D = viewport.get_audio_listener_2d()
	if listener != null:
		return listener.global_position
	return _canvas_transform(viewport).affine_inverse() * (viewport.get_visible_rect().size * 0.5)


func _begin() -> void:
	_hearing = true
	_time_left = randf() * _next_gap()
	if loop_player != null and loop_player.stream != null:
		var from: float = 0.0
		if random_start:
			from = randf() * loop_player.stream.get_length()
		loop_player.play(from)


func _end() -> void:
	_hearing = false
	if loop_player != null:
		loop_player.stop()


func _next_gap() -> float:
	return maxf(interval + randf_range(-deviation, deviation), MIN_GAP)


## Sets the one-shot's volume so that, from where its player is, it sounds as loud as from the
## thing: One Shot Volume dB, lifted by what the distance takes away, up to Max Lift dB; silent
## once its side is out of hearing.
func _lift_one_shot() -> void:
	var lift: float = _lift_db(one_shot_player.global_position, get_listener_position())
	one_shot_player.volume_db = (one_shot_volume_db + minf(lift, MAX_LIFT_DB) if lift < INF
			else SILENT_DB)


## How much louder a sound at spot must play to sound as loud as from the thing, heard from
## listener, in dB: infinite if spot is out of hearing, or the thing is.
func _lift_db(spot: Vector2, listener: Vector2) -> float:
	var from_thing: float = _gain(global_position.distance_to(listener))
	var there: float = _gain(spot.distance_to(listener))
	if from_thing <= 0.0 or there <= 0.0:
		return 0.0 if spot.is_equal_approx(global_position) else INF
	return linear_to_db(from_thing / there)


## Godot's attenuation at distance px from where it listens, before the player's volume.
func _gain(distance: float) -> float:
	return pow(maxf(1.0 - distance / hearing_distance, 0.0), attenuation)


## How far to the side, in px of the world, a one-shot plays to move side of Pan Spread through the
## stereo field: Godot pans by where a sound is on the screen, so it depends on the camera's zoom.
func _side_offset(side: float) -> float:
	var viewport: Viewport = get_viewport()
	var strength: float = one_shot_player.panning_strength * _project_panning * PAN_PER_SCREEN
	var zoom: float = _canvas_transform(viewport).get_scale().x
	if strength <= 0.0 or zoom <= 0.0:
		return 0.0
	return side * pan_spread / strength * viewport.get_visible_rect().size.x / zoom


## From the world to the screen, as Godot's 2D audio takes it.
func _canvas_transform(viewport: Viewport) -> Transform2D:
	return viewport.get_global_canvas_transform() * viewport.get_canvas_transform()


func _apply_distance() -> void:
	for player: AudioStreamPlayer2D in [loop_player, one_shot_player]:
		if player != null:
			player.max_distance = hearing_distance
			player.attenuation = attenuation


## The loop, set to loop: itself if it already does, a copy set to loop if it is an Ogg Vorbis, an
## MP3 or a WAV file that does not, and itself otherwise, such as a randomizer.
static func _looping(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamOggVorbis and not (stream as AudioStreamOggVorbis).loop:
		var ogg := stream.duplicate() as AudioStreamOggVorbis
		ogg.loop = true
		return ogg
	if stream is AudioStreamMP3 and not (stream as AudioStreamMP3).loop:
		var mp3 := stream.duplicate() as AudioStreamMP3
		mp3.loop = true
		return mp3
	if stream is AudioStreamWAV and (stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED:
		var wav := stream.duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
		return wav
	return stream
