class_name Building
extends Area2D

signal request_inv_update(inv_name: String)

@export_category("Workers")
@export var max_workers: int = 3
@export var worker_limit: int = 1

@export_category("Inventory")
@export var inv_input_name: String
@export var inv_output_name: String

var assigned_workers: Array = []
var inventories: Dictionary[String, Inventory]
@onready var build_info: Control = get_node("../../UI/BuildingInfo")


func _ready() -> void:
	add_inv(inv_input_name, 10)
	add_inv(inv_output_name, 15)
	var item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var item_stack = ItemStack.new_stack(item, 10)
	inventories[inv_input_name].add_item_to_inv(item_stack)


func inv_changed(inv: Inventory) -> void:
	var inv_name = inventories.find_key(inv)
	request_inv_update.emit(inv_name)


func add_inv(inv_name: String, slot_amount: int):
	inventories[inv_name] = Inventory.new_inv(slot_amount)
	inventories[inv_name].inv_changed.connect(inv_changed)


func _on_click_area_pressed() -> void:
	build_info.building_clicked(self)
