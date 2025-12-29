extends Camera2D

const MOVE_SPEED := 400
const ZOOM_PERCENT := 0.3
const MAX_ZOOM := 6.0
const MIN_ZOOM := 0.30

var is_dragging := false
var cam_zoom := Vector2(1, 1)

@onready var MAP_BOUNDARY: Vector2 = get_parent().planet_size


func _input(event: InputEvent) -> void:
	var hover = get_viewport().gui_get_hovered_control()
	var is_space_valid = (hover == null or hover.get_parent() is Building)
	
	if event is InputEventMouseMotion and is_dragging:
		global_position += -event.relative / zoom.x
	
	else:
		if event.is_action_pressed("left_click") and is_space_valid:
			is_dragging = true
		elif event.is_action_released("left_click"):
			is_dragging = false
		
		elif not is_space_valid:
			return
		elif event.is_action_released("scroll_up") or event.is_action_pressed("scroll_down") or \
			 event.is_action_pressed("e") or event.is_action_pressed("q"):
			
			if event.is_action_released("scroll_up") or event.is_action_pressed("e"):
				cam_zoom = cam_zoom * (1 + ZOOM_PERCENT)
			else:
				cam_zoom = cam_zoom / (1 + ZOOM_PERCENT)
			
			cam_zoom.x = clampf(cam_zoom.x, MIN_ZOOM, MAX_ZOOM)
			cam_zoom.y = clampf(cam_zoom.y, MIN_ZOOM, MAX_ZOOM)


func _process(delta: float) -> void:
	var speed_scaled := MOVE_SPEED * delta / zoom.x

	if Input.is_action_pressed("right"):
		global_position.x += speed_scaled
	if Input.is_action_pressed("left"):
		global_position.x -= speed_scaled
	if Input.is_action_pressed("down"):
		global_position.y += speed_scaled
	if Input.is_action_pressed("up"):
		global_position.y -= speed_scaled
	
	var vsize := get_viewport_rect().size
	var half_view_w := vsize.x / (zoom.x * 2.0)
	var half_view_h := vsize.y / (zoom.y * 2.0)
	
	global_position.x = clamp(global_position.x, half_view_w, MAP_BOUNDARY.x - half_view_w)
	global_position.y = clamp(global_position.y, half_view_h, MAP_BOUNDARY.y - half_view_h)
	
	zoom.x = lerp(zoom.x, cam_zoom.x, clampf(delta * 3.5, 0.0, 1.0))
	zoom.y = lerp(zoom.y, cam_zoom.y, clampf(delta * 3.5, 0.0, 1.0))
