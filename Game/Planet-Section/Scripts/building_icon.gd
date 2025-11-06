extends TextureButton

@export var data: BuildingData
signal open_confirmation_menu(building: BuildingData)


func _ready() -> void:
	if data:
		texture_normal = data.icon
		$Name.text = data.display_name


func _on_pressed() -> void:
	open_confirmation_menu.emit(data)
