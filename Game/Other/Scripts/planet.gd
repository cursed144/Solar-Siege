extends Area2D

signal mouse_entered_planet(planet: Area2D)
signal planet_clicked(planet: Area2D)

var mouse_in := false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and mouse_in:
		planet_clicked.emit(self)


func _on_mouse_entered() -> void:
	mouse_in = true
	mouse_entered_planet.emit(self)


func _on_mouse_exited() -> void:
	mouse_in = false
