extends TextureButton

@export_range(0, 999) var building_id: int


func _on_pressed() -> void:
	get_tree().current_scene.get_node("Preview").set_building_preview(building_id, $TextureRect.get_texture())
