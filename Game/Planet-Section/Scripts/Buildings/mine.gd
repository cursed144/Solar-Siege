extends ProductionBuilding

var prod_items: Dictionary[Recipe, int]


func _ready() -> void:
	super._ready()
	var planet = get_tree().current_scene
	prod_items = planet.mine
	
	var temp := []
	for recipe in prod_items:
		temp.append(recipe)
	
	while temp.size() > 0:
		recipes.push_front(temp.pop_back())


func recipe_finished(recipe: Recipe) -> void:
	super.recipe_finished(recipe)
	var extra_chance: int = prod_items.get(recipe, -1)
	var extra: Array[ItemAmount] = []
	
	if not is_instance_valid(recipe):
		return
	
	for item in recipe.outputs:
		extra.append(item.duplicate(true))
	
	for item_amount in extra:
		item_amount.amount = 0
	
	if extra_chance != -1:
		while true:
			var rand = randf_range(0, 100)
			if extra_chance >= rand:
				for item_amount in extra:
					item_amount.amount += 1
				extra_chance /= 2
			else:
				break
		
		var output = inventories[inv_output_name]
		output.add_items_to_inv(ItemAmount.amounts_to_stacks(extra))
