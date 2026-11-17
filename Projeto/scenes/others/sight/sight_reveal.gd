class_name SightReveal
extends Node

## Draws what it hangs from only while the man sees it (#253). Once in Look Every physics frames, the
## reveals taking turns over them, rays from his eyes (SightEyes) to Rows rows of spots across Look
## Box, from its top to its bottom, check that nothing in Sight Blockers stands between. The share of
## spots he sees sets how much is drawn: Full Share or more draws all of it, less draws it in part,
## so an edge of rock fades it rather than cuts it; RevealRule turns that into the alpha of Target's
## modulate. Within Near Radius of his eyes it is seen through anything, as what he could all but
## touch is. Only the world blocks his sight, as it does the demons' (ADR 0032): one-way platforms
## do not, nor does someone whose body sits on the world's layer. With Senses set, a demon that sees
## the man is seen too, and reveal_now(), on its warning, draws it in full at once, so none attacks
## unseen. With no eyes in the tree, as in a scene played on its own, all of it is drawn, as with
## Show Hidden: nothing counts as seen. One that remembers stops looking once it is fully drawn. The
## player's Show Hidden option is read on each frame the reveal runs, so turned on in the pause, it
## applies as play resumes.

## Where the project loads the autoload Settings, looked up there so this script compiles before it
## does.
const SETTINGS_PATH: NodePath = ^"/root/Settings"
## Bodies one ray goes past on one look before it counts as blocked; one in the way is the most
## level 1 has, Velvet.
const MOST_LOOKED_PAST: int = 4

## What is drawn or hidden, through its modulate's alpha. The node this hangs from, if left empty.
@export var target: CanvasItem
## The box looked at: Rows rows of spots across it, from end to end, from its top to its bottom. With
## none, the target is always drawn.
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
## Px above the look box's top where the top row of spots sits; below 0, inside the box. The
## spikes' box is the part that kills, lower than the teeth drawn, so theirs sits above it.
@export_range(-48.0, 48.0, 1.0, "suffix:px") var spot_rise: float = -4.0
## Px from his eyes to the nearest edge of the look box within which it is seen through anything,
## wall or ledge: what he could all but touch he cannot miss. Kept short, two tiles, since past it
## only his sight counts; a demon's warning draws it in any case.
@export_range(0.0, 960.0, 1.0, "suffix:px") var near_radius: float = 96.0

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

## The share of spots he must see for it to be drawn in full; seeing fewer draws it in part.
@export_range(0.05, 1.0, 0.05) var full_share: float = 0.5

@export_group("Cost")
## Rows of spots across the look box, from top to bottom; 1 looks at the top only.
@export_range(1, 5) var rows: int = 3
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
## How much of it the man saw the last time it looked, as a share of Full Share, 0 to 1.
var _share: float = 0.0
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
	_share = (_share_seen_by(eyes) if not _no_eyes and look_box != null and look_box.shape != null
			else 0.0)


func _process(delta: float) -> void:
	var show_all: bool = (_no_eyes or look_box == null or look_box.shape == null
			or (_settings != null and _settings.is_show_hidden_on()))
	_draw_at(_rule.step(_share > 0.0, show_all, delta, _share))
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
	_share = 1.0
	_draw_at(_rule.reveal_now())


## How much of the look box the eyes see, as a share of Full Share, 0 to 1: 0 off the screen and its
## margin; 1 within Near Radius of the eyes; else the share of spots a ray from them reaches, over
## Rows rows from the top (Spot Rise) to the bottom (End Inset up from it), stopping once it reaches
## Full Share. A demon that sees the man is seen in full.
func _share_seen_by(eyes: SightEyes) -> float:
	var box: Rect2 = look_box.shape.get_rect()
	var area: Rect2 = look_box.global_transform * box
	if not eyes.can_see_area(area):
		return 0.0
	var from: Vector2 = eyes.global_position
	var nearest := Vector2(clampf(from.x, area.position.x, area.end.x),
			clampf(from.y, area.position.y, area.end.y))
	if from.distance_to(nearest) <= near_radius:
		return 1.0
	var left: float = box.position.x + end_inset
	var right: float = box.end.x - end_inset
	var top: float = box.position.y - spot_rise
	var bottom: float = box.end.y - end_inset
	var row_count: int = rows if bottom > top else 1
	var gaps: int = maxi(1, ceili((right - left) / maxf(spot_spacing, 1.0))) if right > left else 0
	var spots: int = (gaps + 1) * row_count
	var needed: int = maxi(1, ceili(float(spots) * full_share))
	var seen: int = 0
	for row: int in row_count:
		var y: float = top if row_count == 1 else lerpf(top, bottom, float(row) / float(row_count - 1))
		for i: int in gaps + 1:
			var x: float = (box.get_center().x if gaps == 0
					else lerpf(left, right, float(i) / float(gaps)))
			if _is_in_view(from, look_box.global_transform * Vector2(x, y)):
				seen += 1
				if seen >= needed:
					return 1.0
	if senses != null and senses.can_see(eyes.get_man()):
		return 1.0
	return float(seen) / float(needed)


## True when nothing in Sight Blockers stands between from and spot. Someone's body left on the
## world's layer, as Velvet's is, does not count: the ray goes past it, and from then on always does.
func _is_in_view(from: Vector2, spot: Vector2) -> bool:
	_ray.global_position = from
	_ray.target_position = spot - from
	for i: int in MOST_LOOKED_PAST + 1:
		_ray.force_raycast_update()
		var blocker: Object = _ray.get_collider()
		if blocker == null:
			return true
		if not blocker is CharacterBody2D:
			return false
		_ray.add_exception(blocker as CharacterBody2D)
	return false


## Sets the target's alpha, only when it changes: most reveals stay undrawn or drawn for long.
func _draw_at(opacity: float) -> void:
	if opacity != _drawn_opacity:
		target.modulate.a = opacity
		_drawn_opacity = opacity
