class_name WorkController
extends Node

signal alert_work_finished(recipe: Recipe)

enum WorkState {
	READY,
	NEED_SUPPLY,
	NEED_EMPTY,
	FINISHED
}

const MAX_FAILS: int = 3

var assigned_worker = null
var assigned_recipe: Recipe = null
var amount_to_produce: int = 0
var used_materials: Array[ItemStack]
var fail_count: int = 0

@onready var building: ProductionBuilding = get_node("../../")


func _ready() -> void:
	alert_work_finished.connect(building.recipe_finished)


func assign_recipe(recipe: Recipe, amount: int = 1):
	assigned_recipe = recipe
	amount_to_produce = amount
	$Timer.wait_time = recipe.creation_time / building.production_multiplier
	
	building.worker_head.add_job(self)


func prepare_for_work() -> WorkState:
	if amount_to_produce <= 0:
		return WorkState.FINISHED
	
	var check = can_work_start()
	if check == WorkState.READY:
		var input_inv: Inventory = building.inventories.get(building.inv_input_name)
		var requirements := ItemAmount.amounts_to_stacks(assigned_recipe.requirements)
		
		if is_instance_valid(input_inv):
			input_inv.create_claim(name, requirements)
			used_materials = input_inv.get_claimed_items(name)
	
	return check


func _on_timeout() -> void:
	var recipe: Recipe = assigned_recipe
	work_finished()
	alert_work_finished.emit(recipe)
	building.request_worker_rows_update.emit()


func start_work() -> void:
	$Timer.start()
	$Timer.paused = false

func pause_work() -> void:
	$Timer.paused = true

func resume_work() -> void:
	$Timer.paused = false

func work_finished() -> void:
	amount_to_produce -= 1
	if amount_to_produce <= 0:
		used_materials.clear()
		assigned_recipe = null


func cancel_production() -> void:
	var input_inv: Inventory = building.get(building.inv_input_name)
	if input_inv != null:
		input_inv.add_items_to_inv(used_materials)
	
	used_materials.clear()
	assigned_recipe = null
	amount_to_produce = 0
	alert_work_finished.emit(null)
	building.worker_head.remove_job(self)
	$Timer.stop()


## Returns true when the timer is running (i.e. production in progress)
func is_producing() -> bool:
	return ($Timer.time_left > 0)


func is_work_required() -> bool:
	if amount_to_produce > 0:
		return true
	else:
		return false


func can_work_start() -> WorkState:
	var inventories: Dictionary[String, Inventory] = building.inventories
	var input_inv: Inventory = inventories.get(building.inv_input_name)
	var output_inv: Inventory = inventories.get(building.inv_output_name)
	
	# Check if there is enough space in the output
	var output_items := assigned_recipe.outputs
	var fitting := output_inv.how_many_items_fit(output_items)
	for i in range(output_items.size()):
		if output_items[i].amount != fitting[i]:
			return WorkState.NEED_EMPTY
	
	# Check if there are enough materials for at least 1 work
	for item_amount in assigned_recipe.requirements:
		if input_inv.get_total_item_amount(item_amount.item) < item_amount.amount:
			return WorkState.NEED_SUPPLY
	
	return WorkState.READY


func get_possible_job_amount_for_item(item: Item, extra: int = 0) -> int:
	var in_inv = get_available_amount_of_item(item)
	var total: int = in_inv + extra
	
	@warning_ignore("integer_division")
	return total / assigned_recipe.find_requirement_by_item(item).amount


func get_available_amount_of_item(item: Item) -> int:
	var input := building.inventories[building.inv_input_name]
	var in_inv: int = input.get_total_item_amount(item)
	return in_inv


func get_requirement_by_item(item: Item) -> ItemAmount:
	var ret = null
	
	for req in assigned_recipe.requirements:
		if req.item == item:
			ret = req
			break
	
	return ret


func _exit_tree() -> void:
	alert_work_finished.disconnect(building.recipe_finished)
	cancel_production()
