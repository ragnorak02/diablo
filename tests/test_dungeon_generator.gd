extends RefCounted
## Tests for DungeonGenerator (scripts/dungeon/dungeon_generator.gd)

var _script: GDScript
var _mesh_loader_script: GDScript


func _init() -> void:
	_script = load("res://scripts/dungeon/dungeon_generator.gd")
	_mesh_loader_script = load("res://scripts/dungeon/dungeon_mesh_loader.gd")


func _create_generator() -> Object:
	var gen = _script.new()
	gen._mesh_loader = _mesh_loader_script.new()
	gen.max_floors = 10
	return gen


# --- Floor data shape ---

func test_generate_floor_returns_dictionary() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)
	var expected_keys := ["floor_number", "rooms", "entrance", "exit", "spawn_points", "enemy_spawn_points"]
	for key in expected_keys:
		if not data.has(key):
			gen.free()
			return {"passed": false, "message": "Missing key: %s" % key}
	gen.free()
	return {"passed": true, "message": ""}


func test_floor_has_rooms() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)
	if data.rooms.size() == 0:
		gen.free()
		return {"passed": false, "message": "No rooms generated"}
	gen.free()
	return {"passed": true, "message": ""}


func test_floor_has_spawn_points() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)
	if data.spawn_points.size() == 0:
		gen.free()
		return {"passed": false, "message": "No spawn points generated"}
	gen.free()
	return {"passed": true, "message": ""}


func test_floor_has_enemy_spawn_points() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)
	if data.enemy_spawn_points.size() == 0:
		gen.free()
		return {"passed": false, "message": "No enemy spawn points generated"}
	gen.free()
	return {"passed": true, "message": ""}


func test_floor_has_entrance_and_exit() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)
	if data.entrance == Vector2i.ZERO and data.exit == Vector2i.ZERO:
		gen.free()
		return {"passed": false, "message": "Entrance and exit both at origin"}
	if data.entrance == data.exit:
		gen.free()
		return {"passed": false, "message": "Entrance and exit at same position"}
	gen.free()
	return {"passed": true, "message": ""}


# --- Seed determinism ---

func test_seed_determinism() -> Dictionary:
	var gen1 = _create_generator()
	gen1.set_seed(12345)
	var data1: Dictionary = gen1.generate_floor(1)
	var rooms1: Array = []
	for r in data1.rooms:
		rooms1.append({"pos": r.position, "size": r.size})
	gen1.free()

	var gen2 = _create_generator()
	gen2.set_seed(12345)
	var data2: Dictionary = gen2.generate_floor(1)
	var rooms2: Array = []
	for r in data2.rooms:
		rooms2.append({"pos": r.position, "size": r.size})
	gen2.free()

	if rooms1.size() != rooms2.size():
		return {"passed": false, "message": "Room count differs: %d vs %d" % [rooms1.size(), rooms2.size()]}
	for i in rooms1.size():
		if rooms1[i].pos != rooms2[i].pos or rooms1[i].size != rooms2[i].size:
			return {"passed": false, "message": "Room %d differs between runs" % i}
	return {"passed": true, "message": ""}


func test_different_seeds_different_floors() -> Dictionary:
	var gen1 = _create_generator()
	gen1.set_seed(111)
	var data1: Dictionary = gen1.generate_floor(1)
	var rooms1_positions: Array = []
	for r in data1.rooms:
		rooms1_positions.append(r.position)
	gen1.free()

	var gen2 = _create_generator()
	gen2.set_seed(999)
	var data2: Dictionary = gen2.generate_floor(1)
	var rooms2_positions: Array = []
	for r in data2.rooms:
		rooms2_positions.append(r.position)
	gen2.free()

	# At least one room should differ in position
	var all_same := true
	if rooms1_positions.size() != rooms2_positions.size():
		all_same = false
	else:
		for i in rooms1_positions.size():
			if rooms1_positions[i] != rooms2_positions[i]:
				all_same = false
				break
	if all_same:
		return {"passed": false, "message": "Different seeds produced identical layouts"}
	return {"passed": true, "message": ""}


