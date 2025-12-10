extends Control

var is_open: bool = false
var curr_building = null


func building_clicked(building) -> void:
	if is_instance_valid(curr_building) and (curr_building == building) and is_open:
		close()
		return
	
	if not is_open:
		open()
	
	fill_info(building)
	curr_building = building


func fill_info(building = curr_building) -> void:
	#$RichTextLabel.text = building.name
	pass


func open() -> void:
	if %UI/BuildingMenu.is_open:
		%UI/BuildingMenu._on_tab_pressed("Exit")
	
	$AnimationPlayer.play("open")
	is_open = true

func close():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("close")
	is_open = false
