class_name DemonDebugView
extends Node2D

## Draws over the room what each of its demons is doing, for trying them out and tuning them while
## playing: above it, the name of its state and the seconds it has been in it, and an arrow the way
## it faces; along its floor, its post and its patrol; while it is after the man or looks for him,
## where it last saw him; and while it sees him, a line to him. It shows and hides with the debug
## overlay, F3. Outside debug builds it frees itself, so a release export never shows it. Only the
## test room has it: a level's demons show only what their art shows. The room sets its process
## mode to Always, so it keeps drawing while the game is paused; its seconds stop with the game.

## How high above its feet the text sits, and the arrow below it, in px: over the 96 px body.
const TEXT_HEIGHT: float = 140.0
const ARROW_HEIGHT: float = 116.0
const ARROW_LENGTH: float = 20.0
const FONT_SIZE: int = 26
const OUTLINE_SIZE: int = 6
## How high the demon's eyes and the man's middle are above their feet, in px: half their bodies,
## where demon.tscn and player.tscn put the sight ray and the body box.
const EYE_HEIGHT: float = 48.0
## The post's mark, the patrol's line and the cross where it last saw the man, in px.
const POST_MARK_HEIGHT: float = 32.0
const LINE_WIDTH: float = 3.0
const CROSS_SIZE: float = 14.0
const TEXT_COLOR: Color = Color(1.0, 1.0, 1.0)
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0)
const POST_COLOR: Color = Color(0.4, 0.8, 1.0)
const PATROL_COLOR: Color = Color(0.4, 0.8, 1.0, 0.5)
const LAST_SEEN_COLOR: Color = Color(1.0, 0.6, 0.1)
const SIGHT_COLOR: Color = Color(1.0, 0.25, 0.25, 0.7)

## The overlay it shows and hides with. Without one, it shows from the start and stays.
@export var overlay: DebugOverlay
## The demons it shows, set in the room.
@export var demons: Array[Demon] = []
## The man the line of sight goes to.
@export var player: Node2D

## Physics frames each demon of demons has been in the state it is in, not counting a pause, as the
## states count their times.
var _frames_in_state: PackedInt32Array = []
var _state_names: PackedStringArray = []
@onready var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	_state_names = PackedStringArray(Demon.State.keys())
	_frames_in_state.resize(demons.size())
	for index: int in demons.size():
		if is_instance_valid(demons[index]):
			demons[index].state_changed.connect(_on_demon_state_changed.bind(index))
	if is_instance_valid(overlay):
		overlay.visibility_changed.connect(_on_overlay_visibility_changed)
		_set_shown(overlay.visible)
	else:
		_set_shown(true)


## Draws again on every frame while it shows, with new strings each time, which only debug builds pay
## for. While hidden, _process does not run, so it draws nothing.
func _process(_delta: float) -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	for index: int in _frames_in_state.size():
		_frames_in_state[index] += 1


## The text above the demon at index in demons: its state and the seconds it has been in it.
func get_text(index: int) -> String:
	var seconds: float = float(_frames_in_state[index]) / Engine.physics_ticks_per_second
	return "%s %.1f s" % [_state_names[demons[index].get_state()], seconds]


func _draw() -> void:
	for index: int in demons.size():
		if is_instance_valid(demons[index]):
			_draw_demon(index)


func _draw_demon(index: int) -> void:
	var demon: Demon = demons[index]
	var feet: Vector2 = to_local(demon.global_position)
	var post: Vector2 = to_local(Vector2(demon.get_post_x(), demon.global_position.y))
	var half_patrol: float = demon.stats.patrol_width / 2.0
	if half_patrol > 0.0:
		draw_line(post - Vector2(half_patrol, 0.0), post + Vector2(half_patrol, 0.0), PATROL_COLOR,
				LINE_WIDTH)
	draw_line(post, post - Vector2(0.0, POST_MARK_HEIGHT), POST_COLOR, LINE_WIDTH)
	if demon.has_target() or demon.get_state() == Demon.State.SEARCH:
		var seen: Vector2 = to_local(Vector2(demon.get_last_seen_x(), demon.global_position.y))
		draw_line(seen + Vector2(-CROSS_SIZE, -CROSS_SIZE), seen + Vector2(CROSS_SIZE, CROSS_SIZE),
				LAST_SEEN_COLOR, LINE_WIDTH)
		draw_line(seen + Vector2(-CROSS_SIZE, CROSS_SIZE), seen + Vector2(CROSS_SIZE, -CROSS_SIZE),
				LAST_SEEN_COLOR, LINE_WIDTH)
	if demon.sees_target() and is_instance_valid(player):
		var eyes: Vector2 = feet - Vector2(0.0, EYE_HEIGHT)
		draw_line(eyes, to_local(player.global_position) - Vector2(0.0, EYE_HEIGHT), SIGHT_COLOR,
				LINE_WIDTH)
	var facing: float = demon.get_facing()
	var tip: Vector2 = feet - Vector2(-facing * ARROW_LENGTH, ARROW_HEIGHT)
	draw_line(tip - Vector2(2.0 * facing * ARROW_LENGTH, 0.0), tip, TEXT_COLOR, LINE_WIDTH)
	draw_line(tip, tip + Vector2(-facing, -1.0) * ARROW_LENGTH / 2.0, TEXT_COLOR, LINE_WIDTH)
	draw_line(tip, tip + Vector2(-facing, 1.0) * ARROW_LENGTH / 2.0, TEXT_COLOR, LINE_WIDTH)
	var text: String = get_text(index)
	var width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var at: Vector2 = feet - Vector2(width / 2.0, TEXT_HEIGHT)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, OUTLINE_SIZE,
			OUTLINE_COLOR)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)


func _set_shown(shown: bool) -> void:
	visible = shown
	set_process(shown)


func _on_overlay_visibility_changed() -> void:
	_set_shown(overlay.visible)


func _on_demon_state_changed(_previous: Demon.State, _current: Demon.State, index: int) -> void:
	_frames_in_state[index] = 0
