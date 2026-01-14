class_name UiInvSlot
extends Control

signal inv_slot_clicked(slot: UiInvSlot)

var inv_slots: Array[ItemStack]
var item_index: int
var is_reserved := false


func set_slot(_inv_slots: Array[ItemStack], index: int = 0, _is_reserved: bool = false) -> void:
	inv_slots = _inv_slots
	item_index = index
	is_reserved = _is_reserved
	
	var item_stack = inv_slots[item_index]
	
	if is_instance_valid(item_stack):
		$Item.texture = item_stack.item.icon
		$Label.text = str(item_stack.amount) + "/" + str(item_stack.item.max_per_stack)
		$Frame.self_modulate = Color.from_rgba8(0, 168, 0, 255) if not is_reserved else Color.from_rgba8(168, 0, 0, 255)
		$Frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		$Frame.disabled = false
	else:
		$Item.texture = null
		$Label.text = ""
		$Frame.self_modulate = Color(1, 1, 1)
		$Frame.mouse_default_cursor_shape = Control.CURSOR_ARROW
		$Frame.disabled = true


func update() -> void:
	set_slot(inv_slots, item_index, is_reserved)


func clear_slot() -> void:
	if is_reserved:
		push_error("Attempted to clear a reserved slot on node: " + name)
	
	set_slot([])


func _on_frame_pressed() -> void:
	if not inv_slots.is_empty():
		inv_slot_clicked.emit(self)
