extends Area2D

class BuildingOption:
	var building_pos: Vector2
	var inventory: Inventory
	var score: float
	
	static func init(_building_pos: Vector2, _inventory: Inventory, _score: float) -> BuildingOption:
		var new_option = BuildingOption.new()
		new_option.building_pos = _building_pos
		new_option.inventory = _inventory
		new_option.score = _score
		return new_option
	
	## The first element has the highest score
	static func sort_by_score(a: BuildingOption, b: BuildingOption):
		if a.score > b.score:
			return true
		return false


signal dest_reached

const INV_SLOT := preload("res://Planet-Section/Scenes/UI/inv_slot.tscn")
const ARRIVE_DISTANCE := 10.0
const SPEED = 150

var current_job: WorkController = null
var path := []

@onready var head = get_parent()
@onready var inv := Inventory.new_inv(3)
@onready var destination := global_position


func _ready() -> void:
	inv.inv_changed.connect(update_inv)
	create_slots()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		empty_inventory()


func _physics_process(delta: float) -> void:
	if !path.is_empty():
		position = position.move_toward(path[0], SPEED*delta)
		if position.distance_to(path[0]) < ARRIVE_DISTANCE:
			path.pop_front()
			if path.is_empty():
				dest_reached.emit()


# -----------------------
# Job handling
# -----------------------

func get_job() -> void:
	var new_job: WorkController = head.get_from_available_jobs()
	if is_instance_valid(new_job):
		new_job.assigned_worker = self
		current_job = new_job
		handle_job()


func handle_job() -> void:
	if not is_instance_valid(current_job):
		abandon_job()
		return
	
	var status = current_job.prepare_for_work()
	match status:
		WorkController.WorkState.READY:
			work_in_building()
		WorkController.WorkState.NEED_SUPPLY:
			supply_building()
		WorkController.WorkState.NEED_EMPTY:
			empty_building_output()
		WorkController.WorkState.FINISHED:
			await empty_building_output()
			abandon_job()


func abandon_job() -> void:
	current_job = null
	get_job()
	show()


# -----------------------
# Job execution
# -----------------------

func work_in_building() -> void:
	await go_to(current_job.building.global_position)
	
	if not is_instance_valid(current_job):
		handle_job()
		return
	
	current_job.start_work()
	hide()
	await current_job.alert_work_finished
	handle_job()


func empty_building_output() -> void:
	show()
	while true:
		get_items_from_building_output()
		var more_work = await empty_inventory()
		if not more_work:
			break


func supply_building() -> void:
	show()
	var reqs: Array[ItemAmount] = current_job.assigned_recipe.requirements
	var amount_to_make: int = current_job.amount_to_produce
	var building = current_job.building
	var input_inv: Inventory = building.inventories[building.inv_input_name]
	
	var available_list := get_available_items_for_reqs(reqs)
	available_list.sort_custom(ItemAmount.sort_by_amount_asce)
	
	var item_map := get_best_mapping(available_list, amount_to_make)
	if item_map.is_empty():
		return
	
	claim_mapping(item_map)
	for option: BuildingOption in item_map.keys():
		await go_to(option.building_pos)
		var claim = option.inventory.get_claimed_items(name)
		inv.add_items_to_inv(claim)
	
	await go_to(building.global_position)
	inv.create_claim(name, inv.strip_slots())
	input_inv.add_items_to_inv(inv.get_claimed_items(name))
	
	handle_job()


# -----------------------
# Utility for supplying
# -----------------------

## Returns a list of the requirements where the first is the one with smallest amount in the input inventory in the building in which we are working
func find_top_storages_with_item(item: Item, top: int = 3) -> Array[BuildingOption]:
	var planet = get_tree().current_scene
	var global_storage: Dictionary = planet.global_storage
	var list: Array[BuildingOption] = []
	
	for storage: Inventory in global_storage.keys():
		var build_pos: Vector2 = global_storage[storage]
		var score = storage.get_total_item_amount(item)
		var option = BuildingOption.init(build_pos, storage, score)
		list.append(option)
	
	list.sort_custom(BuildingOption.sort_by_score)
	return list.slice(0, top)


func map_storages_with_item(available_item: ItemAmount, amount_to_make: int) -> Dictionary[BuildingOption, ItemAmount]:
	var job_req = current_job.get_requirement_by_item(available_item.item)
	var storages = find_top_storages_with_item(available_item.item, 3)
	var map_total: Dictionary[BuildingOption, ItemAmount] = {}
	var simulated_inv = inv.duplicate(true)
	
	for storage in storages:
		var in_storage = storage.inventory.get_total_item_amount(available_item.item)
		var recipe_limit = (job_req.amount * amount_to_make) - available_item.amount
		var to_get = min(in_storage, recipe_limit)
		var final_fetch := ItemAmount.new_amount(available_item.item, to_get)
		var can_fit_in_inv = simulated_inv.how_much_of_item_fits(final_fetch)
		
		final_fetch.amount = min(final_fetch.amount, can_fit_in_inv)
		simulated_inv.add_items_to_inv(final_fetch.to_stack())
		map_total[storage] = final_fetch
	
	var total = 0
	for item_amount in map_total.values():
		total += item_amount.amount
	
	if (total + available_item.amount) < job_req.amount:
		return {}
	else:
		return map_total


