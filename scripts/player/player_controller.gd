class_name PlayerController
extends CharacterBody3D
## Player character controller. Handles movement, combat, dodge, health, and stats.

@export var player_id: int = 0
@export var move_speed: float = 7.0
@export var dodge_speed: float = 14.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.8
@export var attack_range: float = 2.5
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 0.5

# Health/Mana
var health: float = 100.0
var max_health: float = 100.0
var mana: float = 50.0
var max_mana: float = 50.0
var is_dead: bool = false

# Combat state
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _is_dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_cooldown_timer: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO

# Aim direction
var _aim_direction: Vector3 = Vector3.FORWARD
var _mouse_aim_pos: Vector3 = Vector3.ZERO

# References
var _camera: Camera3D
var _mesh: MeshInstance3D
var _attack_area: Area3D
var _health_regen_timer: float = 0.0
var _mana_regen_timer: float = 0.0

# Invincibility frames during dodge
var _invincible: bool = false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2  # player layer
	collision_mask = 1 | 4 | 16 | 32 | 64  # environment, enemies, loot, interaction, extraction

	_setup_mesh()
	_setup_attack_area()
	_setup_collision()
	_sync_from_game_manager()


func _setup_mesh() -> void:
	_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	_mesh.mesh = capsule

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.2, 0.4)
	mat.emission_energy_multiplier = 0.3
	_mesh.material_override = mat

	_mesh.position.y = 0.9
	add_child(_mesh)


func _setup_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)


func _setup_attack_area() -> void:
	_attack_area = Area3D.new()
	_attack_area.name = "AttackArea"
	_attack_area.collision_layer = 8  # projectiles layer
	_attack_area.collision_mask = 4 | 2  # enemies + players (for PvP)
	_attack_area.monitoring = false  # Only enable during attack
	add_child(_attack_area)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = attack_range
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	_attack_area.add_child(col)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)
	_handle_movement(delta)
	_handle_aim()
	_handle_combat()
	_handle_dodge()
	_handle_interact()
	_handle_potion()
	_handle_regen(delta)

	move_and_slide()


func _update_timers(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
		if _attack_timer <= 0:
			_is_attacking = false
			_attack_area.monitoring = false

	if _dodge_timer > 0:
		_dodge_timer -= delta
		if _dodge_timer <= 0:
			_is_dodging = false
			_invincible = false

	if _dodge_cooldown_timer > 0:
		_dodge_cooldown_timer -= delta


func _handle_movement(delta: float) -> void:
	if _is_dodging:
		velocity = _dodge_direction * dodge_speed
		velocity.y -= 20.0 * delta  # Gravity
		return

	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_back")

	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var speed := move_speed
	if _is_attacking:
		speed *= 0.4  # Slow during attack

	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

	# Face movement direction
	if input_dir.length() > 0.1 and not _is_attacking:
		_aim_direction = input_dir.normalized()
		_mesh.rotation.y = atan2(-_aim_direction.x, -_aim_direction.z)


func _handle_aim() -> void:
	# Right stick aim (controller)
	var aim_input := Vector3.ZERO
	aim_input.x = Input.get_axis("aim_left", "aim_right")
	aim_input.z = Input.get_axis("aim_up", "aim_down")

	if aim_input.length() > 0.3:
		_aim_direction = aim_input.normalized()
		_mesh.rotation.y = atan2(-_aim_direction.x, -_aim_direction.z)


func _handle_combat() -> void:
	if Input.is_action_just_pressed("attack_primary") and _attack_timer <= 0:
		_perform_attack(false)

	if Input.is_action_just_pressed("attack_secondary") and _attack_timer <= 0 and mana >= 15.0:
		_perform_attack(true)

	if Input.is_action_just_pressed("skill_1") and mana >= 25.0:
		_perform_skill()


func _perform_attack(is_heavy: bool) -> void:
	_is_attacking = true
	var cd := attack_cooldown
	var dmg := _calculate_damage()

	if is_heavy:
		cd *= 1.5
		dmg *= 2.0
		mana -= 15.0

	_attack_timer = cd
	_attack_area.monitoring = true

	AudioManager.play_sfx("attack_swing")

	# Show swing visual on every attack
	_show_attack_arc(is_heavy)

	# Detect and damage enemies in range
	# Short delay to let area detect overlapping bodies
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self):
		return

	var hit_something := false
	for body in _attack_area.get_overlapping_bodies():
		if body == self:
			continue

		var dir_to_body := (body.global_position - global_position).normalized()
		var dot := _aim_direction.dot(Vector3(dir_to_body.x, 0, dir_to_body.z).normalized())

		# Only hit things roughly in front (120 degree arc)
		if dot > 0.0 or is_heavy:  # Heavy attack is 360
			if body.is_in_group("enemy"):
				_deal_damage_to(body, dmg)
				hit_something = true
			elif body.is_in_group("player") and body != self:
				# PvP damage
				_deal_damage_to(body, dmg * 0.7)  # Reduced PvP damage
				EventBus.pvp_damage.emit(player_id, body.player_id, dmg * 0.7)
				hit_something = true

	_attack_area.monitoring = false

	# Visual feedback
	if hit_something:
		_flash_mesh(Color(1.0, 0.8, 0.3))


