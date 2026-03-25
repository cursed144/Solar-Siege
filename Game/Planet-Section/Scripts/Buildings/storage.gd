extends StorageBuilding

func _on_upgrade_finished() -> void:
	super._on_upgrade_finished()
	inventories[inv_storage_name].add_slots(4)
	var items: Array[ItemStack] = []
	items.append(ItemStack.new_stack(ItemLoader.based_on_id(ItemLoader.ItemID.WOOD_LOG), 40))
	inventories[inv_storage_name].add_items_to_inv(items)
