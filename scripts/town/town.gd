extends Node2D
## Walkable isometric town (Tristram). Player spawns and moves freely with camera follow.
## Walking to cathedral door + pressing interact → CathedralEntrance.tscn

const PlayerIsoScript = preload("res://scripts/player/player_iso.gd")
const IsoTileGridScript = preload("res://scripts/environment/iso_tile_grid.gd")
const InteractionZoneScript = preload("res://scripts/environment/interaction_zone.gd")

var _player: CharacterBody2D
var _camera: Camera2D


func _ready() -> void:
	y_sort_enabled = true

	# Ground tiles — green-brown grass/dirt
	var ground = IsoTileGridScript.new()
	ground.name = "GroundTiles"
	ground.grid_width = 24
	ground.grid_height = 24
	ground.tile_size = 32.0
	ground.tile_color = Color(0.22, 0.28, 0.15)
	ground.tile_color_alt = Color(0.18, 0.24, 0.12)
	add_child(ground)

	var grid_center = ground.get_grid_center()

	# --- Buildings ---
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	add_child(buildings)

	# Cathedral
	var cathedral := Node2D.new()
	cathedral.name = "Cathedral"
	cathedral.position = grid_center + Vector2(0, -80)
	buildings.add_child(cathedral)

	var cathedral_body := Polygon2D.new()
	cathedral_body.polygon = PackedVector2Array([
		Vector2(-50, -40), Vector2(50, -40),
		Vector2(50, 40), Vector2(-50, 40),
	])
	cathedral_body.color = Color(0.3, 0.25, 0.2)
	cathedral.add_child(cathedral_body)

	# Cathedral label
	var cath_label := Label.new()
	cath_label.text = "Cathedral"
	cath_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cath_label.position = Vector2(-40, -60)
	cath_label.add_theme_font_size_override("font_size", 14)
	cath_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	cathedral.add_child(cath_label)

	# Cathedral walls (prevent walking through)
	var cath_walls := StaticBody2D.new()
	cath_walls.collision_layer = 1
	cath_walls.collision_mask = 0
	cathedral.add_child(cath_walls)

	# Left wall
	_add_wall_segment(cath_walls, Vector2(-50, 0), Vector2(6, 80))
	# Right wall
	_add_wall_segment(cath_walls, Vector2(50, 0), Vector2(6, 80))
	# Back wall
	_add_wall_segment(cath_walls, Vector2(0, -40), Vector2(100, 6))

	# Cathedral door zone
	var door_zone = InteractionZoneScript.new()
	door_zone.name = "DoorZone"
	door_zone.prompt_text = "Press [A] to enter Cathedral"
	door_zone.target_scene = "res://scenes/CathedralEntrance.tscn"
	door_zone.position = Vector2(0, 44)
	cathedral.add_child(door_zone)

	var door_col := CollisionShape2D.new()
	var door_shape := RectangleShape2D.new()
	door_shape.size = Vector2(30, 20)
	door_col.shape = door_shape
	door_zone.add_child(door_col)

	# Door visual
	var door_visual := Polygon2D.new()
	door_visual.polygon = PackedVector2Array([
		Vector2(-12, -8), Vector2(12, -8),
		Vector2(12, 8), Vector2(-12, 8),
	])
	door_visual.color = Color(0.6, 0.45, 0.15)
	door_zone.add_child(door_visual)

	# Weapon Shop
	var weapon_shop := Node2D.new()
	weapon_shop.name = "WeaponShop"
	weapon_shop.position = grid_center + Vector2(-120, 40)
	buildings.add_child(weapon_shop)

	var ws_body := Polygon2D.new()
	ws_body.polygon = PackedVector2Array([
		Vector2(-30, -25), Vector2(30, -25),
		Vector2(30, 25), Vector2(-30, 25),
	])
	ws_body.color = Color(0.35, 0.25, 0.15)
	weapon_shop.add_child(ws_body)

	var ws_walls := StaticBody2D.new()
	ws_walls.collision_layer = 1
	ws_walls.collision_mask = 0
	weapon_shop.add_child(ws_walls)
	_add_wall_segment(ws_walls, Vector2(0, 0), Vector2(60, 50))

	var ws_label := Label.new()
	ws_label.text = "Weapon Shop (WIP)"
	ws_label.position = Vector2(-50, -40)
	ws_label.add_theme_font_size_override("font_size", 12)
	ws_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	weapon_shop.add_child(ws_label)

	# Armor Shop
	var armor_shop := Node2D.new()
	armor_shop.name = "ArmorShop"
	armor_shop.position = grid_center + Vector2(120, 40)
	buildings.add_child(armor_shop)

	var as_body := Polygon2D.new()
	as_body.polygon = PackedVector2Array([
		Vector2(-30, -25), Vector2(30, -25),
		Vector2(30, 25), Vector2(-30, 25),
	])
	as_body.color = Color(0.28, 0.28, 0.22)
	armor_shop.add_child(as_body)

	var as_walls := StaticBody2D.new()
	as_walls.collision_layer = 1
	as_walls.collision_mask = 0
	armor_shop.add_child(as_walls)
	_add_wall_segment(as_walls, Vector2(0, 0), Vector2(60, 50))

	var as_label := Label.new()
	as_label.text = "Armor Shop (WIP)"
	as_label.position = Vector2(-50, -40)
	as_label.add_theme_font_size_override("font_size", 12)
	as_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	armor_shop.add_child(as_label)

	# --- Boundaries ---
	var boundary_size := 400.0
	var boundaries := Node2D.new()
	boundaries.name = "Boundaries"
	add_child(boundaries)

	# Top
	var top_wall := StaticBody2D.new()
	top_wall.collision_layer = 1
	top_wall.position = grid_center + Vector2(0, -boundary_size * 0.5)
	boundaries.add_child(top_wall)
	_add_wall_segment(top_wall, Vector2.ZERO, Vector2(boundary_size * 2, 10))

	# Bottom
	var bot_wall := StaticBody2D.new()
	bot_wall.collision_layer = 1
	bot_wall.position = grid_center + Vector2(0, boundary_size * 0.5)
	boundaries.add_child(bot_wall)
	_add_wall_segment(bot_wall, Vector2.ZERO, Vector2(boundary_size * 2, 10))

	# Left
	var left_wall := StaticBody2D.new()
	left_wall.collision_layer = 1
	left_wall.position = grid_center + Vector2(-boundary_size, 0)
	boundaries.add_child(left_wall)
	_add_wall_segment(left_wall, Vector2.ZERO, Vector2(10, boundary_size))

	# Right
	var right_wall := StaticBody2D.new()
	right_wall.collision_layer = 1
	right_wall.position = grid_center + Vector2(boundary_size, 0)
	boundaries.add_child(right_wall)
	_add_wall_segment(right_wall, Vector2.ZERO, Vector2(10, boundary_size))

	# --- Town label ---
	var town_label := Label.new()
	town_label.name = "TownLabel"
	town_label.text = "Tristram"
	town_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	town_label.position = grid_center + Vector2(-60, -boundary_size * 0.45)
	town_label.add_theme_font_size_override("font_size", 28)
	town_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	add_child(town_label)

	# --- Spawn player ---
	_player = PlayerIsoScript.new()
	_player.name = "Player"
	_player.position = grid_center + Vector2(0, 60)
	add_child(_player)

	# --- Camera ---
	_camera = Camera2D.new()
	_camera.name = "GameCamera"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.zoom = Vector2(2.0, 2.0)
	_camera.position = _player.position
	add_child(_camera)
	_camera.make_current()


func _process(_delta: float) -> void:
	if _player and _camera:
		_camera.position = _player.position


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		# Pause handled by PauseMenu node if present
		pass


func _add_wall_segment(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	parent.add_child(col)
