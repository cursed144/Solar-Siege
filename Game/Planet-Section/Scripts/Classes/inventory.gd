class_name Inventory
extends Resource

signal inv_changed(inv: Inventory)

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
	
	if items.is_empty():
		return []
	
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
	
	inv_changed.emit(self)
	return result


## Internal: compute from which slots and how much can be taken for a requested item stack
func _add_claim_to_item(item_stack: ItemStack, inv_slots: Array[ItemStack] = slots) -> Dictionary[int, int]:
	var mapped_claim: Dictionary[int, int] = {}
	var amount_requested = item_stack.amount
	
	for i in range(inv_slots.size()):
		# Iterate backwards
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
	var claim = claims.get(claim_name, null)
	
	if claim == null:
		return []
	
	for dict in claim:
		for key in dict.keys():
			var new_item = ItemStack.new_stack(slots[key].item, dict[key])
			
			slots[key].remove_amount(dict[key])
			if slots[key].amount <= 0:
				slots[key] = null
			
			result.append(new_item)
	
	remove_claim(claim_name)
	inv_changed.emit(self)
	return result


## Remove a stored claim without returning its contents
func remove_claim(claim_name: String) -> void:
	claims.erase(claim_name)


# -----------------------
# Simulation
# -----------------------

## Produce a copy of slots with claimed amounts subtracted (used to plan new claims)
func simulate_claimed_slots(for_claim_name: String = "*") -> Array[ItemStack]:
	var new_slots: Array[ItemStack] = []
	for item in slots:
		new_slots.append(item.duplicate() if is_instance_valid(item) else null)
	
	if claims.is_empty():
		return new_slots
	
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

func get_total_item_amount(item: Item) -> int:
	var item_stacks := simulate_claimed_slots()
	var total: int = 0
	
	for item_stack in item_stacks:
		if not is_instance_valid(item_stack):
			continue
		if item_stack.item == item:
			total += item_stack.amount
	
	return total


## Return how many of each requested ItemAmount would fit (calls helper per item)
func how_many_items_fit(items: Array[ItemAmount]) -> Array[int]:
	var result: Array[int] = []
	for i in range(items.size()):
		result.append(how_much_of_item_fits(items[i]))
	
	return result


## Return how much of a single ItemAmount would fit into the inventory
func how_much_of_item_fits(item_amount: ItemAmount) -> int:
	var capacity := 0
	var max_per_stack := item_amount.item.max_per_stack
	
	for slot in slots:
		if not is_instance_valid(slot):
			# empty slot can hold a whole new stack
			capacity += max_per_stack
		elif slot.item.id == item_amount.item.id:
			capacity += (slot.item.max_per_stack - slot.amount)
		
		if capacity >= item_amount.amount:
			return item_amount.amount
	
	return min(capacity, item_amount.amount)



## Meant to be used to strip slots of inventories of their null values and return them without
func strip_slots() -> Array[ItemStack]:
	var result: Array[ItemStack] = []
	
	for slot in slots:
		if is_instance_valid(slot):
			result.append(slot.duplicate())
	
	return result


func is_slot_claimed(index: int) -> bool:
	for claim in claims.values():
		for item_claim in claim:
			for idx in item_claim.keys():
				if idx == index:
					return true
	return false


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
	var left_to_add := item_stack.amount
	var added_total := 0
	
	for i in range(slots.size()):
		if left_to_add <= 0:
			break
		
		var slot = slots[i]
		if not is_instance_valid(slot):
			var place = min(item_stack.item.max_per_stack, left_to_add)
			slots[i] = ItemStack.new_stack(item_stack.item, place)
			left_to_add -= place
			added_total += place
		elif slot.item.id == item_stack.item.id and slot.amount < slot.item.max_per_stack:
			var space = slot.item.max_per_stack - slot.amount
			var place = min(space, left_to_add)
			var leftover = slots[i].add_to_amount(place)
			var actually_added = place - leftover
			left_to_add -= actually_added
			added_total += actually_added
	
	inv_changed.emit(self)
	return added_total



# -----------------------
# Slot management
# -----------------------

## Append empty slots to the inventory
func add_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.append(null)
	
	inv_changed.emit(self)

## Remove slots from the end of the inventory
func remove_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.pop_back()
	
	inv_changed.emit(self)