func _perform_skill() -> void:
	mana -= 25.0
	var dmg := _calculate_damage() * 3.0

	AudioManager.play_sfx("ground_slam")

	# Show slam visual
	_show_slam_effect()

	# AoE slam - damage everything nearby
	_attack_area.monitoring = true
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self):
		return

	for body in _attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("enemy") or (body.is_in_group("player") and body != self):
			_deal_damage_to(body, dmg)
			EventBus.show_damage_number.emit(body.global_position, dmg, true)

	_attack_area.monitoring = false
	_attack_timer = attack_cooldown * 2.0
	EventBus.show_notification.emit("GROUND SLAM!", "skill")


func _deal_damage_to(target: Node, amount: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(amount, self)
	AudioManager.play_sfx("attack_hit")
	EventBus.show_damage_number.emit(target.global_position + Vector3(0, 2, 0), amount, amount > attack_damage * 1.5)


func _calculate_damage() -> float:
	var base: float = attack_damage
	var str_bonus: float = float(GameManager.player_data.stats.strength) * 0.5
	# Check equipped weapon
	for item in GameManager.player_data.inventory:
		if item.has("damage") and item.get("equipped", false):
			base = item.damage
			break
	return base + str_bonus


func _handle_dodge() -> void:
	if Input.is_action_just_pressed("dodge") and _dodge_cooldown_timer <= 0 and not _is_dodging:
		_is_dodging = true
		_invincible = true
		_dodge_timer = dodge_duration
		_dodge_cooldown_timer = dodge_cooldown
		AudioManager.play_sfx("dodge")

		var input_dir := Vector3.ZERO
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.z = Input.get_axis("move_forward", "move_back")

		if input_dir.length() > 0.1:
			_dodge_direction = input_dir.normalized()
		else:
			_dodge_direction = _aim_direction


func _handle_interact() -> void:
	if Input.is_action_just_pressed("interact"):
		# Check for nearby interactables (stairs, items)
		pass  # Handled by Area3D signals from dungeon


func _handle_potion() -> void:
	if Input.is_action_just_pressed("use_potion") and GameManager.player_data.potions > 0:
		if health < max_health:
			GameManager.player_data.potions -= 1
			var heal_amount := 40.0
			heal(heal_amount)
			AudioManager.play_sfx("potion_use")
			EventBus.show_notification.emit("Used Health Potion (+%d HP)" % int(heal_amount), "heal")


func _handle_regen(delta: float) -> void:
	# Mana regeneration
	_mana_regen_timer += delta
	if _mana_regen_timer >= 2.0:
		_mana_regen_timer = 0.0
		if mana < max_mana:
			mana = minf(mana + 2.0, max_mana)


func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or _invincible:
		return

	# Apply defense reduction
	var defense := 0.0
	for item in GameManager.player_data.inventory:
		if item.has("defense") and item.get("equipped", false):
			defense += item.defense
	defense += GameManager.player_data.stats.vitality * 0.3

	var reduced := maxf(amount - defense * 0.5, amount * 0.15)  # Min 15% damage
	health -= reduced
	GameManager.player_data.health = health

	AudioManager.play_sfx("player_damage")
	EventBus.player_damaged.emit(player_id, reduced, source)
	EventBus.show_damage_number.emit(global_position + Vector3(0, 2.5, 0), reduced, false)
	_flash_mesh(Color(1.0, 0.2, 0.2))

	if health <= 0:
		die()


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	GameManager.player_data.health = health
	EventBus.player_healed.emit(player_id, amount)


func die() -> void:
	is_dead = true
	health = 0.0
	GameManager.player_data.health = 0.0
	AudioManager.play_sfx("player_death")
	EventBus.player_died.emit(player_id)
	# Drop some loot on death
	_drop_death_loot()
	visible = false
	set_physics_process(false)


func respawn(pos: Vector3) -> void:
	is_dead = false
	health = max_health * 0.5  # Respawn at half health
	mana = max_mana * 0.5
	GameManager.player_data.health = health
	global_position = pos
	visible = true
	set_physics_process(true)
	EventBus.player_respawned.emit(player_id)


func _drop_death_loot() -> void:
	# Drop some inventory on death
	var to_drop: int = ceili(GameManager.player_data.inventory.size() * 0.3)
	for i in to_drop:
		if GameManager.player_data.inventory.is_empty():
			break
		var idx: int = randi() % GameManager.player_data.inventory.size()
		var item: Dictionary = GameManager.player_data.inventory[idx]
		GameManager.player_data.inventory.remove_at(idx)
		EventBus.loot_dropped.emit(item, global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2)))


