class_name DemonSearchState
extends DemonState

## SEARCH: with Search Time, once a wall has hidden the man for Give Up Time (ADR 0035). The demon
## walks at Search Speed, facing the way it walks, to where it last saw him, or as near it as its
## floor lets it go, or to Pack Spacing behind another demon searching that way, and sniffs there
## for Search Time, turning round halfway; then it gives up and walks back to its post, or stands.
## With where it last saw him out of its reach in height, it first jumps up or leaps down toward
## there with Jump Height or Max Drop, as in the chase (ADR 0042), and walks on from the floor it
## lands on; where it cannot, it walks toward there along its floor, as without them, and a jump or
## leap that gets it nowhere has it sniff where it is.
## It is alerted by the man as soon as it notices him, and with Chases Only On Screen, it gives up
## as soon as it is further off the screen than Screen Margin. In the air, it only falls.

## True once the demon got to where it last saw the man.
var _there: bool = false
## Physics frames the demon has sniffed there.
var _frames: int = 0
## True once it could not go off its floor toward where it last saw the man on this search, so it
## walks along this floor toward there from then on, as with no Jump Height nor Max Drop.
var _floor_blocked: bool = false


func enter() -> void:
	_there = false
	_frames = 0
	_floor_blocked = false


## Sniffs where the demon is, as if it had got to where it last saw the man.
func sniff_here() -> void:
	_there = true


func physics_update(delta: float) -> void:
	_demon.velocity.x = 0.0
	if _demon.chase_if_it_notices_the_man():
		return
	if not _demon.may_keep_on_from_here():
		_demon.stand_or_return()
		return
	if not _demon.is_on_floor():
		return
	if not _there and not _floor_blocked and _demon.last_seen_off_its_floor():
		if _demon.searches_off_its_floor(delta):
			return
		_floor_blocked = true
	if not _there:
		var gap: float = _demon.get_last_seen_x() - _demon.global_position.x
		var direction: float = signf(gap)
		var room: float = minf(absf(gap), _demon.room_behind_a_searching_packmate(gap))
		_there = room <= Demon.POST_REACH or _demon.is_edge_ahead(direction) \
				or _demon.is_against_a_wall(direction)
		if not _there:
			_demon.turn_to(direction)
			_demon.velocity.x = direction * minf(_demon.stats.search_speed, room / delta)
			return
	_frames += 1
	if _frames == roundi(_demon.stats.get_search_frames() / 2.0):
		_demon.turn_to(-_demon.get_facing())
	if _frames >= _demon.stats.get_search_frames():
		_demon.stand_or_return()
