extends Node2D
## Walkable 2D isometric dungeon floor with stairs up/down.
## Stairs up: floor 1 → CathedralEntrance; floor 2+ → reload with floor-1.
## Stairs down: hidden on max floor; otherwise reload with floor+1.

var _player: PlayerIso
var _camera: Camera2D
var _floor_label: Label
var _stairs_down_zone: InteractionZone


func _ready() -> void:
	y_sort_enabled = true

	var current_floor := GameManager.current_floor

	# Floor tiles — very dark stone
	var floor_tiles := IsoTileGrid.new()
	floor_tiles.name = "FloorTiles"
	floor_tiles.grid_width = 16
	floor_tiles.grid_height = 16
	floor_tiles.tile_size = 32.0
	floor_tiles.tile_color = Color(0.12, 0.10, 0.10)
	floor_tiles.tile_color_alt = Color(0.09, 0.07, 0.08)
	add_child(floor_tiles)

	var grid_center := floor_tiles.get_grid_center()

	# --- Boundary walls ---
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)

	var wall_extent := 180.0

	# Top wall
	var tw := StaticBody2D.new()
	tw.collision_layer = 1
	tw.position = grid_center + Vector2(0, -wall_extent * 0.5)
	walls.add_child(tw)
	_add_wall_segment(tw, Vector2.ZERO, Vector2(wall_extent * 2, 8))
	_add_wall_visual(tw, Vector2(wall_extent * 2, 8))

	# Bottom wall
	var bw := StaticBody2D.new()
	bw.collision_layer = 1
	bw.position = grid_center + Vector2(0, wall_extent * 0.5)
	walls.add_child(bw)
	_add_wall_segment(bw, Vector2.ZERO, Vector2(wall_extent * 2, 8))
	_add_wall_visual(bw, Vector2(wall_extent * 2, 8))

	# Left wall
	var lw := StaticBody2D.new()
	lw.collision_layer = 1
	lw.position = grid_center + Vector2(-wall_extent, 0)
	walls.add_child(lw)
	_add_wall_segment(lw, Vector2.ZERO, Vector2(8, wall_extent))
	_add_wall_visual(lw, Vector2(8, wall_extent))

	# Right wall
	var rw := StaticBody2D.new()
	rw.collision_layer = 1
	rw.position = grid_center + Vector2(wall_extent, 0)
	walls.add_child(rw)
	_add_wall_segment(rw, Vector2.ZERO, Vector2(8, wall_extent))
	_add_wall_visual(rw, Vector2(8, wall_extent))

	# --- Stairs Up ---
	var stairs_up := InteractionZone.new()
	stairs_up.name = "StairsUp"
	stairs_up.position = grid_center + Vector2(-60, -wall_extent * 0.35)
	add_child(stairs_up)

	var su_col := CollisionShape2D.new()
	var su_shape := RectangleShape2D.new()
	su_shape.size = Vector2(36, 26)
	su_col.shape = su_shape
	stairs_up.add_child(su_col)

	if current_floor == 1:
		stairs_up.prompt_text = "Press [A] to return to Cathedral"
	else:
		stairs_up.prompt_text = "Press [A] to ascend"

	# Stairs up visual
	var su_vis := Polygon2D.new()
	su_vis.polygon = PackedVector2Array([
		Vector2(-16, -10), Vector2(16, -10),
		Vector2(16, 10), Vector2(-16, 10),
	])
	su_vis.color = Color(0.25, 0.22, 0.18)
	stairs_up.add_child(su_vis)

	var su_label := Label.new()
	su_label.text = "Up"
	su_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	su_label.position = Vector2(-10, -28)
	su_label.add_theme_font_size_override("font_size", 11)
	su_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
	stairs_up.add_child(su_label)

	stairs_up.zone_activated.connect(_on_stairs_up)

	# --- Stairs Down ---
	_stairs_down_zone = InteractionZone.new()
	_stairs_down_zone.name = "StairsDown"
	_stairs_down_zone.prompt_text = "Press [A] to descend"
	_stairs_down_zone.position = grid_center + Vector2(60, wall_extent * 0.35)
	add_child(_stairs_down_zone)

	var sd_col := CollisionShape2D.new()
	var sd_shape := RectangleShape2D.new()
	sd_shape.size = Vector2(36, 26)
	sd_col.shape = sd_shape
	_stairs_down_zone.add_child(sd_col)

	# Stairs down visual
	var sd_vis := Polygon2D.new()
	sd_vis.polygon = PackedVector2Array([
		Vector2(-16, -10), Vector2(16, -10),
		Vector2(16, 10), Vector2(-16, 10),
	])
	sd_vis.color = Color(0.05, 0.03, 0.06)
	_stairs_down_zone.add_child(sd_vis)

	var sd_label := Label.new()
	sd_label.text = "Down"
	sd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sd_label.position = Vector2(-14, -28)
	sd_label.add_theme_font_size_override("font_size", 11)
	sd_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
	_stairs_down_zone.add_child(sd_label)

	_stairs_down_zone.zone_activated.connect(_on_stairs_down)

	# Hide stairs down on max floor
	if current_floor >= GameManager.total_floors:
		_stairs_down_zone.visible = false
		_stairs_down_zone.set_process(false)
		_stairs_down_zone.set_physics_process(false)
		_stairs_down_zone.monitoring = false

	# --- Floor label ---
	_floor_label = Label.new()
	_floor_label.name = "FloorLabel"
	_floor_label.text = "Floor %d" % current_floor
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_floor_label.position = grid_center + Vector2(-40, -wall_extent * 0.5 - 30)
	_floor_label.add_theme_font_size_override("font_size", 22)
	_floor_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	add_child(_floor_label)

	# --- Spawn player near stairs up ---
	_player = PlayerIso.new()
	_player.name = "Player"
	_player.position = grid_center + Vector2(-60, -wall_extent * 0.25)
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

	EventBus.show_notification.emit("Dungeon — Floor %d" % current_floor, "default")
	EventBus.floor_changed.emit(current_floor)


func _process(_delta: float) -> void:
	if _player and _camera:
		_camera.position = _player.position


func _on_stairs_up() -> void:
	if GameManager.current_floor == 1:
		# Return to cathedral entrance
		get_tree().change_scene_to_file("res://scenes/CathedralEntrance.tscn")
	else:
		GameManager.current_floor -= 1
		get_tree().reload_current_scene()


func _on_stairs_down() -> void:
	if GameManager.current_floor < GameManager.total_floors:
		GameManager.current_floor += 1
		get_tree().reload_current_scene()


func _add_wall_segment(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	parent.add_child(col)


func _add_wall_visual(parent: Node2D, size: Vector2) -> void:
	var vis := Polygon2D.new()
	var hs := size * 0.5
	vis.polygon = PackedVector2Array([
		Vector2(-hs.x, -hs.y), Vector2(hs.x, -hs.y),
		Vector2(hs.x, hs.y), Vector2(-hs.x, hs.y),
	])
	vis.color = Color(0.28, 0.24, 0.2)
	parent.add_child(vis)
