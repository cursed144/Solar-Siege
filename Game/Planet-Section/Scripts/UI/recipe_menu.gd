extends Control

const recipe_slot := preload("res://Planet-Section/Scenes/UI/recipe_slot.tscn")


func on_worker_slot_clicked(building: Building, slot_num: int) -> void:
	show()
	$RecipeSlots.show()
	
	for recipe in $RecipeSlots/Recipes.get_children():
		recipe.queue_free()
	
	for recipe in building.recipes:
		var new_slot = recipe_slot.instantiate()
		new_slot.init(recipe)
		new_slot.slot_clicked.connect(on_recipe_slot_clicked)
		$RecipeSlots/Recipes.add_child(new_slot)


func on_recipe_slot_clicked(recipe: Recipe) -> void:
	$RecipeSlots.hide()
	$RecipeConfirm.show()
