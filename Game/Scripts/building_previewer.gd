extends Area2D

var preview_id = 0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and preview_id > 0:
		if get_overlapping_bodies().size() <= 0:
			place_building()
	
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("right_click"):
		clear_building_preview()


func _physics_process(delta: float) -> void:
	if get_overlapping_bodies().size() <= 0 or preview_id <= 0:
		$Label.hide()
	else:
		$Label.show()
	
	global_position = get_global_mouse_position()
	global_position.x = int(global_position.x / 64) * 64
	global_position.y = int(global_position.y / 64) * 64



func place_building() -> void:
	if preview_id <= 0:
		return
	
	var cell := %Buildings.local_to_map($Sprite.global_position) as Vector2i
	%Buildings.set_cell(cell, 0, Vector2i.ZERO, preview_id)


func set_building_preview(id: int, texture: Texture2D) -> void:
	preview_id = id
	$Sprite.set_texture(texture)


func clear_building_preview() -> void:
	preview_id = 0
	$Sprite.set_texture(null)
