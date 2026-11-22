# Checks the low SP warning in PlayerSounds. A full man hears nothing. When the SP falls to Low
# Threshold the warning plays from its start, on its own bus, PlayerLowSP, into Alerts, and when its file ends it starts
# again while the SP is still low. Healed above Low Threshold, it fades out in Low SP Fade Out and
# stops, with its volume back as set for the next time; falling low again during the fade starts
# it again at once. When the SP runs out it stops at once, without the fade.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_low_sp_sound.gd
extends "res://tests/support/player_test.gd"

## Where the man stands, on a floor far from anything.
const BusRoute = preload("res://tests/support/bus_route.gd")
const START: Vector2 = Vector2(0.0, -2.0)
## A hit that leaves the man at or below the stats file's Low Threshold from full SP.
const LOW_HIT_SHARE: float = 0.9
## Seconds before the end of the file the warning is put at, to hear it end and start again.
const NEAR_THE_END: float = 0.1
## Seconds into the file the warning may be once it started again.
const RESTART_POSITION: float = 0.5
## Physics frames past the fade-out time before it must have stopped.
const FADE_SLACK_FRAMES: int = 5
## Rounding room for the volume put back, in dB.
const VOLUME_TOLERANCE: float = 0.01


func _initialize() -> void:
	make_platform(-2000.0, 2000.0)
	var results: Array[bool] = []
	results.append(await _full_man_hears_nothing())
	results.append(await _low_plays_on_alerts_and_starts_again_at_the_end())
	results.append(await _healing_above_fades_out_and_puts_the_volume_back())
	results.append(await _falling_low_during_the_fade_starts_again())
	results.append(await _running_out_stops_at_once())
	finish(results)


func _full_man_hears_nothing() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the man never landed")
	var sounds: PlayerSounds = _sounds(player)
	await wait_frames(10)
	var playing: bool = sounds.low_sp.playing
	remove_player(player)
	return report(not playing, "Full SP: warning playing %s, expected false" % playing)


func _low_plays_on_alerts_and_starts_again_at_the_end() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the man never landed")
	var sounds: PlayerSounds = _sounds(player)
	_hit_to_low(player)
	var started: bool = sounds.is_low_sp_playing()
	var bus: StringName = sounds.low_sp.bus
	# Headless, the dummy audio driver never moves a sound on (put 0.1 s before its end, it is still
	# there 0.5 s later), so the file never ends by itself. The case does what Godot does at the end:
	# stops the player and emits finished.
	sounds.low_sp.seek(sounds.low_sp.stream.get_length() - NEAR_THE_END)
	sounds.low_sp.stop()
	sounds.low_sp.finished.emit()
	await wait_frames(1)
	var again: bool = sounds.low_sp.playing
	var position: float = sounds.low_sp.get_playback_position()
	remove_player(player)
	return report(started and bus == &"PlayerLowSP" and BusRoute.reaches(bus, &"Alerts") and again and position < RESTART_POSITION,
			("Low SP: started %s on bus %s (expected true on PlayerLowSP, into Alerts); after its end, playing %s "
			+ "at %.2f s (expected true, under %.1f s)") % [started, bus, again, position,
			RESTART_POSITION])


func _healing_above_fades_out_and_puts_the_volume_back() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the man never landed")
	var sounds: PlayerSounds = _sounds(player)
	var volume_db: float = sounds.low_sp.volume_db
	_hit_to_low(player)
	_soul_points(player).heal(_soul_points(player).get_max_sp())
	var fading: bool = sounds.low_sp.playing and not sounds.is_low_sp_playing()
	await wait_frames(roundi(sounds.low_sp_fade_out * Engine.physics_ticks_per_second)
			+ FADE_SLACK_FRAMES)
	var stopped: bool = not sounds.low_sp.playing
	var volume_back: bool = absf(sounds.low_sp.volume_db - volume_db) <= VOLUME_TOLERANCE
	remove_player(player)
	return report(fading and stopped and volume_back,
			"Healed above: fading %s, stopped after the fade %s, volume back %s (all expected true)"
			% [fading, stopped, volume_back])


func _falling_low_during_the_fade_starts_again() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the man never landed")
	var sounds: PlayerSounds = _sounds(player)
	var volume_db: float = sounds.low_sp.volume_db
	_hit_to_low(player)
	_soul_points(player).heal(_soul_points(player).get_max_sp())
	await wait_frames(3)
	_hit_to_low(player)
	var playing: bool = sounds.is_low_sp_playing()
	var position: float = sounds.low_sp.get_playback_position()
	var volume_back: bool = absf(sounds.low_sp.volume_db - volume_db) <= VOLUME_TOLERANCE
	await wait_frames(roundi(sounds.low_sp_fade_out * Engine.physics_ticks_per_second)
			+ FADE_SLACK_FRAMES)
	var still: bool = sounds.is_low_sp_playing()
	remove_player(player)
	return report(playing and position < RESTART_POSITION and volume_back and still,
			("Low again during the fade: playing %s at %.2f s with its volume back %s, still "
			+ "playing after the old fade's time %s (all expected true)")
			% [playing, position, volume_back, still])


func _running_out_stops_at_once() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "the man never landed")
	var sounds: PlayerSounds = _sounds(player)
	_hit_to_low(player)
	var was_playing: bool = sounds.is_low_sp_playing()
	_soul_points(player).take_damage(_soul_points(player).get_max_sp())
	var stopped: bool = not sounds.low_sp.playing
	remove_player(player)
	return report(was_playing and stopped,
			"Running out: was playing %s, stopped at once %s (both expected true)"
			% [was_playing, stopped])


## Takes the man from where he is down to LOW_HIT_SHARE below Max SP, at or below Low Threshold.
func _hit_to_low(player: Player) -> void:
	var soul_points: SoulPoints = _soul_points(player)
	var target: float = soul_points.get_max_sp() * (1.0 - LOW_HIT_SHARE)
	soul_points.take_damage(maxf(soul_points.get_sp() - target, 0.0))


func _sounds(player: Player) -> PlayerSounds:
	return player.get_node(^"PlayerSounds") as PlayerSounds


func _soul_points(player: Player) -> SoulPoints:
	return player.get_node(^"SoulPoints") as SoulPoints
