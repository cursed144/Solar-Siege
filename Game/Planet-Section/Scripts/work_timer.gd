extends Timer

var assingned_worker
var assigned_recipe: Recipe = null
var amount_to_produce: int = 0
@onready var building: Building = get_node("../../")


func assign_recipe(recipe: Recipe, amount: int = 1):
	assigned_recipe = recipe
	amount_to_produce = amount
	wait_time = recipe.creation_time
	
	start()
	paused = true
	start_work()


func is_work_required() -> bool:
	if amount_to_produce > 0:
		return true
	else:
		return false


func start_work() -> void:
	paused = false

func pause_work() -> void:
	paused = true

func cancel_production() -> void:
	assigned_recipe = null
	amount_to_produce = 0
	stop()


func _on_timeout() -> void:
	var output = building.inventories[building.inv_output_name]
	output.add_items_to_inv(Recipe.amounts_to_stacks(assigned_recipe.outputs))
	
	amount_to_produce -= 1
	if amount_to_produce <= 0:
		cancel_production()
	
	building.request_worker_rows_update.emit()
