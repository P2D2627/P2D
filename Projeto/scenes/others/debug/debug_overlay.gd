class_name DebugOverlay
extends CanvasLayer

## Text in a corner of the screen that helps tune the game while playing, in pages. The Toggle Debug
## Overlay action (F3) goes to the next page: hidden, numbers, lighting and shaders, and hidden
## again. Each page shows its name and the next one above its text, and the page chosen with F3 stays
## through a restart of the same level, as after a death. The numbers page has the numbers
## of the man, the camera and the run; the lighting page has the lighting rig's settings, from the
## node in Lighting Group, and passes it the keys, so they change the light only there. Debug Damage
## hurts the player. Debug Accept Offer and Debug Refuse Offer answer the last offer made, or the
## first not yet accepted, as the lines would, so a shortcut or a gift can be tried without playing
## up to it; Debug Reset Run starts the run state over, offers and moral record included. On the
## numbers page, Debug Phase 1 to 3 (the keys 1 to 3) start the level over at that phase
## (Level.jump_to_phase); on the other pages, or in a level of one phase, as the gym and its
## stations, the keys go on to the game. Debug God Mode (F1) and Debug Noclip (F2) turn the man's two
## cheats on and off (#273), also with the text hidden and while paused, and a label of their own
## shows while either is on; on the lighting page the rig gets F1 and F2 first, as its other keys.
## They stay on in the next copy of the level, as after a death or a jump to a phase, until pressed
## again. Outside debug builds it frees itself, so a release export never shows it and nothing
## happens through it, the lighting keys and the cheats included. Its scene sets the process mode to
## Always, so it keeps working while the game is paused.

## The pages, in the order Toggle Debug Overlay goes through them.
enum Page { HIDDEN, NUMBERS, LIGHTING }

const TOGGLE_ACTION: StringName = &"toggle_debug_overlay"
const DAMAGE_ACTION: StringName = &"debug_damage"
const GOD_MODE_ACTION: StringName = &"debug_god_mode"
const NOCLIP_ACTION: StringName = &"debug_noclip"
## What the cheats' label says for each, and between the two when both are on.
const GOD_MODE_TEXT: String = "GOD MODE"
const NOCLIP_TEXT: String = "NOCLIP"
const CHEAT_SEPARATOR: String = "   "
# TEMPORARY, debug only: Debug Accept Offer (F7), Debug Refuse Offer (F8) and Debug Reset Run (F9)
# try the offers before the lines reach them in play. Once every offer is answered in its
# .dialogue and the levels lead up to it, remove them: these three constants, their branches in
# _unhandled_input, _answer_offer, _offer_to_answer, the three actions in project.godot, F7 to F9
# in RESERVED_KEYS of scenes/autoload/input_profiles.gd, and their rows in the README.
const ACCEPT_OFFER_ACTION: StringName = &"debug_accept_offer"
const REFUSE_OFFER_ACTION: StringName = &"debug_refuse_offer"
const RESET_RUN_ACTION: StringName = &"debug_reset_run"
## Debug Phase 1, 2 and 3, in that order: the phase is the place in the list plus one.
const PHASE_ACTIONS: Array[StringName] = [&"debug_phase_1", &"debug_phase_2", &"debug_phase_3"]
const MS_PER_SECOND: float = 1000.0
const SECONDS_PER_MINUTE: int = 60
## The group of the node that gives the lighting page its text and takes its keys, the lighting
## rig. Such a node has get_debug_text() -> String, and handle_debug_key(event: InputEvent) -> bool,
## true if the key changed a setting.
const LIGHTING_GROUP: StringName = &"debug_lighting"
## Above each shown page: its name, then where F3 goes next.
const PAGE_TITLES: Dictionary[Page, String] = {
	Page.NUMBERS: "numbers   (F3: lighting and shaders)",
	Page.LIGHTING: "lighting and shaders   (F3: hide)",
}
## The lighting page's text in a level with no lighting rig.
const NO_LIGHTING_TEXT: String = "no lighting rig in this level"
## Frames between two looks for the lighting rig while the lighting page shows without one: a level
## with no rig has none to find, and a level adds its rig after its overlay is ready.
const LIGHTING_LOOKUP_FRAMES: int = 30

