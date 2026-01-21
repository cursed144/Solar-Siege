class_name ProductionBuilding
extends Building

signal request_inv_update(inv_name: String)
signal request_worker_rows_update

const WORK_CONTROLLER := preload("res://Planet-Section/Scenes/work_controller.tscn")

@export_category("Workers")
@export_range(0, 99) var max_workers: int = 3

@export_category("Inventory")
@export var inv_input_name: String = "Input"
@export_range(1, 999) var inv_input_size: int = 0
@export var inv_output_name: String = "Output"
@export_range(1, 999) var inv_output_size: int = 0

@export_category("Production")
@export var recipes: Array[Recipe]

var worker_limit: int = 0
var assigned_workers: Array = []
var production_multiplier: float = 1.0

@onready var build_info: Control = get_node("../../UI/BuildingInfo")
@onready var worker_head = get_node("../../WorkerHead")


func _ready() -> void:
	super._ready()
	
	add_inv(inv_input_name, inv_input_size)
	add_inv(inv_output_name, inv_output_size)
	
	var limit = worker_limit
	worker_limit = 0
	for i in range(limit):
		increment_worker_rows()
	
	var work_rows = Node.new()
	work_rows.name = "WorkerRows"
	add_child(work_rows)

# -----------------------
# Clicking
# -----------------------

func _on_click_area_pressed() -> void:
	# call the UI manager
	if build_info:
		build_info.building_clicked(self)


# -----------------------
# Recipes
# -----------------------

func assign_recipe_to_row(recipe: Recipe, amount_to_make: int, row_num: int) -> void:
	var row = $WorkerRows.get_node(str(row_num))
	if $WorkerRows.get_node(str(row_num)) == null:
		push_error("Failed to find row with number: " + str(row_num))
	
	row.assign_recipe(recipe, amount_to_make)
	request_worker_rows_update.emit()


func recipe_finished(recipe: Recipe) -> void:
	if not is_instance_valid(recipe):
		return
	var output = inventories[inv_output_name]
	output.add_items_to_inv(ItemAmount.amounts_to_stacks(recipe.outputs))


func cancel_recipe_on_row(row_num: int) -> void:
	var row = $WorkerRows.get_node(str(row_num))
	if $WorkerRows.get_node(str(row_num)) == null:
		push_error("Failed to find row with number: " + str(row_num))
	
	row.cancel_production()
	request_worker_rows_update.emit()


func cancel_all_recipes() -> void:
	for job: WorkController in $WorkerRows.get_children():
		job.cancel_production()
	
	request_worker_rows_update.emit()


# -----------------------
# Worker Rows
# -----------------------

## Returns if successful
func increment_worker_rows() -> bool:
	if worker_limit == max_workers:
		return false
	
	worker_limit += 1
	request_worker_rows_update.emit()
	
	var new_work_controller = WORK_CONTROLLER.instantiate()
	$WorkerRows.add_child(new_work_controller)
	new_work_controller.name = str(worker_limit)
	return true


## Returns if successful
func decrement_worker_rows() -> bool:
	if worker_limit <= 0:
		return false
	
	worker_limit -= 1
	request_worker_rows_update.emit()
	$WorkerRows.get_child(-1).queue_free()
	return true


# -----------------------
# Upgrade
# -----------------------

func begin_upgrade(time: float) -> void:
	cancel_all_recipes()
	super.begin_upgrade(time)


# -----------------------
# Inventory
# -----------------------

func inv_changed(inv: Inventory) -> void:
	var inv_name = inventories.find_key(inv)
	if inv_name != null:
		request_inv_update.emit(inv_name)


func add_inv(inv_name: String, slot_amount: int) -> void:
	inventories[inv_name] = Inventory.new_inv(slot_amount)
	inventories[inv_name].inv_changed.connect(inv_changed)


# -----------------------
# When destroyed
# -----------------------

func destroy() -> void:
	for job: WorkController in $WorkerRows.get_children():
		job.cancel_production()
	
	super.destroy()
