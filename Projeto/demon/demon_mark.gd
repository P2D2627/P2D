class_name DemonMark
extends Node2D

## The mark over a demon's head that tells the man what it is about (ADR 0040): Alert Text from the
## moment it notices him, kept for Alert Linger Time into the chase, and Search Text for as long as
## it searches for him. A demon with Alert Time 0 has no alert, so no mark when it notices him. The two tell apart by their shape, not their colour, and each pops up once
## as it shows and never blinks. It only listens to the demon's state_changed, wired in demon.tscn;
## DemonSounds plays the beeps that go with it, so a man who does not hear sees them and one who is
## not looking hears them. It stays when the art comes, which only changes its look.

## Shows the mark. Its text is set here, by state.
@export var label: Label
## The mark from the moment the demon notices the man.
@export var alert_text: String = "!"
## The mark while the demon searches for the man.
@export var search_text: String = "?"
## Seconds Alert Text stays once the alert turns into the chase, so it shows long enough to read:
## the alert itself lasts only the demon's Alert Time.
@export_range(0.0, 2.0, 0.05, "suffix:s") var alert_linger_time: float = 0.5
## How big the mark shows, as a fraction of its own size, before it shrinks to it over Pop Time.
@export_range(1.0, 3.0, 0.05) var pop_scale: float = 1.6
## Seconds the mark takes to shrink from Pop Scale to its own size.
@export_range(0.05, 1.0, 0.05, "suffix:s") var pop_time: float = 0.15

var _tween: Tween


func _ready() -> void:
	assert(label != null, "DemonMark: assign a Label to Label.")
	_hide_mark()


## Alert Text as the demon notices the man, kept a while as it chases him, Search Text while it
## searches, and no mark in any other state, at once, so the crucifix or a lost man end it at once.
func _on_demon_state_changed(previous: Demon.State, current: Demon.State) -> void:
	match current:
		Demon.State.ALERT:
			_show_mark(alert_text)
		Demon.State.SEARCH:
			_show_mark(search_text)
		Demon.State.CHASE when previous == Demon.State.ALERT:
			_linger()
		_:
			_hide_mark()


## Shows text at Pop Scale and shrinks it to its own size, on the physics frames, as the body moves.
func _show_mark(text: String) -> void:
	_kill_tween()
	label.text = text
	visible = true
	scale = Vector2.ONE * pop_scale
	reset_physics_interpolation()
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, ^"scale", Vector2.ONE, pop_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Keeps the mark for Alert Linger Time, at its own size, and then hides it. It counts physics
## frames, so it stops in a pause.
func _linger() -> void:
	_kill_tween()
	scale = Vector2.ONE
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_interval(alert_linger_time)
	_tween.tween_callback(hide)


func _hide_mark() -> void:
	_kill_tween()
	visible = false
	scale = Vector2.ONE


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
