extends Control


func _ready() -> void:
	for section in $Buildings.get_children():
		for building in section.get_children():
			building.open_confirmation_menu.connect(_open_confirmation_menu)


func _open_confirmation_menu(data: BuildingData) -> void:
	print("open")
