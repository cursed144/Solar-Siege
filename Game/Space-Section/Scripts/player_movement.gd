extends Node

var ROT_SPEED := 13.5
var MAX_ROT_SPEED := 3.0
var ROT_DECAY := 0.09
var ROT_STABILITY_BOOST := 20.0

# Thrust force direction base (ship points UP by default)
var LIN_SPEED := 10.5 # force magnitude
var MAX_FWD_SPEED := 350.0 # forward speed cap 
var LIN_DECAY := 10.0
var LIN_BRAKE_BOOST := 15.0

# how softly thrust fades near the cap (bigger = softer)
var THRUST_SOFTNESS := 80.0
var ROT_SOFTNESS := 1.0

@onready var target: RigidBody2D = get_parent()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		target.apply_torque_impulse(1000)

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)


func handle_movement(delta: float) -> void:
	var forward := Vector2.UP.rotated(target.rotation).normalized()
	
	if Input.is_action_pressed("down"):
		target.linear_velocity = target.linear_velocity.move_toward(Vector2.ZERO, LIN_DECAY * LIN_BRAKE_BOOST * delta)
		return
	
	if Input.is_action_pressed("up"):
		# forward component of velocity (only what matters for "top speed")
		var fwd_speed := target.linear_velocity.dot(forward)
		
		# Soft cap: scale thrust down as you approach the cap.
		# - Below cap: scale ~1
		# - Near cap: scale smoothly -> 0
		# - Above cap: scale = 0 (no extra thrust)
		var remaining := MAX_FWD_SPEED - fwd_speed
		var thrust_scale := clampf(remaining / THRUST_SOFTNESS, 0.0, 1.0)
		
		if thrust_scale > 0.0:
			target.apply_central_force(forward * LIN_SPEED * thrust_scale)
	else:
		target.linear_velocity = target.linear_velocity.move_toward(Vector2.ZERO, LIN_DECAY * delta)


func handle_rotation(delta: float) -> void:
	var ang_vel := target.angular_velocity
	
	if Input.is_action_pressed("right") and Input.is_action_pressed("left"):
		target.angular_velocity = move_toward(ang_vel, 0.0, ROT_DECAY * ROT_STABILITY_BOOST * delta)
	
	elif Input.is_action_pressed("right"):
		var remaining := MAX_ROT_SPEED - ang_vel
		var torque_scale := clampf(remaining / ROT_SOFTNESS, 0.0, 1.0)
		
		if torque_scale > 0.0:
			target.apply_torque(ROT_SPEED * torque_scale)
	
	elif Input.is_action_pressed("left"):
		var remaining := MAX_ROT_SPEED + ang_vel
		var torque_scale := clampf(remaining / ROT_SOFTNESS, 0.0, 1.0)
		
		if torque_scale > 0.0:
			target.apply_torque(-ROT_SPEED * torque_scale)
	
	else:
		target.angular_velocity = move_toward(ang_vel, 0.0, ROT_DECAY * delta)
