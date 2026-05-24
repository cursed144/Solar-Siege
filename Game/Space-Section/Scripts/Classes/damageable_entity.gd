class_name DamagableEntity
extends RigidBody2D

enum LifeState {
	ALIVE,
	COLLISION_DYING,
	DEAD
}

signal damage_taken(context: HitContext)
signal died(context: HitContext)

@export_group("HP")
@export var hp_bar: Range = null

@export_group("Collision Damage")
## Minimum damage to actually take away HP.
## Damage below this threshhold still applies knockback.
@export_range(0.0, 9999) var coll_damage_threshold: float = 50.0
@export_range(0.05, 10) var coll_invincibility_time: float = 0.05
@export_range(0.0, 10) var coll_damage_multiplier: float = 0.3
## Overkill when excess damage (past 0 HP) >= (overkill_ratio - 1) * max_hp.
## e.g. ratio=2 means you must deal an extra full health bar worth of damage over the kill.
@export_range(1.0, 10.0)   var overkill_ratio: float = 2.0

@export_group("Collision Death Fling")
@export_range(0.1, 10) var collision_death_delay: float = 2.0
@export_range(0.0, 10) var fling_speed_multiplier: float = 1.0
@export_range(0.0, 999) var fling_speed_min: float = 150.0
@export_range(0.0, 9999) var fling_speed_max: float = 2000.0
@export_range(0.0, 99) var collision_death_spin_speed: float = 25.0 ## rad/s

@export_group("Death Explosion")
@export_range(1.0, 999.0) var explosion_size: float = 20.0
@export_range(0.1, 10.0) var explosion_speed_scale: float = 1.2
@export var explosion_color: Color = Color.WHITE

var life_state: LifeState = LifeState.ALIVE

var prev_linear_velocity: Vector2 = Vector2.ZERO
var prev_angular_velocity: float = 0.0

var _coll_invincibility_timer: Timer
var _collision_death_timer: Timer

## True while awaiting hitstop after an overkill, before queue_free.
## Prevents any further processing during that window.
var _awaiting_death: bool = false
var _volatile_killer: Node2D = null


func _ready() -> void:
	assert(hp_bar != null, "%s: hp_bar export is not set." % name)
	
	contact_monitor = true
	max_contacts_reported = 3
	
	add_to_group("damageable")
	add_to_group("damaging")
	
	_coll_invincibility_timer = Timer.new()
	_coll_invincibility_timer.name = "CollInvincibility"
	_coll_invincibility_timer.wait_time = coll_invincibility_time
	_coll_invincibility_timer.one_shot = true
	add_child(_coll_invincibility_timer)
	
	_collision_death_timer = Timer.new()
	_collision_death_timer.name = "CollisionDeath"
	_collision_death_timer.wait_time = collision_death_delay
	_collision_death_timer.one_shot = true
	_collision_death_timer.timeout.connect(_on_collision_death_timeout)
	add_child(_collision_death_timer)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	prev_linear_velocity = state.linear_velocity
	prev_angular_velocity = state.angular_velocity
	
	_pre_integrate(state)
	
	# Volatile bodies explode via body_entered; nothing to do here.
	if life_state == LifeState.COLLISION_DYING:
		return
	
	if life_state != LifeState.ALIVE or _awaiting_death:
		return
	if not _coll_invincibility_timer.is_stopped():
		return
	
	var contact_count := state.get_contact_count()
	if contact_count == 0:
		return
	
	var best_speed  := 0.0
	var best_normal := Vector2.ZERO
	var best_attacker: Node = null
	
	for i: int in contact_count:
		var other: Node = state.get_contact_collider_object(i)
		if other == null or other == self:
			continue
		if not other.is_in_group("damaging"):
			continue
		
		var v_self  := state.get_contact_local_velocity_at_position(i)
		var v_other := state.get_contact_collider_velocity_at_position(i)
		var normal  := state.get_contact_local_normal(i)
		var rel     := v_self - v_other
		
		var closing_speed := maxf(rel.dot(normal), rel.dot(-normal))
		closing_speed = maxf(closing_speed, 0.0)
		
		if closing_speed > best_speed:
			best_speed    = closing_speed
			best_attacker = other
			best_normal   = normal
	
	if best_speed <= 0.0:
		return
	
	var raw_damage := best_speed * coll_damage_multiplier * randf_range(0.95, 1.05)
	
	if raw_damage < coll_damage_threshold:
		return
	
	var context := HitContext.new()
	context.type          = HitContext.DamageType.COLLISION
	context.damage        = raw_damage
	context.hit_dir       = best_normal
	context.attacker_speed = best_speed
	context.attacker      = best_attacker
	
	apply_damage(context)
	_coll_invincibility_timer.start()


