extends Control

@onready var cam = get_node("../../PlayerCam")

func _process(_delta: float) -> void:
	$TextEdit.text = "X: " + str(snappedf(cam.position.x, 0.01)) + " | Y: " + str(snappedf(cam.position.y, 0.01))
