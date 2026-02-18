class_name DamagableEntity
extends RigidBody2D

signal damage_taken(damage: float)

## How much force the enemy has to recieve before it starts taking damage
@export_range(1, 9999) var coll_damage_threshold: float = 1
## A time after recieving damage where contact damage can not be recieved again
@export_range(0.05, 9999) var coll_invincibility: float = 0.05
## A direct multiplier to how much collision damage is taken
@export_range(0.0, 9999.0) var coll_damage_multiplier: float = 20.0
@export var hp_bar: Range = null

var coll_invincibility_timer: Timer
var prev_velocity: Vector2


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 3
	assert((hp_bar is ProgressBar) or (hp_bar is TextureProgressBar))
	
	var timer = Timer.new()
	timer.name = "CollInv"
	timer.wait_time = coll_invincibility
	timer.one_shot = true
	coll_invincibility_timer = timer
	add_child(timer)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not coll_invincibility_timer.is_stopped():
		return
	
	var contact_count = state.get_contact_count()
	if contact_count <= 0:
		return
	
	var best_closing_speed := 0.0
	for i in contact_count:
		var other_obj: Node2D = state.get_contact_collider_object(i)
		if other_obj == null or not (other_obj.is_in_group("damaging_entity")):
			continue
		
		# Velocity of THIS body at the contact point (includes angular velocity effects)
		var v_self := state.get_contact_local_velocity_at_position(i)
		
		# Velocity of the OTHER body at the contact point (0 for StaticBody2D)
		var v_other := state.get_contact_collider_velocity_at_position(i)
		
		# Contact normal for THIS body (points outward from this body at the contact)
		var contact_normal := state.get_contact_local_normal(i)
		
		var rel := v_self - v_other
		
		# Closing speed is how fast we're moving INTO the surface.
		# One of these will be positive.
		var closing_speed := rel.dot(-contact_normal)
		if closing_speed < 0.0:
			closing_speed = rel.dot(contact_normal)
		closing_speed = max(0.0, closing_speed)
		
		best_closing_speed = max(best_closing_speed, closing_speed)
	
	# Only damage based on the strongest contact this frame
	if best_closing_speed <= coll_damage_threshold:
		return
	
	var damage_scale: float = (best_closing_speed / coll_damage_threshold) * coll_damage_multiplier
	var damage: float = damage_scale * randf_range(0.95, 1.05)
	
	apply_coll_damage(damage)


func apply_coll_damage(damage: float) -> void:
	apply_damage(damage)
	coll_invincibility_timer.start()


func apply_damage(damage: float) -> void:
	hp_bar.value -= damage
	print(damage)
	if hp_bar.value <= hp_bar.min_value:
		queue_free()
	
	damage_taken.emit(damage)
