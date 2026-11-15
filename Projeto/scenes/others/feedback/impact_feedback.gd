class_name ImpactFeedback
extends Node

## Answers each moment and each state the man's body feels with a vibration of the controller, and
## the blows and grave moments also with a shake of the screen: a hit from a demon or a hazard; a
## grab, his sinking while it holds him, each press to break free of it and breaking free; his death,
## sharper on lethal spikes; a landing, firmer the longer the fall, which also shakes the screen after
## a long one; a jump; his head hitting a ceiling; getting on a wall; raising the crucifix, holding it
## up, something it pushes coming into its light, its running out and losing it; and a falling rock
## that breaks near him. A rock that falls on him is both: its hazard hits him and it breaks where he
## is. The moments are listed here once, so the shake and the vibration never drift apart (ADR 0062).
## It listens to the signals the player, his parts, the hazards, the lethal spikes and the rocks
## already send, so none of them knows it is there. Stats says how hard the screen shakes at each
## moment and Rumble Stats how the controller vibrates, and both are read at each answer, so the
## Remote tab tunes them live. Once he is dead, what the crucifix says vibrates nothing: it stays up
## until the room starts over, but his body feels nothing more. It sits in the camera's scene, so
## every level with the game camera has it. It looks for the player's parts, the hazards, the lethal
## spikes and the rocks once, at the end of the frame the level starts on: what the level does as it
## starts, such as taking the crucifix from a man who lost it before, is no impact. _process() only
## runs while the crucifix is up.

## The keys of the sustained vibrations in ControllerRumble: the grab's and the crucifix's.
const GRAB_HOLD: StringName = &"grab"
const CRUCIFIX_HOLD: StringName = &"crucifix"
## No physics frame yet.
const NO_FRAME: int = -1

## How hard the screen shakes at each moment.
@export var stats: ImpactStats
## How the controller vibrates at each moment.
@export var rumble_stats: RumbleStats
## The camera whose player and level it listens to.
@export var camera: GameCamera
## The shake it adds trauma to.
@export var shake: CameraShake
## The controller vibration it starts pulses on.
@export var rumble: ControllerRumble

var _player: Player
## The player's parts whose state the vibration reads: how close he is to breaking free, how long
## the crucifix has left up and how hard the last landing was.
var _grab: GrabEscape
var _crucifix: Crucifix
var _sounds: PlayerSounds
## The physics frames he last died on and last came into lethal spikes on, NO_FRAME before either:
## the two on the same frame are a death on the spikes, whichever is heard first.
var _death_frame: int = NO_FRAME
var _spikes_frame: int = NO_FRAME


func _ready() -> void:
	assert(stats != null, "ImpactFeedback: assign an ImpactStats resource to Stats.")
	assert(rumble_stats != null, "ImpactFeedback: assign a RumbleStats resource to Rumble Stats.")
	assert(shake != null, "ImpactFeedback: assign the CameraShake to Shake.")
	assert(rumble != null, "ImpactFeedback: assign the ControllerRumble to Rumble.")
	set_process(false)
	_listen.call_deferred()


## While the crucifix is up, its held vibration grows as its use time runs out; once it is down, by
## any way, the vibration ends.
func _process(_delta: float) -> void:
	if not is_instance_valid(_crucifix) or not _crucifix.is_raised():
		_end_crucifix_hold()
		return
	_hold_crucifix()


## The level's _ready() runs after this node's, as parents' do after their children's, so listening
## waits for the end of the frame.
func _listen() -> void:
	if camera == null or not is_instance_valid(camera.player):
		return
	_player = camera.player
	_player.died.connect(_on_died)
	_player.jumped.connect(_on_jumped)
	_player.wall_jumped.connect(_on_jumped)
	_player.head_bumped.connect(_on_head_bumped)
	_player.got_on_wall.connect(_on_got_on_wall)
	for part: Node in _player.get_children():
		if not part.is_queued_for_deletion():
			_listen_to_part(part)
	_listen_to_level()


func _listen_to_part(part: Node) -> void:
	if part is Hurtbox:
		(part as Hurtbox).hit_received.connect(_on_hit_received)
	elif part is GrabEscape:
		_grab = part as GrabEscape
		_grab.grabbed.connect(_on_grabbed)
		_grab.sink_changed.connect(_on_sink_changed)
		_grab.struggled.connect(_on_struggled)
		_grab.broke_free.connect(_on_broke_free)
	elif part is Crucifix:
		_crucifix = part as Crucifix
		_crucifix.raised.connect(_on_crucifix_raised)
		_crucifix.ran_out.connect(_on_crucifix_ran_out)
		_crucifix.struck.connect(_on_crucifix_struck)
		_crucifix.lowered.connect(_end_crucifix_hold)
		_crucifix.lost.connect(_on_crucifix_lost)
	elif part is PlayerSounds:
		_sounds = part as PlayerSounds
		_sounds.land_played.connect(_on_land_played)


## The hazards, the lethal spikes and the rocks in the camera's level, which it finds as the camera
## finds its own. The spikes kill without a signal of their own, so their own sensing of a body is
## what tells a death on them.
func _listen_to_level() -> void:
	var level: Node = camera.owner if camera.owner != null else camera.get_parent()
	if level == null:
		return
	for node: Node in level.find_children("*", "Node2D", true, false):
		if node is Hazard:
			(node as Hazard).player_hit.connect(_on_hazard_hit)
		elif node is LethalSpikes:
			(node as LethalSpikes).body_entered.connect(_on_spikes_entered)
		elif node is FallingRock:
			var rock: FallingRock = node as FallingRock
			rock.broke.connect(_on_rock_broke.bind(rock))


