extends Area2D

signal dest_reached

const ARRIVE_DISTANCE := 10.0
const SPEED = 175

var current_job: WorkController = null
var path := []

@onready var head = get_parent()
@onready var destination := global_position

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("left_click"):
		#go_to(get_global_mouse_position())


func _physics_process(delta: float) -> void:
	if !path.is_empty():
		position = position.move_toward(path[0], SPEED*delta)
		if position.distance_to(path[0]) < ARRIVE_DISTANCE:
			path.pop_front()
			if path.is_empty():
				dest_reached.emit()


func get_job() -> void:
	var new_job: WorkController = head.get_from_available_jobs()
	if is_instance_valid(new_job):
		new_job.assigned_worker = self
		current_job = new_job
		handle_job()


func handle_job() -> void:
	if not is_instance_valid(current_job):
		abandon_job()
		return
	
	var status = current_job.prepare_for_work()
	match status:
		WorkController.WorkState.READY:
			work_in_building()
		WorkController.WorkState.FINISHED:
			abandon_job()


func abandon_job() -> void:
	current_job = null
	get_job()
	show()


func work_in_building() -> void:
	go_to(current_job.building.global_position)
	await dest_reached
	hide()
	current_job.start_work()
	await current_job.alert_work_finished
	handle_job()


func go_to(dest: Vector2) -> void:
	destination = dest
	set_astar_path(dest)


func set_astar_path(dest: Vector2) -> void:
	var start_astar = world_to_astar_cell(global_position)
	var end_astar = world_to_astar_cell(dest)
	
	# if the point is solid because of a building, the cell to the left is chosen
	while(head.astar.is_point_solid(end_astar)):
		end_astar.x -= 1
	
	var id_path : Array = head.astar.get_id_path(start_astar, end_astar, false)
	path.clear()
	for cell in id_path:
		path.append(astar_cell_center(cell))


func world_to_astar_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - head.astar.offset
	return Vector2i(floor(local.x / head.astar.cell_size.x), floor(local.y / head.astar.cell_size.y))

func astar_cell_center(cell: Vector2i) -> Vector2:
	return head.astar.offset + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * head.astar.cell_size
