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
	else:
		$Frame.disabled = true
		$Frame.self_modulate = Color.from_rgba8(0, 115, 0, 255)
		$Frame.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_frame_pressed() -> void:
	slot_clicked.emit(recipe)
