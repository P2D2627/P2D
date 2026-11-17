extends RefCounted
## PROTOTYPE (#257, mode B): light that spreads through the cave instead of shining in straight
## lines, as tile games do. The level is a grid of solid and open tiles; light leaves its cell and
## loses strength with the length of the path it takes through open cells, so it turns corners and
## fills the room it is in. Entering a
## solid cell costs Rock Cost steps, so the light reaches only a little way into the rock and lights
## its faces. The path length comes from a chamfer distance: sweeps forward and back over the patch
## around the light, each cell taking the shortest step from the neighbours already swept.

const DIAGONAL: float = 1.41421


## Solid tiles of the layer as bytes, 1 for rock, over its used rectangle; one-way platforms (any
## alternative tile other than 0) count as open.
static func build_grid(tiles: TileMapLayer) -> Dictionary:
	var rect: Rect2i = tiles.get_used_rect()
	var grid := PackedByteArray()
	grid.resize(rect.size.x * rect.size.y)
	for cell: Vector2i in tiles.get_used_cells():
		if tiles.get_cell_alternative_tile(cell) == 0:
			grid[(cell.y - rect.position.y) * rect.size.x + (cell.x - rect.position.x)] = 1
	return {"grid": grid, "rect": rect}


## The light, 0 to 1, in each cell of the square patch of side 2 Radius + 1 around Center. Cells are
## Factor to a tile, and Center counts cells from the grid's corner; outside the grid is rock.
static func spread(grid: PackedByteArray, grid_size: Vector2i, factor: int, center: Vector2i,
		radius: int, rock_cost: float, passes: int) -> PackedFloat32Array:
	var size: int = radius * 2 + 1
	var count: int = size * size
	var cost := PackedFloat32Array()
	cost.resize(count)
	var corner := center - Vector2i(radius, radius)
	for py: int in size:
		var tile_y: int = (corner.y + py) / factor
		for px: int in size:
			var tile_x: int = (corner.x + px) / factor
			var solid: bool = tile_x < 0 or tile_y < 0 or tile_x >= grid_size.x or tile_y >= grid_size.y \
					or grid[tile_y * grid_size.x + tile_x] == 1
			cost[py * size + px] = rock_cost if solid else 1.0
	var dist := PackedFloat32Array()
	dist.resize(count)
	dist.fill(INF)
	dist[radius * size + radius] = 0.0
	for pass_index: int in passes:
		for y: int in size:
			for x: int in size:
				var i: int = y * size + x
				var step: float = cost[i]
				var best: float = dist[i]
				if x > 0:
					best = minf(best, dist[i - 1] + step)
				if y > 0:
					best = minf(best, dist[i - size] + step)
					if x > 0:
						best = minf(best, dist[i - size - 1] + step * DIAGONAL)
					if x < size - 1:
						best = minf(best, dist[i - size + 1] + step * DIAGONAL)
				dist[i] = best
		for y: int in range(size - 1, -1, -1):
			for x: int in range(size - 1, -1, -1):
				var i: int = y * size + x
				var step: float = cost[i]
				var best: float = dist[i]
				if x < size - 1:
					best = minf(best, dist[i + 1] + step)
				if y < size - 1:
					best = minf(best, dist[i + size] + step)
					if x < size - 1:
						best = minf(best, dist[i + size + 1] + step * DIAGONAL)
					if x > 0:
						best = minf(best, dist[i + size - 1] + step * DIAGONAL)
				dist[i] = best
	var light := PackedFloat32Array()
	light.resize(count)
	for i: int in count:
		var t: float = dist[i] / float(radius)
		light[i] = 0.0 if t >= 1.0 else (1.0 - t) * (1.0 - t)
	return light
