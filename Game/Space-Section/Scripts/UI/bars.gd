extends Control

var is_shown := true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ctrl"):
		if is_shown: $AnimationPlayer.play("hide")
		else: $AnimationPlayer.play("show")
		is_shown = not is_shown
