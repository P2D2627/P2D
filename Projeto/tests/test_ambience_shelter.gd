# Checks the ambience shelter, which muffles the listed buses as the ear goes into closed places, on
# the small map of the shelter's tests and a bus made here, which already has a compressor. The
# shelter adds a low-pass filter and an amplifier at the end of that bus, after the compressor, and
# none anywhere else; a bus not in the layout is left out. In the open both are off, so the bus is as
# mixed. Deep in the corridor it reaches Closed's volume and cutoff, gliding there from the open, not
# at once; deep in the chimney, Chimney's. Its first reading is taken at once. It never sets a bus's
# volume. Leaving the tree, it takes its effects out and leaves the compressor; a new copy that
# enters before the old one leaves, as when a level starts over, keeps its own and drives them.
# Level 1's ambience has a shelter on the Wind bus with level 1's field. In the level, it hears from
# the man: open where he starts, and muffling Wind as closed as Closed once he stands on a fully
# closed floor; once the level is gone, Wind has no effects left.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_shelter.gd
extends "res://tests/support/base_test.gd"

const SmallMap = preload("res://tests/support/small_shelter_map.gd")
## The bus made for the test, and a name no bus has.
const TEST_BUS: StringName = &"ShelterTest"
const MISSING_BUS: StringName = &"NoSuchBus"
## Long enough for a glide of the default 0.4 s to come within 0.1% of its end (7.5 times it), at 60
## physics frames a second.
const SETTLE_FRAMES: int = 180
## How near the end of a glide the volume must be, in dB, and the cutoff, as a share of it.
const DB_TOLERANCE: float = 0.02
const CUTOFF_TOLERANCE: float = 0.005
## The frames of a glide to watch, from the open into the corridor.
const GLIDE_FRAMES: int = 10
## Level 1, its field, the bus its shelter muffles, where the shelter is in it, and the frames the
## level takes to settle in.
const LEVEL1_PATH: String = "res://scenes/levels/lust/level1.tscn"
const LEVEL1_FIELD_PATH: String = "res://scenes/levels/lust/level1_shelter.res"
const WIND_BUS: StringName = &"Wind"
const SHELTER_PATH: NodePath = ^"Ambience/Shelter"
const LEVEL_SETTLE_FRAMES: int = 30
## How closed a floor must be to stand on for the level's check, and how near Closed's volume the
## shelter must come there, in dB.
const FULLY_CLOSED: float = 0.999
const LEVEL_DB_TOLERANCE: float = 0.05


func _initialize() -> void:
	await physics_frame
	var bus: int = _make_test_bus()
	var volumes_before: PackedFloat32Array = _bus_volumes()
	var effects_before: PackedInt32Array = _effect_counts()
	var field: ShelterField = SmallMap.bake()
	var ear := Node2D.new()
	ear.position = SmallMap.centre(SmallMap.CAVERN.get_center())
	root.add_child(ear)
	var shelter: AmbienceShelter = _new_shelter(field, ear)
	var results: Array[bool] = []
	results.append(_it_adds_its_effects_at_the_end_of_the_listed_buses(shelter, bus, effects_before))
	await _physics_frames(SETTLE_FRAMES)
	results.append(_in_the_open_the_bus_is_as_mixed(shelter, bus))
	results.append(await _deep_in_the_corridor_it_glides_to_closed(shelter, ear))
	results.append(await _deep_in_the_chimney_it_reaches_chimney(shelter, ear))
	results.append(await _the_first_reading_is_taken_at_once(field, ear))
	results.append(_it_never_sets_a_bus_volume(volumes_before))
	results.append(await _a_new_copy_keeps_its_own_when_the_old_leaves(shelter, field, ear, bus))
	results.append(await _level1_muffles_its_wind_as_the_man_goes_in())
	results.append(_it_never_sets_a_bus_volume(volumes_before))
	ear.free()
	AudioServer.remove_bus(AudioServer.get_bus_index(TEST_BUS))
	quit(1 if results.has(false) else 0)


func _it_adds_its_effects_at_the_end_of_the_listed_buses(shelter: AmbienceShelter, bus: int,
		effects_before: PackedInt32Array) -> bool:
	var count: int = AudioServer.get_bus_effect_count(bus)
	var in_order: bool = (count == 3
			and AudioServer.get_bus_effect(bus, 0) is AudioEffectCompressor
			and AudioServer.get_bus_effect(bus, 1) is AudioEffectLowPassFilter
			and AudioServer.get_bus_effect(bus, 2) is AudioEffectAmplify)
	var off: bool = (count == 3 and not AudioServer.is_bus_effect_enabled(bus, 1)
			and not AudioServer.is_bus_effect_enabled(bus, 2))
	var elsewhere: Array[String] = []
	var counts: PackedInt32Array = _effect_counts()
	for index: int in counts.size():
		if index != bus and counts[index] != effects_before[index]:
			elsewhere.append(String(AudioServer.get_bus_name(index)))
	return _report(in_order and off and elsewhere.is_empty() and shelter.buses.has(MISSING_BUS),
			"It adds a low-pass filter and an amplifier, off, after the bus's compressor (%s, %s), "
			% [in_order, off] + "and none on any other bus, the missing one left out (changed: %s)"
			% ", ".join(elsewhere))