func get_available_items_for_reqs(reqs: Array[ItemAmount]) -> Array[ItemAmount]:
	var available_list: Array[ItemAmount]
	
	for item_amount in reqs:
		available_list.append(
			ItemAmount.new_amount(
				item_amount.item,
				current_job.get_available_amount_of_item(item_amount.item)))
	
	return available_list


func get_best_mapping(available_items: Array[ItemAmount], amount_to_make: int) -> Dictionary[BuildingOption, ItemAmount]:
	var item_map: Dictionary[BuildingOption, ItemAmount] = {}
	
	for available_item in available_items:
		item_map = map_storages_with_item(available_item, amount_to_make)
		
		if not item_map.is_empty():
			break
	
	return item_map


func claim_mapping(map: Dictionary[BuildingOption, ItemAmount]):
	for option: BuildingOption in map.keys():
		option.inventory.create_claim(
			name,
			ItemAmount.new_amount(
				map[option].item,
				map[option].amount
				).to_stack()
			)


func get_items_from_building_output() -> void:
	var build: ProductionBuilding = current_job.building
	var build_inv := build.inventories[build.inv_output_name]
	var items = build_inv.strip_slots()
	var space = inv.slots.size()
	
	var claim: Array[ItemStack] = []
	for item_stack in items:
		var amount_to_take = inv.how_much_of_item_fits(item_stack.to_amount())
		if amount_to_take <= 0: continue
		claim.append(ItemStack.new_stack(item_stack.item, amount_to_take))
		
		space -= 1
		if space <= 0:
			break
	
	build_inv.create_claim(name, claim)
	inv.add_items_to_inv(build_inv.get_claimed_items(name))


# -----------------------
# Utility for emptying
# -----------------------

## Returns if possible
func empty_inventory() -> bool:
	var choice = get_best_empty_storage()
	if not is_instance_valid(choice):
		return false
	if inv.strip_slots().is_empty():
		return false
	
	await go_to(choice.building_pos)
	var items_to_store := inv.strip_slots()
	var available_space = choice.inventory.how_many_items_fit(ItemStack.stacks_to_amounts(items_to_store))
	for i in range(items_to_store.size()):
		items_to_store[i].amount = available_space[i]
	
	inv.create_claim(name, items_to_store)
	items_to_store = inv.get_claimed_items(name)
	choice.inventory.add_items_to_inv(items_to_store)
	
	return true


func get_best_empty_storage(from_pos := global_position) -> BuildingOption:
	var options := get_storage_options_for_empty(from_pos)
	options.sort_custom(BuildingOption.sort_by_score)
	
	var choice: BuildingOption = options.pop_front()
	return choice


func get_storage_options_for_empty(from_pos := global_position) -> Array[BuildingOption]:
	var planet = get_tree().current_scene
	var global_storage: Dictionary = planet.global_storage
	var list: Array[BuildingOption] = []
	
	for storage: Inventory in global_storage.keys():
		var build_pos: Vector2 = global_storage[storage]
		var score = 1
		
		for slot in inv.slots:
			if is_instance_valid(slot):
				score += storage.how_much_of_item_fits(slot.to_amount())
		
		var final_score = (score * 2) * 100 / (from_pos.distance_to(build_pos)) # Score is multiplied by 2 to prefer more empty storages
		var option = BuildingOption.init(build_pos, storage, final_score)
		list.append(option)
	
	return list


# -----------------------
# Inventory visual display
# -----------------------

func create_slots() -> void:
	for child in $InvSlots.get_children():
		child.queue_free()
	
	for i in range(inv.slots.size()):
		var slot = INV_SLOT.instantiate()
		$InvSlots.add_child(slot)
	
	update_inv(inv)

func update_inv(inventory) -> void:
	if $InvSlots.get_child_count() == inventory.slots.size():
		for i in range(inventory.slots.size()):
			$InvSlots.get_child(i).set_slot(inventory.slots, i)
	else:
		create_slots()


# -----------------------
# Pathfinding
# -----------------------

func go_to(dest: Vector2) -> void:
	destination = dest
	set_astar_path(dest)
	await dest_reached


func set_astar_path(dest: Vector2) -> void:
	var start_astar = world_to_astar_cell(global_position)
	var end_astar = world_to_astar_cell(dest)
	
	# if the point is solid because of a building, the cell to the left is chosen
	while(head.astar.is_point_solid(end_astar)):
		end_astar.x -= 1
	
	var id_path : Array = head.astar.get_id_path(start_astar, end_astar, false)
	path.clear()
	for cell in id_path:
		path.append(astar_cell_center(cell))


func world_to_astar_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - head.astar.offset
	return Vector2i(floor(local.x / head.astar.cell_size.x), floor(local.y / head.astar.cell_size.y))

func astar_cell_center(cell: Vector2i) -> Vector2:
	return head.astar.offset + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * head.astar.cell_size


# -----------------------
# Mouse detection for display
# -----------------------

func _on_mouse_entered() -> void:
	$InvSlots.show()

func _on_mouse_exited() -> void:
	$InvSlots.hide()
