@tool
extends Node2D

@export var planet_size := Vector2(5000, 5000)
@export_category("Max buildings")
@export_tool_button("Get Buildings") var buildings = get_all_buildings
@export var max_building_amount: Dictionary[String, int]
var bulding_amounts: Dictionary[String, int] = {}


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
				max_building_amount[res.display_name] = 0
		file_name = dir.get_next()
	dir.list_dir_end()


func get_unique_name(initial_name: String) -> String:
	var amount: int = bulding_amounts.get(initial_name, -1)
	if amount <= 0:
		bulding_amounts[initial_name] = 0
		amount = 0
	
	amount += 1
	bulding_amounts.set(initial_name, amount)
	
	var ret := initial_name + " " + str(amount)
	return ret
