extends StorageBuilding

func _ready() -> void:
	super._ready()
	inventories[inv_storage_name].add_item_to_inv(ItemStack.from_id(ItemLoader.ItemID.WOOD_LOG, 40))


func _on_upgrade_finished() -> void:
	super._on_upgrade_finished()
	inventories[inv_storage_name].add_slots(4)
