extends Node2D

const CELL_SIZE = Vector2i(64, 64)
var astar = AStarGrid2D.new()


func _ready() -> void:
	astar.region = Rect2(Vector2.ZERO, get_parent().planet_size)
	astar.cell_size = CELL_SIZE
	astar.offset = Vector2.ZERO
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()


func world_to_astar_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - astar.offset
	return Vector2i(floor(local.x / astar.cell_size.x), floor(local.y / astar.cell_size.y))

func astar_cell_center(cell: Vector2i) -> Vector2:
	return astar.offset + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * astar.cell_size


func tilemap_cell_to_astar_cells(tile_cell: Vector2i) -> Array:
	var base = tile_cell * 2
	return [
		Vector2i(base.x + 0, base.y + 0),
		Vector2i(base.x + 1, base.y + 0),
		Vector2i(base.x + 0, base.y + 1),
		Vector2i(base.x + 1, base.y + 1),
	]
