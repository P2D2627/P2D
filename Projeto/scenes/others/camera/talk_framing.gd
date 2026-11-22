class_name TalkFraming
extends Node

## A talk shown as a scene, in the level's GameCamera. When a DialogueBalloon starts, black bars slide in at
## the top and bottom of the screen, under the balloon, and the camera leaves the man to frame him and who
## talks to him together. The shot is as close as Max Zoom, with their feet just over the bottom bar and their
## heads under the answers' wheel, so a taller demon gets a wider shot (TalkShot works it out from their drawn
## figures). The man takes no hits meanwhile: it closes his hurtbox if it was open, and opens it again at the
## end unless a cutscene has the camera then; what holds him still is the talker's. Once a shot has held Hold
## Time, the camera leans a little to whoever has the turn: the demon while she speaks, the man while the
## answers show. When the balloon goes, the bars slide out and the camera eases back, in Return Time and with
## the curve it came in with, to where it was on the man before the talk, moved as far as he moved since; he
## moves again at once, and only then is the camera given back. A cutscene may take the camera meanwhile
## (GameCamera.let_be_taken()): the way back stops, and the cutscene comes back to where the camera was on
## the man before the talk. With Reduce Motion the camera stays with the man, with no zoom and no
## lean, and the bars fade in and out at full height; with Show Bars off there are no bars. Both are set here
## until the options screen has them. The balloon tells every node in its group TALK_WATCHERS, so a new talker
## gets all this with nothing to wire in the level. A talk while a CameraCutscene has the camera leaves the
## camera and the man's hurtbox to the cutscene and only shows the bars. The soul bar hides through the
## balloon's own group.

## The bars' layer: over the level and the HUD (5), under the balloon (8) and the pause menu (10).
const BARS_LAYER: int = 7

## The camera it moves; its player is the man.
@export var camera: GameCamera

@export_group("Bars")
## Off: a talk shows no bars.
@export var show_bars: bool = true
## Each bar's height, as a share of the visible height: 0.128 leaves a 2.39:1 picture on a 16:9 screen, the
## cinema's scope frame, 138 px each at 1080 px; 0.067 is the thinner 2D games' (72 px, about 2.05:1).
@export_range(0.0, 0.2, 0.001) var bar_share: float = 0.128
## Seconds the bars take to slide in, slowing down as they come.
@export_range(0.0, 2.0, 0.05, "suffix:s") var bars_in_time: float = 0.8
## Seconds the bars take to slide out, speeding up as they go: shorter than in.
@export_range(0.0, 2.0, 0.05, "suffix:s") var bars_out_time: float = 0.6
## With Reduce Motion, seconds the bars take to fade in or out instead.
@export_range(0.0, 2.0, 0.05, "suffix:s") var bars_fade_time: float = 0.2
@export var bars_color: Color = Color.BLACK

@export_group("Shot")
## On: the camera stays with the man in a talk, with no zoom and no lean, and the bars fade.
@export var reduce_motion: bool = false
## The closest the camera comes: 2.0 shows the demons' art one texel to a pixel at 1080p.
@export_range(1.0, 4.0, 0.05) var max_zoom: float = 2.0
## The furthest the camera pulls back to fit the figures.
@export_range(0.25, 2.0, 0.05) var min_zoom: float = 0.5
## Room between the figures' feet and the bottom bar, in px of the screen.
@export_range(0.0, 200.0, 1.0, "suffix:px") var feet_gap: float = 16.0
## Room between the figures' heads and the bottom of the answers' wheel, in px of the screen.
@export_range(0.0, 200.0, 1.0, "suffix:px") var head_gap: float = 8.0
## Room kept on each side of the screen, in px of the screen.
@export_range(0.0, 600.0, 1.0, "suffix:px") var side_gap: float = 96.0
## Seconds the camera takes to the shot as a talk starts: it settles before the first line is read.
@export_range(0.1, 5.0, 0.05, "suffix:s") var enter_time: float = 1.4
## Seconds the camera takes back to the man as a talk ends.
@export_range(0.1, 5.0, 0.05, "suffix:s") var return_time: float = 1.2

