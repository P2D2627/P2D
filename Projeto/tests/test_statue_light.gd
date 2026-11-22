# Checks the light of a gate statue (GateUnlocker) on level 1 with the lighting rig (#284): unlit, the
# statue gives no light; once used, its flame lights the cave round it as a fire does, in the fires'
# colour and fainter than a fire, on the same layers (the world, the backdrop, the man and the rock). As
# the fires' lights, they are off in the rig's other modes and on again back in the lit one.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_statue_light.gd
extends "res://tests/support/base_test.gd"

const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")
const ROOM: PackedScene = preload("res://scenes/levels/prototypes/lighting/lighting_level1.tscn")
## Frames for the level and the rig to set up.
const SETUP_FRAMES: int = 10
const LIT_MASKS: int = LightingRig.MASK_WORLD | LightingRig.MASK_PARALLAX | LightingRig.MASK_MAN


func _initialize() -> void:
	LightingRig.mode = LightingRig.Mode.HYBRID
	var room: Node = ROOM.instantiate()
	root.add_child(room)
	for _frame: int in SETUP_FRAMES:
		await process_frame
	var level: Node = (room.get_rig() as Node).get_parent()
	var statue: GateUnlocker = level.get_node(^"GateUnlockers/UnlockerA") as GateUnlocker
	var results: Array[bool] = []
	var unlit: Array[PointLight2D] = _lights_of(statue)
	results.append(report(not unlit.is_empty() and unlit.all(func(l: PointLight2D) -> bool: return not l.enabled),
			"Unlit: %d lights on the statue, all off %s"
			% [unlit.size(), unlit.all(func(l: PointLight2D) -> bool: return not l.enabled)]))
	statue.activate()
	await process_frame
	var lit: Array[PointLight2D] = _lights_of(statue).filter(func(l: PointLight2D) -> bool: return l.enabled)
	var masks: int = 0
	var problems: Array[String] = []
	for light: PointLight2D in lit:
		masks |= light.range_item_cull_mask
		if not light.color.is_equal_approx(LightingRig.FIRE_COLOR):
			problems.append("colour %s" % light.color)
		if light.energy <= 0.0 or light.energy >= LightingRig.FIRE_ENERGY:
			problems.append("energy %.2f" % light.energy)
	results.append(report(not lit.is_empty() and problems.is_empty()
			and masks == LIT_MASKS | LightingRig.MASK_ROCK,
			"Used: %d lights on, in the fires' colour and fainter than a fire's %.2f (%s), on layers %d (%d)"
			% [lit.size(), LightingRig.FIRE_ENERGY, problems, masks, LIT_MASKS | LightingRig.MASK_ROCK]))
	var rig: Node = room.get_rig() as Node
	for other: LightingRig.Mode in [LightingRig.Mode.CURRENT, LightingRig.Mode.PROPAGATION]:
		rig.set_mode(other)
		var on: int = _lights_of(statue).filter(func(l: PointLight2D) -> bool: return l.enabled).size()
		results.append(report(on == 0, "In mode %s, as the fires: %d of the statue's lights on" % [other, on]))
	rig.set_mode(LightingRig.Mode.HYBRID)
	var back_on: int = _lights_of(statue).filter(func(l: PointLight2D) -> bool: return l.enabled).size()
	results.append(report(back_on == unlit.size(),
			"Back in the lit mode: %d of the used statue's %d lights on" % [back_on, unlit.size()]))
	room.queue_free()
	await process_frame
	quit(0 if not results.has(false) else 1)


func _lights_of(statue: Node) -> Array[PointLight2D]:
	var lights: Array[PointLight2D] = []
	for child: Node in statue.get_children():
		if child is PointLight2D:
			lights.append(child as PointLight2D)
	return lights


func report(passed: bool, what: String) -> bool:
	print(("PASS: " if passed else "FAIL: ") + what)
	return passed
