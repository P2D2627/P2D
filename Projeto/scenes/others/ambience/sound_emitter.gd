class_name SoundEmitter
extends Node2D

## The sound of a thing in the world, such as a fire or a demon dog, heard by how far it is from the
## ear: the man of the level it is in, so walking up to the thing makes it louder and walking away
## makes it quieter wherever the camera is, held at a room's edge or still inside its window; with
## no man, as in a scene of its own, the centre of the screen. Ear, if set, hears it instead.
## A steady Loop, and One Shots on top of it at random moments, about one every Interval, so the
## loop never sounds like one. It is as loud as at the thing within Near Distance of the ear, then
## falls as Falloff says, to silence at Hearing Distance: the emitter sets its players' volume each
## frame, and Godot's own falloff is off. Left and right stay Godot's, by where the thing shows on
## the screen. The loop plays only within Hearing Distance and stops a little past it, so a level can
## hold many and only the near ones play. A loop whose file ends in a tail, such as reverb, plays the
## tail out under its next pass (Loop End).
## Each one-shot comes from a little to one side of the thing, up to Pan Spread of the stereo field
## (a balance from 50/50 to 40/60 at 0.1), as loud as the loop: the side only moves it in the
## stereo. One Shot Played tells which side, so something seen, such as a fire's embers
## (RisingEmbers), can come from there too. A thing that moves, such as a dog, carries the emitter
## and its players with it. With Plays On Its Own off, as for a dog's voice, it plays a one-shot
## only when told (play_one_shot), and with no Loop it sleeps between them, so a level's many dogs
## cost nothing while they are quiet.
## It counts in real time, as AmbienceBed does, because the audio keeps playing through the hitstop
## of a death, and in its physics frame, so the pause holds it, and its players with it.

## A one-shot started, heard from side of the thing: -1 at the left edge of Pan Spread, 1 at the
## right one, 0 from the thing itself. at is where the thing was.
signal one_shot_played(at: Vector2, side: float)

## The most real time one frame counts for, in s: on the frame the game's time scale changes, the
## frame's delta still has the old scale (see AmbienceBed).
const MAX_STEP: float = 0.1
## The shortest wait between two one-shots, in s, however far Deviation reaches.
const MIN_GAP: float = 0.2
## Physics frames a one-shot told to play is followed for before its player has to say it plays: a
## 2D player starts its voice in its own physics step, after the emitter's.
const START_FRAMES: int = 2
## A player's volume once the thing is out of hearing, in dB: silent.
const SILENT_DB: float = -80.0
## Godot's own falloff, off: an Attenuation of 0 makes its curve flat, and a Max Distance this far, in
## px, is past anywhere its players play from, so only the emitter's volume makes them quieter.
const GODOT_ATTENUATION: float = 0.0
const GODOT_MAX_DISTANCE: float = 1000000.0
## The falloff without one of its own, from Near Distance (0) to Hearing Distance (1): half as loud
## (-6 dB) a fifth of the way, a quarter (-12 dB) a little short of halfway, a tenth (-20 dB) at
## three quarters, and silent at the end, in straight lines between. As loudness falls with distance
## in the open, about 6 dB each time it doubles, but silent at the end of hearing.
const DEFAULT_FALLOFF: PackedVector2Array = [Vector2(0.0, 1.0), Vector2(0.2, 0.5),
		Vector2(0.45, 0.25), Vector2(0.75, 0.1), Vector2(1.0, 0.0)]
## Godot's 2D pan: a sound one screen width to the side of the centre moves this share of the
## stereo field per unit of panning strength (the player's times the project's), as in
## AudioStreamPlayer2D's own code (measured on 19/11: a sound 400 px right of the centre, at
## strength 1 and the project's 0.5, plays 1.232 times louder right than left, as it says).
const PAN_PER_SCREEN: float = 0.5
## The project setting that scales every 2D player's panning, and Godot's own default for it.
const PANNING_SETTING: String = "audio/general/2d_panning_strength"
const DEFAULT_PANNING: float = 0.5

## The steady sound. It loops here even if its import does not (a copy of it is set to loop, so the
## file and its import stay as they are); with Loop End, each pass plays its tail out under the
## next. It replaces Loop Player's stream.
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
## What hears it, if not the man of the level it is in.
@export var ear: Node2D

@export_group("Distance")
## Within this distance of the ear, in px of the world, it is as loud as at the thing.
@export_range(0.0, 2000.0, 5.0, "suffix:px") var near_distance: float = 150.0
## How far from the ear it is heard, in px of the world: silent there, and the loop stops a little
## past it.
@export_range(50.0, 5000.0, 10.0, "suffix:px") var hearing_distance: float = 1000.0
## How loud it is, from 1 at Near Distance (x 0) to Hearing Distance (x 1), as a share of its volume
## at the thing (y; 0.5 is 6 dB quieter, 0.1 is 20 dB quieter). Empty, or with fewer than two
## points: Default Falloff.
@export var falloff: Curve
## How far past Hearing Distance the loop goes on before it stops, in px, so walking along the edge
## does not start and stop it every frame.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var hearing_margin: float = 100.0

