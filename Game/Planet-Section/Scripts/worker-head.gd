extends Node2D

const CELL_SIZE = Vector2i(32, 32)

var astar = AStarGrid2D.new()
var job_list: Array[WorkController]
var grid: Vector2i
var ratio: float


func _ready() -> void:
	grid = %Buildings.grid_size
	ratio = grid.x / float(CELL_SIZE.x)
	
	astar.region = Rect2i(
		Vector2i.ZERO,
		Vector2i(
			ceili(get_parent().planet_size.x / float(CELL_SIZE.x)),
			ceili(get_parent().planet_size.y / float(CELL_SIZE.y))
		)
	)
	astar.cell_size = CELL_SIZE
	astar.offset = Vector2.ZERO
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	
	await get_tree().process_frame
	for building: Building in %Buildings.get_children():
		var sprite: Sprite2D = building.get_node("Sprite2D")
		var rect: Rect2 = sprite.get_rect()
		var top_left: Vector2 = sprite.to_global(rect.position)
		var size: Vector2 = rect.size
		set_building_tiles_solid(top_left, size)


func add_job(job: WorkController, worker_name: String = "", delay := 0.1) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(job):
		return
	
	print("Job added to building: " + str(job.building.name))
	
	if not worker_name.is_empty():
		force_job_on_worker(worker_name, job)
	else:
		job_list.append(job)
		give_job_to_worker()


func get_from_available_jobs() -> WorkController:
	if job_list.is_empty():
		return null
	
	return job_list.pop_front()


func give_job_to_worker() -> void:
	for worker in get_children():
		if not is_instance_valid(worker.current_job):
			worker.get_job()
			break

func force_job_on_worker(worker_name: String, job: WorkController) -> void:
	for worker in get_children():
		if worker.name == worker_name:
			worker.get_job(job)


func remove_job(job: WorkController) -> void:
	job_list.erase(job)


func set_tilemap_tile_solid(tile: Vector2i, is_solid := true) -> void:
	var corner := Vector2i(
		int(tile.x * ratio),
		int(tile.y * ratio)
	)
	
	for i in range(int(ratio)):
		for j in range(int(ratio)):
			var point := corner + Vector2i(i, j)
			if astar.is_in_boundsv(point):
				astar.set_point_solid(point, is_solid)
	
	refresh_worker_paths()
	#queue_redraw()


func set_building_tiles_solid(origin_point: Vector2, size: Vector2, is_solid := true) -> void:
	var top_left := origin_point
	var tiles_w: int = int(ceil(size.x / grid.x))
	var tiles_h: int = int(ceil(size.y / grid.y))
	
	for i in range(tiles_w):
		for j in range(tiles_h):
			var world_pos := top_left + Vector2(grid.x * i, grid.y * j)
			var cell := Vector2i(
				int(floor((world_pos.x - astar.offset.x) / grid.x)),
				int(floor((world_pos.y - astar.offset.y) / grid.y))
			)
			set_tilemap_tile_solid(cell, is_solid)


func refresh_worker_paths() -> void:
	for worker in get_children():
		worker.set_astar_path(worker.destination)


func _draw() -> void:
	for x in range(astar.region.size.x):
		for y in range(astar.region.size.y):
			var cell := Vector2i(x, y)
			
			if astar.is_point_solid(cell):
				var world_pos = astar.offset + Vector2(x, y) * Vector2(CELL_SIZE)
				draw_rect(Rect2(world_pos, Vector2(CELL_SIZE)), Color(1, 0, 0, 0.4))
