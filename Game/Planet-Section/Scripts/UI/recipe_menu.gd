extends Control

const recipe_slot := preload("res://Planet-Section/Scenes/UI/recipe_slot.tscn")
var pending_recipe: Recipe = null
var target_building: Building = null
var target_slot: int = 0


func on_worker_slot_clicked(building: Building, slot_num: int) -> void:
	show()
	$RecipeSlots.show()
	target_building = building
	target_slot = slot_num
	
	for recipe in building.recipes:
		var new_slot = recipe_slot.instantiate()
		new_slot.init(recipe)
		new_slot.slot_clicked.connect(on_recipe_slot_clicked)
		$RecipeSlots/Recipes.add_child(new_slot)


func on_recipe_slot_clicked(recipe: Recipe) -> void:
	$RecipeConfirm.show()
	pending_recipe = recipe


func cancel_recipe() -> void:
	show()
	$CancelRecipe.show()


func _on_recipe_slots_close_pressed() -> void:
	for recipe in $RecipeSlots/Recipes.get_children():
		recipe.slot_clicked.disconnect(on_recipe_slot_clicked)
		recipe.queue_free()
	
	$RecipeSlots.hide()
	hide()


func _on_begin_production() -> void:
	target_building.assign_recipe_to_row(pending_recipe, $RecipeConfirm/Amount.value, target_slot)
	reset_menus()


func reset_menus() -> void:
	$RecipeConfirm.hide()
	$RecipeSlots.hide()
	$StopRecipe.hide()
	target_building = null
	pending_recipe = null
	target_slot = 0