@export_group("Volume")
## The loop's volume and the one-shots', as heard within Near Distance.
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var loop_volume_db: float = 0.0
@export_range(-60.0, 12.0, 0.5, "suffix:dB") var one_shot_volume_db: float = 0.0

@export_group("One Shots")
## Whether it plays its one-shots by itself, about one every Interval, while it is heard. Off, as for
## a dog's voice, it plays one only when told (play_one_shot); with no Loop either, it sleeps
## between them, its physics frame off.
@export var plays_on_its_own: bool = true
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
## Where the loop starts in its file, in s.
@export_range(0.0, 600.0, 0.001, "suffix:s") var loop_start: float = 0.0
## Where the loop ends in its file, in s, when what comes after it is a tail, such as the reverb of
## its last moment: each pass plays on past Loop End, through its tail, while the next starts at
## Loop Start over it, so the loop neither cuts the tail off nor goes quiet in it. 0: the whole file
## loops, one pass straight after the other.
@export_range(0.0, 600.0, 0.001, "suffix:s") var loop_end: float = 0.0

## Default Falloff as a curve, made once for every emitter.
static var _default_falloff: Curve

## Whether the ear is within hearing, so the loop plays and the one-shots come.
var _hearing: bool = false
## Real seconds until the next one-shot.
var _time_left: float = 0.0
## The project's 2D panning strength, read once.
var _project_panning: float = DEFAULT_PANNING
## The man of the level it is in, found once; none outside a level.
var _man: Node2D
## Physics frames left of START_FRAMES since a one-shot was told to play.
var _start_frames_left: int = 0


func _ready() -> void:
	_project_panning = float(ProjectSettings.get_setting(PANNING_SETTING, DEFAULT_PANNING))
	for player: AudioStreamPlayer2D in [loop_player, one_shot_player]:
		if player != null:
			player.attenuation = GODOT_ATTENUATION
			player.max_distance = GODOT_MAX_DISTANCE
			player.volume_db = SILENT_DB
	if loop_player != null:
		if _has_tail():
			loop_player.stream = _played_once(loop)
			loop_player.max_polyphony = maxi(loop_player.max_polyphony, _passes_at_once())
		else:
			loop_player.stream = _looping(loop)
	if one_shot_player != null:
		one_shot_player.stream = one_shots
	_man = _find_man()
	if loop == null and one_shots == null:
		push_warning("SoundEmitter %s: no Loop or One Shots to play." % name)
	if _sleeps_between():
		set_physics_process(false)


# In the physics step, as the players start the voices they are asked for in their own, after this
# one: the mix then takes up a new pass of the loop and the newest one's next round together.
func _physics_process(delta: float) -> void:
	if _sleeps_between():
		_follow_one_shot()
		return
	var step: float = minf(delta / Engine.time_scale, MAX_STEP) if Engine.time_scale > 0.0 else 0.0
	var distance: float = global_position.distance_to(get_ear_position())
	if not _hearing:
		if enabled and distance <= hearing_distance:
			_begin(distance)
		return
	if not enabled or distance > hearing_distance + hearing_margin:
		_end()
		return
	_set_volumes(distance)
	if loop_player != null and _has_tail():
		_next_pass()
	_time_left -= step
	if _time_left <= 0.0:
		_time_left = _next_gap()
		if plays_on_its_own and one_shot_player != null and one_shots != null:
			play_one_shot(randf_range(-1.0, 1.0))


## Plays one one-shot now, from side of the thing (-1 at the left edge of Pan Spread, 1 at the right
## one), as loud as the loop. Disabled, it plays none. Sleeping between one-shots, it wakes to keep
## this one's volume to the ear while it plays.
func play_one_shot(side: float) -> void:
	if not enabled or one_shot_player == null or one_shots == null:
		return
	var way: float = clampf(side, -1.0, 1.0)
	one_shot_player.global_position = global_position + Vector2(_side_offset(way), 0.0)
	_set_volumes(global_position.distance_to(get_ear_position()))
	one_shot_player.play()
	one_shot_played.emit(global_position, way)
	if _sleeps_between():
		_start_frames_left = START_FRAMES
		set_physics_process(true)


## Whether it is heard now: the loop plays and the one-shots come.
func is_hearing() -> bool:
	return _hearing


## Where it is heard from, in the world: Ear, the man of the level it is in, or else the centre of
## the screen.
func get_ear_position() -> Vector2:
	if ear != null and is_instance_valid(ear):
		return ear.global_position
	if _man != null and is_instance_valid(_man):
		return _man.global_position
	return get_listener_position()


