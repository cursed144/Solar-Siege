class_name Inventory
extends Resource

@export var slots: Array[ItemStack] = []
var claims: Array[Dictionary] = []
var promises: Array[Dictionary] = []


static func new_inv(slot_amount: int = 1) -> Inventory:
	var inv = Inventory.new()
	inv.add_slots(slot_amount)
	return inv


# ---------- public add / helpers ----------

# returns true if whole stack was added, false otherwise
# accepts optional excluded_promise_name so the promise-owner can use their reservation
func add_item(new_item: ItemStack, excluded_promise_name: String = "") -> bool:
	var leftover = _attempt_add(new_item, excluded_promise_name)
	if leftover > 0:
		print("Insufficient room!")
		return false
	return true


# returns list of booleans for each attempted stack add
func add_item_list(list: Array[ItemStack], excluded_promise_name: String = ""):
	var output: Array[bool] = []
	for item in list:
		output.append(add_item(item, excluded_promise_name))
	
	return output


# internal: try to add stack. Returns leftover amount
# Mirrors your original add_item flow but returns leftover.
func _attempt_add(new_item: ItemStack, excluded_promise_name: String = "") -> int:
	var mapped_slots: Dictionary[int, int] = {}
	new_item = new_item.duplicate()
	
	# check using can_fit that considers promises (excluding optional name)
	if !can_fit(new_item, excluded_promise_name):
		return new_item.amount
	
	for i in range(slots.size()):
		if not is_instance_valid(slots[i]):
			slots[i] = new_item.duplicate()
			slots[i].amount = min(slots[i].amount, slots[i].item.max_per_stack)
			new_item.amount -= new_item.item.max_per_stack
		elif (slots[i].item.id == new_item.item.id) and (slots[i].amount != slots[i].item.max_per_stack):
			var amount_to_place = min(slots[i].item.max_per_stack - slots[i].amount, new_item.amount)
			mapped_slots[i] = amount_to_place
			new_item.amount -= amount_to_place
		
		if new_item.amount <= 0:
			break
	
	for slot in mapped_slots.keys():
		slots[slot].amount += mapped_slots[slot]
	
	return max(new_item.amount, 0)


# ---------- claims ----------

# _remove_item is only meant to be called by create_claim/get_claimed_items to ensure items exist
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
		item.amount = min(get_quantity(item.item.id), item.amount)
		
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


# ---------- promises (capped on creation, deleted on fulfillment) ----------

# Add or replace a promise under `name`. promise_list is Array[ItemStack].
# This caps the promise to what can actually be reserved now and returns the reserved stacks.
# If nothing can be reserved, returns [] and does not create a promise.
func add_promise(name: String, promise_list: Array[ItemStack]) -> Array[ItemStack]:
	# Make a working copy of current slots and treat existing promises as already-reserved
	var temp_slots := []
	for s in slots:
		temp_slots.append(s.duplicate(true) if is_instance_valid(s) else null)
	
	# Simulate existing promises onto temp_slots so they consume empty slots
	for p in promises:
		for key in p.keys():
			var arr: Array = p[key]
			for s in arr:
				if s:
					_simulate_place_stack(temp_slots, s.item, s.amount)
	
	# Now attempt to reserve what the caller asked for on top of those simulated reservations
	var reserved_list: Array = []
	for req in promise_list:
		if not req:
			continue
		var reserved_amount := _simulate_place_stack(temp_slots, req.item, req.amount)
		if reserved_amount > 0:
			reserved_list.append(ItemStack.new_stack(req.item, reserved_amount))

	# If nothing could be reserved, return empty list
	if reserved_list.size() == 0:
		return []

	# Remove existing promise by name if any and store the new reserved one
	for i in range(promises.size() - 1, -1, -1):
		if promises[i].has(name):
			promises.remove_at(i)
			break

	var new_promise := {}
	var store_arr := []
	for s in reserved_list:
		store_arr.append(s.duplicate(true))
	new_promise[name] = store_arr
	promises.append(new_promise)

	return reserved_list


# Remove and return a promise by name (returns Array[ItemStack] or [] if none)
func get_promised_items(name: String) -> Array[ItemStack]:
	for i in range(promises.size()):
		if promises[i].has(name):
			return (promises.pop_at(i))[name]
	return []


# Cancel a promise without returning it
func remove_promise(name: String) -> void:
	for i in range(promises.size() - 1, -1, -1):
		if promises[i].has(name):
			promises.remove_at(i)
			return


