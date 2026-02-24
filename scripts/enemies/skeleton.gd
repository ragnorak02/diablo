class_name Skeleton
extends EnemyBase
## Skeleton enemy — basic melee fighter. Common on early floors.

func _ready() -> void:
	enemy_name = "Skeleton"
	enemy_type = "skeleton"
	max_health = 40.0
	move_speed = 3.0
	attack_damage = 8.0
	attack_range = 2.0
	attack_cooldown = 1.2
	detection_range = 10.0
	xp_reward = 15
	_base_color = Color(0.8, 0.75, 0.6)  # Bone white-yellow
	super._ready()