func _in_the_open_the_bus_is_as_mixed(shelter: AmbienceShelter, bus: int) -> bool:
	var off: bool = (not AudioServer.is_bus_effect_enabled(bus, 1)
			and not AudioServer.is_bus_effect_enabled(bus, 2))
	return _report(not shelter.is_muffling() and off and shelter.get_amounts() == Vector2.ZERO,
			"In the open, nothing closes it in %s and both effects are off: %s"
			% [shelter.get_amounts(), off])


func _deep_in_the_corridor_it_glides_to_closed(shelter: AmbienceShelter, ear: Node2D) -> bool:
	ear.position = SmallMap.centre(SmallMap.CORRIDOR.get_center())
	var glide: Array[float] = []
	var falling: bool = true
	for _frame: int in GLIDE_FRAMES:
		await _physics_frames(1)
		var volume: float = shelter.get_volume_db()
		falling = falling and (glide.is_empty() or volume < glide[-1])
		glide.append(snappedf(volume, 0.001))
	var glided: bool = falling and glide[0] < 0.0 and glide[0] > shelter.closed_volume_db * 0.5
	await _physics_frames(SETTLE_FRAMES)
	var reached: bool = _near(shelter, shelter.closed_volume_db, shelter.closed_cutoff_hz)
	return _report(glided and reached and shelter.is_muffling(), "Into the corridor, the volume "
			+ "glides down from the open, not at once (%s, first frames %s), and " % [glided, glide]
			+ "reaches Closed's %.1f dB and %d Hz: %.3f dB and %.1f Hz" % [shelter.closed_volume_db,
			shelter.closed_cutoff_hz, shelter.get_volume_db(), shelter.get_cutoff_hz()])


func _deep_in_the_chimney_it_reaches_chimney(shelter: AmbienceShelter, ear: Node2D) -> bool:
	ear.position = SmallMap.centre(SmallMap.CHIMNEY.get_center())
	await _physics_frames(SETTLE_FRAMES)
	var reached: bool = _near(shelter, shelter.chimney_volume_db, shelter.chimney_cutoff_hz)
	return _report(reached, "Deep in the chimney, it reaches Chimney's %.1f dB and %d Hz: %.3f dB "
			% [shelter.chimney_volume_db, shelter.chimney_cutoff_hz, shelter.get_volume_db()]
			+ "and %.1f Hz" % shelter.get_cutoff_hz())


func _the_first_reading_is_taken_at_once(field: ShelterField, ear: Node2D) -> bool:
	# The ear is still deep in the chimney.
	var fresh: AmbienceShelter = _new_shelter(field, ear)
	await _physics_frames(1)
	var at_once: bool = _near(fresh, fresh.chimney_volume_db, fresh.chimney_cutoff_hz)
	var volume: float = fresh.get_volume_db()
	fresh.free()
	return _report(at_once, "A shelter that starts deep in the chimney is at Chimney's volume from "
			+ "its first frame, with no glide in: %.3f dB" % volume)


func _it_never_sets_a_bus_volume(volumes_before: PackedFloat32Array) -> bool:
	var now: PackedFloat32Array = _bus_volumes()
	return _report(now == volumes_before, "No bus's volume has changed: %s" % (now == volumes_before))


func _a_new_copy_keeps_its_own_when_the_old_leaves(old: AmbienceShelter, field: ShelterField,
		ear: Node2D, bus: int) -> bool:
	var fresh: AmbienceShelter = _new_shelter(field, ear)
	var both: int = AudioServer.get_bus_effect_count(bus)
	old.free()
	var left: int = AudioServer.get_bus_effect_count(bus)
	ear.position = SmallMap.centre(SmallMap.CORRIDOR.get_center())
	await _physics_frames(SETTLE_FRAMES)
	var amplify := AudioServer.get_bus_effect(bus, left - 1) as AudioEffectAmplify
	var driven: bool = (amplify != null and absf(amplify.volume_db - fresh.closed_volume_db)
			< DB_TOLERANCE)
	fresh.free()
	var after: int = AudioServer.get_bus_effect_count(bus)
	var compressor: bool = after == 1 and AudioServer.get_bus_effect(bus, 0) is AudioEffectCompressor
	return _report(both == 5 and left == 3 and driven and compressor, "With a new copy in before "
			+ "the old one leaves, the bus holds both copies' effects (%d), the old one's " % both
			+ "go with it (%d left), the new one drives its own %s, and when it goes too " % [left,
			driven] + "only the compressor is left: %s" % compressor)


