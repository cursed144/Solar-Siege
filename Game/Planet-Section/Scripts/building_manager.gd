@tool
extends Node2D

const RESOURCE_PATH := "res://Planet-Section/Resources/Buildings/"

@export var grid_size := Vector2(64, 64)

@export_category("Max buildings")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Get Buildings") var _buildings = _get_all_buildings
@export var max_building_amount: Dictionary[String, int]

@export_category("Planet specific building productions")
@export var mine: Dictionary[Recipe, int] # Recipe to chance for extra
@export var lumber_mill: Dictionary[Recipe, int]

var building_amounts: Dictionary[String, int] = {}
var global_storage: Dictionary[Inventory, Vector2] = {} # Keep building inv as key and pos as value
var _building_mapping: Dictionary[int, BuildingData] = {}


func _ready() -> void:
	_refresh_buildings()
	
	if not Engine.is_editor_hint():
		place_building_by_id(1, Vector2i(snappedi(1750 - 64, 64), snappedi(1750 - 64, 64)), true)


func place_building_by_id(id: int, pos: Vector2, skip_construction := false) -> void:
	assert(_building_mapping.has(id))
	var building_data = _building_mapping[id]
	var building: Building = load(building_data.building_path).instantiate()
	building.name = get_unique_name(building_data.display_name)
	
	%WorkerHead.set_building_tiles_solid(pos, building_data.building_sprite.get_size())
	
	if not skip_construction:
		building.call_deferred("begin_upgrade", building_data.build_time)
	else:
		building.level = 1
	
	building.internal_id = building_data.id
	building.global_position = pos
	add_child(building)
	
	%BuildingPreview.end_placement()


# Remove from the building counter, remove from tree, remove from astar
func remove_building(building: Building) -> void:
	building.name = unique_to_initial(building.name)
	building_amounts[building.name] -= 1
	
	var build_size = building.get_node("Sprite2D").get_rect().size
	$WorkerHead.set_building_tiles_solid(building.global_position, build_size, false)
	
	building.queue_free()


func get_unique_name(initial_name: String) -> String:
	var amount: int = building_amounts.get(initial_name, -1)
	if amount <= 0:
		building_amounts[initial_name] = 0
		amount = 0
	
	amount += 1
	building_amounts.set(initial_name, amount)
	
	var ret := initial_name + " " + str(amount)
	return ret


func unique_to_initial(unique_name: String) -> String:
	for i in range(unique_name.length() - 1, -1, -1):
		if not unique_name[i].is_valid_int() and unique_name[i] != " ":
			return unique_name.substr(0, i + 1)
	
	return ""


func get_building_max_amount(building_name: String) -> int:
	return max_building_amount.get(building_name)


func get_building_current_amount(building_name: String) -> int:
	return building_amounts.get(building_name, 0)


func get_global_item_amount(item: Item) -> int:
	var total := 0
	for inv in global_storage.keys():
		total += inv.get_total_item_amount(item)
	
	return total


func create_global_claim(claim_name: String, items: Array[ItemAmount]):
	var temp: Array[ItemAmount] = []
	for item_amount in items:
		temp.append(item_amount.duplicate(true))
	
	for storage: Inventory in global_storage.keys():
		var stacks := ItemAmount.amounts_to_stacks(temp)
		var res = storage.create_claim(claim_name, stacks)
		temp = ItemAmount.subtract_array(temp, res)
		if temp.is_empty():
			break


func get_claimed_global_items(claim_name: String):
	for storage: Inventory in global_storage.keys():
		storage.get_claimed_items(claim_name)


func remove_global_claim(claim_name: String):
	for storage: Inventory in global_storage.keys():
		storage.remove_claim(claim_name)


func _refresh_buildings() -> void:
	var files := _get_all_file_names(RESOURCE_PATH)
	_building_mapping = _get_loaded_buildings(files, RESOURCE_PATH)


func _get_all_file_names(path: String) -> Array:
	var files := []
	var dir := DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				files.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files


func _get_loaded_buildings(files: Array, path: String) -> Dictionary[int, BuildingData]:
	var buildings: Dictionary[int, BuildingData] = {}
	
	for building_resource_name in files:
		var full_path: String = path + building_resource_name
		var building_data: BuildingData = load(full_path)
		var building_id = building_data.id
		
		assert(not buildings.has(building_id))
		buildings[building_id] = building_data
	
	return buildings


func _get_all_buildings() -> void:
	var dir = DirAccess.open(RESOURCE_PATH)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = RESOURCE_PATH + file_name
			var res = load(full_path)
			if res:
				max_building_amount[res.display_name] = 1
		file_name = dir.get_next()
	dir.list_dir_end()