func apply_damage(context: HitContext) -> void:
	if life_state == LifeState.DEAD or _awaiting_death:
		return
	
	if life_state == LifeState.COLLISION_DYING:
		# Anything hitting a volatile body detonates it immediately.
		explode()
		return
	
	if context.type == HitContext.DamageType.COLLISION:
		if not _coll_invincibility_timer.is_stopped():
			return
	
	var effective_damage := context.damage * get_damage_reduction(context)
	var hp_before := hp_bar.value
	hp_bar.value = maxf(0.0, hp_bar.value - effective_damage)
	damage_taken.emit(context)
	
	if hp_bar.value > 0.0:
		return  # Survived.
	
	# Fatal
	hp_bar.hide()
	
	match context.type:
		HitContext.DamageType.COLLISION:
			var excess   := maxf(0.0, effective_damage - hp_before)
			var required := maxf(0.0, (overkill_ratio - 1.0) * hp_bar.max_value)
			context.is_overkill = excess >= required
			
			if context.attacker != null and context.attacker.has_method(&"on_ram_kill"):
				context.attacker.on_ram_kill(context)
			
			if context.is_overkill:
				_begin_overkill_death()
			else:
				_enter_collision_death(context)
		_:
			explode()


## Immediately removes the body from physics so it can't push anything,
## then waits for hitstop before spawning the explosion.
func _begin_overkill_death() -> void:
	_awaiting_death = true
	# Ghost the body: freeze movement and remove all collision so it can't
	# nudge subsequent enemies during the hitstop pause.
	set_deferred("freeze", true)
	call_deferred("set_collision_layer", 0)
	call_deferred("set_collision_mask", 0)
	
	HitStop.queue_hitstop()
	await HitStop.one_hitstop_finished
	
	# Restore just enough for explode() to run cleanly, then free.
	freeze = false
	explode()


func _enter_collision_death(context: HitContext) -> void:
	set_collision_layer_value(2, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
	
	life_state = LifeState.COLLISION_DYING
	remove_from_group("damaging")
	
	# Remember who killed us so we don't detonate on their lingering contact.
	_volatile_killer = context.attacker
	body_entered.connect(_on_volatile_body_entered)
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	var dir := context.hit_dir.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	
	var fling_speed := clampf(
		context.attacker_speed * fling_speed_multiplier,
		fling_speed_min, fling_speed_max
	)
	linear_velocity  = dir * fling_speed
	angular_velocity = collision_death_spin_speed * (1.0 if dir.x >= 0.0 else -1.0)
	
	_collision_death_timer.start()


## Fires after all _integrate_forces calls for this physics step — never races.
func _on_volatile_body_entered(body: Node) -> void:
	if life_state != LifeState.COLLISION_DYING:
		return
	
	# The entity that flung us is still touching us — ignore them.
	if body == _volatile_killer:
		return
	
	if body.has_method("apply_damage"):
		var speed := linear_velocity.length()
		var ctx := HitContext.new()
		ctx.type           = HitContext.DamageType.COLLISION
		ctx.damage         = speed * coll_damage_multiplier * randf_range(0.95, 1.05)
		ctx.attacker_speed = speed
		ctx.attacker       = self
		ctx.hit_dir        = linear_velocity.normalized()
		body.apply_damage(ctx)
	
	explode()

func explode() -> void:
	if life_state == LifeState.DEAD:
		return
	life_state = LifeState.DEAD
	died.emit(null)
	Explosion.create_explosion(global_position, get_tree().current_scene)
	queue_free()

func _on_collision_death_timeout() -> void:
	explode()


# -----------------------
# Virtual methods
# -----------------------

## Called when THIS entity rams another entity to death.
## Player overrides this to schedule the bounce-back or smash-through.
func on_ram_kill(_ctx: HitContext) -> void:
	pass

## Return a multiplier on incoming damage. 1.0 = full damage, 0.0 = full immunity.
## Override per entity type (e.g. armoured enemies, player during overkill window).
func get_damage_reduction(_ctx: HitContext) -> float:
	return 1.0

## Called at the very start of _integrate_forces, after velocity cache, before contact scan.
## Override in Player to apply the pending ram velocity rewrite in the correct physics step.
func _pre_integrate(_state: PhysicsDirectBodyState2D) -> void:
	pass
