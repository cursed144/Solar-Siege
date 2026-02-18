class_name DamagableEntity
extends RigidBody2D

enum DamageSource { GENERIC, COLLISION, EFFECT }
enum LifeState { ALIVE, DYING_BY_COLLISION, DEAD }

signal damage_taken(damage: float)

# Player-only
const ram_kill_pushback_speed: float = 150.0
const ram_overkill_velocity_boost: float = 2.5

@export_group("Collision Damage")
@export_range(1, 9999) var coll_damage_threshold: float = 1.0
@export_range(0.05, 999.0) var coll_invincibility: float = 0.05
@export_range(0.0, 999.0) var coll_damage_multiplier: float = 20.0
@export_range(1.0, 100.0) var overkill_ratio: float = 1.5

@export_group("Collision Death Fling")
@export_range(0.5, 10.0) var collision_death_explode_delay: float = 1.5
# final fling speed = clamp(attacker_into_speed * fling_speed_mult, fling_min, fling_max)
@export_range(0.0, 100.0) var fling_speed_mult: float = 1.0
@export_range(0.0, 999.0) var fling_min: float = 150.0
@export_range(0.0, 9999.0) var fling_max: float = 2000.0
@export_range(0.0, 99.0) var collision_death_spin_speed: float = 25.0 # rad/s

@export_group("")
@export var hp_bar: Range = null

var life_state: LifeState = LifeState.ALIVE

var coll_invincibility_timer: Timer
var collision_death_timer: Timer

# used for overkill "piledrive through"
var prev_linear_velocity: Vector2 = Vector2.ZERO
var prev_angular_velocity: float = 0.0

# pending ram response applied in THIS body's integrate (so solver doesn't stomp it)
var _pending_ram: bool = false
var _pending_ram_dir: Vector2 = Vector2.ZERO
var _pending_ram_overkill: bool = false


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 3
	assert((hp_bar is ProgressBar) or (hp_bar is TextureProgressBar))
	
	coll_invincibility_timer = Timer.new()
	coll_invincibility_timer.name = "CollInv"
	coll_invincibility_timer.wait_time = coll_invincibility
	coll_invincibility_timer.one_shot = true
	add_child(coll_invincibility_timer)
	
	collision_death_timer = Timer.new()
	collision_death_timer.name = "CollDeath"
	collision_death_timer.wait_time = collision_death_explode_delay
	collision_death_timer.one_shot = true
	collision_death_timer.timeout.connect(_on_collision_death_timeout)
	add_child(collision_death_timer)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# cache pre-step (used for overkill response)
	prev_linear_velocity = state.linear_velocity
	prev_angular_velocity = state.angular_velocity
	
	# Apply pending ram response first (player only)
	if _pending_ram:
		_pending_ram = false
		if _pending_ram_overkill:
			state.linear_velocity = prev_linear_velocity * ram_overkill_velocity_boost
			state.angular_velocity = prev_angular_velocity * ram_overkill_velocity_boost
		else:
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0.0
			state.linear_velocity = _pending_ram_dir * ram_kill_pushback_speed
	
	
	# don't take more collision damage / scan contacts if not alive
	if life_state != LifeState.ALIVE:
		return
	if not coll_invincibility_timer.is_stopped():
		return
	
	var contact_count := state.get_contact_count()
	if contact_count <= 0:
		return
	
	var best_closing_speed := 0.0
	var best_hit_dir := Vector2.ZERO              # victim fling direction (away from attacker)
	var best_attacker: Node2D = null
	
	for i in contact_count:
		var other_obj: Node2D = state.get_contact_collider_object(i)
		if other_obj == null or not other_obj.is_in_group("damaging_entity"):
			continue
		
		var v_self := state.get_contact_local_velocity_at_position(i)
		var v_other := state.get_contact_collider_velocity_at_position(i)
		var n := state.get_contact_local_normal(i) # outward from THIS body
		
		var rel := v_self - v_other
		
		var closing_speed := rel.dot(-n)
		if closing_speed < 0.0:
			closing_speed = rel.dot(n)
		closing_speed = max(0.0, closing_speed)
		
		if closing_speed > best_closing_speed:
			best_closing_speed = closing_speed
			best_attacker = other_obj
			
			# Fly away from attacker (outward from victim)
			best_hit_dir = n.normalized()
	
	if best_closing_speed <= coll_damage_threshold:
		return
	
	var damage_scale := (best_closing_speed / coll_damage_threshold) * coll_damage_multiplier
	var damage := damage_scale * randf_range(0.95, 1.05)
	
	apply_damage(damage, DamageSource.COLLISION, best_hit_dir, best_closing_speed, best_attacker)
	coll_invincibility_timer.start()


func apply_damage(
		damage: float,
		source: DamageSource = DamageSource.GENERIC,
		hit_dir: Vector2 = Vector2.ZERO,
		attacker_speed: float = 0.0,
		attacker: Node = null
	) -> void:
	
	# If already collision-dying, any further damage instantly explodes
	if (life_state == LifeState.DYING_BY_COLLISION) and (source != DamageSource.EFFECT):
		explode()
		return
	if life_state == LifeState.DEAD:
		return
	
	var hp_before := float(hp_bar.value)
	hp_bar.value -= damage
	damage_taken.emit(damage)
	
	if hp_bar.value > hp_bar.min_value:
		return
	
	# Fatal
	hp_bar.hide()
	
	if source == DamageSource.COLLISION:
		var is_overkill := damage >= hp_before * overkill_ratio
		
		# tell attacker (player) to respond; applied in its own integrate
		if attacker != null:
			# hit_dir is victim-away direction; player should bounce opposite => queue will negate
			attacker.call("_queue_ram_response", hit_dir, is_overkill)
		
		if is_overkill:
			explode()
			return
		
		_enter_collision_death(hit_dir, attacker_speed)
	else:
		explode()


func _queue_ram_response(victim_away_dir: Vector2, is_overkill: bool) -> void:
	# only player reacts
	if name != "Player":
		return
	
	# Bounce player away from victim (opposite of victim's away direction)
	_pending_ram_dir = (-victim_away_dir).normalized()
	if _pending_ram_dir == Vector2.ZERO:
		_pending_ram_dir = Vector2.LEFT
	
	_pending_ram_overkill = is_overkill
	_pending_ram = true


func _enter_collision_death(victim_away_dir: Vector2, impact_speed: float) -> void:
	life_state = LifeState.DYING_BY_COLLISION
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	var dir := victim_away_dir.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	
	var fling_speed := clampf(impact_speed * fling_speed_mult, fling_min, fling_max)
	linear_velocity = dir * fling_speed
	
	# spin fast; sign based on direction for consistency
	var spin_sign := 1.0 if dir.x >= 0.0 else -1.0
	angular_velocity = collision_death_spin_speed * spin_sign
	
	collision_death_timer.start()


func _on_collision_death_timeout() -> void:
	if life_state == LifeState.DYING_BY_COLLISION:
		explode()


func explode() -> void:
	if life_state == LifeState.DEAD:
		return
	life_state = LifeState.DEAD
	
	queue_free()
