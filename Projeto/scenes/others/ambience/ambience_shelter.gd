class_name AmbienceShelter
extends Node

## Muffles a level's wind as the man goes into closed places: a little quieter and duller just
## inside a tunnel, more as he goes deeper, and more again deep in a tight chimney; in the open, the
## wind as it is. How enclosed each spot is comes from Field, baked from the level's tiles (see
## ShelterField). A level's ambience scene holds one, which muffles only the buses it lists, so each
## level chooses its own, or none.
## It never sets a bus's volume, which is the mix's and the options'. While it is in the tree, it
## adds a low-pass filter and an amplifier of its own at the end of each listed bus, after the bus's
## own effects, and drives them; it takes them out as it leaves, as when the level starts over or is
## left. In the open both are off, so the bus is as mixed. Listing a bus and one it feeds would
## muffle the first twice: it warns.
## It hears from the man of the level it is in, at Listen Offset from his feet, or from Ear if set.
## A change glides, so running past the mouth of a tunnel does not flutter; the first reading, as the
## level starts, is taken at once. In a debug build it warns if Field was baked from other tiles than
## the level's, with the command that bakes it again.

## The low-pass filter's cutoff in the open: the highest Godot's filter takes, in Hz.
const OPEN_CUTOFF_HZ: float = 20500.0
## Below this amount, closed and chimney alike, both effects are off.
const OFF_BELOW: float = 0.005
## The name of the effects it adds, as the debugger shows them.
const EFFECT_NAME: String = "Shelter"
## The command that bakes a field again, given the level's scene and the field's file.
const BAKE_COMMAND: String = ("godot --headless --path Projeto --script "
		+ "res://scenes/others/ambience/bake_shelter.gd -- %s %s")

## How enclosed each spot of the level is: its baked ShelterField.
@export var field: ShelterField
## The buses it muffles, by name, such as Wind, which gathers a level's wind. A bus not in the
## layout is left out, with a warning.
@export var buses: Array[StringName] = [&"Wind"]
## What hears, if not the man of the level it is in.
@export var ear: Node2D
## Where on the man it hears from, from his feet, in px: his head, three quarters of the way up his
## 96 px body.
@export var listen_offset: Vector2 = Vector2(0.0, -72.0)

@export_group("Closed")
## The volume and the low-pass cutoff where the place is fully closed, as deep in a low corridor.
@export_range(-40.0, 0.0, 0.5, "suffix:dB") var closed_volume_db: float = -4.0
@export_range(200.0, 20000.0, 10.0, "exp", "suffix:Hz") var closed_cutoff_hz: float = 2500.0

@export_group("Chimney")
## The volume and the low-pass cutoff deep in a tight chimney.
@export_range(-40.0, 0.0, 0.5, "suffix:dB") var chimney_volume_db: float = -9.0
@export_range(100.0, 20000.0, 10.0, "exp", "suffix:Hz") var chimney_cutoff_hz: float = 900.0

@export_group("Where")
## The openness where closing starts, and where it is whole (see ShelterField).
@export_range(0.0, 1.0, 0.01) var open_at: float = ShelterField.DEFAULT_OPEN_AT
@export_range(0.0, 1.0, 0.01) var shut_at: float = ShelterField.DEFAULT_SHUT_AT
## How far into a closed place, walking from the open, the closing is whole, in tiles.
@export_range(0.0, 40.0, 0.5, "suffix:tiles") var closed_ramp: float = (
		ShelterField.DEFAULT_CLOSED_RAMP)
## How narrow a chimney is whole, and how far in from its mouth, in tiles.
@export_range(1.0, 10.0, 0.5, "suffix:tiles") var tight_width: float = (
		ShelterField.DEFAULT_TIGHT_WIDTH)
@export_range(0.0, 30.0, 0.5, "suffix:tiles") var chimney_ramp: float = (
		ShelterField.DEFAULT_CHIMNEY_RAMP)

@export_group("Response")
## How long a change takes to go about two thirds of the way, in s. 0 follows at once.
@export_range(0.0, 5.0, 0.05, "suffix:s") var glide_time: float = 0.4
## How steeply the filter cuts above its cutoff, and how much it lifts the cutoff itself (Godot's
## default, 0.5, lifts nothing).
@export var filter_slope: AudioEffectFilter.FilterDB = AudioEffectFilter.FILTER_12DB
@export_range(0.0, 1.0, 0.01) var filter_resonance: float = 0.5

## The effects added to each listed bus.
var _muffles: Array[Muffle] = []
## How closed the place is and how much of a chimney, as heard after the glide; whether the first
## reading is in.
var _amounts: Vector2 = Vector2.ZERO
var _settled: bool = false
var _volume_db: float = 0.0
var _cutoff_hz: float = OPEN_CUTOFF_HZ
## The man it hears from, and whether it has looked for him since it entered the tree.
var _man: Node2D = null
var _looked_for_man: bool = false


func _enter_tree() -> void:
	_settled = false
	_looked_for_man = false
	for bus: StringName in buses:
		var index: int = AudioServer.get_bus_index(bus)
		if index == -1:
			push_warning("AmbienceShelter %s: the bus layout has no %s bus." % [name, bus])
			continue
		if _muffles.any(func(muffle: Muffle) -> bool: return muffle.bus == bus):
			continue
		var muffle := Muffle.new(bus)
		AudioServer.add_bus_effect(index, muffle.filter)
		AudioServer.add_bus_effect(index, muffle.amplify)
		_muffles.append(muffle)
		_enable(muffle, false)


