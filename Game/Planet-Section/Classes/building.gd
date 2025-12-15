class_name Building
extends Area2D

@export var inventories: Dictionary[String, Inventory]
@onready var build_info: Control = get_node("../../UI/BuildingInfo")

signal request_update


func _ready() -> void:
	add_inv("Input", 10)
	add_inv("Output", 15)
	var item = load("res://Planet-Section/Resources/Items/wood_log.tres")
	var item_stack = ItemStack.new_stack(item, 10)
	inventories["Input"].add_items_to_inv([item_stack])
	pass


func add_inv(inv_name: String, slot_amount: int):
	inventories[inv_name] = Inventory.new_inv(slot_amount)


func _on_click_area_pressed() -> void:
	build_info.building_clicked(self)