## The page last chosen with F3 in this session, and the scene of the level it was chosen in: a new
## copy of that level, as after a death or a jump to a phase, opens on that page. An overlay that is
## not in a level's scene never takes it.
static var _chosen_page: Page = Page.HIDDEN
static var _chosen_in: String = ""
## Whether God Mode (F1) and Noclip (F2) are on. Static, so they outlive the overlay: a death or a
## jump to a phase starts the level over as a new copy, with a new overlay and a new man, and each
## overlay gives them to its man as it gets ready. Only F1 and F2 change them, and the tests.
static var god_mode: bool = false
static var noclip: bool = false

## On, the overlay starts on the numbers page; off, hidden.
@export var start_visible: bool = true
## SP a press of Debug Damage takes from the player, as a hit would, so the regeneration and the
## warnings can be tried before anything in the game hurts.
@export_range(0.0, 100.0, 1.0, "suffix:SP") var debug_damage: float = 10.0
## The player whose state, velocity, SP and jumps the text shows. Without one, the text has only the
## frame rate and frame times.
@export var player: Player
## The camera whose zone, look ahead and look down the text shows. Without one, there is no camera
## line.
@export var camera: GameCamera
## How fast the man flies in noclip (F2), in px/s.
@export_range(100.0, 4000.0, 10.0, "suffix:px/s") var noclip_speed: float = (
		Player.DEFAULT_NOCLIP_SPEED)

## The last jump, as text, kept until the next one: what it jumped off and the tolerance frames it
## used. Empty until the first jump.
var _last_jump: String = ""
## The y the last jump took off from, and the smallest y it has reached since, in px.
var _take_off_y: float = 0.0
var _peak_y: float = 0.0
var _page: Page = Page.HIDDEN
## The node in Lighting Group, kept once found; null until then.
var _lighting: Node = null
## Frames left before the next look for the lighting rig; 0 looks at the next need.
var _frames_to_lookup: int = 0

@onready var _page_label: Label = %PageLabel
@onready var _label: Label = %Label
## The cheats' label, empty while both are off. It is on a layer of its own: hiding the overlay's
## layer does not reach another one, so it shows with the text hidden.
@onready var _cheat_label: Label = %CheatLabel
@onready var _offers: GameOffers = get_node_or_null(^"/root/Offers") as GameOffers
@onready var _moral: GameMoral = get_node_or_null(^"/root/Moral") as GameMoral
@onready var _progress: GameProgress = get_node_or_null(^"/root/GameState") as GameProgress
@onready var _run_stats: GameRunStats = get_node_or_null(^"/root/RunStats") as GameRunStats
## The level's ActivityTracker, which its camera has; without one, there is no activity line.
@onready var _activity: ActivityTracker = get_tree().get_first_node_in_group(
		ActivityTracker.TRACKER_GROUP) as ActivityTracker


func _ready() -> void:
	if not _is_debug_build():
		queue_free()
		return
	var level_scene: String = _level_scene()
	if not level_scene.is_empty() and level_scene == _chosen_in:
		show_page(_chosen_page)
	else:
		show_page(Page.NUMBERS if start_visible else Page.HIDDEN)
	# _physics_process only follows a jump up, so it starts off.
	set_physics_process(false)
	if is_instance_valid(player):
		player.jumped.connect(_on_jumped)
		player.wall_jumped.connect(_on_wall_jumped)
	_give_the_cheats()


