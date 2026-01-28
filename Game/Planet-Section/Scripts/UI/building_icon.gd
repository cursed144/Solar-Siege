extends TextureButton

signal select_building(building: BuildingData)
signal show_hover_menu(building: BuildingData)
signal hide_hover_menu

@export var data: BuildingData
@onready var planet := get_tree().current_scene


func _ready() -> void:
	if data:
		texture_normal = data.icon
		$Name.text = data.display_name
	
	update_validity()


func update_validity() -> void:
	if data == null or not is_instance_valid(data):
		disabled = true
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		return
	
	var valid := true
	for req in data.requirements:
		var have = planet.get_global_item_amount(req.item)
		if have < req.amount:
			valid = false
			break
	
	disabled = not valid
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND \
		if valid else  \
		Control.CURSOR_FORBIDDEN


func _on_pressed() -> void:
	select_building.emit(data)


func _on_mouse_entered() -> void:
	update_validity()
	$HoverTimer.start()

func _on_mouse_exited() -> void:
	$HoverTimer.stop()
	hide_hover_menu.emit()

func _on_hover_timer_timeout() -> void:
	show_hover_menu.emit(data)
