extends Control

const RECIPE_SLOT := preload("res://Planet-Section/Scenes/UI/recipe_slot.tscn")
const REQUIREMENT_ROW := preload("res://Planet-Section/Scenes/UI/requirement_row.tscn")

var pending_recipe: Recipe = null
var target_building: Building = null
var target_slot: int = 0

@onready var requirement_row_parent = $RecipeConfirm/Requirements/HBoxContainer


func on_worker_slot_clicked(building: Building, slot_num: int) -> void:
	show()
	$RecipeSlots.show()
	target_building = building
	target_slot = slot_num
	
	for recipe in building.recipes:
		var new_slot = RECIPE_SLOT.instantiate()
		new_slot.init(recipe)
		new_slot.slot_clicked.connect(on_recipe_slot_clicked)
		$RecipeSlots/Recipes.add_child(new_slot)


func on_recipe_slot_clicked(recipe: Recipe) -> void:
	$RecipeConfirm.show()
	pending_recipe = recipe
	$RecipeConfirm/RecipeImage.texture = recipe.display_icon
	$RecipeConfirm/RecipeName.text = recipe.recipe_name
	$RecipeConfirm/AmountLabel.text = "Amount to produce: 1/20"
	$RecipeConfirm/Amount.value = 1
	
	for req in requirement_row_parent.get_children():
		req.queue_free()
	for req: ItemAmount in recipe.requirements:
		var new_row = REQUIREMENT_ROW.instantiate()
		new_row.get_node("Image").texture = req.item.icon
		new_row.get_node("Amount").text = "x" + str(req.amount)
		requirement_row_parent.add_child(new_row)


func _on_amount_value_changed(value: float) -> void:
	$RecipeConfirm/AmountLabel.text = "Amount to produce: " + str(value as int) + "/20"


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
	hide()
	target_building = null
	pending_recipe = null
	target_slot = 0
