extends Control

signal slot_clicked(building: Building, slot_num: int, delete: bool)

var building: Building = null
var has_item := false


func init(_building: Building) -> void:
	building = _building


func set_display_item(recipe: Recipe, amount: int) -> void:
	if not is_instance_valid(recipe):
		$HBoxContainer/Slot/Item.texture = null
		$HBoxContainer/Slot/Amount.text = ""
		$HBoxContainer/Slot.self_modulate = Color(1,1,1)
		has_item = false
	else:
		$HBoxContainer/Slot/Item.texture = recipe.display_icon
		$HBoxContainer/Slot/Amount.text = "x" + str(amount)
		$HBoxContainer/Slot.self_modulate = Color.from_rgba8(0, 168, 0, 255)
		has_item = true


func _on_slot_pressed() -> void:
	slot_clicked.emit(building, int(name), has_item)


func _on_slot_mouse_entered() -> void:
	if has_item:
		$HBoxContainer/Slot/RemovePrompt.show()

func _on_slot_mouse_exited() -> void:
	$HBoxContainer/Slot/RemovePrompt.hide()
