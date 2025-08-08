extends RigidBody2D

@onready var bars = $UI/Bars
var ACCEL_SPEED := 800 * Vector2.UP
var DECCEL_SPEED := 60.0
var ROT_SPEED := 3700.0
var ROT_DECCEL := 1.5
var DASH_SPEED := 10 * Vector2.UP
var DASH_MULT := 2.0
var DASH_FUEL_MULT := 4.0
var FUEL_USAGE_MOVE := 1.0
var FUEL_USAGE_ROT := 0.2
var FUEL_USAGE_SLOW := 0.1
var has_fuel := true


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("space"):
		apply_central_impulse(DASH_SPEED.rotated(rotation))
		ACCEL_SPEED *= DASH_MULT
		FUEL_USAGE_MOVE *= DASH_FUEL_MULT
		angular_velocity *= 0.75
	elif Input.is_action_just_released("space"):
		ACCEL_SPEED /= DASH_MULT
		FUEL_USAGE_MOVE /= DASH_FUEL_MULT


func _physics_process(delta: float) -> void:
	if has_fuel:
		process_basic_movement(delta)



func process_basic_movement(delta) -> void:
	if Input.is_action_pressed("up") or Input.is_action_pressed("space"):
		apply_central_force(ACCEL_SPEED.rotated(rotation) * delta)
		bars.use_fuel(FUEL_USAGE_MOVE)
	elif Input.is_action_pressed("down"):
		linear_velocity = linear_velocity.move_toward(Vector2.ZERO, DECCEL_SPEED * delta)
		bars.use_fuel(FUEL_USAGE_SLOW)
	
	if (Input.is_action_pressed("right") and Input.is_action_pressed("left")) or Input.is_action_pressed("slow_rot"):
		angular_velocity = move_toward(angular_velocity, 0, ROT_DECCEL * delta)
		bars.use_fuel(FUEL_USAGE_ROT*2)
	elif Input.is_action_pressed("right"):
		apply_torque(ROT_SPEED * delta)
		bars.use_fuel(FUEL_USAGE_ROT)
	elif Input.is_action_pressed("left"):
		apply_torque(-ROT_SPEED * delta)
		bars.use_fuel(FUEL_USAGE_ROT)
