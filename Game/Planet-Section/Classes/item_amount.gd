class_name ItemAmount
extends Resource

@export var item: Item
@export var amount: int


func to_stack() -> Array[ItemStack]:
	var out: Array[ItemStack] = []
	if not is_instance_valid(item) or amount <= 0:
		return out
	
	var max_stack := int(item.max_per_stack_limit)
	var left := int(amount)
	var count := int(ceil(left / float(max_stack)))
	
	for i in range(count):
		var take = min(left, max_stack)
		var stack := ItemStack.new_stack(item, take)
		out.append(stack)
		left -= take
	
	return out
