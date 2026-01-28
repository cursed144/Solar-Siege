extends StorageBuilding


func _ready() -> void:
	super._ready()
	var log: Item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var new_item = ItemStack.new_stack(log, log.max_per_stack)
	inventories[inv_storage_name].add_item_to_inv(new_item)