# --- Spawn boundary validation ---

func test_enemy_spawns_within_rooms() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)
	var tile_size: float = 3.0  # DungeonGenerator.TILE_SIZE

	for sp in data.enemy_spawn_points:
		var inside := false
		for room in data.rooms:
			var room_min := Vector3(room.position.x * tile_size, 0, room.position.y * tile_size)
			var room_max := Vector3((room.end.x - 1) * tile_size, 0, (room.end.y - 1) * tile_size)
			if sp.x >= room_min.x and sp.x <= room_max.x and sp.z >= room_min.z and sp.z <= room_max.z:
				inside = true
				break
		if not inside:
			gen.free()
			return {"passed": false, "message": "Enemy spawn at (%s, %s) outside all rooms" % [str(sp.x), str(sp.z)]}
	gen.free()
	return {"passed": true, "message": ""}


# --- Connectivity / softlock detection ---

func test_all_rooms_connected() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	gen.generate_floor(1)

	# Verify corridor connectivity via flood fill on the grid
	var visited: Dictionary = {}
	var rooms_arr: Array = gen.rooms
	var first_room: Rect2i = rooms_arr[0]
	var start: Vector2i = first_room.get_center()
	var queue: Array = [start]
	visited[start] = true

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front()
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = pos + dir
			if next.x >= 0 and next.x < 60 and next.y >= 0 and next.y < 60:
				if not visited.has(next) and gen.grid[next.x][next.y] != 0:  # not EMPTY
					visited[next] = true
					queue.append(next)

	# Check that every room has at least one visited tile
	for room in gen.rooms:
		var found := false
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				if visited.has(Vector2i(x, y)):
					found = true
					break
			if found:
				break
		if not found:
			gen.free()
			return {"passed": false, "message": "Room at %s unreachable" % str(room.position)}

	gen.free()
	return {"passed": true, "message": ""}


func test_stairs_in_different_rooms() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(42)
	var data: Dictionary = gen.generate_floor(1)

	if data.entrance == data.exit:
		gen.free()
		return {"passed": false, "message": "Entrance and exit at same position"}

	# Verify they're in different rooms
	var entrance_room := -1
	var exit_room := -1
	for i in gen.rooms.size():
		var room: Rect2i = gen.rooms[i]
		if room.has_point(data.entrance):
			entrance_room = i
		if room.has_point(data.exit):
			exit_room = i

	if entrance_room == exit_room:
		gen.free()
		return {"passed": false, "message": "Entrance and exit in same room (%d)" % entrance_room}
	gen.free()
	return {"passed": true, "message": ""}


# --- Softlock loop test ---

func test_no_softlocks_10_floors() -> Dictionary:
	for s in range(10):
		var gen = _create_generator()
		gen.set_seed(s * 7 + 13)
		var data: Dictionary = gen.generate_floor(s + 1)
		if data.rooms.size() < 2:
			gen.free()
			return {"passed": false, "message": "Floor %d has fewer than 2 rooms (seed %d)" % [s + 1, s * 7 + 13]}
		if data.spawn_points.size() == 0:
			gen.free()
			return {"passed": false, "message": "Floor %d has no spawn points" % (s + 1)}
		gen.free()
	return {"passed": true, "message": ""}


# --- Stress test ---

func test_stress_20_floors() -> Dictionary:
	var gen = _create_generator()
	gen.set_seed(1)
	for floor_num in range(1, 21):
		var data: Dictionary = gen.generate_floor(floor_num)
		if data.rooms.size() == 0:
			gen.free()
			return {"passed": false, "message": "Floor %d generated 0 rooms" % floor_num}
		if data.floor_number != floor_num:
			gen.free()
			return {"passed": false, "message": "Floor %d returned wrong floor_number: %d" % [floor_num, data.floor_number]}
	gen.free()
	return {"passed": true, "message": ""}
