extends RefCounted
## Where a bus's sound goes in the bus layout: the chain of sends from a bus up to Master. A sound
## on a bus of its own still gets the volume option, the ducking and the effects of every bus
## above it, so tests check the route, not just the bus a player names.


## Whether bus is target or sends to it, directly or through other buses. False when bus is not in
## the layout.
static func reaches(bus: StringName, target: StringName) -> bool:
	return target in route(bus)


## The buses a sound on bus goes through, bus first and Master last; empty when bus is not in the
## layout. Godot only lets a bus send to one before it, so the chain always ends.
static func route(bus: StringName) -> Array[StringName]:
	var chain: Array[StringName] = []
	var index: int = AudioServer.get_bus_index(bus)
	while index != -1 and bus not in chain:
		chain.append(bus)
		if index == 0:
			break
		bus = AudioServer.get_bus_send(index)
		index = AudioServer.get_bus_index(bus)
	return chain
