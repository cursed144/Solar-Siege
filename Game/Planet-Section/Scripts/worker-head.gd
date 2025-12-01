extends Node2D

const CELL_SIZE = Vector2i(64, 64)
var astar = AStarGrid2D.new()
@onready var ratio = %Buildings.tile_set.tile_size.x / CELL_SIZE.x


func _ready() -> void:
	astar.region = Rect2(Vector2.ZERO, get_parent().planet_size)
	astar.cell_size = CELL_SIZE
	astar.offset = Vector2.ZERO
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

func set_tilemap_tile_solid(tile: Vector2i) -> void:
	var corner: Vector2i = tile * ratio
	
	for i in range(ratio):
		for j in range(ratio):
			astar.set_point_solid(corner + Vector2i(i, j))
	
	refresh_worker_paths()


func refresh_worker_paths() -> void:
	for worker in get_children():
		worker.set_astar_path(worker.destination)


func world_to_astar_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - astar.offset
	return Vector2i(floor(local.x / astar.cell_size.x), floor(local.y / astar.cell_size.y))

func astar_cell_center(cell: Vector2i) -> Vector2:
	return astar.offset + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * astar.cell_size
