class_name ExtractionManager
extends Node
## Manages the extraction mechanic. Players must physically return to entrance to extract.

const EXTRACTION_TIME: float = 5.0  # Seconds to channel extraction
const EXTRACTION_INTERRUPT_RANGE: float = 8.0  # Enemies within this range cancel extraction

var is_extracting: bool = false
var extraction_progress: float = 0.0
var extracting_player_id: int = -1
var _player_in_zone: Dictionary = {}  # player_id -> bool


func _ready() -> void:
	EventBus.extraction_zone_entered.connect(_on_zone_entered)
	EventBus.extraction_zone_exited.connect(_on_zone_exited)
	EventBus.player_damaged.connect(_on_player_damaged)


func _process(delta: float) -> void:
	if is_extracting:
		# Check for nearby enemies that would interrupt
		if _enemies_nearby():
			cancel_extraction("Enemies nearby! Extraction cancelled!")
			return

		extraction_progress += delta
		if extraction_progress >= EXTRACTION_TIME:
			_complete_extraction()


func start_extraction(player_id: int) -> void:
	if not _player_in_zone.get(player_id, false):
		EventBus.show_notification.emit("Must be in extraction zone!", "warning")
		return

	if GameManager.current_floor != 1:
		EventBus.show_notification.emit("Must return to floor 1 to extract!", "warning")
		return

	is_extracting = true
	extraction_progress = 0.0
	extracting_player_id = player_id
	EventBus.extraction_started.emit(player_id)
	EventBus.show_notification.emit("Extracting... Hold position for %ds" % int(EXTRACTION_TIME), "extraction")


func cancel_extraction(reason: String = "Extraction cancelled!") -> void:
	is_extracting = false
	extraction_progress = 0.0
	var pid := extracting_player_id
	extracting_player_id = -1
	EventBus.extraction_cancelled.emit(pid)
	EventBus.show_notification.emit(reason, "warning")


func _complete_extraction() -> void:
	is_extracting = false
	var pid := extracting_player_id
	extracting_player_id = -1

	var loot: Array = GameManager.player_data.inventory.duplicate(true)
	var trophies: Array = GameManager.player_data.trophies.duplicate(true)
	var gold: int = GameManager.player_data.gold

	EventBus.extraction_completed.emit(pid, loot)
	EventBus.show_notification.emit("EXTRACTION SUCCESSFUL! Gold: %d, Items: %d" % [gold, loot.size()], "extraction")


func _enemies_nearby() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and enemy.state != EnemyBase.State.DEAD:
			# Find the extracting player
			for player in get_tree().get_nodes_in_group("player"):
				if player is PlayerController and player.player_id == extracting_player_id:
					if enemy.global_position.distance_to(player.global_position) < EXTRACTION_INTERRUPT_RANGE:
						return true
	return false


func _on_zone_entered(player_id: int) -> void:
	_player_in_zone[player_id] = true
	EventBus.show_notification.emit("Extraction zone! Press [E] / [Y] to extract", "extraction")


func _on_zone_exited(player_id: int) -> void:
	_player_in_zone[player_id] = false
	if is_extracting and extracting_player_id == player_id:
		cancel_extraction("Left extraction zone!")


func _on_player_damaged(player_id: int, _amount: float, _source: Node) -> void:
	if is_extracting and extracting_player_id == player_id:
		cancel_extraction("Took damage! Extraction interrupted!")