@export_group("Lean")
## How far the camera leans to whoever has the turn, as a share of the screen's width.
@export_range(0.0, 0.3, 0.01) var lean_share: float = 0.1
## Seconds a lean takes.
@export_range(0.1, 5.0, 0.05, "suffix:s") var lean_time: float = 0.7
## Seconds a shot holds before the camera may lean again, so it never keeps moving.
@export_range(0.0, 10.0, 0.1, "suffix:s") var hold_time: float = 2.0

## The balloon of the talk it frames, and the node that balloon was added to, who talks to the man.
var _balloon: DialogueBalloon = null
var _talker: Node2D = null
## What draws the man and the talker, found once as the talk starts; null where there is none.
var _man_figure: Node2D = null
var _talker_figure: Node2D = null
## True while it has the camera for a talk, and while it eases it back to the man after one.
var _framing: bool = false
var _returning: bool = false
## Where the camera was on the man as the talk started, and where he was: the way back goes there, moved as
## far as he moved since.
var _home_centre: Vector2 = Vector2.ZERO
var _home_zoom: float = 1.0
var _man_at_home: Vector2 = Vector2.ZERO
## The man's hurtbox while this talk keeps it closed: only when it was open as the talk started.
var _hurtbox: Hurtbox = null
## True while the camera goes to a new shot; then _time counts the move, else how long the shot has held.
var _moving: bool = false
var _time: float = 0.0
var _move_time: float = 1.0
var _from_centre: Vector2 = Vector2.ZERO
var _from_zoom: float = 1.0
## The side the camera leans to: 1 right, -1 left, 0 neither.
var _lean_side: float = 0.0
## How far in the bars are, from 0 to 1.
var _bars_in: float = 0.0
var _bars_tween: Tween
var _bars: CanvasLayer
var _top_bar: ColorRect
var _bottom_bar: ColorRect


func _enter_tree() -> void:
	add_to_group(DialogueBalloon.TALK_WATCHERS)


func _ready() -> void:
	set_physics_process(false)
	_bars = CanvasLayer.new()
	_bars.name = "Bars"
	_bars.layer = BARS_LAYER
	_bars.visible = false
	add_child(_bars)
	_top_bar = _make_bar(Control.PRESET_TOP_WIDE)
	_bottom_bar = _make_bar(Control.PRESET_BOTTOM_WIDE)
	# A window resized mid-talk keeps the bars at their share of the new height.
	get_viewport().size_changed.connect(func() -> void: _set_bars_in(_bars_in))
	if is_instance_valid(camera):
		camera.taken.connect(_on_camera_taken)


func _physics_process(delta: float) -> void:
	if _returning:
		_ease_back(delta)
		return
	if not is_instance_valid(_balloon) or not is_instance_valid(_talker):
		_end_talk()
		return
	_time += delta
	var figures: Rect2 = _figures()
	var room: Rect2 = _room()
	var screen: Vector2 = _screen()
	var level: float = TalkShot.zoom_to_fit(figures, room, max_zoom, min_zoom)
	var centre: Vector2 = TalkShot.centre_for(figures, room, screen, level, _lean_side * lean_share * screen.x)
	centre = camera.centre_to_show(Rect2(centre - screen / (2.0 * level), screen / level), level)
	if _moving:
		var eased: float = TalkShot.ease_along(_time / _move_time)
		camera.zoom = Vector2.ONE * TalkShot.zoom_along(_from_zoom, level, eased)
		camera.global_position = _from_centre.lerp(centre, eased)
		if _time >= _move_time:
			_moving = false
			_time = 0.0
		return
	camera.zoom = Vector2.ONE * level
	camera.global_position = centre
	var side: float = _turn_side()
	if side != _lean_side and _time >= hold_time:
		_lean_side = side
		_start_move(lean_time)


