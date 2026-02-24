class_name DungeonGenerator
extends Node3D
## Procedural dungeon generator. Creates rooms, corridors, stairs, and extraction zone.

signal generation_complete(floor_data: Dictionary)

const TILE_SIZE := 3.0
const MIN_ROOM_SIZE := Vector2i(4, 4)
const MAX_ROOM_SIZE := Vector2i(8, 8)
const ROOMS_PER_FLOOR := 8
const CORRIDOR_WIDTH := 2
const GRID_SIZE := Vector2i(60, 60)

enum TileType { EMPTY, FLOOR, WALL, STAIRS_DOWN, STAIRS_UP, EXTRACTION, DOOR }

var grid: Array = []  # 2D array of TileType
var rooms: Array[Rect2i] = []
var floor_number: int = 1
var entrance_pos: Vector2i = Vector2i.ZERO
var exit_pos: Vector2i = Vector2i.ZERO
var spawn_points: Array[Vector3] = []
var enemy_spawn_points: Array[Vector3] = []

# Mesh loader handles procedural + .glb mesh/material loading
const MeshLoaderScript = preload("res://scripts/dungeon/dungeon_mesh_loader.gd")
var _mesh_loader


func _ready() -> void:
	_mesh_loader = MeshLoaderScript.new()


func generate_floor(floor_num: int) -> Dictionary:
	floor_number = floor_num
	rooms.clear()
	spawn_points.clear()
	enemy_spawn_points.clear()
	_clear_children()
	_init_grid()
	_place_rooms()
	_connect_rooms()
	_place_stairs()
	_place_extraction_zone()
	_calculate_spawn_points()
	_build_geometry()
	_add_lights()

	var floor_data := {
		"floor_number": floor_num,
		"rooms": rooms,
		"entrance": entrance_pos,
		"exit": exit_pos,
		"spawn_points": spawn_points,
		"enemy_spawn_points": enemy_spawn_points,
	}
	generation_complete.emit(floor_data)
	return floor_data


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _init_grid() -> void:
	grid.clear()
	for x in GRID_SIZE.x:
		var row: Array = []
		for y in GRID_SIZE.y:
			row.append(TileType.EMPTY)
		grid.append(row)


func _place_rooms() -> void:
	var attempts := 0
	while rooms.size() < ROOMS_PER_FLOOR and attempts < 200:
		attempts += 1
		var w := randi_range(MIN_ROOM_SIZE.x, MAX_ROOM_SIZE.x)
		var h := randi_range(MIN_ROOM_SIZE.y, MAX_ROOM_SIZE.y)
		var x := randi_range(2, GRID_SIZE.x - w - 2)
		var y := randi_range(2, GRID_SIZE.y - h - 2)
		var room := Rect2i(x, y, w, h)

		var overlaps := false
		for existing in rooms:
			if room.grow(2).intersects(existing):
				overlaps = true
				break

		if not overlaps:
			rooms.append(room)
			_carve_room(room)


func _carve_room(room: Rect2i) -> void:
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			grid[x][y] = TileType.FLOOR


func _connect_rooms() -> void:
	for i in range(rooms.size() - 1):
		var from := rooms[i].get_center()
		var to := rooms[i + 1].get_center()
		_carve_corridor(from, to)


func _carve_corridor(from: Vector2i, to: Vector2i) -> void:
	var x := from.x
	var y := from.y

	# L-shaped corridor
	while x != to.x:
		for w in CORRIDOR_WIDTH:
			var cy := clampi(y + w, 0, GRID_SIZE.y - 1)
			if grid[x][cy] == TileType.EMPTY:
				grid[x][cy] = TileType.FLOOR
		x += 1 if to.x > x else -1

	while y != to.y:
		for w in CORRIDOR_WIDTH:
			var cx := clampi(x + w, 0, GRID_SIZE.x - 1)
			if grid[cx][y] == TileType.EMPTY:
				grid[cx][y] = TileType.FLOOR
		y += 1 if to.y > y else -1


