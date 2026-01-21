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
@onready var inv := Inventory.new_inv(2)
@onready var destination := global_position


func _ready() -> void:
	inv.inv_changed.connect(update_inv)
	create_slots()
	var log = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var rock = load("res://Planet-Section/Resources/Items/rock.tres")
	inv.add_item_to_inv(ItemStack.new_stack(log, 10))

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
		WorkController.WorkState.NEED_EMPTY:
			pass
		WorkController.WorkState.FINISHED:
			abandon_job()


func abandon_job() -> void:
	current_job = null
	get_job()
	show()


# -----------------------
# Job execution
# -----------------------

func work_in_building() -> void:
	go_to(current_job.building.global_position)
	await dest_reached
	hide()
	current_job.start_work()
	await current_job.alert_work_finished
	handle_job()


func get_from_building() -> void:
	#claim items from building
	empty_inventory()


func empty_inventory() -> void:
	var choice = get_best_building()
	if not is_instance_valid(choice):
		return
	
	go_to(choice.building_pos)
	await dest_reached
	var items_to_store := inv.strip_slots()
	var available_space = choice.inventory.how_many_items_fit(items_to_store)
	for i in range(items_to_store.size()):
		items_to_store[i].amount = available_space[i]
	
	inv.create_claim(name, items_to_store)
	items_to_store = inv.get_claimed_items(name)
	choice.inventory.add_items_to_inv(items_to_store)


func get_best_building(from_pos := global_position) -> BuildingOption:
	var options := get_building_options(from_pos)
	options.sort_custom(BuildingOption.sort_by_score)
	
	var choice: BuildingOption = options.pop_front()
	return choice


func get_building_options(from_pos := global_position) -> Array[BuildingOption]:
	var planet = get_tree().current_scene
	var global_storage: Dictionary = planet.global_storage
	var list: Array[BuildingOption] = []
	
	for storage: Inventory in global_storage.keys():
		var build_pos: Vector2 = global_storage[storage]
		var score = 1
		
		for slot in inv.slots:
			if is_instance_valid(slot):
				score += storage.how_much_of_item_fits(slot)
		
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
