extends Area2D

@onready var astar = get_parent().astar
const ARRIVE_DISTANCE := 5.0
const SPEED = 300
var destination := Vector2.ZERO
var path := []


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		set_astar_path(get_global_mouse_position())


func _physics_process(delta: float) -> void:
	if !path.is_empty():
		position = position.move_toward(path[0], SPEED*delta)
		if position.distance_to(path[0]) < ARRIVE_DISTANCE:
			path.pop_front()


func go_to(dest: Vector2) -> void:
	destination = dest
	set_astar_path(dest)


func set_astar_path(dest: Vector2) -> void:
	var start_astar = world_to_astar_cell(global_position)
	var end_astar = world_to_astar_cell(dest)
	
	# if the point is solid because of a building, the cell to the left is chosen
	while(astar.is_point_solid(end_astar)):
		end_astar.x -= 1
	
	var id_path : Array = astar.get_id_path(start_astar, end_astar, false)
	path.clear()
	for cell in id_path:
		path.append(astar_cell_center(cell))


func world_to_astar_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - astar.offset
	return Vector2i(floor(local.x / astar.cell_size.x), floor(local.y / astar.cell_size.y))

func astar_cell_center(cell: Vector2i) -> Vector2:
	return astar.offset + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * astar.cell_size
