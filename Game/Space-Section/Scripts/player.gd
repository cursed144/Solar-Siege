extends DamagableEntity

## Speed the player is pushed back to after a regular kill ram.
@export_range(0.0, 999.0) var ram_kill_pushback_speed: float = 150.0
## Velocity multiplier applied on overkill smash-through.
@export_range(1.0, 10.0)  var ram_overkill_velocity_boost: float = 3.5
## How long the player is immune to collision damage after an overkill (prevents
## the victim's explosion from immediately hurting the player).
@export_range(0.0, 5.0)   var overkill_immunity_time: float = 0.3

# Velocity to write in next _pre_integrate. Computed at kill time, not next frame.
var _pending_ram: bool = false
var _pending_ram_overkill: bool = false
var _pending_ram_target_velocity: Vector2 = Vector2.ZERO
var _pending_ram_target_angular: float = 0.0


# -----------------------
# DamagableEntity overrides
# -----------------------

## Called by the victim inside apply_damage when the player rams them to death.
## Runs in the victim's _integrate_forces; schedules a velocity rewrite for next
## physics step via _pre_integrate so the physics solver doesn't overwrite it.
func on_ram_kill(ctx: HitContext) -> void:
	_pending_ram = true
	_pending_ram_overkill = ctx.is_overkill
	
	if ctx.is_overkill:
		# Use prev_linear_velocity captured at the START of this physics frame
		# (before the solver ran the collision response), not next frame's stale value.
		_pending_ram_target_velocity = prev_linear_velocity * ram_overkill_velocity_boost
		_pending_ram_target_angular  = prev_angular_velocity * ram_overkill_velocity_boost
		
		_coll_invincibility_timer.wait_time = overkill_immunity_time
		_coll_invincibility_timer.start()
	else:
		var pushback_dir := (-ctx.hit_dir).normalized()
		if pushback_dir == Vector2.ZERO:
			pushback_dir = Vector2.LEFT
		_pending_ram_target_velocity = pushback_dir * ram_kill_pushback_speed
		_pending_ram_target_angular  = 0.0


## During an overkill smash-through the player has already received their immunity
## window above, so damage reduction stays at default.
func get_damage_reduction(context: HitContext) -> float:
	return super.get_damage_reduction(context)


## Applied BEFORE the contact scan each physics step, so the rewrite wins.
func _pre_integrate(state: PhysicsDirectBodyState2D) -> void:
	if not _pending_ram:
		return
	_pending_ram = false
	state.linear_velocity  = _pending_ram_target_velocity
	state.angular_velocity = _pending_ram_target_angular