## Called by the balloon as it starts: talker is the node it was added to, who talks to the man.
func talk_began(balloon: DialogueBalloon, talker: Node) -> void:
	if is_instance_valid(_balloon) or not _has_man():
		return
	_balloon = balloon
	_talker = talker as Node2D
	_bars_come_in()
	# A talk that starts while the last one's camera eases back takes it on from there.
	var was_returning: bool = _returning
	_returning = false
	if camera.is_directed():
		return
	_close_hurtbox()
	if reduce_motion or _talker == null:
		if was_returning:
			set_physics_process(false)
			camera.release()
		return
	_man_figure = camera.player.get_node_or_null(^"Sprite") as Node2D
	_talker_figure = _talker.call(&"get_figure") as Node2D if _talker.has_method(&"get_figure") else null
	# Taken on from a way back, the camera's home is still the one from before the last talk, with the man
	# where he was then: kept, so the man's walk since counts on the way back from this one.
	if not was_returning:
		_home_centre = camera.get_home_centre()
		_home_zoom = camera.get_home_zoom()
		_man_at_home = camera.player.global_position
	camera.direct()
	_framing = true
	_lean_side = 0.0
	_start_move(enter_time)
	set_physics_process(true)


## Called by the balloon as it goes: the camera eases back to the man, the bars go and he can be hit.
func talk_finished(balloon: DialogueBalloon) -> void:
	if balloon == _balloon:
		_end_talk()


## True while it has the camera. For the tests.
func is_framing() -> bool:
	return _framing


## True while the camera eases back to the man after a talk. For the tests.
func is_returning() -> bool:
	return _returning


## The height of each bar now, in px of the screen. For the tests.
func get_bar_height() -> float:
	return _bottom_bar.size.y if _bars.visible else 0.0


## How opaque the bars are now, from 0 to 1. For the tests.
func get_bar_alpha() -> float:
	return _bottom_bar.modulate.a if _bars.visible else 0.0


## What figure draws, in the level: a Sprite2D's rect, or an AnimatedSprite2D's frame, with its offset,
## scale and turn. Anything else is a point where it stands.
static func drawn_rect(figure: Node2D) -> Rect2:
	var local: Rect2 = Rect2()
	if figure is Sprite2D:
		local = (figure as Sprite2D).get_rect()
	elif figure is AnimatedSprite2D:
		var sprite: AnimatedSprite2D = figure as AnimatedSprite2D
		var texture: Texture2D = null
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
			texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if texture != null:
			var size: Vector2 = texture.get_size()
			local = Rect2(sprite.offset - (size / 2.0 if sprite.centered else Vector2.ZERO), size)
	return figure.global_transform * local


func _has_man() -> bool:
	return is_instance_valid(camera) and is_instance_valid(camera.player)


## Starts the camera's way back to the man, letting a cutscene take it meanwhile; takes the bars out and
## opens the hurtbox this talk closed, unless a cutscene has the camera, and so the man, now: its end opens it.
func _end_talk() -> void:
	_balloon = null
	_talker = null
	_man_figure = null
	_talker_figure = null
	_moving = false
	set_physics_process(false)
	if _framing and _has_man():
		_returning = true
		camera.let_be_taken()
		_start_move(return_time)
		set_physics_process(true)
	_framing = false
	if is_instance_valid(_hurtbox) and not (is_instance_valid(camera) and camera.is_directed()):
		_hurtbox.set_closed(false)
	_hurtbox = null
	if is_inside_tree():
		_bars_go_out()


## One step of the way back: to where the camera was on the man before the talk, moved as far as he moved,
## and to its zoom then; at the end, the camera is given back.
func _ease_back(delta: float) -> void:
	if not _has_man():
		_returning = false
		set_physics_process(false)
		return
	_time += delta
	var eased: float = TalkShot.ease_along(_time / _move_time)
	var screen: Vector2 = _screen()
	var home: Vector2 = _home_centre + camera.player.global_position - _man_at_home
	home = camera.centre_to_show(Rect2(home - screen / (2.0 * _home_zoom), screen / _home_zoom), _home_zoom)
	camera.zoom = Vector2.ONE * TalkShot.zoom_along(_from_zoom, _home_zoom, eased)
	camera.global_position = _from_centre.lerp(home, eased)
	if _time >= _move_time:
		_returning = false
		set_physics_process(false)
		camera.release()


