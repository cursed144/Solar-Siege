extends Control

var ui_item_slot: UiInvSlot = null
var item_stack: ItemStack
var item_index: int
var amount_to_del: int = 0


func delete_item_prompt(ui_slot: UiInvSlot) -> void:
	ui_item_slot = ui_slot
	item_index = ui_slot.item_index
	item_stack = ui_slot.inv_slots[item_index]
	
	$Amount.max_value = item_stack.amount
	$Amount.value = item_stack.amount
	amount_to_del = item_stack.amount
	
	if ui_slot.is_reserved:
		$Amount.hide()
		$Delete.disabled = true
	else:
		$Amount.show()
		$Delete.disabled = false
	
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
	
	hide()


func _on_cancel_pressed() -> void:
	ui_item_slot = null
	hide()
