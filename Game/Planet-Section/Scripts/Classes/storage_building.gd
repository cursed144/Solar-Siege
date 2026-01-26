class_name StorageBuilding
extends Building

signal request_inv_update(inv_name: String)

@export_category("Inventory")
@export var inv_storage_name: String = "Storage"
@export_range(1, 999) var inv_storage_size: int = 0

@onready var build_info: Control = get_node("../../UI/BuildingInfo")


func _ready() -> void:
	super._ready()
	
	add_inv(inv_storage_name, inv_storage_size)
	var log = load("res://Planet-Section/Resources/Items/wood_log.tres")
	inventories[inv_storage_name].add_item_to_inv(ItemStack.new_stack(log, 40))
	
	
	var planet = get_tree().current_scene
	for inv in inventories.values():
		planet.global_storage[inv] = global_position


# -----------------------
# Clicking
# -----------------------

func _on_click_area_pressed() -> void:
	# call the UI manager
	if build_info:
		build_info.building_clicked(self)


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


func destroy() -> void:
	var planet = get_tree().current_scene
	for inv in inventories:
		planet.global_storage.erase(inv)
	
	super.destroy()
