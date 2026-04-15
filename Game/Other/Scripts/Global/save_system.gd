extends Node

const WORKER_SCENE := preload("res://Planet-Section/Scenes/worker.tscn")
const WORK_CONTROLLER := preload("res://Planet-Section/Scenes/work_controller.tscn")


func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	load_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ctrl"):
		save_scene()


func save_scene() -> bool:
	var planet: Node2D = get_tree().current_scene
	var planet_name: String = planet.name.to_lower()
	var path: String = "user://planets/" + planet_name + "/save.json"
	DirAccess.make_dir_recursive_absolute("user://planets")
	DirAccess.make_dir_recursive_absolute("user://planets/" + planet_name)
	
	var save_data := {
		"workers": {},
		"buildings": []
	}
	
	save_workers(save_data, planet)
	save_buildings(save_data, planet)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	return true


func load_scene() -> bool:
	var planet: Node2D = get_tree().current_scene
	var data := file_stability_check(planet)
	
	var stable: Array[String] = []
	worker_structure_check(data[true], stable, planet)
	building_structure_check(data[true], stable, planet)
	print(stable)
	assert(stable.is_empty())
	
	load_workers(data[true], planet)
	await get_tree().process_frame
	load_buildings(data[true], planet)
	
	return true


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
		
		# --- Inventory ---
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
	
	var building_array: Array = buildings.get_children()
	building_array.sort_custom(func(a, b):
		return a.name > b.name
	)
	
	for i in range(building_array.size()):
		var building: Building = building_array[i]
		var internal_id := "building_" + str(i + 1)
		
		var building_data = {
			"position": {
				"x": building.global_position.x,
				"y": building.global_position.y
			},
			"name": building.name,
			"internal_id": building.internal_id,
			"level": building.level,
			"inventories": []
		}
		
		# --- Inventories ---
		var inv_keys := building.inventories.keys()
		for j in range(inv_keys.size()):
			var inventory_name = inv_keys[j]
			var inventory_id := "inventory_" + str(j + 1)
			var inventory: Inventory = building.inventories[inventory_name]
			
			var inventory_data = {
				"name": inventory_name,
				"inventory_id": inventory_id,
				"slots": []
			}
			
			for k in range(inventory.slots.size()):
				var slot = inventory.slots[k]
				
				if not is_instance_valid(slot):
					inventory_data["slots"].append(null)
				else:
					inventory_data["slots"].append({
						"id": slot.item.id,
						"amount": slot.amount
					})
			
			building_data["inventories"].append(inventory_data)
		
		# --- Jobs ---
		if building is ProductionBuilding:
			building_data["jobs"] = []
			
			var jobs: Array = building.get_work_controllers()
			for j in range(jobs.size()):
				var job_id := "job_" + str(j + 1)
				var job: WorkController = jobs[j]
				var work_done: Timer = job.get_node("Timer")
				
				var job_data = {
					"job_id": job_id,
					"recipe_row": int(job.name),
					"recipe_id": job.internal_recipe_idx,
					"amount_to_produce": job.amount_to_produce,
					"work_left": work_done.time_left
				}
				
				var assigned_worker = job.assigned_worker
				if assigned_worker != null:
					assigned_worker = assigned_worker.name
				
				job_data["assigned_worker"] = assigned_worker
				
				building_data["jobs"].append(job_data)
		
		save_data["buildings"].append(building_data)


func load_workers(data: Dictionary, planet: Node2D) -> void:
	var workers_data: Dictionary = data["workers"]
	var worker_head: Node2D = planet.get_node("WorkerHead")
	
	for worker in workers_data.keys():
		var inv_data: Array = workers_data[worker]["inventory"]
		var new_worker = WORKER_SCENE.instantiate()
		new_worker.name = workers_data[worker]["name"]
		worker_head.add_child(new_worker)
		
		var pos: Vector2
		pos.x = workers_data[worker]["position"]["x"]
		pos.y = workers_data[worker]["position"]["y"]
		new_worker.global_position = pos
		
		new_worker.create_inv(inv_data.size())
		for i in range(inv_data.size()):
			var slot = inv_data[i]
			
			if slot != null:
				var item_id: ItemLoader.ItemID = slot["id"]
				var item_amount: int = slot["amount"]
				var new_stack := ItemStack.from_id(item_id, item_amount)
				new_worker.inv.slots[i] = new_stack


