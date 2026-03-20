extends Node2D


func _on_play_pressed() -> void:
	SceneSwitcher.switch_to_planet_choice()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
