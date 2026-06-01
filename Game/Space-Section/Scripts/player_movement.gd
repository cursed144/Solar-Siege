class_name PlayerController
extends Node

@export_group("Linear")
@export_range(0.0, 9999.0) var lin_force: float = 10.5
@export_range(0.0, 9999.0) var max_fwd_speed: float = 350.0
@export_range(0.0, 999.0)  var lin_decay: float = 10.0
@export_range(0.0, 999.0)  var brake_boost: float = 15.0
@export_range(0.0, 999.0)  var thrust_softness: float = 80.0

@export_group("Rotation")
@export_range(0.0, 999.0) var rot_torque: float = 13.5
@export_range(0.0, 99.0)  var max_rot_speed: float = 3.0
@export_range(0.0, 99.0)  var rot_decay: float = 0.09
@export_range(0.0, 999.0) var rot_stability_boost: float = 20.0
@export_range(0.0, 99.0)  var rot_softness: float = 1.0

@export_group("References")
@export var thruster_particles: CPUParticles2D = null

@onready var _body: DamagableEntity = get_parent()


func _ready() -> void:
	assert(_body != null, "PlayerController must be a direct child of a Player node.")


func _input(event: InputEvent) -> void:
	if thruster_particles == null:
		return
	if event.is_action_pressed("up"):
		thruster_particles.emitting = true
	elif event.is_action_released("up"):
		thruster_particles.emitting = false


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_rotation(delta)


func _handle_movement(delta: float) -> void:
	var forward := Vector2.UP.rotated(_body.rotation)
	
	if Input.is_action_pressed("down"):
		_body.linear_velocity = _body.linear_velocity.move_toward(
				Vector2.ZERO, lin_decay * brake_boost * delta)
		return
	
	if Input.is_action_pressed("up"):
		var fwd_speed := _body.linear_velocity.dot(forward)
		var remaining := max_fwd_speed - fwd_speed
		var thrust_scale := clampf(remaining / thrust_softness, 0.0, 1.0)
		if thrust_scale > 0.0:
			_body.apply_central_force(forward * lin_force * thrust_scale)
	else:
		_body.linear_velocity = _body.linear_velocity.move_toward(
				Vector2.ZERO, lin_decay * delta)


func _handle_rotation(delta: float) -> void:
	var ang_vel := _body.angular_velocity
	
	if Input.is_action_pressed("right") and Input.is_action_pressed("left"):
		_body.angular_velocity = move_toward(ang_vel, 0.0, rot_decay * rot_stability_boost * delta)
	
	elif Input.is_action_pressed("right"):
		var scale := clampf((max_rot_speed - ang_vel) / rot_softness, 0.0, 1.0)
		if scale > 0.0:
			_body.apply_torque(rot_torque * scale)
	
	elif Input.is_action_pressed("left"):
		var scale := clampf((max_rot_speed + ang_vel) / rot_softness, 0.0, 1.0)
		if scale > 0.0:
			_body.apply_torque(-rot_torque * scale)
	
	else:
		_body.angular_velocity = move_toward(ang_vel, 0.0, rot_decay * delta)
