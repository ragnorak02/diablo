extends Node3D
## Main game scene. Bootstraps all systems, manages game loop.

var floor_manager: FloorManager
var extraction_manager: ExtractionManager
var pvp_manager: PvPManager
var player: PlayerController
var camera: CameraController
var hud: HUD
var inventory_screen: InventoryScreen
var pause_menu: PauseMenu
var game_over_screen: GameOverScreen


func _ready() -> void:
	# Create floor manager (dungeon + enemies + loot)
	floor_manager = FloorManager.new()
	floor_manager.name = "FloorManager"
	add_child(floor_manager)

	# Create extraction manager
	extraction_manager = ExtractionManager.new()
	extraction_manager.name = "ExtractionManager"
	add_child(extraction_manager)

	# Create PvP manager
	pvp_manager = PvPManager.new()
	pvp_manager.name = "PvPManager"
	add_child(pvp_manager)

	# Create player
	player = PlayerController.new()
	player.name = "Player"
	add_child(player)

	# Create camera
	camera = CameraController.new()
	camera.name = "GameCamera"
	camera.target = player
	add_child(camera)

	# Create UI layers
	hud = HUD.new()
	hud.name = "HUD"
	add_child(hud)

	inventory_screen = InventoryScreen.new()
	inventory_screen.name = "InventoryScreen"
	add_child(inventory_screen)

	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)

	game_over_screen = GameOverScreen.new()
	game_over_screen.name = "GameOverScreen"
	add_child(game_over_screen)

	# Connect extraction interact
	EventBus.extraction_zone_entered.connect(_on_extraction_zone)

	# Connect audio events
	EventBus.loot_picked_up.connect(_on_loot_picked_up)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.floor_changed.connect(_on_floor_changed_audio)

	# Start the run after one frame so all nodes are in the tree
	await get_tree().process_frame
	GameManager.start_new_run()

	# Start dungeon music
	AudioManager.play_music("dungeon_ambient")
	AudioManager.play_ambient("dungeon_drips")


func _process(_delta: float) -> void:
	# Update extraction progress display
	if extraction_manager.is_extracting:
		hud.show_extraction_progress(extraction_manager.extraction_progress, ExtractionManager.EXTRACTION_TIME)
	elif hud:
		hud.hide_extraction_progress()


func _input(event: InputEvent) -> void:
	# Extraction trigger
	if event.is_action_pressed("interact"):
		if extraction_manager._player_in_zone.get(player.player_id, false):
			if not extraction_manager.is_extracting:
				extraction_manager.start_extraction(player.player_id)


func _on_extraction_zone(_player_id: int) -> void:
	pass  # Notification handled by extraction manager


func _on_loot_picked_up(_player_id: int, _item_data: Dictionary) -> void:
	AudioManager.play_sfx("loot_pickup")


func _on_player_leveled_up(_player_id: int, _new_level: int) -> void:
	AudioManager.play_sfx("level_up")


func _on_floor_changed_audio(_floor_number: int) -> void:
	# Restart dungeon music on each new floor
	AudioManager.play_music("dungeon_ambient")
	AudioManager.play_ambient("dungeon_drips")
