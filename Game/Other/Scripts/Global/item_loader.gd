extends Node

enum ItemID {
	WOOD_LOG,
	WOOD_PLANKS,
	ROCK,
	COAL,
	IRON_ORE,
	STEEL_PLATES
}

const RESOURCE_PATH := "res://Planet-Section/Resources/Items/"

var _global_items: Array[Item] = []


func _ready() -> void:
	_refresh_items()


func based_on_id(id: ItemID) -> Item:
	assert(id in ItemID.values())
	return _global_items[id]


func _refresh_items() -> void:
	var files := _get_all_file_names(RESOURCE_PATH)
	_global_items = _get_loaded_items(files, RESOURCE_PATH)


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


func _get_loaded_items(files: Array, path: String) -> Array[Item]:
	var items: Array[Item] = []
	
	for item_name in files:
		var full_path: String = path + item_name
		var item: Item = load(full_path)
		items.append(item)
	
	items.sort_custom(Item.sort_by_id_asc)
	return items
