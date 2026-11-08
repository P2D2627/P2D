# Checks the offers' data, so a typo in an id or a missing file shows here and not in a playtest.
# Every offer in the catalog has an id, used by no other, who offers it and a Moral Weight above 0.
# Every offer id the .dialogue files name, in Offers.present, accept or refuse and in
# Moral.has_taken, has its offer in the catalog. Each offer the lines accept is also presented and
# can be refused. A shortcut names a phase that exists and an ArrivalPoint that phase has; an
# upgrade names its id.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_offer_catalog.gd
extends "res://tests/support/player_test.gd"

const DIALOGUE_FOLDER: String = "res://dialogue/"
## How the lines name an offer: the function, then the id.
const OFFER_PATTERN: String = ("(Offers\\.present|Offers\\.accept|Offers\\.refuse|Moral\\.has_taken)"
		+ "\\(&\"(\\w+)\"\\)")


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_every_offer_has_its_fields_and_its_own_id())
	results.append(_every_id_in_the_lines_is_in_the_catalog())
	results.append(_every_offer_accepted_is_presented_and_can_be_refused())
	results.append(_every_effect_names_what_it_needs())
	finish(results)


func _every_offer_has_its_fields_and_its_own_id() -> bool:
	var seen: Array[StringName] = []
	var wrong: PackedStringArray = []
	for offer: OfferData in GameOffers.get_catalog().offers:
		if offer == null:
			wrong.append("an empty entry")
			continue
		if offer.id.is_empty() or seen.has(offer.id):
			wrong.append("%s: no id, or used twice" % offer.resource_path)
		if offer.offerer.is_empty():
			wrong.append("%s: no offerer" % offer.id)
		if offer.moral_weight <= 0.0:
			wrong.append("%s: weighs nothing" % offer.id)
		seen.append(offer.id)
	return report(not seen.is_empty() and wrong.is_empty(),
			"The catalog: %d offers, wrong: %s" % [seen.size(), wrong])


func _every_id_in_the_lines_is_in_the_catalog() -> bool:
	var missing: PackedStringArray = []
	var calls: Dictionary[String, Array] = _offer_calls()
	for call: String in calls:
		for id: StringName in calls[call]:
			if not GameOffers.get_catalog().has(id) and not missing.has(String(id)):
				missing.append(String(id))
	return report(not calls.is_empty() and missing.is_empty(),
			"The lines name %d kinds of offer call; ids missing from the catalog: %s"
			% [calls.size(), missing])


func _every_offer_accepted_is_presented_and_can_be_refused() -> bool:
	var calls: Dictionary[String, Array] = _offer_calls()
	var accepted: Array = calls.get("Offers.accept", [])
	var lacking: PackedStringArray = []
	for id: StringName in accepted:
		if not calls.get("Offers.present", []).has(id):
			lacking.append("%s never presented" % id)
		if not calls.get("Offers.refuse", []).has(id):
			lacking.append("%s never refused" % id)
	return report(not accepted.is_empty() and lacking.is_empty(),
			"%d offers accepted in the lines; lacking: %s" % [accepted.size(), lacking])


func _every_effect_names_what_it_needs() -> bool:
	var wrong: PackedStringArray = []
	for offer: OfferData in GameOffers.get_catalog().offers:
		if offer == null or offer.effect == null:
			continue
		if offer.effect is GoToSceneEffect:
			var effect: GoToSceneEffect = offer.effect as GoToSceneEffect
			var scene: PackedScene = load(effect.scene_path) as PackedScene \
					if ResourceLoader.exists(effect.scene_path) else null
			if scene == null:
				wrong.append("%s: no phase at %s" % [offer.id, effect.scene_path])
				continue
			if effect.arrival.is_empty():
				continue
			var level: Node = scene.instantiate()
			if ArrivalPoint.find_in(level, effect.arrival) == null:
				wrong.append("%s: %s has no ArrivalPoint %s" % [offer.id, effect.scene_path,
						effect.arrival])
			level.free()
		elif offer.effect is GrantUpgradeEffect:
			if (offer.effect as GrantUpgradeEffect).upgrade.is_empty():
				wrong.append("%s: an upgrade with no id" % offer.id)
	return report(wrong.is_empty(), "The effects: wrong %s" % [wrong])


## The ids each kind of call names in the .dialogue files, as {"Offers.accept": [ids]}, each once.
func _offer_calls() -> Dictionary[String, Array]:
	var pattern: RegEx = RegEx.create_from_string(OFFER_PATTERN)
	var calls: Dictionary[String, Array] = {}
	for file: String in DirAccess.get_files_at(DIALOGUE_FOLDER):
		if file.get_extension() != "dialogue":
			continue
		var text: String = FileAccess.get_file_as_string(DIALOGUE_FOLDER + file)
		for found: RegExMatch in pattern.search_all(text):
			var ids: Array = calls.get_or_add(found.get_string(1), [])
			var id: StringName = StringName(found.get_string(2))
			if not ids.has(id):
				ids.append(id)
	return calls
