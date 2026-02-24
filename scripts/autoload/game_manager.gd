extends Node
## Central game state manager. Handles game flow, floor transitions, extraction state.

enum GameState { MENU, PLAYING, PAUSED, EXTRACTING, GAME_OVER, VICTORY }

var state: GameState = GameState.MENU
var current_floor: int = 1
var max_floor_reached: int = 1
var total_floors: int = 10
var run_timer: float = 0.0
var is_run_active: bool = false

# Player data persists across floors
var player_data: Dictionary = {
	"health": 100.0,
	"max_health": 100.0,
	"mana": 50.0,
	"max_mana": 50.0,
	"level": 1,
	"xp": 0,
	"xp_to_next": 100,
	"gold": 0,
	"inventory": [],
	"trophies": [],
	"potions": 3,
	"max_potions": 5,
	"stats": {
		"strength": 10,
		"dexterity": 10,
		"vitality": 10,
		"intelligence": 10,
	}
}

# Run statistics
var run_stats: Dictionary = {
	"enemies_killed": 0,
	"damage_dealt": 0.0,
	"damage_taken": 0.0,
	"items_collected": 0,
	"floors_cleared": 0,
	"pvp_kills": 0,
	"gold_earned": 0,
	"time_elapsed": 0.0,
}


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.loot_picked_up.connect(_on_loot_picked_up)
	EventBus.extraction_completed.connect(_on_extraction_completed)
	EventBus.pvp_kill.connect(_on_pvp_kill)


func _process(delta: float) -> void:
	if is_run_active and state == GameState.PLAYING:
		run_timer += delta
		run_stats.time_elapsed = run_timer


func start_new_run() -> void:
	state = GameState.PLAYING
	current_floor = 1
	max_floor_reached = 1
	run_timer = 0.0
	is_run_active = true
	_reset_player_data()
	_reset_run_stats()
	EventBus.floor_changed.emit(current_floor)


func change_floor(direction: int) -> void:
	var new_floor := current_floor + direction
	if new_floor < 1 or new_floor > total_floors:
		return
	current_floor = new_floor
	if new_floor > max_floor_reached:
		max_floor_reached = new_floor
	EventBus.floor_changed.emit(current_floor)


func pause_game() -> void:
	if state == GameState.PLAYING:
		state = GameState.PAUSED
		get_tree().paused = true


func resume_game() -> void:
	if state == GameState.PAUSED:
		state = GameState.PLAYING
		get_tree().paused = false


func get_xp_for_next_level(level: int) -> int:
	return int(100 * pow(1.5, level - 1))


func add_xp(amount: int) -> void:
	player_data.xp += amount
	EventBus.player_xp_gained.emit(0, amount)
	while player_data.xp >= player_data.xp_to_next:
		player_data.xp -= player_data.xp_to_next
		player_data.level += 1
		player_data.xp_to_next = get_xp_for_next_level(player_data.level)
		_apply_level_up()
		EventBus.player_leveled_up.emit(0, player_data.level)


func _apply_level_up() -> void:
	player_data.max_health += 10.0
	player_data.health = player_data.max_health
	player_data.max_mana += 5.0
	player_data.mana = player_data.max_mana
	player_data.stats.strength += 2
	player_data.stats.dexterity += 2
	player_data.stats.vitality += 2
	player_data.stats.intelligence += 2
	EventBus.show_notification.emit("LEVEL UP! Now level %d" % player_data.level, "level_up")


func _reset_player_data() -> void:
	player_data.health = 100.0
	player_data.max_health = 100.0
	player_data.mana = 50.0
	player_data.max_mana = 50.0
	player_data.level = 1
	player_data.xp = 0
	player_data.xp_to_next = 100
	player_data.gold = 0
	player_data.inventory.clear()
	player_data.trophies.clear()
	player_data.potions = 3
	player_data.stats.strength = 10
	player_data.stats.dexterity = 10
	player_data.stats.vitality = 10
	player_data.stats.intelligence = 10


func _reset_run_stats() -> void:
	for key in run_stats:
		if run_stats[key] is float:
			run_stats[key] = 0.0
		else:
			run_stats[key] = 0


func _on_player_died(_player_id: int) -> void:
	state = GameState.GAME_OVER
	is_run_active = false


func _on_enemy_died(_enemy: Node, _killer: Node) -> void:
	run_stats.enemies_killed += 1


func _on_loot_picked_up(_player_id: int, item_data: Dictionary) -> void:
	run_stats.items_collected += 1
	if item_data.has("gold_value"):
		run_stats.gold_earned += item_data.gold_value


func _on_extraction_completed(_player_id: int, _loot: Array) -> void:
	state = GameState.VICTORY
	is_run_active = false
	run_stats.floors_cleared = max_floor_reached


func go_to_town() -> void:
	get_tree().change_scene_to_file("res://scenes/Town.tscn")


func go_to_dungeon_entrance() -> void:
	get_tree().change_scene_to_file("res://scenes/CathedralEntrance.tscn")


func go_to_dungeon_floor() -> void:
	get_tree().change_scene_to_file("res://scenes/DungeonFloor.tscn")


func _on_pvp_kill(_killer_id: int, _victim_id: int) -> void:
	run_stats.pvp_kills += 1
