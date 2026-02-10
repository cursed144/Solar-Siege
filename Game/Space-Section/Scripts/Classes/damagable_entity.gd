class_name DamagableEntity
extends RigidBody2D

@export_range(0, 9999) var coll_damage_threshold: float = 0
@export_range(0.05, 9999) var coll_invincibility: float = 0.05
@export_range(1, 9999) var max_hp: float = 1
var coll_invincibility_timer: Timer
var prev_velocity: Vector2
var curr_hp: float


func _ready() -> void:
	var timer = Timer.new()
	timer.name = "CollInv"
	timer.wait_time = coll_invincibility
	timer.one_shot = true
	coll_invincibility_timer = timer
	add_child(timer)


func _physics_process(_delta: float) -> void:
	prev_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0:
		return
	
	var body: Node2D = state.get_contact_collider_object(0)
	var body_vel := Vector2.ZERO
	if body is RigidBody2D and coll_invincibility_timer.is_stopped():
		
		if body is DamagableEntity:
			body_vel = body.prev_velocity
		else:
			body_vel = body.linear_velocity
		
		var relative_vel := prev_velocity - body_vel
		var impact_points := relative_vel.length()
		
		if impact_points > coll_damage_threshold:
			var damage = impact_points / coll_damage_threshold * 20 * randf_range(0.95, 1.05)
			print(damage)
			apply_coll_damage(damage)


func apply_coll_damage(damage: float) -> void:
	coll_invincibility_timer.start()


func apply_damage(damage: float) -> void:
	pass
