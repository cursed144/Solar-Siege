class_name DamagableEntity
extends RigidBody2D

signal damage_taken(damage: float)

@export_range(1, 9999) var coll_damage_threshold: float = 1.0
@export_range(0.05, 999) var coll_invincibility: float = 0.05
@export_range(0.0, 999.0) var coll_damage_multiplier: float = 20.0
@export_range(1.0, 100.0) var overkill_ratio: float = 1.5
@export var hp_bar: Range = null

# --- pending ram response (applied in THIS body's integrate) ---
var _pending_ram: bool = false
var _pending_ram_dir: Vector2 = Vector2.ZERO
var _pending_ram_overkill: bool = false
var prev_linear_velocity: Vector2 = Vector2.ZERO

var coll_invincibility_timer: Timer

# Player-only
const ram_kill_pushback_speed: float = 150.0
const ram_overkill_velocity_boost: float = 1.75


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 3
	assert((hp_bar is ProgressBar) or (hp_bar is TextureProgressBar))
	
	var timer := Timer.new()
	timer.name = "CollInv"
	timer.wait_time = coll_invincibility
	timer.one_shot = true
	coll_invincibility_timer = timer
	add_child(timer)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# cache pre-step velocities
	prev_linear_velocity = state.linear_velocity
	
	if _pending_ram:
		_pending_ram = false
		
		if _pending_ram_overkill:
			# "piledrive through"
			state.linear_velocity = prev_linear_velocity * ram_overkill_velocity_boost
		else:
			# fixed pushback regardless of incoming speed
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0.0
			state.linear_velocity = _pending_ram_dir * ram_kill_pushback_speed
	
	# normal collision damage logic
	if not coll_invincibility_timer.is_stopped():
		return
	
	var contact_count := state.get_contact_count()
	if contact_count <= 0:
		return
	
	var best_closing_speed := 0.0
	var best_normal := Vector2.ZERO
	var best_other: Node2D = null
	
	for i in contact_count:
		var other_obj: Node2D = state.get_contact_collider_object(i)
		if other_obj == null or not other_obj.is_in_group("damaging_entity"):
			continue
		
		var v_self := state.get_contact_local_velocity_at_position(i)
		var v_other := state.get_contact_collider_velocity_at_position(i)
		var n := state.get_contact_local_normal(i)
		
		var rel := v_self - v_other
		
		var closing_speed := rel.dot(-n)
		if closing_speed < 0.0:
			closing_speed = rel.dot(n)
		closing_speed = max(0.0, closing_speed)
		
		if closing_speed > best_closing_speed:
			best_closing_speed = closing_speed
			best_normal = n
			best_other = other_obj
	
	if best_closing_speed <= coll_damage_threshold:
		return
	
	var damage_scale := (best_closing_speed / coll_damage_threshold) * coll_damage_multiplier
	var damage := damage_scale * randf_range(0.95, 1.05)
	
	var hp_before := float(hp_bar.value)
	if damage < hp_before:
		apply_coll_damage(damage)
		return
	
	# fatal
	var is_overkill := damage >= hp_before * overkill_ratio
	
	# Tell the rammer (usually player) to apply ram response in its own integrate step
	if best_other != null and best_other.has_method("_queue_ram_response"):
		best_other.call("_queue_ram_response", best_normal, is_overkill)
	
	apply_coll_damage(damage)


func _queue_ram_response(push_normal_from_victim: Vector2, is_overkill: bool) -> void:
	# Only the player should respond
	if name != "Player":
		return

	# We want to push the player BACK away from the victim.
	_pending_ram_dir = -push_normal_from_victim.normalized()
	_pending_ram_overkill = is_overkill
	_pending_ram = true


func apply_coll_damage(damage: float) -> void:
	apply_damage(damage)
	coll_invincibility_timer.start()


func apply_damage(damage: float) -> void:
	hp_bar.value -= damage
	if hp_bar.value <= hp_bar.min_value:
		queue_free()
	damage_taken.emit(damage)
