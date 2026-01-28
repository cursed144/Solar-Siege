@tool
extends Node2D

@export var planet_size := Vector2(3500, 3500)

@export_category("Max buildings")
@export_tool_button("Get Buildings") var buildings = get_all_buildings
@export var max_building_amount: Dictionary[String, int]

@export_category("Planet specific building productions")
@export var mine: Dictionary[Recipe, int] # Recipe to chance for extra


var building_amounts: Dictionary[String, int] = {}
var global_storage: Dictionary[Inventory, Vector2] = {} # Keep building inv as key and pos as value


func _ready() -> void:
	$PlayingField.position = planet_size/2
	$PlayingField.scale = planet_size
	$PlayerCam.position = $PlayingField.position
	
	await get_tree().process_frame
	for building: Building in $Buildings.get_children():
		var pos = building.global_position
		var sprite: Sprite2D = building.get_node("Sprite2D")
		var sprite_size = sprite.get_rect().size
		$WorkerHead.set_building_tiles_solid(pos, sprite_size)


func get_all_buildings() -> void:
	var path = "res://Planet-Section/Resources/Buildings"
	
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = path + "/" + file_name
			var res = load(full_path)
			if res:
				max_building_amount[res.display_name] = 1
		file_name = dir.get_next()
	dir.list_dir_end()


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


# Remove from the building counter, remove from tilemap, remove from astar
func remove_building(building: Building) -> void:
	building.name = unique_to_initial(building.name)
	building_amounts[building.name] -= 1
	
	var local_pos = $Buildings.local_to_map(building.global_position)
	$Buildings.erase_cell(local_pos)
	
	var build_size = building.get_node("Sprite2D").get_rect().size
	%WorkerHead.set_building_tiles_solid(building.global_position, build_size, false)


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
	for storage: Inventory in global_storage.keys():
		var stacks := ItemAmount.amounts_to_stacks(items)
		var res = storage.create_claim(claim_name, stacks)
		items = ItemAmount.subtract_array(items, res)
		if items.is_empty():
			break


func get_claimed_global_items(claim_name: String):
	for storage: Inventory in global_storage.keys():
		storage.get_claimed_items(claim_name)


func remove_global_claim(claim_name: String):
	for storage: Inventory in global_storage.keys():
		storage.remove_claim(claim_name)