## How loud it is at distance px from the ear, as a share of its volume at the thing: 1 within Near
## Distance, then as Falloff says, 0 from Hearing Distance on.
func get_gain(distance: float) -> float:
	if distance <= near_distance:
		return 1.0
	if distance >= hearing_distance:
		return 0.0
	var way: float = (distance - near_distance) / (hearing_distance - near_distance)
	return clampf(_falloff().sample(way), 0.0, 1.0)


## Where Godot's 2D audio listens from, in the world, which pans by it: the current
## AudioListener2D, or else the centre of the screen.
func get_listener_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	var listener: AudioListener2D = viewport.get_audio_listener_2d()
	if listener != null:
		return listener.global_position
	return _canvas_transform(viewport).affine_inverse() * (viewport.get_visible_rect().size * 0.5)


func _begin(distance: float) -> void:
	_hearing = true
	_time_left = randf() * _next_gap()
	_set_volumes(distance)
	if loop_player != null and loop_player.stream != null:
		var from: float = loop_start if _has_tail() else 0.0
		if random_start:
			from = (randf_range(loop_start, _loop_end()) if _has_tail()
					else randf() * loop_player.stream.get_length())
		loop_player.play(from)


func _end() -> void:
	_hearing = false
	if loop_player != null:
		loop_player.stop()


## Both players' volume for the ear at distance: their own, lowered by the falloff.
func _set_volumes(distance: float) -> void:
	var gain: float = get_gain(distance)
	var lowered: float = maxf(linear_to_db(gain), SILENT_DB) if gain > 0.0 else SILENT_DB
	if loop_player != null:
		loop_player.volume_db = maxf(loop_volume_db + lowered, SILENT_DB)
	if one_shot_player != null:
		one_shot_player.volume_db = maxf(one_shot_volume_db + lowered, SILENT_DB)


func _next_gap() -> float:
	return maxf(interval + randf_range(-deviation, deviation), MIN_GAP)


## Whether it has nothing to do between one-shots: no Loop, and none it plays by itself.
func _sleeps_between() -> bool:
	return loop == null and not plays_on_its_own


## While a one-shot it was told to play goes on, keeps its volume to the ear as the thing and the ear
## move; once it is over, sleeps again.
func _follow_one_shot() -> void:
	if _start_frames_left > 0:
		_start_frames_left -= 1
	elif one_shot_player == null or not one_shot_player.playing:
		set_physics_process(false)
		return
	_set_volumes(global_position.distance_to(get_ear_position()))


## Starts the loop's next pass once the newest reaches Loop End, from as far past Loop Start as the
## newest is past Loop End, so the two stay in step; the newest plays on through its tail.
func _next_pass() -> void:
	if not loop_player.playing:
		loop_player.play(loop_start)
		return
	var at: float = loop_player.get_playback_position()
	var end: float = _loop_end()
	if at >= end:
		loop_player.play(minf(loop_start + at - end, end))


## Whether the loop has a tail after Loop End, played out under the next pass.
func _has_tail() -> bool:
	return loop != null and loop_end > loop_start


## Loop End, within the file.
func _loop_end() -> float:
	var length: float = loop.get_length() if loop != null else 0.0
	return minf(loop_end, length) if length > 0.0 else loop_end


## How many passes play at once at most: the newest and those whose tails still ring.
func _passes_at_once() -> int:
	var length: float = loop.get_length()
	var pass_length: float = _loop_end() - loop_start
	if length <= 0.0 or pass_length <= 0.0:
		return 2
	return maxi(2, ceili((length - loop_start) / pass_length) + 1)


## Falloff, or Default Falloff without one that has two points at least.
func _falloff() -> Curve:
	if falloff != null and falloff.point_count >= 2:
		return falloff
	if _default_falloff == null:
		_default_falloff = Curve.new()
		for point: Vector2 in DEFAULT_FALLOFF:
			_default_falloff.add_point(point, 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return _default_falloff


## The man of the level it is in: among the levels in the tree (which join their group as they
## enter it, before their children are ready), the one that holds it.
func _find_man() -> Node2D:
	for node: Node in get_tree().get_nodes_in_group(Level.GROUP):
		var level: Level = node as Level
		if level != null and level.is_ancestor_of(self):
			return level.player
	return null


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


## The loop, played once each pass, to its end: itself if it does not loop, and otherwise a copy
## that does not, if it is an Ogg Vorbis, an MP3 or a WAV file.
static func _played_once(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamOggVorbis and (stream as AudioStreamOggVorbis).loop:
		var ogg := stream.duplicate() as AudioStreamOggVorbis
		ogg.loop = false
		return ogg
	if stream is AudioStreamMP3 and (stream as AudioStreamMP3).loop:
		var mp3 := stream.duplicate() as AudioStreamMP3
		mp3.loop = false
		return mp3
	if stream is AudioStreamWAV and (stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED:
		var wav := stream.duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
		return wav
	return stream
