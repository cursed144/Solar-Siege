class_name ItemStack
extends Resource

@export var item: Item
@export_range(1, 99) var amount: int = 1


static func new_stack(_item: Item, _amount: int = 1) -> ItemStack:
	var item_stack = ItemStack.new()
	item_stack.item = _item
	item_stack.amount = _amount
	
	return item_stack
