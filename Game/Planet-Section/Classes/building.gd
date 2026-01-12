class_name Building
extends Area2D

signal request_inv_update(inv_name: String)
signal request_worker_rows_update
signal destroyed

const WORK_CONTROLLER := preload("res://Planet-Section/Scenes/work_controller.tscn")

@export_category("Workers")
@export var max_workers: int = 3
@export var worker_limit: int = 0

@export_category("Inventory")
@export var inv_input_name: String = "Input"
@export var inv_output_name: String = "Output"

@export_category("Production")
@export var recipes: Array[Recipe]

var work_in_progress := false
var assigned_workers: Array = []
var inventories: Dictionary[String, Inventory] = {}
var production_multiplier: float = 1.0
var level: int = 0

@onready var build_info: Control = get_node("../../UI/BuildingInfo")


func _ready() -> void:
	# Align elements to tilemap cells
	var tilemap: TileMapLayer = get_parent()
	var cell_size := tilemap.tile_set.tile_size as Vector2
	$Sprite2D.offset = -cell_size / 2
	$CollisionShape2D.position -= cell_size / 2
	$ClickArea.position -= cell_size / 2
	
	add_inv(inv_input_name, 10)
	add_inv(inv_output_name, 15)
	
	var item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var item_stack = ItemStack.new_stack(item, 10)
	inventories[inv_input_name].add_item_to_inv(item_stack)
	
	var limit = worker_limit
	worker_limit = 0
	for i in range(limit):
		increment_worker_rows()


func assign_recipe_to_row(recipe: Recipe, amount_to_make: int, row_num: int) -> void:
	var row = $WorkerRows.get_node(str(row_num))
	if $WorkerRows.get_node(str(row_num)) == null:
		push_error("Failed to find row with number: " + str(row_num))
	
	row.assign_recipe(recipe, amount_to_make)
	request_worker_rows_update.emit()


func cancel_recipe_on_row(row_num: int):
	var row = $WorkerRows.get_node(str(row_num))
	if $WorkerRows.get_node(str(row_num)) == null:
		push_error("Failed to find row with number: " + str(row_num))
	
	row.cancel_production()
	request_worker_rows_update.emit()


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


func _on_click_area_pressed() -> void:
	# call the UI manager
	if build_info:
		build_info.building_clicked(self)


func begin_upgrade(time: float) -> void:
	work_in_progress = true
	$ClickArea.disabled = true
	$ClickArea.mouse_default_cursor_shape = Control.CURSOR_ARROW
	$AnimationPlayer.play("upgrade")
	$UpgradeTimer.start(time)

func _on_upgrade_timer_timeout() -> void:
	level += 1
	work_in_progress = false
	$ClickArea.disabled = false
	$ClickArea.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	$AnimationPlayer.play("RESET")


func inv_changed(inv: Inventory) -> void:
	var inv_name = inventories.find_key(inv)
	if inv_name != null:
		request_inv_update.emit(inv_name)


func add_inv(inv_name: String, slot_amount: int) -> void:
	inventories[inv_name] = Inventory.new_inv(slot_amount)
	inventories[inv_name].inv_changed.connect(inv_changed)


func destroy() -> void:
	destroyed.emit()
	queue_free()
