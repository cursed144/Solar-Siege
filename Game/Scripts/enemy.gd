extends RigidBody2D

@export var coll_damage_zone := 150.0
@export var armor := 0.0
var prev_velocity


func _physics_process(delta: float) -> void:
	prev_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0 or !$CollIFrames.is_stopped():
		return
	
	var body = state.get_contact_collider_object(0)
	if body.is_in_group("Friendly"):
		var rel_vel: Vector2 = prev_velocity - body.prev_velocity
		var impact: float = rel_vel.length()
		if impact > coll_damage_zone:
			var damage = impact/coll_damage_zone * 20 * randf_range(0.8, 1.2)
			print(damage)
			apply_damage(damage)
		$CollIFrames.start()


func apply_damage(amount: float) -> void:
	$Health.value -= amount
	if $Health.value <= 0:
		pass
