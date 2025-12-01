extends Sprite2D

@onready var head = get_parent()
const ARRIVE_DISTANCE := 10.0
const SPEED = 300
var destination := Vector2.ZERO
var path := []


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		set_astar_path(get_global_mouse_position())
		print(path)
		print("TIlememap: " + str(%Buildings.local_to_map(get_global_mouse_position())))


func _physics_process(delta: float) -> void:
	if !path.is_empty():
		position = position.move_toward(path[0], SPEED*delta)
		if position.distance_to(path[0]) < ARRIVE_DISTANCE:
			path.pop_front()


func go_to(dest: Vector2) -> void:
	destination = dest
	set_astar_path(dest)


func set_astar_path(dest: Vector2) -> void:
	var start_astar = head.world_to_astar_cell(global_position)
	var end_astar = head.world_to_astar_cell(dest)
	
	# if the point is solid because of a building, the cell to the left is chosen
	while(head.astar.is_point_solid(end_astar)):
		end_astar.x -= 1
	
	var id_path : Array = head.astar.get_id_path(start_astar, end_astar, false)
	path.clear()
	for cell in id_path:
		path.append(head.astar_cell_center(cell))