func _place_stairs() -> void:
	if rooms.size() < 2:
		return

	# Entrance (stairs up) in first room
	var first_room := rooms[0]
	entrance_pos = first_room.get_center()
	grid[entrance_pos.x][entrance_pos.y] = TileType.STAIRS_UP

	# Exit (stairs down) in last room
	if floor_number < GameManager.total_floors:
		var last_room := rooms[rooms.size() - 1]
		exit_pos = last_room.get_center()
		grid[exit_pos.x][exit_pos.y] = TileType.STAIRS_DOWN


func _place_extraction_zone() -> void:
	# Extraction zone is at the entrance (floor 1 stairs up area)
	if floor_number == 1 and rooms.size() > 0:
		var room := rooms[0]
		for x in range(room.position.x, mini(room.position.x + 3, room.end.x)):
			for y in range(room.position.y, mini(room.position.y + 3, room.end.y)):
				if grid[x][y] == TileType.FLOOR:
					grid[x][y] = TileType.EXTRACTION


func _calculate_spawn_points() -> void:
	# Player spawns near entrance
	var entrance_world := _grid_to_world(entrance_pos)
	spawn_points.append(entrance_world + Vector3(TILE_SIZE, 0, 0))
	spawn_points.append(entrance_world + Vector3(-TILE_SIZE, 0, 0))
	spawn_points.append(entrance_world + Vector3(0, 0, TILE_SIZE))
	spawn_points.append(entrance_world + Vector3(0, 0, -TILE_SIZE))

	# Enemy spawns in rooms (skip first room - that's the entrance)
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var center := room.get_center()
		var center_world := _grid_to_world(center)
		enemy_spawn_points.append(center_world)
		# Add more spawn points around room
		for offset in [Vector3(TILE_SIZE * 2, 0, 0), Vector3(-TILE_SIZE * 2, 0, 0),
						Vector3(0, 0, TILE_SIZE * 2), Vector3(0, 0, -TILE_SIZE * 2)]:
			var sp: Vector3 = center_world + offset
			enemy_spawn_points.append(sp)


func _grid_to_world(pos: Vector2i) -> Vector3:
	return Vector3(pos.x * TILE_SIZE, 0.0, pos.y * TILE_SIZE)


func _build_geometry() -> void:
	# Use MultiMeshInstance3D for performance
	var floor_tiles: Array[Vector3] = []
	var wall_tiles: Array[Vector3] = []
	var stair_tiles: Array[Vector3] = []
	var extraction_tiles: Array[Vector3] = []

	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			var tile: int = grid[x][y]
			var world_pos := _grid_to_world(Vector2i(x, y))

			match tile:
				TileType.FLOOR:
					floor_tiles.append(world_pos)
				TileType.STAIRS_UP, TileType.STAIRS_DOWN:
					stair_tiles.append(world_pos)
				TileType.EXTRACTION:
					extraction_tiles.append(world_pos)
				TileType.EMPTY:
					# Check if adjacent to floor - if so, place wall
					if _is_adjacent_to_floor(x, y):
						wall_tiles.append(world_pos)

	# Build meshes using the loader
	var floor_mesh = _mesh_loader.get_mesh(MeshLoaderScript.TileMesh.FLOOR)
	var floor_mat = _mesh_loader.get_material(MeshLoaderScript.TileMesh.FLOOR)
	var wall_mesh = _mesh_loader.get_mesh(MeshLoaderScript.TileMesh.WALL)
	var wall_mat = _mesh_loader.get_material(MeshLoaderScript.TileMesh.WALL)
	var stairs_mesh = _mesh_loader.get_mesh(MeshLoaderScript.TileMesh.STAIRS)
	var stairs_mat = _mesh_loader.get_material(MeshLoaderScript.TileMesh.STAIRS)
	var extraction_mesh = _mesh_loader.get_mesh(MeshLoaderScript.TileMesh.EXTRACTION)
	var extraction_mat = _mesh_loader.get_material(MeshLoaderScript.TileMesh.EXTRACTION)
	var wall_cap_mesh = _mesh_loader.get_mesh(MeshLoaderScript.TileMesh.WALL_CAP)
	var wall_cap_mat = _mesh_loader.get_material(MeshLoaderScript.TileMesh.WALL_CAP)

	_build_multimesh("Floors", floor_tiles, floor_mesh, floor_mat, Vector3(0, -0.1, 0), true)
	_build_multimesh("Walls", wall_tiles, wall_mesh, wall_mat, Vector3(0, 1.3, 0), false)
	_build_multimesh("Stairs", stair_tiles, stairs_mesh, stairs_mat, Vector3(0, -0.1, 0), false)
	_build_multimesh("Extraction", extraction_tiles, extraction_mesh, extraction_mat, Vector3(0, -0.05, 0), false)

	# Wall caps on top of walls
	_build_multimesh("WallCaps", wall_tiles, wall_cap_mesh, wall_cap_mat, Vector3(0, 2.85, 0), false)

	# Build collision
	_build_collision(wall_tiles)
	_build_floor_collision(floor_tiles + stair_tiles + extraction_tiles)

	# Build navigation mesh
	_build_navigation(floor_tiles + stair_tiles + extraction_tiles)

	# Build extraction zone area
	if extraction_tiles.size() > 0:
		_build_extraction_area(extraction_tiles)

	# Build stair interaction areas
	_build_stair_areas(stair_tiles)

	# Place torches in rooms
	_place_torches()


