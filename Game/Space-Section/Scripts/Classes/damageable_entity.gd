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
@export_range(1.0, 9999) var max_hp: float = 100.0

@export_group("Collision Damage")
## Minimum damage to actually take away HP
## Damage below this threshhold still applies knockback
@export_range(0.0, 9999) var coll_damage_threshhold: float = 50.0
@export_range(0.05, 10) var coll_inv_time: float = 0.05
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
