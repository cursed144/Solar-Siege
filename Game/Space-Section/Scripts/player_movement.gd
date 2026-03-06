extends Node

var ROT_SPEED = 850
var MAX_ROT_SPEED = 3.0
var ROT_DECAY = 0.09
var ROT_STABILITY_BOOST = 16

var LIN_SPEED := 600 * Vector2.UP
var MAX_LIN_SPEED := Vector2(300, 300)
var LIN_DECAY = 10
var LIN_BRAKE_BOOST = 15

@onready var player: PhysicsBody2D = get_parent()


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)


func handle_movement(delta: float) -> void:
	if Input.is_action_pressed("up"):
		player.apply_central_force(LIN_SPEED.rotated(player.rotation) * delta)
	elif Input.is_action_pressed("down"):
		player.linear_velocity = player.linear_velocity.move_toward(Vector2.ZERO, LIN_DECAY * LIN_BRAKE_BOOST * delta)
		print("Braking")
	else:
		player.linear_velocity = player.linear_velocity.move_toward(Vector2.ZERO, LIN_DECAY * delta)
	
	player.linear_velocity.x = clampf(player.linear_velocity.x, -MAX_LIN_SPEED.x, MAX_LIN_SPEED.x)
	player.linear_velocity.y = clampf(player.linear_velocity.y, -MAX_LIN_SPEED.y, MAX_LIN_SPEED.y)
	#print("LIN VEL: " + str(linear_velocity))


func handle_rotation(delta: float) -> void:
	if Input.is_action_pressed("right") and Input.is_action_pressed("left"):
		player.angular_velocity = move_toward(player.angular_velocity, 0, ROT_DECAY * ROT_STABILITY_BOOST * delta)
		print("Stabilizing")
	elif Input.is_action_pressed("right"):
		player.apply_torque(ROT_SPEED * delta)
	elif Input.is_action_pressed("left"):
		player.apply_torque(-ROT_SPEED * delta)
	else:
		player.angular_velocity = move_toward(player.angular_velocity, 0, ROT_DECAY * delta)
	
	player.angular_velocity = clampf(player.angular_velocity, -MAX_ROT_SPEED, MAX_ROT_SPEED)
	#print("ROT VEL: " + str(angular_velocity))