func _is_adjacent_to_floor(x: int, y: int) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < GRID_SIZE.x and ny >= 0 and ny < GRID_SIZE.y:
				var neighbor: int = grid[nx][ny]
				if neighbor != TileType.EMPTY and neighbor != TileType.WALL:
					return true
	return false


func _build_multimesh(mesh_name: String, positions: Array, mesh: Mesh, material: Material, offset: Vector3, randomize_rotation: bool = false) -> void:
	if positions.is_empty():
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()

	for i in positions.size():
		var t := Transform3D()
		if randomize_rotation:
			# Random 90-degree rotation increments + subtle scale variation
			var rot_step: int = randi() % 4
			var angle: float = rot_step * PI * 0.5
			t = t.rotated(Vector3.UP, angle)
			var scale_var: float = randf_range(0.97, 1.03)
			t = t.scaled(Vector3(scale_var, 1.0, scale_var))
		t.origin = positions[i] + offset
		mm.set_instance_transform(i, t)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = mesh_name
	mmi.multimesh = mm
	mmi.material_override = material
	add_child(mmi)


func _build_collision(wall_positions: Array) -> void:
	var sb := StaticBody3D.new()
	sb.name = "WallCollision"
	sb.collision_layer = 1  # environment layer
	sb.collision_mask = 0
	add_child(sb)

	for pos in wall_positions:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(TILE_SIZE, 3.0, TILE_SIZE)
		cs.shape = shape
		cs.position = pos + Vector3(0, 1.3, 0)
		sb.add_child(cs)


func _build_floor_collision(floor_positions: Array) -> void:
	var sb := StaticBody3D.new()
	sb.name = "FloorCollision"
	sb.collision_layer = 1
	sb.collision_mask = 0
	add_child(sb)

	for pos in floor_positions:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(TILE_SIZE, 0.4, TILE_SIZE)
		cs.shape = shape
		cs.position = pos + Vector3(0, -0.3, 0)
		sb.add_child(cs)


func _build_navigation(floor_positions: Array) -> void:
	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavRegion"

	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.1
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.3

	# Build nav mesh vertices from floor positions
	var vertices := PackedVector3Array()
	for pos in floor_positions:
		var half := TILE_SIZE * 0.5
		vertices.append(pos + Vector3(-half, 0, -half))
		vertices.append(pos + Vector3(half, 0, -half))
		vertices.append(pos + Vector3(half, 0, half))
		vertices.append(pos + Vector3(-half, 0, half))

	# Add polygons (quads as two triangles each)
	for i in range(0, vertices.size(), 4):
		nav_mesh.add_polygon(PackedInt32Array([i, i + 1, i + 2]))
		nav_mesh.add_polygon(PackedInt32Array([i, i + 2, i + 3]))

	nav_mesh.vertices = vertices
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)


