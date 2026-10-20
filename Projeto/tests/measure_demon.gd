# Prints what chasing demons cost on a physics frame. It puts 10, 50 and 200 demons of demon.tscn on
# the floor, all inside Sight Distance of the man, who stands still with the crucifix down, so every
# one of them chases and attacks him, over and over: the busiest a demon gets. They all start on the
# same frame, so the ones near him start warning on the same frame too, and that is the worst frame.
# Each cost is what the demons add to the same room with no demons, on average and on the worst
# frame. The whole frame: the time from one physics frame to the next, which with --fixed-fps and no
# window waits for nothing, so it takes in the physics server's step over the demons' bodies and
# areas. The scripts, inside it: from a node that runs before every other node's _physics_process to
# one that runs after them all, which takes in the demons' move_and_slide() and rays. The Physics
# time monitor would not do: it keeps one value for many frames, and stays at 0 through the first
# measures, which are over in less than a second. Before the measures, it prints the lunge of
# lust_demon_stats.tres on flat floor and how its demons first attack a man standing still, and with
# each measure, how many demons started their warning on its worst frame. It checks nothing: the
# exit code is 1 only if the player never lands or a demon is not after the man when the measure
# starts. The README quotes the result in the demon's section.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_demon.gd
extends "res://tests/support/player_test.gd"


## Stamps the time of its own _physics_process. With the lowest priority it runs before every other
## node's, and with the highest after them all.
class Stamp extends Node:
	var usec: int = 0

	func _init(priority: int) -> void:
		process_physics_priority = priority

	func _physics_process(_delta: float) -> void:
		usec = Time.get_ticks_usec()


## What a measure found, in us per physics frame, and how many demons started their warning on the
## worst one.
class Cost:
	var frame: float = 0.0
	var worst_frame: float = 0.0
	var scripts: float = 0.0
	var worst_scripts: float = 0.0
	var worst_frame_warnings: int = 0


const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## How many demons chase the man in each measure.
const DEMON_COUNTS: Array[int] = [10, 50, 200]
## Nearest and farthest a demon starts from the man, in px: inside the 480 px Sight Distance of
## lust_demon_stats.tres, so each one sees him at once.
const NEAREST: float = 50.0
const FARTHEST: float = 450.0
## Physics frames left out after the demons are put in, while they land and start after the man.
const SETTLE_FRAMES: int = 30
## Physics frames each measure averages over: five seconds of chasing and attacking.
const MEASURED_FRAMES: int = 300
## The most 50 demons may add to a physics frame on average, in ms: about a quarter above the
## measures with the bite and the lunge of ADR 0020 (1.15 to 1.20 ms over seven runs, 2026-10-20),
## so a change that makes them dearer shows here before 2 ms. A demon after the man costs about
## 23 us a frame and one standing about 10: the cost is the chase, not the attacks.
const AVERAGE_BUDGET_MS: float = 1.5
## The most 50 demons may add to the worst physics frame, in ms: the 2 ms any one system may take
## of a 16.6 ms frame.
const WORST_BUDGET_MS: float = 2.0
## The number of demons the budget is for.
const BUDGET_DEMONS: int = 50
const USEC_PER_MS: float = 1000.0
## Priorities that put a Stamp before or after every other node's _physics_process.
const FIRST: int = -1000000
const LAST: int = 1000000
const FLOOR_HALF_WIDTH: float = 3000.0
## A little above the floor, so the player lands on its own.
const FLOOR_START: Vector2 = Vector2(0.0, -2.0)
## How far left of the man the demon whose lunge is printed starts, in px: inside the Sight Distance
## of lust_demon_stats.tres.
const LUNGE_START: float = 200.0
## Demons that come at the man standing still together, from FARTHEST, each rolling its own chances:
## enough for the share of each attack to show.
const APPROACHES: int = 40
## Physics frames those demons are watched for: two seconds, past their first attack.
const WATCHED_FRAMES: int = 120

## Demons that started their warning since the last physics frame was read.
var _warnings: int = 0


func _initialize() -> void:
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		printerr("The player never landed.")
		quit(1)
		return
	await _print_lunge()
	await _print_attacks()
	var first: Stamp = Stamp.new(FIRST)
	var last: Stamp = Stamp.new(LAST)
	root.add_child(first)
	root.add_child(last)
	var empty: Cost = await _measure(first, last)
	for count: int in DEMON_COUNTS:
		var demons: Array[Demon] = _spawn_demons(count)
		await wait_frames(SETTLE_FRAMES)
		if demons.any(func(demon: Demon) -> bool: return demon.get_state() == Demon.State.IDLE):
			printerr("%d demons: one is not after the man." % count)
			quit(1)
			return
		var cost: Cost = await _measure(first, last)
		var frame: float = cost.frame - empty.frame
		var worst_frame: float = cost.worst_frame - empty.frame
		var scripts: float = cost.scripts - empty.scripts
		var worst_scripts: float = cost.worst_scripts - empty.scripts
		var verdict: String = ""
		if count == BUDGET_DEMONS:
			var within: bool = frame < AVERAGE_BUDGET_MS * USEC_PER_MS \
					and worst_frame < WORST_BUDGET_MS * USEC_PER_MS
			verdict = "; budget %.0f us on average and %.0f us on the worst, %s" % [
					AVERAGE_BUDGET_MS * USEC_PER_MS, WORST_BUDGET_MS * USEC_PER_MS,
					"within" if within else "OVER"]
		print("%d demons after the man: whole frame %.0f us on average, %.0f us on the worst, on which %d started their warning; scripts %.0f and %.0f us%s"
				% [count, frame, worst_frame, cost.worst_frame_warnings, scripts, worst_scripts,
						verdict])
		for demon: Demon in demons:
			demon.queue_free()
		await wait_frames(SETTLE_FRAMES)
	await remove_player(player)
	quit(0)


