class_name ItemAmount
extends Resource

@export var item: Item
@export var amount: int


static func new_amount(_item: Item, _amount: int) -> ItemAmount:
	var item_amount = ItemAmount.new()
	item_amount.item = _item
	item_amount.amount = _amount
	
	return item_amount


func to_stack() -> Array[ItemStack]:
	var out: Array[ItemStack] = []
	if not is_instance_valid(item) or amount <= 0:
		return out
	
	var max_stack := item.max_per_stack
	var left := int(amount)
	var count := int(ceil(left / float(max_stack)))
	
	for i in range(count):
		var take = min(left, max_stack)
		var stack := ItemStack.new_stack(item, take)
		out.append(stack)
		left -= take
	
	return out


static func amounts_to_stacks(amounts: Array[ItemAmount]) -> Array[ItemStack]:
	var out: Array[ItemStack] = []
	
	for curr_amount in amounts:
		if curr_amount == null:
			continue
		out.append_array(curr_amount.to_stack())
	
	return out


static func sort_by_amount_desc(a: ItemAmount, b: ItemAmount):
		if a.amount > b.amount:
			return true
		return false

static func sort_by_amount_asce(a: ItemAmount, b: ItemAmount):
		if a.amount < b.amount:
			return true
		return false
