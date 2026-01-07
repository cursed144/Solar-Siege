extends Area2D

var is_placing := false
var stored_building: BuildingData

@onready var grid: Vector2 = %Buildings.tile_set.tile_size


func _input(event: InputEvent) -> void:
	if is_placing:
		if event.is_action_pressed("left_click"):
			if get_overlapping_areas().size() <= 0:
				place_building(stored_building.id)
		elif event.is_action_pressed("right_click"):
			end_placement()


func _process(_delta: float) -> void:
	if stored_building != null:
		global_position = snapped(get_global_mouse_position() - grid/2, grid)
		if get_overlapping_areas().size() > 0:
			$Sprite2D.self_modulate = Color(1, 0, 0, 0.5)
		else:
			$Sprite2D.self_modulate = Color(1, 1, 1, 0.5)


func start_placing(data: BuildingData) -> void:
	%UI.hide()
	is_placing = true
	stored_building = data
	$Sprite2D.texture = data.icon
	$CollisionShape2D.position = data.icon.get_size() / 2
	$CollisionShape2D.scale = (data.icon.get_size() / 20) + Vector2(0.5, 0.5)


func place_building(id: int) -> void:
	var cell := %Buildings.local_to_map(global_position) as Vector2i
	%Buildings.set_cell(cell, 1, Vector2i.ZERO, id)
	%WorkerHead.set_tilemap_tile_solid(cell)
	end_placement()


func end_placement() -> void:
	%UI.show()
	is_placing = false
	stored_building = null
	$Sprite2D.texture = null
	global_position = Vector2.ZERO
