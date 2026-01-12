extends Control

signal slot_clicked(self_recipe: Recipe)

var recipe: Recipe = null


func init(_recipe: Recipe) -> void:
	if not is_instance_valid(_recipe):
		push_error("Invalid recipe!")
		return
	
	recipe = _recipe
	if recipe.is_unlocked:
		$Item.texture = recipe.display_icon
		$ItemText.text = recipe.recipe_name
	else:
		$Lock.show()
		$Item.hide()
		$ItemText.hide()
		$Button.hide()
		modulate = Color(0.5, 0.5, 0.5)


func _on_button_pressed() -> void:
	slot_clicked.emit(recipe)


# Animate when hovering over button

func _on_button_mouse_entered() -> void:
	if not $Button.disabled:
		var tween := create_tween()
		tween.tween_property($Design, "modulate", Color.from_rgba8(0, 168, 0, 255), 0.2)
		z_index = 2

func _on_button_mouse_exited() -> void:
	if not $Button.disabled:
		var tween := create_tween()
		tween.tween_property($Design, "modulate", Color(1, 1, 1, 1), 0.2)
		z_index = 1
		await tween.finished
		z_index = 0
