# Checks the autoload Offers with the real catalog, Moral and GameState. Accepting says accepted
# once and counts the temptation once, however often he says yes. Refusing says refused and counts
# each refusal, and, after present(), how long he listened. An id missing from the catalog says
# nothing and does nothing but count in Moral, with warnings. A shortcut accepted with a balloon
# showing asks for its phase only when the balloon closes; with none, at once, with the phase and
# the arrival point of its data. The first upgrade, whichever it is, costs the crucifix in GameState
# and the one in the man's hands in a level; a second keeps both lost. Moral and GameState are reset
# before and after each case. Two warnings are printed on purpose, for the unknown offer.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_offers.gd
extends "res://tests/support/player_test.gd"

const SHORTCUT: StringName = &"lust_shortcut"
const CHARM: StringName = &"charm"
const CLAIM: StringName = &"claim"
const PHASE_3_PATH: String = "res://scenes/levels/lust/LustLevel_Phase3.tscn"
const TENT: StringName = &"asmodeus_tent"
const TEST_ROOM: PackedScene = preload("res://scenes/levels/test_room.tscn")
## Seconds he listens before refusing, in the listening case, on a clock of the test's own.
const LISTEN_SECONDS: float = 4.5

var _offers: GameOffers
var _moral: GameMoral
var _progress: GameProgress


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	_moral = root.get_node_or_null(^"Moral") as GameMoral
	_progress = root.get_node_or_null(^"GameState") as GameProgress
	_offers = root.get_node_or_null(^"Offers") as GameOffers
	if _offers == null:
		print("Offers is not an autoload yet, so the test puts one in the tree.")
		_offers = GameOffers.new()
		_offers.name = &"Offers"
		root.add_child(_offers)
	var results: Array[bool] = []
	results.append(_accepting_says_so_and_counts_once())
	results.append(_refusing_counts_each_refusal_and_the_listening())
	results.append(_an_unknown_offer_only_counts_in_moral())
	results.append(_a_shortcut_waits_for_the_balloon_to_close())
	results.append(_without_a_balloon_a_shortcut_asks_at_once())
	results.append(_the_first_upgrade_costs_the_crucifix())
	results.append(await _the_crucifix_in_his_hands_goes_with_the_first_upgrade())
	_clean()
	finish(results)


func _clean() -> void:
	_progress.reset()
	_offers.clear()


func _accepting_says_so_and_counts_once() -> bool:
	_clean()
	var said: Array[StringName] = []
	var listen: Callable = func(offer: OfferData) -> void: said.append(offer.id)
	_offers.accepted.connect(listen)
	_offers.accept(&"greed_toll_1")
	_offers.accept(&"greed_toll_1")
	var points: float = _moral_points()
	_offers.accepted.disconnect(listen)
	var expected: Array[StringName] = [&"greed_toll_1"]
	var weight: float = GameOffers.get_catalog().find(&"greed_toll_1").moral_weight
	_clean()
	return report(said == expected and is_equal_approx(points, weight),
			"A toll accepted twice: accepted said %s, %s points, its weight %s"
			% [said, points, weight])


func _refusing_counts_each_refusal_and_the_listening() -> bool:
	_clean()
	var said: Array[StringName] = []
	var listen: Callable = func(offer: OfferData) -> void: said.append(offer.id)
	_offers.refused.connect(listen)
	var now: Array[int] = [0]
	var real_clock: Callable = _offers.clock
	_offers.clock = func() -> int: return now[0]
	_offers.refuse(SHORTCUT)
	var unheard: float = _moral.get_listening_seconds(SHORTCUT)
	_offers.present(SHORTCUT)
	now[0] += roundi(LISTEN_SECONDS * GameOffers.MS_PER_SECOND)
	_offers.refuse(SHORTCUT)
	var heard: float = _moral.get_listening_seconds(SHORTCUT)
	_offers.clock = real_clock
	_offers.refused.disconnect(listen)
	var refusals: int = _moral.get_refusal_count(SHORTCUT)
	var taken: bool = _moral.has_taken(SHORTCUT)
	_clean()
	var expected: Array[StringName] = [SHORTCUT, SHORTCUT]
	return report(said == expected and refusals == 2 and is_zero_approx(unheard)
			and is_equal_approx(heard, LISTEN_SECONDS) and not taken,
			"Refused twice, once after listening: refused said %s, %d refusals, %s s then %s s, taken %s"
			% [said, refusals, unheard, heard, taken])


