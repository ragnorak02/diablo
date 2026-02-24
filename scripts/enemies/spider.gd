class_name Spider
extends EnemyBase
## Spider enemy — fast, low health, attacks in swarms. Appears mid-floors.

func _ready() -> void:
	enemy_name = "Cave Spider"
	enemy_type = "spider"
	max_health = 25.0
	move_speed = 5.5
	attack_damage = 6.0
	attack_range = 1.5
	attack_cooldown = 0.6
	detection_range = 14.0
	xp_reward = 12
	_base_color = Color(0.2, 0.15, 0.1)  # Dark brown

	super._ready()

	# Override mesh to be flatter
	if _mesh and _mesh.mesh is CapsuleMesh:
		var capsule: CapsuleMesh = _mesh.mesh
		capsule.radius = 0.3
		capsule.height = 0.6
		_mesh.position.y = 0.3
		_mesh.scale = Vector3(1.3, 0.5, 1.3)

	# Update collision shape
	for child in get_children():
		if child is CollisionShape3D and child.shape is CapsuleShape3D:
			var shape: CapsuleShape3D = child.shape
			shape.radius = 0.3
			shape.height = 0.6
			child.position.y = 0.3
			break
