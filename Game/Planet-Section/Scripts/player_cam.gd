extends Camera2D

const MOVE_SPEED := 400
const ZOOM_PERCENT := 0.3
const MAX_ZOOM := 7.5
const MIN_ZOOM := 0.35
var is_dragging := false
var cam_zoom := Vector2(1, 1)
@onready var MAP_BOUNDARY: Vector2 = get_parent().planet_size


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_dragging:
		global_position += -event.relative / zoom.x
	
	else:
		if event.is_action_pressed("left_click"):
			is_dragging = true
		elif event.is_action_released("left_click"):
			is_dragging = false
		
		elif event.is_action_released("scroll_up") or event.is_action_pressed("scroll_down") or \
			 event.is_action_pressed("e") or event.is_action_pressed("q"):
			
			if event.is_action_released("scroll_up") or event.is_action_pressed("e"):
				cam_zoom = cam_zoom * (1 + ZOOM_PERCENT)
			else:
				cam_zoom = cam_zoom / (1 + ZOOM_PERCENT)
			
			cam_zoom.x = clampf(cam_zoom.x, MIN_ZOOM, MAX_ZOOM)
			cam_zoom.y = clampf(cam_zoom.y, MIN_ZOOM, MAX_ZOOM)


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("right"):
		global_position.x += MOVE_SPEED / zoom.x * delta
	if Input.is_action_pressed("left"):
		global_position.x += -MOVE_SPEED / zoom.x * delta
	if Input.is_action_pressed("down"):
		global_position.y += MOVE_SPEED / zoom.x * delta
	if Input.is_action_pressed("up"):
		global_position.y += -MOVE_SPEED / zoom.x * delta
	
	var vsize = get_viewport_rect().size
	global_position.x = clampf(global_position.x, vsize.x/zoom.x/2, MAP_BOUNDARY.x - vsize.y/zoom.x)
	global_position.y = clampf(global_position.y, vsize.y/zoom.y/2, MAP_BOUNDARY.y - vsize.y/zoom.x)
	
	zoom.x = lerpf(zoom.x, cam_zoom.x, delta*3.5)
	zoom.y = lerpf(zoom.y, cam_zoom.y, delta*3.5)
