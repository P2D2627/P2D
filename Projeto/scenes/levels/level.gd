class_name Level
extends Node2D

## The root of every level (ADR 0026). When its man dies, it waits Restart Delay, so the death shows,
## and then the level starts over as a new copy of itself, so everything is as at the start: the
## man, the demons and the camera. In the game, Main put it in its level slot and makes the swap,
## on restart_requested; run on its own, with F6, it is the current scene and reloads itself, after
## saying so with the same signal. The wait pauses with the level. The man keeps the crucifix only
## while GameState says he holds it, and GameState hears when he loses it, since the level starts
## over without what it knew; when the first upgrade costs it in GameState, the one in his hands
## goes at once.
## It also tells RunStats which phase the man is in, and where he died: the phase is First Phase, or
## the highest Starts Phase among its save points already reached; the place is the camera zone the
## level's GameCamera keeps to, the one he entered last and sees
## (man_zone), or, outside every zone, a cell of Death Cell Size. Each frame it adds to the
## time of that phase, and of the zone he is in, so a line can say how long he has been trying to
## get past it; paused, the level does not run, so the pause does not count.
## Over the last Close Time of the wait, the screen fades to dark, all dark for the last frame, so
## the new copy takes its place on black, and the new copy fades in (#263); with Iris on in Iris
## Stats, an iris closes on his body and opens on him instead. A fresh press of Jump once Skip After
## is over cuts the wait to the fade, so a player who has seen the death goes on.
## For the debug keys, jump_to_phase starts it over at the start of one of its phases, behind the
## same fade.

## A new copy of this level should take its place. Main listens, and so does what must outlive the
## copy, as the gym's station. Not said when the level is left before the wait is over.
signal restart_requested
## GameState holds a jump to phase, so Main saves it: a restart in the run goes back to the save.
signal jumped_to_phase(phase: int)

## The group every level joins, where the debug overlay finds the one that runs.
const GROUP: StringName = &"levels"
## The name of a death outside every camera zone, by its cell.
const CELL_FORMAT: String = "cell_%d_%d"
const DeathIris := preload("res://scenes/levels/death_iris.gd")
const DeathIrisPlan := preload("res://scenes/levels/death_iris_plan.gd")
const DeathIrisStats := preload("res://scenes/levels/death_iris_stats.gd")
const DEFAULT_IRIS_STATS: DeathIrisStats = preload("res://scenes/levels/death_iris_stats.tres")
## The man's body, whose middle the iris closes and opens on.
const MAN_BODY_PATH := ^"CollisionShape2D"
## A copy made within this many frames of the old one's restart is that restart, and opens the iris.
const RESTART_FRAMES: int = 2

## The process frame of the last restart: the new copy, made on the same frame or the next (by
## Main, or as the reloaded current scene), opens the iris. Shared by every copy, as only one level
## runs at a time.
static var _restart_frame: int = -RESTART_FRAMES - 1

@export var player: Player
## Seconds between the man's death and the restart, so the death shows, the iris's close included.
## At 0 it starts over at once.
@export_range(0.0, 5.0, 0.05, "suffix:s") var restart_delay: float = 0.7
## Seconds after the death before a fresh press of Jump cuts the wait to the iris's close, so a
## press in the panic of the touch does not skip the death. With Close Time added, the earliest a
## skip restarts the level.
@export_range(0.0, 2.0, 0.05, "suffix:s") var skip_after: float = 0.15
## How the iris closes and opens. Empty takes the game's.
@export var iris_stats: DeathIrisStats
@export_group("Run stats")
## What RunStats files this level's deaths and times under; empty takes the scene's file name.
@export var id: StringName = &""
## The phase the man is in before any save point with a Starts Phase.
@export_range(1, 9) var first_phase: int = 1
## Outside every camera zone, a death counts in a square cell this wide.
@export_range(64.0, 4096.0, 16.0, "suffix:px") var death_cell_size: float = 768.0

var _restart_timer: Timer
var _camera_zones: Array[CameraZone] = []
var _camera_zones_found: bool = false
var _camera: GameCamera
var _camera_found: bool = false
var _run_stats: GameRunStats
var _iris: DeathIris
var _iris_plan: DeathIrisPlan
## His body's middle in the world when he died, where the iris closes.
var _death_point: Vector2 = Vector2.ZERO
## Seconds into the iris's opening; below 0 when it is not opening.
var _opening_for: float = -1.0
var _man_body: Node2D
## The phase a debug key asked for, held at the restart; 0 for none.
var _jump_to: int = 0
## The smallest radius the iris has had in this close; INF while it does not close.
var _closing_radius: float = INF
## How dark the screen was when this close began: 0, or more when it began as the new copy lightened.
var _close_from: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	assert(player != null, "Level: assign the level's Player to Player.")
	_restart_timer = Timer.new()
	_restart_timer.one_shot = true
	_restart_timer.timeout.connect(_restart)
	add_child(_restart_timer)
	player.died.connect(_on_player_died)
	_follow_the_crucifix()
	_run_stats = get_node(^"/root/RunStats") as GameRunStats
	_follow_the_phases()
	_set_up_the_iris()


