extends Control

const BUILD_PLACEMENT_REQ := preload("res://Planet-Section/Scenes/UI/building_placement_requirement.tscn")

var current_building: BuildingData = null
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


func _process(_delta: float) -> void:
	if hover.visible and is_instance_valid(current_building):
		update_hover_menu_data()


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
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", Vector2(0, 481), 0.8)


func select_building(data: BuildingData) -> void:
	%BuildingPreview.start_placing(data)


func show_hover_menu(data: BuildingData) -> void:
	set_hover_info(data)
	
	if $HoverMenu/AnimationPlayer.is_playing():
		await $HoverMenu/AnimationPlayer.animation_finished
	$HoverMenu/AnimationPlayer.play("fade_in_hover")

func set_hover_info(data: BuildingData) -> void:
	current_building = data
	
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

func update_hover_menu_data() -> void:
	hover.get_node("BName").text = current_building.display_name
	hover.get_node("Desc").text = current_building.description
	
	var reqs := current_building.requirements
	var index := 0
	for column in hover.get_node("Requirements").get_children():
		for req in column.get_children():
			req.set_item(reqs[index].item, reqs[index].amount)
			index += 1
	
	var planet = get_tree().current_scene
	var current = planet.get_building_current_amount(current_building.display_name)
	var limit = planet.get_building_max_amount(current_building.display_name)
	hover.get_node("MaxAllowed").text = "You have %d / %d" % [current, limit]

func hide_hover_menu() -> void:
	current_building = null
	$HoverMenu/AnimationPlayer.play("fade_out_hover")


func _on_tab_pressed(target_name: String) -> void:
	if target_name == "Exit":
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "position", Vector2(0, 648), 0.8)
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
