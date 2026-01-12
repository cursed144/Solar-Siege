@tool
extends Node2D

@export var planet_size := Vector2(5000, 5000)
@export_category("Max buildings")
@export_tool_button("Get Buildings") var buildings = get_all_buildings
@export var max_building_amount: Dictionary[String, int]

var building_amounts: Dictionary[String, int] = {}
var global_storage: Array[Inventory]


func _ready() -> void:
	$PlayingField.position = planet_size/2
	$PlayingField.scale = planet_size
	$PlayerCam.position = $PlayingField.position


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
		if not unique_name[i].is_valid_int():
			return unique_name.substr(0, i + 1)
	
	return ""


func get_building_max_amount(building_name: String) -> int:
	return max_building_amount.get(building_name)


func get_building_current_amount(building_name: String) -> int:
	return building_amounts.get(building_name, 0)


func get_global_item_amount(item: Item) -> int:
	var total := 0
	for inv in global_storage:
		total += inv.get_total_item_amount(item)
	
	return total
