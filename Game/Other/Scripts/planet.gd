extends Area2D

signal mouse_entered_planet(planet: Area2D)
signal planet_clicked(planet: Area2D)

var mouse_in := false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and mouse_in:
		planet_clicked.emit(self)
		$Label.hide()


func _on_mouse_entered() -> void:
	if not get_parent().zoomed:
		$Label.show()
	else:
		$Label.hide()
	
	mouse_in = true
	mouse_entered_planet.emit(self)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	$Label.hide()
	mouse_in = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
