class_name ItemAmount
extends Resource

@export var item: Item
@export var amount: int


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