## A cutscene took the camera on the way back: it is the cutscene's now.
func _on_camera_taken() -> void:
	if _returning:
		_returning = false
		set_physics_process(false)


func _start_move(time: float) -> void:
	_moving = true
	_time = 0.0
	_move_time = time
	_from_centre = camera.global_position
	_from_zoom = camera.zoom.x


## The man and who talks to him, as one rect in the level. A talker with no get_figure() counts as where
## she stands.
func _figures() -> Rect2:
	return _drawn_rect_of(_man_figure, camera.player).merge(_drawn_rect_of(_talker_figure, _talker))


func _drawn_rect_of(figure: Node2D, stand_in: Node2D) -> Rect2:
	return drawn_rect(figure) if is_instance_valid(figure) else Rect2(stand_in.global_position, Vector2.ZERO)


## The part of the screen the figures may take: under the wheel by Head Gap, over where the bottom bar ends by
## Feet Gap (whether or not the bars show, so the shot is the same), and Side Gap in from each side.
func _room() -> Rect2:
	var screen: Vector2 = _screen()
	var top: float = _balloon.get_answers_rect().end.y + head_gap
	var bottom: float = maxf(top + 1.0, screen.y * (1.0 - bar_share) - feet_gap)
	return Rect2(side_gap, top, screen.x - 2.0 * side_gap, bottom - top)


func _screen() -> Vector2:
	return camera.get_viewport_rect().size


## The side of whoever has the turn, seen from the man: the talker's while she speaks, his own once the
## answers show. 0 with the two in the same place.
func _turn_side() -> float:
	var talker: Node2D = _talker_figure if is_instance_valid(_talker_figure) else _talker
	var talker_side: float = signf(talker.global_position.x - camera.player.global_position.x)
	return -talker_side if _balloon.is_mans_turn() else talker_side


## Closes the man's hurtbox if it is open; one something else closed, as a demon's hold, is left to it.
func _close_hurtbox() -> void:
	for child: Node in camera.player.get_children():
		if child is Hurtbox:
			if not (child as Hurtbox).is_closed():
				_hurtbox = child as Hurtbox
				_hurtbox.set_closed(true)
			return


func _make_bar(preset: Control.LayoutPreset) -> ColorRect:
	var bar: ColorRect = ColorRect.new()
	bar.color = bars_color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.add_child(bar)
	bar.set_anchors_and_offsets_preset(preset)
	return bar


func _bars_come_in() -> void:
	if show_bars:
		_tween_bars(1.0, bars_fade_time if reduce_motion else bars_in_time, Tween.EASE_OUT)


func _bars_go_out() -> void:
	if _bars_in > 0.0:
		_tween_bars(0.0, bars_fade_time if reduce_motion else bars_out_time, Tween.EASE_IN)


func _tween_bars(to: float, time: float, easing: Tween.EaseType) -> void:
	if _bars_tween != null:
		_bars_tween.kill()
	_bars_tween = create_tween()
	_bars_tween.set_trans(Tween.TRANS_LINEAR if reduce_motion else Tween.TRANS_CUBIC).set_ease(easing)
	_bars_tween.tween_method(_set_bars_in, _bars_in, to, time)


## Draws the bars amount of the way in: sliding, at that share of their height, or, with Reduce Motion, at
## their whole height and that opaque.
func _set_bars_in(amount: float) -> void:
	_bars_in = amount
	var height: float = bar_share * _screen().y * (1.0 if reduce_motion else amount)
	_top_bar.offset_top = 0.0
	_top_bar.offset_bottom = height
	_bottom_bar.offset_top = -height
	_bottom_bar.offset_bottom = 0.0
	var alpha: float = amount if reduce_motion else 1.0
	_top_bar.modulate.a = alpha
	_bottom_bar.modulate.a = alpha
	_bars.visible = amount > 0.0