func _on_hit_received(_hitbox: Hitbox) -> void:
	shake.add_trauma(stats.hit_trauma)
	rumble.play(rumble_stats.hit)


## A hazard hits any body that walks into it; only a hit on the man shakes the screen and the
## controller.
func _on_hazard_hit(body: Node2D, _health_fraction: float) -> void:
	if body == _player:
		shake.add_trauma(stats.hit_trauma)
		rumble.play(rumble_stats.hit)


## The grab's pulse, with its held vibration starting under it.
func _on_grabbed() -> void:
	shake.add_trauma(stats.grab_trauma)
	rumble.play(rumble_stats.grab)
	rumble.sustain(GRAB_HOLD, rumble_stats.grab_sink)


## The grab's held vibration grows as he sinks, from 0 at the grab to 1 at his death. The frame he
## breaks free, sink comes back to 0 just before broke_free ends it.
func _on_sink_changed(sink: float) -> void:
	rumble.sustain(GRAB_HOLD, rumble_stats.grab_sink, sink)


## A press to break free (pressed true) gives a jolt that never piles up and a tick of the
## controller, firmer the closer he is to breaking free; holding Jump gives neither, while the grab's
## held vibration still says he is held.
func _on_struggled(pressed: bool) -> void:
	if pressed:
		shake.raise_trauma(stats.struggle_trauma)
		var progress: float = _grab.get_escape_progress() if is_instance_valid(_grab) else 0.0
		rumble.play(rumble_stats.struggle, rumble_stats.struggle_share(progress))


## Breaking free raises the trauma to its level instead of adding to what the presses left, so it is
## the same jolt after fast presses, slow ones or holding Jump. The grab's held vibration stops.
func _on_broke_free() -> void:
	shake.raise_trauma(stats.break_free_trauma)
	rumble.end_sustain(GRAB_HOLD)
	rumble.play(rumble_stats.break_free)


## His death, by any way, ends the held vibrations: the room starts over. On lethal spikes it also
## stabs.
func _on_died() -> void:
	_death_frame = Engine.get_physics_frames()
	shake.add_trauma(stats.death_trauma)
	rumble.end_sustain(GRAB_HOLD)
	_end_crucifix_hold()
	rumble.play(rumble_stats.death)
	if _spikes_frame == _death_frame:
		rumble.play(rumble_stats.spike_death)


## Lethal spikes sense only the man. His coming into them on the frame he dies is his death on them,
## so it stabs, whether the death was heard before or after.
func _on_spikes_entered(body: Node2D) -> void:
	if body != _player:
		return
	_spikes_frame = Engine.get_physics_frames()
	if _death_frame == _spikes_frame:
		rumble.play(rumble_stats.spike_death)


## Every landing PlayerSounds hears vibrates, from Landing for the shortest to Hard Landing for a hard
## one, by how hard PlayerSounds says it was, slowly over the short falls (RumbleStats.landing_at());
## only a hard one shakes the screen.
func _on_land_played(hard: bool) -> void:
	var share: float = 1.0
	if hard:
		shake.add_trauma(stats.hard_landing_trauma)
	elif is_instance_valid(_sounds):
		share = _sounds.get_last_landing_share()
	rumble.play(rumble_stats.landing_at(share))


## A jump off the floor or off a wall.
func _on_jumped(_late_frames: int, _buffered_frames: int) -> void:
	rumble.play(rumble_stats.jump)


func _on_head_bumped() -> void:
	rumble.play(rumble_stats.head_bump)


func _on_got_on_wall() -> void:
	rumble.play(rumble_stats.on_wall)


## The crucifix's pulse, with its held vibration starting under it and growing each frame it stays up.
func _on_crucifix_raised() -> void:
	shake.add_trauma(stats.crucifix_raised_trauma)
	rumble.play(rumble_stats.crucifix_raised)
	_hold_crucifix()
	set_process(true)


## Something the crucifix pushes came into its light, such as a demon running at it: a knock in the
## hands, over its held vibration. After his death, nothing.
func _on_crucifix_struck() -> void:
	if not _is_dead():
		rumble.play(rumble_stats.crucifix_struck)


## The crucifix ran out of time: a pulse fades out in place of its held vibration, which ends as it
## comes down on the same frame. After his death, nothing.
func _on_crucifix_ran_out() -> void:
	if not _is_dead():
		rumble.play(rumble_stats.crucifix_ran_out)


func _on_crucifix_lost() -> void:
	shake.add_trauma(stats.crucifix_lost_trauma)
	_end_crucifix_hold()
	rumble.play(rumble_stats.crucifix_lost)


## The crucifix's held vibration, grown as far as its warning has gone, with its light.
func _hold_crucifix() -> void:
	var progress: float = _crucifix.get_warning_progress() if is_instance_valid(_crucifix) else 0.0
	rumble.sustain(CRUCIFIX_HOLD, rumble_stats.crucifix_held, progress)


func _end_crucifix_hold() -> void:
	set_process(false)
	rumble.end_sustain(CRUCIFIX_HOLD)


func _is_dead() -> bool:
	return is_instance_valid(_player) and _player.is_dead()


## A rock breaks on the floor below where it hangs, or on the man on the way down, who is then even
## closer. Before the rock has measured its fall, where it hangs stands in. The shake's trauma and
## the vibration weaken with the distance by the same share.
func _on_rock_broke(rock: FallingRock) -> void:
	if not is_instance_valid(_player):
		return
	var broke_at: Vector2 = rock.global_position + Vector2.DOWN * maxf(rock.get_fall_distance(), 0.0)
	var distance: float = broke_at.distance_to(_player.global_position)
	shake.add_trauma(stats.rock_trauma_at(distance))
	rumble.play(rumble_stats.rock, stats.rock_closeness(distance))
