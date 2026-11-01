class_name Level
extends Node2D

## The root of every level (ADR 0026). When its man dies, it waits Restart Delay, so the death shows,
## and then the level starts over as a new copy of itself, so everything is as at the start: the
## man, the demons and the camera. In the game, Main put it in its level slot and makes the swap,
## on restart_requested; run on its own, with F6, it is the current scene and reloads itself. The
## wait pauses with the level. The man keeps the crucifix only while GameState says he holds it, and
## GameState hears when he loses it, since the level starts over without what it knew.

## A new copy of this level should take its place. Main listens.
signal restart_requested

@export var player: Player
## Seconds between the man's death and the restart, so the death shows. At 0 it starts over at once.
@export_range(0.0, 5.0, 0.1, "suffix:s") var restart_delay: float = 1.5

var _restart_timer: Timer


func _ready() -> void:
	assert(player != null, "Level: assign the level's Player to Player.")
	_restart_timer = Timer.new()
	_restart_timer.one_shot = true
	_restart_timer.timeout.connect(_restart)
	add_child(_restart_timer)
	player.died.connect(_on_player_died)
	_follow_the_crucifix()


func _follow_the_crucifix() -> void:
	var progress: GameProgress = get_node(^"/root/GameState") as GameProgress
	var crucifix: Crucifix = player.get_node_or_null(^"Crucifix") as Crucifix
	if crucifix == null:
		return
	if progress.has_crucifix:
		crucifix.lost.connect(progress.lose_crucifix)
	else:
		crucifix.lose()


func _on_player_died() -> void:
	if restart_delay > 0.0:
		_restart_timer.start(restart_delay)
	else:
		_restart()


func _restart() -> void:
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		restart_requested.emit()
