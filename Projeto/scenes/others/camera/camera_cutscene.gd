class_name CameraCutscene
extends Node

## A short camera cutscene. The camera leaves the man to show the CameraShot children, in their order,
## each reached in its Travel Time and held its Hold Time, and then comes back to him in Return Time.
## The world keeps running meanwhile; only the man waits: he stands still, can't use the crucifix and
## takes no hits, so a dog that walks up does him nothing. It plays when play() is called, as a
## GateUnlocker with it does, by itself the first time the man is inside Trigger Zone, or once a
## talk from Talk Cue ends (a talk_ended(cue) signal, as Asmodeus's, connected to
## play_after_talk()). The world along each move is woken before the camera comes (the camera's
## ActivityTracker is shown the way), so the dogs there run and the parallax slides. With an
## Event, it plays once in the game: it marks the event in GameState as it starts and says so with
## event_marked, so Main saves and a death does not undo it, and a level that starts with the event
## already marked never plays it. Skip Action, after Skip Delay, ends it at once: the shots not reached
## yet still say arrived, so what hangs from them happens, and the camera cuts back to the man.
## The camera moves with a sine ease in and out, and zooms evenly in scale, so a zoom from far out
## does not rush at the end. With Zoom Out To Travel, a move between two places that do not fit on
## one screen together pulls back half way, until both screens would show, and closes in again, so
## the camera never sweeps past the level up close. With Motion Blur, the screen streaks along each
## move, more the faster it goes.

## The cutscene started: the camera is about to leave the man. Set the stage here, as a gate a shot
## will show locking.
signal started
## The camera got to shot, or a skip passed it.
signal shot_reached(shot: CameraShot)
## Event was marked in GameState; Main saves, so a death does not undo it.
signal event_marked
## The camera is back with the man, who moves again on the next physics frame.
signal finished

## The group every cutscene joins, where Main finds them.
const GROUP: StringName = &"camera_cutscenes"
## Name of the cutscene's change to the man's movement, and of what keeps his crucifix down.
const SOURCE: StringName = &"camera_cutscene"
## A move's way is shown to the ActivityTracker as screens along it, one at least every this share
## of the screen's shorter side, and no more than WAY_MOST of them.
const WAY_STEP: float = 0.5
const WAY_MOST: int = 64

## The level's camera, which the cutscene moves.
@export var camera: GameCamera
## The man who waits while it plays.
@export var player: Player
## The camera zone that starts it the first time the man is inside it. Empty: only play() starts it.
@export var trigger_zone: CameraZone
## With a talk_ended(cue) signal connected to play_after_talk(), the talk whose end starts it, as
## Asmodeus's offer at the start of a phase. Empty: the end of any talk.
@export var talk_cue: String = ""
## The GameState event that says it was seen, so it plays once in the game. Empty: it plays every time.
@export var event: StringName = &""
## Seconds the camera takes to come back to the man after the last shot.
@export_range(0.1, 10.0, 0.1, "suffix:s") var return_time: float = 2.0
## What ends it at once. Empty: it can't be skipped.
@export var skip_action: StringName = &"jump"
## Seconds before Skip Action can end it, so a press made just before it started does not.
@export_range(0.0, 3.0, 0.05, "suffix:s") var skip_delay: float = 0.5
## On: a move between places too far apart for one screen pulls back half way, so both show.
@export var zoom_out_to_travel: bool = true

@export_group("Motion Blur")
## How much of each frame's move the screen streaks along, as a camera's shutter left open: 0.5 is
## half of it. 0: no streak.
@export_range(0.0, 2.0, 0.05) var motion_blur: float = 0.0
## The longest streak, in px of the screen, however fast the camera goes.
@export_range(0.0, 200.0, 1.0, "suffix:px") var max_blur: float = 40.0

