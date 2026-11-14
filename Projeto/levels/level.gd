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
## the highest Starts Phase among its save points already reached; the place is the smallest camera
## zone around him, or, outside every zone, a cell of Death Cell Size. Each frame it adds to the
## time of that phase, and of the zone he is in, so a line can say how long he has been trying to
## get past it; paused, the level does not run, so the pause does not count.

## A new copy of this level should take its place. Main listens, and so does what must outlive the
## copy, as the gym's station. Not said when the level is left before the wait is over.
signal restart_requested

## The name of a death outside every camera zone, by its cell.
const CELL_FORMAT: String = "cell_%d_%d"

@export var player: Player
## Seconds between the man's death and the restart, so the death shows. At 0 it starts over at once.
@export_range(0.0, 5.0, 0.1, "suffix:s") var restart_delay: float = 1.5
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
var _run_stats: GameRunStats


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


func _process(delta: float) -> void:
	_run_stats.add_time(delta, zone_at(player.global_position))


## What RunStats files this level under: Id, or else the scene's file name, or else the node's name.
func get_run_id() -> StringName:
	if not id.is_empty():
		return id
	if not scene_file_path.is_empty():
		return StringName(scene_file_path.get_file().get_basename())
	return StringName(name)


## Where a death at point counts: the smallest camera zone of this level around it, or a cell.
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


## This level's camera zones, looked up once: in the game they never change.
func _get_camera_zones() -> Array[CameraZone]:
	if _camera_zones_found:
		return _camera_zones
	for node: Node in get_tree().get_nodes_in_group(CameraZone.GROUP):
		if node is CameraZone and is_ancestor_of(node):
			_camera_zones.append(node as CameraZone)
	_camera_zones_found = true
	return _camera_zones


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
	_run_stats.record_death(zone_at(player.global_position), player.global_position,
			player.get_death_cause(), player.get_death_source())
	if restart_delay > 0.0:
		_restart_timer.start(restart_delay)
	else:
		_restart()


func _restart() -> void:
	restart_requested.emit()
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
