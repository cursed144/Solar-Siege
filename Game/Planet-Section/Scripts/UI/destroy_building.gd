extends Control


func _on_destroy_pressed() -> void:
	show()
	$Building.texture = %UI/BuildingInfo.curr_building.get_node("Sprite2D").texture
	get_tree().paused = true


func _on_confirm_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_cancel_pressed() -> void:
	hide()
	get_tree().paused = false