## True while it plays.
var _playing: bool = false
## True while Trigger Zone can still start it.
var _watching: bool = false
var _shots: Array[CameraShot] = []
## The shot the camera goes to or stays on; the number of shots while it goes back to the man.
var _index: int = 0
## True while the camera stays on the shot at _index.
var _holding: bool = false
## Seconds since the camera left for the shot at _index, or since it got there while it stays.
var _time: float = 0.0
## Seconds since it started, for Skip Delay.
var _elapsed: float = 0.0
## Where the current move starts and ends: the screen's middle and the zoom.
var _from_centre: Vector2 = Vector2.ZERO
var _from_zoom: float = 1.0
var _to_centre: Vector2 = Vector2.ZERO
var _to_zoom: float = 1.0
## The zoom half way through the move, further out than both ends when the move pulls back.
var _mid_zoom: float = 1.0
var _move_time: float = 1.0
## Where the camera was on the man when it started, to come back to.
var _home_centre: Vector2 = Vector2.ZERO
var _home_zoom: float = 1.0
## Where the camera was on the last physics frame, for the streak.
var _last_centre: Vector2 = Vector2.ZERO
## No run and no jump while it plays.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)

@onready var _progress: GameProgress = get_node_or_null(^"/root/GameState") as GameProgress


## Joins the group on entering the tree, so Main finds it as soon as it adds the level.
func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	for child: Node in get_children():
		if child is CameraShot:
			_shots.append(child as CameraShot)
	assert(not _shots.is_empty(), "CameraCutscene %s: add CameraShot children." % name)
	_watching = trigger_zone != null and not was_seen()
	set_physics_process(_watching)


func _physics_process(delta: float) -> void:
	if _playing:
		_advance(delta)
	elif _watching and is_instance_valid(player) and trigger_zone.has_point(player.global_position):
		play()


## True once it was seen in the game: its Event is marked in GameState. Never without an Event.
func was_seen() -> bool:
	return not event.is_empty() and _progress != null and _progress.has_event(event)


func is_playing() -> bool:
	return _playing


## For a talk_ended(cue) signal: plays it when the talk was from Talk Cue (any, with Talk Cue
## empty), as play() does.
func play_after_talk(cue: String) -> void:
	if talk_cue.is_empty() or cue == talk_cue:
		play()


## Starts it, and says whether it did. It does not when it is playing, was seen, has no camera, man
## or shots, the man is dead or held by a demon, or another cutscene has the camera.
func play() -> bool:
	if not _can_play():
		return false
	_playing = true
	_watching = false
	if not event.is_empty() and _progress != null:
		_progress.mark_event(event)
		event_marked.emit()
	_home_centre = camera.global_position
	_home_zoom = camera.zoom.x
	_last_centre = _home_centre
	_index = 0
	_holding = false
	_time = 0.0
	_elapsed = 0.0
	camera.direct()
	_hold_the_man()
	_start_move()
	set_physics_process(true)
	started.emit()
	return true


func _can_play() -> bool:
	return (not _playing and not was_seen() and not _shots.is_empty() and is_instance_valid(camera)
			and is_instance_valid(player) and not player.is_dead() and not player.is_grabbed()
			and not camera.is_directed())


func _advance(delta: float) -> void:
	_elapsed += delta
	if (not skip_action.is_empty() and _elapsed >= skip_delay
			and Input.is_action_just_pressed(skip_action)):
		_skip()
		return
	_time += delta
	if _holding:
		camera.set_motion_blur(Vector2.ZERO)
		if _time >= _shots[_index].hold_time:
			_index += 1
			_holding = false
			_time = 0.0
			_start_move()
		return
	var done: float = clampf(_time / _move_time, 0.0, 1.0)
	_place(0.5 - 0.5 * cos(PI * done))
	if done < 1.0:
		return
	if _index >= _shots.size():
		_finish()
		return
	_holding = true
	_time = 0.0
	_reach(_shots[_index])


## From where the camera is to the shot at _index, or back to the man after the last.
func _start_move() -> void:
	_from_centre = camera.global_position
	_from_zoom = camera.zoom.x
	if _index < _shots.size():
		var shot: CameraShot = _shots[_index]
		var view: Rect2 = shot.get_view()
		_to_zoom = _home_zoom if shot.keep_zoom else camera.zoom_to_show(view)
		_to_centre = camera.centre_to_show(view, _to_zoom)
		_move_time = shot.travel_time
	else:
		_to_zoom = _home_zoom
		_to_centre = _home_centre
		_move_time = return_time
	_mid_zoom = minf(_from_zoom, _to_zoom)
	if zoom_out_to_travel:
		var both: Rect2 = _screen_at(_from_centre, _from_zoom).merge(_screen_at(_to_centre, _to_zoom))
		_mid_zoom = minf(_mid_zoom, camera.zoom_to_show(both))
	_show_the_way()


