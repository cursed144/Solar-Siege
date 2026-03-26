extends Node

const WORKER_SCENE := preload("res://Planet-Section/Scenes/worker.tscn")


func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	#save_scene()
	load_scene()


func save_scene() -> bool:
	var planet: Node2D = get_tree().current_scene
	var planet_name: String = planet.name.to_lower()
	var path: String = "user://planets/" + planet_name + "/save.json"
	DirAccess.make_dir_recursive_absolute("user://planets")
	DirAccess.make_dir_recursive_absolute("user://planets/" + planet_name)
	
	var save_data := {
		"workers": {},
		"buildings": {}
	}
	
	save_workers(save_data, planet)
	save_buildings(save_data, planet)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	return true


func load_scene() -> bool:
	var planet: Node2D = get_tree().current_scene
	var data := file_stability_check(planet)
	
	var stable = worker_structure_check(data[true], planet)
	print(stable)
	assert(not stable.has(false))
	
	load_buildings(data[true], planet)
	load_workers(data[true], planet)
	
	return true


func file_stability_check(planet: Node2D) -> Dictionary[bool, Variant]:
	assert(is_instance_valid(planet))
	var planet_name: String = planet.name.to_lower()
	var path: String = "user://planets/" + planet_name + "/save.json"
	var data: Dictionary[bool, Variant] = {}
	var error: String = ""
	
	if not FileAccess.file_exists(path):
		error = "Save file does not exist: " + path
		push_warning(error)
		data[false] = error
		return data
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		error = "Failed to open save file: " + path
		push_warning(error)
		data[false] = error
		return data
	
	var text := file.get_as_text()
	var save_data = JSON.parse_string(text)
	if (save_data == null) or (save_data is not Dictionary):
		error = "Save file is corrupted! Path: " + path
		push_error(error)
		data[false] = error
		return data
	
	data[true] = save_data
	return data


func save_workers(save_data: Dictionary, planet: Node2D) -> void:
	var worker_head: Node2D = planet.get_node("WorkerHead")
	assert(is_instance_valid(worker_head))
	
	for i in range(worker_head.get_child_count()):
		var worker: Node2D = worker_head.get_child(i)
		var section_name: String = "worker_" + str(i+1)
		
		save_data["workers"][section_name] = {
			"position": {
				"x": worker.global_position.x,
				"y": worker.global_position.y
			},
			"name": worker.name,
			"visible": worker.visible,
			"inventory": [],
			"pathfinding": []
		}
		
		for j in range(worker.inv.slots.size()):
			var slot = worker.inv.slots[j]
			
			if not is_instance_valid(slot):
				save_data["workers"][section_name]["inventory"].append(null)
			else:
				save_data["workers"][section_name]["inventory"].append({
					"id": slot.item.id,
					"amount": slot.amount
				})
		
		save_data["workers"][section_name]["pathfinding"] = worker.path


func save_buildings(save_data: Dictionary, planet: Node2D) -> void:
	var buildings = planet.get_node("Buildings")
	assert(is_instance_valid(buildings))
	
	for i in range(buildings.get_child_count()):
		var building: Building = buildings.get_child(i)
		var internal_id := "building_" + str(i+1)
		
		save_data["buildings"][internal_id] = {
			"position": {
				"x": building.global_position.x,
				"y": building.global_position.y
			},
			"name": building.name,
			"internal_id": building.internal_id,
			"level": building.level,
			"inventories": {}
		}
		
		var inv_keys := building.inventories.keys()
		for j in range(inv_keys.size()):
			var inventory_name = inv_keys[j]
			var inventory_id := "inventory_" + str(j+1)
			var inventory: Inventory = building.inventories[inventory_name]
			
			save_data["buildings"][internal_id]["inventories"][inventory_id] = {
				"name": inventory_name,
				"slots": []
			}
			
			for k in range(inventory.slots.size()):
				var slot = inventory.slots[k]
				
				if not is_instance_valid(slot):
					save_data["buildings"][internal_id]["inventories"]\
							 [inventory_id]["slots"].append(null)
				else:
					save_data["buildings"][internal_id]["inventories"]\
							 [inventory_id]["slots"].append({
						"id": slot.item.id,
						"amount": slot.amount
					})