func load_buildings(data: Dictionary, planet: Node2D) -> void:
	var building_data: Array = data["buildings"]
	var buildings = planet.get_node("Buildings")
	
	for building in building_data:
		var building_id = building["internal_id"]
		var level = building["level"]
		var pos: Vector2
		pos.x = building["position"]["x"]
		pos.y = building["position"]["y"]
		
		var placed: Building = buildings.place_building_by_id(building_id, pos, true, level)
		
		for inv in building["inventories"]:
			var build_inv: Inventory = placed.inventories[inv["name"]]
			assert(is_instance_valid(build_inv))
			
			for i in inv["slots"].size():
				var slot = inv["slots"][i]
				
				if slot != null:
					var item_id: ItemLoader.ItemID = slot["id"]
					var item_amount: int = slot["amount"]
					var new_stack := ItemStack.from_id(item_id, item_amount)
					build_inv.slots[i] = new_stack
		
		if placed is ProductionBuilding:
			var jobs = building["jobs"]
			if jobs.is_empty():
				continue
			
			for i in range(jobs.size()):
				var job = jobs[i]
				placed.increment_worker_rows()
				
				if job["amount_to_produce"] < 1:
					continue
				
				var id = job["recipe_id"]
				var row = job["recipe_row"]
				var work_left = job["work_left"]
				var amount = job["amount_to_produce"]
				var worker_name = job["assigned_worker"] 
				if worker_name == null:
					worker_name = ""
				
				placed.load_recipe(id, amount, row, work_left, worker_name)



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


func worker_structure_check(data: Dictionary, errors: Array[String], planet: Node2D) -> Array[String]:
	var worker_head: Node2D = planet.get_node("WorkerHead")
	if not is_instance_valid(worker_head):
		_err(errors, "Scene did not load correctly!")
		return errors
	
	if not data.has("workers"):
		_err(errors, "Save file is corrupted!\nWorker section does not exist!")
		return errors
	
	var worker_section = data["workers"]
	if worker_section is not Dictionary:
		_err(errors, "Save file is corrupted!\nWorker section is corrupted!")
		return errors
	
	if worker_section.is_empty():
		_err(errors, "Save file is corrupted!\nExpected at least 1 worker. Found none.")
	
	for worker in worker_section.keys():
		var worker_data = worker_section[worker]
		var base_error: String = "Save file is corrupted!\n[workers/" + worker + "]"
		
		if worker_data is not Dictionary:
			_err(errors, base_error + "\nWorker data is corrupted!")
			continue
		
		if not worker_data.has("name"):
			_err(errors, base_error + "\nWorker name not found!")
		elif worker_data["name"] is not String:
			_err(errors, base_error + "\nWorker name is corrupted!")
		
		if not worker_data.has("visible"):
			_err(errors, base_error + "\nWorker visibility not found!")
		elif worker_data["visible"] is not bool:
			_err(errors, base_error + "\nWorker visibility is corrupted!")
		
		if not worker_data.has("position"):
			_err(errors, base_error + "\nWorker position not found!")
		else:
			var pos = worker_data["position"]
			if pos is not Dictionary:
				_err(errors, base_error + "\nWorker position is corrupted!")
			elif not (pos.has("x") and pos.has("y")):
				_err(errors, base_error + "\nWorker position is corrupted!")
			else:
				if pos["x"] is not float and pos["x"] is not int:
					_err(errors, base_error + "\nWorker position X is corrupted!")
				if pos["y"] is not float and pos["y"] is not int:
					_err(errors, base_error + "\nWorker position Y is corrupted!")
		
		if not worker_data.has("pathfinding"):
			_err(errors, base_error + "\nWorker pathfinding not found!")
		elif worker_data["pathfinding"] is not Array:
			_err(errors, base_error + "\nWorker pathfinding is corrupted!")
		
		if not worker_data.has("inventory"):
			_err(errors, base_error + "\nWorker inventory not found!")
		elif worker_data["inventory"] is not Array:
			_err(errors, base_error + "\nWorker inventory is corrupted!")
		else:
			var inv: Array = worker_data["inventory"]
			for i in range(inv.size()):
				var slot = inv[i]
				var slot_error: String = "Save file is corrupted!\n[workers/" + worker + "/inventory/slot " + str(i + 1) + "]"
				
				if slot != null and slot is not Dictionary:
					_err(errors, slot_error + "\nInventory slot is corrupted!")
					continue
				
				if slot is Dictionary:
					if not slot.has("id") or not slot.has("amount"):
						_err(errors, slot_error + "\nInventory slot is corrupted!")
					elif slot["amount"] is not int:
						_err(errors, slot_error + "\nInventory slot amount is corrupted!")
	
	return errors