## On the lighting page, the lighting rig gets each key first, F3 alone excepted. Shortcut input
## runs before any unhandled input, so neither a line on screen nor the debug actions on the same F
## keys (F4, F7 to F9, which also take their key with Ctrl held) take them: the rig keeps the keys
## it had when it read them itself, before the overlay had pages. A key it does not use goes on.
func _shortcut_input(event: InputEvent) -> void:
	if (_page == Page.LIGHTING and not event.is_action(TOGGLE_ACTION, true)
			and _lighting_takes(event)):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		show_page(((_page + 1) % Page.size()) as Page)
		_chosen_page = _page
		_chosen_in = _level_scene()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(DAMAGE_ACTION):
		_hurt_player()
		get_viewport().set_input_as_handled()
	elif _is_pressed(event, GOD_MODE_ACTION):
		god_mode = not god_mode
		_give_the_cheats()
		get_viewport().set_input_as_handled()
	elif _is_pressed(event, NOCLIP_ACTION):
		noclip = not noclip
		_give_the_cheats()
		get_viewport().set_input_as_handled()
	elif _is_pressed(event, ACCEPT_OFFER_ACTION):
		_answer_offer(true)
		get_viewport().set_input_as_handled()
	elif _is_pressed(event, REFUSE_OFFER_ACTION):
		_answer_offer(false)
		get_viewport().set_input_as_handled()
	elif _is_pressed(event, RESET_RUN_ACTION) and _progress != null:
		_progress.reset()
		if _offers != null:
			_offers.clear()
		get_viewport().set_input_as_handled()
	elif _page == Page.NUMBERS and _jump_to_phase(event):
		get_viewport().set_input_as_handled()


## Rewrites the text on every frame while it shows, with new strings each time, which only debug
## builds pay for. The lighting page is the rig's text. On the numbers page, each section is its
## own function. The player's sections need a player that still exists, and the camera's a camera:
## none may be linked, or it may have been freed. The activity section needs the level's
## ActivityTracker. The offers' section is about his run, so it shows with a player too, and with
## the autoloads Offers and Moral; the run's numbers, with a player and the autoload RunStats.
func _process(_delta: float) -> void:
	if _page == Page.LIGHTING:
		_frames_to_lookup = maxi(_frames_to_lookup - 1, 0)
		_label.text = _lighting_text()
		return
	var text: String = _performance_section()
	if is_instance_valid(player):
		text += "\n" + _player_section()
	if is_instance_valid(player) and is_instance_valid(player.soul_points):
		text += "\n" + _soul_points_section()
	if is_instance_valid(camera):
		text += "\n" + _camera_section()
	if is_instance_valid(_activity):
		text += "\n" + _activity_section()
	if is_instance_valid(player) and not _last_jump.is_empty():
		text += "\n" + _jump_section()
	if is_instance_valid(player) and _offers != null and _moral != null:
		text += "\n" + _offers_section()
	if is_instance_valid(player) and _run_stats != null:
		text += "\n" + _run_section()
	_label.text = text


## Follows the last jump up, one physics frame at a time, and stops once it no longer rises: its
## peak is the smallest y on the way.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		set_physics_process(false)
		return
	_peak_y = minf(_peak_y, player.global_position.y)
	if player.velocity.y >= 0.0:
		set_physics_process(false)


## Shows page, with its title. While hidden, _process does not run, so the text costs nothing per
## frame. Jumps are still followed up, so the numbers are right as soon as they show again.
func show_page(page: Page) -> void:
	_page = page
	var shown: bool = page != Page.HIDDEN
	visible = shown
	set_process(shown)
	_page_label.text = PAGE_TITLES.get(page, "")
	_frames_to_lookup = 0


func get_page() -> Page:
	return _page


## Takes Debug Damage SP from the player, as a hit would, unless the game is paused. Works with the
## text hidden too.
func _hurt_player() -> void:
	if get_tree().paused or not is_instance_valid(player) or not is_instance_valid(player.soul_points):
		return
	player.soul_points.take_damage(debug_damage)


## Gives God Mode and Noclip as they are to the man, with Noclip Speed, and names the ones on in
## their label. With no man, as in a scene whose overlay has none, they reach no one, so the label
## says nothing.
func _give_the_cheats() -> void:
	var names: PackedStringArray = []
	if is_instance_valid(player):
		player.god_mode = god_mode
		player.noclip_speed = noclip_speed
		player.noclip = noclip
		if god_mode:
			names.append(GOD_MODE_TEXT)
		if noclip:
			names.append(NOCLIP_TEXT)
	_cheat_label.text = CHEAT_SEPARATOR.join(names)


## Whether the game runs as a debug build, where the overlay works. On its own so a test can answer
## as a release build would, which a debug run can't make OS.is_debug_build() do.
func _is_debug_build() -> bool:
	return OS.is_debug_build()