func load_buildings(data: Dictionary, planet: Node2D) -> void:
	var buildings = planet.get_node("Buildings")
	assert(is_instance_valid(buildings))


func load_workers(data: Dictionary, planet: Node2D) -> void:
	var workers_data: Dictionary = data["workers"]
	var worker_head: Node2D = planet.get_node("WorkerHead")
	
	for worker in workers_data.keys():
		var inv_data: Array = workers_data[worker]["inventory"]
		var new_worker = WORKER_SCENE.instantiate()
		new_worker.name = workers_data[worker]["name"]
		worker_head.add_child(new_worker)
		
		var position = workers_data[worker]["position"]
		position = Vector2(position["x"], position["y"])
		new_worker.global_position = position
		
		new_worker.create_inv(inv_data.size())
		for i in range(inv_data.size()):
			if inv_data[i] != null:
				var item_id: ItemLoader.ItemID = inv_data[i]["id"]
				var item_amount: int = inv_data[i]["amount"]
				var new_stack := ItemStack.from_id(item_id, item_amount)
				new_worker.inv.slots[i] = new_stack



func worker_structure_check(data: Dictionary, planet: Node2D) -> Dictionary[bool, String]:
	var stable: Dictionary[bool, String] = {}
	
	var worker_head: Node2D = planet.get_node("WorkerHead")
	if not is_instance_valid(worker_head):
		return _fail(stable, "Scene did not load correctly!")
	
	if not data.has("workers"):
		return _fail(stable, "Save file is corrupted!\nParsing stopped at root/.\nWorker section does not exist!")
	
	var worker_section = data["workers"]
	if worker_section is not Dictionary:
		return _fail(stable, "Save file is corrupted!\nParsing stopped at root/workers/.\nWorker section is corrupted!")
	
	if worker_section.is_empty():
		return _fail(stable, "Save file is corrupted!\nParsing stopped at root/workers/.\nExpected at least 1 worker. Found none.")
	
	for worker in worker_section.keys():
		var worker_data = worker_section[worker]
		var base_error: String = "Save file is corrupted!\nParsing stopped at root/workers/" + worker + "/."
		
		if worker_data is not Dictionary:
			return _fail(stable, base_error + "\nWorker data is corrupted!")
		
		if not worker_data.has("name"):
			return _fail(stable, base_error + "\nWorker name not found!")
		
		if not worker_data.has("visible"):
			return _fail(stable, base_error + "\nWorker visiblity not found!")
		
		if not worker_data.has("position"):
			return _fail(stable, base_error + "\nWorker position not found!")
		
		if worker_data["position"] is not Dictionary:
			return _fail(stable, base_error + "\nWorker position is corrupted!")
		
		if not (worker_data["position"].has("x") and worker_data["position"].has("y")):
			return _fail(stable, base_error + "\nWorker position is corrupted!")
		
		if not worker_data.has("pathfinding"):
			return _fail(stable, base_error + "\nWorker pathfinding not found!")
		
		if worker_data["pathfinding"] is not Array:
			return _fail(stable, base_error + "\nWorker pathfinding is corrupted!")
		
		if not worker_data.has("inventory"):
			return _fail(stable, base_error + "\nWorker inventory not found!")
		
		if worker_data["inventory"] is not Array:
			return _fail(stable, base_error + "\nWorker inventory is corrupted!")
		
		for i in range(worker_data["inventory"].size()):
			var slot = worker_data["inventory"][i]
			var slot_error: String = "Save file is corrupted!\nParsing stopped at root/workers/" + worker + "/inventory/slot " + str(i + 1)
			
			if slot != null and slot is not Dictionary:
				return _fail(stable, slot_error + "\nInventory slot is corrupted!")
			
			if slot is Dictionary:
				if not (slot.has("id") and slot.has("amount")):
					return _fail(stable, slot_error + "\nInventory slot is corrupted!")
	
	return stable


func _fail(stable: Dictionary, message: String) -> Dictionary[bool, String]:
		push_error(message)
		stable[false] = message
		return stable