## count demons on the floor, every other one on each side of the man, from NEAREST to FARTHEST.
func _spawn_demons(count: int) -> Array[Demon]:
	var demons: Array[Demon] = []
	for index: int in count:
		var side: float = 1.0 if index % 2 == 0 else -1.0
		var distance: float = lerpf(NEAREST, FARTHEST, float(index) / count)
		var demon: Demon = DEMON_SCENE.instantiate() as Demon
		demon.position = FLOOR_START + Vector2(side * distance, 0.0)
		demon.state_changed.connect(_on_demon_state_changed)
		root.add_child(demon)
		demons.append(demon)
	return demons


## The whole frame and the scripts' time between the two Stamps, over MEASURED_FRAMES physics
## frames. Each read runs as a physics frame starts, so it reads the frame before, which has run
## whole by then.
func _measure(first: Stamp, last: Stamp) -> Cost:
	var cost: Cost = Cost.new()
	await physics_frame
	var frame_start: int = Time.get_ticks_usec()
	_warnings = 0
	for _frame: int in MEASURED_FRAMES:
		await physics_frame
		var now: int = Time.get_ticks_usec()
		var frame: float = now - frame_start
		frame_start = now
		var scripts: float = last.usec - first.usec
		cost.frame += frame / MEASURED_FRAMES
		if frame > cost.worst_frame:
			cost.worst_frame = frame
			cost.worst_frame_warnings = _warnings
		cost.scripts += scripts / MEASURED_FRAMES
		cost.worst_scripts = maxf(cost.worst_scripts, scripts)
		_warnings = 0
	return cost


## Prints the attack of lust_demon_stats.tres the demon warns of first on flat floor, at the man
## standing still, LUNGE_START away, with every attack's Chance Per Second at 1 for it, so it is the
## lunge, at once: how high it rises and how far it lands from where it warned, with what the attack
## asks of both at a man standing that far, and the time from take-off to the first physics frame
## it stands on the floor again. The chances go back to the file's before the measures.
func _print_lunge() -> void:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.position = FLOOR_START + Vector2(-LUNGE_START, 0.0)
	var chances: PackedFloat64Array = []
	for attack: DemonAttack in demon.stats.attacks:
		chances.append(attack.chance_per_second)
		attack.chance_per_second = 1.0
	var warned_of: Array[DemonAttack] = []
	demon.warning_started.connect(func(attack: DemonAttack) -> void: warned_of.append(attack))
	root.add_child(demon)
	await wait_until(func() -> bool: return demon.get_state() == Demon.State.WARNING)
	var take_off: Vector2 = demon.position
	await wait_until(func() -> bool: return demon.get_state() == Demon.State.LUNGE)
	var start: int = Engine.get_physics_frames()
	var peak_y: float = demon.position.y
	while not demon.is_on_floor():
		peak_y = minf(peak_y, demon.position.y)
		await physics_frame
	var seconds: float = float(Engine.get_physics_frames() - start + 1) \
			/ Engine.physics_ticks_per_second
	var attack: DemonAttack = warned_of[0]
	var asked: float = attack.get_lunge_distance_to(FLOOR_START.x - take_off.x, 0.0)
	print("Attack '%s' of lust_demon_stats.tres: %.2f px up (asked %.1f), lands %.1f px from where it warned (asked %.0f), %.3f s from take-off to standing"
			% [attack.animation, take_off.y - peak_y, attack.get_lunge_height(asked),
					demon.position.x - take_off.x, asked, seconds])
	for index: int in chances.size():
		demon.stats.attacks[index].chance_per_second = chances[index]
	demon.queue_free()
	await wait_frames(SETTLE_FRAMES)


## Prints how APPROACHES demons of lust_demon_stats.tres, put in together FARTHEST from the man
## standing still, first attack him: for each attack, how many started with it, and the nearest and
## farthest from him they did, which with a chance below 1 should spread over the attack's range.
func _print_attacks() -> void:
	var distances: Dictionary[StringName, Array] = {}
	var demons: Array[Demon] = []
	for _approach: int in APPROACHES:
		var demon: Demon = DEMON_SCENE.instantiate() as Demon
		demon.position = FLOOR_START + Vector2(-FARTHEST, 0.0)
		var on_first_warning: Callable = func(attack: DemonAttack) -> void:
			if not distances.has(attack.animation):
				distances[attack.animation] = []
			distances[attack.animation].append(absf(demon.position.x - FLOOR_START.x))
		demon.warning_started.connect(on_first_warning, CONNECT_ONE_SHOT)
		root.add_child(demon)
		demons.append(demon)
	await wait_frames(WATCHED_FRAMES)
	var lines: PackedStringArray = []
	for animation: StringName in distances:
		var from: Array = distances[animation]
		lines.append("%s %d, from %.0f to %.0f px" % [animation, from.size(), from.min(), from.max()])
	print("First attacks of %d demons of lust_demon_stats.tres from %.0f px, at the man standing still: %s"
			% [APPROACHES, FARTHEST, "; ".join(lines)])
	for demon: Demon in demons:
		demon.queue_free()
	await wait_frames(SETTLE_FRAMES)


func _on_demon_state_changed(_previous: Demon.State, current: Demon.State) -> void:
	if current == Demon.State.WARNING:
		_warnings += 1
