extends RigidBody2D

var ROT_SPEED: float = 3250
var ACCEL_SPEED := 500 * Vector2.UP
var DECCEL_SPEED: float = 60
var ROT_DECCEL: float = 1.5


func _physics_process(delta: float) -> void:
	process_basic_movement(delta)
	print(angular_velocity)



func process_basic_movement(delta) -> void:
	if Input.is_action_pressed("forward"):
		apply_central_force(ACCEL_SPEED.rotated(rotation) * delta)
	elif Input.is_action_pressed("slow_down"):
		linear_velocity = linear_velocity.move_toward(Vector2.ZERO, DECCEL_SPEED * delta)
	
	if Input.is_action_pressed("rot_right") and Input.is_action_pressed("rot_left"):
		angular_velocity = move_toward(angular_velocity, 0, ROT_DECCEL * delta)
	elif Input.is_action_pressed("rot_right"):
		apply_torque(ROT_SPEED * delta)
	elif Input.is_action_pressed("rot_left"):
		apply_torque(-ROT_SPEED * delta)
