extends Control

func set_slot(slot: ItemStack, is_reserved: bool) -> void:
	if is_instance_valid(slot):
		$Item.texture = slot.item.icon
		$Label.text = str(slot.amount) + "/" + str(slot.item.max_per_stack)
		$Frame.self_modulate = Color(0, 168, 0) if not is_reserved else Color(168, 0, 0)
		$Frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		$Frame.disabled = false
	else:
		$Item.texture = null
		$Label.text = ""
		$Frame.self_modulate = Color(1, 1, 1)
		$Frame.mouse_default_cursor_shape = Control.CURSOR_ARROW
		$Frame.disabled = true