func _build_extraction_area(positions: Array) -> void:
	var area := Area3D.new()
	area.name = "ExtractionZone"
	area.collision_layer = 64  # layer 7 = extraction_zone
	area.collision_mask = 2  # player layer
	area.monitoring = true
	add_child(area)

	for pos in positions:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(TILE_SIZE, 3.0, TILE_SIZE)
		cs.shape = shape
		cs.position = pos + Vector3(0, 1.0, 0)
		area.add_child(cs)

	area.body_entered.connect(_on_extraction_zone_entered)
	area.body_exited.connect(_on_extraction_zone_exited)


func _build_stair_areas(positions: Array) -> void:
	for pos in positions:
		var area := Area3D.new()
		area.name = "StairArea"
		area.collision_layer = 32  # layer 6 = interaction
		area.collision_mask = 2  # player
		area.monitoring = true
		add_child(area)

		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(TILE_SIZE, 3.0, TILE_SIZE)
		cs.shape = shape
		cs.position = pos + Vector3(0, 1.0, 0)
		area.add_child(cs)

		# Determine if this is up or down stairs based on grid
		var grid_pos := Vector2i(roundi(pos.x / TILE_SIZE), roundi(pos.z / TILE_SIZE))
		var is_down: bool = grid[grid_pos.x][grid_pos.y] == TileType.STAIRS_DOWN
		area.set_meta("stairs_direction", "down" if is_down else "up")
		area.body_entered.connect(_on_stair_entered.bind(area))


func _place_torches() -> void:
	# Place 2-4 torches per room on wall-adjacent positions
	for room in rooms:
		var torch_count := randi_range(2, 4)
		var placed := 0
		var attempts := 0
		while placed < torch_count and attempts < 20:
			attempts += 1
			# Pick a random edge position of the room
			var side := randi() % 4
			var tx: int
			var ty: int
			match side:
				0:  # Top edge
					tx = randi_range(room.position.x, room.end.x - 1)
					ty = room.position.y
				1:  # Bottom edge
					tx = randi_range(room.position.x, room.end.x - 1)
					ty = room.end.y - 1
				2:  # Left edge
					tx = room.position.x
					ty = randi_range(room.position.y, room.end.y - 1)
				_:  # Right edge
					tx = room.end.x - 1
					ty = randi_range(room.position.y, room.end.y - 1)

			# Only place if this tile is floor and has an adjacent wall
			if tx >= 0 and tx < GRID_SIZE.x and ty >= 0 and ty < GRID_SIZE.y:
				if grid[tx][ty] == TileType.FLOOR:
					var world_pos := _grid_to_world(Vector2i(tx, ty))
					var torch = _mesh_loader.create_torch_prop()
					torch.position = world_pos + Vector3(0, 0, 0)
					add_child(torch)
					placed += 1


func _add_lights() -> void:
	# Ambient light
	var env := WorldEnvironment.new()
	env.name = "Environment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.03, 0.06)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.35, 0.28, 0.4)
	environment.ambient_light_energy = 3.0
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.08, 0.05, 0.1)
	environment.fog_density = 0.002
	env.environment = environment
	add_child(env)

	# Point lights in each room
	for room in rooms:
		var center := room.get_center()
		var world_pos := _grid_to_world(center)

		var light := OmniLight3D.new()
		light.name = "RoomLight"
		light.position = world_pos + Vector3(0, 2.5, 0)
		light.light_color = Color(0.9, 0.6, 0.3)  # Warm torch light
		light.light_energy = 8.0
		light.omni_range = TILE_SIZE * 12.0
		light.omni_attenuation = 0.8
		light.shadow_enabled = false
		add_child(light)


func _on_extraction_zone_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.get("player_id") if body.get("player_id") != null else 0
		EventBus.extraction_zone_entered.emit(pid)


func _on_extraction_zone_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.get("player_id") if body.get("player_id") != null else 0
		EventBus.extraction_zone_exited.emit(pid)


func _on_stair_entered(body: Node3D, area: Area3D) -> void:
	if body.is_in_group("player"):
		var direction: String = area.get_meta("stairs_direction")
		EventBus.stairs_entered.emit(direction, floor_number)
