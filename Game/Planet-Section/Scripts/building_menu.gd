extends Control

var is_mouse_in_area := false


func _ready() -> void:
	for section in $Buildings.get_children():
		for building in section.get_children():
			building.open_confirmation_menu.connect(open_confirmation_menu)
	
	for tab: TextureButton in $Tabs.get_children():
		tab.tab_pressed.connect(_on_tab_pressed)


func _input(event: InputEvent) -> void:
	if (event.is_action_released("scroll_down") or event.is_action_released("scroll_up")) and is_mouse_in_area:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if event.is_action_released("scroll_up"):
			tween.tween_property($Buildings, "scroll_horizontal", $Buildings.scroll_horizontal - 350, 0.4)
		elif event.is_action_released("scroll_down"):
			tween.tween_property($Buildings, "scroll_horizontal", $Buildings.scroll_horizontal + 350, 0.4)


func open_confirmation_menu(data: BuildingData) -> void:
	$ConfirmMenu/Icon.texture = data.icon
	$ConfirmMenu/Title.text = data.display_name
	$ConfirmMenu/Desc.text = data.description
	$ConfirmMenu.show()


func _on_scrolling_area_mouse_entered() -> void:
	is_mouse_in_area = true

func _on_scrolling_area_mouse_exited() -> void:
	is_mouse_in_area = false


func _on_tab_pressed(target_name: String) -> void:
	$Buildings.scroll_horizontal = 0
	
	for buildings in $Buildings.get_children():
		if buildings.name == target_name:
			buildings.show()
		else:
			buildings.hide()
