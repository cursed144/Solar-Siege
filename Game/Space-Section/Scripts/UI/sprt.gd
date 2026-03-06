extends HBoxContainer

@export var target: RigidBody2D
@export var constants: Node

func  _ready() -> void:
	$Speed.max_value = constants.MAX_LIN_SPEED.length() * 1.5
	$Rotation.max_value = constants.MAX_ROT_SPEED * 29


func _process(delta: float) -> void:
	var vel :=  target.linear_velocity.length()
	var rot :=  absf(target.angular_velocity * 15)
	
	$Speed.value = lerpf($Speed.value, vel, 3*delta)
	$Rotation.value = lerpf($Rotation.value, rot, 3*delta)
	$Speed/Number.text = str(int(vel))
	$Rotation/Number.text = str(snappedf(rot, 0.1))
	
	handle_coloring($Speed)
	handle_coloring($Rotation)


func handle_coloring(for_node: TextureProgressBar) -> void:
	if for_node.value < for_node.max_value / 6:
		for_node.modulate = Color(0.165, 0.44, 1.0, 1.0)
	elif for_node.value < for_node.max_value / 2:
		for_node.modulate = Color(0.20, 0.65, 0.0, 1.0)
	elif for_node.value < (for_node.max_value / 4) * 3:
		for_node.modulate = Color(1.0, 0.818, 0.0, 1.0)
	else:
		for_node.modulate = Color(1.0, 0.0, 0.0, 1.0)
