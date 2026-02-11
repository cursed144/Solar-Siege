extends DamagableEntity

var ROT_SPEED = 850
var MAX_ROT_SPEED = 3.0
var ROT_DECAY = 0.09
var ROT_STABILITY_BOOST = 16

var LIN_SPEED := 600 * Vector2.UP
var MAX_LIN_SPEED := Vector2(300, 300)
var LIN_DECAY = 10
var LIN_BRAKE_BOOST = 15


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)


func handle_movement(delta: float) -> void:
	if Input.is_action_pressed("up"):
		apply_central_force(LIN_SPEED.rotated(rotation) * delta)
	elif Input.is_action_pressed("down"):
		linear_velocity = linear_velocity.move_toward(Vector2.ZERO, LIN_DECAY * LIN_BRAKE_BOOST * delta)
		print("Braking")
	else:
		linear_velocity = linear_velocity.move_toward(Vector2.ZERO, LIN_DECAY * delta)
	
	linear_velocity.x = clampf(linear_velocity.x, -MAX_LIN_SPEED.x, MAX_LIN_SPEED.x)
	linear_velocity.y = clampf(linear_velocity.y, -MAX_LIN_SPEED.y, MAX_LIN_SPEED.y)
	#print("LIN VEL: " + str(linear_velocity))


func handle_rotation(delta: float) -> void:
	if Input.is_action_pressed("right") and Input.is_action_pressed("left"):
		angular_velocity = move_toward(angular_velocity, 0, ROT_DECAY * ROT_STABILITY_BOOST * delta)
		print("Stabilizing")
	elif Input.is_action_pressed("right"):
		apply_torque(ROT_SPEED * delta)
	elif Input.is_action_pressed("left"):
		apply_torque(-ROT_SPEED * delta)
	else:
		angular_velocity = move_toward(angular_velocity, 0, ROT_DECAY * delta)
	
	angular_velocity = clampf(angular_velocity, -MAX_ROT_SPEED, MAX_ROT_SPEED)
	#print("ROT VEL: " + str(angular_velocity))
