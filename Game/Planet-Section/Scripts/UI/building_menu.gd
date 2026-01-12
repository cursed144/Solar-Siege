extends Control

const BUILD_PLACEMENT_REQ := preload("res://Planet-Section/Scenes/UI/building_placement_requirement.tscn")

var is_mouse_in_area := false
var is_open := false

@onready var hover = $HoverMenu/VBoxContainer


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
	hover.get_node("BName").text = data.display_name
	hover.get_node("Desc").text = data.description
	
	for child in hover.get_node("Requirements").get_children():
		child.queue_free()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 40)
	hover.get_node("Requirements").add_child(column)
	
	var reqs := data.requirements
	for req in reqs:
		var placement = hover.get_node("Requirements").get_child(-1)
		var new_req = BUILD_PLACEMENT_REQ.instantiate()
		placement.add_child(new_req)
		new_req.set_item(req.item, req.amount)
		if placement.get_child_count() >= 2:
			column = VBoxContainer.new()
			column.add_theme_constant_override("separation", 40)
			hover.get_node("Requirements").add_child(column)
	
	var planet = get_tree().current_scene
	var current = planet.get_building_current_amount(data.display_name)
	var limit = planet.get_building_max_amount(data.display_name)
	hover.get_node("MaxAllowed").text = "You have %d / %d" % [current, limit]
	
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
