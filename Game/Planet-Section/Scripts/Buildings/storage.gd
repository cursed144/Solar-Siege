extends StorageBuilding

func _on_upgrade_finished() -> void:
	super._on_upgrade_finished()
	inventories[inv_storage_name].add_slots(4)
