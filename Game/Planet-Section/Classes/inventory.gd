class_name Inventory
extends Resource

var slots: Array[Item]


static func new_inv(slots: int = 1) -> Inventory:
	var inv = Inventory.new()
	inv.add_slots(slots)
	
	return inv


func add_item(new_item: Item) -> void:
	var mapped_slots: Dictionary[int, int]
	
	if !can_fit(new_item):
		print("Insufficient room!")
		return
	
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = new_item
			new_item.amount = 0
			break
		elif slots[i] == Item:
			if slots[i].amount == slots[i].max_per_stack:
				continue
			
			var amount_to_place = max(slots[i].max_per_stack - slots[i].amount, new_item.amount)
			mapped_slots[i] = amount_to_place
			new_item.amount -= amount_to_place
		
		if new_item.amount <= 0: break
	
	
	for slot in mapped_slots.keys():
		slots[slot].amount += mapped_slots[slot]


func can_fit(new_item: Item) -> bool:
	for i in range(slots.size()):
		if slots[i] == null:
			return true
		elif slots[i] == Item:
			if slots[i].amount == slots[i].max_per_stack:
				continue
			
			var amount_to_place = max(slots[i].max_per_stack - slots[i].amount, new_item.amount)
			new_item.amount -= amount_to_place
		
		if new_item.amount <= 0:
			return true
	
	return false


func add_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.append(null)

func remove_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.pop_back()
