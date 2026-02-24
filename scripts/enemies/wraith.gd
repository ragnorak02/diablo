class_name Wraith
extends EnemyBase
## Wraith enemy — ranged attacker, floats, transparent. Deep floor enemy.

var _ranged_attack_timer: float = 0.0
var _projectile_speed: float = 10.0


func _ready() -> void:
	enemy_name = "Wraith"
	enemy_type = "wraith"
	max_health = 35.0
	move_speed = 2.5
	attack_damage = 15.0
	attack_range = 8.0
	attack_cooldown = 2.0
	detection_range = 15.0
	xp_reward = 25
	_base_color = Color(0.3, 0.1, 0.5)  # Purple ghostly

	super._ready()

	# Make it float higher and transparent
	if _mesh:
		_mesh.position.y = 1.5
		if _mesh.material_override:
			var mat: StandardMaterial3D = _mesh.material_override
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.6
			mat.emission_energy_multiplier = 0.8


func _perform_attack() -> void:
	if not is_instance_valid(target):
		return
	_shoot_projectile()


func _shoot_projectile() -> void:
	var projectile := Area3D.new()
	projectile.collision_layer = 8  # projectiles
	projectile.collision_mask = 2  # player
	projectile.monitoring = true

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	mesh.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.1, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.1, 0.8)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	projectile.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	projectile.add_child(col)

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector3(0, 1.5, 0)

	var direction := (target.global_position + Vector3(0, 1, 0) - projectile.global_position).normalized()
	var damage := attack_damage

	projectile.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, self)
			EventBus.show_damage_number.emit(body.global_position + Vector3(0, 2, 0), damage, false)
		if not body.is_in_group("enemy"):
			projectile.queue_free()
	)

	# Move projectile
	var tween := projectile.create_tween()
	var end_pos := projectile.global_position + direction * 20.0
	tween.tween_property(projectile, "global_position", end_pos, 20.0 / _projectile_speed)
	tween.tween_callback(projectile.queue_free)

	# Auto-destroy after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(projectile):
			projectile.queue_free()
	)
