class_name Inventory
extends Resource

@export var slots: Array[ItemStack] = []
var claims: Dictionary[String, Array] = {}


static func new_inv(slot_amount: int = 1) -> Inventory:
	var inv = Inventory.new()
	inv.add_slots(slot_amount)
	return inv


# -----------------------
# Claims
# -----------------------

## Create a claim for requested resources and return how much of each was claimed
func create_claim(claim_name: String, items: Array[ItemStack]) -> Array[ItemStack]:
	var claim: Array[Dictionary] = []
	var result: Array[ItemStack] = []
	
	for item_stack in items:
		var mapped_value := _add_claim_to_item(item_stack, simulate_claimed_slots())
		var total: int = 0
		
		for amount in mapped_value.values():
			total += amount
		
		if total > 0:
			var new_item_stack = ItemStack.new_stack(item_stack.item, total)
			result.append(new_item_stack)
		
		claim.append(mapped_value)
	
	claims[claim_name] = claim
	
	return result


## Internal: compute from which slots and how much can be taken for a requested item stack
func _add_claim_to_item(item_stack: ItemStack, inv_slots: Array[ItemStack] = slots) -> Dictionary[int, int]:
	var mapped_claim: Dictionary[int, int] = {}
	var amount_requested = item_stack.amount
	
	for i in range(inv_slots.size()):
		var curr_index = inv_slots.size() - i - 1
		var slot = inv_slots[curr_index]
		
		if not is_instance_valid(slot):
			continue
		if (slot.item.id == item_stack.item.id):
			var amount_to_take = min(slot.amount, amount_requested)
			mapped_claim[curr_index] = amount_to_take
			amount_requested -= amount_to_take
		
		if amount_requested <= 0: break
	
	return mapped_claim


## Return all items in the named claim and remove that claim (physically subtracts from slots)
func get_claimed_items(claim_name: String) -> Array[ItemStack]:
	var result: Array[ItemStack] = []
	var claim: Array[Dictionary] = claims[claim_name]
	
	for dict in claim:
		for key in dict.keys():
			var new_item = ItemStack.new_stack(slots[key].item, dict[key])
			
			slots[key].remove_amount(dict[key])
			if slots[key].amount <= 0:
				slots[key] = null
			
			result.append(new_item)
	
	remove_claim(claim_name)
	return result


## Remove a stored claim without returning its contents
func remove_claim(claim_name: String) -> void:
	claims.erase(claim_name)


# -----------------------
# Simulation
# -----------------------

## Produce a copy of slots with claimed amounts subtracted (used to plan new claims)
func simulate_claimed_slots(for_claim_name: String = "*") -> Array[ItemStack]:
	if claims.is_empty():
		return slots
	
	var new_slots: Array[ItemStack] = []
	for item in slots:
		new_slots.append(item.duplicate() if is_instance_valid(item) else null)
	
	if for_claim_name == "*":
		for claim: Array in claims.values():
			for dict: Dictionary in claim:
				for key: int in dict.keys():
					new_slots[key].remove_amount(dict[key])
					if new_slots[key].amount <= 0:
						new_slots[key] = null
	elif claims.has(for_claim_name):
		var claim: Array = claims[for_claim_name]
		for dict: Dictionary in claim:
			for key: int in dict.keys():
				new_slots[key].remove_amount(dict[key])
				if new_slots[key].amount <= 0:
					new_slots[key] = null
	
	return new_slots


# -----------------------
# Utility
# -----------------------

## Return how many of each requested ItemStack would fit (calls helper per item)
func how_many_items_fit(items: Array[ItemStack]) -> Array[int]:
	var result: Array[int] = []
	for i in range(items.size()):
		result.append(how_much_of_item_fits(items[i]))
	
	return result


## Return how much of a single ItemStack would fit into the inventory
func how_much_of_item_fits(item_stack: ItemStack) -> int:
	var amount = 0
	
	for slot in slots:
		if is_instance_valid(slot):
			amount = item_stack.amount
			break
		if slot.item.id == item_stack.item.id:
			amount += slot.item.max_per_stack - slot.amount
		
		if amount >= item_stack.amount: break
	
	return amount


## Meant to be used to strip slots of inventories of their null values and return them without
func strip_slots(target_slots: Array[ItemStack]) -> Array[ItemStack]:
	var result: Array[ItemStack] = []
	
	for slot in target_slots:
		if is_instance_valid(slot):
			result.append(slot.duplicate())
	
	return result


# -----------------------
# Adding
# -----------------------

## Add multiple ItemStack entries to inventory; returns how much was added for each
func add_items_to_inv(items: Array[ItemStack]) -> Array[int]:
	var result: Array[int] = []
	
	for item in items:
		result.append(add_item_to_inv(item))
	
	return result


## Add a single ItemStack to inventory and return how much of it was placed
func add_item_to_inv(item_stack: ItemStack) -> int:
	var fitting := how_much_of_item_fits(item_stack)
	var left_to_add := fitting
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		if not is_instance_valid(slot):
			slot = ItemStack.new_stack(item_stack.item, fitting)
			left_to_add = 0
		elif (slot.item.id == item_stack.item.id) and (slot.amount < slot.item.max_per_stack):
			left_to_add = slot.add_to_amount(left_to_add)
		
		if left_to_add <= 0: break
	
	return fitting


# -----------------------
# Slot management
# -----------------------

## Append empty slots to the inventory
func add_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.append(null)

## Remove slots from the end of the inventory
func remove_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.pop_back()
