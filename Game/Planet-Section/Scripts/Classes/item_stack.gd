class_name ItemStack
extends Resource

@export var item: Item
@export_range(1, 99) var amount: int = 1


static func new_stack(_item: Item = null, _amount: int = 0) -> ItemStack:
	if (_amount <= 0 or _amount > _item.max_per_stack) or not is_instance_valid(_item):
		push_error("Invalid amount!")
		return null
	
	var item_stack = ItemStack.new()
	item_stack.item = _item
	item_stack.amount = _amount
	
	return item_stack


## Change the item to another
func set_item(_item: Item, _amount: int = 1) -> void:
	if _amount <= 0 or _amount > _item.max_per_stack:
		push_error("Invalid amount!")
		return
	
	item = _item
	amount = _amount


## Returns how much of it wasn't added
func add_to_amount(value: int = 1) -> int:
	var old_amount = amount
	var space_left = item.max_per_stack - old_amount
	var to_add = min(space_left, value)
	amount = old_amount + to_add
	
	return value - to_add


## Returns how much wasn't removed
func remove_amount(value: int = 1) -> int:
	var removed = min(amount, value)
	amount -= removed
	
	return value - removed
