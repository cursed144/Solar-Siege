extends Control

signal slot_clicked(building: Building, slot_num: int)

var building: Building = null
var has_item := false


func init(_building: Building) -> void:
	building = _building
	
	if building.recipes.size() <= 1:
		$HBoxContainer/Slot.disabled = true
		$HBoxContainer/Slot.mouse_default_cursor_shape = Control.CURSOR_ARROW
		$HBoxContainer/Slot.self_modulate = Color.from_rgba8(0, 115, 0, 255)
	if building.recipes.size() == 1:
		$HBoxContainer/Slot/Item.texture = building.recipes.get(0).display_icon
		has_item = true


func set_display_item(recipe: Recipe, amount: int) -> void:
	if not is_instance_valid(recipe):
		$HBoxContainer/Slot/Item.texture = null
		$HBoxContainer/Slot/Amount.text = ""
		$HBoxContainer/Slot.self_modulate = Color(1,1,1)
	else:
		$HBoxContainer/Slot/Item.texture = recipe.display_icon
		$HBoxContainer/Slot/Amount.text = "x" + str(amount)
		$HBoxContainer/Slot.self_modulate = Color.from_rgba8(0, 168, 0, 255)


func _on_slot_pressed() -> void:
	slot_clicked.emit(building, int(name))
