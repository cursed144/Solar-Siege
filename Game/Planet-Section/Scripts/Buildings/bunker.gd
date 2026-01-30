extends StorageBuilding


func _ready() -> void:
	super._ready()
	var starting_items: Array[ItemStack] = []
	var start_item: Item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var new_item = ItemStack.new_stack(start_item, 20)
	starting_items.append(new_item)
	
	start_item = load("res://Planet-Section/Resources/Items/rock.tres")
	new_item = ItemStack.new_stack(start_item, 15)
	starting_items.append(new_item)
	
	start_item = load("res://Planet-Section/Resources/Items/coal.tres")
	new_item = ItemStack.new_stack(start_item, 10)
	starting_items.append(new_item)
	
	inventories[inv_storage_name].add_items_to_inv(starting_items)
