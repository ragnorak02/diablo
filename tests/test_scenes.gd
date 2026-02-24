extends RefCounted
## Tests for scene and script file existence and integrity.


# --- Scene file existence ---

func test_town_scene_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scenes/Town.tscn"):
		return {"passed": false, "message": "Town.tscn not found"}
	return {"passed": true, "message": ""}


func test_cathedral_entrance_scene_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scenes/CathedralEntrance.tscn"):
		return {"passed": false, "message": "CathedralEntrance.tscn not found"}
	return {"passed": true, "message": ""}


func test_dungeon_floor_scene_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scenes/DungeonFloor.tscn"):
		return {"passed": false, "message": "DungeonFloor.tscn not found"}
	return {"passed": true, "message": ""}


func test_main_scene_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scenes/main/main.tscn"):
		return {"passed": false, "message": "main.tscn not found"}
	return {"passed": true, "message": ""}


# --- Script file existence ---

func test_town_script_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scripts/town/town.gd"):
		return {"passed": false, "message": "town.gd not found"}
	return {"passed": true, "message": ""}


func test_cathedral_entrance_script_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scripts/dungeon/cathedral_entrance.gd"):
		return {"passed": false, "message": "cathedral_entrance.gd not found"}
	return {"passed": true, "message": ""}


func test_dungeon_floor_script_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scripts/dungeon/dungeon_floor.gd"):
		return {"passed": false, "message": "dungeon_floor.gd not found"}
	return {"passed": true, "message": ""}


func test_interaction_zone_script_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scripts/environment/interaction_zone.gd"):
		return {"passed": false, "message": "interaction_zone.gd not found"}
	return {"passed": true, "message": ""}


func test_iso_tile_grid_script_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scripts/environment/iso_tile_grid.gd"):
		return {"passed": false, "message": "iso_tile_grid.gd not found"}
	return {"passed": true, "message": ""}


func test_player_iso_script_exists() -> Dictionary:
	if not ResourceLoader.exists("res://scripts/player/player_iso.gd"):
		return {"passed": false, "message": "player_iso.gd not found"}
	return {"passed": true, "message": ""}


# --- Scene loading tests ---

func test_town_scene_loads() -> Dictionary:
	var scene := load("res://scenes/Town.tscn")
	if scene == null:
		return {"passed": false, "message": "Town.tscn failed to load"}
	return {"passed": true, "message": ""}


func test_cathedral_entrance_scene_loads() -> Dictionary:
	var scene := load("res://scenes/CathedralEntrance.tscn")
	if scene == null:
		return {"passed": false, "message": "CathedralEntrance.tscn failed to load"}
	return {"passed": true, "message": ""}


func test_dungeon_floor_scene_loads() -> Dictionary:
	var scene := load("res://scenes/DungeonFloor.tscn")
	if scene == null:
		return {"passed": false, "message": "DungeonFloor.tscn failed to load"}
	return {"passed": true, "message": ""}


# --- All scene paths referenced in code should exist ---

func test_all_scene_paths_resolve() -> Dictionary:
	var paths := [
		"res://scenes/Town.tscn",
		"res://scenes/CathedralEntrance.tscn",
		"res://scenes/DungeonFloor.tscn",
		"res://scenes/main/main.tscn",
	]
	for path in paths:
		if not ResourceLoader.exists(path):
			return {"passed": false, "message": "Scene path does not exist: %s" % path}
	return {"passed": true, "message": ""}