# Worker arrives to fulfill a promise. delivered_list is Array[ItemStack] (what they actually carry).
# The function will deposit as much as possible of each delivered stack (respecting other promises & claims).
# It returns an Array[ItemStack] representing how many were actually deposited for each delivered stack.
# The stored promise is removed (deleted) after this function runs.
func fulfill_promise(name: String, delivered_list: Array[ItemStack]) -> Array[ItemStack]:
	var results: Array[ItemStack] = []
	# find the promise index if any (we be deleted at the end)
	var promise_idx = -1
	for i in range(promises.size()):
		if promises[i].has(name):
			promise_idx = i
			break
	
	# Attempt to add each delivered stack while EXCLUDING the caller's own promise
	for delivered in delivered_list:
		if not delivered:
			results.append(null)
			continue
		var to_add = delivered.duplicate()
		var leftover = _attempt_add(to_add, name) # returns leftover
		var stored_amount = delivered.amount - leftover
		var stored_stack = ItemStack.new_stack(delivered.item, stored_amount)
		results.append(stored_stack)
	
	# delete the promise entry (if existed) now that they attempted to fulfill it
	if promise_idx >= 0 and promise_idx < promises.size():
		# promises may have changed order; search and remove by name to be safe
		var pname = name
		for j in range(promises.size() - 1, -1, -1):
			if promises[j].has(pname):
				promises.remove_at(j)
				break
	
	return results


# ---------- capacity & query helpers ----------

# can_fit respects promises. If excluded_promise_name is provided it will not count that promise as reserved (so promise-maker can use their reservation).
func can_fit(new_item: ItemStack, excluded_promise_name: String = "") -> bool:
	new_item = new_item.duplicate()
	
	# compute "free units" for that specific item type across the inventory
	var free_units := 0
	for s in slots:
		if not is_instance_valid(s):
			free_units += new_item.item.max_per_stack
		elif s.item.id == new_item.item.id:
			free_units += (s.item.max_per_stack - s.amount)
	
	# subtract total promised amounts (all promises) except the excluded one
	var total_promised = _total_promised_amounts(excluded_promise_name)
	free_units = max(0, free_units - total_promised)
	return free_units >= new_item.amount


# sum of promised amounts across all promises (optionally excluding one name)
func _total_promised_amounts(excluded_name: String = "") -> int:
	var total := 0
	for p in promises:
		for key in p.keys():
			if key == excluded_name:
				continue
			var arr: Array = p[key]
			for s in arr:
				if s:
					total += s.amount
	return total


# returns how much of the item is present (only counts items actually in slots)
# expects an ItemStack for the check (preserves your API)
func get_quantity(item_id: int) -> int:
	var amount = 0
	
	for item in slots:
		if not is_instance_valid(item):
			continue
		if item.item.id == item_id:
			amount += item.amount
	
	return amount


# get_combined_inv: preserves original idea (claims removed from slots by create_claim)
func get_combined_inv() -> Inventory:
	if claims.is_empty():
		return self
	
	var inv_new = self.duplicate()
	
	for claim in claims:
		for key in claim.keys()[0]:
			inv_new.add_item_list(inv_new.get_claimed_items(key))
	
	return inv_new


# ---------- simulation helper used by add_promise ----------

# Helper: try to place `amount` of `item` into temp_slots (simulated).
# Mutates temp_slots to mark the reserved spaces. Returns how many units were placed.
# Mirrors add logic (first fill same-item partially filled stacks, then fill empties).
func _simulate_place_stack(temp_slots: Array, item: Item, amount: int) -> int:
	var left := amount
	
	# 1) fill existing slots with same item
	for i in range(temp_slots.size()):
		var s = temp_slots[i]
		if not is_instance_valid(s):
			continue
		if s.item.id == item.id and s.amount < s.item.max_per_stack:
			var space = s.item.max_per_stack - s.amount
			var put = min(space, left)
			s.amount += put
			left -= put
			if left <= 0:
				return amount # fully placed

	# 2) use empty slots (create new stacks in temp_slots)
	for i in range(temp_slots.size()):
		if left <= 0:
			break
		if not is_instance_valid(temp_slots[i]):
			var put = min(item.max_per_stack, left)
			var new_stack := ItemStack.new_stack(item, put)
			temp_slots[i] = new_stack
			left -= put

	return (amount - left) # how many we actually reserved


# ---------- slot management ----------

func add_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.append(null)

func remove_slots(amount: int = 1) -> void:
	for i in range(amount):
		slots.pop_back()
