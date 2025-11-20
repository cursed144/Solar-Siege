extends TextureButton

@export var data: BuildingData
signal select_building(building: BuildingData)
signal show_hover_menu(building: BuildingData)
signal hide_hover_menu


func _ready() -> void:
	if data:
		texture_normal = data.icon
		$Name.text = data.display_name


func _on_pressed() -> void:
	select_building.emit(data)


func _on_mouse_entered() -> void:
	$HoverTimer.start()

func _on_mouse_exited() -> void:
	$HoverTimer.stop()
	hide_hover_menu.emit()

func _on_hover_timer_timeout() -> void:
	show_hover_menu.emit(data)
