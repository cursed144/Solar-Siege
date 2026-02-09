extends Control

@export var cam: Camera2D

func _process(_delta: float) -> void:
	$TextEdit.text = "X: " + str(snappedf(cam.global_position.x, 0.01)) + " | Y: " + str(snappedf(cam.global_position.y, 0.01))
