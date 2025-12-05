class_name ItemStack
extends Resource

@export var item: Item
@export_range(1, 99) var amount: int = 1


static func new_stack(_item: Item, _amount: int = 1) -> ItemStack:
	var item_stack = ItemStack.new()
	item_stack.item = _item
	item_stack.amount = _amount
	if _amount > _item.max_per_stack:
		print("Amount over max!")
		return null
	
	return item_stack


## Returns how much of it wasn't added
func add_to_amount(value: int = 1) -> int:
	var old_amount = amount
	amount = min(amount + value, item.max_per_stack)
	
	return (old_amount - amount)


## Returns how much wasn't removed
func remove_amount(value: int = 1) -> int:
	var old_amount = amount
	amount = max(amount - value, 0)
	
	return -(old_amount - amount - value)