func _an_unknown_offer_only_counts_in_moral() -> bool:
	_clean()
	print("Warnings about test_unknown follow, on purpose.")
	var said: Array[int] = [0]
	var listen: Callable = func(_offer: OfferData) -> void: said[0] += 1
	_offers.accepted.connect(listen)
	_offers.accept(&"test_unknown")
	_offers.accepted.disconnect(listen)
	var points: float = _moral_points()
	_clean()
	return report(said[0] == 0 and points > 0.0,
			"An unknown offer: accepted said %d times, %s points in Moral" % [said[0], points])


func _a_shortcut_waits_for_the_balloon_to_close() -> bool:
	_clean()
	var asked: Array = []
	var listen: Callable = func(path: String, arrival: StringName) -> void:
		asked.append([path, arrival])
	_offers.scene_requested.connect(listen)
	var dialogue_manager: Node = root.get_node(^"DialogueManager")
	dialogue_manager.dialogue_started.emit(null)
	_offers.accept(SHORTCUT)
	var during: int = asked.size()
	dialogue_manager.dialogue_ended.emit(null)
	_offers.scene_requested.disconnect(listen)
	_clean()
	return report(during == 0 and asked == [[PHASE_3_PATH, TENT]],
			"The shortcut with a balloon: %d asks while it shows, then %s" % [during, asked])


func _without_a_balloon_a_shortcut_asks_at_once() -> bool:
	_clean()
	var asked: Array = []
	var listen: Callable = func(path: String, arrival: StringName) -> void:
		asked.append([path, arrival])
	_offers.scene_requested.connect(listen)
	_offers.accept(SHORTCUT)
	_offers.scene_requested.disconnect(listen)
	_clean()
	return report(asked == [[PHASE_3_PATH, TENT]],
			"The shortcut with no balloon asks at once: %s" % [asked])


func _the_first_upgrade_costs_the_crucifix() -> bool:
	_clean()
	var granted: Array[StringName] = []
	var listen: Callable = func(id: StringName) -> void: granted.append(id)
	_progress.upgrade_granted.connect(listen)
	var held_before: bool = _progress.has_crucifix
	_offers.accept(CLAIM)
	var held_after_first: bool = _progress.has_crucifix
	_offers.accept(CHARM)
	_progress.upgrade_granted.disconnect(listen)
	var both: bool = _progress.has_upgrade(CLAIM) and _progress.has_upgrade(CHARM)
	var saved: Dictionary = _progress.to_save()
	_progress.reset()
	_progress.from_save(saved)
	var kept: bool = _progress.has_upgrade(CLAIM) and not _progress.has_crucifix
	_clean()
	var expected: Array[StringName] = [CLAIM, CHARM]
	return report(held_before and not held_after_first and both and granted == expected and kept,
			"Claim, then charm: crucifix %s, then %s; both kept %s, said %s; after a save %s"
			% [held_before, held_after_first, both, granted, kept])


func _the_crucifix_in_his_hands_goes_with_the_first_upgrade() -> bool:
	_clean()
	var level: Level = TEST_ROOM.instantiate() as Level
	root.add_child(level)
	await wait_frames(2)
	var crucifix: Crucifix = level.player.get_node_or_null(^"Crucifix") as Crucifix
	var had_one: bool = is_instance_valid(crucifix)
	_offers.accept(CHARM)
	await wait_frames(2)
	var gone: bool = not is_instance_valid(crucifix)
	level.queue_free()
	await process_frame
	_clean()
	return report(had_one and gone, "The test room: a crucifix in his hands %s, gone after the charm %s"
			% [had_one, gone])


## The moral record's total, read through a copy of what Moral would save.
func _moral_points() -> float:
	var record: MoralRecord = MoralRecord.new(GameMoral.STATS, GameOffers.get_catalog())
	record.from_save(_moral.to_save())
	return record.get_points()
