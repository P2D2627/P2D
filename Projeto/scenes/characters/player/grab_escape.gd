class_name GrabEscape
extends Node

## The grab on the man (ADR 0021). A hit that grabs, heard from his HitReaction, puts him in his
## GRABBED state with Player.grab(), which holds him where he is, with no run and no jump: he stops
## at once, and in the air he falls straight down. Player.release() ends it as he breaks free. Jump fills
## GrabRules until he breaks free or dies. Each press counts; with Hold To Escape on, holding counts
## instead, from a press made in the grab on, so a jump held from before gives nothing. Hold To
## Escape is the player's option in Settings, read on each frame he is held, so turning it on or off
## in the pause changes the grab under way. Free, he
## stays invulnerable for a moment, so the demon does not grab him again at once. It tells the
## HitReaction he is held, and every hit then grabs, whatever his SP: another demon's joins the
## grab, up to GrabRules.MAX_DEMONS, and asks for more presses; the same demon's again changes
## nothing. With the most holding him, his Hurtbox closes until he breaks free, so no more hits land
## and the other demons keep away, as while he is invulnerable, but with no blink (ADR 0029). Each
## Hitbox that holds him hears start_hold() as it grabs or joins and end_hold() when he breaks free,
## so its demon holds on and lets go, and sink_hold() in between, so it sinks with him, also when it
## joins half way down. At his death they hold on and his Hurtbox closes, since the room starts
## over. Dead from something else while held, as on spikes, the grab ends as a death there and then:
## no press counts any more, and died tells the prompt. With the debug cheats (#273), noclip lets
## him go at once, and in god mode the time running out lets him go instead of killing him; either
## way he goes free as by presses, and the next grab starts afresh. It only says when the grab
## starts and ends, and how far he sank: the player's scene connects grabbed, broke_free and
## sink_changed to what else changes, such as the crucifix going down and his drawing sinking.

## A demon grabbed the man; he can't run or jump until broke_free.
signal grabbed
## How far the man has sunk, from 0 at the grab to 1 at his death, at the pace of Time To Die: on
## each physics frame he is held and on the one he dies, and 0 on the one he breaks free, before
## broke_free.
signal sink_changed(sink: float)
## The man broke free and moves again.
signal broke_free
## A press of Jump counted towards breaking free (pressed true), or, with Hold To Escape, Jump held
## on a physics frame that counts (pressed false): he struggles, and his drawing shows it.
signal struggled(pressed: bool)
## The time ran out before the man broke free. He stays held: what comes next, such as the room
## starting over, listens to this.
signal died

## Name of the grab when it keeps the crucifix down.
const SOURCE: StringName = &"grab"
## Where the project loads the autoload Settings, looked up there so this script compiles before it
## exists.
const SETTINGS_PATH: NodePath = ^"/root/Settings"

@export var player: Player
@export var hit_reaction: HitReaction
@export var hurtbox: Hurtbox
## Time to die and what breaks the man free. Read each time it is used, so it can be tuned in the
## Remote tab while the game runs.
@export var stats: GrabStats
## Seconds after breaking free in which no hit lands, so the demon does not grab the man again at
## once.
@export_range(0.0, 3.0, 0.05, "suffix:s") var invulnerable_time: float = 1.0

## The grab under way, or the last one; null before the first.
var _rules: GrabRules = null
## True once Jump was pressed in this grab: from then on, holding counts.
var _pressed_in_grab: bool = false
## The Hitboxes holding the man in this grab, GrabRules.MAX_DEMONS at most.
var _holders: Array[Hitbox] = []
## Where Hold To Escape is read; null without the autoload, and then the grab asks for presses.
var _settings: GameSettings


func _ready() -> void:
	assert(player != null, "GrabEscape: assign the Player to Player.")
	assert(hit_reaction != null, "GrabEscape: assign the player's HitReaction to Hit Reaction.")
	assert(hurtbox != null, "GrabEscape: assign the player's Hurtbox to Hurtbox.")
	assert(stats != null, "GrabEscape: assign a GrabStats resource to Stats.")
	_settings = get_node_or_null(SETTINGS_PATH) as GameSettings
	if _settings == null:
		push_warning(("GrabEscape: no Settings at %s, so the grab asks for presses, whatever the "
				+ "Hold To Escape option.") % SETTINGS_PATH)
	hit_reaction.grab_hit.connect(_on_grab_hit)
	player.died.connect(_on_player_died)