func _ready() -> void:
	if field == null or not field.is_baked():
		push_warning("AmbienceShelter %s: no Field baked by this version, so nothing is muffled."
				% name)
	elif OS.is_debug_build() and not is_field_current():
		var level: Level = _level()
		push_warning("AmbienceShelter %s: Field was baked from other tiles than the level's; "
				% name + "bake it again: " + BAKE_COMMAND % [level.scene_file_path,
				field.resource_path])
	for bus: StringName in buses:
		for other: StringName in buses:
			if other != bus and _feeds(bus, other):
				push_warning("AmbienceShelter %s: %s feeds %s, so it is muffled twice."
						% [name, bus, other])


func _physics_process(delta: float) -> void:
	if field == null or not field.is_baked() or _muffles.is_empty():
		return
	var listener: Node2D = _listener()
	if listener == null:
		return
	var at: Vector2 = listener.global_position + listen_offset
	var target := Vector2(ShelterField.closed_amount(field.openness_at(at),
			field.closed_depth_at(at), open_at, shut_at, closed_ramp),
			field.chimney_amount(field.width_at(at), field.chimney_depth_at(at), tight_width,
			chimney_ramp))
	if not _settled or glide_time <= 0.0:
		_amounts = target
		_settled = true
	else:
		_amounts = _amounts.lerp(target, 1.0 - exp(-delta / glide_time))
	_apply()


func _exit_tree() -> void:
	for muffle: Muffle in _muffles:
		var index: int = AudioServer.get_bus_index(muffle.bus)
		if index == -1:
			continue
		for effect: int in range(AudioServer.get_bus_effect_count(index) - 1, -1, -1):
			var added: AudioEffect = AudioServer.get_bus_effect(index, effect)
			if added == muffle.filter or added == muffle.amplify:
				AudioServer.remove_bus_effect(index, effect)
	_muffles.clear()


## How closed the place it hears from is, as heard (x), and how much of a chimney (y), each 0 to 1.
func get_amounts() -> Vector2:
	return _amounts


## The volume and the cutoff it gives the listed buses now.
func get_volume_db() -> float:
	return _volume_db


func get_cutoff_hz() -> float:
	return _cutoff_hz


## Whether its effects are on: anywhere not open.
func is_muffling() -> bool:
	return not _muffles.is_empty() and _muffles[0].enabled


## Whether Field was baked from the tiles of the level it is in, at Field's Tiles Path; true when
## there is no such level or tile map to compare with.
func is_field_current() -> bool:
	var level: Level = _level()
	if field == null or level == null:
		return true
	var tiles := level.get_node_or_null(field.tiles_path) as TileMapLayer
	return tiles == null or ShelterField.fingerprint(tiles) == field.source_sha256


## Closed takes the wind from as it is to Closed's values, and chimney from there to Chimney's; the
## cutoff moves on a log scale, by the same share of an octave each step, as the ear hears it.
func _apply() -> void:
	_volume_db = lerpf(lerpf(0.0, closed_volume_db, _amounts.x), chimney_volume_db, _amounts.y)
	_cutoff_hz = exp(lerpf(lerpf(log(OPEN_CUTOFF_HZ), log(closed_cutoff_hz), _amounts.x),
			log(chimney_cutoff_hz), _amounts.y))
	var on: bool = maxf(_amounts.x, _amounts.y) >= OFF_BELOW
	for muffle: Muffle in _muffles:
		muffle.amplify.volume_db = _volume_db
		muffle.filter.cutoff_hz = _cutoff_hz
		muffle.filter.db = filter_slope
		muffle.filter.resonance = filter_resonance
		if muffle.enabled != on:
			_enable(muffle, on)


func _enable(muffle: Muffle, on: bool) -> void:
	muffle.enabled = on
	var index: int = AudioServer.get_bus_index(muffle.bus)
	if index == -1:
		return
	for effect: int in AudioServer.get_bus_effect_count(index):
		var added: AudioEffect = AudioServer.get_bus_effect(index, effect)
		if added == muffle.filter or added == muffle.amplify:
			AudioServer.set_bus_effect_enabled(index, effect, on)


## Ear, or the man of the level it is in, looked for once each time it enters the tree.
func _listener() -> Node2D:
	if ear != null and is_instance_valid(ear):
		return ear
	if _man != null and not is_instance_valid(_man):
		_man = null
		_looked_for_man = false
	if _man == null and not _looked_for_man:
		_looked_for_man = true
		var level: Level = _level()
		if level != null:
			_man = level.player
	return _man


## The level it is in: among the levels in the tree (which join their group as they enter it,
## before their children are ready), the one that holds it.
func _level() -> Level:
	for node: Node in get_tree().get_nodes_in_group(Level.GROUP):
		var level: Level = node as Level
		if level != null and level.is_ancestor_of(self):
			return level
	return null


## Whether bus sends into other, directly or through other buses.
func _feeds(bus: StringName, other: StringName) -> bool:
	var index: int = AudioServer.get_bus_index(bus)
	var seen: Array[StringName] = [bus]
	while index > 0:
		var to: StringName = AudioServer.get_bus_send(index)
		if to == other:
			return true
		if to in seen:
			return false
		seen.append(to)
		index = AudioServer.get_bus_index(to)
	return false


## The two effects added to one bus, and whether they are on.
class Muffle:
	var bus: StringName
	var filter := AudioEffectLowPassFilter.new()
	var amplify := AudioEffectAmplify.new()
	var enabled: bool = true

	func _init(on: StringName) -> void:
		bus = on
		filter.resource_name = EFFECT_NAME
		filter.cutoff_hz = OPEN_CUTOFF_HZ
		amplify.resource_name = EFFECT_NAME