func building_structure_check(data: Dictionary, errors: Array[String], planet: Node2D) -> Array[String]:
	var building_head: Node2D = planet.get_node("Buildings")
	if not is_instance_valid(building_head):
		_err(errors, "Scene did not load correctly!")
		return errors
	
	if not data.has("buildings"):
		_err(errors, "Save file is corrupted!\nBuilding section does not exist!")
		return errors
	
	var building_section = data["buildings"]
	if building_section is not Array:
		_err(errors, "Save file is corrupted!\nBuilding section is corrupted!")
		return errors
	
	if building_section.is_empty():
		_err(errors, "Save file is corrupted!\nExpected at least 1 building. Found none.")
	
	for i in range(building_section.size()):
		var building_data = building_section[i]
		var building_name := "building_" + str(i + 1)
		var base_error := "Save file is corrupted!\n[buildings/" + building_name + "]"
		
		if building_data is not Dictionary:
			_err(errors, base_error + "\nBuilding data is corrupted!")
			continue
		
		if not building_data.has("name"):
			_err(errors, base_error + "\nBuilding name not found!")
		
		if not building_data.has("internal_id"):
			_err(errors, base_error + "\nBuilding internal ID not found!")
		
		if not building_data.has("level"):
			_err(errors, base_error + "\nBuilding level not found!")
		
		if not building_data.has("position"):
			_err(errors, base_error + "\nBuilding position not found!")
		else:
			var pos = building_data["position"]
			if pos is not Dictionary:
				_err(errors, base_error + "\nBuilding position is corrupted!")
			elif not (pos.has("x") and pos.has("y")):
				_err(errors, base_error + "\nBuilding position is corrupted!")
		
		if not building_data.has("inventories"):
			_err(errors, base_error + "\nBuilding inventories not found!")
		elif building_data["inventories"] is not Array:
			_err(errors, base_error + "\nBuilding inventories are corrupted!")
		else:
			var inventories: Array = building_data["inventories"]
			for j in range(inventories.size()):
				var inventory_data = inventories[j]
				var inventory_error := "Save file is corrupted!\n[buildings/" + building_name + "/inventories/inventory " + str(j + 1) + "]"
				
				if inventory_data is not Dictionary:
					_err(errors, inventory_error + "\nInventory data is corrupted!")
					continue
				
				if not inventory_data.has("name"):
					_err(errors, inventory_error + "\nInventory name not found!")
				
				if not inventory_data.has("inventory_id"):
					_err(errors, inventory_error + "\nInventory ID not found!")
				
				if not inventory_data.has("slots"):
					_err(errors, inventory_error + "\nInventory slots not found!")
				elif inventory_data["slots"] is not Array:
					_err(errors, inventory_error + "\nInventory slots are corrupted!")
				else:
					var slots: Array = inventory_data["slots"]
					for k in range(slots.size()):
						var slot = slots[k]
						var slot_error := "Save file is corrupted!\n[buildings/" + building_name + "/inventories/inventory " + str(j + 1) + "/slot " + str(k + 1) + "]"
						
						if slot != null and slot is not Dictionary:
							_err(errors, slot_error + "\nInventory slot is corrupted!")
							continue
						
						if slot is Dictionary and (not slot.has("id") or not slot.has("amount")):
							_err(errors, slot_error + "\nInventory slot is corrupted!")
		
		if building_data.has("jobs"):
			if building_data["jobs"] is not Array:
				_err(errors, base_error + "\nBuilding jobs are corrupted!")
			else:
				var jobs: Array = building_data["jobs"]
				for j in range(jobs.size()):
					var job_data = jobs[j]
					var job_error := "Save file is corrupted!\n[buildings/" + building_name + "/jobs/job " + str(j + 1) + "]"
					
					if job_data is not Dictionary:
						_err(errors, job_error + "\nJob data is corrupted!")
						continue
					
					if not job_data.has("job_id"):
						_err(errors, job_error + "\nJob ID not found!")
					if not job_data.has("recipe_row"):
						_err(errors, job_error + "\nJob recipe row not found!")
					if not job_data.has("recipe_id"):
						_err(errors, job_error + "\nJob recipe ID not found!")
					if not job_data.has("amount_to_produce"):
						_err(errors, job_error + "\nJob amount to produce not found!")
					if not job_data.has("work_left"):
						_err(errors, job_error + "\nJob work left not found!")
					if not job_data.has("assigned_worker"):
						_err(errors, job_error + "\nJob assigned worker not found!")
	
	return errors


func _err(errors: Array[String], msg: String) -> void:
	push_error(msg)
	errors.append(msg)
