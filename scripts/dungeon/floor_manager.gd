class_name FloorManager
extends Node3D
## Manages floor transitions. Generates new dungeon floors, spawns enemies, handles stairs.

var dungeon_generator: DungeonGenerator
var enemy_spawner: EnemySpawner
var loot_spawner: Node3D
var _current_floor_data: Dictionary = {}


func _ready() -> void:
	dungeon_generator = DungeonGenerator.new()
	dungeon_generator.name = "DungeonGenerator"
	add_child(dungeon_generator)

	enemy_spawner = EnemySpawner.new()
	enemy_spawner.name = "EnemySpawner"
	add_child(enemy_spawner)

	loot_spawner = Node3D.new()
	loot_spawner.name = "LootSpawner"
	add_child(loot_spawner)

	EventBus.stairs_entered.connect(_on_stairs_entered)
	EventBus.loot_dropped.connect(_on_loot_dropped)
	EventBus.floor_changed.connect(_on_floor_changed)


func generate_floor(floor_num: int) -> Dictionary:
	_current_floor_data = dungeon_generator.generate_floor(floor_num)
	enemy_spawner.spawn_enemies_for_floor(_current_floor_data)
	_clear_loot()
	return _current_floor_data


func get_player_spawn_position() -> Vector3:
	if _current_floor_data.has("spawn_points"):
		var spawns: Array = _current_floor_data.spawn_points
		if spawns.size() > 0:
			return spawns[0]
	return Vector3(30, 1, 30)  # Fallback


func _on_stairs_entered(direction: String, _floor: int) -> void:
	if direction == "down":
		GameManager.change_floor(1)
	elif direction == "up":
		if GameManager.current_floor > 1:
			GameManager.change_floor(-1)


func _on_floor_changed(floor_number: int) -> void:
	var floor_data := generate_floor(floor_number)

	# Teleport player to entrance of new floor
	for player in get_tree().get_nodes_in_group("player"):
		if player is PlayerController:
			player.global_position = get_player_spawn_position() + Vector3(0, 1, 0)

	EventBus.show_notification.emit("Floor %d" % floor_number, "default")


func _on_loot_dropped(item_data: Dictionary, world_pos: Vector3) -> void:
	var drop := LootDrop.new()
	drop.init(item_data, world_pos)
	loot_spawner.add_child(drop)


func _clear_loot() -> void:
	for child in loot_spawner.get_children():
		child.queue_free()