func _sync_from_game_manager() -> void:
	health = GameManager.player_data.health
	max_health = GameManager.player_data.max_health
	mana = GameManager.player_data.mana
	max_mana = GameManager.player_data.max_mana
	attack_damage = 15.0 + GameManager.player_data.stats.strength * 0.5


func _flash_mesh(color: Color) -> void:
	if _mesh and _mesh.material_override:
		var mat: StandardMaterial3D = _mesh.material_override
		var original_emission := mat.emission
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(_mesh) and _mesh.material_override:
			mat.emission = original_emission
			mat.emission_energy_multiplier = 0.3


func _show_attack_arc(is_heavy: bool) -> void:
	var arc := MeshInstance3D.new()
	var box := BoxMesh.new()
	if is_heavy:
		box.size = Vector3(3.0, 1.2, 0.2)
	else:
		box.size = Vector3(2.5, 1.0, 0.15)

	arc.mesh = box

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	if is_heavy:
		mat.albedo_color = Color(0.6, 0.7, 1.0, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.7, 1.0)
		mat.emission_energy_multiplier = 2.0
	else:
		mat.albedo_color = Color(1.0, 0.85, 0.3, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.3)
		mat.emission_energy_multiplier = 1.5
	arc.material_override = mat

	# Position in front of player in aim direction
	var angle := atan2(-_aim_direction.x, -_aim_direction.z)
	arc.position = global_position + Vector3(_aim_direction.x * 1.3, 1.0, _aim_direction.z * 1.3)
	arc.rotation.y = angle

	get_parent().add_child(arc)

	# Tween: rotate 90° (swing arc) then fade out
	var tween := arc.create_tween()
	var sweep := PI * 0.5 if not is_heavy else PI * 0.75
	tween.tween_property(arc, "rotation:y", angle + sweep, 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.tween_callback(arc.queue_free)


func _show_slam_effect() -> void:
	var ring := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	ring.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.albedo_color = Color(1.0, 0.6, 0.2, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.emission_energy_multiplier = 2.5
	ring.material_override = mat

	ring.position = global_position + Vector3(0, 0.3, 0)
	get_parent().add_child(ring)

	# Scale up rapidly and fade
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(5.0, 1.5, 5.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)
