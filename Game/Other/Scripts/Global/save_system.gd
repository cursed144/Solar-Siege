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
	
	#save_workers(save_data, planet)
	save_buildings(save_data, planet)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	return true


func load_scene() -> bool:
	var planet: Node2D = get_tree().current_scene
	var planet_name: String = planet.name.to_lower()
	var path: String = "user://planets/" + planet_name + "/save.json"
	
	if not FileAccess.file_exists(path):
		push_warning("Save file does not exist: " + path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file: " + path)
		return false
	
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	
	if data == null:
		push_error("Save file is invalid JSON.")
		return false
	
	load_workers(data, planet)
	
	return true


func save_workers(save_data: Dictionary, planet: Node2D) -> void:
	var worker_head: Node2D = planet.get_node("WorkerHead")
	for i in range(worker_head.get_child_count()):
		var worker = worker_head.get_child(i)
		var internal_id := "worker_" + str(i+1)
		
		save_data["workers"][internal_id] = {
			"position": {
				"x": worker.global_position.x,
				"y": worker.global_position.y
			},
			"name": worker.name,
			"visible": worker.visible,
			"inventory": {},
			"pathfinding": []
		}
		
		for j in range(worker.inv.slots.size()):
			var slot = worker.inv.slots[j]
			
			if not is_instance_valid(slot):
				save_data["workers"][internal_id]["inventory"]["slot_" + str(j+1)] = null
			else:
				save_data["workers"][internal_id]["inventory"]["slot_" + str(j+1)] = {
					"id": slot.item.id,
					"amount": slot.amount
				}
		
		save_data["workers"][internal_id]["pathfinding"] = worker.path


func load_workers(data: Dictionary, planet: Node2D) -> void:
	var worker_head: Node2D = planet.get_node("WorkerHead")
	var workers_data: Dictionary = data["workers"]
	
	for worker_name in workers_data.keys():
		var inv_data: Dictionary = workers_data[worker_name]["inventory"]
		var new_worker = WORKER_SCENE.instantiate()
		new_worker.name = workers_data[worker_name]["name"]
		worker_head.add_child(new_worker)
		
		var position = workers_data[worker_name]["position"]
		position = Vector2(position["x"], position["y"])
		new_worker.global_position = position
		
		new_worker.create_inv(inv_data.size())
		for slot: String in inv_data.keys():
			var slot_num := int(slot.erase(0, 5))
			
			if inv_data[slot] != null:
				var item_id: ItemLoader.ItemID = inv_data[slot]["id"]
				var item_amount: int = inv_data[slot]["amount"]
				var item = ItemLoader.based_on_id(item_id)
				var new_stack := ItemStack.new_stack(item, item_amount)
				new_worker.inv.slots[slot_num] = new_stack


func save_buildings(save_data: Dictionary, planet: Node2D) -> void:
	pass