func _process(delta: float) -> void:
	_run_stats.add_time(delta, man_zone())
	_show_the_iris(delta)


func _physics_process(_delta: float) -> void:
	if _restart_timer.is_stopped() or player.input == null:
		return
	var close: float = _close_time()
	if (_restart_timer.time_left > close and restart_delay - _restart_timer.time_left >= skip_after
			and player.input.is_jump_just_pressed()):
		_restart_timer.start(close)


## The iris of a restart, for the tests.
func get_iris() -> DeathIris:
	return _iris


## For the debug keys: the level starts over at the start of phase, behind the fade, and gives true;
## a phase it does not have, or a level that does not run (paused, or frozen by Main in a phase
## change), does nothing and gives false. A level of one phase, as the gym, has nothing to jump to,
## so the keys stay its own. A second press during the fade does not start it again; the restart
## takes the last phase asked for. Only the save points' events change (_hold_the_jump): lines,
## offers, upgrades, the crucifix and the moral record stay as they are.
func jump_to_phase(phase: int) -> bool:
	if not can_process() or _save_points_behind(phase, _get_save_points()) < 0:
		return false
	_jump_to = phase
	var close: float = _close_time()
	if not _restart_timer.is_stopped() and _restart_timer.time_left <= close:
		return true
	_death_point = _man_body.global_position
	if close > 0.0:
		_restart_timer.start(close)
	else:
		_restart()
	return true


## What RunStats files this level under: Id, or else the scene's file name, or else the node's name.
func get_run_id() -> StringName:
	if not id.is_empty():
		return id
	if not scene_file_path.is_empty():
		return StringName(scene_file_path.get_file().get_basename())
	return StringName(name)


## The zone the man is in, for his deaths, his time and the offers that wait for him: the camera
## zone the level's GameCamera keeps to, the one he entered last, so it is the zone he sees. With no
## camera, outside every zone, or while a cutscene directs the camera (it does not follow him then,
## so its zone is the one from before), zone_at() of his feet.
func man_zone() -> StringName:
	var camera: GameCamera = _get_camera()
	if camera != null and not camera.is_directed():
		var zone: CameraZone = camera.get_zone()
		if zone != null:
			return StringName(zone.name)
	return zone_at(player.global_position)


## The camera zone at point when no camera says it: the smallest of this level around it, or a cell.
func zone_at(point: Vector2) -> StringName:
	var best: CameraZone = null
	for zone: CameraZone in _get_camera_zones():
		if not zone.has_point(point):
			continue
		if best == null or zone.get_area() < best.get_area():
			best = zone
	if best != null:
		return StringName(best.name)
	var cell: Vector2i = Vector2i((point / death_cell_size).floor())
	return StringName(CELL_FORMAT % [cell.x, cell.y])


## This level's GameCamera, looked up once among its children; null if it has none.
func _get_camera() -> GameCamera:
	if not _camera_found:
		_camera_found = true
		for node: Node in find_children("*", "Camera2D", true, false):
			if node is GameCamera:
				_camera = node as GameCamera
				break
	return _camera if is_instance_valid(_camera) else null


## This level's camera zones, looked up once: in the game they never change.
func _get_camera_zones() -> Array[CameraZone]:
	if _camera_zones_found:
		return _camera_zones
	for node: Node in get_tree().get_nodes_in_group(CameraZone.GROUP):
		if node is CameraZone and is_ancestor_of(node):
			_camera_zones.append(node as CameraZone)
	_camera_zones_found = true
	return _camera_zones


## Puts the jump asked for in GameState, at the restart, so a save point he walked into during the
## fade does not undo it. The save points count in the scene's order, which is the route's: every
## one up to the one where the phase starts is marked and every later one forgotten, so the new copy
## puts him at that save point, as Continue would; First Phase starts after the save points before
## the next phase's, as the tutorial's. jumped_to_phase lets Main save it before the restart, which
## in the run goes back to the save.
func _hold_the_jump() -> void:
	var phase: int = _jump_to
	_jump_to = 0
	var save_points: Array[SavePoint] = _get_save_points()
	var behind: int = _save_points_behind(phase, save_points)
	var progress: GameProgress = get_node(^"/root/GameState") as GameProgress
	progress.arrival_point = &""
	for index: int in save_points.size():
		if index < behind:
			progress.mark_event(save_points[index].event)
		else:
			progress.forget_event(save_points[index].event)
	jumped_to_phase.emit(phase)


## This level's save points, in the scene's order.
func _get_save_points() -> Array[SavePoint]:
	var save_points: Array[SavePoint] = []
	for node: Node in get_tree().get_nodes_in_group(SavePoint.GROUP):
		if node is SavePoint and is_ancestor_of(node):
			save_points.append(node as SavePoint)
	return save_points


## How many of save_points, from the first, are behind the man at the start of phase; -1 when the
## level has no such phase. A Starts Phase of 0 starts no phase, so phase 0 is never found; a level
## with no phase after First Phase has none to jump to.
func _save_points_behind(phase: int, save_points: Array[SavePoint]) -> int:
	if phase < first_phase:
		return -1
	if phase == first_phase:
		for index: int in save_points.size():
			if save_points[index].starts_phase > first_phase:
				return index
		return -1
	for index: int in save_points.size():
		if save_points[index].starts_phase == phase:
			return index + 1
	return -1


