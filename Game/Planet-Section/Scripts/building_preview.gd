extends Area2D

var is_placing := false
var stored_building: BuildingData

@onready var buildings: TileMapLayer = %Buildings
@onready var grid: Vector2 = buildings.tile_set.tile_size


func _ready() -> void:
	$Sprite2D.texture = null
	$CollisionShape2D.scale = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if is_placing:
		if event.is_action_pressed("left_click"):
			if get_overlapping_areas().size() <= 0:
				place_building(stored_building.id)
		elif event.is_action_pressed("right_click"):
			end_placement()


func _process(_delta: float) -> void:
	if is_instance_valid(stored_building):
		global_position = snapped(get_global_mouse_position() - grid/2, grid)
		if get_overlapping_areas().size() > 0:
			$Sprite2D.self_modulate = Color(1, 0, 0, 0.5)
		else:
			$Sprite2D.self_modulate = Color(1, 1, 1, 0.5)


func start_placing(data: BuildingData) -> void:
	if not is_instance_valid(data):
		push_error("Invalid building data given!")
	
	%UI.hide()
	is_placing = true
	stored_building = data
	$Sprite2D.texture = data.icon
	$CollisionShape2D.position = data.icon.get_size() / 2
	$CollisionShape2D.scale = (data.icon.get_size() / 20) + Vector2(0.5, 0.5)


func place_building(id: int) -> void:
	var cell := buildings.local_to_map(global_position) as Vector2i
	buildings.set_cell(cell, 1, Vector2i.ZERO, id)
	
	await get_tree().process_frame
	var building: Building = buildings.get_child(-1)
	var sprite: Sprite2D = building.get_node("Sprite2D")
	var sprite_size = sprite.get_rect().size / grid
	
	var planet = get_parent()
	building.name = planet.get_unique_name(stored_building.display_name)
	
	for i in range(sprite_size.x):
		for j in range(sprite_size.y):
			cell = buildings.local_to_map(
				Vector2(global_position.x + (grid.x * i),
						global_position.y + (grid.y * j)) ) as Vector2i
			%WorkerHead.set_tilemap_tile_solid(cell)
	
	building.begin_upgrade(stored_building.build_time)
	end_placement()


func end_placement() -> void:
	%UI.show()
	is_placing = false
	stored_building = null
	$Sprite2D.texture = null
	$CollisionShape2D.scale = Vector2.ZERO
	global_position = Vector2.ZERO
