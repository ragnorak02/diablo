extends RefCounted
## Tests for ItemDatabase (scripts/autoload/item_database.gd)

var DB: Object
var _db_script: GDScript


func _init() -> void:
	_db_script = load("res://scripts/autoload/item_database.gd")


func before_each() -> void:
	DB = _db_script.new()
	DB._register_items()


# --- Item registry ---

func test_items_registered() -> Dictionary:
	if DB.items.size() == 0:
		return {"passed": false, "message": "No items registered"}
	return {"passed": true, "message": ""}


func test_known_item_exists() -> Dictionary:
	if not DB.items.has("rusty_sword"):
		return {"passed": false, "message": "rusty_sword not found in items"}
	return {"passed": true, "message": ""}


func test_all_items_have_name_and_type() -> Dictionary:
	for id in DB.items:
		var item: Dictionary = DB.items[id]
		if not item.has("name"):
			return {"passed": false, "message": "%s missing 'name'" % id}
		if not item.has("type"):
			return {"passed": false, "message": "%s missing 'type'" % id}
	return {"passed": true, "message": ""}


# --- get_item returns copy ---

func test_get_item_returns_copy() -> Dictionary:
	var item: Dictionary = DB.get_item("rusty_sword")
	if item.is_empty():
		return {"passed": false, "message": "get_item returned empty for rusty_sword"}
	item["name"] = "MUTATED"
	var original: Dictionary = DB.get_item("rusty_sword")
	if original.name == "MUTATED":
		return {"passed": false, "message": "get_item did not return a copy — original was mutated"}
	return {"passed": true, "message": ""}


func test_get_item_unknown_returns_empty() -> Dictionary:
	var item: Dictionary = DB.get_item("nonexistent_item_xyz")
	if not item.is_empty():
		return {"passed": false, "message": "Expected empty dict for unknown item"}
	return {"passed": true, "message": ""}


# --- UID increments ---

func test_uid_increments() -> Dictionary:
	var uid1: int = DB.generate_uid()
	var uid2: int = DB.generate_uid()
	if uid2 != uid1 + 1:
		return {"passed": false, "message": "UIDs not sequential: %d, %d" % [uid1, uid2]}
	return {"passed": true, "message": ""}


func test_create_item_instance_has_uid() -> Dictionary:
	var inst: Dictionary = DB.create_item_instance("rusty_sword")
	if not inst.has("uid"):
		return {"passed": false, "message": "Instance missing uid"}
	if inst.uid <= 0:
		return {"passed": false, "message": "uid should be > 0, got %d" % inst.uid}
	return {"passed": true, "message": ""}


# --- Rarity rolls ---

func test_roll_rarity_returns_valid_range() -> Dictionary:
	for i in 20:
		var r: int = DB.roll_rarity(0.0)
		if r < 0 or r > 4:
			return {"passed": false, "message": "Rarity out of range: %d" % r}
	return {"passed": true, "message": ""}


func test_rarity_weights_count() -> Dictionary:
	if DB.RARITY_WEIGHTS.size() != 5:
		return {"passed": false, "message": "Expected 5 rarity weights, got %d" % DB.RARITY_WEIGHTS.size()}
	return {"passed": true, "message": ""}


func test_rarity_colors_count() -> Dictionary:
	if DB.RARITY_COLORS.size() != 5:
		return {"passed": false, "message": "Expected 5 rarity colors, got %d" % DB.RARITY_COLORS.size()}
	return {"passed": true, "message": ""}
