extends StorageBuilding


func _ready() -> void:
	super._ready()
	var start_log: Item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var new_item = ItemStack.new_stack(start_log, start_log.max_per_stack)
	inventories[inv_storage_name].add_item_to_inv(new_item)
