extends Control


func _ready() -> void:
	for section in $Buildings.get_children():
		for building in section.get_children():
			building.open_confirmation_menu.connect(open_confirmation_menu)


func open_confirmation_menu(data: BuildingData) -> void:
	$ConfirmMenu/Icon.texture = data.icon
	$ConfirmMenu/Title.text = data.display_name
	$ConfirmMenu/Desc.text = data.description
	$ConfirmMenu.show()


func on_confirm_menu_cancelled() -> void:
	$ConfirmMenu.hide()


func on_building_confirmed() -> void:
	pass