func _level1_muffles_its_wind_as_the_man_goes_in() -> bool:
	var level := (load(LEVEL1_PATH) as PackedScene).instantiate() as Level
	root.add_child(level)
	await _physics_frames(LEVEL_SETTLE_FRAMES)
	var shelter := level.get_node_or_null(SHELTER_PATH) as AmbienceShelter
	var wind: int = AudioServer.get_bus_index(WIND_BUS)
	if shelter == null or level.player == null or wind == -1:
		level.queue_free()
		return _report(false, "Level 1 has its man, a shelter at %s and a Wind bus" % SHELTER_PATH)
	var wired: bool = (shelter.buses.size() == 1 and shelter.buses[0] == WIND_BUS
			and shelter.field != null and shelter.field.resource_path == LEVEL1_FIELD_PATH)
	var open_at_start: bool = not shelter.is_muffling() and shelter.get_amounts() == Vector2.ZERO
	var feet: Vector2 = _fully_closed_floor(shelter)
	level.player.process_mode = Node.PROCESS_MODE_DISABLED
	level.player.global_position = feet
	await _physics_frames(SETTLE_FRAMES)
	var on: int = _shelter_effects(wind, true)
	var muffled: bool = (shelter.is_muffling() and on == 2 and absf(shelter.get_volume_db()
			- shelter.closed_volume_db) < LEVEL_DB_TOLERANCE)
	var volume: float = shelter.get_volume_db()
	level.queue_free()
	await _physics_frames(2)
	var left: int = _shelter_effects(wind, false)
	return _report(wired and open_at_start and muffled and left == 0, "Level 1's shelter muffles "
			+ "Wind with level 1's field (%s); where the man starts it is open (%s); " % [wired,
			open_at_start] + "standing on a fully closed floor at %s, Wind's two " % feet
			+ "effects are on (%d) at %.3f dB; with the level gone, Wind has %d left" % [on, volume,
			left])


## The feet of the first floor in the shelter's field, from the top-left, where the man's head is
## fully closed and in no chimney, with the room for him above it; INF if there is none.
func _fully_closed_floor(shelter: AmbienceShelter) -> Vector2:
	var field: ShelterField = shelter.field
	for y: int in range(1, field.size.y - 1):
		for x: int in field.size.x:
			var i: int = y * field.size.x + x
			if field.widths[i] == 0 or field.widths[i - field.size.x] == 0:
				continue
			if field.widths[i + field.size.x] != 0:
				continue
			var feet: Vector2 = field.origin + Vector2((x + 0.5) * field.tile_size.x,
					(y + 1) * field.tile_size.y)
			var head: Vector2 = feet + shelter.listen_offset
			var closed: float = ShelterField.closed_amount(field.openness_at(head), shelter.open_at,
					shelter.shut_at)
			var chimney: float = field.chimney_amount(field.width_at(head),
					field.chimney_depth_at(head), shelter.tight_width, shelter.chimney_ramp)
			if closed >= FULLY_CLOSED and chimney == 0.0:
				return feet
	return Vector2.INF


## How many of the effects on a bus are a shelter's; with only_on, only those that are on.
func _shelter_effects(bus: int, only_on: bool) -> int:
	var count: int = 0
	for effect: int in AudioServer.get_bus_effect_count(bus):
		if (AudioServer.get_bus_effect(bus, effect).resource_name == AmbienceShelter.EFFECT_NAME
				and (not only_on or AudioServer.is_bus_effect_enabled(bus, effect))):
			count += 1
	return count


## A bus of its own, sending to Master, with a compressor already on it, as a mixed bus has.
func _make_test_bus() -> int:
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, TEST_BUS)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.add_bus_effect(index, AudioEffectCompressor.new())
	return index


## A shelter on the test bus and a missing one, hearing from ear itself, in the tree.
func _new_shelter(field: ShelterField, ear: Node2D) -> AmbienceShelter:
	var shelter := AmbienceShelter.new()
	shelter.field = field
	shelter.buses = [TEST_BUS, MISSING_BUS]
	shelter.ear = ear
	shelter.listen_offset = Vector2.ZERO
	root.add_child(shelter)
	return shelter


func _near(shelter: AmbienceShelter, volume_db: float, cutoff_hz: float) -> bool:
	return (absf(shelter.get_volume_db() - volume_db) < DB_TOLERANCE
			and absf(shelter.get_cutoff_hz() - cutoff_hz) < cutoff_hz * CUTOFF_TOLERANCE)


func _bus_volumes() -> PackedFloat32Array:
	var volumes := PackedFloat32Array()
	for index: int in AudioServer.bus_count:
		volumes.append(AudioServer.get_bus_volume_db(index))
	return volumes


func _effect_counts() -> PackedInt32Array:
	var counts := PackedInt32Array()
	for index: int in AudioServer.bus_count:
		counts.append(AudioServer.get_bus_effect_count(index))
	return counts


## Waits until the nodes have run at least frames physics frames more.
func _physics_frames(frames: int) -> void:
	for _frame: int in frames + 1:
		await physics_frame


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
