class_name ItemStack
extends Resource

@export var item: Item
@export_range(1, 99) var amount: int = 1


static func new_stack(_item: Item = null, _amount: int = 0) -> ItemStack:
	assert(is_instance_valid(_item))
	assert(_amount <= _item.max_per_stack)
	assert(_amount > 0)
	
	var item_stack = ItemStack.new()
	item_stack.item = _item
	item_stack.amount = _amount
	
	return item_stack


static func from_id(id: ItemLoader.ItemID, _amount: int) -> ItemStack:
	assert(ItemLoader.ItemID.has(id))
	
	var new_item: Item = ItemLoader.based_on_id(id)
	var item_stack: ItemStack = new_stack(new_item, _amount)
	
	return item_stack


static func stacks_to_amounts(stacks: Array[ItemStack]) -> Array[ItemAmount]:
	var out: Array[ItemAmount] = []
	
	for stack in stacks:
		var is_found := false
		for curr_amount in out:
			if curr_amount.item.id == stack.item.id:
				curr_amount.amount += stack.amount
				is_found = true
				break
		if not is_found:
			var new_amount = ItemAmount.new_amount(stack.item, stack.amount)
			out.append(new_amount)
	
	return out


## Returns the ItemStack expressed as an ItemAmount
func to_amount() -> ItemAmount:
	var item_amount := ItemAmount.new_amount(item, amount)
	return item_amount


## Change the item to another
func set_item(_item: Item, _amount: int = 1) -> void:
	assert(is_instance_valid(_item))
	assert(_amount <= _item.max_per_stack)
	assert(_amount > 0)
	
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


static func sort_by_id_asc(a: ItemStack, b: ItemStack):
		if a.item.id < b.item.id:
			return true
		return false

static func sort_by_id_desc(a: ItemStack, b: ItemStack):
		if a.item.id > b.item.id:
			return true
		return false

static func sort_by_amount_asc(a: ItemStack, b: ItemStack):
		if a.amount < b.amount:
			return true
		return false

static func sort_by_amount_desc(a: ItemStack, b: ItemStack):
		if a.amount > b.amount:
			return true
		return false
