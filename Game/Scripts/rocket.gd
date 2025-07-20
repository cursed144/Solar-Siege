extends RigidBody2D

var ACCEL_SPEED := 500 * Vector2.UP
var DECCEL_SPEED: float = 60
var ROT_SPEED: float = 3500
var ROT_DECCEL: float = 1.5
var DASH_SPEED := 10 * Vector2.UP
var DASH_MULT: float = 2


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("space"):
		apply_central_impulse(DASH_SPEED.rotated(rotation))
		ACCEL_SPEED *= DASH_MULT
		angular_velocity *= 0.75
	elif Input.is_action_just_released("space"):
		ACCEL_SPEED /= DASH_MULT


func _physics_process(delta: float) -> void:
	process_basic_movement(delta)
	print(ACCEL_SPEED)



func process_basic_movement(delta) -> void:
	if Input.is_action_pressed("up") or Input.is_action_pressed("space"):
		apply_central_force(ACCEL_SPEED.rotated(rotation) * delta)
	elif Input.is_action_pressed("down"):
		linear_velocity = linear_velocity.move_toward(Vector2.ZERO, DECCEL_SPEED * delta)
	
	if (Input.is_action_pressed("right") and Input.is_action_pressed("left")) or Input.is_action_pressed("slow_rot"):
		angular_velocity = move_toward(angular_velocity, 0, ROT_DECCEL * delta)
	elif Input.is_action_pressed("right"):
		apply_torque(ROT_SPEED * delta)
	elif Input.is_action_pressed("left"):
		apply_torque(-ROT_SPEED * delta)
