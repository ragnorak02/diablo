extends Node2D
## Walkable cathedral interior with stairs down to dungeon.
## Stairway zone → enters dungeon. Exit door → returns to Town.

const PlayerIsoScript = preload("res://scripts/player/player_iso.gd")
const IsoTileGridScript = preload("res://scripts/environment/iso_tile_grid.gd")
const InteractionZoneScript = preload("res://scripts/environment/interaction_zone.gd")

var _player: CharacterBody2D
var _camera: Camera2D


func _ready() -> void:
	y_sort_enabled = true

	# Floor tiles — dark stone
	var floor_tiles = IsoTileGridScript.new()
	floor_tiles.name = "FloorTiles"
	floor_tiles.grid_width = 10
	floor_tiles.grid_height = 14
	floor_tiles.tile_size = 32.0
	floor_tiles.tile_color = Color(0.18, 0.16, 0.14)
	floor_tiles.tile_color_alt = Color(0.14, 0.12, 0.10)
	add_child(floor_tiles)

	var grid_center = floor_tiles.get_grid_center()

	# --- Walls ---
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)

	# Left wall
	var left_wall := StaticBody2D.new()
	left_wall.collision_layer = 1
	left_wall.position = grid_center + Vector2(-90, 0)
	walls.add_child(left_wall)
	_add_wall_segment(left_wall, Vector2.ZERO, Vector2(8, 200))

	# Wall visual (left)
	var lw_vis := Polygon2D.new()
	lw_vis.polygon = PackedVector2Array([
		Vector2(-4, -100), Vector2(4, -100),
		Vector2(4, 100), Vector2(-4, 100),
	])
	lw_vis.color = Color(0.3, 0.25, 0.2)
	left_wall.add_child(lw_vis)

	# Right wall
	var right_wall := StaticBody2D.new()
	right_wall.collision_layer = 1
	right_wall.position = grid_center + Vector2(90, 0)
	walls.add_child(right_wall)
	_add_wall_segment(right_wall, Vector2.ZERO, Vector2(8, 200))

	var rw_vis := Polygon2D.new()
	rw_vis.polygon = PackedVector2Array([
		Vector2(-4, -100), Vector2(4, -100),
		Vector2(4, 100), Vector2(-4, 100),
	])
	rw_vis.color = Color(0.3, 0.25, 0.2)
	right_wall.add_child(rw_vis)

	# Back wall
	var back_wall := StaticBody2D.new()
	back_wall.collision_layer = 1
	back_wall.position = grid_center + Vector2(0, -100)
	walls.add_child(back_wall)
	_add_wall_segment(back_wall, Vector2.ZERO, Vector2(180, 8))

	var bw_vis := Polygon2D.new()
	bw_vis.polygon = PackedVector2Array([
		Vector2(-90, -4), Vector2(90, -4),
		Vector2(90, 4), Vector2(-90, 4),
	])
	bw_vis.color = Color(0.3, 0.25, 0.2)
	back_wall.add_child(bw_vis)

	# --- Pillars ---
	var pillar_positions := [
		grid_center + Vector2(-50, -40),
		grid_center + Vector2(50, -40),
		grid_center + Vector2(-50, 30),
		grid_center + Vector2(50, 30),
	]
	for i in pillar_positions.size():
		var pillar := StaticBody2D.new()
		pillar.name = "Pillar%d" % i
		pillar.collision_layer = 1
		pillar.position = pillar_positions[i]
		add_child(pillar)
		_add_wall_segment(pillar, Vector2.ZERO, Vector2(12, 12))

		var pvis := Polygon2D.new()
		pvis.polygon = PackedVector2Array([
			Vector2(-6, -6), Vector2(6, -6),
			Vector2(6, 6), Vector2(-6, 6),
		])
		pvis.color = Color(0.4, 0.35, 0.28)
		pillar.add_child(pvis)

	# --- Stairway zone (descend into dungeon) ---
	var stairway = InteractionZoneScript.new()
	stairway.name = "StairwayZone"
	stairway.prompt_text = "Press [A] to descend"
	stairway.position = grid_center + Vector2(0, -60)
	add_child(stairway)

	var stair_col := CollisionShape2D.new()
	var stair_shape := RectangleShape2D.new()
	stair_shape.size = Vector2(40, 30)
	stair_col.shape = stair_shape
	stairway.add_child(stair_col)

	# Stairs visual — dark opening
	var stairs_vis := Polygon2D.new()
	stairs_vis.polygon = PackedVector2Array([
		Vector2(-18, -12), Vector2(18, -12),
		Vector2(18, 12), Vector2(-18, 12),
	])
	stairs_vis.color = Color(0.05, 0.03, 0.08)
	stairway.add_child(stairs_vis)

	var stairs_label := Label.new()
	stairs_label.text = "Stairs Down"
	stairs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stairs_label.position = Vector2(-30, -30)
	stairs_label.add_theme_font_size_override("font_size", 12)
	stairs_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
	stairway.add_child(stairs_label)

	stairway.zone_activated.connect(_on_stairway_activated)

	# --- Exit door (return to town) ---
	var exit_door = InteractionZoneScript.new()
	exit_door.name = "ExitDoorZone"
	exit_door.prompt_text = "Press [A] to exit to Town"
	exit_door.target_scene = "res://scenes/Town.tscn"
	exit_door.position = grid_center + Vector2(0, 85)
	add_child(exit_door)

	var exit_col := CollisionShape2D.new()
	var exit_shape := RectangleShape2D.new()
	exit_shape.size = Vector2(30, 20)
	exit_col.shape = exit_shape
	exit_door.add_child(exit_col)

	# Door visual — amber rectangle
	var exit_vis := Polygon2D.new()
	exit_vis.polygon = PackedVector2Array([
		Vector2(-12, -8), Vector2(12, -8),
		Vector2(12, 8), Vector2(-12, 8),
	])
	exit_vis.color = Color(0.6, 0.45, 0.15)
	exit_door.add_child(exit_vis)

	# --- Location label ---
	var loc_label := Label.new()
	loc_label.name = "LocationLabel"
	loc_label.text = "Cathedral"
	loc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_label.position = grid_center + Vector2(-40, -120)
	loc_label.add_theme_font_size_override("font_size", 24)
	loc_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.3))
	add_child(loc_label)

	# --- Spawn player near exit door ---
	_player = PlayerIsoScript.new()
	_player.name = "Player"
	_player.position = grid_center + Vector2(0, 60)
	add_child(_player)

	# --- Camera ---
	_camera = Camera2D.new()
	_camera.name = "GameCamera"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.zoom = Vector2(2.5, 2.5)
	add_child(_camera)

	# --- HUD ---
	var hud := HUD.new()
	hud.name = "HUD"
	add_child(hud)

	EventBus.show_notification.emit("Cathedral Entrance", "default")


func _process(_delta: float) -> void:
	if _player and _camera:
		_camera.position = _player.position


func _on_stairway_activated() -> void:
	# Enter dungeon floor 1
	GameManager.current_floor = 1
	get_tree().change_scene_to_file("res://scenes/DungeonFloor.tscn")


func _add_wall_segment(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	parent.add_child(col)
