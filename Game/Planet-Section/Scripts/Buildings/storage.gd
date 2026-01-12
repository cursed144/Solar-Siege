extends Building

func _ready() -> void:
	super._ready()
	
	var planet = get_tree().current_scene
	planet.global_storage[global_position] = inventories["Storage"]


func destroy() -> void:
	var planet = get_tree().current_scene
	planet.global_storage.erase(global_position)
	super.destroy()