## Accepts or refuses the offer the debug keys answer, unless the game is paused.
func _answer_offer(accept: bool) -> void:
	var offer: OfferData = _offer_to_answer()
	if get_tree().paused or offer == null:
		return
	if accept:
		_offers.accept(offer.id)
	else:
		_offers.refuse(offer.id)


## The last offer made, or else the first in the catalog not yet accepted; null with no Offers or
## with every offer accepted.
func _offer_to_answer() -> OfferData:
	if _offers == null:
		return null
	if _offers.last_presented != null:
		return _offers.last_presented
	for offer: OfferData in GameOffers.get_catalog().offers:
		if offer != null and not _moral.has_taken(offer.id):
			return offer
	return null


## The phase a Debug Phase key pressed in event asks for; 0 for any other event.
func _phase_of(event: InputEvent) -> int:
	for index: int in PHASE_ACTIONS.size():
		if _is_pressed(event, PHASE_ACTIONS[index]):
			return index + 1
	return 0


## The level that runs starts over at the phase a Debug Phase key in event asks for; true if it
## does. Not a key his controls also give to an action, as a Custom profile can: the man reads his
## actions as they are held, so the key would be both. When it does not, as paused, or in the gym,
## which has one phase, the key goes on to the game.
func _jump_to_phase(event: InputEvent) -> bool:
	var phase: int = _phase_of(event)
	if phase == 0 or _is_a_control(event):
		return false
	var level: Level = get_tree().get_first_node_in_group(Level.GROUP) as Level
	return level != null and level.jump_to_phase(phase)


## Whether event is also one of the actions the controls screen gives the player.
func _is_a_control(event: InputEvent) -> bool:
	for action: StringName in InputProfiles.ACTIONS:
		if event.is_action(action):
			return true
	return false


## Whether event presses action, and false, with no error, while the Input Map lacks it.
func _is_pressed(event: InputEvent, action: StringName) -> bool:
	return InputMap.has_action(action) and event.is_action_pressed(action)


## The lighting rig's text, or that the level has none.
func _lighting_text() -> String:
	var lighting: Node = _lighting_node()
	return lighting.call(&"get_debug_text") as String if lighting != null else NO_LIGHTING_TEXT


## Whether the lighting rig changed a setting with the key in event; false with no rig.
func _lighting_takes(event: InputEvent) -> bool:
	var lighting: Node = _lighting_node()
	return lighting != null and lighting.call(&"handle_debug_key", event) == true


## The node in Lighting Group. While none is kept, looked for at once when the lighting page opens
## and then every Lighting Lookup Frames frames, never on every frame.
func _lighting_node() -> Node:
	if is_instance_valid(_lighting):
		return _lighting
	if _frames_to_lookup > 0:
		return null
	_lighting = get_tree().get_first_node_in_group(LIGHTING_GROUP)
	_frames_to_lookup = LIGHTING_LOOKUP_FRAMES
	return _lighting


## The scene of the level the overlay is in, which owns it; empty outside a level's scene.
func _level_scene() -> String:
	return owner.scene_file_path if owner != null else ""


## Frames per second, and the slowest process step and slowest physics step, all over the last
## second. The engine updates the two times once a second, so a single slow frame shows for a
## whole second. At 60 FPS a frame has 16.6 ms.
func _performance_section() -> String:
	return "%d FPS   worst process %.2f ms   worst physics %.2f ms" % [
			roundi(Engine.get_frames_per_second()),
			_monitor_ms(Performance.TIME_PROCESS),
			_monitor_ms(Performance.TIME_PHYSICS_PROCESS)]


## How many of the ActivityTracker's members are awake: the rest are far off the screen and at
## rest, and cost nothing on a frame.
func _activity_section() -> String:
	return "activity: %d of %d awake" % [_activity.get_awake_count(), _activity.get_member_count()]


## The player's state, by its name in Player.State, and its velocity in px/s. In Godot, y grows
## downwards, so a fall has a positive y and a rise a negative one.
func _player_section() -> String:
	return "state %s   velocity (%+.0f, %+.0f) px/s" % [
			Player.State.find_key(player.get_state()), player.velocity.x, player.velocity.y]


