extends DamagableEntity

## Speed the player is pushed back to after a regular kill ram.
@export_range(0.0, 999.0) var ram_kill_pushback_speed: float = 150.0
## Velocity multiplier applied on overkill smash-through.
@export_range(1.0, 10.0)  var ram_overkill_velocity_boost: float = 3.0
## How long the player is immune to collision damage after an overkill (prevents
## the victim's explosion from immediately hurting the player).
@export_range(0.0, 5.0)   var overkill_immunity_time: float = 0.3

var _pending_ram: bool = false
var _pending_ram_dir: Vector2 = Vector2.ZERO
var _pending_ram_overkill: bool = false


# -----------------------
# DamagableEntity overrides
# -----------------------

## Called by the victim inside apply_damage when the player rams them to death.
## Runs in the victim's _integrate_forces; schedules a velocity rewrite for next
## physics step via _pre_integrate so the physics solver doesn't overwrite it.
func on_ram_kill(context: HitContext) -> void:
	# Bounce direction is AWAY from the victim (opposite of the victim's fling direction).
	_pending_ram_dir = (-context.hit_dir).normalized()
	if _pending_ram_dir == Vector2.ZERO:
		_pending_ram_dir = Vector2.LEFT
	
	_pending_ram_overkill = context.is_overkill
	_pending_ram = true
	
	if context.is_overkill:
		# Start a longer invincibility window so the victim's explosion doesn't
		# immediately punish the player for smashing through.
		_coll_invincibility_timer.wait_time = overkill_immunity_time
		_coll_invincibility_timer.start()


## During an overkill smash-through the player has already received their immunity
## window above, so damage reduction stays at default.
func get_damage_reduction(context: HitContext) -> float:
	return super.get_damage_reduction(context)


## Applied BEFORE the contact scan each physics step, so the rewrite wins.
func _pre_integrate(state: PhysicsDirectBodyState2D) -> void:
	if not _pending_ram:
		return
	_pending_ram = false
	
	if _pending_ram_overkill:
		# Smash through: keep momentum and boost it.
		# prev_linear_velocity was cached before this call in the base class.
		state.linear_velocity = prev_linear_velocity * ram_overkill_velocity_boost
		state.angular_velocity = prev_angular_velocity * ram_overkill_velocity_boost
	else:
		# Regular kill: cancel all velocity and push back.
		state.linear_velocity  = _pending_ram_dir * ram_kill_pushback_speed
		state.angular_velocity = 0.0
