class_name HitContext
extends RefCounted

enum DamageType {
	NORMAL,
	COLLISION,
	EXPLOSION,
	STATUS,
}

var damage: float = 0.0
var type: DamageType = DamageType.NORMAL
var hit_dir: Vector2 = Vector2.ZERO
var attacker_speed: float = 0.0
var attacker: Node2D = null
var is_overkill: bool = false
