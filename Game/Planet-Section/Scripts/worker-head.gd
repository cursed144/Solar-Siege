extends Node2D

const CELL_SIZE = Vector2i(32, 32)

var astar = AStarGrid2D.new()
var job_list: Array[WorkController]

@onready var grid = %Buildings.tile_set.tile_size
@onready var ratio = grid.x / CELL_SIZE.x


func _ready() -> void:
	astar.region = Rect2(Vector2.ZERO, get_parent().planet_size)
	astar.cell_size = CELL_SIZE
	astar.offset = Vector2.ZERO
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()


func add_job(job: WorkController) -> void:
	print("Job added to building: " + str(job.building.name))
	job_list.append(job)
	give_job_to_worker()


func get_from_available_jobs() -> WorkController:
	if job_list.is_empty():
		return null
	
	return job_list.pop_front()


func give_job_to_worker() -> void:
	for worker in get_children():
		if not is_instance_valid(worker.current_job): # free
			worker.get_job()
			break


func remove_job(job: WorkController) -> void:
	job_list.erase(job)


func set_tilemap_tile_solid(tile: Vector2i, is_solid := true) -> void:
	var corner: Vector2i = tile * ratio
	
	for i in range(ratio):
		for j in range(ratio):
			astar.set_point_solid(corner + Vector2i(i, j), is_solid)
	
	refresh_worker_paths()


func set_building_tiles_solid(origin_point: Vector2, size: Vector2i, is_solid := true) -> void:
	var cell := %Buildings.local_to_map(origin_point) as Vector2i
	size /= grid
	
	for i in range(size.x):
		for j in range(size.y):
			cell = %Buildings.local_to_map(
				Vector2(origin_point.x + (grid.x * i),
						origin_point.y + (grid.y * j)) ) as Vector2i
			set_tilemap_tile_solid(cell, is_solid)


func refresh_worker_paths() -> void:
	for worker in get_children():
		worker.set_astar_path(worker.destination)
