class_name EnemyBase
extends CharacterBody3D
## Base enemy class. All enemy types extend this.

@export var enemy_name: String = "Enemy"
@export var max_health: float = 50.0
@export var move_speed: float = 3.5
@export var attack_damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var detection_range: float = 12.0
@export var xp_reward: int = 20
@export var enemy_type: String = "basic"

enum State { IDLE, PATROL, CHASE, ATTACK, STAGGER, DEAD }

var health: float = 50.0
var state: State = State.IDLE
var target: Node3D = null
var _attack_timer: float = 0.0
var _stagger_timer: float = 0.0
var _patrol_timer: float = 0.0
var _patrol_direction: Vector3 = Vector3.ZERO
var _mesh: MeshInstance3D
var _nav_agent: NavigationAgent3D
var _detection_area: Area3D
var _base_color: Color = Color(0.6, 0.15, 0.1)


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4  # enemies layer
	collision_mask = 1 | 2 | 4  # environment, player, enemies

	health = max_health
	_setup_mesh()
	_setup_collision()
	_setup_navigation()
	_setup_detection()
	EventBus.enemy_spawned.emit(self)


func _setup_mesh() -> void:
	_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	_mesh.mesh = capsule

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _base_color
	mat.emission_enabled = true
	mat.emission = _base_color * 0.3
	mat.emission_energy_multiplier = 0.2
	_mesh.material_override = mat
	_mesh.position.y = 0.8
	add_child(_mesh)


func _setup_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	col.shape = shape
	col.position.y = 0.8
	add_child(col)


func _setup_navigation() -> void:
	_nav_agent = NavigationAgent3D.new()
	_nav_agent.path_desired_distance = 1.0
	_nav_agent.target_desired_distance = 1.5
	_nav_agent.max_speed = move_speed
	_nav_agent.avoidance_enabled = true
	_nav_agent.radius = 0.4
	add_child(_nav_agent)


func _setup_detection() -> void:
	_detection_area = Area3D.new()
	_detection_area.name = "DetectionArea"
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 2  # player layer
	_detection_area.monitoring = true
	add_child(_detection_area)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = detection_range
	col.shape = shape
	_detection_area.add_child(col)

	_detection_area.body_entered.connect(_on_player_detected)
	_detection_area.body_exited.connect(_on_player_lost)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_update_timers(delta)

	match state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.STAGGER:
			_process_stagger(delta)

	# Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	move_and_slide()


func _update_timers(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
	if _stagger_timer > 0:
		_stagger_timer -= delta
		if _stagger_timer <= 0:
			state = State.CHASE if target else State.IDLE


func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	_patrol_timer += delta
	if _patrol_timer > 3.0:
		_patrol_timer = 0.0
		state = State.PATROL
		_patrol_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


func _process_patrol(delta: float) -> void:
	velocity.x = _patrol_direction.x * move_speed * 0.4
	velocity.z = _patrol_direction.z * move_speed * 0.4
	_patrol_timer += delta
	if _patrol_timer > 2.0:
		_patrol_timer = 0.0
		state = State.IDLE
	_face_direction(_patrol_direction)


func _process_chase(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		state = State.IDLE
		return

	if target is PlayerController and target.is_dead:
		target = null
		state = State.IDLE
		return

	var dist := global_position.distance_to(target.global_position)

	if dist <= attack_range:
		state = State.ATTACK
		velocity.x = 0
		velocity.z = 0
		return

	# Navigate toward target
	_nav_agent.target_position = target.global_position
	if not _nav_agent.is_navigation_finished():
		var next_pos := _nav_agent.get_next_path_position()
		var direction := (next_pos - global_position).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_face_direction(direction)
	else:
		velocity.x = 0
		velocity.z = 0


func _process_attack(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		state = State.IDLE
		return

	var dist := global_position.distance_to(target.global_position)

	if dist > attack_range * 1.5:
		state = State.CHASE
		return

	_face_direction((target.global_position - global_position).normalized())
	velocity.x = 0
	velocity.z = 0

	if _attack_timer <= 0:
		_perform_attack()
		_attack_timer = attack_cooldown


func _process_stagger(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 10.0)
	velocity.z = move_toward(velocity.z, 0, 10.0)


func _perform_attack() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage, self)


func take_damage(amount: float, source: Node = null) -> void:
	if state == State.DEAD:
		return

	health -= amount
	AudioManager.play_sfx("enemy_hit")
	EventBus.enemy_damaged.emit(self, amount, source)

	# Stagger
	state = State.STAGGER
	_stagger_timer = 0.3

	# Knockback
	if source:
		var kb_dir: Vector3 = (global_position - source.global_position).normalized()
		velocity = kb_dir * 5.0

	# Aggro
	if source and source.is_in_group("player"):
		target = source

	_flash_mesh(Color(1, 1, 1))

	if health <= 0:
		die(source)


func die(killer: Node = null) -> void:
	state = State.DEAD
	health = 0
	AudioManager.play_sfx("enemy_death")
	EventBus.enemy_died.emit(self, killer)

	# Grant XP
	if killer and killer.is_in_group("player"):
		GameManager.add_xp(xp_reward)

	# Drop loot
	var drops := ItemDatabase.generate_loot_drop(GameManager.current_floor, enemy_type)
	for item in drops:
		EventBus.loot_dropped.emit(item, global_position + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)))

	# Death animation (simple fade)
	_death_animation()


func _death_animation() -> void:
	var tween := create_tween()
	tween.tween_property(_mesh, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	tween.parallel().tween_property(_mesh, "position:y", 0.1, 0.5)
	tween.tween_callback(queue_free)


func _face_direction(dir: Vector3) -> void:
	if dir.length() > 0.01 and _mesh:
		_mesh.rotation.y = atan2(-dir.x, -dir.z)


func _flash_mesh(color: Color) -> void:
	if _mesh and _mesh.material_override:
		var mat: StandardMaterial3D = _mesh.material_override
		var orig := mat.emission
		mat.emission = color
		mat.emission_energy_multiplier = 3.0
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(_mesh) and _mesh.material_override:
			mat.emission = orig
			mat.emission_energy_multiplier = 0.2


func _on_player_detected(body: Node3D) -> void:
	if body.is_in_group("player") and state != State.DEAD:
		if body is PlayerController and not body.is_dead:
			target = body
			state = State.CHASE


func _on_player_lost(body: Node3D) -> void:
	if body == target:
		# Keep chasing for a bit, then lose interest
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(self) and state != State.DEAD:
			if not is_instance_valid(target) or global_position.distance_to(target.global_position) > detection_range:
				target = null
				state = State.IDLE