## The man's SP out of Max SP, with a tenth so regeneration shows, the speed regeneration gives, so
## its ramp shows, and whether it is low or has run out.
func _soul_points_section() -> String:
	var soul_points: SoulPoints = player.soul_points
	var status: String = ""
	if soul_points.is_depleted():
		status = "   run out"
	elif soul_points.is_low():
		status = "   low"
	return "SP %.1f / %.0f   regen %.1f SP/s%s" % [soul_points.get_sp(),
			soul_points.get_max_sp(), soul_points.get_regen_rate(), status]


## The camera zone the player is in, or none, and how far the camera leads ahead and down, in px.
func _camera_section() -> String:
	return "camera zone %s   look ahead %+.0f px   look down %+.0f px" % [
			camera.get_zone_name(), camera.get_look_ahead(), camera.get_look_down()]


## The last jump and its peak, in px above where it took off. The peak grows while the jump rises
## and stays once it stops.
func _jump_section() -> String:
	return "%s   peak %.0f px" % [_last_jump, _take_off_y - _peak_y]


## The offer the debug keys answer and whether it was accepted, the moral stage and the points, and
## whether he still holds the crucifix.
func _offers_section() -> String:
	var offer: OfferData = _offer_to_answer()
	var answered: String = "every offer accepted"
	if offer != null:
		answered = "offer %s (%s)   refused %d" % [offer.id,
				"accepted" if _moral.has_taken(offer.id) else "open", _moral.get_refusal_count(offer.id)]
	var crucifix: String = ""
	if _progress != null:
		crucifix = "   crucifix %s" % ("held" if _progress.has_crucifix else "lost")
	return "%s   moral stage %d%s" % [answered, _moral.stage(), crucifix]


## The run's hidden numbers, which the player never sees: the phase he is in, his deaths there, in
## the level and in the run, the zone of his last death, the time in the phase, and the pressure of
## his deaths against the threshold of the next shortcut offer, with the offers' state: waiting at
## their zones, or closed once he took the shortcut.
func _run_section() -> String:
	var pacer: DeathOfferPacer = _run_stats.get_death_offer_pacer()
	var offer: String = "open"
	if pacer.is_closed():
		offer = "closed"
	elif pacer.has_pending():
		var zones: PackedStringArray = []
		for zone: StringName in pacer.get_pending_zones():
			zones.append(String(zone))
		offer = "waits at %s" % ", ".join(zones)
	var last_zone: StringName = _run_stats.last_zone()
	var seconds: int = floori(_run_stats.phase_seconds())
	@warning_ignore("integer_division")
	return ("run phase %d   deaths %d phase, %d level, %d run   last death %s   time %d:%02d   "
			+ "death offer %.1f / %.1f %s") % [_run_stats.get_phase(), _run_stats.deaths_in_phase(),
			_run_stats.deaths_in_level(), _run_stats.total_deaths(),
			last_zone if not last_zone.is_empty() else &"none",
			seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE, pacer.get_pressure(),
			pacer.get_threshold(), offer]


## One of the engine's time monitors, in ms instead of seconds.
func _monitor_ms(monitor: Performance.Monitor) -> float:
	return Performance.get_monitor(monitor) * MS_PER_SECOND


func _on_jumped(late_frames: int, buffered_frames: int) -> void:
	_remember_jump("the floor", late_frames, buffered_frames)


func _on_wall_jumped(late_frames: int, buffered_frames: int) -> void:
	_remember_jump("a wall", late_frames, buffered_frames)


## Keeps what the jump was for the text and starts following it up from where it took off. Each
## tolerance shows as the frames it used out of the frames Stats gives it.
func _remember_jump(jumped_off: String, late_frames: int, buffered_frames: int) -> void:
	var tolerances: PackedStringArray = []
	if late_frames > 0:
		tolerances.append("coyote %d/%d frames late"
				% [late_frames, player.stats.get_coyote_frames()])
	if buffered_frames > 0:
		tolerances.append("buffer %d/%d frames early"
				% [buffered_frames, player.stats.get_jump_buffer_frames()])
	if tolerances.is_empty():
		tolerances.append("on time")
	_last_jump = "jump off %s   %s" % [jumped_off, "   ".join(tolerances)]
	_take_off_y = player.global_position.y
	_peak_y = _take_off_y
	set_physics_process(true)
