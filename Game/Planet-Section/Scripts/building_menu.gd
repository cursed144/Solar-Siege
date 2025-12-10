extends Control

var is_mouse_in_area := false
var is_open := false


func _ready() -> void:
	for section in $Buildings.get_children():
		for building in section.get_children():
			building.select_building.connect(select_building)
			building.show_hover_menu.connect(show_hover_menu)
			building.hide_hover_menu.connect(hide_hover_menu)
	
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


func _on_building_button_pressed() -> void:
	is_open = true
	$HoverMenu.show()
	$AnimationPlayer.play("show_build_ui")


func select_building(data: BuildingData) -> void:
	#TODO start placing building if sufficient resourses and not over max allowed
	%BuildingPreview.start_placing(data)

func show_hover_menu(data: BuildingData) -> void:
	$HoverMenu/BName.text = data.display_name
	$HoverMenu/Desc.text = data.description
	create_tween().tween_property($HoverMenu, "modulate", Color(1,1,1,1), 0.5)

func hide_hover_menu() -> void:
	create_tween().tween_property($HoverMenu, "modulate", Color(1,1,1,0), 0.2)


func _on_tab_pressed(target_name: String) -> void:
	if target_name == "Exit":
		$AnimationPlayer.play("hide_build_ui")
		$HoverMenu.hide()
		is_open = false
		return
	
	$Buildings.scroll_horizontal = 0
	for buildings in $Buildings.get_children():
		if buildings.name == target_name:
			buildings.show()
		else:
			buildings.hide()


func _on_scrolling_area_mouse_entered() -> void:
	is_mouse_in_area = true

func _on_scrolling_area_mouse_exited() -> void:
	is_mouse_in_area = false
