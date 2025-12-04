class_name Inventory
extends Resource

@export var slots: Array[ItemStack] = []
var claims: Array[Dictionary] = []


static func new_inv(slot_amount: int = 1) -> Inventory:
	var inv = Inventory.new()
	inv.add_slots(slot_amount)
	
	return inv


# returns if item was successfully added
func add_item(new_item: ItemStack) -> bool:
	var mapped_slots: Dictionary[int, int] = {}
	new_item = new_item.duplicate()
	
	if !can_fit(new_item):
		print("Insufficient room!")
		return false
	
	for i in range(slots.size()):
		if not is_instance_valid(slots[i]):
			slots[i] = new_item.duplicate()
			slots[i].amount = min(slots[i].amount, slots[i].item.max_per_stack)
			new_item.amount -= new_item.item.max_per_stack
		elif (slots[i].item.id == new_item.item.id) and (slots[i].amount != slots[i].item.max_per_stack):
			var amount_to_place = min(slots[i].item.max_per_stack - slots[i].amount, new_item.amount)
			mapped_slots[i] = amount_to_place
			new_item.amount -= amount_to_place
		
		if new_item.amount <= 0: break
	
	
	for slot in mapped_slots.keys():
		slots[slot].amount += mapped_slots[slot]
	
	return true


# returns list of which items were successfully added
func add_item_list(list: Array[ItemStack]):
	var output: Array[bool] = []
	
	for item in list:
		output.append(add_item(item))
	
	return output


# _remove_item is only meant to be called by create_claim to ensure items exist
func _remove_item(item: ItemStack) -> void:
	var remaining := item.amount
	var size = slots.size()
	
	for i in range(size):
		var slot = slots[size - i - 1]
		
		if not is_instance_valid(slot):
			continue
		if slot.item.id == item.item.id:
			var to_take = min(slot.amount, remaining)
			slot.amount -= to_take
			remaining -= to_take
			if slot.amount <= 0:
				slots[i] = null
		
		if remaining <= 0:
			break


# returns created claim
func create_claim(name: String, claim: Array[ItemStack]) -> Array[ItemStack]:
	var claimed_items: Array[ItemStack] = []
	
	for item in claim:
		item = item.duplicate()
		item.amount = min(is_present(item), item.amount)
		
		_remove_item(item)
		claimed_items.append(item)
	
	var new_claim := {}
	new_claim[name] = claimed_items
	claims.append(new_claim)
	return claimed_items


func get_claimed_items(name: String) -> Array[ItemStack]:
	for i in range(claims.size()):
		if claims[i].has(name):
			return (claims.pop_at(i))[name]
	
	return []


func can_fit(new_item: ItemStack) -> bool:
	new_item = new_item.duplicate()
	var inv = get_combined_inv()
	
	for item in inv.slots:
		if not is_instance_valid(item):
			new_item.amount -= new_item.item.max_per_stack
		elif (item.item.id == new_item.item.id) and (item.amount != item.item.max_per_stack):
			var amount_to_place = max(item.item.max_per_stack - item.amount, new_item.amount)
			new_item.amount -= amount_to_place
		
		if new_item.amount <= 0:
			return true
	
	return false


# returns how much of the item is present
func is_present(item_check: ItemStack) -> int:
	var amount = 0
	
	for item in slots:
		if not is_instance_valid(item):
			continue
		if item.item.id == item_check.item.id:
			amount += item.amount
	
	return amount


func get_combined_inv() -> Inventory:
	if claims.is_empty():
		return self
	
	var inv_new = self.duplicate()
	
	for claim in claims:
		for key in claim.keys()[0]:
			inv_new.add_item_list(inv_new.get_claimed_items(key))
	
	return inv_new


func add_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.append(null)

func remove_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.pop_back()
