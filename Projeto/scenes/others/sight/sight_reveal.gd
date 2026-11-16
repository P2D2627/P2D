class_name SightReveal
extends Node

## Draws what it hangs from only while the man sees it (#253). Once in Look Every physics frames, the
## reveals taking turns over them, rays from his eyes (SightEyes) to a row of spots across the top of
## Look Box check that nothing in Sight Blockers stands between; RevealRule turns that into how much
## is drawn, through the alpha of Target's modulate. The top, since what stands in front hides the
## bottom first, seen from above or below. Only the world blocks his sight, as it does the demons'
## (ADR 0032): one-way platforms do not. With Senses set, a demon that sees the man is seen too, and
## reveal_now(), on its warning, draws it in full at once, so none attacks unseen. With no eyes in the
## tree, as in a scene played on its own, all of it is drawn, as with Show Hidden: nothing counts as
## seen. One that remembers stops looking once it is fully drawn. The player's Show Hidden option is
## read on each frame the reveal runs, so turned on in the pause, it applies as play resumes.

## Where the project loads the autoload Settings, looked up there so this script compiles before it
## does.
const SETTINGS_PATH: NodePath = ^"/root/Settings"

## What is drawn or hidden, through its modulate's alpha. The node this hangs from, if left empty.
@export var target: CanvasItem
## The box looked at: a row of spots across its top, from end to end. With none, the target is always
## drawn.
@export var look_box: CollisionShape2D
## Stays drawn for good once the man has seen it, as the spikes do.
@export var remembers: bool = false:
	set(value):
		remembers = value
		if _rule != null:
			_rule.remembers = value
## A demon's senses, so the demon is seen whenever it sees the man. Left empty for anything else.
@export var senses: DemonSenses
## The physics layers that block the man's sight: the world.
@export_flags_2d_physics var sight_blockers: int = 1:
	set(value):
		sight_blockers = value
		if _ray != null:
			_ray.collision_mask = value
## Px above the look box's top where the row of spots sits; below 0, inside the box. The spikes' box
## is the part that kills, lower than the teeth drawn, so theirs sits above it.
@export_range(-48.0, 48.0, 1.0, "suffix:px") var spot_rise: float = -4.0

@export_group("Feel")
## Seconds from undrawn to fully drawn.
@export_range(0.0, 2.0, 0.01, "suffix:s") var fade_in_time: float = 0.15:
	set(value):
		fade_in_time = value
		if _rule != null:
			_rule.fade_in_time = value
## Seconds from fully drawn to undrawn.
@export_range(0.0, 2.0, 0.01, "suffix:s") var fade_out_time: float = 0.4:
	set(value):
		fade_out_time = value
		if _rule != null:
			_rule.fade_out_time = value
## Seconds it stays drawn after the man last saw it, so the edge of a wall does not make it flicker.
## No less than 0.3 s: going and coming back then takes over 1/3 s, so nothing flashes more than
## three times a second (WCAG 2.2, criterion 2.3.1).
@export_range(0.3, 2.0, 0.01, "suffix:s") var linger_time: float = 0.3:
	set(value):
		linger_time = value
		if _rule != null:
			_rule.linger_time = value

@export_group("Cost")
## It looks once in this many physics frames.
@export_range(1, 10) var look_every: int = 3:
	set(value):
		look_every = maxi(value, 1)
## Most px between two spots across the look box; its two ends always count.
@export_range(8.0, 512.0, 1.0, "suffix:px") var spot_spacing: float = 96.0
## Px in from each end of the look box, so a box flush with a wall is not looked at inside it.
@export_range(0.0, 48.0, 1.0, "suffix:px") var end_inset: float = 6.0

## How many reveals have come in, so each takes the next turn and they spread evenly over the frames.
static var _turns_taken: int = 0

var _rule: RevealRule
## The man's sight, from his eyes to one spot at a time.
var _ray: RayCast2D
## Whether the man saw it the last time it looked.
var _seen: bool = false
## Whether there were no eyes to look with the last time it looked; then all is drawn.
var _no_eyes: bool = false
## This reveal's turn: it looks on the physics frames where the count over Look Every lands on it.
var _turn: int = 0
## The player's options, for Show Hidden; null with no autoload, and then nothing shows hidden.
var _settings: GameSettings
## The alpha last set on the target; nan until the first, so that one is always set.
var _drawn_opacity: float = NAN


func _ready() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	if target == null:
		push_error("SightReveal: nothing to draw or hide; give it a Target.")
		set_process(false)
		set_physics_process(false)
		return
	if look_box == null or look_box.shape == null:
		push_warning("SightReveal: no Look Box on %s, so it is always drawn." % target.name)
	_rule = RevealRule.new(remembers, fade_in_time, fade_out_time, linger_time)
	_settings = get_node_or_null(SETTINGS_PATH) as GameSettings
	_turn = _turns_taken
	_turns_taken += 1
	_no_eyes = SightEyes.current == null
	_ray = RayCast2D.new()
	_ray.top_level = true
	_ray.enabled = false
	_ray.collision_mask = sight_blockers
	add_child(_ray, false, INTERNAL_MODE_BACK)
	_draw_at(_rule.get_opacity())


func _physics_process(_delta: float) -> void:
	if posmod(Engine.get_physics_frames(), look_every) != posmod(_turn, look_every):
		return
	var eyes: SightEyes = SightEyes.current
	_no_eyes = eyes == null
	_seen = (not _no_eyes and look_box != null and look_box.shape != null
			and _is_seen_by(eyes))


func _process(delta: float) -> void:
	var show_all: bool = (_no_eyes or look_box == null or look_box.shape == null
			or (_settings != null and _settings.is_show_hidden_on()))
	_draw_at(_rule.step(_seen, show_all, delta))
	if _rule.is_settled():
		set_process(false)
		set_physics_process(false)


## How much of the target is drawn, from 0, nothing, to 1, all of it.
func get_opacity() -> float:
	return _rule.get_opacity() if _rule != null else 1.0


## Draws it in full at once and counts it as seen, as a demon starts the warning of an attack: the
## man sees it then, even between two looks or while it was fading in.
func reveal_now() -> void:
	if _rule == null:
		return
	_seen = true
	_draw_at(_rule.reveal_now())


## True when the look box is in the eyes' sight and a ray from them reaches a spot across its top, or
## the demon sees the man.
func _is_seen_by(eyes: SightEyes) -> bool:
	var box: Rect2 = look_box.shape.get_rect()
	if not eyes.can_see_area(look_box.global_transform * box):
		return false
	var from: Vector2 = eyes.global_position
	var left: float = box.position.x + end_inset
	var right: float = box.end.x - end_inset
	var row_y: float = box.position.y - spot_rise
	var gaps: int = maxi(1, ceili((right - left) / maxf(spot_spacing, 1.0))) if right > left else 0
	for i: int in gaps + 1:
		var x: float = (box.get_center().x if gaps == 0
				else lerpf(left, right, float(i) / float(gaps)))
		if _is_in_view(from, look_box.global_transform * Vector2(x, row_y)):
			return true
	return senses != null and senses.can_see(eyes.get_man())


## True when nothing in Sight Blockers stands between from and spot.
func _is_in_view(from: Vector2, spot: Vector2) -> bool:
	_ray.global_position = from
	_ray.target_position = spot - from
	_ray.force_raycast_update()
	return not _ray.is_colliding()


## Sets the target's alpha, only when it changes: most reveals stay undrawn or drawn for long.
func _draw_at(opacity: float) -> void:
	if opacity != _drawn_opacity:
		target.modulate.a = opacity
		_drawn_opacity = opacity
