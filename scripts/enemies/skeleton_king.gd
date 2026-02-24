class_name SkeletonKing
extends EnemyBase
## Boss enemy — Skeleton King. Large, powerful, multi-phase combat.

enum BossPhase { PHASE_1, PHASE_2, ENRAGE }

var boss_phase: BossPhase = BossPhase.PHASE_1
var _summon_timer: float = 0.0
var _summon_cooldown: float = 10.0
var _slam_cooldown: float = 5.0
var _slam_timer: float = 0.0
var _enrage_threshold: float = 0.3


func _ready() -> void:
	enemy_name = "Skeleton King"
	enemy_type = "boss"
	max_health = 500.0
	move_speed = 2.5
	attack_damage = 25.0
	attack_range = 3.0
	attack_cooldown = 1.5
	detection_range = 20.0
	xp_reward = 200
	_base_color = Color(0.9, 0.8, 0.2)  # Golden

	super._ready()

	# Boss is bigger
	if _mesh:
		_mesh.scale = Vector3(1.8, 2.0, 1.8)
		_mesh.position.y = 1.6

	# Update collision
	for child in get_children():
		if child is CollisionShape3D and child.shape is CapsuleShape3D:
			var shape: CapsuleShape3D = child.shape
			shape.radius = 0.7
			shape.height = 3.2
			child.position.y = 1.6
			break


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	# Phase transitions
	var health_pct := health / max_health
	if health_pct <= 0.5 and boss_phase == BossPhase.PHASE_1:
		boss_phase = BossPhase.PHASE_2
		move_speed = 3.5
		attack_damage = 35.0
		attack_cooldown = 1.0
		EventBus.show_notification.emit("Skeleton King enters Phase 2!", "boss")

	if health_pct <= _enrage_threshold and boss_phase == BossPhase.PHASE_2:
		boss_phase = BossPhase.ENRAGE
		move_speed = 4.5
		attack_damage = 45.0
		attack_cooldown = 0.7
		# Visual feedback
		if _mesh and _mesh.material_override:
			var mat: StandardMaterial3D = _mesh.material_override
			mat.emission = Color(1.0, 0.2, 0.1)
			mat.emission_energy_multiplier = 1.5
		EventBus.show_notification.emit("Skeleton King is ENRAGED!", "boss")

	# Special abilities
	_summon_timer += delta
	_slam_timer += delta

	if state == State.CHASE or state == State.ATTACK:
		if _summon_timer >= _summon_cooldown and boss_phase != BossPhase.PHASE_1:
			_summon_minions()
			_summon_timer = 0.0

		if _slam_timer >= _slam_cooldown:
			_ground_slam()
			_slam_timer = 0.0

	super._physics_process(delta)


func _summon_minions() -> void:
	EventBus.show_notification.emit("Skeleton King summons minions!", "boss")
	for i in 3:
		var angle := (TAU / 3.0) * i
		var offset := Vector3(cos(angle) * 3.0, 0, sin(angle) * 3.0)
		var spawn_pos := global_position + offset

		var skeleton := Skeleton.new()
		skeleton.global_position = spawn_pos
		get_tree().current_scene.add_child(skeleton)


func _ground_slam() -> void:
	if not is_instance_valid(target):
		return

	EventBus.show_notification.emit("Ground Slam!", "boss")

	# AoE damage around boss
	var slam_range := 5.0
	var slam_damage := attack_damage * 1.5

	for node in get_tree().get_nodes_in_group("player"):
		if node is PlayerController and not node.is_dead:
			var dist := global_position.distance_to(node.global_position)
			if dist <= slam_range:
				var falloff := 1.0 - (dist / slam_range)
				node.take_damage(slam_damage * falloff, self)


func die(killer: Node = null) -> void:
	# Drop trophy
	var trophy := ItemDatabase.create_item_instance("skeleton_kings_crown")
	if not trophy.is_empty():
		EventBus.loot_dropped.emit(trophy, global_position + Vector3(0, 1, 0))

	super.die(killer)
