class_name WorkController
extends Node

signal alert_work_finished(recipe: Recipe)
signal alert_work_cancelled

enum WorkState {
	READY,
	NEED_SUPPLY,
	NEED_EMPTY
}

var assigned_recipe: Recipe = null
var amount_to_produce: int = 0
var used_materials: Array[ItemStack]

@onready var building: Building = get_node("../../")


func _ready() -> void:
	alert_work_finished.connect(building.recipe_finished)


func assign_recipe(recipe: Recipe, amount: int = 1):
	assigned_recipe = recipe
	amount_to_produce = amount
	$Timer.wait_time = recipe.creation_time / building.production_multiplier
	
	prepare_for_work()


func prepare_for_work() -> WorkState:
	var check = can_work_start()
	if check == WorkState.READY:
		var input_inv: Inventory = building.inventories.get(building.inv_input_name)
		var requirements := ItemAmount.amounts_to_stacks(assigned_recipe.requirements)
		
		if is_instance_valid(input_inv):
			input_inv.create_claim(name, requirements)
			used_materials = input_inv.get_claimed_items(name)
		start_work()
	
	return check


func _on_timeout() -> void:
	alert_work_finished.emit(assigned_recipe)
	work_finished()
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
	var input_inv := building.inventories[building.inv_input_name]
	input_inv.add_items_to_inv(used_materials)
	used_materials.clear()
	assigned_recipe = null
	amount_to_produce = 0
	alert_work_cancelled.emit()
	$Timer.stop()


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
	var output_items := ItemAmount.amounts_to_stacks(assigned_recipe.outputs)
	var fitting := output_inv.how_many_items_fit(output_items)
	for i in range(output_items.size()):
		if output_items[i].amount != fitting[i]:
			return WorkState.NEED_EMPTY
	
	# Check if there are enough materials for at least 1 work
	for item_amount in assigned_recipe.requirements:
		if input_inv.get_total_item_amount(item_amount.item) < item_amount.amount:
			return WorkState.NEED_SUPPLY
	
	return WorkState.READY


func _exit_tree() -> void:
	alert_work_finished.disconnect(building.recipe_finished)
	cancel_production()
