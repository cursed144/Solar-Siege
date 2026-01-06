class_name Building
extends Area2D

signal request_inv_update(inv_name: String)
signal request_worker_rows_update
signal destroyed

const work_timer := preload("res://Planet-Section/Scenes/work_timer.tscn")

@export_category("Workers")
@export var max_workers: int = 3
@export var worker_limit: int = 1

@export_category("Inventory")
@export var inv_input_name: String = "Input"
@export var inv_output_name: String = "Output"

@export_category("Production")
@export var recipes: Array[Recipe]

var assigned_workers: Array = []
var inventories: Dictionary[String, Inventory] = {}
var production_multiplier: float = 1.0
var building_level: int = 1

@onready var build_info: Control = get_node("../../UI/BuildingInfo")


func _ready() -> void:
	# Align sprite to tilemap cells
	var tilemap: TileMapLayer = get_parent()
	var cell_size = tilemap.tile_set.tile_size
	$Sprite2D.offset = -cell_size / 2
	
	add_inv(inv_input_name, 10)
	add_inv(inv_output_name, 15)
	
	var item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var item_stack = ItemStack.new_stack(item, 10)
	inventories[inv_input_name].add_item_to_inv(item_stack)
	
	var limit = worker_limit
	worker_limit = 0
	for i in range(limit):
		increment_worker_rows()


func inv_changed(inv: Inventory) -> void:
	var inv_name = inventories.find_key(inv)
	if inv_name != null:
		request_inv_update.emit(inv_name)


func add_inv(inv_name: String, slot_amount: int) -> void:
	inventories[inv_name] = Inventory.new_inv(slot_amount)
	inventories[inv_name].inv_changed.connect(inv_changed)


func assign_recipe_to_row(recipe: Recipe, amount_to_make: int, row_num: int) -> void:
	var row = $WorkerRows.get_node(str(row_num))
	if $WorkerRows.get_node(str(row_num)) == null:
		push_error("Failed to find row with number: " + str(row_num))
	
	row.assign_recipe(recipe, amount_to_make)
	request_worker_rows_update.emit()


## Returns if successful
func increment_worker_rows() -> bool:
	if worker_limit == max_workers:
		return false
	
	worker_limit += 1
	request_worker_rows_update.emit()
	
	var new_work_timer = work_timer.instantiate()
	$WorkerRows.add_child(new_work_timer)
	new_work_timer.name = str(worker_limit)
	return true


## Returns if successful
func decrement_worker_rows() -> bool:
	if worker_limit <= 0:
		return false
	
	worker_limit -= 1
	request_worker_rows_update.emit()
	$WorkerRows.get_child(-1).queue_free()
	return true


func _on_click_area_pressed() -> void:
	# call the UI manager
	if build_info:
		build_info.building_clicked(self)


func _exit_tree() -> void:
	emit_signal("destroyed")
