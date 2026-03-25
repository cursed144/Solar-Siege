@tool
class_name BuildingData
extends Resource

@export var id: int
@export var build_time: float
@export var display_name: String
@export var description: String
@export var requirements: Array[ItemAmount]
@export var icon: Texture2D
@export var building_sprite: Texture2D
@export var building_path: String

@warning_ignore("unused_private_class_variable")
@export_tool_button("Get file path based on name") var _path = _get_building_path


func _get_building_path() -> void:
	var file_path := "res://Planet-Section/Scenes/Buildings/" 
	
	if not display_name.is_empty():
		var files := _get_all_file_names(file_path)
		var name := display_name.to_lower()
		name = name.replace(" ", "_")
		name += ".tscn"
		
		for file_name in files:
			if file_name == name:
				building_path = file_path + file_name
				return
	
	building_path = "Not found"


func _get_all_file_names(file_path: String) -> Array:
	var files := []
	var dir := DirAccess.open(file_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				files.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files