## Runs after the player's own physics, which goes first, so a press that breaks the man free does
## not also make him jump: the jump was still blocked on that frame.
func _physics_process(delta: float) -> void:
	if not is_held():
		return
	if player.noclip:
		_let_go_for_a_cheat()
		return
	var pressed: bool = player.input.is_jump_just_pressed()
	_pressed_in_grab = _pressed_in_grab or pressed
	var hold: bool = is_hold_to_escape()
	var holding: bool = hold and _pressed_in_grab and player.input.is_jump_held()
	_rules.advance(delta, pressed and not hold, holding)
	if (pressed and not hold) or holding:
		struggled.emit(not hold)
	match _rules.get_state():
		GrabRules.State.HELD:
			_sink(_rules.get_sink())
		GrabRules.State.FREE:
			_break_free()
		GrabRules.State.DEAD when player.is_invincible():
			_let_go_for_a_cheat()
		GrabRules.State.DEAD:
			_sink(_rules.get_sink())
			hurtbox.set_closed(true)
			died.emit()


## True while a demon holds the man and he is alive: a dead man's grab is over.
func is_held() -> bool:
	return _rules != null and _rules.get_state() == GrabRules.State.HELD and not player.is_dead()


## True if holding Jump breaks the man free, as the player chose in the options; false, the presses,
## also without Settings. For the prompt, which says which.
func is_hold_to_escape() -> bool:
	if _settings == null:
		return GameSettings.DEFAULT_HOLD_TO_ESCAPE
	return _settings.is_hold_to_escape_on()


## How near the man is to breaking free, from 0 to 1; 0 while he is not held. For the prompt.
func get_escape_progress() -> float:
	return _rules.get_escape_progress() if is_held() else 0.0


## What holds him, as Hitbox.get_cause() names it: the first that grabbed him while several do;
## Player's unknown cause while nothing does.
func get_hold_cause() -> StringName:
	for holder: Hitbox in _holders:
		if is_instance_valid(holder):
			return holder.get_cause()
	return Player.UNKNOWN_CAUSE


## Dead from something else while held, as on spikes: the grab ends as when its own time runs out,
## with the Hurtbox closed and died, but where he is. When its own time ran out, it already did.
func _on_player_died() -> void:
	if _rules == null or _rules.get_state() != GrabRules.State.HELD:
		return
	hurtbox.set_closed(true)
	died.emit()


func _on_grab_hit(hitbox: Hitbox) -> void:
	if is_held():
		_join(hitbox)
	elif _rules == null or _rules.get_state() == GrabRules.State.FREE:
		_start_grab(hitbox)


func _start_grab(hitbox: Hitbox) -> void:
	_rules = GrabRules.new(stats)
	_pressed_in_grab = false
	hit_reaction.hold()
	player.grab()
	_holders.clear()
	_holders.append(hitbox)
	hitbox.start_hold(hurtbox)
	_close_when_full()
	grabbed.emit()


func _join(hitbox: Hitbox) -> void:
	if _holders.has(hitbox) or not _rules.join():
		return
	_holders.append(hitbox)
	hitbox.start_hold(hurtbox)
	_close_when_full()


## Held by as many demons as can hold him, the man takes no more hits until he breaks free (ADR
## 0029).
func _close_when_full() -> void:
	hurtbox.set_closed(_holders.size() >= GrabRules.MAX_DEMONS)


## The man is invulnerable before the demons let go, so none of them starts an attack he can't take,
## and open to hits again once that is over.
func _break_free() -> void:
	hit_reaction.release()
	player.release()
	hurtbox.start_invulnerability(invulnerable_time)
	hurtbox.set_closed(false)
	_sink(0.0)
	for holder: Hitbox in _holders:
		if is_instance_valid(holder):
			holder.end_hold(hurtbox)
	_holders.clear()
	broke_free.emit()


## The man goes free although the grab's rules did not free him, for a debug cheat (#273). The
## rules go with the grab, so is_held() is false at once and the next grab starts afresh.
func _let_go_for_a_cheat() -> void:
	_break_free()
	_rules = null


## Tells the man's drawing and the demons holding him how far he has sunk.
func _sink(sink: float) -> void:
	sink_changed.emit(sink)
	for holder: Hitbox in _holders:
		if is_instance_valid(holder):
			holder.sink_hold(sink)
