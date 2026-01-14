class_name Building
extends Area2D

signal request_inv_update(inv_name: String)
signal request_worker_rows_update
signal destroyed

const WORK_CONTROLLER := preload("res://Planet-Section/Scenes/work_controller.tscn")

@export_category("Workers")
@export_range(0, 99) var max_workers: int = 3

@export_category("Inventory")
@export var inv_input_name: String = "Input"
@export var inv_input_size: int = 0
@export var inv_output_name: String = "Output"
@export var inv_output_size: int = 0

@export_category("Production")
@export var recipes: Array[Recipe]

var assigned_workers: Array = []
var inventories: Dictionary[String, Inventory] = {}
var production_multiplier: float = 1.0
var level: int = 0
var worker_limit: int = 0

@onready var build_info: Control = get_node("../../UI/BuildingInfo")


func _ready() -> void:
	# Align elements to tilemap cells
	var tilemap: TileMapLayer = get_parent()
	var cell_size := tilemap.tile_set.tile_size as Vector2
	$Sprite2D.offset = -cell_size / 2
	$CollisionShape2D.position -= cell_size / 2
	$ClickArea.position -= cell_size / 2
	
	if inv_input_size > 0:
		add_inv(inv_input_name, inv_input_size)
	if inv_output_size > 0:
		add_inv(inv_output_name, inv_output_size)
	
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
	cancel_all_recipes()
	$ClickArea.disabled = true
	$ClickArea.mouse_default_cursor_shape = Control.CURSOR_ARROW
	$AnimationPlayer.play("upgrade")
	$UpgradeTimer.start(time)

func _on_upgrade_timer_timeout() -> void:
	level += 1
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


# Remove the building from the planet
func destroy() -> void:
	var planet = get_tree().current_scene
	planet.remove_building(self)
	destroyed.emit()
	queue_free()
