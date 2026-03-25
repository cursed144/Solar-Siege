extends Area2D

var is_placing := false
var stored_building: BuildingData

@onready var buildings: Node2D = %Buildings
@onready var grid: Vector2 = buildings.grid_size


func _ready() -> void:
	$Sprite2D.texture = null


func _input(event: InputEvent) -> void:
	if is_placing:
		if event.is_action_pressed("left_click"):
			if get_overlapping_areas().size() <= 0:
				buildings.place_building_by_id(stored_building.id, global_position)
		elif event.is_action_pressed("right_click"):
			end_placement()


func _process(_delta: float) -> void:
	if stored_building != null:
		global_position = snapped(get_global_mouse_position() - buildings.grid_size/2, buildings.grid_size)
		if get_overlapping_areas().size() > 0:
			$CollisionShape2D/BlockedCover.show()
		else:
			$CollisionShape2D/BlockedCover.hide()


func start_placing(data: BuildingData) -> void:
	if not is_instance_valid(data):
		push_error("Invalid building data given!")
	
	buildings.create_global_claim(name, data.requirements)
	
	%UI.hide()
	is_placing = true
	stored_building = data
	$Sprite2D.texture = data.building_sprite
	$CollisionShape2D.position = data.building_sprite.get_size() / 2
	$CollisionShape2D.scale = (data.building_sprite.get_size() / 20) + Vector2(0.5, 0.5)
	$CollisionShape2D.disabled = false


func end_placement() -> void:
	%UI.show()
	is_placing = false
	stored_building = null
	$Sprite2D.texture = null
	$CollisionShape2D.disabled = true
	global_position = Vector2(-100, -100)
	buildings.remove_global_claim(name)