func _follow_the_phases() -> void:
	var phase: int = first_phase
	for node: Node in get_tree().get_nodes_in_group(SavePoint.GROUP):
		var save_point: SavePoint = node as SavePoint
		if save_point == null or not is_ancestor_of(save_point) or save_point.starts_phase < 1:
			continue
		if save_point.is_reached():
			phase = maxi(phase, save_point.starts_phase)
		else:
			save_point.reached.connect(_on_phase_save_point_reached.bind(save_point.starts_phase))
	_run_stats.enter(get_run_id(), phase)


func _on_phase_save_point_reached(phase: int) -> void:
	if phase > _run_stats.get_phase():
		_run_stats.enter(get_run_id(), phase)


func _follow_the_crucifix() -> void:
	var progress: GameProgress = get_node(^"/root/GameState") as GameProgress
	var crucifix: Crucifix = player.get_node_or_null(^"Crucifix") as Crucifix
	if crucifix == null:
		return
	if progress.has_crucifix:
		crucifix.lost.connect(progress.lose_crucifix)
		progress.upgrade_granted.connect(_on_upgrade_granted.bind(crucifix))
	else:
		crucifix.lose()


## The first upgrade cost him the crucifix, in GameState: the one in his hands goes too.
func _on_upgrade_granted(_id: StringName, crucifix: Crucifix) -> void:
	var progress: GameProgress = get_node(^"/root/GameState") as GameProgress
	if is_instance_valid(crucifix) and not progress.has_crucifix:
		crucifix.lose()


func _on_player_died() -> void:
	_run_stats.record_death(man_zone(), player.global_position,
			player.get_death_cause(), player.get_death_source())
	# Dying in a jump's fade, the death counts and the fade goes on: the restart is already coming.
	if not _restart_timer.is_stopped() and _restart_timer.time_left <= _close_time():
		return
	_death_point = _man_body.global_position
	if restart_delay > 0.0:
		_restart_timer.start(restart_delay)
	else:
		_restart()


func _restart() -> void:
	if _jump_to > 0:
		_hold_the_jump()
	_restart_frame = Engine.get_process_frames()
	restart_requested.emit()
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()


func _set_up_the_iris() -> void:
	if iris_stats == null:
		iris_stats = DEFAULT_IRIS_STATS
	_iris_plan = DeathIrisPlan.new(iris_stats)
	_man_body = player.get_node_or_null(MAN_BODY_PATH) as Node2D
	if _man_body == null:
		_man_body = player
	_iris = DeathIris.new()
	_iris.name = "DeathIris"
	add_child(_iris)
	if Engine.get_process_frames() - _restart_frame <= RESTART_FRAMES:
		_opening_for = 0.0
		_iris.cover(1.0, iris_stats)


## The part of the wait the iris closes over: Close Time, or the whole wait if it is shorter.
func _close_time() -> float:
	return minf(iris_stats.close_time, restart_delay)


## Darkening over the end of the wait, lightening in a new copy: the whole screen, or, as an iris,
## closing around where he died and opening around him. Dying while it opens, it goes on opening
## until the close begins. A step of the opening is one frame of the effects at most: a new copy's
## first frames can be long (level 1 draws its first in about 0.4 s), and would skip it.
func _show_the_iris(delta: float) -> void:
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var close: float = _close_time()
	var into: float = close - _restart_timer.time_left
	if not _restart_timer.is_stopped() and into >= 0.0:
		if _opening_for >= 0.0:
			# The close begins while the new copy still lightens: it darkens on from there.
			_close_from = _iris.get_darkness()
			_opening_for = -1.0
		if not iris_stats.iris:
			_iris.cover(lerpf(_close_from, 1.0, _iris_plan.fading_out(into, close)), iris_stats)
			return
		var centre: Vector2 = get_canvas_transform() * _death_point
		# The camera can still move after the death and take the full radius further out, while
		# the close holds its first frames: it never opens again.
		_closing_radius = minf(_closing_radius, _iris_plan.closing(into, close,
				_iris_plan.full_radius(centre, screen)))
		_iris.draw_at(centre, _closing_radius, _iris_plan.frame_of(into), iris_stats)
		return
	_closing_radius = INF
	_close_from = 0.0
	if _opening_for < 0.0:
		return
	_opening_for += minf(delta, 1.0 / iris_stats.frame_rate)
	if _opening_for >= iris_stats.open_time:
		_opening_for = -1.0
		_iris.clear()
		return
	if not iris_stats.iris:
		_iris.cover(_iris_plan.fading_in(_opening_for), iris_stats)
		return
	var on_him: Vector2 = get_canvas_transform() * _man_body.global_position
	_iris.draw_at(on_him, _iris_plan.opening(_opening_for, _iris_plan.full_radius(on_him, screen)),
			_iris_plan.frame_of(_opening_for), iris_stats)
