class_name GrabEscape
extends Node

## The grab on the man (ADR 0021). A hit that grabs, heard from his HitReaction, holds him where he
## is, with no run and no jump: he stops at once, and in the air he falls straight down. Jump fills
## GrabRules until he breaks free or dies. Each press counts; with Hold To Escape on, holding counts
## instead, from a press made in the grab on, so a jump held from before gives nothing. Free, he
## stays invulnerable for a moment, so the demon does not grab him again at once. It tells the
## HitReaction he is held, and every hit then grabs, whatever his SP: another demon's joins the
## grab, up to GrabRules.MAX_DEMONS, and asks for more presses; the same demon's again changes
## nothing. With the most holding him, his Hurtbox closes until he breaks free, so no more hits land
## and the other demons keep away, as while he is invulnerable, but with no blink (ADR 0029). Each
## Hitbox that holds him hears start_hold() as it grabs or joins and end_hold() when he breaks free,
## so its demon holds on and lets go, and sink_hold() in between, so it sinks with him, also when it
## joins half way down. At his death they hold on and his Hurtbox closes, since the room starts
## over. It only says when the grab starts and ends, and how far he sank: the player's scene
## connects grabbed, broke_free and sink_changed to what else changes, such as the crucifix going
## down and his drawing sinking.

## A demon grabbed the man; he can't run or jump until broke_free.
signal grabbed
## How far the man has sunk, from 0 at the grab to 1 at his death, at the pace of Time To Die: on
## each physics frame he is held and on the one he dies, and 0 on the one he breaks free, before
## broke_free.
signal sink_changed(sink: float)
## The man broke free and moves again.
signal broke_free
## The time ran out before the man broke free. He stays held: what comes next, such as the room
## starting over, listens to this.
signal died

## Name of the grab's modifier on the player, and of the grab when it keeps the crucifix down.
const SOURCE: StringName = &"grab"

@export var player: Player
@export var hit_reaction: HitReaction
@export var hurtbox: Hurtbox
## Time to die and what breaks the man free. Read each time it is used, so it can be tuned in the
## Remote tab while the game runs.
@export var stats: GrabStats
## On, holding Jump breaks the man free instead of pressing it again and again. The Options are to
## set it.
@export var hold_to_escape: bool = false
## Seconds after breaking free in which no hit lands, so the demon does not grab the man again at
## once.
@export_range(0.0, 3.0, 0.05, "suffix:s") var invulnerable_time: float = 1.0

## The grab under way, or the last one; null before the first.
var _rules: GrabRules = null
## True once Jump was pressed in this grab: from then on, holding counts.
var _pressed_in_grab: bool = false
## The Hitboxes holding the man in this grab, GrabRules.MAX_DEMONS at most.
var _holders: Array[Hitbox] = []
## No run and no jump while the man is held. The same one for every grab.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)


func _ready() -> void:
	assert(player != null, "GrabEscape: assign the Player to Player.")
	assert(hit_reaction != null, "GrabEscape: assign the player's HitReaction to Hit Reaction.")
	assert(hurtbox != null, "GrabEscape: assign the player's Hurtbox to Hurtbox.")
	assert(stats != null, "GrabEscape: assign a GrabStats resource to Stats.")
	hit_reaction.grab_hit.connect(_on_grab_hit)


## Runs after the player's own physics, which goes first, so a press that breaks the man free does
## not also make him jump: the jump was still blocked on that frame.
func _physics_process(delta: float) -> void:
	if not is_held():
		return
	var pressed: bool = player.input.is_jump_just_pressed()
	_pressed_in_grab = _pressed_in_grab or pressed
	var holding: bool = hold_to_escape and _pressed_in_grab and player.input.is_jump_held()
	_rules.advance(delta, pressed and not hold_to_escape, holding)
	match _rules.get_state():
		GrabRules.State.HELD:
			_sink(_rules.get_sink())
		GrabRules.State.FREE:
			_break_free()
		GrabRules.State.DEAD:
			_sink(_rules.get_sink())
			hurtbox.set_closed(true)
			died.emit()


## True while a demon holds the man.
func is_held() -> bool:
	return _rules != null and _rules.get_state() == GrabRules.State.HELD


## How near the man is to breaking free, from 0 to 1; 0 while he is not held. For the prompt.
func get_escape_progress() -> float:
	return _rules.get_escape_progress() if is_held() else 0.0


func _on_grab_hit(hitbox: Hitbox) -> void:
	if is_held():
		_join(hitbox)
	elif _rules == null or _rules.get_state() == GrabRules.State.FREE:
		_start_grab(hitbox)


func _start_grab(hitbox: Hitbox) -> void:
	_rules = GrabRules.new(stats)
	_pressed_in_grab = false
	hit_reaction.hold()
	player.add_movement_modifier(SOURCE, _modifier)
	player.hold_still()
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
	player.remove_movement_modifier(SOURCE)
	player.let_go()
	hurtbox.start_invulnerability(invulnerable_time)
	hurtbox.set_closed(false)
	_sink(0.0)
	for holder: Hitbox in _holders:
		if is_instance_valid(holder):
			holder.end_hold(hurtbox)
	_holders.clear()
	broke_free.emit()


## Tells the man's drawing and the demons holding him how far he has sunk.
func _sink(sink: float) -> void:
	sink_changed.emit(sink)
	for holder: Hitbox in _holders:
		if is_instance_valid(holder):
			holder.sink_hold(sink)
