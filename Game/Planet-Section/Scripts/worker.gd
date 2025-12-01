extends Sprite2D

@onready var head = get_parent()
const ARRIVE_DISTANCE := 10.0
const SPEED = 300
var destination := 0.0
var path := []


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		get_astar_path()


func _physics_process(delta: float) -> void:
	if !path.is_empty():
		position = position.move_toward(path[0], SPEED*delta)
		if position.distance_to(path[0]) < ARRIVE_DISTANCE:
			path.pop_front()


func get_astar_path() -> void:
	var start_astar = head.world_to_astar_cell(global_position)
	var end_astar = head.world_to_astar_cell(get_global_mouse_position())
	
	var id_path : Array = head.astar.get_id_path(start_astar, end_astar)
	path.clear()
	for cell in id_path:
		path.append(head.astar_cell_center(cell))
