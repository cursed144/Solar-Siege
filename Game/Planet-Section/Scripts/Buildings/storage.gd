extends Building

func _ready() -> void:
	super._ready()
	
	var planet = get_tree().current_scene
	planet.global_storage[inventories["Storage"]] = global_position


func destroy() -> void:
	var planet = get_tree().current_scene
	planet.global_storage.erase(inventories["Storage"])
	super.destroy()
