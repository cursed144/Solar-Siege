extends Camera2D

var is_dragging := false
var cam_zoom := Vector2(1, 1)

const zoom_percent := 0.3
const max_zoom := 7.5
const min_zoom := 0.35


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_dragging:
		global_position += -event.relative / zoom.x
	
	elif event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			is_dragging = true
		elif event.is_action_released("left_click"):
			is_dragging = false
		
		elif event.is_action_released("scroll_up") or event.is_action_pressed("scroll_down"):
			if event.is_action_released("scroll_up"):
				cam_zoom = cam_zoom * (1 + zoom_percent)
			else:
				cam_zoom = cam_zoom / (1 + zoom_percent)
			
			cam_zoom.x = clampf(cam_zoom.x, min_zoom, max_zoom)
			cam_zoom.y = clampf(cam_zoom.y, min_zoom, max_zoom)


func _physics_process(delta: float) -> void:
	zoom.x = lerpf(zoom.x, cam_zoom.x, delta*3.5)
	zoom.y = lerpf(zoom.y, cam_zoom.y, delta*3.5)
