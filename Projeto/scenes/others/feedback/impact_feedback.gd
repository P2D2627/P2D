class_name ImpactFeedback
extends Node

## Answers each moment that hits the man with a shake of the screen: a hit from a demon or a hazard,
## a grab, each press to break free of it and breaking free, his death, a landing after a long fall,
## raising the crucifix and losing it, and a falling rock that breaks near him. A rock that falls on
## him is both: its hazard hits him and it breaks where he is. It listens to the signals the player,
## his parts, the hazards and the rocks already send, so none of them knows it is there. Stats says
## how strong each answer is, and is read at each answer, so the Remote tab tunes it live. It sits in
## the camera's scene, so every level with the game camera has it. It looks for the player's parts,
## the hazards and the rocks once, at the end of the frame the level starts on: what the level does
## as it starts, such as taking the crucifix from a man who lost it before, is no impact.

## How strong each answer is.
@export var stats: ImpactStats
## The camera whose player and level it listens to.
@export var camera: GameCamera
## The shake it adds trauma to.
@export var shake: CameraShake

var _player: Player


func _ready() -> void:
	assert(stats != null, "ImpactFeedback: assign an ImpactStats resource to Stats.")
	assert(shake != null, "ImpactFeedback: assign the CameraShake to Shake.")
	_listen.call_deferred()


## The level's _ready() runs after this node's, as parents' do after their children's, so listening
## waits for the end of the frame.
func _listen() -> void:
	if camera == null or not is_instance_valid(camera.player):
		return
	_player = camera.player
	_player.died.connect(_on_died)
	for part: Node in _player.get_children():
		if not part.is_queued_for_deletion():
			_listen_to_part(part)
	_listen_to_level()


func _listen_to_part(part: Node) -> void:
	if part is Hurtbox:
		(part as Hurtbox).hit_received.connect(_on_hit_received)
	elif part is GrabEscape:
		var grab: GrabEscape = part as GrabEscape
		grab.grabbed.connect(_on_grabbed)
		grab.struggled.connect(_on_struggled)
		grab.broke_free.connect(_on_broke_free)
	elif part is Crucifix:
		var crucifix: Crucifix = part as Crucifix
		crucifix.raised.connect(_on_crucifix_raised)
		crucifix.lost.connect(_on_crucifix_lost)
	elif part is PlayerSounds:
		(part as PlayerSounds).land_played.connect(_on_land_played)


## The hazards and the rocks in the camera's level, which it finds as the camera finds its own.
func _listen_to_level() -> void:
	var level: Node = camera.owner if camera.owner != null else camera.get_parent()
	if level == null:
		return
	for node: Node in level.find_children("*", "Node2D", true, false):
		if node is Hazard:
			(node as Hazard).player_hit.connect(_on_hazard_hit)
		elif node is FallingRock:
			var rock: FallingRock = node as FallingRock
			rock.broke.connect(_on_rock_broke.bind(rock))


func _on_hit_received(_hitbox: Hitbox) -> void:
	shake.add_trauma(stats.hit_trauma)


## A hazard hits any body that walks into it; only a hit on the man shakes the screen.
func _on_hazard_hit(body: Node2D, _health_fraction: float) -> void:
	if body == _player:
		shake.add_trauma(stats.hit_trauma)


func _on_grabbed() -> void:
	shake.add_trauma(stats.grab_trauma)


## A press to break free (pressed true) gives a jolt that never piles up; holding Jump gives none.
func _on_struggled(pressed: bool) -> void:
	if pressed:
		shake.raise_trauma(stats.struggle_trauma)


## Breaking free raises the trauma to its level instead of adding to what the presses left, so it is
## the same jolt after fast presses, slow ones or holding Jump.
func _on_broke_free() -> void:
	shake.raise_trauma(stats.break_free_trauma)


func _on_died() -> void:
	shake.add_trauma(stats.death_trauma)


func _on_land_played(hard: bool) -> void:
	if hard:
		shake.add_trauma(stats.hard_landing_trauma)


func _on_crucifix_raised() -> void:
	shake.add_trauma(stats.crucifix_raised_trauma)


func _on_crucifix_lost() -> void:
	shake.add_trauma(stats.crucifix_lost_trauma)


## A rock breaks on the floor below where it hangs, or on the man on the way down, who is then even
## closer. Before the rock has measured its fall, where it hangs stands in.
func _on_rock_broke(rock: FallingRock) -> void:
	if not is_instance_valid(_player):
		return
	var broke_at: Vector2 = rock.global_position + Vector2.DOWN * maxf(rock.get_fall_distance(), 0.0)
	shake.add_trauma(stats.rock_trauma_at(broke_at.distance_to(_player.global_position)))