## Puts the camera eased of the way along the move, and streaks the screen along its step since the
## last frame.
func _place(eased: float) -> void:
	camera.global_position = _centre_at(eased)
	camera.zoom = Vector2.ONE * _zoom_at(eased)
	var step: Vector2 = (camera.global_position - _last_centre) * camera.zoom.x
	_last_centre = camera.global_position
	camera.set_motion_blur((step * motion_blur).limit_length(max_blur))


## The middle of the screen eased of the way along the move: a straight line.
func _centre_at(eased: float) -> Vector2:
	return _from_centre.lerp(_to_centre, eased)


## The zoom eased of the way along the move: evenly in scale, through _mid_zoom half way when that
## is further out than both ends.
func _zoom_at(eased: float) -> float:
	var from: float = log(_from_zoom)
	var to: float = log(_to_zoom)
	var mid: float = log(_mid_zoom)
	var level: float = lerpf(from, to, eased)
	if mid < minf(from, to):
		# A curve through from, mid (half way) and to: its middle control point puts it at mid at 0.5.
		var control: float = 2.0 * mid - 0.5 * (from + to)
		var rest: float = 1.0 - eased
		level = rest * rest * from + 2.0 * eased * rest * control + eased * eased * to
	return exp(level)


## Shows the camera's ActivityTracker the screens the move passes, ends included, close enough
## together that none of the way is left out, so what is there wakes before it shows.
func _show_the_way() -> void:
	var start: Rect2 = _screen_at(_from_centre, _from_zoom)
	var end: Rect2 = _screen_at(_to_centre, _to_zoom)
	var shortest: float = minf(minf(start.size.x, start.size.y), minf(end.size.x, end.size.y))
	var steps: int = clampi(ceili(_from_centre.distance_to(_to_centre) / (shortest * WAY_STEP)), 1,
			WAY_MOST - 1)
	var screens: Array[Rect2] = []
	for index: int in steps + 1:
		var along: float = float(index) / steps
		screens.append(_screen_at(_centre_at(along), _zoom_at(along)))
	camera.show_the_way(screens)


## What the screen shows with its middle at centre and zoom level, in the level.
func _screen_at(centre: Vector2, level: float) -> Rect2:
	var size: Vector2 = camera.get_viewport_rect().size / level
	return Rect2(centre - size / 2.0, size)


func _reach(shot: CameraShot) -> void:
	shot_reached.emit(shot)
	shot.arrived.emit()


## Every shot not reached yet says so, and the camera cuts back to the man.
func _skip() -> void:
	var first: int = _index + 1 if _holding else _index
	for index: int in range(first, _shots.size()):
		_reach(_shots[index])
	camera.global_position = _home_centre
	camera.zoom = Vector2(_home_zoom, _home_zoom)
	camera.reset_physics_interpolation()
	_finish()


func _finish() -> void:
	_playing = false
	set_physics_process(false)
	camera.release()
	finished.emit()
	_let_the_man_go()


## While it plays, the man stands still, with no run, no jump and no crucifix, and no hit lands.
func _hold_the_man() -> void:
	player.add_movement_modifier(SOURCE, _modifier)
	player.hold_still()
	var crucifix: Crucifix = player.get_node_or_null(^"Crucifix") as Crucifix
	if crucifix != null:
		crucifix.block(SOURCE)
	var hurtbox: Hurtbox = _find_hurtbox()
	if hurtbox != null:
		hurtbox.set_closed(true)


## On the next physics frame, so the press of Skip Action that ended it does not also make him jump:
## his jump is still blocked on the frame it counts as just pressed.
func _let_the_man_go() -> void:
	await get_tree().physics_frame
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	player.remove_movement_modifier(SOURCE)
	player.let_go()
	var crucifix: Crucifix = player.get_node_or_null(^"Crucifix") as Crucifix
	if crucifix != null:
		crucifix.unblock(SOURCE)
	var hurtbox: Hurtbox = _find_hurtbox()
	if hurtbox != null:
		hurtbox.set_closed(false)


func _find_hurtbox() -> Hurtbox:
	for child: Node in player.get_children():
		if child is Hurtbox:
			return child as Hurtbox
	return null
