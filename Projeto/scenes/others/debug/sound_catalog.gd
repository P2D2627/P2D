class_name SoundCatalog
extends RefCounted

## The sound events under a folder of audio, read from the file names, so a new sound with the
## right name is listed and played without a change to the code. The sound test room
## (sound_room.tscn) shows them.
##
## The rule of the names: a file's event is its name without the extension and without a last
## "_<number>", and the files of one folder with the same event are its versions. So footstep_1.wav
## to footstep_6.wav are the six versions of footstep, hard_land.wav and hard_land_2.wav the two of
## hard_land, and player_jump.wav the one of player_jump. The first folder under the root picks the
## bus, through a table: sfx to SFX, ambience to Ambience, and so on.

## The extensions of the audio files read; anything else in a folder is left out.
const AUDIO_EXTENSIONS: PackedStringArray = ["wav", "ogg", "mp3"]
## The digits a last "_<number>" is made of.
const DIGITS: String = "0123456789"


## A sound event: its name, its folder, the bus it plays on and its versions.
class Event:
	extends RefCounted

	## The event's name, as in its file names: footstep.
	var name: String
	## The folder of its files, from the root: sfx, or ambience/thunder. Empty at the root.
	var folder: String
	## The bus it plays on.
	var bus: StringName
	## Its files, one per version, in natural order (footstep_2 before footstep_10).
	var paths: PackedStringArray = PackedStringArray()

	func _init(event_name: String, event_folder: String, event_bus: StringName) -> void:
		name = event_name
		folder = event_folder
		bus = event_bus

	## The folder and the name together, which no two events share: sfx/footstep.
	func get_key() -> String:
		return name if folder.is_empty() else folder + "/" + name

	## The streams of its versions, in the order of Paths; a file that does not load is left out,
	## with a warning.
	func load_streams() -> Array[AudioStream]:
		var streams: Array[AudioStream] = []
		for path: String in paths:
			var stream := load(path) as AudioStream
			if stream == null:
				push_warning("SoundCatalog: %s does not load as an AudioStream." % path)
				continue
			streams.append(stream)
		return streams

	## What a player plays for it: the file itself, for one version; for more, an
	## AudioStreamRandomizer that picks one at random, never the one played before, and moves the
	## pitch by up to Random Pitch either way (1.05 is 5% up or down). Null if no file loads.
	func make_stream(random_pitch: float) -> AudioStream:
		var streams := load_streams()
		if streams.is_empty():
			return null
		if streams.size() == 1:
			return streams[0]
		var randomizer := AudioStreamRandomizer.new()
		randomizer.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
		randomizer.random_pitch = random_pitch
		for stream: AudioStream in streams:
			randomizer.add_stream(-1, stream)
		return randomizer

	## Whether one of its versions loops by its import, and so plays until it is stopped.
	func loops() -> bool:
		for stream: AudioStream in load_streams():
			if stream_loops(stream):
				return true
		return false

	## Whether a stream loops by its import: an AudioStreamWAV with a Loop Mode, or an OGG or MP3
	## with Loop on.
	static func stream_loops(stream: AudioStream) -> bool:
		if stream is AudioStreamWAV:
			return (stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED
		if stream is AudioStreamOggVorbis:
			return (stream as AudioStreamOggVorbis).loop
		if stream is AudioStreamMP3:
			return (stream as AudioStreamMP3).loop
		return false


## The events under Root, read from its folders and subfolders with ResourceLoader.list_directory,
## which also works in an exported game, where the files are converted. Bus By Folder gives the bus
## of each first folder under Root; a folder not in it, and a file at the root, play on Fallback
## Bus.
static func scan(root: String, bus_by_folder: Dictionary[String, StringName],
		fallback_bus: StringName) -> Array[Event]:
	var relative_paths := PackedStringArray()
	_collect(root, "", relative_paths)
	return group(root, relative_paths, bus_by_folder, fallback_bus)


## The events of the files at Relative Paths, each from Root, by the rule of the names: sorted by
## folder and then by name, in natural order, each with its versions in natural order.
static func group(root: String, relative_paths: PackedStringArray,
		bus_by_folder: Dictionary[String, StringName], fallback_bus: StringName) -> Array[Event]:
	var sorted_paths: Array[String] = []
	for relative: String in relative_paths:
		if relative.get_extension().to_lower() in AUDIO_EXTENSIONS:
			sorted_paths.append(relative)
	sorted_paths.sort_custom(_comes_first)
	var by_key: Dictionary[String, Event] = {}
	for relative: String in sorted_paths:
		var folder := relative.get_base_dir()
		var event := Event.new(event_name_of(relative.get_file()), folder,
				bus_of(folder, bus_by_folder, fallback_bus))
		var key := event.get_key()
		if by_key.has(key):
			event = by_key[key]
		else:
			by_key[key] = event
		event.paths.append(root.path_join(relative))
	var events: Array[Event] = []
	events.assign(by_key.values())
	events.sort_custom(func(a: Event, b: Event) -> bool:
		if a.folder != b.folder:
			return _comes_first(a.folder, b.folder)
		return _comes_first(a.name, b.name))
	return events


## The event a file belongs to: its name without the extension and without a last "_<number>".
## footstep_2.wav is footstep; hard_land.wav is hard_land; one_shot_wind_3_low.wav keeps its name.
static func event_name_of(file_name: String) -> String:
	var stem := file_name.get_basename()
	var cut := stem.rfind("_")
	if cut <= 0:
		return stem
	var tail := stem.substr(cut + 1)
	if tail.is_empty() or not tail.lstrip(DIGITS).is_empty():
		return stem
	return stem.left(cut)


## The bus of a folder, from Root: the one Bus By Folder gives its first folder, or Fallback Bus.
static func bus_of(folder: String, bus_by_folder: Dictionary[String, StringName],
		fallback_bus: StringName) -> StringName:
	return bus_by_folder.get(folder.get_slice("/", 0), fallback_bus)


## Adds to Out the files under Root, folder Relative and its subfolders, each from Root.
static func _collect(root: String, relative: String, out: PackedStringArray) -> void:
	for entry: String in ResourceLoader.list_directory(root.path_join(relative)):
		if entry.ends_with("/"):
			_collect(root, relative.path_join(entry.trim_suffix("/")), out)
		else:
			out.append(relative.path_join(entry))


## The natural order, without case: footstep_2 before footstep_10.
static func _comes_first(a: String, b: String) -> bool:
	return a.naturalnocasecmp_to(b) < 0
