class_name EnemySpawner
extends Node3D
## Spawns enemies in dungeon rooms based on floor depth.

const ENEMIES_PER_ROOM_BASE := 2
const ENEMIES_PER_ROOM_SCALE := 0.5  # Extra per floor
const BOSS_FLOOR_INTERVAL := 5  # Boss every N floors

var _active_enemies: Array[Node] = []


func spawn_enemies_for_floor(floor_data: Dictionary) -> void:
	_clear_enemies()

	var floor_num: int = floor_data.floor_number
	var spawn_points: Array = floor_data.enemy_spawn_points

	if spawn_points.is_empty():
		return

	var enemies_per_room := ENEMIES_PER_ROOM_BASE + int(floor_num * ENEMIES_PER_ROOM_SCALE)
	var total_enemies := mini(enemies_per_room * (spawn_points.size() / 4), 40)  # Cap at 40

	for i in total_enemies:
		var sp: Vector3 = spawn_points[randi() % spawn_points.size()]
		sp += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var enemy := _create_enemy(floor_num)
		add_child(enemy)
		enemy.global_position = sp
		_active_enemies.append(enemy)

	# Boss on boss floors
	if floor_num % BOSS_FLOOR_INTERVAL == 0 and spawn_points.size() > 0:
		var boss_pos: Vector3 = spawn_points[spawn_points.size() - 1]
		var boss := SkeletonKing.new()
		# Scale boss health with floor
		boss.max_health *= 1.0 + (floor_num / 10.0)
		add_child(boss)
		boss.global_position = boss_pos
		_active_enemies.append(boss)
		EventBus.show_notification.emit("A BOSS lurks on this floor!", "boss")


func _create_enemy(floor_num: int) -> EnemyBase:
	var roll := randf()

	# Deeper floors have harder enemies
	if floor_num >= 7 and roll < 0.3:
		var wraith := Wraith.new()
		wraith.max_health *= 1.0 + (floor_num * 0.1)
		wraith.attack_damage *= 1.0 + (floor_num * 0.05)
		return wraith
	elif floor_num >= 4 and roll < 0.6:
		var spider := Spider.new()
		spider.max_health *= 1.0 + (floor_num * 0.1)
		spider.attack_damage *= 1.0 + (floor_num * 0.05)
		return spider
	else:
		var skeleton := Skeleton.new()
		skeleton.max_health *= 1.0 + (floor_num * 0.1)
		skeleton.attack_damage *= 1.0 + (floor_num * 0.05)
		return skeleton


func _clear_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()

	# Also clear any strays
	for child in get_children():
		child.queue_free()
