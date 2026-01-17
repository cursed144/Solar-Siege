extends Control

var ui_item_slot: UiInvSlot = null
var item_stack: ItemStack
var item_index: int
var amount_to_del: int = 0


func delete_item_prompt(ui_slot: UiInvSlot) -> void:
	get_tree().paused = true
	ui_item_slot = ui_slot
	item_index = ui_slot.item_index
	item_stack = ui_slot.inv_slots[item_index]
	
	$Amount.max_value = item_stack.amount
	$Amount.value = item_stack.amount
	amount_to_del = item_stack.amount
	
	var tex = ui_slot.get_node("Item").texture
	$TextureRect.texture = tex
	
	if ui_slot.is_reserved:
		$Amount.hide()
		$Blocking.show()
		$AmountLabel.hide()
		$Delete.disabled = true
		$Delete.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		$Amount.show()
		$Blocking.hide()
		$AmountLabel.show()
		$Delete.disabled = false
		$Delete.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	show()


func _on_amount_value_changed(value: float) -> void:
	amount_to_del = value as int
	$AmountLabel.text = "Amount to delete: " + str(value as int) + "/" + str(item_stack.amount)


func _on_delete_pressed() -> void:
	if is_instance_valid(ui_item_slot):
		item_stack.remove_amount(amount_to_del)
		if item_stack.amount <= 0:
			ui_item_slot.inv_slots[item_index] = null
		
		ui_item_slot.update()
	
	get_tree().paused = false
	hide()


func _on_cancel_pressed() -> void:
	get_tree().paused = false
	ui_item_slot = null
	hide()
